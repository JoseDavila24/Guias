# Fase 0 — Preparación del entorno en Windows 10 Home (técnico/profesional)

> Objetivo: dejar el equipo listo para desarrollar SIGECOVIP con **Create-T3-App (Next.js + TypeScript + tRPC + Prisma + Tailwind)**, **PostgreSQL en Docker**, e integraciones modulares (Mapbox/Firebase) bajo el enfoque **Opción C (híbrida)** que ya definiste en tus documentos.

---

## 0.1 Requisitos del sistema

* **Windows 10 Home** actualizado (20H2+ recomendado).
* CPU con **virtualización** habilitada (Intel VT-x/AMD-V) en BIOS/UEFI.
* 16 GB RAM (mínimo 8 GB), 30+ GB libres en disco.
* Conectividad de red sin bloqueo a `registry.npmjs.org` y `ghcr.io`.

> En el Manual Técnico registra: versión de Windows, CPU, RAM, disco y confirmación de virtualización.

---

## 0.2 PowerShell y política de ejecución

Para evitar bloqueos al usar herramientas **pnpm/npx** en PS:

* Opción segura (por sesión):

  ```powershell
  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
  ```
* Opción persistente (recomendada para tu usuario):

  ```powershell
  Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
  ```

> Nota: Siempre puedes invocar **`pnpm.cmd`** para saltar restricciones si fuese necesario.

---

## 0.3 Node.js + Corepack (pnpm)

1. **Instala Node.js LTS** (o superior).
2. **Habilita Corepack** y activa pnpm:

   ```powershell
   corepack enable
   corepack prepare pnpm@latest --activate
   pnpm.cmd -v
   ```

   Si quieres usar `pnpm` (sin `.cmd`), asegúrate de haber aplicado 0.2.

**Comprobaciones**

```powershell
node -v
npm -v
corepack --version
pnpm.cmd -v
```

---

## 0.4 Git y GitHub CLI

1. **Instala Git** (habilita “Git from command line”).
2. Configura identidad global:

   ```powershell
   git config --global user.name  "Tu Nombre"
   git config --global user.email "tu@email"
   git config --global init.defaultBranch main
   ```
3. **GitHub CLI (opcional, recomendado)**:

   ```powershell
   gh --version
   gh auth login
   ```

---

## 0.5 VS Code y extensiones

* **VS Code** actualizado.
* Extensiones mínimas:

  * **ESLint**, **Prettier**, **Prisma**, **Tailwind CSS IntelliSense**, **Docker**, **GitHub Actions**.
* Ajustes recomendados (`.vscode/settings.json` del repo más adelante):

  * `"editor.formatOnSave": true`
  * `"eslint.validate": ["typescript","typescriptreact","javascript"]`

---

## 0.6 WSL2 y Docker Desktop (imprescindible en Win10 Home)

### 0.6.1 Activar características de Windows

Ejecuta PowerShell **Administrador**:

```powershell
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```

Reinicia.

### 0.6.2 Instalar distribución WSL y configurar WSL2

```powershell
wsl --install -d Ubuntu
wsl --set-default-version 2
wsl --status
```

### 0.6.3 Instalar y configurar Docker Desktop

* En **Settings → General**: activa **“Use the WSL 2 based engine”**.
* En **Resources → WSL Integration**: habilita tu distro (Ubuntu).
* En **Resources → Advanced**: reserva **CPU/RAM** (ej. 4 vCPU / 6-8 GB) para cargas con Postgres, Prisma y el frontend.

**Pruebas rápidas Docker**

```powershell
docker version
docker info
docker run --rm hello-world
docker pull postgres:16
```

> Tu arquitectura (Docker + PostgreSQL) está alineada al diseño y RNF de compatibilidad y escalabilidad definidos.

---

## 0.7 Utilidades opcionales (recomendadas)

* **7-Zip** o **PeaZip** (manejo de backups/exports).
* **mkcert** (TLS local, si pruebas HTTPS).
* **PostgreSQL client** (`psql`) dentro de WSL o contenedor:

  ```bash
  # en Ubuntu (WSL)
  sudo apt update && sudo apt install -y postgresql-client
  psql --version
  ```

---

## 0.8 Validaciones finales (checklist)

* [ ] `node -v`, `npm -v`, `pnpm.cmd -v`, `corepack --version` OK.
* [ ] PS con ExecutionPolicy ajustada (o decidido usar `pnpm.cmd`).
* [ ] Docker Desktop operativo con WSL2 engine; `docker run hello-world` OK.
* [ ] Imagen `postgres:16` descargada.
* [ ] VS Code con extensiones instaladas.
* [ ] Git configurado (`git config --global --list`).
* [ ] (Opcional) `gh auth login` realizado.

> **Registro en Manual Técnico** (sección “Requisitos del entorno”): versiones instaladas, política de ejecución adoptada, capturas de `docker info` y `pnpm.cmd -v`, y observaciones de red/seguridad. Esta sección conecta con el stack y compatibilidad documentados en ERS/Manual.

---

## 0.9 Notas operativas (riesgos tempranos)

* **Antivirus/Firewall corporativo**: puede interferir con `registry.npmjs.org` o sockets Docker. Documenta exclusiones si aplica.
* **Espacio en disco**: Docker y volúmenes de Postgres crecen; planifica limpieza con `docker system prune` (con cuidado).
* **Telemetría/privacidad**: registra en el Manual cómo se resguardarán `.env` y secretos (se usan en fases siguientes).

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

