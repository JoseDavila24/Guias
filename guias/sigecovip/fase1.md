# Fase 1 — Creación del proyecto SIGECOVIP con Create-T3-App

**Objetivo:** generar el proyecto base `sigecovip` con el stack aprobado (Create-T3-App + PostgreSQL en Docker + Prisma + tRPC + NextAuth.js), dejando lista la **infraestructura de migraciones** para soportar las entidades definidas en el diseño: `Usuario`, `Comerciante`, `Inspección`, `Reporte`, `Auditoría`.

---

## 1. Scaffold inicial

En tu carpeta de trabajo (`C:\Dev\sigecovip`):

```powershell
cd C:\Dev
pnpm.cmd dlx create-t3-app@latest sigecovip
```

Selecciona exactamente:

* **TypeScript**: Sí
* **Tailwind CSS**: Sí
* **tRPC**: Sí
* **Auth provider**: NextAuth.js
* **ORM**: Prisma
* **App Router**: Sí
* **DB provider**: PostgreSQL
* **Lint/Format**: ESLint + Prettier
* **Init Git**: Sí
* **Run pnpm install**: Sí
* **Import alias**: @/

---

## 2. Variables de entorno iniciales

Crea un archivo `.env` en la raíz:

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

> Desde esta fase se prepara la compatibilidad con **Mapbox** y **Firebase/Auth**, como se definió en el EVS y el diseño.

---

## 3. Prisma centrado en migraciones

En `prisma/schema.prisma` pega lo siguiente:

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

## 4. Scripts de migración en `package.json`

```json
{
  "name": "sigecovip",
  "version": "0.1.0",
  "private": true,
  "type": "module",
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
  "dependencies": {
    "@auth/prisma-adapter": "^2.7.2",
    "@prisma/client": "^6.5.0",
    "@t3-oss/env-nextjs": "^0.12.0",
    "@tanstack/react-query": "^5.69.0",
    "@trpc/client": "^11.0.0",
    "@trpc/react-query": "^11.0.0",
    "@trpc/server": "^11.0.0",
    "next": "^15.2.3",
    "next-auth": "5.0.0-beta.25",
    "react": "^19.0.0",
    "react-dom": "^19.0.0",
    "server-only": "^0.0.1",
    "superjson": "^2.2.1",
    "zod": "^3.24.2"
  },
  "devDependencies": {
    "@eslint/eslintrc": "^3.3.1",
    "@tailwindcss/postcss": "^4.0.15",
    "@types/node": "^20.14.10",
    "@types/react": "^19.0.0",
    "@types/react-dom": "^19.0.0",
    "eslint": "^9.23.0",
    "eslint-config-next": "^15.2.3",
    "postcss": "^8.5.3",
    "prettier": "^3.5.3",
    "prettier-plugin-tailwindcss": "^0.6.11",
    "prisma": "^6.5.0",
    "tailwindcss": "^4.0.15",
    "typescript": "^5.8.2",
    "typescript-eslint": "^8.27.0"
  },
  "ct3aMetadata": {
    "initVersion": "7.39.3"
  },
  "packageManager": "pnpm@10.15.1"
}
```

---

## 5. Migración inicial (sin aplicar aún)

```powershell
pnpm.cmd prisma migrate dev --name init --create-only
pnpm.cmd prisma generate
```

Esto crea `/prisma/migrations/YYYYMMDDHHMMSS_init/` con SQL versionado, sin necesidad de que PostgreSQL esté corriendo todavía.

---

## 6. Smoke test del proyecto

```powershell
pnpm.cmd dev
```

Abre `http://localhost:3000` y valida que la app arranca correctamente.

---

## 7. Validaciones técnicas

* **Lint**

  ```powershell
  pnpm.cmd lint
  ```

* **Prisma Client**

  ```powershell
  pnpm.cmd prisma generate
  ```

* **Studio (cuando DB esté arriba, fase 2):**

  ```powershell
  pnpm.cmd prisma studio
  ```

---

## 8. Estado al finalizar Fase 1

✔ Proyecto T3 creado con Next.js + Tailwind + tRPC + Auth.js + Prisma.
✔ Migración inicial versionada (`--create-only`).
✔ `.env` preparado con soporte a **PostgreSQL, Mapbox y Firebase/Auth**.
✔ Scripts listos para `migrate dev` (local) y `migrate deploy` (CI/producción).
✔ Proyecto en Git listo para integrarse con GitHub Actions (CI/CD).

---

### Notas clave

* No se debe usar `db push`; todas las modificaciones se gestionan con **migraciones** versionadas.
* El esquema reflejará las entidades principales: **Usuario, Comerciante, Inspección, Reporte, Auditoría**.
* Esta fase cumple con lo estipulado en:

  * **Project Charter** (stack: Create-T3-App + PostgreSQL + Docker)
  * **EVS** (Alternativa C híbrida, pinning de versiones y resiliencia con servicios externos)
  * **ERS-830** (RF-01 a RF-08 y RNF-06 compatibilidad tecnológica)
  * **Especificación de diseño** (clases y modelo relacional base)

---
