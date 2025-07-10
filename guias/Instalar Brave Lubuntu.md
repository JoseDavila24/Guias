

# 🦁 **Guía de Instalación de Brave Browser en Lubuntu**



## ✅ **1. Preparativos previos**

Antes de comenzar, asegúrate de que tu sistema esté actualizado:

```bash
sudo apt update && sudo apt upgrade -y
```

---

## 🔧 **2. Instalación de Brave paso a paso**

### Paso 1: Instalar `curl` (si aún no está instalado)

```bash
sudo apt install curl -y
```

---

### Paso 2: Añadir la clave GPG del repositorio de Brave

```bash
sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
```

---

### Paso 3: Añadir el repositorio oficial de Brave

```bash
sudo curl -fsSLo /etc/apt/sources.list.d/brave-browser-release.sources \
https://brave-browser-apt-release.s3.brave.com/brave-browser.sources
```

---

### Paso 4: Actualizar los paquetes

```bash
sudo apt update
```

---

### Paso 5: Instalar Brave Browser

```bash
sudo apt install brave-browser -y
```

---

## 🚀 **3. Lanzar Brave por primera vez**

Una vez instalado, puedes abrir Brave desde el menú o escribiendo:

```bash
brave-browser
```

---

## ⚠️ **4. Problemas conocidos: Brave se siente lento (teclado o interfaz)**

Si notas que **el teclado responde lento** o la experiencia web (por ejemplo, en ChatGPT o sitios pesados) es **ralentizada**, sigue estas recomendaciones:

---

### 🛠️ Recomendaciones de mejora de rendimiento:

#### 🔹 A) Desactiva **aceleración por hardware** en Brave:

1. Abre Brave.
2. Ve a `Configuración` → `Sistema`.
3. Desactiva la opción:

   * **“Usar aceleración por hardware cuando esté disponible”**
4. Reinicia Brave.

> Esto resuelve la mayoría de los casos de teclado lento o interfaz congelada.

---

#### 🔹 B) Usa Brave con una ventana vacía al inicio (sin restaurar pestañas anteriores)

En `Configuración` → `Al iniciar`, selecciona:

* **“Abrir la página de nueva pestaña”**
  en lugar de restaurar sesiones anteriores.

---

#### 🔹 C) Revisa si hay problemas de GPU en Brave

En la barra de direcciones escribe:

```
brave://gpu
```

Busca líneas marcadas en rojo bajo "Graphics Feature Status". Si ves errores, lo ideal es dejar desactivada la aceleración por hardware.

---

#### 🔹 D) Usa la versión estable del kernel y drivers

Un kernel demasiado nuevo o un driver inestable puede provocar lentitud en la aceleración de gráficos.

Puedes comprobar tu versión actual con:

```bash
uname -r
```

Si tienes hardware Intel o AMD, asegúrate de tener instalados los controladores correctos:

```bash
sudo apt install mesa-utils
glxinfo | grep "OpenGL renderer"
```

---

### 📦 Opción adicional: Instalar Brave con `--disable-gpu`

Si el problema es persistente, puedes lanzar Brave con aceleración completamente desactivada:

```bash
brave-browser --disable-gpu
```

Puedes crear un acceso directo personalizado si esto te soluciona el problema permanentemente.
