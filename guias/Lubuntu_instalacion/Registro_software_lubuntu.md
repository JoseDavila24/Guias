# 📘 Registro y Monitoreo de Software en Lubuntu

---

## 🎯 Objetivo

Detectar, registrar y comparar todo lo que se instala en el sistema, tanto de forma manual como automática, integrando toda la trazabilidad dentro de `/mnt/hdd/Control_Instalaciones/`.

---

## 🧱 Estructura recomendada de archivos

Todos los scripts y registros deben almacenarse en:

```
/mnt/hdd/Control_Instalaciones/
├── historial_instalaciones_auto.log     → Registro automático desde terminal (bash/zsh)
├── instalaciones_software.txt           → Entradas manuales por fecha y categoría
├── lista_paquetes_dpkg.txt              → Snapshot actual de paquetes APT
├── lista_paquetes_snap.txt              → Snapshot actual de Snap
├── lista_paquetes_flatpak.txt           → Snapshot actual de Flatpak
├── lista_paquetes_dpkg_anterior.txt     → Snapshot anterior para comparación
├── diferencias_apt.txt                  → Salida del diff entre snapshots APT
├── actualizaciones.log                  → Log de ejecución del script
└── integridad_instaladores.md           → Registro de instaladores verificados
```

---

## ⚙️ Registro automático desde la terminal

Este registro captura comandos relacionados con instalaciones, tanto en Bash como en Zsh.

### Para usuarios de Bash (`~/.bashrc`)

Agregar al final del archivo:

```
log_installs() {
  case "$BASH_COMMAND" in
    *apt*|*dpkg*|*snap*|*flatpak*|*wget*|*curl*|*make*|*./configure*|*install*)
      echo "$(date '+%Y-%m-%d %H:%M:%S') - $BASH_COMMAND" >> /mnt/hdd/Control_Instalaciones/historial_instalaciones_auto.log
      ;;
  esac
}
trap log_installs DEBUG
```

Recargar con:

```
source ~/.bashrc
```

---

### Para usuarios de Zsh (`~/.zshrc`)

Agregar:

```
precmd() {
  if [[ "$BUFFER" == *apt* || "$BUFFER" == *dpkg* || "$BUFFER" == *snap* || "$BUFFER" == *flatpak* || "$BUFFER" == *wget* || "$BUFFER" == *curl* || "$BUFFER" == *make* || "$BUFFER" == *install* ]]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $BUFFER" >> /mnt/hdd/Control_Instalaciones/historial_instalaciones_auto.log
  fi
}
```

Recargar con:

```
source ~/.zshrc
```

---

## ✍️ Registro manual organizado por fecha

Para registrar instalaciones manuales, AppImages o paquetes externos.

Ejecuta:

```
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

## 🔁 Exportación y comparación de estado del sistema

La funcionalidad de exportar snapshots, detectar diferencias y registrar cambios está ahora centralizada en el script:

```
/mnt/hdd/Almacenamiento/Scripts/actualizar_historial_completo.sh
```

Este script realiza las siguientes tareas:

* Exporta listas actualizadas de paquetes APT, Snap y Flatpak
* Genera `lista_paquetes_dpkg_anterior.txt` automáticamente
* Compara y genera `diferencias_apt.txt`
* Registra cada ejecución en `actualizaciones.log`

---

## 📆 Automatización con `cron`

Para mantener el monitoreo activo semanalmente, programa el siguiente cronjob:

1. Abre el crontab del usuario:

```
crontab -e
```

2. Agrega esta línea al final:

```
0 10 * * 1 bash /mnt/hdd/Almacenamiento/Scripts/actualizar_historial_completo.sh
```

(Ejecuta todos los lunes a las 10:00 a.m.)

---

## 🔐 Verificación de integridad de instaladores

Lleva un registro manual de los instaladores descargados para asegurar autenticidad:

Edita:

```
nano /mnt/hdd/Control_Instalaciones/integridad_instaladores.md
```

Formato recomendado:

```
✅ balenaEtcher-linux-x64-2.1.0.zip
  Fuente: https://www.balena.io
  SHA256: a1b2c3...

✅ VMware-Workstation-Full-17.6.3.bundle
  Fuente: https://www.vmware.com
  SHA256: d4e5f6...
```

Para obtener el hash:

```
sha256sum archivo
```

---

## ✅ Resultado final

* Registro automático desde la terminal
* Entradas manuales organizadas y claras
* Estado del sistema exportado y comparado
* Cambios rastreados semanalmente
* Log completo de acciones en el tiempo
* Todo respaldado en `/mnt/hdd`, organizado y listo para restaurar
