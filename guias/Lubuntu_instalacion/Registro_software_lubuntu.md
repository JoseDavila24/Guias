# 🧠 Control Total de Instalaciones y Cambios en Lubuntu

### 🎯 Objetivo: Detectar, registrar y comparar todo lo que se instala en tu sistema (manualmente o automáticamente)

---

## 🧱 1. Estructura recomendada de archivos

Todos los scripts y registros vivirán en:

```
/mnt/hdd/Control_Instalaciones/
├── historial_instalaciones_auto.log     # Registro automático (bash/zsh)
├── instalaciones_software.txt           # Entradas manuales por categoría
├── lista_paquetes_dpkg.txt              # Snapshot actual de APT
├── lista_paquetes_snap.txt              # Snapshot actual de Snap
├── lista_paquetes_flatpak.txt           # Snapshot actual de Flatpak
├── lista_paquetes_dpkg_anterior.txt     # Snapshot anterior (para comparar)
├── diferencias_apt.txt                  # Salida del diff entre snapshots
├── actualizaciones.log                  # Log general de ejecuciones
└── integridad_instaladores.md           # Verificación de fuentes
```

---

## ⚙️ 2. Registro automático en terminal

### 🟦 Para Bash (`~/.bashrc`)

Agrega al final:

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

```bash
source ~/.bashrc
```

---

### 🟪 Para Zsh (`~/.zshrc`)

Agrega:

```zsh
precmd() {
  if [[ "$BUFFER" == *apt* || "$BUFFER" == *dpkg* || "$BUFFER" == *snap* || "$BUFFER" == *flatpak* || "$BUFFER" == *wget* || "$BUFFER" == *curl* || "$BUFFER" == *make* || "$BUFFER" == *install* ]]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $BUFFER" >> /mnt/hdd/Control_Instalaciones/historial_instalaciones_auto.log
  fi
}
```

```bash
source ~/.zshrc
```

---

## ✍️ 3. Registro manual organizado por fecha

Edita el archivo:

```bash
nano /mnt/hdd/Control_Instalaciones/instalaciones_software.txt
```

Formato de entrada:

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

## 📦 4. Script: Exportar estado actual del sistema

```bash
#!/bin/bash
# ~/actualizar_historial.sh

set -e
HIST_DIR="/mnt/hdd/Control_Instalaciones"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

echo "🔄 Exportando estado actual del sistema..."

dpkg --get-selections > "$HIST_DIR/lista_paquetes_dpkg.txt"
snap list > "$HIST_DIR/lista_paquetes_snap.txt" 2>/dev/null || true
flatpak list > "$HIST_DIR/lista_paquetes_flatpak.txt" 2>/dev/null || true

echo "✅ Historial actualizado: $DATE" >> "$HIST_DIR/actualizaciones.log"
```

```bash
chmod +x ~/actualizar_historial.sh
```

---

## 🧪 5. Script: Detectar diferencias de paquetes APT entre capturas

```bash
#!/bin/bash
# ~/comparar_cambios_dpkg.sh

set -e
DIR="/mnt/hdd/Control_Instalaciones"
OLD="$DIR/lista_paquetes_dpkg_anterior.txt"
NEW="$DIR/lista_paquetes_dpkg.txt"
OUT="$DIR/diferencias_apt.txt"

# Mueve la versión actual a anterior (si existe)
[ -f "$NEW" ] && mv "$NEW" "$OLD"

# Genera nuevo snapshot
dpkg --get-selections > "$NEW"

# Compara versiones
diff -u "$OLD" "$NEW" > "$OUT" || echo "🔍 No hay diferencias relevantes"

echo "📑 Comparación exportada a $OUT"
```

```bash
chmod +x ~/comparar_cambios_dpkg.sh
```

---

## 📅 6. Automatización con cron

Ejecuta:

```bash
crontab -e
```

Agrega estas líneas (ejecuta los lunes a las 10 a.m.):

```
0 10 * * 1 bash ~/actualizar_historial.sh
0 10 * * 1 bash ~/comparar_cambios_dpkg.sh
```

---

## 🔐 7. Archivo de integridad (opcional pero recomendado)

Edita:

```bash
nano /mnt/hdd/Control_Instalaciones/integridad_instaladores.md
```

Formato:

```
✅ balenaEtcher-linux-x64-2.1.0.zip
  Fuente: https://www.balena.io
  SHA256: [copia desde sha256sum archivo]

✅ VMware-Workstation-Full-17.6.3.bundle
  Fuente: https://www.vmware.com
```

Para obtener el hash:

```bash
sha256sum archivo
```

---

## ✅ Resultado final

✔️ Tienes registro automático desde terminal
✔️ Puedes escribir entradas manuales ordenadas
✔️ Cada semana puedes detectar cualquier cambio en tu sistema
✔️ Todo respaldado en tu HDD, centralizado, organizado y auditable
