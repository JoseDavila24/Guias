# 📚 Bienvenido a mis guias

Este repositorio incluye **varias guías** sobre procesos que pueden ser útiles durante tu vida estudiantil.  
Pero antes de comenzar a explorarlas, es importante que tengas claro el concepto y el uso básico de **Git**.

A continuación, te comparto una guía ligera pero completa para que comiences a usar Git de manera eficiente.

---

## 🔹 A - ¿Qué es Git?
**Git** es un sistema de control de versiones distribuido. Sirve para:

- Gestionar el historial de cambios de tus proyectos.
- Trabajar con otras personas sin sobrescribir el trabajo de nadie.
- Recuperar versiones anteriores si algo sale mal.

> En resumen: te da **control**, **seguridad** y **colaboración**.

---

## 🔹 B - Configuración Inicial

### 📌 1. Instalar Git

#### ✅ En Ubuntu/Linux:
```bash
sudo apt update && sudo apt install git
```

#### ✅ En Windows:
1. Descarga **Git para Windows** desde [git-scm.com](https://git-scm.com/downloads).
2. Instala con las opciones por defecto.
3. Abre **Git Bash** y verifica:
   ```bash
   git --version
   ```

### 📌 2. Configurar tu identidad
Esto permite que tus cambios queden registrados con tu nombre.

```bash
git config --global user.name "Tu Nombre"
git config --global user.email "tuemail@example.com"
```

> 🧠 Puedes revisar tu configuración con `git config --list`

---

## 🔹 C - Flujo de Trabajo Diario con Git

### 1️⃣ Clonar un repositorio
Para obtener una copia del proyecto y trabajar localmente:
```bash
git clone https://github.com/TuUsuario/nombre-repo.git
cd nombre-repo
```

### 2️⃣ Crear una nueva rama de trabajo
Siempre trabaja en ramas diferentes a `main`:
```bash
git checkout -b mi-rama-de-trabajo
```

### 3️⃣ Hacer cambios y prepararlos
```bash
git add .
```

> 📌 Puedes añadir archivos específicos: `git add archivo.txt`

### 4️⃣ Confirmar (commit) los cambios
```bash
git commit -m "Describe brevemente el cambio realizado"
```

> 🗣 Usa mensajes claros como: `"Corrige error en validación del formulario"`

### 5️⃣ Subir la rama al repositorio remoto
```bash
git push origin mi-rama-de-trabajo
```

---

## 🔄 D - Fusionar Cambios con Pull Request

1. Entra a tu repositorio en GitHub.
2. Crea un **Pull Request** desde tu rama hacia `main`.
3. Agrega una descripción y solicita revisión.
4. Una vez aprobado, puedes fusionar los cambios.

### Actualiza tu rama local:
```bash
git checkout main
git pull origin main
git branch -d mi-rama-de-trabajo
```

---

## 🛠️ Comandos Útiles

| Acción | Comando |
|--------|---------|
| Ver estado de cambios | `git status` |
| Ver historial de commits | `git log --oneline` |
| Ver ramas disponibles | `git branch` |
| Cambiar de rama | `git checkout nombre-rama` |
| Guardar cambios temporales | `git stash` |

---

## ✅ Recomendaciones Finales

- 🧩 **Crea una rama por cada nueva función o corrección**.
- ✍️ **Escribe mensajes de commit descriptivos y consistentes.**
- 🔄 **Haz `pull` frecuentemente para evitar conflictos.**
- 🧼 **Usa `.gitignore` para evitar subir archivos innecesarios.**

---

Ahora que tienes una base sólida para usar Git, puedes aprovechar mejor las guías de este repositorio.  
¡Feliz aprendizaje y codificación! 🚀
