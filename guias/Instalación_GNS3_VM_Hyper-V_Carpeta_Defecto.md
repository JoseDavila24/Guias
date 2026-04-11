# Instalación limpia de GNS3 VM en Hyper-V

### Usando la carpeta que GNS3 crea por defecto

---

## 📋 Estructura final que lograrás

```
C:\ProgramData\Microsoft\Windows\Virtual Hard Disks\
├── GNS3 VM-disk001.vhd      ← Disco 1 (se queda)
├── GNS3 VM-disk002.vhd      ← Disco 2 (se queda)
├── create-vm.ps1            ← Temporal (se borra)
└── install-vm.bat           ← Temporal (se borra)
```

---

## 🚀 Paso a paso

### 1️⃣ Ubicar la carpeta que GNS3 creó por defecto

```powershell
# Verificar que la carpeta existe
Test-Path "C:\ProgramData\Microsoft\Windows\Virtual Hard Disks"

# Si no existe, GNS3 la creará al ejecutarse o puedes crearla manualmente
New-Item -Path "C:\ProgramData\Microsoft\Windows\Virtual Hard Disks" -ItemType Directory -Force
```

### 2️⃣ Extraer el ZIP directamente en la carpeta por defecto

```powershell
# Extraer TODO el contenido del ZIP en la ubicación definitiva
# Ajusta la ruta según donde descargaste el ZIP

Expand-Archive -Path "C:\Users\josem.HERACLES\Downloads\GNS3.VM.Hyper-V.2.2.57.zip" -DestinationPath "C:\ProgramData\Microsoft\Windows\Virtual Hard Disks" -Force
```

### 3️⃣ Verificar que los archivos están en el lugar correcto

```powershell
# Listar el contenido
Get-ChildItem "C:\ProgramData\Microsoft\Windows\Virtual Hard Disks"

# Deberías ver:
# - create-vm.ps1
# - install-vm.bat
# - GNS3 VM-disk001.vhd
# - GNS3 VM-disk002.vhd
```

### 4️⃣ Ejecutar la instalación

```powershell
# Navegar a la carpeta
cd "C:\ProgramData\Microsoft\Windows\Virtual Hard Disks"

# Ejecutar el instalador
.\install-vm.bat
```

### 5️⃣ Verificar que la VM se creó correctamente

```powershell
# Ver estado de la VM
Get-VM -Name "GNS3 VM" | Select-Object Name, State, Version, Path

# Ver discos conectados (deben apuntar a la ubicación actual)
Get-VMHardDiskDrive -VMName "GNS3 VM"
```

### 6️⃣ Probar que funciona desde GNS3

```powershell
# Iniciar GNS3 como Administrador
Start-Process "C:\Program Files\GNS3\gns3.exe" -Verb RunAs
```

**En GNS3:**
1. Edit → Preferences → GNS3 VM
2. Virtualization engine: **Hyper-V**
3. Debería aparecer "GNS3 VM" en la lista
4. Click en **Apply** y **OK**

### 7️⃣ Probar con un proyecto simple

1. Crear un nuevo proyecto
2. Agregar un router (por ejemplo, Cisco IOS)
3. Iniciar el dispositivo
4. Verificar que la VM se inicia automáticamente

### 8️⃣ Limpiar archivos temporales (después de probar)

```powershell
# Una vez confirmado que todo funciona correctamente
cd "C:\ProgramData\Microsoft\Windows\Virtual Hard Disks"

# Eliminar solo los scripts
Remove-Item "create-vm.ps1" -Force
Remove-Item "install-vm.bat" -Force

# Verificar que solo quedan los VHD
Get-ChildItem "C:\ProgramData\Microsoft\Windows\Virtual Hard Disks"

# Deberías ver solo:
# - GNS3 VM-disk001.vhd
# - GNS3 VM-disk002.vhd
```

---

## 📝 Script automatizado completo

**Guarda esto como `Instalar-GNS3-Directo.ps1` y ejecútalo como Administrador:**

```powershell
# Script de instalación directa en carpeta por defecto de GNS3

$DefaultPath = "C:\ProgramData\Microsoft\Windows\Virtual Hard Disks"
$ZIPPath = "C:\Users\josem.HERACLES\Downloads\GNS3.VM.Hyper-V.2.2.57.zip"  # ← CAMBIAR SEGÚN TU DESCARGA
$VMName = "GNS3 VM"

Write-Host "=== INSTALACIÓN GNS3 VM EN CARPETA POR DEFECTO ===" -ForegroundColor Green

# 1. Verificar carpeta por defecto
Write-Host "`n[1/7] Verificando carpeta por defecto..." -ForegroundColor Yellow
if (-not (Test-Path $DefaultPath)) {
    New-Item -Path $DefaultPath -ItemType Directory -Force | Out-Null
    Write-Host "Carpeta creada: $DefaultPath" -ForegroundColor Green
} else {
    Write-Host "Carpeta existe: $DefaultPath" -ForegroundColor Green
}

# 2. Extraer ZIP
Write-Host "`n[2/7] Extrayendo ZIP en carpeta por defecto..." -ForegroundColor Yellow
Expand-Archive -Path $ZIPPath -DestinationPath $DefaultPath -Force
Write-Host "Archivos extraídos correctamente" -ForegroundColor Green

# 3. Verificar archivos
Write-Host "`n[3/7] Verificando archivos necesarios..." -ForegroundColor Yellow
$files = @("create-vm.ps1", "install-vm.bat", "GNS3 VM-disk001.vhd", "GNS3 VM-disk002.vhd")
$missing = $false
foreach ($file in $files) {
    $filePath = Join-Path $DefaultPath $file
    if (Test-Path $filePath) {
        Write-Host "✅ $file" -ForegroundColor Green
    } else {
        Write-Host "❌ FALTA: $file" -ForegroundColor Red
        $missing = $true
    }
}
if ($missing) { exit 1 }

# 4. Ejecutar instalación
Write-Host "`n[4/7] Ejecutando instalación de la VM..." -ForegroundColor Yellow
Set-Location $DefaultPath
& .\install-vm.bat

# 5. Verificar VM
Write-Host "`n[5/7] Verificando VM creada..." -ForegroundColor Yellow
$vm = Get-VM -Name $VMName -ErrorAction SilentlyContinue
if ($vm) {
    Write-Host "✅ VM creada: $($vm.Name)" -ForegroundColor Green
    Write-Host "   Estado: $($vm.State)" -ForegroundColor Green
    Write-Host "   Versión: $($vm.Version)" -ForegroundColor Green
} else {
    Write-Host "❌ Error: No se pudo crear la VM" -ForegroundColor Red
    exit 1
}

# 6. Verificar discos
Write-Host "`n[6/7] Verificando discos conectados..." -ForegroundColor Yellow
$disks = Get-VMHardDiskDrive -VMName $VMName
foreach ($disk in $disks) {
    Write-Host "✅ Disco: $($disk.Path)" -ForegroundColor Green
}

# 7. Limpiar scripts
Write-Host "`n[7/7] Limpiando scripts temporales..." -ForegroundColor Yellow
Remove-Item "$DefaultPath\create-vm.ps1" -Force -ErrorAction SilentlyContinue
Remove-Item "$DefaultPath\install-vm.bat" -Force -ErrorAction SilentlyContinue
Write-Host "Scripts eliminados" -ForegroundColor Green

# Resultado final
Write-Host "`n=== INSTALACIÓN COMPLETADA ===" -ForegroundColor Green
Write-Host "VM: $VMName" -ForegroundColor Green
Write-Host "Ubicación: $DefaultPath" -ForegroundColor Green
Write-Host "Discos: GNS3 VM-disk001.vhd y GNS3 VM-disk002.vhd" -ForegroundColor Green
Write-Host "`nPróximos pasos:" -ForegroundColor Yellow
Write-Host "1. Abre GNS3 como Administrador" -ForegroundColor White
Write-Host "2. Edit → Preferences → GNS3 VM" -ForegroundColor White
Write-Host "3. Selecciona Hyper-V como engine" -ForegroundColor White
Write-Host "4. Verifica que aparece 'GNS3 VM'" -ForegroundColor White
```

---

## 📊 Resumen de lo que se puede borrar

| Archivo | ¿Se borra? | ¿Cuándo? |
|---------|------------|----------|
| `GNS3 VM-disk001.vhd` | ❌ NO | Nunca (es el disco de la VM) |
| `GNS3 VM-disk002.vhd` | ❌ NO | Nunca (es el disco de la VM) |
| `create-vm.ps1` | ✅ SÍ | Después de ejecutarlo |
| `install-vm.bat` | ✅ SÍ | Después de ejecutarlo |
| `GNS3.VM.Hyper-V.2.2.57.zip` | ✅ SÍ | Después de extraer |

---

## ✅ Verificación final

```powershell
# Comando rápido para verificar el estado final
Write-Host "=== VERIFICACIÓN FINAL ===" -ForegroundColor Green
Write-Host "`n📁 Archivos en carpeta por defecto:" -ForegroundColor Yellow
Get-ChildItem "C:\ProgramData\Microsoft\Windows\Virtual Hard Disks"

Write-Host "`n🖥️ Estado de la VM:" -ForegroundColor Yellow
Get-VM -Name "GNS3 VM" | Select-Object Name, State, MemoryAssigned, ProcessorCount

Write-Host "`n💿 Discos conectados:" -ForegroundColor Yellow
Get-VMHardDiskDrive -VMName "GNS3 VM" | Select-Object Path
```
