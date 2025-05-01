# Guía Optimizada de Instalación y Configuración de Oracle XE 10g en Ubuntu

### Importante: Actualización del Sistema
**Descripción:**  
Actualiza el sistema para asegurarte de contar con las últimas mejoras y parches de seguridad.

**Comando:**
```bash
sudo apt update && sudo apt full-upgrade -y && sudo apt autoremove -y && sudo apt clean
```
- 🔄 *apt update:* Actualiza la lista de paquetes.  
- ⬆️ *apt full-upgrade:* Instala todas las actualizaciones disponibles.  
- 🧹 *apt autoremove:* Elimina paquetes innecesarios.  
- 🗑️ *apt clean:* Limpia archivos temporales.

## 1. Verifica la arquitectura del sistema

```bash
uname -m
```
- `x86_64`: 64 bits (habilita multiarch)
- `i686`: 32 bits (sin cambios)

## 2. Descargar archivos necesarios

Descarga la carpeta llamada `Oracle10gXE` usando el siguiente comando desde la terminal:

```bash
wget -O Oracle10gXE.zip "https://www.dropbox.com/scl/fi/scmu10zr2zfzwh9mkje6z/Oracle10gXE.zip?rlkey=xyl0606by1fjw5jy7rpv4qszk&st=cr718ejs&dl=1"
```

Luego, extrae los archivos:

```bash
unzip Oracle10gXE.zip
```

## 3. Instalación mediante scripts

Dentro de la carpeta `Oracle10gXE/Linux-DEB`, asegúrate de tener estos archivos:
- `oracle-xe-universal_10.2.0.1-1.1_i386.deb`
- `oracle-xe-client_10.2.0.1-1.2_i386.deb`
- `libaio_0.3.104-1_i386.deb`

Luego, crea los siguientes scripts en la misma carpeta:

### Script 1: `multiarch-setup.sh` (Solo para sistemas de 64 bits)

```bash
#!/bin/bash

ARCH=$(uname -m)

if [ "$ARCH" = "x86_64" ]; then
    echo "Sistema de 64 bits detectado. Habilitando soporte para i386..."
    sudo dpkg --add-architecture i386
    sudo apt-get update
    echo "Instalando dependencias necesarias para i386..."
    sudo apt-get install -y libaio1:i386
    sudo apt --fix-broken install -y
else
    echo "Sistema de 32 bits detectado. No es necesario realizar cambios adicionales."
fi
```

### Script 2: `oracle-xe-install.sh`

```bash
#!/bin/bash

# Instalar paquetes .deb con --force-architecture
echo "Instalando paquetes de Oracle XE..."
sudo dpkg -i --force-architecture \
    libaio_0.3.104-1_i386.deb \
    oracle-xe-client_10.2.0.1-1.2_i386.deb \
    oracle-xe-universal_10.2.0.1-1.1_i386.deb

# Corregir posibles dependencias faltantes
echo "Corrigiendo posibles dependencias faltantes..."
sudo apt --fix-broken install -y

# Instalar rlwrap para mejorar la experiencia en SQL*Plus
echo "Instalando rlwrap para mejorar la experiencia en SQL*Plus..."
sudo apt-get install -y rlwrap

# Configurar Oracle XE
echo "Configurando Oracle XE..."
sudo /etc/init.d/oracle-xe configure

# Ajustar variables de entorno
echo "Configurando variables de entorno..."
echo "export ORACLE_HOME=/usr/lib/oracle/xe/app/oracle/product/10.2.0/server" >> ~/.bashrc
echo "export ORACLE_SID=XE" >> ~/.bashrc
echo "export PATH=\$PATH:\$ORACLE_HOME/bin" >> ~/.bashrc
echo "unset TWO_TASK" >> ~/.bashrc

# Añadir alias para usar rlwrap automáticamente con sqlplus
echo "Configurando alias para sqlplus..."
echo "alias sqlplus='rlwrap sqlplus'" >> ~/.bashrc

# Recargar el archivo .bashrc
source ~/.bashrc

# Mensaje final con ejemplos de uso
echo "Instalación y configuración completadas."
echo ""
echo "Para iniciar sesión en SQL*Plus, usa los siguientes comandos:"
echo "  sqlplus SYS/tu_contraseña AS SYSDBA"
echo "  sqlplus SYSTEM/tu_contraseña"
echo ""
echo "El alias 'sqlplus' ya está configurado para usar rlwrap automáticamente."
```

### Ejecución de scripts:

```bash
cd Oracle10gXE/Linux-DEB
chmod +x multiarch-setup.sh oracle-xe-install.sh

# Solo si es necesario (sistema 64 bits)
./multiarch-setup.sh

# Instalación y configuración Oracle XE
./oracle-xe-install.sh
```

## 4. Arrancar, detener y verificar Oracle XE

```bash
sudo /etc/init.d/oracle-xe start    # Iniciar
sudo /etc/init.d/oracle-xe stop     # Detener
ps -ef | grep oracle                # Verificar procesos
```

---

## 5. Ejemplos de cómo iniciar sesión en SQL*Plus

Una vez completada la instalación y configuración, puedes iniciar sesión en SQL*Plus usando el alias `sqlplus`, que ya incluye `rlwrap` automáticamente. Aquí tienes algunos ejemplos:

### Iniciar sesión como `SYS` (usuario administrador):
```bash
sqlplus SYS/tu_contraseña AS SYSDBA
```

### Iniciar sesión como `SYSTEM` (usuario administrativo):
```bash
sqlplus SYSTEM/tu_contraseña
```

### Iniciar sesión con un usuario creado:
Si has creado un usuario (por ejemplo, `nuevo_usuario`), puedes iniciar sesión de la siguiente manera:
```bash
sqlplus nuevo_usuario/contraseña
```

### Verificar la conexión:
Una vez dentro de SQL*Plus, puedes ejecutar consultas SQL para verificar que todo funciona correctamente. Por ejemplo:
```sql
SELECT * FROM v$version;
```

---

### Notas adicionales:
- El alias `sqlplus` ya está configurado para usar `rlwrap`, lo que permite navegar por el historial de comandos y mejorar la experiencia en la línea de comandos.
- Si necesitas desactivar `rlwrap` temporalmente, puedes usar el comando completo:
  ```bash
  /usr/lib/oracle/xe/app/oracle/product/10.2.0/server/bin/sqlplus
  ```

---

## 6. Gestión básica de usuarios

```sql
-- Crear usuario
CREATE USER nuevo_usuario IDENTIFIED BY contraseña;
GRANT CONNECT, RESOURCE TO nuevo_usuario;

-- Dar todos los privilegios al usuario
GRANT ALL PRIVILEGES TO nuevo_usuario;

-- Ver usuarios y roles
SELECT * FROM dba_users;
SELECT * FROM dba_roles;

-- Tablas del usuario actual
SELECT table_name FROM user_tables;

-- Eliminar usuario
DROP USER nuevo_usuario CASCADE;
```

---

## 7. Configuración automática para SQL*Plus (`login.sql`)

Crea un archivo llamado **`login.sql`** con el siguiente contenido mejorado, el cual establece automáticamente un formato claro y legible cada vez que inicies sesión en SQL*Plus:

```sql
-- login.sql - configuración automática mejorada para SQL*Plus

SET LINESIZE 200
SET PAGESIZE 50
SET WRAP OFF
SET FEEDBACK ON
SET TRIMSPOOL ON
SET VERIFY OFF
SET COLSEP ' | '
SET HEADING ON
SET NULL 'N/A'

ALTER SESSION SET NLS_DATE_FORMAT='DD-MON-YYYY HH24:MI';

PROMPT *********************************************************
PROMPT *            Bienvenido a SQL*Plus (Biblioteca)         *
PROMPT *                                                       *
PROMPT * Configuración automática cargada correctamente        *
PROMPT *********************************************************
```

Guarda el archivo `login.sql` en el directorio desde el cual ejecutas SQL*Plus para que la configuración se cargue automáticamente al iniciar cada sesión. Esto facilitará la lectura, análisis y presentación de los resultados en tus consultas SQL.

## Nota final
- Oracle XE 10g funciona en sistemas modernos usando multiarch.
- Considera una máquina virtual, Docker o contenedores LXD como alternativa recomendada para aislar Oracle XE 10g y evitar conflictos futuros con la arquitectura i386, especialmente cuando se trabaja en un host Ubuntu.

