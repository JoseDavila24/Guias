# Cómo Usar LXD

Esta guía cubre los conceptos básicos de LXD, incluyendo instalación, gestión de contenedores, compartir archivos y listar versiones disponibles.

## 🔹 A - ¿Qué es LXD?
LXD es un sistema de contenedores basado en Linux que permite ejecutar entornos virtualizados de manera ligera y eficiente, similar a máquinas virtuales pero con mejor rendimiento.

## 🔹 B - Instalación de LXD

### 📌 Instalar LXD en Ubuntu/Linux
```bash
sudo apt update && sudo apt install lxd -y
```
Después de la instalación, añade tu usuario al grupo `lxd` para evitar permisos restringidos:
```bash
sudo usermod -aG lxd $USER
newgrp lxd
```
Inicializa LXD con:
```bash
lxd init
```

### 📌 Instalar LXD en Windows
LXD no está disponible nativamente en Windows, pero se puede usar dentro de **WSL2 (Windows Subsystem for Linux)**.
1. Habilita WSL2 e instala Ubuntu desde la Microsoft Store.
2. Dentro de WSL, sigue las instrucciones de instalación para Ubuntu.

## 🔹 C - Uso Básico de LXD

### 📌 Crear y administrar contenedores
#### **Crear un contenedor**
```bash
lxc launch ubuntu:22.04 mi-contenedor
```
#### **Listar contenedores activos**
```bash
lxc list
```
#### **Detener un contenedor**
```bash
lxc stop mi-contenedor
```
#### **Eliminar un contenedor**
```bash
lxc delete mi-contenedor
```

### 📌 Acceder a un contenedor
```bash
lxc exec mi-contenedor -- bash
```

## 📂 Compartir Archivos entre Host y Contenedor
Puedes compartir directorios entre el sistema anfitrión y el contenedor con el siguiente comando:
```bash
lxc config device add mi-contenedor mi-carpeta disk source=/ruta/en/host path=/ruta/en/contenedor
```
Ejemplo:
```bash
lxc config device add mi-contenedor datos disk source=$HOME/datos path=/mnt/datos
```
Para verificar que se haya montado correctamente:
```bash
lxc exec mi-contenedor -- ls /mnt/datos
```

## 🔄 Listar Versiones Disponibles de Imágenes
Para ver todas las versiones de imágenes disponibles en LXD:
```bash
lxc image list ubuntu:
```
También puedes buscar imágenes específicas:
```bash
lxc image list images: | grep "22.04"
```

## 🚀 Consejos
- **Usa nombres descriptivos para los contenedores**.
- **Mantén LXD actualizado con `snap refresh lxd` si usas Snap**.
- **Asegura los permisos adecuados al compartir archivos**.

¡Con estos pasos ya puedes comenzar a utilizar LXD de manera eficiente! 🚀
