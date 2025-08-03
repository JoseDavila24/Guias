# 📘 Registro y Monitoreo de Software en Lubuntu

---

## 🎯 Objetivo

Implementar un sistema robusto para **detectar, registrar y comparar automáticamente todo software instalado en Lubuntu**, ya sea mediante comandos, herramientas gráficas o paquetes externos, manteniendo trazabilidad completa en:

```
/mnt/hdd/Control_Instalaciones/
```

---

## 🗂️ Estructura de archivos recomendada

Todos los registros y capturas deben mantenerse organizados en:

```
/mnt/hdd/Control_Instalaciones/
├── historial_instalaciones_auto.log     → Registro automático desde terminal (Bash/Zsh)
├── instalaciones_software.txt           → Registro manual por categoría y fecha
├── lista_paquetes_dpkg.txt              → Captura actual de paquetes APT
├── lista_paquetes_snap.txt              → Captura actual de paquetes Snap
├── lista_paquetes_flatpak.txt           → Captura actual de paquetes Flatpak
├── lista_paquetes_dpkg_anterior.txt     → Captura anterior (para comparación)
├── diferencias_apt.txt                  → Cambios detectados entre capturas APT
├── actualizaciones.log                  → Log cronológico de ejecuciones
└── integridad_instaladores.md           → Verificación de instaladores locales
```

---

## ⚙️ Registro automático desde la terminal

Este mecanismo registra todo comando relacionado con instalación ejecutado en Bash o Zsh, sin intervención manual.

### 🟦 Para usuarios de Bash (`~/.bashrc`)

Agregar al final del archivo:

```bash
log_installs() {
  case "$BASH_COMMAND" in
    *apt*|*dpkg*|*snap*|*flatpak*|*wget*|*curl*|*make*|*./configure*|*install*)
      echo "$(date '+%Y-%m-%d %H:%M:%S') - $BASH_COMMAND" >> /mnt/hdd/Control_Instalaciones/historial_instalaciones_auto.log
      ;;
  esac
}
trap log_installs DEBUG
```

Recargar la configuración:

```bash
source ~/.bashrc
```

---

### 🟪 Para usuarios de Zsh (`~/.zshrc`)

Agregar:

```zsh
precmd() {
  if [[ "$BUFFER" == *apt* || "$BUFFER" == *dpkg* || "$BUFFER" == *snap* || "$BUFFER" == *flatpak* || "$BUFFER" == *wget* || "$BUFFER" == *curl* || "$BUFFER" == *make* || "$BUFFER" == *install* ]]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $BUFFER" >> /mnt/hdd/Control_Instalaciones/historial_instalaciones_auto.log
  fi
}
```

Recargar con:

```bash
source ~/.zshrc
```

---

## ✍️ Registro manual por categoría y fecha

Para documentar instalaciones externas como AppImages, binarios directos, o herramientas gráficas.

Editar el archivo:

```bash
nano /mnt/hdd/Control_Instalaciones/instalaciones_software.txt
```

Formato sugerido:

```
📅 2025-07-14
🧩 Categoría: Multimedia
🔧 Instalado: Audacity, VLC
📌 Motivo: Edición de audio y video

📅 2025-07-15
🧩 Categoría: Desarrollo
🔧 Instalado: Git, Python3-pip
📌 Motivo: Proyectos de software
```

---

## 🔄 Captura y comparación del estado del sistema

Todas las tareas relacionadas con capturas del sistema y comparación de cambios están centralizadas en el script:

```
/mnt/hdd/Almacenamiento/Scripts/actualizar_historial_completo.sh
```

Este script realiza:

* Captura actual de paquetes instalados (`dpkg`, `snap`, `flatpak`)
* Backup automático del snapshot anterior (`lista_paquetes_dpkg_anterior.txt`)
* Comparación entre capturas (`diferencias_apt.txt`)
* Log detallado de ejecución (`actualizaciones.log`)

---

## 📅 Automatización con `cron`

Para que el monitoreo se realice automáticamente cada semana:

1. Abre el archivo crontab del usuario:

```bash
crontab -e
```

2. Añade al final:

```bash
0 10 * * 1 /bin/bash /mnt/hdd/Almacenamiento/Scripts/actualizar_historial_completo.sh
```

📌 Esto ejecutará el script todos los lunes a las 10:00 a.m.

---

## 🧾 Verificación de integridad de instaladores

Permite validar que los archivos `.deb`, `.bundle`, `.zip`, etc., provienen de fuentes confiables.

Editar:

```bash
nano /mnt/hdd/Control_Instalaciones/integridad_instaladores.md
```

Formato sugerido:

```
✅ balenaEtcher-linux-x64-2.1.0.zip
  Fuente: https://www.balena.io
  SHA256: abc123...

✅ VMware-Workstation-Full-17.6.3.bundle
  Fuente: https://www.vmware.com
  SHA256: def456...
```

Obtener el hash con:

```bash
sha256sum nombre_del_archivo
```

---

## ♻️ Restauración del sistema (opcional)

Para reinstalar paquetes APT desde un snapshot previo:

```bash
sudo dpkg --set-selections < lista_paquetes_dpkg.txt
sudo apt-get dselect-upgrade
```

---

## ✅ Resultado final

✔ Registro automático de comandos de instalación
✔ Documentación manual de instalaciones externas
✔ Captura y comparación programada del estado del sistema
✔ Registro cronológico de cambios y diferencias
✔ Control total de integridad de instaladores
✔ Todo organizado en `/mnt/hdd`, auditable y restaurable en cualquier momento
