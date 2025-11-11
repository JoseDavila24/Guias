# 🚀 **GUÍA COMPLETA PASO A PASO - Exchange 2019 en Hyper-V**

## **FASE 1: PREPARACIÓN DEL ENTORNO HYPER-V**

### **1.1 Crear conmutador NAT para Internet temporal**
En el **HOST Hyper-V** (PowerShell como Administrador):

```powershell
# Crear conmutador interno
New-VMSwitch -Name "NAT-LAB" -SwitchType Internal

# Configurar IP para el adaptador virtual
New-NetIPAddress -IPAddress 192.168.10.1 -PrefixLength 24 -InterfaceAlias "vEthernet (NAT-LAB)"

# Crear NAT para salida a Internet
New-NetNAT -Name "NAT-LAB" -InternalIPInterfaceAddressPrefix 192.168.10.0/24
```

### **1.2 Crear la VM con el VHD existente**
1. Abre **Hyper-V Manager**
2. **Acción → Nueva → Máquina Virtual**
3. **Nombre**: `JMDC01`
4. **Generación**: **Generation 1** (compatible con VHD)
5. **Memoria**: 12288 MB (12 GB)
6. **Red**: `NAT-LAB`
7. **Disco duro virtual**: **Usar disco virtual existente** → selecciona tu VHD
8. **Finalizar**

---

## **FASE 2: CONFIGURACIÓN INICIAL DE WINDOWS SERVER**

### **2.1 Iniciar la VM y configurar red temporal**
Inicia sesión como **Administrator** y abre **PowerShell como Administrador**:

```powershell
# Configurar IP estática con gateway para Internet
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 192.168.10.20 -PrefixLength 24 -DefaultGateway 192.168.10.1

# DNS temporal para descargas
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 8.8.8.8, 1.1.1.1

# Verificar conectividad
Test-NetConnection 8.8.8.8
Test-NetConnection microsoft.com
```

### **2.2 Cambiar nombre del equipo**
```powershell
Rename-Computer -NewName "JMDC01" -Restart
```

---

## **FASE 3: DESCARGAR PRERREQUISITOS CON INTERNET**

### **3.1 Descargar e instalar componentes requeridos**
Después del reinicio, abre **PowerShell como Administrador**:

```powershell
# Habilitar TLS 1.2 para descargas seguras
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Descargar Visual C++ 2013
Invoke-WebRequest -Uri "https://download.microsoft.com/download/2/E/6/2E61CFA4-993B-4DD4-91DA-3737CD5CD6E3/vcredist_x64.exe" -OutFile "C:\vcredist_x64.exe"
Start-Process -FilePath "C:\vcredist_x64.exe" -ArgumentList "/quiet", "/norestart" -Wait

# Descargar UCMA
Invoke-WebRequest -Uri "https://download.microsoft.com/download/2/C/4/2C47A5C6-A2AE-4DAA-9A5C-2A6C2D5F0E14/SetupUcmaRuntime.exe" -OutFile "C:\SetupUcmaRuntime.exe"
Start-Process -FilePath "C:\SetupUcmaRuntime.exe" -ArgumentList "/quiet", "/norestart" -Wait

# Instalar .NET Framework 4.8 (si es necesario)
Enable-WindowsOptionalFeature -Online -FeatureName "NetFx4-AdvSrvs" -All
```

### **3.2 Instalar características de Windows**
```powershell
# Instalar características base
Install-WindowsFeature NET-Framework-45-Features, RSAT-ADDS, Web-Server, Web-Mgmt-Console, WAS-Process-Model -IncludeManagementTools

# Reiniciar para aplicar cambios
Restart-Computer
```

---

## **FASE 4: CAMBIO A RED AISLADA**

### **4.1 Crear conmutador interno aislado**
En el **HOST Hyper-V**:
1. **Hyper-V Manager → Virtual Switch Manager**
2. **Nuevo conmutador virtual → Internal**
3. **Nombre**: `Lab-Interno`
4. **Aceptar**

### **4.2 Cambiar configuración de red de la VM**
En la VM (**apagada**):
1. **Configuración → Red → Conmutador virtual**: `Lab-Interno`
2. **Aplicar**

### **4.3 Configurar red aislada en la VM**
Inicia la VM y en **PowerShell**:

```powershell
# Quitar gateway (sin Internet)
Remove-NetRoute -InterfaceAlias "Ethernet" -DestinationPrefix "0.0.0.0/0" -Confirm:$false

# Configurar DNS a sí mismo (para AD)
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 192.168.10.20

# Verificar configuración
Get-NetIPAddress
Get-DnsClientServerAddress
```

---

## **FASE 5: ACTIVE DIRECTORY**

### **5.1 Instalar AD DS y DNS**
```powershell
Install-WindowsFeature AD-Domain-Services, DNS -IncludeManagementTools
```

### **5.2 Promover a Controlador de Dominio**
```powershell
Install-ADDSForest -DomainName "jmrd.com" -DomainNetbiosName "JMRD" -InstallDns
```
- **Contraseña DSRM**: Define una que recuerdes (ej: `P@ssw0rd123!`)
- El servidor se reiniciará automáticamente

### **5.3 Verificar dominio**
Después del reinicio:
```powershell
Get-ADDomain
Get-DnsServerZone
```

### **5.4 Registrar DNS para Exchange**
```powershell
Add-DnsServerResourceRecordA -Name "mail" -ZoneName "jmrd.com" -IPv4Address 192.168.10.20
Add-DnsServerResourceRecordCName -Name "autodiscover" -HostNameAlias "mail.jmrd.com" -ZoneName "jmrd.com"

# Verificar
nslookup mail.jmrd.com
nslookup autodiscover.jmrd.com
```

---

## **FASE 6: PREPARACIÓN PARA EXCHANGE**

### **6.1 Montar ISO de Exchange**
En Hyper-V Manager:
1. **Medios → Unidad de DVD → Insertar disco**
2. Selecciona tu **ISO de Exchange 2019**

### **6.2 Preparar Active Directory**
En **PowerShell como Administrador**, navega a la unidad del DVD de Exchange:

```powershell
# Cambiar a unidad del DVD (normalmente E:)
E:

# Preparar esquema y AD
.\Setup.exe /PrepareSchema /IAcceptExchangeServerLicenseTerms_DiagnosticDataOFF
.\Setup.exe /PrepareAD /OrganizationName:"JMRDOrg" /IAcceptExchangeServerLicenseTerms_DiagnosticDataOFF
.\Setup.exe /PrepareAllDomains /IAcceptExchangeServerLicenseTerms_DiagnosticDataOFF
```

---

## **FASE 7: INSTALACIÓN DE EXCHANGE 2019**

### **7.1 Instalar Exchange**
```powershell
# Instalar rol Mailbox
.\Setup.exe /Mode:Install /Roles:Mailbox /IAcceptExchangeServerLicenseTerms_DiagnosticDataOFF
```

**⚠️ Esto tomará 30-60 minutos.** No interrumpas el proceso.

### **7.2 Verificar instalación**
```powershell
Get-ExchangeServer
Get-Service *exchange*
```

---

## **FASE 8: CONFIGURACIÓN POST-INSTALACIÓN**

### **8.1 Configurar dominio aceptado y política**
```powershell
# Dominio aceptado
New-AcceptedDomain -Name "JMRD" -DomainName "jmrd.com" -DomainType Authoritative

# Política de direcciones de correo
Set-EmailAddressPolicy "Default Policy" -EnabledEmailAddressTemplates "SMTP:%g.%s@jmrd.com"
```

### **8.2 Configurar URLs internas**
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

### **8.3 Crear certificado autofirmado**
```powershell
# Crear certificado
$cert = New-SelfSignedCertificate -DnsName "mail.jmrd.com","autodiscover.jmrd.com" -CertStoreLocation "cert:\LocalMachine\My"

# Asignar a servicios Exchange
Enable-ExchangeCertificate -Thumbprint $cert.Thumbprint -Services "IIS,SMTP" -Force

# Reiniciar servicios
Restart-Service MSExchange*
```

### **8.4 Crear buzones de prueba**
```powershell
# Habilitar característica de contraseña en texto plano para el laboratorio
Set-ADDefaultDomainPasswordPolicy -Identity jmrd.com -ComplexityEnabled $false -MinPasswordLength 6

# Crear usuarios
New-Mailbox -Name "Usuario1" -UserPrincipalName usuario1@jmrd.com -Password (ConvertTo-SecureString "P@ssw0rd!" -AsPlainText -Force)
New-Mailbox -Name "Usuario2" -UserPrincipalName usuario2@jmrd.com -Password (ConvertTo-SecureString "P@ssw0rd!" -AsPlainText -Force)
```

---

## **FASE 9: PRUEBAS FINALES**

### **9.1 Probar OWA y ECP**
Abre **Internet Explorer** en la VM:
```
https://mail.jmrd.com/owa
https://mail.jmrd.com/ecp
```
- **Acepta** el certificado de seguridad
- Inicia sesión con `usuario1@jmrd.com` / `P@ssw0rd!`

### **9.2 Validaciones técnicas**
```powershell
# Servicios
Test-ServiceHealth

# Flujo de correo
Test-Mailflow

# Conectividad
Test-NetConnection mail.jmrd.com -Port 443
Test-NetConnection autodiscover.jmrd.com -Port 443

# DNS
Resolve-DnsName mail.jmrd.com
Resolve-DnsName autodiscover.jmrd.com
```

---

## **✅ CHECKLIST FINAL**

- [ ] VM creada con conmutador NAT temporal
- [ ] Prerrequisitos descargados e instalados
- [ ] Red cambiada a aislada (`Lab-Interno`)
- [ ] Active Directory instalado (`jmrd.com`)
- [ ] DNS configurado para Exchange
- [ ] Exchange 2019 instalado correctamente
- [ ] URLs internas configuradas
- [ ] Certificado creado y asignado
- [ ] Buzones de prueba creados
- [ ] OWA y ECP funcionando
- [ ] Envío de correos funcionando
