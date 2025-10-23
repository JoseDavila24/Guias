# 📋 Mini Guía: Gestión de Usuarios y Grupos en Exchange

---

## 🗑️ **1. ELIMINAR USUARIOS**

### Eliminar un usuario específico:
```powershell
Remove-Mailbox -Identity "NombreUsuario" -Confirm:$false
```
**Ejemplo:**
```powershell
Remove-Mailbox -Identity "UsuarioEliminar" -Confirm:$false
```

### Eliminar múltiples usuarios:
```powershell
$UsuariosEliminar = @("Usuario1", "Usuario2", "Usuario3")
foreach ($User in $UsuariosEliminar) {
    Remove-Mailbox -Identity $User -Confirm:$false
}
```

### Verificar usuarios existentes:
```powershell
Get-Mailbox | Select-Object Name, PrimarySmtpAddress
```

---

## 👥 **2. CREAR NUEVOS USUARIOS**

### Crear un usuario individual:
```powershell
New-Mailbox -Name "JuanPerez" -DisplayName "Juan Pérez" -UserPrincipalName "juanperez@jmrd.com" -Password (ConvertTo-SecureString "P@ssw0rd!" -AsPlainText -Force)
```

### Crear múltiples usuarios:
```powershell
$NuevosUsuarios = @(
    @{Name="LauraConta"; DisplayName="Laura Contreras"; Department="Contabilidad"},
    @{Name="MiguelIT"; DisplayName="Miguel Torres"; Department="TI"},
    @{Name="CarmenMkt"; DisplayName="Carmen Ruiz"; Department="Marketing"}
)

foreach ($User in $NuevosUsuarios) {
    New-Mailbox -Name $User.Name -DisplayName $User.DisplayName -UserPrincipalName "$($User.Name)@jmrd.com" -Password (ConvertTo-SecureString "P@ssw0rd!" -AsPlainText -Force)
    Set-User -Identity $User.Name -Department $User.Department
}
```

---

## 📁 **3. AÑADIR USUARIOS A GRUPOS**

### Ver todos los grupos disponibles:
```powershell
Get-DistributionGroup | Select-Object Name, DisplayName, PrimarySmtpAddress
```

### Añadir un usuario a un grupo:
```powershell
Add-DistributionGroupMember -Identity "NombreGrupo" -Member "NombreUsuario"
```
**Ejemplos:**
```powershell
Add-DistributionGroupMember -Identity "Recursos Humanos" -Member "LauraConta"
Add-DistributionGroupMember -Identity "Soporte Técnico" -Member "MiguelIT"
Add-DistributionGroupMember -Identity "Departamento de Ventas" -Member "CarmenMkt"
```

### Añadir múltiples usuarios a un grupo:
```powershell
$UsuariosVentas = @("AnaVentas", "LuisVentas", "SofiaVentas")
foreach ($User in $UsuariosVentas) {
    Add-DistributionGroupMember -Identity "Departamento de Ventas" -Member $User
}
```

---

## 🔄 **4. REMOVER USUARIOS DE GRUPOS**

### Remover un usuario de un grupo:
```powershell
Remove-DistributionGroupMember -Identity "NombreGrupo" -Member "NombreUsuario" -Confirm:$false
```
**Ejemplo:**
```powershell
Remove-DistributionGroupMember -Identity "Recursos Humanos" -Member "UsuarioRemover" -Confirm:$false
```

### Limpiar todos los usuarios de un grupo (excepto Administrator):
```powershell
$Members = Get-DistributionGroupMember -Identity "NombreGrupo"
foreach ($Member in $Members) {
    if ($Member.Name -ne "Administrator") {
        Remove-DistributionGroupMember -Identity "NombreGrupo" -Member $Member.Name -Confirm:$false
    }
}
```

---

## 👀 **5. VER MIEMBROS DE GRUPOS**

### Ver miembros de un grupo específico:
```powershell
Get-DistributionGroupMember -Identity "NombreGrupo" | Select-Object Name, DisplayName, PrimarySmtpAddress
```

### Ver en qué grupos está un usuario:
```powershell
$UserName = "NombreUsuario"
Get-DistributionGroup | Where-Object {
    (Get-DistributionGroupMember -Identity $_.Name | Where-Object {$_.Name -eq $UserName})
} | Select-Object Name, DisplayName
```

---

## 🏗️ **6. CREAR NUEVOS GRUPOS**

### Crear un nuevo grupo de distribución:
```powershell
New-DistributionGroup -Name "Contabilidad" -DisplayName "Departamento de Contabilidad" -Alias "Contabilidad" -PrimarySmtpAddress "contabilidad@jmrd.com" -Type "Distribution"
```

### Crear un grupo de seguridad con correo:
```powershell
New-DistributionGroup -Name "TI" -DisplayName "Departamento de TI" -Alias "TI" -PrimarySmtpAddress "ti@jmrd.com" -Type "Security"
```

---

## 📊 **7. COMANDO TODO EN UNO - VER ESTRUCTURA COMPLETA**

```powershell
Write-Host "`n=== ESTRUCTURA ACTUAL DE GRUPOS Y USUARIOS ===`n" -ForegroundColor Green

$Groups = Get-DistributionGroup | Sort-Object DisplayName

foreach ($Group in $Groups) {
    Write-Host "📁 GRUPO: $($Group.DisplayName) ($($Group.PrimarySmtpAddress))" -ForegroundColor Yellow
    $Members = Get-DistributionGroupMember -Identity $Group.Name | Sort-Object DisplayName
    if ($Members) {
        foreach ($Member in $Members) {
            Write-Host "   └─👤 $($Member.DisplayName) ($($Member.PrimarySmtpAddress))" -ForegroundColor Cyan
        }
    } else {
        Write-Host "   └─ [SIN MIEMBROS]" -ForegroundColor Gray
    }
    Write-Host ""
}
```

---

## 🎯 **PLANTILLA RÁPIDA PARA CAMBIOS COMUNES**

### Agregar nuevo empleado a RRHH:
```powershell
# Crear usuario
New-Mailbox -Name "NuevoRRHH" -DisplayName "Nuevo Empleado RRHH" -UserPrincipalName "nuevorrhh@jmrd.com" -Password (ConvertTo-SecureString "P@ssw0rd!" -AsPlainText -Force)

# Agregar a grupo
Add-DistributionGroupMember -Identity "Recursos Humanos" -Member "NuevoRRHH"
```

### Mover usuario entre departamentos:
```powershell
# Remover del grupo antiguo
Remove-DistributionGroupMember -Identity "Ventas" -Member "UsuarioMover" -Confirm:$false

# Agregar al nuevo grupo
Add-DistributionGroupMember -Identity "Marketing" -Member "UsuarioMover"

# Actualizar departamento
Set-User -Identity "UsuarioMover" -Department "Marketing"
```

---

## ⚠️ **CONSEJOS RÁPIDOS**

- **Verifica siempre** con `Get-Mailbox` y `Get-DistributionGroup` antes de hacer cambios
- **Usa -Confirm:$false** para eliminar sin preguntar confirmación
- **Mantén la consistencia** en nombres y departamentos
- **Prueba en OWA** después de los cambios: `https://mail.jmrd.com/owa`
