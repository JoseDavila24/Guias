# 📘 GUÍA PARA CONTRIBUIR AL PROYECTO Y USAR GIT

Este documento está dirigido a todos los colaboradores que deseen formar parte activa del desarrollo de este proyecto. Aquí encontrarás tanto la base para trabajar con Git como las normas y procesos para contribuir de forma clara, ordenada y efectiva.

---

## 🤝 A. CONTRIBUIR ES COLABORAR

¡Gracias por tu interés en contribuir!
Nuestro objetivo es mantener un entorno colaborativo donde todos puedan aportar, crecer y mejorar el proyecto en conjunto. Para ello:

* Promovemos **colaboración constante** entre desarrolladores.
* Buscamos **transparencia y trazabilidad** en todos los cambios.
* Valoramos el **respeto, la claridad y el orden** en el trabajo en equipo.

---

## 🧾 B. PROCESO DE CONTRIBUCIÓN

### 1. FORK Y CLONACIÓN

1. Haz un **fork** del repositorio original.
2. Clona tu copia a tu entorno local:

```bash
git clone https://github.com/tu-usuario/nombre-del-repo.git
cd nombre-del-repo
```

### 2. CREAR UNA RAMA DE TRABAJO

Siempre trabaja sobre una rama distinta a `main`. Usa nombres descriptivos:

```bash
git checkout -b feature/nueva-funcionalidad
```

### 3. REALIZA CAMBIOS Y CONFÍRMALOS

Haz tus modificaciones, asegúrate de que el código funcione, y luego:

```bash
git add .
git commit -m "feat: agrega validación en formulario"
```

> 📌 Es importante que el mensaje de commit sea **claro y específico**.

### 4. HAZ PUSH Y ENVÍA TU CONTRIBUCIÓN

```bash
git push origin feature/nueva-funcionalidad
```

Después, abre un **Pull Request (PR)** desde tu rama hacia `main`.
Incluye en la descripción:

* Qué hiciste.
* Por qué lo hiciste.
* Si el PR cierra un issue: `Closes #número`.

---

## 🧠 C. BUENAS PRÁCTICAS DE CONTRIBUCIÓN

* ✅ **Escribe código limpio**, comentado y con nombres descriptivos.
* ✅ **No alteres funcionalidades existentes** sin justificación.
* ✅ **Agrega pruebas** si introduces nueva lógica.
* ✅ **Documenta** todo lo necesario para otros desarrolladores.

> Tu aporte no solo es código, también es contexto y claridad para el equipo.

---

## 🌿 D. ESTRUCTURA DE RAMAS

Utilizamos una estructura de ramas sencilla y efectiva:

* `main`: versión estable.
* `develop`: integración de nuevas funcionalidades (si aplica).
* `feature/*`: nuevas características.
* `fix/*`: correcciones de errores.
* `docs/*`: cambios en documentación.

---

## ✍️ E. COMMIT CLAROS Y CONSISTENTES

Usa esta convención en tus commits:

```
tipo: descripción breve del cambio
```

Ejemplos:

* `feat: agrega componente de usuario`
* `fix: corrige error de validación`
* `docs: actualiza guía de contribución`

Tipos válidos: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`.

---

## 🔄 F. GESTIÓN DE PULL REQUESTS

Cuando envíes un Pull Request:

* Explica **qué problema resuelve** tu contribución.
* Menciona si **necesita revisión específica**.
* Mantente disponible para responder comentarios o hacer ajustes.

---

## ⚖️ G. CÓDIGO DE CONDUCTA

Este proyecto sigue un **Código de Conducta** para garantizar un ambiente:

* Respetuoso
* Colaborativo
* Seguro para todos

Léelo antes de contribuir. Tu participación responsable fortalece la comunidad.

---

## 🔧 H. GUÍA BÁSICA DE GIT PARA CONTRIBUIDORES

Si eres nuevo en Git, aquí tienes lo esencial:

### INSTALACIÓN Y CONFIGURACIÓN

**Ubuntu/Linux:**

```bash
sudo apt update && sudo apt install git
```

**Windows:**

* Descarga desde [https://git-scm.com/downloads](https://git-scm.com/downloads)
* Instala y abre Git Bash

**Configura tu identidad:**

```bash
git config --global user.name "Tu Nombre"
git config --global user.email "tucorreo@example.com"
```

### FLUJO RESUMIDO

```bash
# Clonar repositorio
git clone https://github.com/tu-usuario/nombre-del-repo.git

# Crear rama
git checkout -b fix/ajuste-login

# Hacer cambios
git add .
git commit -m "fix: corrige validación en login"

# Enviar contribución
git push origin fix/ajuste-login
```

---

## ✅ RECOMENDACIONES FINALES

* 🔄 Haz `git pull` frecuentemente para mantener tu rama actualizada.
* ✏️ Sé detallado en tus mensajes y en las descripciones de los PR.
* 🧼 Usa `.gitignore` para no subir archivos innecesarios.
* 🙌 Colabora de manera abierta: tu trabajo impacta a todo el equipo.

---

**Tu contribución cuenta.**
Ya sea pequeña o grande, cada mejora suma al valor del proyecto.
Gracias por ser parte de esta comunidad. ¡Vamos a construir juntos algo increíble! 🚀
