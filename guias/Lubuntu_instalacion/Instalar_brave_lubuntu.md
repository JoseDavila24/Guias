# 🦁 Instalar Brave Browser en Lubuntu (Guía Oficial y Optimizada)

## ✅ 1. Instalación de Brave desde el repositorio oficial

Ejecuta cada uno de estos comandos en terminal:

```bash
sudo apt install curl

sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg

sudo curl -fsSLo /etc/apt/sources.list.d/brave-browser-release.sources \
https://brave-browser-apt-release.s3.brave.com/brave-browser.sources

sudo apt update

sudo apt install brave-browser -y
```

---

## 🚀 2. Ejecutar Brave

Desde el menú de aplicaciones o con:

```bash
brave-browser
```

---

## ⚙️ 3. Recomendación rápida de rendimiento

Si Brave se siente lento o congelado:

1. Abre Brave.
2. Ve a `Configuración → Sistema`.
3. Desactiva: **“Usar aceleración por hardware cuando esté disponible”**.
4. Reinicia el navegador.

---

## 🧠 4. Verifica si tu equipo está listo para navegar bien con Brave

Puedes usar un script automático que evalúa:

* Cantidad de RAM
* Tipo de disco (SSD o HDD)
* Presencia de aceleración gráfica
* Estado de la conexión a internet

---

### 📁 Ruta recomendada para guardar el script

Guárdalo en:

```bash
/mnt/hdd/Almacenamiento/Scripts/verificar_equipo_brave.sh
```

---

### 📜 Contenido del script `verificar_equipo_brave.sh`

```bash
#!/bin/bash

echo "🔍 Verificando condiciones del sistema para una buena experiencia con Brave..."

# 1. Verificar RAM
total_ram=$(grep MemTotal /proc/meminfo | awk '{print $2}')
ram_gb=$((total_ram / 1024 / 1024))
echo "📦 RAM instalada: $ram_gb GB"
if [ "$ram_gb" -lt 4 ]; then
  echo "⚠️ Recomendación: Considera ampliar la RAM a al menos 4 GB."
else
  echo "✅ RAM suficiente."
fi

# 2. Verificar si se usa un SSD
root_disk=$(df / | tail -1 | awk '{print $1}')
disk_name=$(basename "$(lsblk -no PKNAME "$root_disk")")
rotational=$(cat /sys/block/$disk_name/queue/rotational 2>/dev/null)
if [ "$rotational" = "0" ]; then
  echo "✅ Disco principal es SSD."
else
  echo "⚠️ Disco principal es HDD. Un SSD mejora mucho el rendimiento."
fi

# 3. Verificar GPU activa
echo "🎮 GPU utilizada:"
if ! command -v glxinfo &> /dev/null; then
  echo "ℹ️ Instalando mesa-utils para detectar GPU..."
  sudo apt install mesa-utils -y
fi
glxinfo | grep "OpenGL renderer"

# 4. Verificar aceleración: llvmpipe indica uso de CPU
gpu_name=$(glxinfo | grep "OpenGL renderer" | cut -d':' -f2)
if echo "$gpu_name" | grep -iq "llvmpipe"; then
  echo "⚠️ No tienes aceleración gráfica real (se usa CPU). Considera instalar drivers adecuados."
else
  echo "✅ Aceleración gráfica disponible."
fi

# 5. Verificar conexión a internet
echo "🌐 Probando conexión a internet (google.com)..."
if ping -c 2 google.com &> /dev/null; then
  echo "✅ Conexión a internet activa."
else
  echo "❌ No se pudo establecer conexión a internet."
fi

echo "✅ Verificación completa."
```

---

### ▶️ Instrucciones para usar el script

1. Abre terminal y ve a la ruta:

```bash
cd /mnt/hdd/Almacenamiento/Scripts
```

2. Crea el archivo:

```bash
nano verificar_equipo_brave.sh
```

3. Pega el contenido, guarda y cierra (Ctrl+O, Enter, Ctrl+X).

4. Dale permisos de ejecución:

```bash
chmod +x verificar_equipo_brave.sh
```

5. Ejecútalo:

```bash
./verificar_equipo_brave.sh
```
