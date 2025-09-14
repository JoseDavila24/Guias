# Fase 1 — Creación del proyecto SIGECOVIP con Create-T3-App (orientada a migraciones)

**Objetivo:** generar el proyecto base `sigecovip` con el stack aprobado (Create-T3-App + PostgreSQL en Docker + Prisma + tRPC + NextAuth.js), dejando lista la **infraestructura de migraciones versionadas** para las entidades: `Usuario`, `Comerciante`, `Inspección`, `Reporte`, `Auditoría`.

---

## 1) Scaffold del proyecto

En `C:\Dev`:

```powershell
cd C:\Dev
pnpm.cmd dlx create-t3-app@latest sigecovip
```

Selecciona:

* TypeScript: **Sí**
* Tailwind CSS: **Sí**
* tRPC: **Sí**
* Auth provider: **NextAuth.js**
* ORM: **Prisma**
* App Router: **Sí**
* DB provider: **PostgreSQL**
* Lint/Format: **ESLint + Prettier**
* Init Git: **Sí**
* Run pnpm install: **Sí**
* Import alias: **@/**

---

## 2) Variables de entorno

Crea/edita `.env` en la raíz:

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
AUTH_DISCORD_ID=""
AUTH_DISCORD_SECRET=""

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

> Mantén `.env` fuera de Git. Crea un `.env.example` sin credenciales.

---

## 3) Modelo de datos (Prisma centrado en migraciones)

`prisma/schema.prisma`:

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

> En fases siguientes podemos endurecer con enums para `formato/accion/modulo`, `onDelete` e índices.

---

## 4) Scripts en `package.json` (migraciones versionadas)

Asegura esta sección:

```json
{
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
  }
}
```

> Nota: Prisma avisa que `package.json#prisma` será deprecado en Prisma 7. Más adelante podemos mover el seed a `prisma.config.ts`. No te bloquea hoy.

---

## 5) Base de datos en Docker

```powershell
docker run --name pg16-sigecovip `
  -e POSTGRES_USER=sigeco `
  -e POSTGRES_PASSWORD=sigeco_pass `
  -e POSTGRES_DB=sigecovip `
  -p 5432:5432 -d postgres:16

docker ps   # contenedor Up
```

Tu `.env` ya apunta a:

```
DATABASE_URL="postgresql://sigeco:sigeco_pass@localhost:5432/sigecovip?schema=public"
```

---

## 6) Migración inicial (creada, aún no aplicada)

Con Postgres arriba:

```powershell
pnpm.cmd prisma migrate dev --name init --create-only
pnpm.cmd prisma generate
pnpm.cmd prisma migrate status   # debe mostrar 'init' como pending
```

Se crea `prisma/migrations/<timestamp>_init/migration.sql` y se genera Prisma Client.
La migración queda **pendiente** para aplicar en Fase 2.

---

## 7) Smoke test del proyecto

```powershell
pnpm.cmd dev
```

Abre `http://localhost:3000` y verifica el scaffold.

---

## 8) Checklist de cierre (Fase 1)

* [x] Proyecto T3 creado (Next.js + TS + Tailwind + tRPC + Auth.js + Prisma).
* [x] `.env` configurado (AUTH\_SECRET, DATABASE\_URL y placeholders externos).
* [x] Docker Postgres 16 **Up** en `localhost:5432`.
* [x] Migración inicial **creada** (`--create-only`), **no aplicada**.
* [x] Prisma Client generado; scripts de migración **sin `db push`**.
* [x] Commit de `prisma/schema.prisma` y `prisma/migrations/**` (sin `.env`).

---

### Notas (para siguientes fases)

* **Aplicar migraciones** en Fase 2: `pnpm prisma:migrate:deploy` y abrir `pnpm prisma:studio`.
* Opcional: mover seed a `prisma.config.ts` (quita el warning para Prisma 7).
* Endurecer el modelo con enums/índices/`onDelete` cuando fijemos reglas de negocio definitivas.

Listo. Esta es tu **Fase 1 oficial**, considerando que **ya levantaste Postgres** y que **ajustaste el `.env`** antes de crear la migración.
