# Fase 1 — Creación del proyecto SIGECOVIP con Create-T3-App

**Objetivo:** generar el proyecto base `sigecovip` con el stack aprobado (**Create-T3-App + PostgreSQL en Docker + Prisma + tRPC + NextAuth.js**), dejando lista la **infraestructura de migraciones** para soportar las entidades definidas en el diseño: `Usuario`, `Comerciante`, `Inspección`, `Reporte`, `Auditoría`.

---

## 1. Scaffold inicial

En tu carpeta de trabajo (`D:\Dev\sigecovip`):

```powershell
cd D:\Dev
pnpm.cmd dlx create-t3-app@latest sigecovip
```

Selección:

* TypeScript ✅
* Tailwind ✅
* tRPC ✅
* Auth provider: NextAuth.js ✅
* ORM: Prisma ✅
* App Router ✅
* DB provider: PostgreSQL ✅
* ESLint + Prettier ✅
* Init Git ✅
* Run pnpm install ✅
* Import alias: @/ ✅

---

## 2. Base de datos en Docker (opcional, solo para testear)

Levantaste un contenedor PostgreSQL 16:

```powershell
docker run --name pg16-sigecovip `
  -e POSTGRES_USER=sigeco `
  -e POSTGRES_PASSWORD=sigeco_pass `
  -e POSTGRES_DB=sigecovip `
  -p 5432:5432 -d postgres:16
```

Verificación:

```powershell
docker ps
```

Resultado: contenedor `pg16-sigecovip` corriendo en `localhost:5432`.

---

## 3. Variables de entorno

Archivo `.env` configurado:

```dotenv
# ===========================================
# NextAuth Configuración base
# ===========================================

# Secret para NextAuth. El que crea T3 es válido, pero puedes regenerarlo:
# npx auth secret
AUTH_SECRET="Iu944Zhi/YJhGUyPtUbWk5ktu2sEEe+wu1LuFUrAyX0="

# URL base de la aplicación
NEXTAUTH_URL="http://localhost:3000"

# Solo necesitas UNO de los dos (mantén coherencia):
# - AUTH_SECRET (el recomendado con T3 moderno)
# - NEXTAUTH_SECRET (legacy). Puedes eliminarlo si ya usas AUTH_SECRET.
#NEXTAUTH_SECRET="dev-secret-change-me"

# ===========================================
# Proveedores externos (vacíos por ahora)
# ===========================================
# Ejemplo con Discord (no se usará en SIGECOVIP, puedes dejarlo vacío o eliminarlo)
AUTH_DISCORD_ID="dummy"
AUTH_DISCORD_SECRET="dummy"

# Tokens que sí usarás en SIGECOVIP
NEXT_PUBLIC_MAPBOX_TOKEN=
FIREBASE_ADMIN_PROJECT_ID=
FIREBASE_ADMIN_CLIENT_EMAIL=
FIREBASE_ADMIN_PRIVATE_KEY=""

# ===========================================
# Prisma / Base de datos
# ===========================================

# URL de conexión a PostgreSQL en Docker
# NOTA: Ya incluye usuario `sigeco`, contraseña `sigeco_pass` y el schema `public`
DATABASE_URL="postgresql://sigeco:sigeco_pass@localhost:5432/sigecovip?schema=public"
```

---

## 4. Modelo de datos (Prisma)

En `prisma/schema.prisma`:

```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

enum RolUsuario {
  INSPECTOR
  COORDINADOR
}

enum EstatusOperativo {
  VIGENTE
  IRREGULAR
  SANCIONADO
  EN_TRAMITE
}

model Usuario {
  id            String    @id @default(uuid())
  nombre        String
  email         String    @unique
  hashPassword  String
  rol           RolUsuario
  creadoEn      DateTime  @default(now())
  actualizadoEn DateTime  @updatedAt

  inspecciones  Inspeccion[] @relation("UsuarioInspecciones")
  reportes      Reporte[]    @relation("UsuarioReportes")
  auditorias    Auditoria[]
}

model Comerciante {
  id               String    @id @default(uuid())
  titularNombre    String
  giro             String
  superficieM2     Decimal?  @db.Decimal(10, 2)
  diasOperacion    String?
  horarioOperacion String?
  tipoMontaje      String?
  licenciaPermiso  String?
  direccion        String?
  latitud          Decimal?  @db.Decimal(9, 6)
  longitud         Decimal?  @db.Decimal(9, 6)
  organizacion     String?
  estatus          EstatusOperativo
  creadoEn         DateTime  @default(now())
  actualizadoEn    DateTime  @updatedAt

  inspecciones     Inspeccion[]
  reportes         ReporteComerciante[] // N:M con Reporte
}

model Inspeccion {
  id            String      @id @default(uuid())
  fechaHora     DateTime    @default(now())
  notas         String?
  evidenciasUrl String?

  comerciante   Comerciante @relation(fields: [idComerciante], references: [id])
  idComerciante String

  inspector     Usuario     @relation("UsuarioInspecciones", fields: [idInspector], references: [id])
  idInspector   String
}

model Reporte {
  id              String               @id @default(uuid())
  tipo            String
  rangoFechas     String?
  formato         String?              // "PDF" | "Excel" | "CSV"
  fechaGeneracion DateTime             @default(now())

  autor           Usuario              @relation("UsuarioReportes", fields: [idAutor], references: [id])
  idAutor         String

  comerciantes    ReporteComerciante[]
  creadoEn        DateTime             @default(now())
}

model ReporteComerciante {
  idReporte     String
  idComerciante String

  reporte       Reporte     @relation(fields: [idReporte], references: [id])
  comerciante   Comerciante @relation(fields: [idComerciante], references: [id])

  @@id([idReporte, idComerciante])
}

model Auditoria {
  id        String   @id @default(uuid())
  usuario   Usuario? @relation(fields: [usuarioId], references: [id])
  usuarioId String?
  accion    String   // "alta" | "baja" | "modificacion" | "login" | "reporte"
  modulo    String   // "comerciante" | "inspeccion" | "reporte" | "usuario"
  fechaHora DateTime @default(now())
  detalle   String?
}
```

---

## 5. Scripts de migración (`package.json`)

```json
  "scripts": {
    "dev": "next dev --turbo",
    "build": "next build",
    "start": "next start",
    "preview": "next build && next start",

    "prisma:generate": "prisma generate",
    "prisma:migrate:dev": "prisma migrate dev",
    "prisma:migrate:create": "prisma migrate dev --create-only",
    "prisma:migrate:deploy": "prisma migrate deploy",
    "prisma:studio": "prisma studio",
    "db:seed": "ts-node --transpile-only prisma/seed.ts",

    "lint": "next lint",
    "lint:fix": "next lint --fix",
    "typecheck": "tsc --noEmit",
    "format:check": "prettier --check \"**/*.{ts,tsx,js,jsx,mdx}\" --cache",
    "format:write": "prettier --write \"**/*.{ts,tsx,js,jsx,mdx}\" --cache",

    "check": "next lint && tsc --noEmit",

    "postinstall": "prisma generate"
  },
  "prisma": {
    "seed": "ts-node --transpile-only prisma/seed.ts"
  },
```

---

## 6. Migración inicial

Se ejecutó:

```powershell
pnpm.cmd prisma migrate dev --name init --create-only
pnpm.cmd prisma generate
```

Resultado:

* Carpeta `prisma/migrations/..._init/` creada (SQL versionado).
* Prisma Client generado.
* Estado: **migración pendiente de aplicar**.

---

## 7. Smoke test

```powershell
pnpm.cmd dev
```

✔ Proyecto corriendo en `http://localhost:3000`.
⚠ Se agregaron variables dummy para evitar error de validación (`AUTH_DISCORD_ID` / `AUTH_DISCORD_SECRET`).

---

## ✅ Estado al finalizar Fase 1

* Proyecto T3 creado y funcionando.
* PostgreSQL corriendo en Docker (`pg16-sigecovip`).
* `.env` listo con DB, NextAuth y placeholders.
* Modelo de datos implementado en `schema.prisma` según el diseño.
* Migración inicial versionada (sin aplicar aún).
* Prisma Client generado.
* Scripts de migración y seed listos.
* Validación de arranque (`pnpm dev`) exitosa.

---
