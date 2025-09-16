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
