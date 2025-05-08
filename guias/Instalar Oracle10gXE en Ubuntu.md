# 🏗️ Guía Completa de Instalación y Configuración

## Oracle XE 10g en Ubuntu (x86\_64 / i386)

---

## ⚠️ Importante: Actualización del Sistema

**Descripción:**
Actualiza el sistema para asegurarte de contar con las últimas mejoras y parches de seguridad.

```bash
sudo apt update && sudo apt full-upgrade -y && sudo apt autoremove -y && sudo apt clean
```

* 🔄 `apt update`: Actualiza la lista de paquetes
* ⬆️ `apt full-upgrade`: Instala actualizaciones completas
* 🧹 `apt autoremove`: Elimina paquetes innecesarios
* 🗑️ `apt clean`: Limpia archivos temporales

---

## ✅ 1. Verificar la arquitectura del sistema

```bash
uname -m
```

* `x86_64`: Sistema de 64 bits (requiere multiarch)
* `i386` / `i686`: Sistema de 32 bits (no requiere cambios)

---

## 📦 2. Descargar archivos necesarios

Descarga el archivo comprimido con los paquetes de Oracle XE:

```bash
wget -O Oracle10gXE.zip "https://www.dropbox.com/scl/fi/y6b53ehf6j1xoe74ucimz/Oracle10gXE.zip?rlkey=sf57q86p6wjlfy2jgr3lz9sd1&st=j3luhuvb&dl=1"
```

Extrae su contenido:

```bash
unzip Oracle10gXE.zip
```

Esto creará una carpeta llamada `Oracle10gXE`.

---

## 📁 3. Instalación mediante scripts

### 🔸 Ingresar a la carpeta

```bash
cd Oracle10gXE/
```

Verifica que existan estos archivos `.deb`:

* `oracle-xe-universal_10.2.0.1-1.1_i386.deb`
* `oracle-xe-client_10.2.0.1-1.2_i386.deb`
* `libaio_0.3.104-1_i386.deb`

---

### 🛠️ Script 1: multiarch-setup.sh (solo para 64 bits)

```bash
#!/bin/bash
ARCH=$(uname -m)

if [ "$ARCH" = "x86_64" ]; then
    echo "🔍 Sistema de 64 bits detectado. Habilitando soporte para i386..."
    sudo dpkg --add-architecture i386
    sudo apt update

    echo "📦 Instalando dependencias necesarias desde archivo local..."
    if [ -f libaio_0.3.104-1_i386.deb ]; then
        sudo dpkg -i libaio_0.3.104-1_i386.deb
    else
        echo "❌ Archivo libaio_0.3.104-1_i386.deb no encontrado en el directorio actual."
        exit 1
    fi

    echo "🔧 Corrigiendo posibles dependencias rotas..."
    sudo apt --fix-broken install -y
else
    echo "ℹ️ Sistema de 32 bits detectado. No es necesario configurar multiarch."
fi
```

---

### 🛠️ Script 2: oracle-xe-install.sh

```bash
#!/bin/bash

# ------------------- PASO 1: Instalación de paquetes ---------------------

echo "🔹 Paso 1: Instalando paquetes .deb de Oracle XE..."

sudo dpkg -i --force-architecture \
    oracle-xe-client_10.2.0.1-1.2_i386.deb \
    oracle-xe-universal_10.2.0.1-1.1_i386.deb

if [ $? -ne 0 ]; then
    echo "⚠️ Error al instalar los paquetes .deb. Intentando reparar dependencias..."
    sudo apt --fix-broken install -y
fi

echo "✅ Paquetes .deb procesados."

# ------------------- PASO 2: Corrección de dependencias ------------------

echo "🔹 Paso 2: Corrigiendo dependencias restantes..."
sudo apt --fix-broken install -y
echo "✅ Dependencias corregidas."

# ------------------- PASO 3: Instalación de rlwrap -----------------------

echo "🔹 Paso 3: Instalando rlwrap..."
sudo apt install -y rlwrap

# ------------------- PASO 4: Configurar Oracle XE ------------------------

echo "🔹 Paso 4: Configurando Oracle XE..."
sudo /etc/init.d/oracle-xe configure

# ------------------- PASO 5: Añadir variables de entorno -----------------

echo "🔹 Paso 5: Añadiendo configuración al archivo ~/.bashrc (sin aplicar automáticamente)..."

CONFIG="
# Configuración Oracle XE 10g
export ORACLE_HOME=/usr/lib/oracle/xe/app/oracle/product/10.2.0/server
export ORACLE_SID=XE
export PATH=\\\$PATH:\\\$ORACLE_HOME/bin
unset TWO_TASK
alias sqlplus='rlwrap sqlplus'
"

# Añadir configuración si no existe aún
if ! grep -q "ORACLE_HOME" ~/.bashrc; then
    echo "$CONFIG" >> ~/.bashrc
    echo "✅ Configuración añadida a ~/.bashrc"
else
    echo "ℹ️ Las variables de entorno ya estaban definidas."
fi

echo ""
echo "📌 NOTA: Cierra y vuelve a abrir la terminal o ejecuta 'source ~/.bashrc' manualmente para aplicar los cambios."

# ------------------- FINAL ---------------------------

echo ""
echo "🎉 Instalación completa. Puedes conectarte con:"
echo "  sqlplus SYS/tu_contraseña AS SYSDBA"
echo "  sqlplus SYSTEM/tu_contraseña"
```

---

### ▶️ Ejecutar los scripts

```bash
chmod +x multiarch-setup.sh oracle-xe-install.sh

# Si estás en 64 bits:
./multiarch-setup.sh

# Para instalar Oracle XE:
./oracle-xe-install.sh
```

---

## 🔁 4. Control del servicio Oracle XE

```bash
sudo /etc/init.d/oracle-xe start     # Iniciar el servicio
sudo /etc/init.d/oracle-xe stop      # Detenerlo
ps -ef | grep oracle                  # Verificar procesos
```

---

## 🔐 5. Acceso a SQL\*Plus

### SYS (administrador total):

```bash
sqlplus SYS/tu_contraseña AS SYSDBA
```

### SYSTEM (administración general):

```bash
sqlplus SYSTEM/tu_contraseña
```

### Otro usuario:

```bash
sqlplus usuario/contraseña
```

---

## 👤 6. Gestión básica de usuarios

```sql
-- Crear usuario:
CREATE USER nuevo_usuario IDENTIFIED BY contraseña;
GRANT CONNECT, RESOURCE TO nuevo_usuario;

-- Dar todos los privilegios:
GRANT ALL PRIVILEGES TO nuevo_usuario;

-- Ver usuarios y roles:
SELECT * FROM dba_users;
SELECT * FROM dba_roles;

-- Listar tablas del usuario actual:
SELECT table_name FROM user_tables;

-- Eliminar usuario:
DROP USER nuevo_usuario CASCADE;
```

---

## ⚙️ 7. Personalización automática de SQL\*Plus (login.sql)

Crea un archivo llamado `login.sql` con esta configuración:

```sql
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
PROMPT *       Bienvenido a SQL*Plus (Configuración cargada)   *
PROMPT *********************************************************
```

Coloca este archivo en el mismo directorio desde donde lanzas `sqlplus`.

---

## 📌 Nota final

* Oracle XE 10g funciona correctamente en sistemas modernos si se usa `multiarch`.
* Recomendamos usar máquinas virtuales, contenedores Docker o LXD si deseas aislar el entorno.
* Esta instalación es ideal para pruebas, enseñanza o desarrollo local.
