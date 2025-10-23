# Guía: Exchange 2019 en **UNA sola VM** (Hyper-V) con dominio **jmrd.com**

## 0) Requisitos rápidos

* **VHD**: `17763.737...server_serverdatacentereval_en-us_1.vhd` (Windows Server 2019).
* **Hyper-V**: host con el rol habilitado.
* **VM**: 2–4 vCPU, **12–16 GB RAM** recomendado (mín. 8 GB para lab chico), **120–160 GB** de disco.
* **ISO de Exchange 2019/SE** disponible dentro de la VM (montarlo).
* **Red de lab**: aislada, p. ej. `192.168.10.0/24` (sin Internet).
* **Nota de lab**: En laboratorio es aceptable instalar Exchange en un **controlador de dominio** (en producción no se recomienda).

---

## 1) Hyper-V: crear la VM con tu VHD

### 1.1 Conmutador virtual aislado

1. Hyper-V Manager → **Virtual Switch Manager** → **New virtual network switch**.
2. Tipo **Internal** → Nombre: `Lab-Interno` → **OK**.

   * *Internal*: VM↔Host (útil para copiar ISOs desde el host).
   * *Private*: aísla de todo (si no necesitas acceso al host).

### 1.2 Crear la VM (usando el VHD existente)

1. **New → Virtual Machine…**
2. **Name**: `JMDC01`
3. **Generation**: **Generation 1** (recomendado para VHD).

   * (Opcional) Si conviertes a **VHDX**, podrás usar **Generation 2**:
     `Convert-VHD -Path "C:\ruta\server.vhd" -DestinationPath "C:\ruta\server.vhdx" -VHDType Dynamic`
4. **Memory**: 12288–16384 MB.
5. **Network**: `Lab-Interno`.
6. **Virtual hard disk**: **Use an existing virtual hard disk** → selecciona tu **VHD**.
7. **Settings**: 2–4 vCPU, disco como primer boot. (Si Gen2: desactiva Secure Boot si hay problema de arranque).

> Sugerencia: crea un **Checkpoint** antes de instalar Exchange.

---

## 2) Configuración inicial en Windows Server (dentro de la VM)

Inicia sesión como **Administrator**.

### 2.1 IP estática y DNS apuntando a sí mismo

```powershell
Get-NetAdapter
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 192.168.10.20 -PrefixLength 24 -DefaultGateway 192.168.10.1
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 192.168.10.20
```

> El **DNS** debe ser **192.168.10.20** (este servidor), clave para AD/Exchange.

### 2.2 Nombre del equipo (opcional recomendado)

```powershell
Rename-Computer -NewName "JMDC01" -Restart
```

---

## 3) Active Directory para **jmrd.com**

### 3.1 Instalar AD DS + DNS

```powershell
Install-WindowsFeature AD-Domain-Services, DNS -IncludeManagementTools
```

### 3.2 Promover a **Controlador de Dominio** (nuevo bosque)

```powershell
Install-ADDSForest -DomainName "jmrd.com" -DomainNetbiosName "JMRD" -InstallDns
```

* Define la contraseña **DSRM** cuando lo pida.
* El servidor **se reinicia** como DC.

### 3.3 DNS interno para Exchange

```powershell
Add-DnsServerResourceRecordA -Name "mail" -ZoneName "jmrd.com" -IPv4Address 192.168.10.20
Add-DnsServerResourceRecordCName -Name "autodiscover" -HostNameAlias "mail.jmrd.com" -ZoneName "jmrd.com"
```

*(Opcional)* Instalar DHCP solo si luego agregarás clientes:

```powershell
Install-WindowsFeature DHCP -IncludeManagementTools
Add-DhcpServerInDC -DnsName "JMDC01.jmrd.com" -IpAddress 192.168.10.20
Add-DhcpServerv4Scope -Name "ScopeJMRD" -StartRange 192.168.10.50 -EndRange 192.168.10.100 -SubnetMask 255.255.255.0 -State Active
Set-DhcpServerv4OptionValue -OptionId 3 -Value 192.168.10.1
Set-DhcpServerv4OptionValue -OptionId 6 -Value 192.168.10.20
Set-DhcpServerv4OptionValue -OptionId 15 -Value "jmrd.com"
```

---

## 4) Prerrequisitos del sistema para Exchange (lab)

> Exchange agregará otros si faltan; con esto suele bastar en laboratorio.

```powershell
Install-WindowsFeature NET-Framework-45-Features, RSAT-ADDS, Web-Server, Web-Mgmt-Console, WAS-Process-Model -IncludeManagementTools
```

Monta el **ISO de Exchange 2019** (Mount) antes del siguiente paso.

---

## 5) Preparar Active Directory para Exchange

En la carpeta del `Setup.exe` de Exchange (PowerShell como Admin):

```powershell
Setup.exe /PrepareSchema /IAcceptExchangeServerLicenseTerms_DiagnosticDataOFF
Setup.exe /PrepareAD /OrganizationName:"JMRDOrg" /IAcceptExchangeServerLicenseTerms_DiagnosticDataOFF
Setup.exe /PrepareAllDomains /IAcceptExchangeServerLicenseTerms_DiagnosticDataOFF
```

---

## 6) Instalar Exchange 2019 (rol **Mailbox**)

```powershell
Setup.exe /Mode:Install /Roles:Mailbox /IAcceptExchangeServerLicenseTerms_DiagnosticDataOFF
```

---

## 7) Post-configuración de Exchange

### 7.1 Dominios aceptados + política de direcciones

```powershell
New-AcceptedDomain -Name "JMRD" -DomainName "jmrd.com" -DomainType Authoritative
Set-EmailAddressPolicy "Default Policy" -EnabledEmailAddressTemplates "SMTP:%g.%s@jmrd.com"
```

### 7.2 URLs internas (OWA/ECP/EWS/AS/OAB) a `mail.jmrd.com`

```powershell
# Autodiscover
Set-ClientAccessService -Identity (Get-ClientAccessService).Name -AutoDiscoverServiceInternalUri https://autodiscover.jmrd.com/Autodiscover/Autodiscover.xml

# OWA y ECP
Get-OWAVirtualDirectory | Set-OWAVirtualDirectory -InternalUrl https://mail.jmrd.com/owa
Get-EcpVirtualDirectory | Set-EcpVirtualDirectory -InternalUrl https://mail.jmrd.com/ecp

# EWS / ActiveSync / OAB
Get-WebServicesVirtualDirectory | Set-WebServicesVirtualDirectory -InternalUrl https://mail.jmrd.com/EWS/Exchange.asmx
Get-ActiveSyncVirtualDirectory | Set-ActiveSyncVirtualDirectory -InternalUrl https://mail.jmrd.com/Microsoft-Server-ActiveSync
Get-OabVirtualDirectory | Set-OabVirtualDirectory -InternalUrl https://mail.jmrd.com/OAB
```

### 7.3 Certificado autofirmado (rápido para lab) y asignación

```powershell
$cert = New-SelfSignedCertificate -DnsName "mail.jmrd.com","autodiscover.jmrd.com" -CertStoreLocation "cert:\LocalMachine\My"
Enable-ExchangeCertificate -Thumbprint $cert.Thumbprint -Services "IIS,SMTP" -Force
# (Opcional) iisreset
```

### 7.4 Buzones de prueba

```powershell
New-Mailbox -Name "Usuario1" -UserPrincipalName usuario1@jmrd.com -Password (ConvertTo-SecureString "P@ssw0rd!" -AsPlainText -Force)
New-Mailbox -Name "Usuario2" -UserPrincipalName usuario2@jmrd.com -Password (ConvertTo-SecureString "P@ssw0rd!" -AsPlainText -Force)
```

---

## 8) Pruebas (todo desde la misma VM)

### 8.1 OWA/ECP

En el navegador:

```
https://mail.jmrd.com/owa   (correo)
https://mail.jmrd.com/ecp   (administración)
```

* Acepta el **certificado autofirmado**.
* Inicia con `usuario1@jmrd.com` (ventana normal) y `usuario2@jmrd.com` (ventana privada/otro perfil).

### 8.2 Validaciones útiles

```powershell
ping mail.jmrd.com
Test-NetConnection mail.jmrd.com -Port 443
nslookup mail.jmrd.com
nslookup autodiscover.jmrd.com
Test-ServiceHealth
Test-Mailflow
```

* `Test-ServiceHealth` → servicios de Exchange en **Running**.
* `Test-Mailflow` → prueba de envío interno OK.

---

## 9) Consideraciones de red en Hyper-V

* **Conmutador**: `Internal` (VM↔Host) es suficiente para este lab.
* **Firewall**: si algo no carga, revisa **443 (IIS/OWA)** y **25 (SMTP)**.
* **Hora**: mantén **Time Synchronization** (evita fallos de autenticación).
* **IPv6**: **no lo deshabilites**.
* **Checkpoints**: crea uno antes de instalar Exchange o cambios grandes.
* **Split-DNS** a futuro: si registras `jmrd.com` público, usa DNS dividido o un sufijo distinto para el lab.

---

## 10) Checklist exprés

* [ ] VM creada (Gen1 con VHD) y conectada a `Lab-Interno`.
* [ ] IP fija `192.168.10.20` y DNS a sí mismo.
* [ ] AD DS + DNS instalados; dominio `jmrd.com` creado; servidor promovido a DC.
* [ ] DNS: `mail` (A) y `autodiscover` (CNAME) apuntan a 192.168.10.20.
* [ ] Prerrequisitos de Windows para Exchange instalados.
* [ ] Exchange 2019 (Mailbox) instalado.
* [ ] Accepted Domain + Email Address Policy configurados.
* [ ] URLs internas (OWA/ECP/EWS/ActiveSync/OAB) en `mail.jmrd.com`.
* [ ] Certificado autofirmado instalado y asignado a IIS/SMTP.
* [ ] Buzones `usuario1` y `usuario2` creados.
* [ ] OWA funcionando y correo ida/vuelta.
* [ ] `Test-ServiceHealth` y `Test-Mailflow` OK.

---
