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

# Fase 1 — Creación del proyecto con Create-T3-App (100% orientada a **migraciones**)

> Objetivo: generar la app **sigecovip** con T3, dejar **Prisma** listo para **migraciones versionadas** (no `db:push`), y producir la **migración inicial** aun si la base local todavía no está levantada. En Windows 10 Home usa **`pnpm.cmd`** (evita bloqueos de PowerShell).

---

## 1) Scaffold del proyecto

En tu carpeta de trabajo (p. ej. `C:\Dev\sigecovip`):

```powershell
cd C:\Dev\sigecovip
pnpm.cmd dlx create-t3-app@latest sigecovip
```

Responde exactamente:

* **TypeScript**: TypeScript
* **Tailwind CSS**: Yes
* **tRPC**: Yes
* **Auth provider**: NextAuth.js
* **ORM**: Prisma
* **App Router**: Yes
* **DB provider**: PostgreSQL
* **Lint/Format**: ESLint/Prettier
* **Init Git**: Yes
* **Run pnpm install**: Yes
* **Import alias**: @/

---

## 2) Entrar al repo y preparar entorno

```powershell
cd .\sigecovip
```

Crea **.env** (no se commitea). Para ahora basta con:

```dotenv
DATABASE_URL="postgresql://sigeco:sigeco_pass@localhost:5432/sigecovip?schema=public"
NEXTAUTH_URL="http://localhost:3000"
NEXTAUTH_SECRET="dev-secret-change-me"
JWT_SIGNING_KEY="dev-jwt-secret-change-me"
# (opcionales por ahora)
NEXT_PUBLIC_MAPBOX_TOKEN=
NEXT_PUBLIC_FIREBASE_API_KEY=
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=
NEXT_PUBLIC_FIREBASE_PROJECT_ID=
FIREBASE_ADMIN_PROJECT_ID=
FIREBASE_ADMIN_CLIENT_EMAIL=
FIREBASE_ADMIN_PRIVATE_KEY=""
```

> Nota: **No usaremos** `./start-database.sh` ni `pnpm db:push`. Toda sincronización será por **migraciones**.

---

## 3) Configuración de Prisma **centrada en migraciones**

### 3.1 Asegura provider y preview (si aplica)

Abre `prisma/schema.prisma` y confirma:

```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}
```

> El modelo vendrá de la Fase 3 (diseño de datos). Puedes dejar el schema vacío o con el mínimo (ej. tabla Usuario) para crear la migración inicial.

### 3.2 Scripts en `package.json` (estándar de migraciones)

En `package.json` agrega/verifica:

```json
{
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint",
    "prisma:generate": "prisma generate",
    "prisma:migrate:dev": "prisma migrate dev",
    "prisma:migrate:create": "prisma migrate dev --create-only",
    "prisma:migrate:deploy": "prisma migrate deploy",
    "prisma:studio": "prisma studio",
    "db:seed": "ts-node --transpile-only prisma/seed.ts"
  },
  "prisma": {
    "seed": "ts-node --transpile-only prisma/seed.ts"
  }
}
```

> Usaremos **`prisma migrate dev`** y **`prisma migrate deploy`**; el flag **`--create-only`** permite **versionar** sin aplicar aún (ideal si la DB todavía no está arriba).

### 3.3 (Opcional) Seed mínimo

Crea `prisma/seed.ts`:

```ts
import { PrismaClient } from "@prisma/client";
const prisma = new PrismaClient();

async function main() {
  // ejemplo: usuario admin base
  await prisma.usuario?.upsert?.({
    where: { email: "admin@sigecovip.local" },
    update: {},
    create: { nombre: "Admin", email: "admin@sigecovip.local", rol: "admin" },
  });
}

main()
  .catch((e) => { console.error(e); process.exit(1); })
  .finally(() => prisma.$disconnect());
```

> Si aún no tienes el modelo `Usuario` definido, deja el seed vacío y lo completarás en la Fase 3.

---

## 4) Generar **migración inicial** (sin aplicar a DB)

> Esto **versiona** tu esquema aunque **todavía** no tengas PostgreSQL corriendo (lo aplicarás en Fase 2).

```powershell
pnpm.cmd prisma migrate dev --name init --create-only
pnpm.cmd prisma generate
```

* Se crea una carpeta en `prisma/migrations/20YYMMDDHHMMSS_init` con SQL.
* Aún **no** toca la base (no necesita conexión).

> Si ya tuvieras la DB arriba y operativa (Fase 2), podrías **aplicarla** directamente con `pnpm.cmd prisma migrate dev` (sin `--create-only`). En CI/producción usaremos **`prisma migrate deploy`**.

---

## 5) Arranque de la app (smoke test UI)

```powershell
pnpm.cmd dev
```

Abre `http://localhost:3000` para validar el scaffold (no requiere DB arriba para renderizar la página base).

---

## 6) Validaciones técnicas inmediatas

* Lint:

  ```powershell
  pnpm.cmd lint
  ```
* Prisma Client (genera tipos):

  ```powershell
  pnpm.cmd prisma:generate
  ```
* (Opcional, cuando tengas DB arriba) abrir Studio:

  ```powershell
  pnpm.cmd prisma:studio
  ```

---

## 7) Estado al finalizar Fase 1 (listo para migraciones reales)

* Proyecto T3 generado (Next.js + TS + App Router) con **tRPC**, **Auth.js**, **Tailwind**, ESLint/Prettier.
* **Estrategia de datos basada en migraciones**:

  * Migración **inicial** creada y versionada (**`--create-only`**).
  * Scripts listos para `migrate dev` (local) y `migrate deploy` (CI/producción).
  * `db:seed` preparado (si decides usar seed).
* Listo para **Fase 2**: levantar **PostgreSQL con Docker** y **aplicar** migraciones:

  ```powershell
  # Fase 2 (cuando exista la DB)
  pnpm.cmd prisma migrate deploy    # aplica todas las migraciones pendientes
  pnpm.cmd db:seed                  # (opcional) llena datos iniciales
  ```

---

### Notas clave (migraciones)

* **No usar** `pnpm db:push` en este proyecto: no crea migraciones versionadas y complica CI/nube.
* Usa `migrate dev` durante desarrollo interactivo y `migrate deploy` en **CI/producción**.
* Si el schema cambia, repite:

  ```powershell
  pnpm.cmd prisma migrate dev --name <cambio> --create-only   # versiona sin aplicar
  ```

  y más tarde (con DB arriba):

  ```powershell
  pnpm.cmd prisma migrate deploy
  ```


