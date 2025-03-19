# Guía de Instalación y Configuración de Oracle XE 10g en Ubuntu

## 1. Verifica la arquitectura del sistema

1. Abre una terminal y ejecuta:
   ```bash
   uname -m
   ```
   - Si el resultado es `x86_64`, tu sistema es de **64 bits**. Deberás habilitar el soporte de multiarch i386.  
   - Si el resultado es `i686` o similar, tu sistema es de **32 bits** y no necesitarás habilitar multiarch.

---

## 2. Ubica la carpeta `Linux-DEB` y comprueba los paquetes

1. Navega a la carpeta donde tienes los archivos `.deb` de Oracle XE. Por ejemplo:
   ```bash
   cd /root/Linux-DEB
   ```
   (Asegúrate de que la ruta sea correcta según donde hayas descargado los archivos).

2. Verifica el contenido de la carpeta ejecutando:
   ```bash
   ls
   ```
   Deberías ver al menos los siguientes archivos:
   ```
   oracle-xe-universal_10.2.0.1-1.1_i386.deb
   oracle-xe-client_10.2.0.1-1.2_i386.deb
   libaio_0.3.104-1_i386.deb
   install.sh
   ```

---

## 3. Ejecuta el script `install.sh` (Recomendado)

Si existe el script `install.sh`, puedes usarlo para automatizar la instalación. Este script realiza lo siguiente:

1. **Verifica la arquitectura del sistema** y habilita soporte para i386 si es necesario.
2. **Instala las dependencias** requeridas (solo para sistemas de 64 bits).
3. **Instala los paquetes `.deb`** de Oracle XE usando `--force-architecture`.
4. **Configura Oracle XE** automáticamente.
5. **Ajusta las variables de entorno** para que Oracle funcione correctamente.

### Pasos para usar el script:

1. Asegúrate de que el script sea ejecutable:
   ```bash
   chmod +x install.sh
   ```

2. Ejecuta el script:
   ```bash
   ./install.sh
   ```

---

### Contenido del Script `install.sh`

```bash
#!/bin/bash

# Verificar la arquitectura del sistema
ARCH=$(uname -m)

# Si el sistema es de 64 bits, habilitar multiarch i386 y instalar dependencias
if [ "$ARCH" = "x86_64" ]; then
    echo "Sistema de 64 bits detectado. Habilitando soporte para i386..."
    sudo dpkg --add-architecture i386
    sudo apt-get update
    echo "Instalando dependencias necesarias para i386..."
    sudo apt-get install -y libaio1:i386
fi

# Instalar los paquetes .deb con --force-architecture
echo "Instalando paquetes de Oracle XE..."
sudo dpkg -i --force-architecture \
    libaio_0.3.104-1_i386.deb \
    oracle-xe-client_10.2.0.1-1.2_i386.deb \
    oracle-xe-universal_10.2.0.1-1.1_i386.deb

# Configurar Oracle XE
echo "Configurando Oracle XE..."
sudo /etc/init.d/oracle-xe configure

# Ajustar variables de entorno
echo "Configurando variables de entorno..."
echo "export ORACLE_HOME=/usr/lib/oracle/xe/app/oracle/product/10.2.0/server" >> ~/.bashrc
echo "export ORACLE_SID=XE" >> ~/.bashrc
echo "export PATH=\$PATH:\$ORACLE_HOME/bin" >> ~/.bashrc
echo "unset TWO_TASK" >> ~/.bashrc

# Recargar el archivo .bashrc
source ~/.bashrc

echo "Instalación y configuración completadas."
```

---

## 4. Instalación Manual (Opcional)

Si prefieres realizar la instalación manualmente, sigue estos pasos:

### 4.1. (Solo para sistemas de 64 bits) Habilita i386 y dependencias

1. **Habilita la arquitectura i386**:
   ```bash
   sudo dpkg --add-architecture i386
   sudo apt-get update
   ```

2. **Instala la biblioteca `libaio1:i386`**:
   ```bash
   sudo apt-get install libaio1:i386
   ```

### 4.2. Instala los paquetes `.deb` de Oracle

Dentro de la carpeta `Linux-DEB`, ejecuta:
```bash
sudo dpkg -i --force-architecture \
    libaio_0.3.104-1_i386.deb \
    oracle-xe-client_10.2.0.1-1.2_i386.deb \
    oracle-xe-universal_10.2.0.1-1.1_i386.deb
```

### 4.3. Configura Oracle XE

Ejecuta el asistente de configuración:
```bash
sudo /etc/init.d/oracle-xe configure
```

---

## 5. Ajusta las variables de entorno

Para que `sqlplus` funcione correctamente, configura las variables de entorno:

```bash
echo "export ORACLE_HOME=/usr/lib/oracle/xe/app/oracle/product/10.2.0/server" >> ~/.bashrc
echo "export ORACLE_SID=XE" >> ~/.bashrc
echo "export PATH=\$PATH:\$ORACLE_HOME/bin" >> ~/.bashrc
echo "unset TWO_TASK" >> ~/.bashrc
```

Luego, recarga el archivo de configuración:
```bash
source ~/.bashrc
```

---

## 6. Arrancar, detener y verificar Oracle XE

1. **Iniciar Oracle XE**:
   ```bash
   sudo /etc/init.d/oracle-xe start
   ```

2. **Detener Oracle XE**:
   ```bash
   sudo /etc/init.d/oracle-xe stop
   ```

3. **Verificar el estado**:
   ```bash
   ps -ef | grep oracle
   ```
   Deberías ver procesos como `ora_pmon_XE`.

---

## 7. Acceso a SQL*Plus

1. **Como SYS** con contraseña:
   ```bash
   sqlplus SYS/tupassword AS SYSDBA
   ```

2. **Como SYSTEM**:
   ```bash
   sqlplus SYSTEM/tupassword@XE
   ```

3. **Conexión interna (sin contraseña)**:
   - Asegúrate de que tu usuario pertenezca al grupo `dba`.
   - Verifica que `ORACLE_SID=XE` y `ORACLE_HOME` estén definidas.
   - Ejecuta:
     ```bash
     sqlplus / as sysdba
     ```

---


## 8. Uso y consejos finales

### Creación de usuarios y asignación de privilegios

1. **Crear un usuario**:
   ```sql
   CREATE USER mi_usuario IDENTIFIED BY mi_clave
   DEFAULT TABLESPACE users
   TEMPORARY TABLESPACE temp
   QUOTA UNLIMITED ON users;
   ```

2. **Asignar privilegios**:
   ```sql
   GRANT CONNECT, RESOURCE TO mi_usuario;
   GRANT ALL PRIVILEGES TO mi_usuario; -- Para dar todos los privilegios
   ```

3. **Consultar usuarios existentes**:
   ```sql
   SELECT username FROM dba_users;
   ```

4. **Ver tablas del usuario actual**:
   ```sql
   SELECT table_name FROM user_tables;
   ```

5. **Consultar la versión de Oracle**:
   ```sql
   SELECT * FROM V$VERSION;
   ```

---

### Mini Guía Adicional

#### Creación de usuarios y asignación de privilegios

1. **Crear un usuario con todos los privilegios**:
   ```sql
   CREATE USER nuevo_usuario IDENTIFIED BY contraseña;
   GRANT ALL PRIVILEGES TO nuevo_usuario;
   ```

2. **Verificar usuarios y roles**:
   ```sql
   SELECT * FROM dba_users;
   SELECT * FROM dba_roles;
   ```

3. **Imprimir las tablas del usuario actual**:
   ```sql
   SELECT table_name FROM user_tables;
   ```

4. **Eliminar un usuario**:
   ```sql
   DROP USER nuevo_usuario CASCADE;
   ```
---

## 9. Mejora la experiencia de SQL*Plus con `rlwrap`

`rlwrap` es una herramienta que envuelve comandos de línea de comandos (como `sqlplus`) para proporcionar funcionalidades adicionales, como:
- **Historial de comandos**: Permite navegar por comandos anteriores usando las flechas ↑ y ↓.
- **Edición de líneas**: Facilita la corrección de errores en comandos largos.
- **Autocompletado**: Soporta autocompletado básico (útil para nombres de tablas o comandos).

### 9.1. Instalación de `rlwrap`

1. En distribuciones basadas en Debian/Ubuntu:
   ```bash
   sudo apt-get install rlwrap
   ```

2. En distribuciones basadas en Red Hat/CentOS:
   ```bash
   sudo yum install rlwrap
   ```

3. En Arch Linux:
   ```bash
   sudo pacman -S rlwrap
   ```

### 9.2. Uso de `rlwrap` con `sqlplus`

Para usar `rlwrap` con `sqlplus`, simplemente antepone `rlwrap` al comando `sqlplus`. Por ejemplo:

1. **Conexión como SYS**:
   ```bash
   rlwrap sqlplus SYS/tupassword AS SYSDBA
   ```

2. **Conexión como SYSTEM**:
   ```bash
   rlwrap sqlplus SYSTEM/tupassword@XE
   ```

3. **Conexión interna (sin contraseña)**:
   ```bash
   rlwrap sqlplus / as sysdba
   ```

### 9.3. Configuración permanente de `rlwrap`

Si deseas usar `rlwrap` automáticamente cada vez que ejecutes `sqlplus`, puedes crear un alias en tu archivo de configuración de shell (`~/.bashrc` o `~/.zshrc`):

1. Abre el archivo de configuración:
   ```bash
   nano ~/.bashrc
   ```

2. Añade el siguiente alias:
   ```bash
   alias sqlplus='rlwrap sqlplus'
   ```

3. Guarda los cambios y recarga el archivo:
   ```bash
   source ~/.bashrc
   ```

Ahora, cada vez que ejecutes `sqlplus`, se usará automáticamente `rlwrap`.

### 9.4. Beneficios de usar `rlwrap`

- **Historial de comandos**: Puedes recuperar comandos anteriores usando las flechas ↑ y ↓.
- **Edición de líneas**: Corrección de errores en comandos largos sin tener que reescribirlos.
- **Autocompletado**: Aunque no es tan avanzado como en un IDE, ayuda a completar nombres de tablas o comandos.
- **Mejor experiencia en general**: Hace que trabajar con `sqlplus` sea más cómodo y productivo.

---

### Ejemplo de uso con `rlwrap`

1. Conéctate a `sqlplus` usando `rlwrap`:
   ```bash
   rlwrap sqlplus SYSTEM/tupassword@XE
   ```

2. Ejecuta algunos comandos SQL:
   ```sql
   SELECT * FROM user_tables;
   ```

3. Usa las flechas ↑ y ↓ para navegar por el historial de comandos.

4. Edita comandos largos directamente en la línea de comandos.

---

## Nota final

- **A la fecha de hoy (marzo de 2025)**, Oracle XE 10g sigue funcionando en la mayoría de distribuciones modernas con los ajustes de multiarch.  
- **Revisa regularmente** la compatibilidad de 32 bits en nuevas distribuciones, ya que el soporte para librerías i386 podría eliminarse en el futuro.  
- **Alternativa recomendada**: Usa una **máquina virtual (VM)** o un **contenedor Docker** de 32 bits para aislar Oracle XE 10g y evitar conflictos con el sistema principal.

---

### Mini Guía Adicional

#### Creación de usuarios y asignación de privilegios

1. **Crear un usuario con todos los privilegios**:
   ```sql
   CREATE USER nuevo_usuario IDENTIFIED BY contraseña;
   GRANT ALL PRIVILEGES TO nuevo_usuario;
   ```

2. **Verificar usuarios y roles**:
   ```sql
   SELECT * FROM dba_users;
   SELECT * FROM dba_roles;
   ```

3. **Imprimir las tablas de un usuario**:
   ```sql
   SELECT table_name FROM all_tables WHERE owner = 'NUEVO_USUARIO';
   ```

4. **Eliminar un usuario**:
   ```sql
   DROP USER nuevo_usuario CASCADE;
   ```
