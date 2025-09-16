# Fase 1 — Inicialización del proyecto (a prueba de fallas)

## 1) Objetivo y resultados esperados

Dejar un proyecto **Create-T3-App** funcionando con:

* Git inicializado localmente (lo hace el CLI del T3).
* PostgreSQL 16 en Docker, **versión fijada** (evita “latest”).&#x20;
* Variables de entorno correctas (**.env** local y **.env.example** versionado sin secretos).&#x20;
* Prisma listo (migraciones aplicadas).
* NextAuth operativo (secret configurado).
* tRPC con un healthcheck.
* Calidad de código (ESLint/Prettier) + **Husky** pre-commit.
* CI de GitHub Actions con **Postgres de servicio** y **env** mínimos definidos.

> Reusa lo que dejaste en **Fase 0**: uso de wrappers `.cmd`, pinning de versiones, WSL2 + Docker, y el **`.env.example` obligatorio**.  &#x20;

---

## 2) Crear el proyecto base (Git ya viene inicializado)

En **PowerShell**:

```powershell
cd D:\Dev
pnpm.cmd dlx create-t3-app@latest sigecovip
```

Selecciona exactamente:

* TypeScript ✅  Tailwind ✅  tRPC ✅
* NextAuth.js ✅  Prisma ✅  App Router ✅
* PostgreSQL ✅  ESLint + Prettier ✅
* Init Git ✅  Run pnpm install ✅
* Import alias: @/ ✅

> Tip Windows: usa `pnpm.cmd`/`npm.cmd` para evitar bloqueos de ejecución.&#x20;

---

## 3) PostgreSQL 16 en Docker (local)

**Fija versión** por compatibilidad:

```powershell
docker pull postgres:16
docker run --name pg-sigecovip -e POSTGRES_PASSWORD=postgres -e POSTGRES_USER=postgres -e POSTGRES_DB=sigecovip -p 5432:5432 -d postgres:16
```

Verifica:

```powershell
docker ps -a
```

> Recomendado en tu Fase 0: pinning a **postgres:16**, no `latest`.&#x20;

---

## 4) Variables de entorno (.env y .env.example)

En la raíz del proyecto `sigecovip/`:

**.env** (local, NO versionar):

```
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/sigecovip?schema=public"
NEXTAUTH_URL="http://localhost:3000"
NEXTAUTH_SECRET="cambia-esto-por-un-valor-largo-y-seguro"

# Integraciones (no obligatorias en CI; sí en prod cuando las uses)
# MAPBOX_API_KEY=""
# FIREBASE_AUTH_URL=""
# FIREBASE_PROJECT_ID=""
# FIREBASE_CLIENT_EMAIL=""
# FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"

NODE_ENV="development"
```

**.env.example** (SÍ versionar, sin secretos):

```
DATABASE_URL="postgresql://USER:PASSWORD@HOST:PORT/DB?schema=public"
NEXTAUTH_URL=""
NEXTAUTH_SECRET=""

# MAPBOX_API_KEY=""
# FIREBASE_AUTH_URL=""
# FIREBASE_PROJECT_ID=""
# FIREBASE_CLIENT_EMAIL=""
# FIREBASE_PRIVATE_KEY="" # con saltos \n escapados

NODE_ENV="development"
```

> Mantener **`.env.example`** desde Fase 0 es requisito y buena práctica de seguridad/compatibilidad.&#x20;

---

## 5) Prisma — esquema inicial seguro para NextAuth

Usa el modelo **oficial** de NextAuth con Prisma (User/Account/Session/VerificationToken) y añade tus entidades de dominio. Abre `prisma/schema.prisma` y usa algo como:

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
  id            String   @id @default(uuid())
  nombre        String
  email         String   @unique
  hashPassword  String
  rol           RolUsuario
  creadoEn      DateTime @default(now())
  actualizadoEn DateTime @updatedAt

  inspecciones  Inspeccion[] @relation("InspectorInspecciones")
  reportes      Reporte[]    @relation("AutorReportes")
  auditorias    Auditoria[]  @relation("AutorAuditorias")
}

model Comerciante {
  id               String            @id @default(uuid())
  titularNombre    String
  giro             String
  superficieM2     Decimal
  diasOperacion    String
  horarioOperacion String
  tipoMontaje      String
  licenciaPermiso  String?
  direccion        String
  latitud          Decimal           @db.Decimal(9,6)
  longitud         Decimal           @db.Decimal(9,6)
  organizacion     String?
  estatus          EstatusOperativo
  fotos            Json?             // Arreglo de URLs
  documentos       Json?             // Arreglo de URLs
  creadoEn         DateTime          @default(now())
  actualizadoEn    DateTime          @updatedAt

  inspecciones     Inspeccion[]
  reportesIncluidos ReporteComerciante[]
}

model Inspeccion {
  id            String    @id @default(uuid())
  fechaHora     DateTime  @default(now())
  notas         String
  evidencias    Json?     // Arreglo de URLs
  comercianteId String
  inspectorId   String

  comerciante   Comerciante @relation(fields: [comercianteId], references: [id])
  inspector     Usuario     @relation("InspectorInspecciones", fields: [inspectorId], references: [id])

  creadoEn      DateTime @default(now())
}

model Reporte {
  id              String              @id @default(uuid())
  tipo            String
  rangoFechas     String
  formato         String              // "PDF" | "Excel" | "CSV"
  fechaGeneracion DateTime            @default(now())
  autorId         String

  autor           Usuario             @relation("AutorReportes", fields: [autorId], references: [id])
  incluye         ReporteComerciante[]

  creadoEn        DateTime            @default(now())
}

model ReporteComerciante {
  id           String      @id @default(uuid())
  reporteId    String
  comercianteId String

  reporte      Reporte     @relation(fields: [reporteId], references: [id])
  comerciante  Comerciante @relation(fields: [comercianteId], references: [id])

  @@unique([reporteId, comercianteId])
}

model Auditoria {
  id         String   @id @default(uuid())
  usuarioId  String
  accion     String   // "alta" | "baja" | "modificacion" | "login" | "reporte"
  modulo     String   // "comerciante" | "inspeccion" | "reporte" | "usuario"
  fechaHora  DateTime @default(now())
  detalle    String?

  autor      Usuario  @relation("AutorAuditorias", fields: [usuarioId], references: [id])
}
```

Ejecuta:

```powershell
pnpm.cmd prisma generate
pnpm.cmd prisma migrate dev --name init
```

---

## 6) NextAuth — mínimo funcional

* Añade **PrismaAdapter** (usa el User del esquema anterior).
* Para desarrollo rápido, puedes usar un **Credentials Provider** (o el que te ofrezca el T3 por defecto) y fijar `NEXTAUTH_SECRET` en `.env`.

> Mantén los secretos fuera del repo — documenta en `.env.example`.&#x20;

---

## 7) tRPC — healthcheck y protección por rol (mínimo)

Crea un router `healthcheck` que devuelva `{ ok: true, time: ... }` y uno `me` que lea sesión/rol. Esto te sirve como **pruebas de humo** antes de exponer CRUD.

---

## 8) Calidad local — ESLint/Prettier + Husky

```powershell
pnpm.cmd add -D husky lint-staged
pnpm.cmd dlx husky-init && pnpm.cmd install
```

`package.json`:

```json
{ "lint-staged": { "*.{ts,tsx,js,jsx}": ["eslint --fix", "prettier --write"] } }
```

`.husky/pre-commit`:

```bash
pnpm lint-staged
```

> Esto no rompe CI; solo mejora la calidad al hacer commit.

---

## 9) CI — GitHub Actions listo y sin “Invalid environment variables”

Crea `.github/workflows/ci.yml`:

```yaml
name: CI
on:
  pull_request:
  push:
    branches: [main]

jobs:
  ci:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:16
        ports: ["5432:5432"]
        env:
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: sigecovip
        options: >-
          --health-cmd="pg_isready -U postgres -d sigecovip"
          --health-interval=10s
          --health-timeout=5s
          --health-retries=5

    env:
      CI: "true"
      DATABASE_URL: postgresql://postgres:postgres@localhost:5432/sigecovip?schema=public
      NEXTAUTH_URL: "http://localhost:3000"
      NEXTAUTH_SECRET: ${{ secrets.NEXTAUTH_SECRET }}
      # Integraciones: agrégalas cuando las uses
      # MAPBOX_API_KEY: ${{ secrets.MAPBOX_API_KEY }}
      # FIREBASE_AUTH_URL: ${{ secrets.FIREBASE_AUTH_URL }}
      # FIREBASE_PROJECT_ID: ${{ secrets.FIREBASE_PROJECT_ID }}
      # FIREBASE_CLIENT_EMAIL: ${{ secrets.FIREBASE_CLIENT_EMAIL }}
      # FIREBASE_PRIVATE_KEY: ${{ secrets.FIREBASE_PRIVATE_KEY }} # con \n escapados

    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v3
        with: { version: 9 }
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'pnpm'
      - run: pnpm install --frozen-lockfile
      - run: pnpm prisma generate
      - run: pnpm prisma migrate deploy
      - run: pnpm lint
      - run: pnpm build
      # - run: pnpm test -- --ci
```

> Claves: **Postgres:16** (pinning) y **.env mínimos** para que el esquema de entorno no falle en CI.&#x20;

---

## 10) (Opcional, pero recomendado) `src/env.ts` robusto

Patrón con `@t3-oss/env-nextjs` + `zod` que **exige** DB/NextAuth siempre, y permite dejar **opcionales en CI** las integraciones externas:

```ts
// src/env.ts
import { createEnv } from "@t3-oss/env-nextjs";
import { z } from "zod";

const isCI = process.env.CI === "true";
const optInCI = (schema: z.ZodTypeAny) => (isCI ? schema.optional().default("") : schema);

export const env = createEnv({
  server: {
    DATABASE_URL: z.string().url(),
    NEXTAUTH_URL: z.string().url(),
    NEXTAUTH_SECRET: z.string().min(32),

    MAPBOX_API_KEY: optInCI(z.string().min(1)),
    FIREBASE_AUTH_URL: optInCI(z.string().url()),
    FIREBASE_PROJECT_ID: optInCI(z.string().min(1)),
    FIREBASE_CLIENT_EMAIL: optInCI(z.string().email()),
    FIREBASE_PRIVATE_KEY: optInCI(z.string().min(1)),

    NODE_ENV: z.enum(["development","test","production"]).default("development"),
  },
  client: {},
  runtimeEnv: process.env,
  emptyStringAsUndefined: true,
});
```

---

## 11) Publicar el repositorio remoto

Si usas GitHub CLI:

```powershell
cd D:\Dev\sigecovip
gh repo create sigecovip --public --source=. --remote=origin --push
```

(Sin `gh`: `git remote add origin ...`, `git push -u origin main`)

---

## 12) Pruebas de humo locales

1. **Conexión DB:**

   ```powershell
   pnpm.cmd prisma migrate dev --name smoke
   pnpm.cmd prisma studio
   ```
2. **Arranque app:**

   ```powershell
   pnpm.cmd dev
   ```

   Abre `http://localhost:3000` y prueba un endpoint tRPC `healthcheck`.

---

# Matriz de errores típicos y solución

| Error                                                   | Causa probable                                                          | Solución                                                                                                     |
| ------------------------------------------------------- | ----------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| `@t3-oss/env-core: Invalid environment variables` en CI | Faltan `DATABASE_URL`, `NEXTAUTH_URL` o `NEXTAUTH_SECRET` en **ci.yml** | Añade `env:` en workflow como arriba y define `NEXTAUTH_SECRET` en **GitHub Secrets**                        |
| `P1001: Can't reach database server`                    | Contenedor Postgres no levantó / puerto ocupado                         | Revisa `services.postgres` en CI; local: `docker ps -a`, reinicia contenedor, verifica puerto **5432** libre |
| `FIREBASE_PRIVATE_KEY` inválida                         | Saltos de línea pegados sin `\n`                                        | En **Secrets**, pega la key con líneas como `\n`; ejemplo del `.env`                                         |
| `Command not found` con pnpm/npm                        | Política de ejecución / PATH en Windows                                 | Usa **wrappers** `pnpm.cmd/npm.cmd` o ajusta policy (RemoteSigned/Process Bypass)                            |
| “latest” de Postgres rompe migraciones                  | Cambios de imagen                                                       | **Pin** `postgres:16` (local y en CI)                                                                        |
| Problemas de CRLF en hooks                              | EOL distintos                                                           | Configura `core.autocrlf input` y **Prettier** como en Fase 0                                                |

---

## Checklist de salida (marca antes de avanzar a Fase 2)

* [ ] Proyecto creado con T3 y **Git** local ok.
* [ ] **Postgres 16** corriendo (Docker).&#x20;
* [ ] `.env` local y **`.env.example`** versionado (sin secretos).&#x20;
* [ ] Prisma `generate` + `migrate` aplicadas.
* [ ] NextAuth configurado con **PrismaAdapter** y `NEXTAUTH_SECRET`.
* [ ] tRPC `healthcheck` responde.
* [ ] Husky + lint-staged operando.
* [ ] CI de GitHub Actions: **verde** (servicio Postgres + env mínimos).
* [ ] Primer push al repo remoto.
