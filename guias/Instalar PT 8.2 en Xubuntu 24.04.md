# 🎓 Guía de Instalación: Cisco Packet Tracer 8.2.2 en Xubuntu 24.04.2 LTS (64 bits)

---

## 🔽 1. Descargar Packet Tracer

1. Ve a: [https://www.netacad.com](https://www.netacad.com)
2. Inicia sesión con tu cuenta de Cisco Networking Academy.
3. Descarga el instalador para Linux:
   **`Packet_Tracer822_amd64_signed.deb`**

📁 Guarda el archivo en la carpeta `Descargas` o similar.

---

## ⚙️ 2. Instalar Dependencias del Sistema

Xubuntu 24.04 no incluye varias bibliotecas necesarias. Instálalas con:

```bash
sudo apt update
sudo apt install libnss3 libxslt1.1 libxss1 libpulse0 \
                 libxcb-xinerama0 libxcb-icccm4 libxcb-image0 \
                 libxcb-keysyms1 libxcb-render-util0 libxkbcommon-x11-0
```

---

## 🛠️ 3. Instalar `libgl1-mesa-glx` Manualmente

Ubuntu 24.04 eliminó este paquete del repositorio, pero es esencial para el entorno gráfico de Packet Tracer.

### ▶️ Pasos:

```bash
wget http://archive.ubuntu.com/ubuntu/pool/main/m/mesa/libgl1-mesa-glx_23.0.4-0ubuntu1~22.04.1_amd64.deb
sudo dpkg -i libgl1-mesa-glx_23.0.4-0ubuntu1~22.04.1_amd64.deb
sudo apt --fix-broken install
```

---

## 📦 4. Instalar Packet Tracer

Desde la carpeta donde guardaste el `.deb`:

```bash
cd ~/Descargas
sudo dpkg -i Packet_Tracer822_amd64_signed.deb
sudo apt --fix-broken install
```

📌 Durante la instalación, acepta los términos de licencia cuando se te solicite.

---

## 🧱 5. Corregir Error de Plugin Qt (`xcb`)

Si al ejecutar ves este mensaje:

```
Fatal: This application failed to start because no Qt platform plugin could be initialized.
```

Debes lanzar Packet Tracer con las variables de entorno adecuadas:

```bash
cd /opt/pt/bin
export QT_QPA_PLATFORM_PLUGIN_PATH=/opt/pt/plugins/platforms
LD_LIBRARY_PATH=/opt/pt/bin ./PacketTracer
```

---

## 🚀 6. Crear Lanzador Global (Opcional)

Para no escribir comandos largos cada vez, crea un script de acceso rápido:

```bash
sudo nano /usr/local/bin/packettracer
```

### Pega esto dentro:

```bash
#!/bin/bash
export QT_QPA_PLATFORM_PLUGIN_PATH=/opt/pt/plugins/platforms
export LD_LIBRARY_PATH=/opt/pt/bin
exec /opt/pt/bin/PacketTracer "$@"
```

### Guarda y hazlo ejecutable:

```bash
sudo chmod +x /usr/local/bin/packettracer
```

✅ Ahora puedes ejecutar Packet Tracer escribiendo simplemente:

```bash
packettracer
```

---

## ✅ Finalizado

¡Cisco Packet Tracer 8.2.2 ya está funcionando en Xubuntu 24.04.2 LTS!

🔁 **Recordatorio:** Si Packet Tracer se actualiza o cambias de versión de sistema operativo, asegúrate de revisar compatibilidades y dependencias nuevamente.
