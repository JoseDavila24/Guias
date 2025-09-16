# Fase 1 — Inicialización del Proyecto (SIGECOVIP)

## 1) Objetivo y resultados esperados

Dejar el proyecto **Create-T3-App** funcionando con base sólida y reproducible:

* Git inicializado.
* **PostgreSQL 16 en Docker** (versión fijada).
* **.env** (local, no versionado) y **.env.example** (versionado, sin secretos).
* **Prisma** con migraciones iniciales (NextAuth + entidades SIGECOVIP).
* **NextAuth** operativo (secret configurado).
* **tRPC** con healthcheck.
* **ESLint + Prettier + Husky (pre-commit)** con **`pnpm exec`** para Windows.
* **CI en GitHub Actions** con Postgres de servicio, variables mínimas y pinning.
  (Alineado a RNF y alcance del Charter/ERS/EVS.)

---

## 2) Crear el proyecto base

En **PowerShell** (usa wrappers `.cmd`):

```powershell
cd D:\Dev
pnpm.cmd dlx create-t3-app@latest sigecovip
```

Selecciona:

* TypeScript ✅ Tailwind ✅ tRPC ✅
* NextAuth.js ✅ Prisma ✅ App Router ✅
* PostgreSQL ✅ ESLint + Prettier ✅
* Init Git ✅ Run pnpm install ✅
* Import alias @/ ✅

> Soporta RF/RNF del alcance definido.

---

## 3) PostgreSQL 16 en Docker (local, versión fijada)

```powershell
docker pull postgres:16
docker run --name pg-sigecovip ^
  -e POSTGRES_PASSWORD=postgres -e POSTGRES_USER=postgres -e POSTGRES_DB=sigecovip ^
  -p 5432:5432 -d postgres:16

docker ps -a
```

> Evita `latest` y garantiza compatibilidad tecnológica.

---

## 4) Variables de entorno

Archivo **`sigecovip/.env`** (local, NO versionar):

```env
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/sigecovip?schema=public"
NEXTAUTH_URL="http://localhost:3000"
NEXTAUTH_SECRET="cambia-esto-por-un-valor-largo-y-seguro"
NODE_ENV="development"
```

Archivo **`sigecovip/.env.example`** (SÍ versionar, sin secretos):

```env
DATABASE_URL="postgresql://USER:PASSWORD@HOST:PORT/DB?schema=public"
NEXTAUTH_URL=""
NEXTAUTH_SECRET=""
NODE_ENV="development"
```

> Buenas prácticas y RNF-04 (seguridad).

---

## 5) Prisma — esquema inicial y migraciones

1. Generar cliente y migración base:

```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

enum RolUsuario { INSPECTOR COORDINADOR }

enum EstatusOperativo { VIGENTE IRREGULAR SANCIONADO EN_TRAMITE }

enum AccionAuditoria { ALTA BAJA MODIFICACION LOGIN REPORTE }
enum ModuloAuditoria { COMERCIANTE INSPECCION REPORTE USUARIO }

model Usuario {
  id            String       @id @default(uuid())
  nombre        String
  email         String       @unique @db.Citext // requiere extensión citext; si no la usas, quita @db.Citext
  hashPassword  String
  rol           RolUsuario
  creadoEn      DateTime     @default(now())
  actualizadoEn DateTime     @updatedAt

  inspecciones  Inspeccion[] @relation("InspectorInspecciones")
  reportes      Reporte[]    @relation("AutorReportes")
  auditorias    Auditoria[]  @relation("AutorAuditorias")
}

model Comerciante {
  id                String               @id @default(uuid())
  titularNombre     String
  giro              String
  superficieM2      Decimal              @db.Decimal(10,2)
  diasOperacion     String
  horarioOperacion  String
  tipoMontaje       String
  licenciaPermiso   String?
  direccion         String
  latitud           Decimal              @db.Decimal(9,6)
  longitud          Decimal              @db.Decimal(9,6)
  organizacion      String?
  estatus           EstatusOperativo     @default(VIGENTE)
  fotos             Json?
  documentos        Json?
  creadoEn          DateTime             @default(now())
  actualizadoEn     DateTime             @updatedAt

  inspecciones      Inspeccion[]
  reportesIncluidos ReporteComerciante[]

  @@index([estatus])
  @@index([latitud, longitud])
  // Opcional: evitar duplicados evidentes
  // @@unique([titularNombre, direccion])
}

model Inspeccion {
  id            String      @id @default(uuid())
  fechaHora     DateTime    @default(now())
  notas         String
  evidencias    Json?
  comercianteId String
  inspectorId   String

  comerciante   Comerciante @relation(fields: [comercianteId], references: [id], onDelete: Restrict)
  inspector     Usuario     @relation("InspectorInspecciones", fields: [inspectorId], references: [id], onDelete: SetNull)

  creadoEn      DateTime    @default(now())
  actualizadoEn DateTime    @updatedAt

  @@index([comercianteId])
  @@index([inspectorId])
  @@index([fechaHora])
}

model Reporte {
  id              String              @id @default(uuid())
  tipo            String
  rangoFechas     String
  formato         String              // "PDF" | "Excel" | "CSV"
  fechaGeneracion DateTime            @default(now())
  autorId         String

  autor           Usuario             @relation("AutorReportes", fields: [autorId], references: [id], onDelete: SetNull)
  incluye         ReporteComerciante[]

  creadoEn        DateTime            @default(now())
  actualizadoEn   DateTime            @updatedAt

  @@index([autorId])
  @@index([fechaGeneracion])
}

// Clave compuesta (sin id artificial)
model ReporteComerciante {
  reporteId     String
  comercianteId String

  reporte       Reporte     @relation(fields: [reporteId], references: [id], onDelete: Cascade)
  comerciante   Comerciante @relation(fields: [comercianteId], references: [id], onDelete: Cascade)

  @@id([reporteId, comercianteId])
}

model Auditoria {
  id         String           @id @default(uuid())
  usuarioId  String?
  accion     AccionAuditoria
  modulo     ModuloAuditoria
  fechaHora  DateTime         @default(now())
  detalle    String?

  autor      Usuario?         @relation("AutorAuditorias", fields: [usuarioId], references: [id], onDelete: SetNull)

  @@index([usuarioId, fechaHora])
}
```

```powershell
pnpm.cmd prisma generate
pnpm.cmd prisma migrate dev --name init
```

2. Scripts útiles en `package.json`:

```json
"scripts": {
  "db:generate": "prisma generate",
  "db:migrate": "prisma migrate dev",
  "db:deploy": "prisma migrate deploy"
}
```

> El modelo debe cubrir Usuario/Comerciante/Inspección/Reporte/Auditoría (ver Diseño).

---

## 6) Calidad de código y hooks (ESLint/Prettier/Husky + lint-staged) — **con fix para Windows**

1. Instalar dependencias:

```powershell
pnpm.cmd add -D husky lint-staged eslint prettier
```

2. Activar Husky:

```powershell
pnpm.cmd dlx husky-init
pnpm.cmd install
```

3. Configurar **lint-staged** en `package.json`:

```json
"lint-staged": {
  "*.{js,ts,tsx}": ["eslint --fix", "prettier --write"],
  "*.{json,md,css,scss}": ["prettier --write"]
}
```

4. **Hook pre-commit** (reemplaza `.husky/pre-commit`):

```sh
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

pnpm exec lint-staged
```

> Uso de **`pnpm exec`** evita el error “`lint-staged` no se reconoce…” en Windows.

**Tip (pnpm builds):**

```powershell
pnpm.cmd approve-builds
```

Selecciona Prisma/Tailwind si ves el aviso de “Ignored build scripts”.

---

## 7) CI en GitHub Actions (con Postgres de servicio, versión fijada)

Crea **`.github/workflows/ci.yml`**:

```yaml
name: CI
on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: sigecovip
        ports: ["5432:5432"]
        options: >-
          --health-cmd="pg_isready -U postgres"
          --health-interval=10s
          --health-timeout=5s
          --health-retries=5

    env:
      DATABASE_URL: postgresql://postgres:postgres@localhost:5432/sigecovip?schema=public
      NEXTAUTH_SECRET: test-secret
      NEXTAUTH_URL: http://localhost:3000
      NODE_ENV: test

    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: pnpm
      - run: corepack enable
      - run: pnpm install --frozen-lockfile
      - run: pnpm prisma generate
      - run: pnpm prisma migrate deploy
      - run: pnpm lint
      - run: pnpm build
      - run: pnpm test --if-present
```

> Cumple RNF-06 (compatibilidad) y CI con Postgres 16.

---

## 8) tRPC — healthcheck mínimo

`src/server/api/routers/health.ts`

```ts
import { createTRPCRouter, publicProcedure } from "@/server/api/trpc";

export const healthRouter = createTRPCRouter({
  ping: publicProcedure.query(() => ({ ok: true, ts: Date.now() })),
});
```

Expón `healthRouter` en tu `appRouter` y verifica desde el panel de tRPC o un fetch simple.

---

## 9) NextAuth — secreto y URL operativos

En `.env`:

```
NEXTAUTH_URL="http://localhost:3000"
NEXTAUTH_SECRET="cambia-esto-por-un-valor-largo-y-seguro"
```

En `.env.example` (sin secretos):

```
NEXTAUTH_URL=""
NEXTAUTH_SECRET=""
```

> Requisito de seguridad (RNF-04) y alcance funcional.

---

## 10) Ajustes de VS Code recomendados

`.vscode/settings.json`

```json
{
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": { "source.fixAll.eslint": true },
  "eslint.validate": ["typescript", "typescriptreact", "javascript"]
}
```

> Flujo recomendado desde Fase 0.

---

## 11) Checklist final de Fase 1

* [ ] Contenedor **`pg-sigecovip`** (imagen `postgres:16`) corriendo.
* [ ] `.env` local correcto y **`.env.example`** versionado (sin secretos).
* [ ] `pnpm prisma migrate dev` aplicado (tablas creadas).
* [ ] **Husky pre-commit** ejecuta `pnpm exec lint-staged` sin errores.
* [ ] `pnpm lint`, `pnpm build` y (si aplica) `pnpm test` OK.
* [ ] **CI** verde en GitHub con Postgres 16 de servicio.
* [ ] tRPC **/health.ping** responde `{ ok: true }`.
* [ ] **NextAuth** sin warnings por `NEXTAUTH_SECRET`.

---
