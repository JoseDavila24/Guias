# **Guía Completa para Usar Git**

Git es un sistema de control de versiones distribuido que te permite gestionar y colaborar en proyectos de software. Esta guía cubre los pasos esenciales para subir, actualizar y mantener repositorios en Git.

---

## **1. Configuración Inicial**

### Instalar Git
- Descarga Git desde [git-scm.com](https://git-scm.com/).
- Sigue las instrucciones de instalación para tu sistema operativo.

### Configurar Git
Abre una terminal y configura tu nombre y correo electrónico:
```bash
git config --global user.name "Tu Nombre"
git config --global user.email "tu-email@ejemplo.com"
```

### Verificar la configuración
```bash
git config --list
```

---

## **2. Crear o Clonar un Repositorio**

### Crear un nuevo repositorio local
1. Crea una carpeta para tu proyecto:
   ```bash
   mkdir mi-proyecto
   cd mi-proyecto
   ```
2. Inicializa un repositorio Git:
   ```bash
   git init
   ```

### Clonar un repositorio existente
Si ya tienes un repositorio en GitHub o en otro servidor remoto, clónalo:
```bash
git clone https://github.com/tu-usuario/tu-repositorio.git
cd tu-repositorio
```

---

## **3. Trabajar con Ramas**

### Crear una nueva rama
Para trabajar en una nueva funcionalidad o corrección, crea una rama:
```bash
git checkout -b nombre-de-la-rama
```

### Cambiar entre ramas
Para cambiar a una rama existente:
```bash
git checkout nombre-de-la-rama
```

### Ver todas las ramas
```bash
git branch
```

---

## **4. Hacer Cambios y Confirmarlos**

### Ver el estado del repositorio
```bash
git status
```

### Agregar cambios al área de preparación (staging)
Agrega archivos específicos:
```bash
git add archivo1.txt archivo2.txt
```
O agrega todos los cambios:
```bash
git add .
```

### Confirmar los cambios
```bash
git commit -m "Descripción breve de los cambios realizados"
```

---

## **5. Sincronizar con el Repositorio Remoto**

### Subir cambios a GitHub
Sube los cambios de tu rama local al repositorio remoto:
```bash
git push origin nombre-de-la-rama
```

### Actualizar tu repositorio local
Para obtener los últimos cambios del repositorio remoto:
```bash
git fetch origin
git pull origin nombre-de-la-rama
```

---

## **6. Fusionar Cambios**

### Fusionar una rama con la rama principal
1. Cambia a la rama principal:
   ```bash
   git checkout main
   ```
2. Fusiona la rama:
   ```bash
   git merge nombre-de-la-rama
   ```
3. Sube los cambios fusionados:
   ```bash
   git push origin main
   ```

### Resolver conflictos
Si hay conflictos al fusionar, Git te lo indicará. Edita los archivos conflictivos, resuelve los conflictos y luego:
```bash
git add archivo-con-conflicto
git commit -m "Resuelto conflicto en archivo-con-conflicto"
```

---

## **7. Crear y Gestionar Pull Requests (PR)**

1. Sube tu rama al repositorio remoto:
   ```bash
   git push origin nombre-de-la-rama
   ```
2. Ve a GitHub y crea un Pull Request desde tu rama hacia la rama principal (`main` o `master`).
3. Espera a que los colaboradores revisen y aprueben tus cambios.
4. Fusiona el PR en GitHub o desde la terminal.

---

## **8. Mantener el Repositorio Actualizado**

### Sincronizar con cambios remotos
Antes de empezar a trabajar, siempre actualiza tu repositorio local:
```bash
git fetch origin
git pull origin main
```

### Limpiar ramas obsoletas
Elimina ramas locales que ya no necesites:
```bash
git branch -d nombre-de-la-rama
```
Elimina ramas remotas obsoletas:
```bash
git push origin --delete nombre-de-la-rama
```

---

## **9. Comandos Útiles**

### Ver el historial de commits
```bash
git log
```

### Deshacer cambios locales
Descartar cambios en un archivo:
```bash
git checkout -- archivo.txt
```

### Revertir un commit
```bash
git revert commit-id
```

### Ver diferencias entre cambios
```bash
git diff
```

---

## **10. Flujo de Trabajo Recomendado**

1. **Actualiza tu repositorio local** antes de empezar a trabajar:
   ```bash
   git fetch origin
   git pull origin main
   ```
2. **Crea una rama** para tus cambios:
   ```bash
   git checkout -b nombre-de-la-rama
   ```
3. **Haz tus cambios** y confírmalos:
   ```bash
   git add .
   git commit -m "Descripción de los cambios"
   ```
4. **Sube tus cambios** al repositorio remoto:
   ```bash
   git push origin nombre-de-la-rama
   ```
5. **Crea un Pull Request** en GitHub para revisión y fusión.
