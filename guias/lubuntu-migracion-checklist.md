# ✅ **Checklist de Instalación de Lubuntu con Respaldo en HDD**

## 🔐 ANTES DE INSTALAR LUBUNTU

* Verifiqué que el backup en `/mnt/hdd/Backups/home_full/` contiene todas mis carpetas esenciales.
* Revisé que también tengo guardados: instaladores, ISOs, scripts, proyectos, etc.
* El HDD (`/dev/sdb1`) está montado en `/mnt/hdd` y accesible.
* Ejecuté `sudo umount /mnt/hdd` para desmontarlo correctamente.
* Cerré todos los programas antes de comenzar la instalación.

## 💿 DURANTE LA INSTALACIÓN DE LUBUNTU

* Elegí instalación manual o guiada en el **SSD (normalmente /dev/sda)**.
* NO toqué ni formateé `/dev/sdb1` (HDD).
* NO monté `/dev/sdb1` como `/home` ni como ninguna otra partición del sistema.
* Elegí **“Instalar Lubuntu junto a otros sistemas”** o **“Usar disco manualmente”**, según el caso.

## 🔁 DESPUÉS DE INSTALAR LUBUNTU

* Inicié Lubuntu correctamente desde el SSD.
* Abrí una terminal y ejecuté:

```bash
sudo mkdir -p /mnt/hdd
sudo blkid    # Para obtener UUID de /dev/sdb1
sudo nano /etc/fstab   # Agregué línea con UUID y punto de montaje
sudo mount -a
sudo chown -R $USER:$USER /mnt/hdd
```

* Verifiqué que `/mnt/hdd` aparece en `df -h` y puedo acceder a mis archivos.

## 🗃️ RECUPERACIÓN Y ORGANIZACIÓN

* Restauré mis archivos de backup desde `/mnt/hdd/Backups/home_full/` según necesidad.
* Accedí a mis proyectos, VMs, instaladores, scripts y recursos desde sus carpetas en `/mnt/hdd/Almacen/` y `/mnt/hdd/Proyectos/`.

Con esta lista, tu migración será **segura, profesional y sin pérdida de datos**.
