# QEMU – Guía básica de uso (caso general)

## 1. Crear disco virtual

Usa `qemu-img` para crear un disco **qcow2** (más eficiente y portable):

```bash
qemu-img create -f qcow2 nombre-vm.qcow2 20G
```

* `-f qcow2` → formato qcow2 (soporta snapshots, compresión).
* `20G` → tamaño máximo (se va ocupando dinámicamente).

Ver información del disco:

```bash
qemu-img info nombre-vm.qcow2
```

---

## 2. Instalar el sistema desde un ISO

Primera vez, arrancas con el **ISO de instalación**:

```bash
qemu-system-x86_64 \
  -m 2G \
  -smp 2 \
  --enable-kvm \
  -name "MiVM" \
  -boot d \
  -hda nombre-vm.qcow2 \
  -cdrom sistema-operativo.iso
```

🔹 Parámetros importantes:

* `-m 2G` → memoria RAM asignada (en MB).
* `-smp 2` → número de CPUs virtuales.
* `--enable-kvm` → aceleración por hardware (mucho más rápido).
* `-name "MiVM"` → nombre de la máquina virtual.
* `-boot d` → arranca desde CD/DVD (ISO).
* `-hda nombre-vm.qcow2` → disco duro virtual.
* `-cdrom sistema-operativo.iso` → ISO de instalación del SO.

---

## 3. Arrancar la VM (sin ISO)

Una vez instalado el sistema operativo, arranca solo desde el disco:

```bash
qemu-system-x86_64 \
  -m 2G \
  -smp 2 \
  --enable-kvm \
  -name "MiVM" \
  -hda nombre-vm.qcow2
```

---

## 4. Controles en QEMU

* **Ctrl + Alt + G** → liberar ratón/teclado (como Ctrl+Alt en VMware).
* **Ctrl + Alt + F** → pantalla completa.
* **Ctrl + Alt + 2** → consola del monitor QEMU.

  * `quit` → apagar VM.
  * `info status` → estado de la VM.
* **Ctrl + Alt + 1** → volver a la pantalla de la VM.

---

## 5. Opciones útiles

* Ejecutar sin ventana gráfica (**modo servidor**):

  ```bash
  -nographic
  ```
* Montar una ISO extra:

  ```bash
  -cdrom ruta/otro.iso
  ```
* Red NAT (internet básico):

  ```bash
  -net nic -net user
  ```

---
