# Mi Flujo de Trabajo en Git

Esta guía describe el flujo de trabajo que sigo para gestionar mis proyectos con Git de manera eficiente en **Ubuntu/Linux** y **Windows**.

## 🔹 A - ¿Qué es Git?
Git es un sistema de control de versiones distribuido que permite gestionar cambios en el código, colaborar con otros desarrolladores y mantener un historial de modificaciones.

## 🔹 B - Configuración Inicial
Antes de empezar, asegúrate de tener Git instalado y configurado.

### 📌 Instalar Git
#### **En Ubuntu/Linux:**
```bash
sudo apt update && sudo apt install git
```

#### **En Windows:**
1. Descarga **Git para Windows** desde [git-scm.com](https://git-scm.com/downloads).
2. Ejecuta el instalador y sigue las instrucciones.
3. Abre **Git Bash** y verifica la instalación con:
   ```bash
   git --version
   ```

### 📌 Configurar Git con tu identidad
Configura tu nombre y correo electrónico para que los commits queden registrados correctamente.

#### **En Ubuntu/Linux y Windows (Git Bash o Terminal):**
```bash
git config --global user.name "Tu Nombre"
git config --global user.email "tuemail@example.com"
```

## 🔹 C - Flujo de Trabajo
Este es mi flujo de trabajo típico al trabajar con Git.

### 1️⃣ Clonar un repositorio
#### **Ubuntu/Linux y Windows (Git Bash o CMD en modo administrador):**
```bash
git clone https://github.com/JoseDavila24/mi-repositorio.git
cd mi-repositorio
```

### 2️⃣ Crear una nueva rama para cambios
```bash
git checkout -b nueva-funcionalidad
```

### 3️⃣ Hacer cambios y agregarlos al área de preparación
```bash
git add .
```

### 4️⃣ Hacer un commit con un mensaje descriptivo
```bash
git commit -m "Agregando nueva funcionalidad"
```

### 5️⃣ Subir la rama al repositorio remoto
```bash
git push origin nueva-funcionalidad
```

### 6️⃣ Crear un Pull Request en GitHub
- Ir al repositorio en GitHub.
- Abrir un **Pull Request** desde la rama `nueva-funcionalidad` hacia `main`.
- Describir los cambios y solicitar revisión.

### 7️⃣ Fusionar cambios y actualizar localmente
Una vez aprobado el Pull Request:
```bash
git checkout main
git pull origin main
git branch -d nueva-funcionalidad
```

## 🚀 Consejos
- **Usa ramas para cada funcionalidad o corrección.**
- **Escribe mensajes de commit claros y descriptivos.**
- **Mantén tu repositorio sincronizado con `git pull`.**

Siguiendo este flujo de trabajo, la gestión del código será más organizada y colaborativa. ¡Feliz coding! 🚀
