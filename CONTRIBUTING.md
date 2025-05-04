# 📘 GUÍA DE USO Y CONTRIBUCIÓN CON GIT

Este documento te ofrece una introducción práctica a Git y una guía clara para contribuir al proyecto de manera efectiva, profesional y colaborativa.

---

## 🔹 A. ¿QUÉ ES GIT?

**Git** es un sistema de control de versiones distribuido que permite:

* Gestionar el historial de cambios de tus proyectos.
* Trabajar con otras personas sin sobrescribir el trabajo de nadie.
* Recuperar versiones anteriores si algo sale mal.

👉 En resumen: te brinda **control**, **seguridad** y **colaboración**.

---

## 🔹 B. CONFIGURACIÓN INICIAL

### 1. INSTALAR GIT

**En Ubuntu/Linux:**

```bash
sudo apt update && sudo apt install git
```

**En Windows:**

1. Descarga Git para Windows desde: [https://git-scm.com/downloads](https://git-scm.com/downloads)
2. Instala con las opciones por defecto.
3. Abre Git Bash y verifica:

```bash
git --version
```

### 2. CONFIGURAR TU IDENTIDAD

Esto es necesario para que tus cambios se registren correctamente.

```bash
git config --global user.name "Tu Nombre"
git config --global user.email "tuemail@example.com"
```

Puedes verificar tu configuración con:

```bash
git config --list
```

---

## 🔹 C. FLUJO DE TRABAJO DIARIO CON GIT

### 1. CLONAR EL REPOSITORIO

```bash
git clone https://github.com/tu-usuario/nombre-del-repo.git
cd nombre-del-repo
```

### 2. CREAR UNA NUEVA RAMA

```bash
git checkout -b nombre-de-tu-rama
```

### 3. HACER CAMBIOS Y AGREGARLOS

```bash
git add .
```

*También puedes agregar archivos específicos:*

```bash
git add archivo.txt
```

### 4. CONFIRMAR LOS CAMBIOS (COMMIT)

```bash
git commit -m "Descripción breve del cambio"
```

Ejemplo:

```bash
git commit -m "fix: corrige validación del formulario"
```

### 5. SUBIR CAMBIOS AL REPOSITORIO REMOTO

```bash
git push origin nombre-de-tu-rama
```

---

## 🔄 D. FUSIONAR CAMBIOS (PULL REQUEST)

1. Entra a tu repositorio en GitHub.
2. Crea un Pull Request desde tu rama hacia `main`.
3. Agrega una descripción breve y clara del cambio.
4. Solicita revisión y fusión.

Para actualizar tu rama local:

```bash
git checkout main
git pull origin main
git branch -d nombre-de-tu-rama
```

---

## 🔸 E. COMANDOS ÚTILES

| Acción                     | Comando                    |
| -------------------------- | -------------------------- |
| Ver estado de cambios      | `git status`               |
| Ver historial de commits   | `git log --oneline`        |
| Ver ramas disponibles      | `git branch`               |
| Cambiar de rama            | `git checkout nombre-rama` |
| Guardar cambios temporales | `git stash`                |

---

## 🤝 F. GUÍA PARA CONTRIBUIR AL PROYECTO

### 1. CÓMO CONTRIBUIR

1. Haz un **fork** del repositorio.
2. Clona tu fork localmente:

```bash
git clone https://github.com/tu-usuario/nombre-del-repo.git
cd nombre-del-repo
```

3. Crea una nueva rama:

```bash
git checkout -b nombre-de-tu-rama
```

4. Realiza tus cambios:

```bash
git add .
git commit -m "Descripción clara del cambio"
```

5. Sube tu rama:

```bash
git push origin nombre-de-tu-rama
```

6. Abre un **Pull Request** hacia `main`.

---

### 2. BUENAS PRÁCTICAS

* Escribe código limpio, documentado y comprensible.
* Añade pruebas si es necesario.
* Verifica que no rompes funcionalidades existentes.
* Usa nombres descriptivos para ramas y commits.

---

### 3. ESTRUCTURA DE RAMAS

* `main`: versión estable del proyecto.
* `develop`: versión en desarrollo (opcional).
* `feature/*`: nuevas funcionalidades.
* `fix/*`: corrección de errores.
* `docs/*`: documentación.

---

### 4. COMMITS CLAROS

Utiliza esta estructura para tus mensajes:

```
tipo: descripción breve del cambio
```

Ejemplos:

* `feat: agrega componente de usuario`
* `fix: corrige error en el login`
* `docs: actualiza el README`

Tipos válidos: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`.

---

### 5. PULL REQUESTS

* Describe qué hiciste.
* Indica si algo requiere atención especial.
* Relaciona el PR con un issue si aplica (ejemplo: `Closes #3`).

---

### 6. CÓDIGO DE CONDUCTA

Este proyecto sigue un **Código de Conducta** que promueve un entorno inclusivo, respetuoso y colaborativo.
Por favor, revísalo antes de enviar tu contribución.

---

## ✅ RECOMENDACIONES FINALES

* Crea una rama por cada nueva función o corrección.
* Escribe mensajes de commit descriptivos y consistentes.
* Haz `pull` frecuentemente para evitar conflictos.
* Usa `.gitignore` para omitir archivos innecesarios.

---

Con esta guía completa ya puedes contribuir de manera ordenada, profesional y efectiva.
¡Gracias por formar parte del proyecto! 🚀
