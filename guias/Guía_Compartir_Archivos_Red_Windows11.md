# 📡 Guía Rápida: Compartir Archivos por Red en Windows 11

## 🔧 **Paso 1: Configurar Red como Privada**

1. **Ve a Configuración > Red e Internet**
2. **Haz clic en "Propiedades"** de tu conexión
3. **Selecciona "Privada"** (no Pública)

## 👥 **Paso 2: Habilitar Compartición**

1. **Abre "Panel de control"** (búscalo en Inicio)
2. **Centro de redes y recursos compartidos**
3. **Cambiar configuración de uso compartido avanzado**
4. **Activar estas opciones:**
   - ✅ **Activado la detección de redes**
   - ✅ **Activado el uso compartido de archivos e impresoras**

## 📂 **Paso 3: Compartir la Carpeta**

### **Método RÁPIDO:**
1. **Botón derecho** en la carpeta `C:\HyperV-Export`
2. **Dar acceso a > Uso compartido específico...**
3. **Agrega "Everyone"** (Todos)
4. **Nivel de permisos: Lectura/Escritura**
5. **Clic en "Compartir"**

### **Método AVANZADO:**
```powershell
# Abre PowerShell como Administrador
New-SmbShare -Name "HyperVExport" -Path "C:\HyperV-Export" -FullAccess "Everyone"
```

## 🌐 **Paso 4: Conectar desde la otra PC**

### **Desde Explorador de Archivos:**
1. **Abre "Este equipo"**
2. **En la barra de dirección escribe:** `\\IP-DEL-OTRO-PC`
   Ejemplo: `\\192.168.1.100`

### **Para saber la IP de la PC ORIGEN:**
```powershell
# Ejecuta en la PC con los archivos
ipconfig
# Busca "Dirección IPv4"
```

## 🔑 **Si pide usuario/contraseña:**
- **Usuario:** `NOMBRE-PC\TuUsuario` 
- **Contraseña:** La de tu Windows

## ⚡ **Comando Directo para Conectar:**
```powershell
# En la PC DESTINO, ejecuta:
net use Z: \\IP-ORIGEN\HyperVExport
```

## 🚨 **Consejos Importantes:**
- **Ambas PCs deben estar en la misma red**
- **Desactiva temporalmente el firewall** si hay problemas
- **La carpeta debe tener suficiente espacio libre**
