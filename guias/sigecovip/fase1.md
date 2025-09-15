# Fase 1 — Inicialización del proyecto (Create-T3-App)

## 1) Crear el proyecto base (con Git inicializado)

En PowerShell (Windows), dentro de tu carpeta de trabajo (p. ej. `D:\Dev`):

```powershell
cd D:\Dev
pnpm.cmd dlx create-t3-app@latest sigecovip
```

Selecciona exactamente lo que indicaste:

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

> Esto deja el repo **local** con Git ya inicializado, conforme al stack definido en ERS/Charter.

## 2) Configurar la base de datos local (Docker + PostgreSQL 16)

Usa la versión fijada para evitar “latest” (pinning) que definiste en Fase 0:

```powershell
docker pull postgres:16
docker run --name pg-sigecovip -e POSTGRES_PASSWORD=postgres -e POSTGRES_USER=postgres -e POSTGRES_DB=sigecovip -p 5432:5432 -d postgres:16
```

## 3) Variables de entorno

En la raíz del proyecto `sigecovip/`, crea **`.env`** (solo local) y **`.env.example`** (sin secretos, para versionar).

**`.env` (local, NO subir a Git):**

```
# DB
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/sigecovip?schema=public"

# NextAuth
NEXTAUTH_URL="http://localhost:3000"
NEXTAUTH_SECRET="cambia-esto-por-un-valor-seguro"

# Mapas (a futuro)
# MAPBOX_TOKEN=""

# Firebase (a futuro, según EVS/ERS)
# FIREBASE_PROJECT_ID=""
# FIREBASE_CLIENT_EMAIL=""
# FIREBASE_PRIVATE_KEY=""

# App
NODE_ENV="development"
```

**`.env.example` (versionar):**

```
DATABASE_URL="postgresql://USER:PASSWORD@HOST:PORT/DB?schema=public"
NEXTAUTH_URL=""
NEXTAUTH_SECRET=""
# MAPBOX_TOKEN=""
# FIREBASE_PROJECT_ID=""
# FIREBASE_CLIENT_EMAIL=""
# FIREBASE_PRIVATE_KEY=""
NODE_ENV="development"
```

## 4) Esquema inicial con Prisma (alineado al diseño)

Basado en tu **Especificación de diseño** (clases Usuario, Comerciante, Inspección, Reporte, Auditoría):

Abre `prisma/schema.prisma` y ajusta:

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

Aplica migraciones:

```powershell
pnpm.cmd prisma migrate dev --name init
```

> Este modelo refleja 1) RF/RNF del ERS/Charter y 2) la traza/auditoría que pediste.

## 5) NextAuth.js (Auth provider seleccionado)

Configura NextAuth con **Prisma Adapter** para almacenar usuarios/sesiones en tu DB. Crea `src/server/auth.ts` (o según estructura de create-t3-app) y define un proveedor básico (p. ej., **Credentials** para desarrollo\*\*). Más adelante podrás migrar a Google/Microsoft o integrar **Firebase como IdP**; por ahora mantenemos NextAuth como capa de autenticación (cumple ERS) y dejamos **Firebase** listo para servicios futuros (storage, hosting, FCM) tal como prevés en EVS/ERS.

> Nota: mantener NextAuth ahora no impide **futuro** uso de Firebase (Auth como IdP SAML/OIDC o solo otros servicios). La elección de NextAuth está alineada con el stack T3 inicial y tus documentos; el “mirar a la nube” con Firebase queda apuntalado para siguientes fases (véase sección “Mirando a Firebase” al final).

## 6) Endpoints tRPC base

* Asegura un **router** inicial: `appRouter` con `healthcheck` y `me` (lee sesión).
* Protege routers con middleware por **rol** (INSPECTOR/COORDINADOR) antes de exponer CRUD sensibles (requisito RF-01 de control de acceso).

## 7) Linting, formateo y hooks

Aunque el CLI ya incluye **ESLint + Prettier**, añade **Husky** + **lint-staged** para validar antes de cada commit:

```powershell
pnpm.cmd add -D husky lint-staged
pnpm.cmd dlx husky-init && pnpm.cmd install
```

En `package.json`:

```json
{
  "lint-staged": {
    "*.{ts,tsx,js,jsx}": ["eslint --fix", "prettier --write"]
  }
}
```

Edita `.husky/pre-commit` para correr lint-staged:

```bash
pnpm lint-staged
```

> Refuerza calidad y consistencia, alineado a tu énfasis en documentación y QA del ERS/Charter.

## 8) GitHub Actions (CI mínimo)

Crea `.github/workflows/ci.yml` para lint + build + prisma generate:

```yaml
name: CI
on:
  pull_request:
  push:
    branches: [main]
jobs:
  ci:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v3
        with:
          version: 9
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'pnpm'
      - run: pnpm install --frozen-lockfile
      - run: pnpm prisma generate
      - run: pnpm lint
      - run: pnpm build
```

> Esto cubre “reproducibilidad y versionado” y prepara el camino para pruebas automatizadas ≥60% en fases posteriores, tal como pides en ERS/Charter.

## 9) Crear el repositorio **remoto** (después del proyecto)

Como **ya iniciaste Git** al crear el proyecto, ahora sí toca crear el repo en GitHub y subir:

```powershell
cd D:\Dev\sigecovip
gh repo create sigecovip --public --source=. --remote=origin --push
```

Si no usas `gh`, hazlo a mano:

```powershell
git remote add origin https://github.com/<tu_usuario>/sigecovip.git
git add .
git commit -m "chore: bootstrap SIGECOVIP with T3 stack"
git push -u origin main
```

> Orden correcto según tu indicación: **primero** crear el proyecto con Git local, **luego** crear/push del repo remoto.

## 10) Arranque local de verificación

```powershell
pnpm.cmd dev
```

* Abre `http://localhost:3000`.
* Ejecuta un flujo básico: registrarte (si usas Credentials para dev), probar `healthcheck`, y verificar conexión DB (`pnpm prisma studio`).

---

## Mirando a Firebase (como solicitaste)

Tus documentos contemplan **servicios en la nube** y **modularidad** (Mapbox, Firebase) con control de datos propios. Te propongo este plan sin romper el stack T3:

1. **Corto plazo (dev/piloto):**

   * Mantén **NextAuth** con Prisma (rápido y nativo al T3).
   * Usa Firebase **solo** para servicios no críticos: Storage (evidencias), mensajería (FCM), o analítica.

2. **Mediano plazo (post-piloto):**

   * Evaluar **Firebase como IdP** (OIDC/SAML) integrado a NextAuth (Provider personalizado) o migración selectiva.
   * Mantener **PostgreSQL** como **fuente de verdad** (cumple tus RNF normativos y de soberanía de datos).

3. **Backups y exportaciones:**

   * Exporta evidencias a Storage, pero conserva **metadatos** en PostgreSQL (trazabilidad/auditoría).

---

## Checklist de salida de Fase 1

* [ ] Proyecto creado con **Create-T3-App** y Git inicializado (local).
* [ ] PostgreSQL 16 en Docker corriendo (DB `sigecovip`).
* [ ] `.env` configurado y **`.env.example` versionado** (sin secretos).
* [ ] `prisma/schema.prisma` definido (Usuario, Comerciante, Inspeccion, Reporte, Auditoria) y **migración aplicada**.
* [ ] NextAuth configurado con Prisma Adapter (Credentials para dev).
* [ ] Routers tRPC base + middleware de **roles**.
* [ ] ESLint/Prettier + **Husky** + **lint-staged**.
* [ ] GitHub Actions (lint/build/prisma).
* [ ] Repo **remoto** creado y **primer push**.
* [ ] App arranca local (`pnpm dev`) y conecta a DB.
