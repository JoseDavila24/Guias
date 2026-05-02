## 🔑 CONFIGURACIÓN SSH PARA BITBUCKET - EQUIPO DE DESARROLLO

### 📌 Requisitos previos
- Cuenta de Bitbucket activa
- Git instalado en el equipo
- Permisos de escritura en el repositorio

---

### 1️⃣ GENERAR LLAVE SSH
```bash
ssh-keygen -t ed25519 -C "tu-email@ejemplo.com"
```
- Presiona **ENTER** para ubicación predeterminada
- Presiona **ENTER** para passphrase vacía (o ingresa una)
- Presiona **ENTER** para confirmar

---

### 2️⃣ COPIAR LLAVE PÚBLICA
```bash
# Windows PowerShell
Get-Content ~/.ssh/id_ed25519.pub | Set-Clipboard

# macOS / Linux
cat ~/.ssh/id_ed25519.pub
# Copiar manualmente la salida
```

---

### 3️⃣ AGREGAR LLAVE A BITBUCKET
- Ir a: `Configuración de cuenta → SSH Keys → Add key`
- Pegar la llave pública copiada
- Guardar

---

### 4️⃣ CLONAR REPOSITORIO CON SSH
```bash
git clone git@bitbucket.org:WORKSPACE/REPOSITORIO.git
cd REPOSITORIO
```

---

### 5️⃣ CONFIGURAR IDENTIDAD GIT LOCAL
```bash
git config user.name "Nombre Apellido"
git config user.email "email@ejemplo.com"
```

---

### 6️⃣ VERIFICAR CONEXIÓN
```bash
ssh -T git@bitbucket.org
```
✅ Respuesta esperada: `logged in as (usuario).`

```bash
git remote -v
```
✅ Debe mostrar: `origin git@bitbucket.org:...`

---

## 🔄 FLUJO DE TRABAJO DIARIO
```bash
git pull origin main          # Obtener últimos cambios
git checkout -b feature/rama  # Crear rama nueva
git add .                     # Agregar cambios
git commit -m "descripción"   # Confirmar cambios
git push origin feature/rama  # Subir rama
```

---

## ⚠️ NOTAS IMPORTANTES
- Cada desarrollador usa su **propia llave SSH**
- No compartir llaves privadas (~/.ssh/id_ed25519)
- La llave pública (~/.ssh/id_ed25519.pub) es la que se comparte con Bitbucket
- Si cambias de equipo, genera una nueva llave
