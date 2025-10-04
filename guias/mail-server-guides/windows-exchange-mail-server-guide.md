# Guía de Implementación de Correo Corporativo Activo con Exchange Server sobre Windows Server

**Materia:** Sistemas Operativos y Redes
**Práctica:** Implementación de correo corporativo activo con Exchange Server
**Fecha de entrega:** **30 de octubre**
**Topología:** 2 máquinas virtuales (Servidor y Cliente)

---

## 1. Objetivo

Implementar un sistema de **correo corporativo activo** basado en **Microsoft Exchange Server 2019/SE** sobre **Windows Server**, integrando los servicios de **Active Directory (AD DS), DNS y DHCP**, en un entorno de laboratorio aislado.
Se validará el envío y recepción de correos internos mediante **OWA (Outlook Web App)** y un cliente Windows unido al dominio.

---

## 2. Topología de Laboratorio

### 2.1 Descripción de las máquinas virtuales

* **VM1 – Servidor**

  * SO: Windows Server 2019/2022
  * Roles: AD DS, DNS, DHCP, Exchange Server (Mailbox)
  * Nombre: `DC-EX01`
  * IP: `192.168.10.20` (estática)
  * Dominio: `JPL.lab`

* **VM2 – Cliente**

  * SO: Windows 7
  * Rol: Cliente de pruebas unido al dominio
  * Nombre: `WIN7CL`
  * IP: Asignada por DHCP
  * Unión al dominio: `JPL.lab`

* **Red de laboratorio:** `192.168.10.0/24`

  * Gateway ficticio: `192.168.10.1` (no es necesario acceso a Internet)

---

## 3. Explicación de los Servicios

* **DHCP:** Asigna dinámicamente direcciones IP a los clientes.
* **DNS:** Traduce nombres de dominio a direcciones IP; crítico para AD y Exchange.
* **Active Directory (AD DS):** Base de datos de usuarios, equipos y políticas de dominio.
* **Exchange Server:** Plataforma de correo electrónico y colaboración.

---

## 4. Instalación y Configuración del Servidor (VM1)

### 4.1 Configuración de red estática

```powershell
New-NetIPAddress -InterfaceAlias "Ethernet0" -IPAddress 192.168.10.20 -PrefixLength 24 -DefaultGateway 192.168.10.1
Set-DnsClientServerAddress -InterfaceAlias "Ethernet0" -ServerAddresses 192.168.10.20
```

### 4.2 Instalación de AD DS y DNS

```powershell
Install-WindowsFeature AD-Domain-Services, DNS -IncludeManagementTools
Install-ADDSForest -DomainName "JPL.lab" -DomainNetbiosName "JPL" -InstallDns
```

> El servidor se reiniciará como **Controlador de Dominio**.

### 4.3 Instalación de DHCP

```powershell
Install-WindowsFeature DHCP -IncludeManagementTools
Add-DhcpServerInDC -DnsName "DC-EX01.JPL.lab" -IpAddress 192.168.10.20
```

Crear un **scope**:

```powershell
Add-DhcpServerv4Scope -Name "ScopeJPL" -StartRange 192.168.10.50 -EndRange 192.168.10.100 -SubnetMask 255.255.255.0 -State Active
Set-DhcpServerv4OptionValue -OptionId 3 -Value 192.168.10.1
Set-DhcpServerv4OptionValue -OptionId 6 -Value 192.168.10.20
Set-DhcpServerv4OptionValue -OptionId 15 -Value "JPL.lab"
```

### 4.4 Preparación de DNS para Exchange

Crear zona interna `JPL.lab` con registros:

* `mail.JPL.lab` → `192.168.10.20` (A)
* `autodiscover.JPL.lab` → `mail.JPL.lab` (CNAME)

```powershell
Add-DnsServerResourceRecordA -Name "mail" -ZoneName "JPL.lab" -IPv4Address 192.168.10.20
Add-DnsServerResourceRecordCName -Name "autodiscover" -HostNameAlias "mail.JPL.lab" -ZoneName "JPL.lab"
```

---

## 5. Instalación de Exchange Server

### 5.1 Prerrequisitos

```powershell
Install-WindowsFeature NET-Framework-45-Features, RSAT-ADDS, Web-Server, Web-Mgmt-Console, WAS-Process-Model, RSAT-ADDS -IncludeManagementTools
```

### 5.2 Preparación de Active Directory

Desde el instalador de Exchange:

```powershell
Setup.exe /PrepareSchema /IAcceptExchangeServerLicenseTerms_DiagnosticDataOFF
Setup.exe /PrepareAD /OrganizationName:"JPLOrg" /IAcceptExchangeServerLicenseTerms_DiagnosticDataOFF
Setup.exe /PrepareAllDomains /IAcceptExchangeServerLicenseTerms_DiagnosticDataOFF
```

### 5.3 Instalación del rol Mailbox

```powershell
Setup.exe /Mode:Install /Roles:Mailbox /IAcceptExchangeServerLicenseTerms_DiagnosticDataOFF
```

---

## 6. Configuración de Exchange

### 6.1 Dominios aceptados

```powershell
New-AcceptedDomain -Name "JPL" -DomainName "JPL.lab" -DomainType Authoritative
```

### 6.2 Políticas de direcciones de correo

```powershell
Set-EmailAddressPolicy "Default Policy" -EnabledEmailAddressTemplates "SMTP:%g.%s@JPL.lab"
```

### 6.3 Creación de buzones de prueba

```powershell
New-Mailbox -Name "Usuario1" -UserPrincipalName usuario1@JPL.lab -Password (ConvertTo-SecureString "P@ssw0rd!" -AsPlainText -Force)
New-Mailbox -Name "Usuario2" -UserPrincipalName usuario2@JPL.lab -Password (ConvertTo-SecureString "P@ssw0rd!" -AsPlainText -Force)
```

---

## 7. Configuración del Cliente (VM2)

### 7.1 Unión al dominio

En Windows 7:
**Panel de Control → Sistema → Cambiar configuración → Nombre de equipo → Dominio → JPL.lab**

Reiniciar y loguear como `JPL\usuario1`.

### 7.2 Acceso a OWA

Abrir navegador y entrar en:

```
https://mail.JPL.lab/owa
```

Aceptar el certificado autofirmado y probar login con `usuario1@JPL.lab`.

---

## 8. Pruebas y Validación

### 8.1 Conectividad

```powershell
ping mail.JPL.lab
Test-NetConnection mail.JPL.lab -Port 443
```

### 8.2 DNS

```cmd
nslookup mail.JPL.lab
nslookup autodiscover.JPL.lab
```

### 8.3 Exchange

```powershell
Test-ServiceHealth
Test-Mailflow
```

### 8.4 Prueba práctica

* Ingresar a OWA con `usuario1` y enviar correo a `usuario2`.
* Confirmar recepción y contestar.

---

## 9. Buenas Prácticas de Laboratorio

* No deshabilitar IPv6.
* Instalar últimos Cumulative Updates de Exchange.
* Evitar relé SMTP abierto.
* Configurar exclusiones antivirus recomendadas por Microsoft.
* Usar cuentas con mínimo privilegio para administración.

---

## 10. Checklist Final

* [ ] Windows Server con IP fija configurada.
* [ ] AD DS, DNS y DHCP instalados y configurados.
* [ ] Zona DNS con registros `mail` y `autodiscover`.
* [ ] Exchange Server instalado (rol Mailbox).
* [ ] Dominios aceptados y política de direcciones configurados.
* [ ] 2 buzones de prueba creados.
* [ ] Windows 7 unido al dominio.
* [ ] Acceso a OWA y prueba de correo realizada.
* [ ] Validaciones con `ping`, `nslookup`, `Test-Mailflow` realizadas.

---

## 11. Cronograma de Entrega

* **Semana 1:** Configuración de VM1 (AD DS, DNS, DHCP).
* **Semana 2:** Instalación de Exchange Server.
* **Semana 3:** Configuración de buzones y unión de cliente Windows 7.
* **Semana 4:** Validaciones y entrega del informe con capturas.
* **Fecha límite:** **30 de octubre**.

---
