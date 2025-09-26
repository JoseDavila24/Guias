# Manual de prácticas: Correo corporativo **activo** con Microsoft Exchange Server sobre Windows Server

**Materia:** Sistemas Operativos y Redes
**Entrega límite:** **30 de octubre**
**Ámbito:** Laboratorio académico (entorno aislado)

---

## 1. Objetivo

Implementar un sistema de **correo corporativo activo** en un entorno Windows, instalando y configurando **DHCP**, **DNS**, **Active Directory (AD DS)** y **Exchange Server**, para crear buzones bajo un dominio ficticio con iniciales del alumno y validar el envío/recepción interno mediante un cliente Windows y **OWA (Outlook Web App)**.

---

## 2. Arquitectura y alcance

**Topología mínima (3 VMs):**

* **DC01** – Controlador de dominio con **AD DS**, **DNS** y **DHCP**
  IP sugerida: `192.168.10.10/24`
* **EX01** – Servidor **Exchange** (rol Mailbox, que incluye servicios de acceso de cliente)
  IP sugerida: `192.168.10.20/24`
* **CL01** – Cliente Windows 10/11 unido al dominio

**Dominio interno sugerido:** `JPL.lab` (o `<INICIALES>.lab`).

> Nota: Para laboratorio interno evite dominios públicos reales (p. ej. `*.com`). Si el docente requiere `JPL.com`, implemente **Split-DNS** creando la zona interna `JPL.com` en su DNS.

---

## 3. ¿Qué hace cada servicio?

* **DHCP:** asigna IPs y opciones (puerta de enlace, DNS, sufijo de dominio) a clientes automáticamente.
* **DNS:** resuelve nombres (inicia sesión, localiza controladores de dominio, `mail`, `autodiscover`, etc.).
* **Active Directory (AD DS):** almacén de identidades, políticas y objetos; Exchange se integra y **depende** de AD.
* **Exchange Server:** plataforma de correo. En Exchange 2019/SE el **rol Mailbox** incluye transporte, bases y acceso de cliente (OWA/EAS/Mapi). ([Practical 365][1])

---

## 4. Requisitos de software/hardware (laboratorio)

* Windows Server 2019 o 2022 para **DC01** y **EX01**; Windows 10/11 para **CL01**.
* ISO de **Exchange Server 2019** (o **Subscription Edition** para fines didácticos) con CU reciente. Requisitos y prerrequisitos oficiales (características de Windows, VC++ 2012/2013, Media Foundation, UCMA) en la guía de Microsoft. ([Microsoft Learn][2])
* No deshabilite **IPv6** en Windows/Exchange (recomendación de Microsoft). ([Microsoft Learn][3])

---

## 5. Preparación inicial (todos los servidores)

1. Ponga **IP estática**:

   * **DC01:** DNS preferido `127.0.0.1` (o su propia IP después de instalar DNS).
   * **EX01:** DNS preferido **DC01** (`192.168.10.10`).
2. Renombre equipos (ej.: `DC01`, `EX01`, `CL01`) y reinicie.
3. Tome **instantánea** de las VMs antes de cada hito.

**Pantallazos sugeridos:** `ipconfig /all` de cada VM antes/después.

---

## 6. Instalación de **AD DS** y **DNS** (en DC01)

### 6.1. Instalar roles

En PowerShell (administrador):

```powershell
Install-WindowsFeature AD-Domain-Services, DNS -IncludeManagementTools
```

### 6.2. Promover a **nuevo bosque** con DNS integrado

```powershell
Install-ADDSForest -DomainName "JPL.lab" -DomainNetbiosName "JPL" -InstallDNS
```

(Se solicitará la contraseña DSRM y reiniciará.) ([Microsoft Learn][4])

**Pantallazos sugeridos:** asistente de promoción (resumen), reinicio y `Server Manager` mostrando AD DS/DNS.

---

## 7. Configuración de **DHCP** (en DC01)

### 7.1. Instalar y **autorizar** DHCP en AD

```powershell
Install-WindowsFeature DHCP -IncludeManagementTools
# Autorizar el servidor DHCP en el dominio
Add-DhcpServerInDC -DnsName "DC01.JPL.lab" -IPAddress 192.168.10.10
```

([Microsoft Learn][5])

### 7.2. Crear **scope** IPv4 y opciones

```powershell
Add-DhcpServerv4Scope -Name "LAB-RED" -StartRange 192.168.10.50 -EndRange 192.168.10.200 -SubnetMask 255.255.255.0
Set-DhcpServerv4OptionValue -DnsServer 192.168.10.10 -DnsDomain "JPL.lab" -Router 192.168.10.1
```

([Microsoft Learn][6])

**Pantallazos sugeridos:** consola DHCP mostrando ámbito y opciones 003/006/015.

---

## 8. DNS para Exchange (en DC01)

> Si usa `JPL.com` como **dominio ficticio**, cree la **zona directa** `JPL.com` (Split-DNS).

Crear zona (si no existe) y registros para Exchange:

```powershell
# (opcional si no existe) zona directa
Add-DnsServerPrimaryZone -Name "JPL.lab" -ReplicationScope "Domain"

# A de Exchange
Add-DnsServerResourceRecordA -Name "mail" -ZoneName "JPL.lab" -IPv4Address 192.168.10.20

# CNAME Autodiscover → mail
Add-DnsServerResourceRecordCName -Name "autodiscover" -ZoneName "JPL.lab" -HostNameAlias "mail.JPL.lab"
```

([CloudTechAdmin][7])

> **Nota:** no cree CNAME en el **apex** de la zona (p. ej. `JPL.lab`) por restricciones DNS. Use `autodiscover.JPL.lab`. ([Server Fault][8])

**Pantallazos sugeridos:** zona `JPL.lab` con `mail` (A) y `autodiscover` (CNAME).

---

## 9. Unir **EX01** y **CL01** al dominio

En cada equipo:

```powershell
Add-Computer -DomainName "JPL.lab" -Credential JPL\Administrator -Restart
```

(Use cuentas con privilegios para unir al dominio.)

---

## 10. Prerrequisitos de **Exchange Server** (en EX01)

### Opción recomendada (rápida)

Deje que **Setup** instale los componentes de Windows con la opción **/InstallWindowsComponents** o marque el check en el asistente. ([Microsoft Learn][2])

### Opción “manual” (formativa)

Instale los prerrequisitos que Microsoft documenta para el rol **Mailbox** (Media Foundation, UCMA, IIS/ASP.NET/HTTP Activation, etc.). Ejemplo (extracto):

```powershell
Install-WindowsFeature Server-Media-Foundation
# Paquetes VC++ 2012/2013 y UCMA desde \UCMARedist del medio de Exchange (según guía)
# Conjunto completo de características web / .NET si no usa /InstallWindowsComponents:
Install-WindowsFeature Server-Media-Foundation, NET-Framework-45-Core, NET-Framework-45-ASPNET, NET-WCF-HTTP-Activation45, `
WAS-Process-Model, Web-Server, Web-Asp-Net45, Web-Metabase, Web-ISAPI-Ext, Web-ISAPI-Filter, Web-Windows-Auth, `
Web-Basic-Auth, Web-Digest-Auth, Web-Http-Logging, Web-Stat-Compression, Web-Dyn-Compression, Web-Static-Content, `
Web-Mgmt-Console, Web-Mgmt-Service, Windows-Identity-Foundation, RSAT-ADDS
```

([Microsoft Learn][2])

> **Tip:** Mantenga Windows actualizado y el servicio **Remote Registry** en **Automático** (requisito de Setup). ([Microsoft Learn][2])

---

## 11. Preparar **Active Directory** para Exchange

Desde la ISO de Exchange (en **EX01** o un miembro del dominio):

```powershell
# Consola cmd/powershell en la raíz del medio de Exchange
Setup.exe /IAcceptExchangeServerLicenseTerms_DiagnosticDataOFF /PrepareSchema
Setup.exe /IAcceptExchangeServerLicenseTerms_DiagnosticDataOFF /PrepareAD /OrganizationName:"Org-JPL"
Setup.exe /IAcceptExchangeServerLicenseTerms_DiagnosticDataOFF /PrepareAllDomains
```

> Con CUs recientes, la aceptación de licencia se hace con los sufijos **_DiagnosticDataON/OFF**.

**Pantallazo sugerido:** salida de preparación correcta.

---

## 12. Instalar **Exchange Server** (rol Mailbox)

### 12.1. Instalación desatendida (sugerida)

```powershell
Setup.exe /IAcceptExchangeServerLicenseTerms_DiagnosticDataOFF /Mode:Install /Roles:Mailbox /InstallWindowsComponents
```

([Microsoft Learn][9])

> La instalación crea OWA/Outlook on the web en `https://EX01/owa` y EAC (Exchange Admin Center clásico) en `https://EX01/ecp`. ([Microsoft Learn][10])

**Pantallazos sugeridos:** fin de Setup, servicios en ejecución.

---

## 13. Configuración posterior mínima (laboratorio interno)

### 13.1. Dominio aceptado y política de direcciones

Asegure que el **dominio interno** sea **Accepted Domain** y que la **política de direcciones** asigne `@JPL.lab` (o `@JPL.com` si Split-DNS):

```powershell
# (si hiciera falta) añadir Accepted Domain
New-AcceptedDomain -Name "JPL-lab" -DomainName "JPL.lab" -DomainType Authoritative

# Forzar que la "Default Policy" asigne @JPL.lab a todos
Set-EmailAddressPolicy "Default Policy" -EnabledEmailAddressTemplates "SMTP:%g.%s@JPL.lab"
Update-EmailAddressPolicy "Default Policy"
```

([Microsoft Learn][11])

> **Formato del buzón del alumno:** use sus **iniciales**. Ej.: Juan Pérez López → dominio **JPL.lab**, buzón como `juan.perez@JPL.lab` o alias `JPL@JPL.lab` según indicación docente.

### 13.2. Crear usuarios y buzones

Opción 1 – crear usuario **y** buzón de una vez:

```powershell
# Reemplace nombres y contraseña
$pass = ConvertTo-SecureString "P@ssw0rd123" -AsPlainText -Force
New-Mailbox -Name "Juan Perez Lopez" -UserPrincipalName "juan.perez@JPL.lab" -Alias "juan.perez" -Password $pass
```

Opción 2 – usuario AD y luego habilitar buzón:

```powershell
$pass = ConvertTo-SecureString "P@ssw0rd123" -AsPlainText -Force
New-ADUser -Name "Juan Perez Lopez" -SamAccountName "juan.perez" -UserPrincipalName "juan.perez@JPL.lab" `
 -AccountPassword $pass -Enabled $true
Enable-Mailbox -Identity "juan.perez"
```

([Microsoft Learn][12])

**Pantallazos sugeridos:** lista de buzones en EAC/EMS.

---

## 14. Cliente Windows y **OWA**

1. **CL01** obtiene IP por **DHCP** y se une al dominio `JPL.lab`.
2. Inicie **Edge/Chrome** y acceda a **OWA**: `https://EX01/owa` (acepte certificado de laboratorio). Inicie sesión con `JPL\juan.perez`. ([Microsoft Learn][10])
3. Envíe un correo entre dos cuentas de prueba (por ejemplo, `juan.perez` ↔ `maria.lopez`) y verifique recepción.

**Pantallazos sugeridos:** inicio de sesión OWA y bandeja de entrada mostrando correo recibido.

---

## 15. **Pruebas y validación**

### 15.1. Red y DNS

```powershell
# Desde CL01 o EX01
ping DC01
ping EX01
nslookup JPL.lab
nslookup -type=a mail.JPL.lab
nslookup -type=cname autodiscover.JPL.lab
# Comprobar TLS/puerto
Test-NetConnection mail.JPL.lab -Port 443
```

### 15.2. Salud de servicios Exchange (EMS)

```powershell
# Servicios requeridos por rol
Test-ServiceHealth

# Mail flow interno (autoprueba)
Test-Mailflow

# Conectividad de Outlook (si aplica)
Test-OutlookConnectivity
```

([Microsoft Learn][13])

### 15.3. OWA

* Iniciar sesión y enviar/recibir (adjunte captura).
* Comprobar que el remitente/destinatario usan su dominio `@JPL.lab` (o `@JPL.com` si se pidió Split-DNS).

**Criterios de aceptación (mínimos):**

* Clientes obtienen IP vía **DHCP**.
* Resolución de `mail.<dominio>` y `autodiscover.<dominio>`.
* Envío y recepción **interno** OK (OWA y al menos un cliente Windows).
* `Test-ServiceHealth` y `Test-Mailflow` **sin errores**.

---

## 16. Buenas prácticas de administración y seguridad (mínimas para el laboratorio)

1. **Mantener CUs/actualizaciones** de Exchange y Windows al día. Use la guía de **instalación desatendida** para automatizar y documentar comandos de Setup/switches. ([Microsoft Learn][9])
2. **No deshabilitar IPv6** en servidores Windows/Exchange (recomendación Microsoft). ([Microsoft Learn][3])
3. **Antivirus:** configurar **exclusiones** recomendadas para Exchange (carpetas de base de datos, logs, colas, procesos). ([Microsoft Learn][14])
4. **TLS/certificados:** aunque en laboratorio puede bastar el certificado autofirmado, documente el **FQDN** usado por OWA y planifique un certificado válido si publica externamente.
5. **Principio de mínimo privilegio:** usar cuentas separadas para administración; no usar `Administrator` para tareas diarias.
6. **Respaldo** de bases de datos (conceptual en laboratorio): identifique ruta de `.edb` y logs; verifique montajes/desmontajes controlados.
7. **No abrir relé SMTP**: mantenga valores por defecto de conectores; por omisión no son open relay. ([Practical 365][1])

---

## 17. Entregables requeridos (formato proyecto académico)

1. **Portada** con datos del alumno, grupo, **fecha** y dominio elegido (`<INICIALES>.lab` o `JPL.com` Split-DNS).
2. **Bitácora paso a paso** con comandos utilizados y **pantallazos** sugeridos:

   * IP estáticas de DC01/EX01; `ipconfig /all` de CL01 por DHCP.
   * Promoción de **AD DS** (resumen), rol **DNS**, creación de zona y registros (`mail`, `autodiscover`).
   * Rol **DHCP**: ámbito y opciones (003, 006, 015).
   * Unión de EX01/CL01 al dominio.
   * **Setup de Exchange** (fin correcto).
   * Lista de **buzones** creados y **OWA** con correo enviado/recibido.
   * Pruebas: salidas de `nslookup`, `Test-ServiceHealth`, `Test-Mailflow`.
3. **Explicación breve** (1–2 párrafos por servicio) de **qué hace** y **por qué es necesario** (DHCP, DNS, AD, Exchange).
4. **Apartado de pruebas y validación** (qué se probó, resultados y evidencia).
5. **Buenas prácticas** aplicadas y pendientes para producción.

---

## 18. Apéndice: comandos de referencia

### 18.1. Alta rápida de dos buzones de prueba

```powershell
$pass = ConvertTo-SecureString "P@ssw0rd123" -AsPlainText -Force
New-Mailbox -Name "Juan Perez"  -UserPrincipalName "juan.perez@JPL.lab"  -Alias "juan.perez"  -Password $pass
New-Mailbox -Name "Maria Lopez" -UserPrincipalName "maria.lopez@JPL.lab" -Alias "maria.lopez" -Password $pass
```

### 18.2. URLs de administración y cliente

* **OWA:** `https://EX01/owa`
* **EAC (clásico):** `https://EX01/ecp` ([Microsoft Learn][10])

---

## 19. Referencias clave (Microsoft Learn)

* **Prerrequisitos Exchange 2019/SE** (características de Windows, VC++, UCMA, opciones de Setup). ([Microsoft Learn][2])
* **Preparar AD para Exchange** (conmutadores **/Prepare*** y aceptación de licencia con `_DiagnosticDataON/OFF`).
* **Instalación desatendida** (switches, ejemplos). ([Microsoft Learn][9])
* **Test-ServiceHealth** (servicios requeridos). ([Microsoft Learn][13])
* **Test-Mailflow** (envío/entrega internos). ([Microsoft Learn][15])
* **Test-OutlookConnectivity** (conectividad Outlook). ([Microsoft Learn][16])
* **DHCP con PowerShell** (despliegue/alcance/opciones). ([Microsoft Learn][17])
* **Add-DhcpServerv4Scope / Add-DhcpServerInDC** (cmdlets). ([Microsoft Learn][6])
* **Instalar bosque AD (Install-ADDSForest)**. ([Microsoft Learn][4])
* **OWA/ECP (URLs y conceptos)**. ([Microsoft Learn][10])
* **Accepted Domains / Email Address Policy**. ([Microsoft Learn][11])
* **Buenas prácticas AV/exclusiones en Exchange**. ([Microsoft Learn][14])
* **No deshabilitar IPv6**. ([Microsoft Learn][3])
* **Mail flow y conectores (visión)**. ([Practical 365][1])

---

### Checklist de verificación antes de entregar

* [ ] DHCP entrega IP, DNS y sufijo de dominio correctos a **CL01**.
* [ ] DNS resuelve `mail` y `autodiscover`.
* [ ] **EX01** instalado y **Test-ServiceHealth** OK.
* [ ] Buzones creados con el **dominio de iniciales** del alumno.
* [ ] OWA: envío/recepción **interno** exitoso con evidencias.
* [ ] Documento con secciones numeradas, pantallazos, comandos y referencias.

> Con esto el alumno demuestra el ciclo completo: **infraestructura base (DHCP/DNS/AD)** → **servidor de correo (Exchange)** → **clientes** → **pruebas y validación**, cumpliendo con la entrega del **30 de octubre**.

[1]: https://practical365.com/exchange-2019-mail-flow-and-transport-services/?utm_source=chatgpt.com "Exchange 2019 Mail Flow and Transport Services"
[2]: https://learn.microsoft.com/en-us/exchange/plan-and-deploy/prerequisites "Exchange Server prerequisites, Exchange 2019 system requirements, Exchange SE system requirements, Exchange 2019 requirements, Exchange SE requirements | Microsoft Learn"
[3]: https://learn.microsoft.com/en-us/troubleshoot/windows-server/networking/configure-ipv6-in-windows?utm_source=chatgpt.com "Configure IPv6 for advanced users - Windows Server"
[4]: https://learn.microsoft.com/en-us/powershell/module/addsdeployment/install-addsforest?view=windowsserver2025-ps "Install-ADDSForest (ADDSDeployment) | Microsoft Learn"
[5]: https://learn.microsoft.com/en-us/windows-server/networking/technologies/dhcp/quickstart-install-configure-dhcp-server?utm_source=chatgpt.com "Install and configure DHCP Server on Windows Server"
[6]: https://learn.microsoft.com/en-us/powershell/module/dhcpserver/add-dhcpserverv4scope?view=windowsserver2025-ps&utm_source=chatgpt.com "Add-DhcpServerv4Scope (DhcpServer)"
[7]: https://www.cloudtechadmin.com/configure-primary-zone-in-windows-dns-server/?utm_source=chatgpt.com "Configure Primary Zone in Windows DNS Server"
[8]: https://serverfault.com/questions/617002/small-issue-with-the-domain-name-system-dns-server-cmdlets?utm_source=chatgpt.com "Small issue with the Domain Name System (DNS) Server Cmdlets"
[9]: https://learn.microsoft.com/en-us/exchange/plan-and-deploy/deploy-new-installations/unattended-installs "Use unattended mode in Exchange Setup | Microsoft Learn"
[10]: https://learn.microsoft.com/en-us/exchange/clients/outlook-on-the-web/customize-outlook-on-the-web?utm_source=chatgpt.com "Customize the Outlook on the web sign-in, language ..."
[11]: https://learn.microsoft.com/en-us/powershell/module/exchangepowershell/new-accepteddomain?view=exchange-ps&utm_source=chatgpt.com "New-AcceptedDomain (ExchangePowerShell)"
[12]: https://learn.microsoft.com/en-us/powershell/module/activedirectory/new-aduser?view=windowsserver2025-ps&utm_source=chatgpt.com "New-ADUser (ActiveDirectory)"
[13]: https://learn.microsoft.com/en-us/powershell/module/exchangepowershell/test-servicehealth?view=exchange-ps&utm_source=chatgpt.com "Test-ServiceHealth (ExchangePowerShell)"
[14]: https://learn.microsoft.com/en-us/exchange/antispam-and-antimalware/windows-antivirus-software?utm_source=chatgpt.com "Running Windows antivirus software on Exchange servers"
[15]: https://learn.microsoft.com/en-us/powershell/module/exchangepowershell/test-mailflow?view=exchange-ps&utm_source=chatgpt.com "Test-Mailflow (ExchangePowerShell)"
[16]: https://learn.microsoft.com/en-us/powershell/module/exchangepowershell/test-outlookconnectivity?view=exchange-ps&utm_source=chatgpt.com "Test-OutlookConnectivity (ExchangePowerShell)"
[17]: https://learn.microsoft.com/en-us/windows-server/networking/technologies/dhcp/dhcp-deploy-wps?utm_source=chatgpt.com "Deploy DHCP Using Windows PowerShell"
