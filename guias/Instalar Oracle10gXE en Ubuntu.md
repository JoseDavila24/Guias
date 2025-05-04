# 📘 Guía Completa de Instalación

## Cisco Packet Tracer 8.2.2 en Xubuntu 24.04.2 LTS (64 bits)

---

## ⚠️ Importante: Actualización del Sistema

**Descripción:**
Antes de instalar cualquier software, es recomendable actualizar el sistema para asegurarte de contar con las últimas mejoras, correcciones y parches de seguridad.

### Comando:

```bash
sudo apt update && sudo apt full-upgrade -y && sudo apt autoremove -y && sudo apt clean
```

### ¿Qué hace cada parte?

* 🔄 `apt update`: Actualiza la lista de paquetes disponibles.
* ⬆️ `apt full-upgrade`: Instala todas las actualizaciones disponibles, incluyendo las que requieren cambios en dependencias.
* 🧹 `apt autoremove`: Elimina paquetes que ya no son necesarios.
* 🗑️ `apt clean`: Borra archivos temporales del gestor de paquetes.

---

## 🔽 Paso 1: Descargar el archivo ZIP desde Dropbox

Usa `wget` para descargar el archivo comprimido con los instaladores:

```bash
wget -O CiscoPacketTracer822.zip "https://www.dropbox.com/scl/fi/jyc0jg98sg551di9ecji3/CiscoPacketTracer822.zip?rlkey=rzx52qc4mycsfursupjn7x6sl&st=zbe2ql4j&dl=1"
```

---

## 📂 Paso 2: Extraer los archivos `.deb`

Descomprime el archivo ZIP descargado:

```bash
unzip CiscoPacketTracer822.zip
```

Deberías obtener estos tres archivos:

* `CiscoPacketTracer822_amd64_signed.deb`
* `libgl1-mesa-glx_23.0.4-0ubuntu1.22.04.1_amd64.deb`
* `libegl1-mesa_23.0.4-0ubuntu1.22.04.1_amd64.deb`

---

## ⚙️ Paso 3: Instalar dependencias del sistema

Ejecuta este comando para instalar las bibliotecas necesarias:

```bash
sudo apt install libnss3 libxslt1.1 libxss1 libpulse0 \
                 libxcb-xinerama0 libxcb-icccm4 libxcb-image0 \
                 libxcb-keysyms1 libxcb-render-util0 libxkbcommon-x11-0 unzip wget
```

---

## 🧱 Paso 4: Instalar bibliotecas gráficas requeridas

Instala las bibliotecas gráficas que Packet Tracer necesita para funcionar correctamente:

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

Durante la instalación, acepta la licencia cuando se te solicite.

---

## ❗ Paso 6: Solucionar error Qt (plugin "xcb")

Si al ejecutar Packet Tracer aparece este error:

```
Fatal: This application failed to start because no Qt platform plugin could be initialized.
```

Ejecuta el programa con las variables necesarias:

```bash
cd /opt/pt/bin
export QT_QPA_PLATFORM_PLUGIN_PATH=/opt/pt/plugins/platforms
LD_LIBRARY_PATH=/opt/pt/bin ./PacketTracer
```

---

## 🚀 Paso 7: Crear lanzador de acceso rápido (opcional)

Para poder ejecutar Packet Tracer fácilmente desde cualquier terminal:

1. Crea un archivo de script:

```bash
sudo nano /usr/local/bin/packettracer
```

2. Pega lo siguiente:

```bash
#!/bin/bash
export QT_QPA_PLATFORM_PLUGIN_PATH=/opt/pt/plugins/platforms
export LD_LIBRARY_PATH=/opt/pt/bin
exec /opt/pt/bin/PacketTracer "$@"
```

3. Guarda y hazlo ejecutable:

```bash
sudo chmod +x /usr/local/bin/packettracer
```

Ahora puedes ejecutar Packet Tracer desde cualquier lugar con:

```bash
packettracer
```

---

## ✅ ¡Instalación Completada!

Cisco Packet Tracer 8.2.2 ya está instalado y funcionando en tu sistema Xubuntu 24.04.2 LTS (64 bits).

📌 Consejo: Si actualizas tu sistema o el programa, asegúrate de verificar que todas las dependencias necesarias estén presentes.
