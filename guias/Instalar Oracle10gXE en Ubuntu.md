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
wget -O Oracle10gXE.zip "https://www.dropbox.com/scl/fi/t7vrmey2dz5elm710rswe/Oracle10gXE.zip?rlkey=3lc8n96g1nnp3x5xxdm8rzatw&st=ch9nkhkt&dl=1"
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

Verifica que existan estos archivos `.sh`:
* `multiarch-setup.sh`
* `oracle-xe-install.sh`

---

### 🛠️ Script 1: multiarch-setup.sh (solo para 64 bits)

```bash
#!/bin/bash

# Salir inmediatamente si un comando falla.
set -e

# --- Verificación de Privilegios ---
if [ "$(id -u)" -ne 0 ]; then
  echo "❌ Este script debe ejecutarse con privilegios de superusuario (sudo)." >&2
  echo "   Por favor, ejecútalo como: sudo ./preparar_entorno_oracle.sh"
  exit 1
fi

# --- Detección de Arquitectura y Configuración Multiarch ---
ARCH=$(uname -m)

if [ "$ARCH" = "x86_64" ]; then
    echo "🔍 Sistema de 64 bits detectado. Habilitando soporte para i386..."
    sudo dpkg --add-architecture i386
    sudo apt update -y # Añadido -y para automatizar si es posible

    echo "📦 Instalando la dependencia libaio desde un archivo local..."
    echo "   Asegúrate de que el archivo 'libaio_0.3.104-1_i386.deb' se encuentra en el mismo directorio que este script."
    if [ -f libaio_0.3.104-1_i386.deb ]; then
        sudo dpkg -i libaio_0.3.104-1_i386.deb
    else
        echo "❌ Archivo 'libaio_0.3.104-1_i386.deb' no encontrado en el directorio actual." >&2
        echo "   Por favor, descarga el archivo y colócalo junto al script antes de continuar."
        exit 1
    fi

    echo "🔧 Corrigiendo posibles dependencias rotas después de instalar libaio..."
    sudo apt --fix-broken install -y
else
    echo "ℹ️ Sistema de 32 bits detectado o arquitectura no x86_64 ($ARCH). No es necesario configurar multiarch para i386."
fi

echo "✅ Preparación del entorno completada."
```

---

### 🛠️ Script 2: oracle-xe-install.sh

```bash
#!/bin/bash

# Salir inmediatamente si un comando falla.
set -e

# --- Verificación de Privilegios ---
if [ "$(id -u)" -ne 0 ]; then
  echo "❌ Este script debe ejecutarse con privilegios de superusuario (sudo)." >&2
  echo "   Por favor, ejecútalo como: sudo ./oracle-xe-install.sh"
  exit 1
fi

# --- Mensaje sobre Archivos Necesarios ---
echo "ℹ️ Este script requiere los siguientes archivos .deb en el mismo directorio:"
echo "   - libaio_0.3.104-1_i386.deb (si no se instaló con el script de preparación)"
echo "   - oracle-xe-client_10.2.0.1-1.2_i386.deb"
echo "   - oracle-xe-universal_10.2.0.1-1.1_i386.deb"
echo "   Por favor, asegúrate de que estén presentes antes de continuar."
# Podrías añadir una pausa aquí si lo deseas: read -p "Presiona [Enter] para continuar..."

# --- PASO 1: Instalación de paquetes .deb de Oracle XE ---
echo ""
echo "🔹 Paso 1: Instalando paquetes .deb de Oracle XE..."

# Lista de paquetes a instalar.
# Nota: libaio_0.3.104-1_i386.deb podría ser redundante si el script de preparación ya lo instaló.
# Se deja aquí por si este script se ejecuta de forma independiente. dpkg lo manejará.
ORACLE_DEBS=(
    "libaio_0.3.104-1_i386.deb"
    "oracle-xe-client_10.2.0.1-1.2_i386.deb"
    "oracle-xe-universal_10.2.0.1-1.1_i386.deb"
)

# Verificar existencia de todos los paquetes .deb necesarios
for pkg_deb in "${ORACLE_DEBS[@]}"; do
    if [ ! -f "$pkg_deb" ]; then
        echo "❌ Archivo requerido '$pkg_deb' no encontrado en el directorio actual." >&2
        exit 1
    fi
done

# Instalar los paquetes
# El uso de --force-architecture es a menudo necesario para estos paquetes antiguos.
sudo dpkg -i --force-architecture "${ORACLE_DEBS[@]}"

# Verifica si la instalación con dpkg falló
# $? contiene el código de salida del último comando ejecutado.
if [ $? -ne 0 ]; then
    echo "⚠️  Error durante la instalación de los paquetes .deb con dpkg."
    echo "    Intentando reparar dependencias con 'apt --fix-broken install'..."
    sudo apt --fix-broken install -y
    # Reintentar la instalación de dpkg podría ser una opción aquí,
    # o simplemente confiar en que fix-broken resolvió las dependencias
    # para que la configuración de Oracle funcione.
    # Por ahora, se asume que fix-broken es suficiente si dpkg falló inicialmente.
fi

echo "✅ Paquetes .deb procesados."

# --- PASO 2: Corrección de dependencias (puede ser redundante pero no perjudicial) ---
echo ""
echo "🔹 Paso 2: Corrigiendo dependencias restantes (si las hubiera)..."
sudo apt --fix-broken install -y
echo "✅ Dependencias corregidas."

# --- PASO 3: Instalación de rlwrap ---
echo ""
echo "🔹 Paso 3: Instalando rlwrap (mejora para SQL*Plus)..."
if sudo apt install -y rlwrap; then
    echo "✅ rlwrap instalado correctamente."
else
    echo "⚠️  No se pudo instalar rlwrap. SQL*Plus funcionará, pero sin historial de comandos mejorado."
    echo "    Puedes intentar instalarlo manualmente más tarde: sudo apt install rlwrap"
fi

# --- PASO 4: Configurar Oracle XE ---
echo ""
echo "🔹 Paso 4: Configurando Oracle XE..."
echo "⏳ Se abrirá el asistente de configuración de Oracle en la terminal."
echo "   Por favor, introduce los datos solicitados (puerto HTTP, puerto del listener, contraseña para SYS y SYSTEM, etc.)."
echo "   Recuerda bien la contraseña que establezcas."
sudo /etc/init.d/oracle-xe configure

# --- PASO 5: Variables de entorno ---
echo ""
echo "🔹 Paso 5: Añadiendo configuración de Oracle XE al archivo ~/.bashrc del usuario actual ($(whoami))..."

# Define el bloque de configuración para evitar errores de sintaxis con EOF si hay comillas dentro.
read -r -d '' ORACLE_CONFIG_BLOCK <<'EOF'

# --- Configuración Oracle XE 10g ---
export ORACLE_HOME=/usr/lib/oracle/xe/app/oracle/product/10.2.0/server
export ORACLE_SID=XE
export PATH=$ORACLE_HOME/bin:$PATH
# Descomentar la siguiente línea si usas NLS_LANG y ajústala a tus necesidades
# export NLS_LANG="SPANISH_SPAIN.WE8ISO8859P1" 
unset TWO_TASK # Evita problemas con conexiones locales si está configurada.
alias sqlplus='rlwrap sqlplus'
# --- Fin Configuración Oracle XE 10g ---
EOF

# Evitar duplicados si el script se ejecuta más de una vez
# Se busca una línea única del bloque, como ORACLE_HOME
if grep -Fxq "export ORACLE_HOME=/usr/lib/oracle/xe/app/oracle/product/10.2.0/server" ~/.bashrc; then
    echo "ℹ️  La configuración de ORACLE_HOME ya parece existir en ~/.bashrc. No se añadirá de nuevo."
else
    echo "$ORACLE_CONFIG_BLOCK" >> ~/.bashrc
    echo "✅ Configuración de Oracle añadida a ~/.bashrc."
fi

# Aplicar los cambios a la sesión actual del script (no afecta otras terminales abiertas)
# El usuario necesitará abrir una nueva terminal o sourcear ~/.bashrc manualmente.
source ~/.bashrc

echo "✅ Variables de entorno aplicadas a la sesión actual del script."
echo "   Para que los cambios surtan efecto en NUEVAS terminales, simplemente ábrelas."
echo "   Para terminales YA ABIERTAS (diferentes a esta), ejecuta: source ~/.bashrc"

# --- PASO FINAL: Mensaje final ---
echo ""
echo "🎉 ¡Instalación y configuración de Oracle XE 10g completadas!"
echo "ℹ️  Para conectarte a la base de datos, abre una NUEVA TERMINAL (o ejecuta 'source ~/.bashrc' en una existente) y luego usa:"
echo "    sqlplus SYS/tu_contraseña AS SYSDBA"
echo "    sqlplus SYSTEM/tu_contraseña"
echo ""
echo "Recuerda reemplazar 'tu_contraseña' con la que estableciste durante la configuración."
echo "Puedes verificar el estado del servicio con: sudo service oracle-xe status"
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
