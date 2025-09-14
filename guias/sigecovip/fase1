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
DATABASE_URL="postgresql://sigeco:sigeco_pass@localhost:5432/sigecovip?schema=public"
NEXTAUTH_URL="http://localhost:3000"
NEXTAUTH_SECRET="dev-secret-change-me"
JWT_SIGNING_KEY="dev-jwt-secret-change-me"

# Tokens externos (se añadirán más adelante)
NEXT_PUBLIC_MAPBOX_TOKEN=
FIREBASE_ADMIN_PROJECT_ID=
FIREBASE_ADMIN_CLIENT_EMAIL=
FIREBASE_ADMIN_PRIVATE_KEY=""
```

> Desde esta fase se prepara la compatibilidad con **Mapbox** y **Firebase/Auth**, como se definió en el EVS y el diseño.

---

## 3. Prisma centrado en migraciones

En `prisma/schema.prisma` confirma:

```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}
```

Deja el schema vacío o con una tabla mínima (`Usuario`) para crear la primera migración.
Esto permitirá versionar el esquema desde el inicio, como pide la metodología.

---

## 4. Scripts de migración en `package.json`

Asegúrate de tener:

```json
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
