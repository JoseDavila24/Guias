# Fase 0 — Preparación “ruta sencilla” (Windows 10/11)

## 0.1 Decisiones de arranque (enfoque rápido)

* **Plantilla**: `create-t3-app` con: **TypeScript, Tailwind, tRPC, Prisma, App Router, NextAuth**.
* **DB**: **PostgreSQL 16 en Docker** (fijar versión; sin `latest`).
* **Auth inicial**: **NextAuth** con **Credentials Provider** (correo/contraseña) para evitar configurar OAuth desde el día 1. En la Fase 1 definimos el `User` en Prisma, hashing y el `authorize()` mínimo.
* **Variables**: `DATABASE_URL`, `NEXTAUTH_SECRET`, `NEXTAUTH_URL` y `.env.example` desde el inicio (sin secretos). Esto te evita problemas de CI/CD y de onboarding del equipo.&#x20;

## 0.2 Requisitos del sistema y ajustes de Windows (sin dolor)

* Windows actualizado, **virtualización** (VT-x/AMD-V) activa, **16 GB RAM** recomendado.
* Evita problemas de ruta y fin de línea:

  ```powershell
  git config --global core.longpaths true
  git config --global core.autocrlf input
  ```
* **VS Code** con ESLint/Prettier/Tailwind/Prisma/Docker y **Remote–WSL** (opcional pero recomendado).
* **WSL2 + Docker Desktop con engine WSL2**, y **PostgreSQL 16** descargado.
  Estos puntos están ya listados y probados en tu Fase 0 previa; mantenlos idénticos para confiabilidad.&#x20;

## 0.3 Herramientas base (Node, pnpm, Git, Docker)

* Instala **Node LTS** (incluye Corepack).
  Luego:

  ```powershell
  corepack enable
  corepack prepare pnpm@latest --activate
  node -v
  pnpm.cmd -v
  ```
* **Git** con identidad y rama por defecto `main`:

  ```powershell
  git config --global user.name  "Tu Nombre"
  git config --global user.email "tu@email"
  git config --global init.defaultBranch main
  ```
* **Docker Desktop** activado con WSL2. **Fija Postgres 16**:

  ```powershell
  docker pull postgres:16
  ```

  (Fijar versión evita sorpresas y cumple tus RNF de compatibilidad).&#x20;

## 0.4 Plantilla de variables de entorno (desde ya)

Crea **`.env.example`** en blanco de secretos pero completo en claves:

```env
DATABASE_URL="postgresql://USER:PASSWORD@HOST:PORT/DB?schema=public"
NEXTAUTH_URL=""
NEXTAUTH_SECRET=""
NODE_ENV="development"
```

* En la Fase 1 copia esto a `.env` y rellena con tus valores locales (incluido el puerto real de Postgres: 5432/5433). Esta práctica ya la dejaste establecida y conviene mantenerla.&#x20;

## 0.5 PostgreSQL en Docker (pre-chequeo)

Antes de crear el proyecto, asegúrate de que tu equipo corre contenedores sin trabas:

```powershell
docker run --rm hello-world
docker images
docker ps -a
```

Luego, en la Fase 1, lanzarás el contenedor Postgres y apuntarás `DATABASE_URL`. (Tu guía previa ya trae las one-liners y validaciones rápidas para puertos, logs y `psql`—las reutilizaremos tal cual).&#x20;

## 0.6 VS Code: configuración mínima para código limpio

Archivo `.vscode/settings.json` sugerido:

```json
{
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": { "source.fixAll.eslint": true },
  "eslint.validate": ["typescript", "typescriptreact", "javascript"]
}
```

(Está alineado con tu Fase 0 anterior y evita ruido en commits desde el primer día).&#x20;

## 0.7 Checklist de salida (Fase 0 completada)

* [ ] **Node LTS** + **pnpm** activos y verificados.&#x20;
* [ ] **Git** configurado (`core.autocrlf input`, `core.longpaths true`).&#x20;
* [ ] **Docker Desktop** con WSL2 OK; imagen **`postgres:16`** descargada.&#x20;
* [ ] **VS Code** con extensiones clave.&#x20;
* [ ] **`.env.example`** creado con `DATABASE_URL`, `NEXTAUTH_URL`, `NEXTAUTH_SECRET`.&#x20;

---
