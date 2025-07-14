# 🦁 Guía Profesional para Instalar Brave Browser en Lubuntu

## ✅ 1. Requisitos previos

Antes de instalar Brave:

1. Asegúrate de que tu sistema esté actualizado:

   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

2. Verifica que tienes permisos de superusuario.

---

## 🔧 2. Instalación paso a paso

### 📦 Paso 1: Instalar `curl` (si no lo tienes)

```bash
sudo apt install curl -y
```

---

### 🔑 Paso 2: Añadir la clave GPG de Brave

```bash
sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
```

---

### 📥 Paso 3: Añadir el repositorio oficial

```bash
sudo curl -fsSLo /etc/apt/sources.list.d/brave-browser-release.sources \
https://brave-browser-apt-release.s3.brave.com/brave-browser.sources
```

---

### 🔄 Paso 4: Actualizar lista de paquetes

```bash
sudo apt update
```

---

### 🚀 Paso 5: Instalar Brave Browser

```bash
sudo apt install brave-browser -y
```

---

### 🧪 Paso 6: Verificar instalación

```bash
brave-browser --version
```

---

## 🧭 3. Ejecutar Brave por primera vez

Puedes iniciarlo desde el menú o con el comando:

```bash
brave-browser
```

---


## ⚠️ 4. Solución a problemas de rendimiento

### (Teclado lento, congelamientos, interfaz lenta)

### (Fixing keyboard lag, freezes, or slow UI responsiveness)

---

### 🔧 A) Desactivar la aceleración por hardware

**(Disable hardware acceleration)**

1. Abre Brave.
   **(Open Brave)**
2. Ve a `Configuración → Sistema`
   **(Go to `Settings → System`)**
3. Desactiva:
   **(Turn off):**

   * **“Usar aceleración por hardware cuando esté disponible”**
     → `Use hardware acceleration when available`
4. Reinicia Brave.
   **(Restart Brave)**

🔁 Esto soluciona la mayoría de los casos de teclado congelado o lentitud gráfica.
**(This resolves most keyboard lag and graphical freeze issues.)**

---

### 🧭 B) Iniciar con una pestaña vacía

**(Start with a new tab page instead of restoring previous session)**

1. Ve a `Configuración → Al iniciar`
   **(Go to `Settings → On startup`)**
2. Selecciona:

   * **“Abrir la página de nueva pestaña”**
     → `Open the New Tab page`

✅ Esto acelera el inicio del navegador.
**(Helps speed up browser startup.)**

---

### 🔍 C) Verifica el estado de aceleración gráfica

**(Check graphics acceleration status in Brave)**

1. En la barra de direcciones escribe:

   ```
   brave://gpu
   ```
2. Busca líneas en rojo en la sección
   **"Graphics Feature Status"**.
   Si hay errores, mantén la aceleración desactivada.
   **(If there are red errors, it’s best to leave acceleration disabled.)**

---

### 🖥️ D) Verifica el kernel y los drivers gráficos

**(Check your Linux kernel and video drivers)**

Comprobar versión del kernel:

```bash
uname -r
```

Ver tu driver gráfico activo:

```bash
sudo apt install mesa-utils -y
glxinfo | grep "OpenGL renderer"
```

🔍 Si aparece `llvmpipe`, **no tienes aceleración por hardware real**.
**(If `llvmpipe` shows up, you don’t have real GPU acceleration.)**

Reinstala o configura los drivers correctos para tu GPU (Intel o AMD).
**(Install proper GPU drivers for Intel or AMD if needed.)**

---

### 🚫 E) Ejecutar Brave sin aceleración de GPU

**(Launch Brave with GPU acceleration disabled)**

Puedes iniciar Brave así desde terminal:

```bash
brave-browser --disable-gpu
```

Esto fuerza al navegador a renderizar sin usar gráficos acelerados.
**(This forces software rendering without GPU usage.)**

🧠 Recomendado si otros pasos no funcionan.
**(Recommended if the above steps don’t solve the issue.)**

---

## 🧠 Extra: Crear lanzador personalizado sin aceleración

1. Crea un archivo `.desktop`:

```bash
nano ~/.local/share/applications/brave-browser-no-gpu.desktop
```

2. Pega lo siguiente:

```ini
[Desktop Entry]
Name=Brave (Sin GPU)
Comment=Brave con aceleración por hardware desactivada
Exec=brave-browser --disable-gpu
Icon=brave-browser
Terminal=false
Type=Application
Categories=Network;WebBrowser;
```

3. Guarda, cierra y hazlo visible en el menú:

```bash
chmod +x ~/.local/share/applications/brave-browser-no-gpu.desktop
```

---

## ✅ Resumen final

| Tarea                                     | Estado      |
| ----------------------------------------- | ----------- |
| Sistema actualizado                       | ✅           |
| Brave instalado desde repositorio oficial | ✅           |
| Clave GPG y fuente segura añadidas        | ✅           |
| Recomendaciones de rendimiento aplicadas  | 🧠 Opcional |
| Acceso directo sin GPU disponible         | 🧠 Opcional |
