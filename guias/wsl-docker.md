# 🧹 Mini guía de limpieza práctica (WSL + Docker)

## 1. Revisar y limpiar distribuciones WSL

🔍 **Ver qué distros tienes instaladas y su estado**:

```powershell
wsl --list --verbose
```

Ejemplo de salida:

```
  NAME      STATE           VERSION
* Ubuntu    Running         2
  Debian    Stopped         2
```

🗑️ **Eliminar una que no uses** (cuidado, se borra todo su contenido):

```powershell
wsl --unregister Debian
```

📦 **Ver cuánto espacio usa WSL**:

```powershell
wsl --status
```

---

## 2. Revisar y limpiar Docker

🔍 **Listar contenedores activos**:

```powershell
docker ps
```

🔍 **Listar todos los contenedores (incluidos los detenidos)**:

```powershell
docker ps -a
```

🗑️ **Eliminar contenedores que ya no uses**:

```powershell
docker rm <container_id>
```

🔍 **Listar imágenes descargadas**:

```powershell
docker images
```

🗑️ **Eliminar imágenes obsoletas**:

```powershell
docker rmi <image_id>
```

📦 **Ver uso de espacio de Docker**:

```powershell
docker system df
```

🧹 **Liberar espacio (cuidadoso, borra contenedores detenidos, redes no usadas, imágenes huérfanas, caché de build)**:

```powershell
docker system prune -a
```

💡 Consejo: Si solo quieres limpiar contenedores detenidos y redes no usadas (más seguro), usa:

```powershell
docker system prune
```

---

## 3. Checklist rápido de limpieza

Antes de cada fase:

* [ ] `wsl --list --verbose` → confirma que solo tienes la distro que usas (ej. Ubuntu).
* [ ] `docker ps -a` → elimina contenedores que no usas.
* [ ] `docker images` → elimina imágenes viejas que ya no necesitas.
* [ ] `docker system df` → revisa uso de espacio.
* [ ] `docker system prune -a` → solo si quieres hacer limpieza profunda.

---

👉 Con esto garantizas que **WSL no tenga distros duplicadas** y que **Docker no acumule imágenes/volúmenes basura**, lo que te dará más estabilidad y espacio libre para SIGECOVIP.

---
