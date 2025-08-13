## 📂 **Navegación de Directorios**

| Comando      | Descripción              |
| ------------ | ------------------------ |
| `pwd`        | Muestra la ruta actual   |
| `ls`         | Lista archivos           |
| `ls -l`      | Lista con detalles       |
| `ls -lh`     | Tamaños legibles         |
| `ls -la`     | Incluye archivos ocultos |
| `cd carpeta` | Entra en carpeta         |
| `cd ..`      | Sube un nivel            |
| `cd ~`       | Va a tu carpeta personal |
| `cd /ruta`   | Ruta absoluta            |
| `cd -`       | Carpeta anterior         |

---

## 🔍 **Búsqueda**

| Comando                    | Descripción                                     |
| -------------------------- | ----------------------------------------------- |
| `find . -name "*.txt"`     | Busca archivos `.txt` en carpeta actual         |
| `find / -name archivo.txt` | Busca en todo el sistema                        |
| `locate archivo`           | Busca rápido en base de datos (`sudo updatedb`) |

---

## 📄 **Visualización de Archivos**

| Comando              | Descripción                          |
| -------------------- | ------------------------------------ |
| `cat archivo`        | Muestra todo el contenido            |
| `less archivo`       | Vista paginada (buscar con `/texto`) |
| `head -n 20 archivo` | Primeras 20 líneas                   |
| `tail -n 20 archivo` | Últimas 20 líneas                    |
| `tail -f archivo`    | Seguir cambios en tiempo real        |

---

## ⚡ **Atajos en la Terminal**

| Atajo      | Función                       |
| ---------- | ----------------------------- |
| `Tab`      | Autocompletar rutas y nombres |
| `↑ / ↓`    | Historial de comandos         |
| `Ctrl + R` | Buscar en historial           |
| `Ctrl + L` | Limpiar pantalla              |
| `Ctrl + A` | Ir al inicio de la línea      |
| `Ctrl + E` | Ir al final de la línea       |

---

## 🌳 **Extras Profesionales**

| Comando                           | Descripción                        |
| --------------------------------- | ---------------------------------- |
| `tree -L 2`                       | Muestra estructura hasta 2 niveles |
| `alias ll='ls -lh --color=auto'`  | Alias útil en `~/.bashrc`          |
| `alias la='ls -lha --color=auto'` | Lista todo con detalles y colores  |

---

💡 **Consejo pro:** combina `find` + `less` para buscar y ver archivos rápido:

```bash
less $(find . -name "*.log" | head -n 1)
```

---
