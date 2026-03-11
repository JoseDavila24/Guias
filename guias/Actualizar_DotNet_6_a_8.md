## 📋 Mini Guía: Actualizar tu proyecto de .NET 6.0 a .NET 8.0

### Paso 1: Abrir el archivo del proyecto
Localiza y abre el archivo **`service1.csproj`** en tu editor de código (VS Code, Notepad++, etc.)

### Paso 2: Modificar la versión de .NET
Busca esta línea:
```xml
<TargetFramework>net6.0</TargetFramework>
```
Y cámbiala a:
```xml
<TargetFramework>net8.0</TargetFramework>
```

### Paso 3: Guardar los cambios
Guarda el archivo después de modificar la versión.

### Paso 4: Limpiar y reconstruir
Abre tu terminal y ejecuta estos comandos en orden:

```powershell
dotnet clean
```
*Esto elimina archivos temporales y compilaciones anteriores*

```powershell
dotnet build
```
*Esto compila el proyecto con la nueva versión*

```powershell
dotnet run
```
*Esto ejecuta tu aplicación actualizada*

---

## ✅ ¡Listo!
Tu aplicación ahora debería ejecutarse sin problemas usando .NET 8.0, que tienes instalado y cuenta con soporte activo.

---

### ⚠️ Nota importante:
Si encuentras errores al compilar después del cambio, puede ser porque algunas librerías o paquetes NuGet necesitan actualizarse para ser compatibles con .NET 8.0. En ese caso, ejecuta:

```powershell
dotnet restore
```
