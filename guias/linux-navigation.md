# Guía de Navegación en Linux

## 1. Navegación de directorios

| Comando      | Descripción                                                                           |
| ------------ | ------------------------------------------------------------------------------------- |
| `pwd`        | Muestra la ruta absoluta del directorio de trabajo actual.                            |
| `ls`         | Lista los archivos y directorios en la ubicación actual.                              |
| `ls -l`      | Lista los elementos con información detallada (permisos, propietario, tamaño, fecha). |
| `ls -lh`     | Igual que `ls -l`, pero muestra los tamaños en formato legible (KB, MB, GB).          |
| `ls -la`     | Lista todos los archivos, incluyendo los ocultos.                                     |
| `cd carpeta` | Cambia al directorio especificado.                                                    |
| `cd ..`      | Regresa al directorio superior inmediato.                                             |
| `cd ~`       | Accede al directorio personal del usuario actual.                                     |
| `cd /ruta`   | Cambia a un directorio específico mediante una ruta absoluta.                         |
| `cd -`       | Regresa al directorio visitado previamente.                                           |

---

## 2. Búsqueda de archivos y directorios

| Comando                    | Descripción                                                                                      |
| -------------------------- | ------------------------------------------------------------------------------------------------ |
| `find . -name "*.txt"`     | Busca archivos con extensión `.txt` en el directorio actual y subdirectorios.                    |
| `find / -name archivo.txt` | Busca un archivo específico en todo el sistema (puede requerir permisos elevados).               |
| `locate archivo`           | Localiza archivos de forma rápida utilizando una base de datos (actualizar con `sudo updatedb`). |

---

## 3. Visualización de archivos

| Comando              | Descripción                                                              |
| -------------------- | ------------------------------------------------------------------------ |
| `cat archivo`        | Muestra el contenido completo de un archivo.                             |
| `less archivo`       | Visualiza el contenido de forma paginada y permite búsquedas (`/texto`). |
| `head -n 20 archivo` | Muestra las primeras 20 líneas de un archivo.                            |
| `tail -n 20 archivo` | Muestra las últimas 20 líneas de un archivo.                             |
| `tail -f archivo`    | Muestra en tiempo real las nuevas líneas añadidas a un archivo.          |

---

## 4. Atajos útiles en la terminal

| Atajo      | Función                                                   |
| ---------- | --------------------------------------------------------- |
| `Tab`      | Autocompleta nombres de archivos, directorios o comandos. |
| `↑ / ↓`    | Navega por el historial de comandos utilizados.           |
| `Ctrl + R` | Busca de manera interactiva en el historial de comandos.  |
| `Ctrl + L` | Limpia el contenido mostrado en la pantalla.              |
| `Ctrl + A` | Desplaza el cursor al inicio de la línea actual.          |
| `Ctrl + E` | Desplaza el cursor al final de la línea actual.           |

---

## 5. Comandos y configuraciones adicionales

| Comando                           | Descripción                                                                              |
| --------------------------------- | ---------------------------------------------------------------------------------------- |
| `tree -L 2`                       | Muestra la estructura de directorios con un nivel de profundidad de hasta 2.             |
| `alias ll='ls -lh --color=auto'`  | Crea un alias para listar archivos con detalles y colores.                               |
| `alias la='ls -lha --color=auto'` | Crea un alias para listar todos los archivos (incluidos ocultos) con detalles y colores. |

---

## 6. Ejemplo de uso avanzado

Se recomienda combinar comandos de búsqueda y visualización para optimizar la administración de archivos. Por ejemplo:

```bash
less $(find . -name "*.log" | head -n 1)
```

Este comando busca el primer archivo con extensión `.log` en el directorio actual y lo abre en `less` para su lectura.
