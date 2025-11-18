# 🚀 **GUÍA TÉCNICA COMPLETA - Sophos XG Firewall en Entorno AISLADO Exchange 2019**

## **CONTEXTO Y OBJETIVIVOS**
**Implementación segura de Sophos XG Firewall sin afectar host principal**, manteniendo funcionalidad completa de Exchange 2019 y Active Directory existentes.

---

## **FASE 1: INFRAESTRUCTURA DE RED AISLADA**

### **1.1 Crear conmutador NAT dedicado para Sophos**
En **HOST Hyper-V (PowerShell como Administrador)**:

```powershell
# Crear conmutador NAT exclusivo para Sophos
New-VMSwitch -Name "Sophos-NAT" -SwitchType Internal

# Configurar IP del adaptador virtual
New-NetIPAddress -IPAddress 192.168.100.1 -PrefixLength 24 -InterfaceAlias "vEthernet (Sophos-NAT)"

# Crear NAT para Internet
New-NetNAT -Name "Sophos-NAT" -InternalIPInterfaceAddressPrefix 192.168.100.0/24

# Verificar creación
Get-VMSwitch | Where-Object {$_.Name -like "*Sophos*"}
Get-NetNAT | Where-Object {$_.Name -like "*Sophos*"}
```

### **1.2 Verificar red laboratorio existente**
```powershell
# Confirmar que red Lab-Interno sigue intacta
Get-VMSwitch | Where-Object {$_.Name -like "*Interno*"}
Get-NetIPAddress -InterfaceAlias "vEthernet (Lab-Interno)" -AddressFamily IPv4
```

---

## **FASE 2: INSTALACIÓN Y CONFIGURACIÓN DE SOPHOS XG**

### **2.1 Crear VM para Sophos XG**
**En Hyper-V Manager**:
1. **Nueva → Máquina Virtual**
2. **Nombre**: `Sophos-XG`
3. **Generación**: Generation 2
4. **Memoria**: 4096 MB
5. **Red**: 
   - **Adaptador 1**: `Sophos-NAT` (WAN)
   - **Adaptador 2**: `Lab-Interno` (LAN)
6. **Disco duro**: 40 GB
7. **Imagen ISO**: Seleccionar Sophos XG Firewall ISO

### **2.2 Instalación de Sophos XG**
**En consola de Sophos**:
1. **Installation type**: Complete
2. **Network configuration**:
   - **Port A (WAN)**: DHCP (obtendrá 192.168.100.x)
   - **Port B (LAN)**: Configurar estático
     - **IP**: 172.16.20.1
     - **Máscara**: 255.255.255.0
     - **Gateway**: dejar vacío
3. **Admin password**: Establecer `P@ssw0rd123!`
4. **Fecha/Hora**: Configurar correctamente
5. **Finalizar instalación**

### **2.3 Configuración inicial vía WebAdmin**
**Desde host principal, navegar a**: `https://172.16.20.1:4444`

```powershell
# Desde HOST verificar conectividad
Test-NetConnection 172.16.20.1 -Port 4444
```

**Configuración en WebAdmin**:
1. **Administration → Device Access**: Habilitar HTTPS
2. **Network → Interfaces**:
   - **Port A (WAN)**: Confirmar IP via DHCP (192.168.100.x)
   - **Port B (LAN)**: Confirmar 172.16.20.1/24
3. **Guardar configuración**

---

## **FASE 3: CONFIGURACIÓN DE SERVIDOR EXISTENTE**

### **3.1 Reconfigurar red de Windows Server**
**En JMDC01 (PowerShell como Administrador)**:

```powershell
# Ver configuración actual
Get-NetIPConfiguration

# Cambiar IP a nueva red
Remove-NetIPAddress -InterfaceAlias "Ethernet" -Confirm:$false
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 172.16.20.10 -PrefixLength 24 -DefaultGateway 172.16.20.1

# Configurar DNS (apuntar a sí mismo + Sophos)
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 172.16.20.10, 172.16.20.1

# Verificar conectividad con Sophos
Test-NetConnection 172.16.20.1
Test-NetConnection 8.8.8.8

# Reiniciar servicios de red críticos
Restart-Service DNS
Restart-Service Netlogon
```

### **3.2 Verificar servicios post-cambio**
```powershell
# Verificar AD
Get-ADDomain
Get-ADDomainController

# Verificar Exchange
Get-ExchangeServer
Get-Service *exchange*

# Verificar DNS
Get-DnsServerZone
Resolve-DnsName google.com
```

---

## **FASE 4: CONFIGURACIÓN AVANZADA DE SOPHOS XG**

### **4.1 Configurar DNS Forwarding en Sophos**
**En WebAdmin Sophos**:
1. **Network → DNS**:
   - **DNS Server 1**: 172.16.20.10 (JMDC01)
   - **DNS Server 2**: 8.8.8.8
   - **Domain suffix**: jmrd.com
2. **DNS Host entries**:
   - **mail.jmrd.com** → 172.16.20.10
   - **autodiscover.jmrd.com** → 172.16.20.10
3. **Aplicar configuración**

### **4.2 Configurar reglas de firewall y NAT**
**En WebAdmin Sophos**:

#### **Regla LAN a WAN**:
1. **Firewall → Add firewall rule**:
   - **Name**: "LAN to WAN Internet"
   - **Source Zone**: LAN
   - **Source Networks**: 172.16.20.0/24
   - **Destination Zone**: WAN
   - **Services**: HTTP, HTTPS, DNS
   - **Action**: Allow
   - **Logging**: Enabled

#### **Regla para servicios internos**:
1. **Firewall → Add firewall rule**:
   - **Name**: "Internal Services"
   - **Source Zone**: LAN
   - **Source Networks**: 172.16.20.0/24
   - **Destination Zone**: LAN
   - **Services**: Any
   - **Action**: Allow

### **4.3 Configurar autenticación LDAP con AD**
**En WebAdmin Sophos**:
1. **Authentication → Servers → Add**:
   - **Name**: "AD-jmrd"
   - **Type**: Active Directory
   - **Server**: 172.16.20.10
   - **Port**: 389
   - **Base DN**: DC=jmrd,DC=com
   - **Bind DN**: administrator@jmrd.com
   - **Password**: [Contraseña del administrador]
2. **Test connection** → Verificar éxito
3. **User → Import users** → Seleccionar dominio jmrd.com

---

## **FASE 5: POLÍTICAS DE FILTRADO WEB**

### **5.1 Crear políticas de filtrado por categorías**
**En WebAdmin Sophos**:

#### **Política base para todo el dominio**:
1. **Web → Policy → Add**:
   - **Name**: "Block Social Media & Games"
   - **Position**: Top
   - **Action**: Block
   - **Categories**: 
     - Social Networking
     - Online Gaming
     - Gambling
     - File Sharing
   - **Apply to**: All users
   - **Schedule**: Always
   - **Block page**: Custom message

#### **Política de filtrado para usuarios específicos**:
1. **Web → Policy → Add**:
   - **Name**: "Standard User Web Access"
   - **Action**: Allow with filtering
   - **Users/Groups**: Domain Users
   - **Categories**: Block inappropriate categories
   - **Application Filtering**: Block streaming media alta prioridad

### **5.2 Configurar páginas de bloqueo personalizadas**
```powershell
# En JMDC01, crear página personalizada para Sophos
$BlockPageHTML = @"
<!DOCTYPE html>
<html>
<head>
    <title>Acceso Bloqueado - JMRD Corporation</title>
    <style>body{font-family:Arial,sans-serif;text-align:center;padding:50px;}</style>
</head>
<body>
    <h2>🚫 Acceso Bloqueado por Política Corporativa</h2>
    <p>El sitio solicitado ha sido bloqueado según las políticas de seguridad de JMRD.</p>
    <p>Usuario: %user% | Categoría: %category%</p>
</body>
</html>
"@

$BlockPageHTML | Out-File "C:\Sophos-Block-Page.html" -Encoding UTF8
```

**En Sophos WebAdmin**:
1. **Web → Block page → Custom**:
   - **Upload file**: Seleccionar C:\Sophos-Block-Page.html
   - **Assign to policies**: Todas las políticas de bloqueo

---

## **FASE 6: CLIENTES DE PRUEBA Y VERIFICACIÓN**

### **6.1 Crear VM cliente Windows**
**En Hyper-V Manager**:
1. **Nueva → Máquina Virtual**
2. **Nombre**: `Win10-Client01`
3. **Red**: `Lab-Interno`
4. **Sistema operativo**: Windows 10

### **6.2 Configurar cliente y unir al dominio**
**En VM cliente (PowerShell)**:
```powershell
# Configurar red
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 172.16.20.20 -PrefixLength 24 -DefaultGateway 172.16.20.1
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 172.16.20.10

# Unir al dominio
Add-Computer -DomainName "jmrd.com" -Credential (Get-Credential) -Restart

# Después del reinicio, verificar
Test-NetConnection 172.16.20.1
Test-NetConnection 8.8.8.8
Resolve-DnsName mail.jmrd.com
```

### **6.3 Crear usuarios de prueba en AD**
**En JMDC01 (PowerShell)**:
```powershell
# Crear usuarios para pruebas de filtrado
New-ADUser -Name "Juan Perez" -SamAccountName "juan.perez" -UserPrincipalName "juan.perez@jmrd.com" -Enabled $true -AccountPassword (ConvertTo-SecureString "P@ssw0rd!" -AsPlainText -Force)

New-ADUser -Name "Maria Lopez" -SamAccountName "maria.lopez" -UserPrincipalName "maria.lopez@jmrd.com" -Enabled $true -AccountPassword (ConvertTo-SecureString "P@ssw0rd!" -AsPlainText -Force)

# Verificar creación
Get-ADUser -Filter {Name -like "*Juan*"} -Properties *
```

---

## **FASE 7: VERIFICACIONES Y PRUEBAS FINALES**

### **7.1 Pruebas de conectividad desde cliente**
**En VM cliente**:
```powershell
# Pruebas básicas
Test-NetConnection 172.16.20.1      # Sophos
Test-NetConnection 172.16.20.10     # JMDC01
Test-NetConnection 8.8.8.8          # Internet
Test-NetConnection google.com       # DNS

# Pruebas Exchange
Test-NetConnection mail.jmrd.com -Port 443
Test-NetConnection autodiscover.jmrd.com -Port 443

# Navegación web
Start-Process "https://mail.jmrd.com/owa"
Start-Process "https://google.com"
```

### **7.2 Pruebas de filtrado web**
**Verificar bloqueos**:
- Intentar acceder a **facebook.com** → Debe mostrar página de bloqueo
- Intentar acceder a **twitter.com** → Debe mostrar página de bloqueo
- Acceder a **microsoft.com** → Debe permitir acceso

### **7.3 Monitoreo en Sophos**
**En WebAdmin Sophos**:
1. **Log & Report → Live Logs**: Ver tráfico en tiempo real
2. **Log & Report → Reports**: Generar reportes de actividad
3. **Monitor → Dashboard**: Ver estado general del sistema

### **7.4 Verificación final de servicios**
**En JMDC01**:
```powershell
# Servicios críticos
Test-ServiceHealth                    # Exchange
Test-Mailflow                         # Flujo de correo
Get-ADDomain                          # Active Directory
Get-DnsServerZone                     # DNS

# Conectividad completa
Test-NetConnection 172.16.20.1 -Port 4444    # Sophos Admin
Test-NetConnection mail.jmrd.com -Port 443   # OWA
Test-NetConnection 8.8.8.8 -Port 53          # DNS externo
```

---

## **✅ CHECKLIST DE VERIFICACIÓN FINAL**

- [ ] **Host principal** mantiene conexión Internet intacta
- [ ] **Sophos XG** instalado y accesible vía WebAdmin
- [ ] **Windows Server JMDC01** funciona en nueva IP (172.16.20.10)
- [ ] **Servicios AD/DNS/Exchange** operativos
- [ ] **Clientes** pueden navegar Internet via Sophos
- [ ] **Filtrado web** bloquea categorías configuradas
- [ ] **Autenticación LDAP** funcionando con AD
- [ ] **Páginas de bloqueo** personalizadas mostrándose
- [ ] **Logs y reportes** generándose en Sophos
- [ ] **Exchange OWA** accesible internamente

---

## **TROUBLESHOOTING COMÚN**

### **Problema: No hay Internet desde clientes**
```powershell
# Verificar gateway
Get-NetRoute -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -eq "Ethernet"}

# Verificar DNS
Get-DnsClientServerAddress -InterfaceAlias "Ethernet"

# Verificar reglas Sophos
# En WebAdmin: Revisar reglas LAN to WAN y políticas web
```

### **Problema: Exchange no funciona**
```powershell
# Verificar URLs
Get-OWAVirtualDirectory | Select-Object InternalURL
Get-WebServicesVirtualDirectory | Select-Object InternalURL

# Verificar certificados
Get-ExchangeCertificate | Where-Object {$_.Services -match "IIS"}

# Reasignar certificado si es necesario
$cert = Get-ExchangeCertificate | Where-Object {$_.Services -match "IIS"}
Enable-ExchangeCertificate -Thumbprint $cert.Thumbprint -Services IIS -Force
```

Esta implementación garantiza **aislamiento completo** del host principal mientras proporciona **Internet controlado y filtrado** para el laboratorio Exchange 2019.
