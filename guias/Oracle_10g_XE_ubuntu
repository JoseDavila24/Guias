## 1. Verifica la arquitectura del sistema

1. En una terminal, ejecuta:
   ```bash
   uname -m
   ```
   - Si aparece `x86_64`, tu sistema es de **64 bits**. Deberás habilitar el soporte de multiarch i386.  
   - Si muestra `i686` u otra variante de **32 bits**, no necesitarás multiarch.

---

## 2. Ubica la carpeta `Linux-DEB` y comprueba los paquetes

1. Sitúate en la carpeta donde tienes los archivos `.deb` de Oracle XE. Por ejemplo:
   ```bash
   cd /root/Linux-DEB
   ```
   (o donde la hayas descargado).
2. Ejecuta:
   ```bash
   ls
   ```
   Deberías ver al menos:
   ```
   oracle-xe-universal_10.2.0.1-1.1_i386.deb
   oracle-xe-client_10.2.0.1-1.2_i386.deb
   libaio_0.3.104-1_i386.deb
   (y posiblemente algún script install.sh)
   ```

---

## 3. (Solo si tu sistema es 64 bits) Habilita i386 y dependencias

Si tu **sistema es 64 bits**:

1. **Habilita** la arquitectura i386:
   ```bash
   sudo dpkg --add-architecture i386
   sudo apt-get update
   ```
2. **Instala** la biblioteca `libaio1:i386` (indispensable para Oracle XE):
   ```bash
   sudo apt-get install libaio1:i386
   ```
   Si el sistema te pide otras dependencias (por ejemplo `libstdc++6:i386`), instálalas también.

---

## 4. Instala los paquetes `.deb` de Oracle

Dentro de la carpeta `Linux-DEB`, instala con `dpkg`. A veces necesitarás `--force-architecture`:

```bash
sudo dpkg -i --force-architecture \
    libaio_0.3.104-1_i386.deb \
    oracle-xe-client_10.2.0.1-1.2_i386.deb \
    oracle-xe-universal_10.2.0.1-1.1_i386.deb
```

- Si no aparece error de arquitectura, puedes omitir `--force-architecture`.
- Asegúrate de que no haya errores de dependencia. De ser así, primero instala las librerías que falten.

---

## 5. Configura Oracle XE

Terminado el paso anterior, ejecuta:

```bash
sudo /etc/init.d/oracle-xe configure
```

El asistente te pedirá:
1. **Puerto** para la consola HTTP (por defecto 8080).  
2. **Puerto** para la base de datos (por defecto 1521).  
3. **Contraseña** para los usuarios `SYS` y `SYSTEM`.  
4. Si deseas que Oracle XE se inicie con cada arranque del sistema.

---

## 6. Ajusta las variables de entorno

Para que `sqlplus` funcione bien (y evitar errores como `sp1<lang>.msb not found`), exporta las variables principales. Suponiendo que Oracle XE quedó en:
```
/usr/lib/oracle/xe/app/oracle/product/10.2.0/server
```
haz lo siguiente:

```bash
echo "export ORACLE_HOME=/usr/lib/oracle/xe/app/oracle/product/10.2.0/server" >> ~/.bashrc
echo "export ORACLE_SID=XE" >> ~/.bashrc
echo "export PATH=\$PATH:\$ORACLE_HOME/bin" >> ~/.bashrc
echo "unset TWO_TASK" >> ~/.bashrc
```

Luego recarga tu archivo de configuración:
```bash
source ~/.bashrc
```

---

## 7. Arrancar, detener y verificar

1. **Iniciar** Oracle XE:
   ```bash
   sudo /etc/init.d/oracle-xe start
   ```
2. **Detener**:
   ```bash
   sudo /etc/init.d/oracle-xe stop
   ```
3. **Verificar** su estado:
   ```bash
   ps -ef | grep oracle
   ```
   Deberías ver procesos como `ora_pmon_XE`.

---

## 8. Acceso a SQL*Plus

1. **Como SYS** con contraseña:
   ```bash
   sqlplus SYS/tupassword AS SYSDBA
   ```
   o:
   ```bash
   sqlplus SYS/tupassword@XE AS SYSDBA
   ```
2. **Como SYSTEM**:
   ```bash
   sqlplus SYSTEM/tupassword@XE
   ```
3. **Conexión interna (sin contraseña)**:
   - Tu usuario de Linux debe pertenecer al grupo `dba`.
   - Debes tener `ORACLE_SID=XE` y `ORACLE_HOME` definidas, y `unset TWO_TASK`.
   - Entonces:
     ```bash
     sqlplus / as sysdba
     ```
     Si aparece `ORA-12162`, es porque falta alguna variable de entorno o tu usuario no pertenece al grupo adecuado.

---

## 9. Uso y consejos finales

- **Crear un usuario** propio:
  ```sql
  CREATE USER mi_usuario IDENTIFIED BY mi_clave
  DEFAULT TABLESPACE users
  TEMPORARY TABLESPACE temp
  QUOTA UNLIMITED ON users;

  GRANT CONNECT, RESOURCE TO mi_usuario;
  ```
- **Consultar versión**:
  ```sql
  SELECT * FROM V$VERSION;
  ```
- **Portal de administración web**: Si configuraste el puerto 8080, puedes acceder vía `http://localhost:8080/` en tu navegador (usuario `SYSTEM` o `SYS`).

---

## Nota final

- **A la fecha de hoy (marzo de 2025), Oracle XE 10g sigue funcionando** en la mayoría de distribuciones modernas con los ajustes de multiarch.  
- **Sin embargo**, conviene **revisar regularmente** la compatibilidad de 32 bits en distros nuevas, ya que podrían ir eliminando soporte para librerías i386 con el paso del tiempo.  
- **Alternativa recomendada**: usar una **VM** o un **contenedor Docker** de 32 bits para aislar Oracle XE 10g y evitar conflictos con el sistema principal.
