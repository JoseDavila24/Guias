# **Registro de Instalaciones de Software en Lubuntu**

## 🔹 **1. Crear carpeta base para el historial**

```bash
mkdir -p /mnt/hdd/Control_Instalaciones/
```

---

## 🔹 **2. Crear archivo de anotaciones manuales (opcional)**

```bash
touch /mnt/hdd/Control_Instalaciones/instalaciones_software.txt
```

Puedes abrirlo con:

```bash
nano /mnt/hdd/Control_Instalaciones/instalaciones_software.txt
```

Ejemplo de entrada:

```
📆 2025-07-10
Instalé: Audacity, GIMP
Razón: Edición de audio e imágenes.
```

---

## 🔹 **3. Activar registro automático en terminal**

Abre tu archivo `.bashrc`:

```bash
nano ~/.bashrc
```

Agrega al final:

```bash
# Registro automático de comandos de instalación
log_installs() {
  case "$BASH_COMMAND" in
    *apt*|*snap*|*flatpak*|*dpkg*|*wget*|*curl*|*make*|*./configure*|*install*)
      echo "$(date '+%Y-%m-%d %H:%M:%S') - $BASH_COMMAND" >> /mnt/hdd/Control_Instalaciones/historial_instalaciones_auto.log
      ;;
  esac
}
trap log_installs DEBUG
```

Guarda y recarga:

```bash
source ~/.bashrc
```

---

## 🔹 **4. Crear el script de actualización del historial**

Abre:

```bash
nano ~/actualizar_historial.sh
```

Pega:

```bash
#!/bin/bash

# Ruta personalizada
HIST_DIR="/mnt/hdd/Control_Instalaciones"

echo "Actualizando historial de paquetes instalados..."

dpkg --get-selections > "$HIST_DIR/lista_paquetes_dpkg.txt"
snap list > "$HIST_DIR/lista_paquetes_snap.txt" 2>/dev/null
flatpak list > "$HIST_DIR/lista_paquetes_flatpak.txt" 2>/dev/null

echo "✅ Historial actualizado: $(date '+%Y-%m-%d %H:%M:%S')" >> "$HIST_DIR/actualizaciones.log"
```

Guarda y dale permisos:

```bash
chmod +x ~/actualizar_historial.sh
```

---

## 🔹 **5. Programar ejecución automática semanal con `cron`**

Abre el crontab del usuario:

```bash
crontab -e
```

Agrega al final esta línea (ejecuta todos los lunes a las 9:00 a.m.):

```cron
0 9 * * 1 bash ~/actualizar_historial.sh
```

Guarda y cierra.

---

## 🧪 **Verificar cron está activo**

Puedes ver tus tareas cron con:

```bash
crontab -l
```

Y para asegurarte de que `cron` esté funcionando:

```bash
systemctl status cron
```

Si no está activo, actívalo con:

```bash
sudo systemctl enable --now cron
```

---

## 📂 **Resumen de archivos en `/mnt/hdd/Control_Instalaciones/`**

```
/mnt/hdd/Control_Instalaciones/
├── historial_instalaciones_auto.log   # Registro automático con fecha
├── instalaciones_software.txt         # Anotaciones manuales
├── lista_paquetes_dpkg.txt            # Paquetes apt
├── lista_paquetes_snap.txt            # Paquetes snap
├── lista_paquetes_flatpak.txt         # Paquetes flatpak
├── actualizaciones.log                # Log de ejecuciones del script
```
