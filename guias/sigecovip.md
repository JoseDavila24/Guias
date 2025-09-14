# Fase 0 — Preparación del entorno en Windows 10 Home (versión mejorada)

## 0.1 Requisitos del sistema

* **Windows 10 Home** actualizado (20H2+).
* CPU con **virtualización** (Intel VT-x/AMD-V) habilitada en BIOS/UEFI.
* **RAM**: 16 GB recomendados (mínimo 8 GB). **Disco**: ≥30 GB libres.
* Red sin bloqueo hacia `registry.npmjs.org` y contenedores (Docker Hub/GHCR).

> Registra en el Manual: versión de Windows, CPU, RAM, disco y confirmación de virtualización.

---

## 0.2 PowerShell y política de ejecución (evitar bloqueos)

* Si PowerShell bloquea scripts (`*.ps1`), tienes tres caminos:

  1. **Usar los wrappers `.cmd`** (recomendado en tu caso): `npm.cmd`, `pnpm.cmd`, `npx.cmd`.
  2. Permitir scripts para tu usuario:

     ```powershell
     Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
     ```
  3. Solo para la sesión actual:

     ```powershell
     Set-ExecutionPolicy -Scope Process Bypass
     ```

> Con esto evitas el error de “la ejecución de scripts está deshabilitada”.

---

## 0.3 Node.js + Corepack (pnpm)

1. Instala **Node.js LTS** (incluye `npm` y **Corepack**).
2. Habilita **pnpm** con Corepack:

   ```powershell
   corepack enable
   corepack prepare pnpm@latest --activate
   ```
3. Verificaciones (usa `.cmd` donde aplique):

   ```powershell
   node -v
   npm.cmd -v
   corepack --version
   pnpm.cmd -v
   ```

> Si `pnpm` sin `.cmd` falla, sigue usando `pnpm.cmd` o aplica 0.2.

---

## 0.4 Git y GitHub CLI

1. Instala **Git** (marca “Git from command line”).
2. Configura identidad:

   ```powershell
   git config --global user.name  "Tu Nombre"
   git config --global user.email "tu@email"
   git config --global init.defaultBranch main
   ```
3. (Opcional) **GitHub CLI**:

   ```powershell
   gh --version
   gh auth login
   ```

---

## 0.5 VS Code y extensiones (mínimo viable)

* **VS Code** actualizado.
* Extensiones: **ESLint**, **Prettier**, **Prisma**, **Tailwind CSS IntelliSense**, **Docker**, **GitHub Actions**.
* Ajustes sugeridos (`.vscode/settings.json`):

  ```json
  {
    "editor.formatOnSave": true,
    "eslint.validate": ["typescript", "typescriptreact", "javascript"]
  }
  ```

---

## 0.6 WSL2 y Docker Desktop (imprescindible en Win10 Home)

### 0.6.1 Activar características

Ejecuta PowerShell **como Administrador**:

```powershell
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```

Reinicia.

### 0.6.2 Instalar/actualizar WSL

* Instala distro (si no la tienes):

  ```powershell
  wsl --install -d Ubuntu
  ```
* Como te pidió Docker, **actualiza el kernel**:

  ```powershell
  wsl --update
  wsl --set-default-version 2
  wsl --status
  ```

### 0.6.3 Instalar y configurar Docker Desktop (descarga oficial)

* **General**: activa **“Use the WSL 2 based engine”**.
* **Resources → WSL Integration**: habilita **Ubuntu**.
* **Resources → Advanced**: asigna **4 vCPU** y **6–8 GB RAM** para un flujo cómodo (Next.js + Prisma + Postgres).

**Smoke test Docker**

```powershell
docker version
docker info
docker run --rm hello-world
```

---

## 0.7 PostgreSQL en contenedor: fijar versión (importante)

* `docker pull postgres` **descarga la última estable** (actualmente suele ser **17**).
* Para **evitar incompatibilidades** entre entornos y CI/CD, **fija versión** explícita. Recomendamos **PostgreSQL 16** por estabilidad y amplia cobertura en proveedores y tooling.

**Descarga la imagen recomendada:**

```powershell
docker pull postgres:16
```

> Si prefieres 17, cámbialo a `postgres:17` en **todos** tus archivos (local, CI/CD). Lo clave es **no usar `latest`** y ser consistente.

---

## 0.8 Utilidades opcionales

* **psql** (cliente Postgres) en WSL:

  ```bash
  sudo apt update && sudo apt install -y postgresql-client
  psql --version
  ```
* **mkcert** (TLS local), **7-Zip/PeaZip** (backups/exports).

---

## 0.9 Validaciones finales (checklist)

* [ ] `node -v`, `npm.cmd -v`, `pnpm.cmd -v`, `corepack --version` OK.
* [ ] **ExecutionPolicy** resuelto o decidido usar `.cmd`.
* [ ] **WSL** actualizado: `wsl --update` ejecutado, **WSL2** por defecto.
* [ ] **Docker Desktop** con engine WSL2 y **hello-world** OK.
* [ ] Imagen Postgres **fijada**: `docker pull postgres:16` descargada.
* [ ] VS Code con extensiones clave.
* [ ] Git configurado; (opcional) `gh auth login` completado.

---

### Notas y buenas prácticas

* **Version pinning**: fija versiones en imágenes (`postgres:16`), Node (LTS), y en CI (Actions) para reproducibilidad.
* **Red corporativa/antivirus**: si bloquea TLS/registro npm, documenta excepciones.
* **Espacio Docker**: limpia periódicamente (`docker system prune`) con cautela (verifica qué eliminarás).
* **Secretos**: prepara desde ahora un `.env.example` (sin credenciales) y define cómo manejarás secretos en CI/Cloud.

---

# Fase 1 — Creación del proyecto con Create-T3-App (ajustada a tus respuestas y a PowerShell)

> Contexto Windows 10 Home: en **PowerShell** la ejecución de scripts puede estar restringida; por eso usa **`pnpm.cmd`** (no `pnpm`) para evitar el bloqueo de `*.ps1`.
> Esta fase deja el proyecto **sigecovip** listo para enlazarlo con PostgreSQL en Docker (Fase 2), Auth y mapas.

---

## 1. Generación del proyecto

En tu carpeta de trabajo (p. ej. `C:\Dev\sigecovip`):

```powershell
cd C:\Dev\sigecovip
pnpm.cmd dlx create-t3-app@latest sigecovip
```

Responde EXACTAMENTE como lo hiciste:

* **TypeScript**: `TypeScript`
* **Tailwind CSS**: `Yes`
* **tRPC**: `Yes`
* **Auth provider**: `NextAuth.js`
* **ORM**: `Prisma`
* **App Router**: `Yes`
* **DB provider**: `PostgreSQL`
* **Lint/Format**: `ESLint/Prettier`
* **Init Git**: `Yes`
* **Run pnpm install**: `Yes`
* **Import alias**: `@/`

Con esas opciones, el generador crea:

* **Next.js + TypeScript** con **App Router**.
* **tRPC** (server procedures tipadas end-to-end).
* **Prisma** configurado con datasource PostgreSQL.
* **Auth.js (NextAuth)** ya integrado.
* **TailwindCSS** para UI.
* Linter/formatter: **ESLint + Prettier**.
* Repo git inicial con commit.

---

## 2. “Next steps” del CLI (y cómo adaptarlos a tu setup)

El CLI te mostró:

```
cd sigecovip
Start up a database, if needed using './start-database.sh'
pnpm db:push
Fill in your .env ...
pnpm dev
git commit -m "initial commit"
```

**Interpretación para SIGECOVIP (Opción C + PostgreSQL en Docker):**

1. **Entrar al proyecto**

```powershell
cd .\sigecovip
```

2. **Base de datos**

* **No uses** `./start-database.sh` (ese script es genérico).
* En su lugar, en la **Fase 2** levantarás **PostgreSQL con Docker** vía `docker compose`.
* Asegúrate de tener la conexión lista y la variable `DATABASE_URL` correcta (ver §3 abajo).

3. **Variables de entorno**
   Copia `.env.example` a `.env` y completa **al menos**:

```dotenv
DATABASE_URL="postgresql://sigeco:sigeco_pass@localhost:5432/sigecovip?schema=public"
NEXTAUTH_URL="http://localhost:3000"
NEXTAUTH_SECRET="dev-secret-change-me"
JWT_SIGNING_KEY="dev-jwt-secret-change-me"   # si usarás Credentials/JWT propio
# Mapas (opcional):
NEXT_PUBLIC_MAPBOX_TOKEN=
# Firebase (si lo activas después):
NEXT_PUBLIC_FIREBASE_API_KEY=
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=
NEXT_PUBLIC_FIREBASE_PROJECT_ID=
FIREBASE_ADMIN_PROJECT_ID=
FIREBASE_ADMIN_CLIENT_EMAIL=
FIREBASE_ADMIN_PRIVATE_KEY=""
```

> Nota: `.env` **no** se commitea.

4. **Sincronización de esquema**
   Tienes dos opciones; para SIGECOVIP (control serio de cambios) recomiendo **migraciones**:

* **Opción A — Migraciones (recomendada)**

  ```powershell
  pnpm.cmd prisma migrate dev --name init
  pnpm.cmd prisma generate
  ```

  Crea una migración versionada en `prisma/migrations/`. Ideal para CI/CD y para la futura migración a nube.

* **Opción B — Push rápido (solo desarrollo temprano)**

  ```powershell
  pnpm.cmd db:push
  pnpm.cmd prisma generate
  ```

  Empuja el schema a la DB **sin** crear migraciones (útil para prototipos). Más adelante deberás pasar a migraciones.

5. **Arranque de la app**

```powershell
pnpm.cmd dev
```

Navega a `http://localhost:3000` y valida que el proyecto inicial levanta.

---

## 3. Validaciones técnicas inmediatas

* **`pnpm.cmd install`** no debería descargar nada extra (ya se ejecutó al generar el proyecto).
* **`pnpm.cmd lint`** → el linter debe pasar sin errores.
* **`pnpm.cmd prisma studio`** (opcional) para abrir UI de Prisma y verificar conexión a PostgreSQL en `localhost:5432`.
* **Auth**: por ahora verás pantallas base de Auth.js; la estrategia exacta (Credentials/JWT propio y/o Firebase) se activa en Fase 5.
* **tRPC**: el esqueleto de routers ya está conectado; más adelante crearás routers de `comerciante/inspeccion/usuario/auditoria`.

---

## 4. Estructura y scripts relevantes (lo que ya tienes)

* **Scripts** en `package.json` típicos de T3:

  * `dev`, `build`, `start`, `lint`, `db:push`, `prisma:*` (según template).
* **Ramas Git**: ya hay **repo**; define tu flujo (`main` protegido + `feat/*`, `fix/*`) en la Fase 9.
* **Paths/alias**: importaciones con `@/` habilitadas (más limpio para módulos).

---

## 5. Gotchas en Windows/PowerShell

* Si `pnpm` (sin `.cmd`) falla por ExecutionPolicy, usa **`pnpm.cmd`** o ejecuta:

  ```powershell
  Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
  ```
* Si tu red corporativa bloquea el registro de npm, ya confirmamos que **tu conexión a `registry.npmjs.org` funciona**; no es necesario cambiar registry.

---

## 6. Qué queda listo al terminar Fase 1

* Proyecto **sigecovip** generado con **Next.js + TypeScript + App Router**.
* **tRPC** y **Auth.js** integrados.
* **Prisma** apuntando a **PostgreSQL** (a la espera de que levantes el contenedor en Fase 2).
* **Tailwind** listo para construir UI responsiva.
* **Lint/Format** operativos con ESLint/Prettier.
* **Git** inicializado con commit.

