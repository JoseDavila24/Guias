
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

## 1. Verificar Arquitectura del Sistema

Debes saber si tu sistema es de 32 o 64 bits.

**Comando para verificar la arquitectura:**  
```bash
uname -m
```
Resultados posibles:

-   `x86_64`: sistema de 64 bits → Requiere configuración adicional (multiarch)
    
-   `i386` / `i686`: sistema de 32 bits → Continúa directamente
    

----------

## 2. Descargar Archivos Necesarios

Descarga y descomprime el archivo `Oracle10gXE.zip`, lo cual generará una carpeta llamada `Oracle10gXE`.

**Estructura esperada del directorio:**

```
Oracle10gXE/
├── oracle-xe-universal_10.2.0.1-1.1_i386.deb
├── oracle-xe-client_10.2.0.1-1.2_i386.deb
├── libaio_0.3.104-1_i386.deb
├── multiarch-setup.sh
├── oracle-xe-install.sh
├── post-configure-setup.sh

```

----------

## 3. Instalación Paso a Paso

### 🔹 Paso 1: Preparar el entorno (solo en sistemas de 64 bits)

Ejecuta el script:

📝 **multiarch-setup.sh**  
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

----------

### 🔹 Paso 2: Instalar Oracle XE

Ejecuta el script:

📝 **oracle-xe-install.sh**  
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
```

🔸 Este script se detendrá en la ejecución de:  
`/etc/init.d/oracle-xe configure`  
➡️ En este punto, deberás completar el asistente de instalación manualmente:

-   Puerto HTTP
    
-   Puerto Listener
    
-   Contraseña para SYS y SYSTEM
    

----------

## 4. Control del Servicio Oracle XE

Antes de continuar con la configuración final, asegúrate de que el servicio está corriendo.

Comandos útiles:

-   ▶️ Iniciar: `/etc/init.d/oracle-xe start`
    
-   ⏹️ Detener: `/etc/init.d/oracle-xe stop`
    
-   🔎 Ver procesos: `ps -ef | grep oracle`
    

----------

## 5. Finalizar la Configuración

Una vez completado el paso interactivo, ejecuta el script final para configurar variables de entorno y dejar listo tu sistema:

📝 **post-configure-setup.sh**

```bash
#!/bin/bash

set -e

# --- Verificación de privilegios ---
if [ "$(id -u)" -ne 0 ]; then
  echo "❌ Este script debe ejecutarse con sudo." >&2
  echo "   Usa: sudo ./post-configure-setup.sh"
  exit 1
fi

# --- Añadir variables de entorno si no existen ---
ORACLE_BASHRC_LINE="export ORACLE_HOME=/usr/lib/oracle/xe/app/oracle/product/10.2.0/server"
if ! grep -Fxq "$ORACLE_BASHRC_LINE" ~/.bashrc; then
    echo "🛠️  Añadiendo configuración de Oracle XE al archivo ~/.bashrc..."
    cat <<'EOF' >> ~/.bashrc

# --- Configuración Oracle XE 10g ---
export ORACLE_HOME=/usr/lib/oracle/xe/app/oracle/product/10.2.0/server
export ORACLE_SID=XE
export PATH=$ORACLE_HOME/bin:$PATH
alias sqlplus='rlwrap sqlplus'
EOF
    echo "✅ Configuración añadida."
    echo "⚠️  Ejecuta 'source ~/.bashrc' o abre una nueva terminal para aplicar los cambios."
else
    echo "ℹ️  Las variables de entorno ya están configuradas en ~/.bashrc."
fi

echo ""
echo "🎯 PASO FINAL: Verifica conexión con Oracle usando sqlplus:"
echo "    sqlplus SYS/tu_contraseña AS SYSDBA"
echo "    sqlplus SYSTEM/tu_contraseña"
```
----------

## 6. Acceso a SQL*Plus

-   🧑‍💼 SYS (administrador):  
    `sqlplus SYS/tu_contraseña AS SYSDBA`
    
-   👤 SYSTEM (uso general):  
    `sqlplus SYSTEM/tu_contraseña`
    
-   👥 Otro usuario:  
    `sqlplus usuario/contraseña`
    

----------

## 7. Gestión Básica de Usuarios

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
----------

## 8. Personalización de SQL*Plus

Incluye un archivo `login.sql` en el mismo directorio desde donde ejecutas `sqlplus` para mejorar la visualización.

📝 **login.sql**  
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
----------

## 9. Recomendaciones Finales

✔️ Ejecuta esta instalación dentro de una máquina virtual o contenedor si puedes.  
✔️ Ideal para desarrollo, formación o pruebas.  
✔️ No olvides ejecutar `source ~/.bashrc` o abrir una nueva terminal para aplicar los cambios.
