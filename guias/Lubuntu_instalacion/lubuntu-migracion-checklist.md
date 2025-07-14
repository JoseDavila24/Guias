# ✅ Checklist para migrar e instalar Lubuntu con respaldo en HDD (`/mnt/hdd`)

## 🔐 ANTES DE INSTALAR LUBUNTU

1. **Verifica que el respaldo está completo:**

   * Asegúrate de que la carpeta `/mnt/hdd/Backups/home_full/` contenga tus carpetas personales: `Documents`, `Pictures`, `Videos`, etc.
   * Confirma que también están respaldados:

     * Scripts personales (`/mnt/hdd/Almacenamiento/Scripts`)
     * Instaladores y archivos ISO (`/mnt/hdd/Almacenamiento/Instaladores` y `ISOs`)
     * Proyectos personales y profesionales (`/mnt/hdd/Proyectos`)

2. **Revisa el estado del HDD:**

   * Monta el disco si aún no lo está:

     ```bash
     sudo mkdir -p /mnt/hdd
     sudo mount /dev/sdb1 /mnt/hdd
     ```
   * Accede al contenido y verifica que todo esté disponible.

3. **Desmonta el HDD de forma segura antes de comenzar la instalación:**

   ```bash
   sudo umount /mnt/hdd
   ```

4. **Cierra todos los programas abiertos.**

---

## 💿 DURANTE LA INSTALACIÓN DE LUBUNTU

1. **Tipo de instalación:**

   * Elige *Instalación manual* o *"Instalar junto a otros sistemas"*, según el caso.

2. **Cuida el disco HDD (`/dev/sdb1`):**

   * **NO** lo formatees ni lo toques en el particionado.
   * **NO** lo montes como `/home` ni ninguna otra partición del sistema.

3. **Selecciona el SSD (`/dev/sda`) para instalar Lubuntu.**

---

## 🔁 DESPUÉS DE INSTALAR LUBUNTU

1. **Montar automáticamente el HDD en cada inicio:**

   1.1. Crear el punto de montaje:

   ```bash
   sudo mkdir -p /mnt/hdd
   ```

   1.2. Obtener el UUID del disco:

   ```bash
   sudo blkid
   ```

   1.3. Editar el archivo `/etc/fstab` de forma segura:

   ```bash
   sudo cp /etc/fstab /etc/fstab.bak  # Respaldo
   sudo nano /etc/fstab
   ```

   1.4. Añadir la siguiente línea al final del archivo:

   ```
   UUID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx  /mnt/hdd  ext4  defaults  0  2
   ```

   > ⚠️ Reemplaza el UUID y tipo de sistema de archivos según lo que muestra `blkid` (puede ser `ext4`, `ntfs`, etc.).

   1.5. Aplicar los cambios:

   ```bash
   sudo mount -a
   sudo chown -R $USER:$USER /mnt/hdd
   ```

   1.6. Verificar que todo esté montado correctamente:

   ```bash
   df -h | grep hdd
   ```

---

## 🔒 CONSEJOS DE SEGURIDAD Y RECUPERACIÓN

* Siempre haz una copia de seguridad de tu archivo `fstab` antes de modificarlo:

  ```bash
  sudo cp /etc/fstab /etc/fstab.bak
  ```

* Si el sistema no arranca después de modificar `fstab`, arranca desde un LiveUSB, monta el disco raíz y corrige el archivo con:

  ```bash
  sudo nano /mnt/sda1/etc/fstab
  ```

---

## 🧠 CONSEJO ADICIONAL

Guarda esta checklist dentro de `/mnt/hdd/Almacenamiento/Scripts/` o crea un alias en tu `.bashrc` para consultarla fácilmente:

```bash
alias checklist='less /mnt/hdd/Almacenamiento/Scripts/lubuntu-migracion-checklist'
```
