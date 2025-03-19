# Guía Optimizada de Instalación y Configuración de Oracle XE 10g en Ubuntu

## 1. Verifica la arquitectura del sistema

```bash
uname -m
```
- `x86_64`: 64 bits (habilita multiarch)
- `i686`: 32 bits (sin cambios)

## 2. Instalación mediante scripts

Descarga o prepara los siguientes archivos en la carpeta `Linux-DEB`:
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
cd /ruta/Linux-DEB
chmod +x multiarch-setup.sh oracle-xe-install.sh

# Solo si es necesario (sistema 64 bits)
./multiarch-setup.sh

# Instalación y configuración Oracle XE
./oracle-xe-install.sh
```

## 3. Arrancar, detener y verificar Oracle XE

```bash
sudo /etc/init.d/oracle-xe start    # Iniciar
sudo /etc/init.d/oracle-xe stop     # Detener
ps -ef | grep oracle                # Verificar procesos
```

## 4. Configura acceso a SQL*Plus con `rlwrap` (Optimizado)

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

## 5. Gestión básica de usuarios

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

## 6. Script adicional para SQL*Plus (`login.sql`)

Crea un archivo llamado `login.sql` con el siguiente contenido para mejorar automáticamente tu experiencia en SQL*Plus:

```sql
-- login.sql - configuración automática para SQL*Plus

-- Configuración visual
SET LINESIZE 200
SET PAGESIZE 100
SET WRAP ON
SET FEEDBACK OFF
SET TRIMSPOOL ON
SET VERIFY OFF

-- Formato predeterminado para columnas comunes
COLUMN ISBN FORMAT A20
COLUMN TITULO FORMAT A100
COLUMN table_name FORMAT A30
COLUMN tablespace_name FORMAT A20
COLUMN status FORMAT A10
COLUMN num_rows FORMAT 999,999
COLUMN last_analyzed FORMAT A20

-- Mensaje inicial personalizado
PROMPT **************************************
PROMPT * Bienvenido a SQL*Plus (biblioteca) *
PROMPT **************************************
```

Guárdalo en la misma ubicación desde donde ejecutas SQL*Plus, para que se cargue automáticamente al iniciar.

## Nota final
- Oracle XE 10g funciona en sistemas modernos usando multiarch.
- Considera una máquina virtual, Docker o contenedores LXD como alternativa recomendada para aislar Oracle XE 10g y evitar conflictos futuros con la arquitectura i386, especialmente cuando se trabaja en un host Ubuntu.

