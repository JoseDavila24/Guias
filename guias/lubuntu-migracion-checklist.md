
# ✅ **Checklist de Instalación de Lubuntu con Respaldo en HDD**


## 🔐 ANTES DE INSTALAR LUBUNTU

* Verifiqué que el backup en `/mnt/hdd/Backups/home_full/` contiene todas mis carpetas esenciales.
* Revisé que también tengo guardados: instaladores, ISOs, scripts, proyectos, etc.
* El HDD (`/dev/sdb1`) está montado en `/mnt/hdd` y accesible.
* Ejecuté `sudo umount /mnt/hdd` para desmontarlo correctamente.
* Cerré todos los programas antes de comenzar la instalación.

---

## 💿 DURANTE LA INSTALACIÓN DE LUBUNTU

* Elegí instalación manual o guiada en el **SSD (normalmente /dev/sda)**.
* NO toqué ni formateé `/dev/sdb1` (HDD).
* NO monté `/dev/sdb1` como `/home` ni como ninguna otra partición del sistema.
* Elegí **“Instalar Lubuntu junto a otros sistemas”** o **“Usar disco manualmente”**, según el caso.

---

## 🔁 DESPUÉS DE INSTALAR LUBUNTU

* Inicié Lubuntu correctamente desde el SSD.
* Abrí una terminal y ejecuté:

```bash
sudo mkdir -p /mnt/hdd         # Crear punto de montaje si no existe
sudo blkid                     # Obtener el UUID del HDD (/dev/sdb1)
```

* Edición segura de `/etc/fstab` para montaje automático:

```bash
sudo cp /etc/fstab /etc/fstab.bak  # Backup de seguridad
sudo nano /etc/fstab
```

* Dentro del archivo `fstab`, añadí al final esta línea (reemplaza el UUID por el tuyo):

```
UUID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx  /mnt/hdd  ext4  defaults  0  2
```

> 📌 Asegúrate de usar el UUID correcto y el tipo de sistema de archivos que corresponda (por ejemplo `ext4`, `ntfs`, `exfat`, etc.).

* Luego ejecuté:

```bash
sudo mount -a                             # Montar todo lo definido en fstab
sudo chown -R $USER:$USER /mnt/hdd        # Dar permisos al usuario
```

* Verifiqué que `/mnt/hdd` está montado correctamente:

```bash
df -h | grep hdd
```

---

## 🗃️ RECUPERACIÓN Y ORGANIZACIÓN

* Restauré mis archivos de backup desde `/mnt/hdd/Backups/home_full/` según necesidad.
* Accedí a mis proyectos, máquinas virtuales, instaladores, scripts y recursos desde:

```
/mnt/hdd/Almacen/
/mnt/hdd/Proyectos/
```

---

## 🔒 CONSEJO DE SEGURIDAD

Siempre haz un backup del archivo `/etc/fstab` antes de editarlo:

```bash
sudo cp /etc/fstab /etc/fstab.bak
```

Y si algo sale mal y tu sistema no arranca, puedes usar un LiveUSB para revertir los cambios.

---

Con esta lista, tu migración será **segura, profesional y sin pérdida de datos**, y el HDD quedará montado automáticamente en cada inicio.
