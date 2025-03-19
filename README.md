# Guía Optimizada de Instalación y Configuración de Oracle XE 10g en Ubuntu

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

## 5. Configura acceso a SQL*Plus con `rlwrap` (Optimizado)

`rlwrap` mejora la experiencia al usar SQL*Plus:

### Instalación:
```bash
sudo apt-get install rlwrap
```

### Configuración permanente:
Edita el archivo `~/.zshrc` o `~/.bashrc` según tu shell (`zsh` recomendado):
```bash
nano ~/.zshrc
```

Agrega el alias:
```bash
alias sqlplus='rlwrap sqlplus'
```

Guarda y aplica cambios:
```bash
source ~/.zshrc
```

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

-- Configuración visual
SET LINESIZE 250
SET PAGESIZE 500
SET WRAP ON
SET FEEDBACK ON
SET TRIMSPOOL ON
SET VERIFY OFF
SET COLSEP ' | '
SET HEADING ON

-- Formato predeterminado mejorado para columnas comunes
COLUMN ISBN FORMAT A20 HEADING 'ISBN'
COLUMN TITULO FORMAT A60 HEADING 'Título'
COLUMN AUTOR FORMAT A40 HEADING 'Autor'
COLUMN table_name FORMAT A30 HEADING 'Nombre de Tabla'
COLUMN tablespace_name FORMAT A20 HEADING 'Tablespace'
COLUMN status FORMAT A10 HEADING 'Estado'
COLUMN num_rows FORMAT 999,999,999 HEADING 'Número de Filas'
COLUMN last_analyzed FORMAT A20 HEADING 'Último Análisis'

-- Formato estándar para fechas
ALTER SESSION SET NLS_DATE_FORMAT='DD-MON-YYYY HH24:MI';

-- Mensaje inicial personalizado y ordenado visualmente
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

