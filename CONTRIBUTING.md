# Guía para Contribuir al Proyecto y Utilizar Git

Este documento está dirigido a todos los colaboradores interesados en participar activamente en el desarrollo de este proyecto. Aquí se presentan las directrices fundamentales para el uso de Git, así como las normas y procedimientos establecidos para garantizar una colaboración clara, organizada y eficiente.

---

## A. Contribuir es Colaborar

Agradecemos su interés en contribuir a este proyecto. Nuestro objetivo es mantener un entorno de trabajo colaborativo que permita a todos los participantes aportar, aprender y mejorar de manera conjunta. Para ello:

* Se promueve la **colaboración constante** entre desarrolladores.
* Se garantiza la **transparencia y trazabilidad** en cada cambio realizado.
* Se valora el **respeto, la claridad y el orden** en todas las interacciones.

---

## B. Proceso de Contribución

### 1. Creación de un Fork y Clonación

1. Realice un *fork* del repositorio original.
2. Clone su copia en el entorno local:

```bash
git clone https://github.com/tu-usuario/nombre-del-repo.git
cd nombre-del-repo
```

### 2. Creación de una Rama de Trabajo

Trabaje siempre en una rama distinta de `main`. Utilice nombres descriptivos:

```bash
git checkout -b feature/nueva-funcionalidad
```

### 3. Realización de Cambios y Confirmación

Efectúe las modificaciones necesarias, verifique su correcto funcionamiento y confirme los cambios:

```bash
git add .
git commit -m "feat: agrega validación en formulario"
```

Es fundamental que los mensajes de confirmación sean **claros y específicos**.

### 4. Envío de Cambios y Pull Request

```bash
git push origin feature/nueva-funcionalidad
```

Posteriormente, abra un **Pull Request (PR)** desde su rama hacia `main`, incluyendo en la descripción:

* Qué cambios fueron realizados.
* La justificación de dichos cambios.
* Referencia a un *issue* asociado, si corresponde (`Closes #número`).

---

## C. Buenas Prácticas de Contribución

* Escribir **código claro y documentado**.
* Evitar alterar funcionalidades existentes sin justificación.
* Incluir **pruebas** al introducir nueva lógica.
* Aportar documentación suficiente para otros colaboradores.

La contribución no se limita al código: el contexto y la claridad también son esenciales.

---

## D. Estructura de Ramas

Se emplea una estructura de ramas simple y funcional:

* `main`: versión estable.
* `develop`: integración de nuevas funcionalidades (si corresponde).
* `feature/*`: incorporación de nuevas características.
* `fix/*`: corrección de errores.
* `docs/*`: modificaciones en la documentación.

---

## E. Convenciones para Mensajes de Commit

Formato recomendado:

```
tipo: descripción breve del cambio
```

Ejemplos:

* `feat: agrega componente de usuario`
* `fix: corrige error de validación`
* `docs: actualiza guía de contribución`

Tipos aceptados: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`.

---

## F. Gestión de Pull Requests

Al enviar un Pull Request:

* Explique el problema que resuelve la contribución.
* Indique si requiere revisión o retroalimentación específica.
* Esté disponible para responder observaciones o realizar ajustes.

---

## G. Código de Conducta

El proyecto se rige por un **Código de Conducta** cuyo objetivo es garantizar un entorno:

* Respetuoso.
* Colaborativo.
* Seguro para todos los participantes.

Se solicita leer y aceptar el Código de Conducta antes de realizar contribuciones.

---

## H. Guía Básica de Git para Contribuidores

### Instalación y Configuración

**Ubuntu/Linux:**

```bash
sudo apt update && sudo apt install git
```

**Windows:**

* Descargue desde [https://git-scm.com/downloads](https://git-scm.com/downloads).
* Instale y utilice Git Bash.

**Configuración inicial de identidad:**

```bash
git config --global user.name "Su Nombre"
git config --global user.email "su-correo@example.com"
```

### Flujo de Trabajo Resumido

```bash
# Clonar repositorio
git clone https://github.com/tu-usuario/nombre-del-repo.git

# Crear rama
git checkout -b fix/ajuste-login

# Realizar cambios
git add .
git commit -m "fix: corrige validación en login"

# Enviar contribución
git push origin fix/ajuste-login
```

---

## Recomendaciones Finales

* Actualice su rama con frecuencia mediante `git pull`.
* Sea detallado en los mensajes de commit y descripciones de los Pull Requests.
* Utilice `.gitignore` para evitar subir archivos innecesarios.
* Mantenga una comunicación abierta y colaborativa: cada aporte contribuye al valor del proyecto.

---

**Toda contribución es valiosa.**
Independientemente de su magnitud, cada mejora fortalece el proyecto y su comunidad.

---
