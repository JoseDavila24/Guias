# Guía Completa de Instalación de Cisco Packet Tracer 8.2.2 en Linux Mint (64 bits)

## ⚠️ Importante: Actualización del Sistema

**Descripción:**
Antes de instalar cualquier software, es recomendable actualizar el sistema para asegurarte de contar con las últimas mejoras, correcciones y parches de seguridad. En Linux Mint usamos `apt` estándar.

### Comando:

```bash
sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y && sudo apt clean
```

### ¿Qué hace cada parte?

* 🔄 `apt update`: Actualiza la lista de paquetes disponibles.
* ⬆️ `apt upgrade`: Instala las actualizaciones de paquetes disponibles (en Mint se recomienda `upgrade` para evitar cambios agresivos en el kernel a menos que uses el Gestor de Actualizaciones gráfico).
* 🧹 `apt autoremove`: Elimina paquetes que ya no son necesarios.
* 🗑️ `apt clean`: Borra archivos temporales del gestor de paquetes.

> **Nota sobre Linux Mint:** El gestor de actualizaciones gráfico (mintupdate) gestiona las políticas de actualización. Si prefieres la terminal, `upgrade` es más seguro que `full-upgrade` para mantener la estabilidad del escritorio Cinnamon/MATE/XFCE.

---

## 🔽 Paso 1: Descargar el archivo ZIP desde Dropbox

Usa `wget` para descargar el archivo comprimido con los instaladores:

```bash
wget -O CiscoPacketTracer822.zip "https://www.dropbox.com/scl/fi/jyc0jg98sg551di9ecji3/CiscoPacketTracer822.zip?rlkey=rzx52qc4mycsfursupjn7x6sl&st=zbe2ql4j&dl=1"
```

---

## 📂 Paso 2: Extraer los archivos `.deb`

Descomprime el archivo ZIP descargado (si no tienes `unzip`, instálalo con `sudo apt install unzip`):

```bash
unzip CiscoPacketTracer822.zip
```

Deberías obtener estos tres archivos:

* `CiscoPacketTracer822_amd64_signed.deb`
* `libgl1-mesa-glx_23.0.4-0ubuntu1.22.04.1_amd64.deb`
* `libegl1-mesa_23.0.4-0ubuntu1.22.04.1_amd64.deb`

---

## ⚙️ Paso 3: Instalar dependencias del sistema

Ejecuta este comando para instalar las bibliotecas necesarias que solicita Packet Tracer:

```bash
sudo apt install libnss3 libxslt1.1 libxss1 libpulse0 \
                 libxcb-xinerama0 libxcb-icccm4 libxcb-image0 \
                 libxcb-keysyms1 libxcb-render-util0 libxkbcommon-x11-0
```

---

## 🧱 Paso 4: Instalar bibliotecas gráficas requeridas

Packet Tracer 8.2.2 necesita versiones específicas de Mesa. Instala los paquetes descargados en el paso 2:

```bash
sudo dpkg -i libegl1-mesa_23.0.4-0ubuntu1.22.04.1_amd64.deb
sudo dpkg -i libgl1-mesa-glx_23.0.4-0ubuntu1.22.04.1_amd64.deb
sudo apt --fix-broken install
```

---

## 📦 Paso 5: Instalar Cisco Packet Tracer

Instala el paquete `.deb` principal:

```bash
sudo dpkg -i CiscoPacketTracer822_amd64_signed.deb
sudo apt --fix-broken install
```

Durante la instalación, acepta la licencia usando la tecla `TAB` para seleccionar `<Aceptar>` y luego `ENTER`.

---

## ❗ Paso 6: Solucionar error Qt (plugin "xcb")

Si al ejecutar Packet Tracer desde el menú de Mint no abre o ves este error en terminal:

```
Fatal: This application failed to start because no Qt platform plugin could be initialized.
```

Debes ejecutarlo con las variables de entorno correctas.

**Método rápido (solo para probar):**
```bash
cd /opt/pt/bin
export QT_QPA_PLATFORM_PLUGIN_PATH=/opt/pt/plugins/platforms
LD_LIBRARY_PATH=/opt/pt/bin ./PacketTracer
```

---

## 🚀 Paso 7: Crear lanzador de acceso rápido (Obligatorio para Linux Mint)

Para que puedas abrir Packet Tracer desde el menú de aplicaciones de Mint (Cinnamon, MATE o XFCE) sin errores, debes modificar el archivo `.desktop` o crear un script envolvente.

### Opción A: Crear Script Global (Recomendado)

1. Crea un archivo de script en `/usr/local/bin`:

```bash
sudo nano /usr/local/bin/packettracer
```

2. Pega el siguiente contenido:

```bash
#!/bin/bash
export QT_QPA_PLATFORM_PLUGIN_PATH=/opt/pt/plugins/platforms
export LD_LIBRARY_PATH=/opt/pt/bin
exec /opt/pt/bin/PacketTracer "$@"
```

3. Guarda (`Ctrl+O`, `Enter`, `Ctrl+X`) y hazlo ejecutable:

```bash
sudo chmod +x /usr/local/bin/packettracer
```

### Opción B: Arreglar el acceso directo del Menú de Mint

Edita el archivo `.desktop` que se creó durante la instalación:

```bash
sudo nano /usr/share/applications/cisco-pt.desktop
```

Busca la línea que empieza con `Exec=` y cámbiala por:

```ini
Exec=env QT_QPA_PLATFORM_PLUGIN_PATH=/opt/pt/plugins/platforms LD_LIBRARY_PATH=/opt/pt/bin /opt/pt/bin/PacketTracer %F
```

Guarda el archivo. Ahora el icono de **Cisco Packet Tracer** en el menú de Linux Mint funcionará correctamente.

---

## ✅ ¡Instalación Completada!

Cisco Packet Tracer 8.2.2 ya está instalado y funcionando en tu sistema Linux Mint.

📌 **Consejo específico para Mint:** Si tras una actualización del sistema Packet Tracer deja de funcionar, revisa que las librerías Mesa (`libgl1-mesa-glx`) no hayan sido actualizadas a una versión incompatible. Si eso ocurre, repite el **Paso 4**.
