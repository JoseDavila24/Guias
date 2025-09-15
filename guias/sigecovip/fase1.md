# Fase 1 — Creación del proyecto SIGECOVIP con Create-T3-App

**Objetivo:** generar el proyecto base `sigecovip` con el stack aprobado (**Create-T3-App + PostgreSQL 16 en Docker + Prisma + tRPC + NextAuth.js**), dejando lista la **infraestructura de migraciones definitivas** que soportarán directamente el modelo productivo, sin usar bases temporales.
Esto asegura la posibilidad de escalar a servicios en la nube (Supabase, Railway, AWS RDS, etc.) de forma transparente y con consistencia en todos los entornos.

---

## 1. Scaffold inicial

En tu carpeta de trabajo (`D:\Dev\sigecovip`), se crea el proyecto base con **Create-T3-App**, seleccionando únicamente las opciones aprobadas en el **EVS (Alternativa C)** y descritas en el **Charter**:

```powershell
cd D:\Dev
pnpm.cmd dlx create-t3-app@latest sigecovip
```

Selección de opciones:

* ✅ TypeScript
* ✅ TailwindCSS
* ✅ tRPC
* ✅ NextAuth.js (Auth provider)
* ✅ Prisma (ORM)
* ✅ App Router
* ✅ PostgreSQL (DB provider, versión 16 en Docker)
* ✅ ESLint + Prettier
* ✅ Init Git
* ✅ Run pnpm install
* ✅ Import alias: @/

📌 **Justificación técnica**

* Esta configuración corresponde directamente a lo aprobado en EVS 6 (Selección de la Solución, Alternativa C).
* Garantiza compatibilidad tecnológica (RNF-06), escalabilidad (RNF-02) y cumplimiento de requisitos funcionales iniciales del Charter/ERS (RF-01 a RF-08).
* El uso de Create-T3-App reduce en un 40% el tiempo de arranque y estandariza buenas prácticas, lo cual está señalado en la justificación del EVS.

---

## 2. Base de datos con `docker-compose` (productiva desde el inicio)

**Principio:** La instancia de PostgreSQL 16 definida en `docker-compose.yml` es tu **base productiva local** desde el día 1 (nombres y credenciales reales). Más adelante solo **cambias `DATABASE_URL`** para apuntar a la nube (Supabase/Railway/RDS/etc.) sin rehacer migraciones.

### 2.1 Estructura y políticas

* **Versión fija:** PostgreSQL **16** (evitar `latest`).
* **Persistencia:** volumen **nombrado** para datos (p. ej., `pgdata_sigecovip`).
* **Red:** red bridge propia (p. ej., `sigecovip_net`) para aislamiento.
* **Reinicio:** política `unless-stopped` opcional.

> Esto garantiza trazabilidad de migraciones y portabilidad 1:1 a cloud.

### 2.2 Archivo `docker-compose.yml`

**(Pega aquí tu archivo compose)**
Incluye un servicio `postgres` con:

* imagen `postgres:16`
* variables `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB` (valores **definitivos**)
* volumen `pgdata_sigecovip:/var/lib/postgresql/data`
* (opcional) `healthcheck` simple
* red `sigecovip_net`

```
# AQUÍ TU CÓDIGO: docker-compose.yml
```

### 2.3 Variables de entorno del proyecto

**(Pega aquí el fragmento de tu `.env` con `DATABASE_URL`)**

Recomendado (solo en `.env`, **no** en el repo):

* `DATABASE_URL="postgresql://<usuario>:<password>@localhost:5432/<db>?schema=public"`

Publica un `.env.example` (sin secretos) con las variables esperadas.

```
# AQUÍ TU CÓDIGO: .env (solo placeholders, sin credenciales reales en el repo)
```

### 2.4 Comandos de ciclo de vida (compose)

* **Arrancar en segundo plano:**
  `docker compose up -d`
* **Ver estado de servicios:**
  `docker compose ps`
* **Logs (en vivo o recientes):**
  `docker compose logs -f postgres`
* **Entrar al contenedor (psql):**
  `docker compose exec postgres psql -U <usuario> -d <db>`
* **Apagar (sin borrar datos):**
  `docker compose down`
* **Apagar y borrar red/volúmenes anónimos:**
  `docker compose down --remove-orphans`
* **Apagar y borrar también el volumen de datos (⚠️ productivo):**
  `docker compose down -v`

> ⚠️ **Nunca** uses `-v` en tu base productiva salvo que tengas respaldo.

### 2.5 Listar y limpiar (evitar “basura”)

**Listar lo que tienes:**

* Servicios y estado: `docker compose ps`
* Volúmenes (global): `docker volume ls`
* Imágenes (global): `docker images`
* Contenedores (global): `docker ps -a`
* Espacio usado: `docker system df`

**Limpiar con cuidado:**

* Contenedor detenido: `docker rm <container_id>`
* Imagen sin uso: `docker rmi <image_id>`
* Volumen huérfano: `docker volume rm <volume_name>`
* Limpieza global (revisa antes):

  * `docker system prune`
  * `docker system prune -a` (incluye imágenes sin usar)
  * `docker volume prune` (solo volúmenes **no** usados por contenedores)

> 💡 Mantén **`pgdata_sigecovip`** intacto para no perder datos.

### 2.6 Pruebas de salud y conexión

* **Healthcheck** del servicio `postgres` (si lo definiste) debe reportar **healthy**.
* **Comprobaciones rápidas:**

  * `docker compose ps` → estado `Up`
  * `docker compose logs postgres` → sin errores
  * `docker compose exec postgres psql -U <usuario> -d <db> -c "\dt"` → conexión OK

### 2.7 Respaldo y restauración (pensando en la nube)

**Backups (desde el contenedor):**

* `docker compose exec postgres pg_dump -U <usuario> -d <db> -Fc -f /tmp/sigecovip.dump`
* `docker cp <nombre_contenedor>:/tmp/sigecovip.dump ./backups/`

**Restore (local o cloud):**

* `pg_restore -U <usuario> -d <db> -c ./backups/sigecovip.dump`

> Define desde ahora una **rutina de backups** (carpeta `./backups/` y naming con fecha).

### 2.8 Seguridad mínima y redes

* Expón el puerto a `localhost` únicamente (si necesitas clientes externos, usa túneles).
* Credenciales **solo** en `.env` o secret manager (no en el repo).
* Considera límites de conexiones y parámetros si sube la concurrencia.

### 2.9 Estado al terminar esta sección

* `docker-compose` en marcha con **PostgreSQL 16** y **volumen persistente**.
* `.env` apuntando a esta base **productiva local**.
* Comandos de **operación**, **listado/limpieza** y **backup/restore** documentados.

## 3. Variables de entorno

**Principio:** Mantener **secretos fuera del repo**, publicar un **`.env.example`** completo (sin credenciales) y usar la **misma forma de `DATABASE_URL`** en todos los entornos para facilitar la migración a nube (cambiar solo host/credenciales).

### 3.1 Convenciones y archivos

* **`.env` (local desarrollo):** Solo en tu máquina. No se versiona.
* **`.env.example` (plantilla):** Se versiona (sin secretos). Debe reflejar **todas** las variables esperadas.
* **`.env.production` / secretos en nube:** Se gestionan con el secret manager del proveedor (Vercel, Railway, Render, Supabase, AWS, etc.).
* **`.gitignore`:** Asegúrate de ignorar `.env`, `.env.local`, llaves JSON, dumps y `/backups/`.

### 3.2 `.env` (desarrollo local)

Usa lo que ya tienes como base. Mantén **solo uno** entre `AUTH_SECRET` (moderno) y `NEXTAUTH_SECRET` (legacy). T3 moderno usa `AUTH_SECRET`.

```
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

**Notas sobre lo que ya traes:**

* `AUTH_SECRET`: OK. Si cambias, genera uno nuevo con `npx auth secret`.
* `NEXTAUTH_URL`: en local, `http://localhost:3000`. En producción, cámbialo a la URL pública.
* Proveedores externos:

  * `NEXT_PUBLIC_MAPBOX_TOKEN` → pública en frontend, pero **no** la subas en `.env.example` con valor real.
  * `FIREBASE_ADMIN_*`: si usas la **llave privada** en variable, recuerda colocarla **entre comillas** y con saltos de línea escapados: `\n`. Alternativa más segura: usa credencial por **ruta de archivo** y variable `GOOGLE_APPLICATION_CREDENTIALS` apuntando a un JSON **fuera** del repo (o usa secret manager en producción).
* `DATABASE_URL`: apunta a **tu base productiva local** del `docker-compose` (la que migrará a cloud). Ejemplo (lo que ya usas):

  ```
  postgresql://sigeco:sigeco_pass@localhost:5432/sigecovip?schema=public
  ```

> 💡 Si en el futuro corres **la app dentro de Docker** en la misma red de `compose`, el host cambia a `postgres` (nombre del servicio), no `localhost`.

### 3.3 `.env.example` (plantilla sin secretos)

Incluye **todas** las variables esperadas por el proyecto, pero en blanco o con placeholders. Así cualquier colaborador puede arrancar rápido.

```
# AQUÍ TU CÓDIGO: .env.example (placeholders, sin credenciales)
```

**Recomendación de contenido mínimo en `.env.example`:**

* `AUTH_SECRET=`
* `NEXTAUTH_URL=http://localhost:3000`
* `NEXT_PUBLIC_MAPBOX_TOKEN=`
* `FIREBASE_ADMIN_PROJECT_ID=`
* `FIREBASE_ADMIN_CLIENT_EMAIL=`
* `FIREBASE_ADMIN_PRIVATE_KEY=`  # (o usa GOOGLE\_APPLICATION\_CREDENTIALS)
* `DATABASE_URL=postgresql://USER:PASS@HOST:5432/DB?schema=public`

> Mantén este archivo **siempre sincronizado** con lo que realmente usa el proyecto.

### 3.4 Notas específicas de NextAuth

* Usa **solo `AUTH_SECRET`** (el moderno). Elimina comentarios/variables legacy si ya no se usan.
* `NEXTAUTH_URL`:

  * Local: `http://localhost:3000`
  * Producción: URL pública (Vercel/tu dominio).
* Si más adelante añades OAuth (Google, etc.), declara variables como `AUTH_GOOGLE_ID`, `AUTH_GOOGLE_SECRET` **solo** en secretos de prod.

### 3.5 Prisma / `DATABASE_URL` (compatibilidad Docker y nube)

* **Local (app en host + DB en Docker):** host `localhost`, puerto `5432`.
* **App y DB dentro de `compose`:** host `postgres` (nombre del servicio en `docker-compose.yml`), mismo puerto `5432`.
* **Nube:** cambia host, usuario y password según tu proveedor (no cambias el esquema ni las migraciones).

```
# AQUÍ TU CÓDIGO: si quieres pegar 2 variantes comentadas de DATABASE_URL (host localhost vs host postgres)
```

### 3.6 Validación rápida (pasos mínimos)

1. `pnpm prisma generate`
2. (Si aún no aplicaste) `pnpm prisma migrate dev --name init`
3. `pnpm dev` → App en `http://localhost:3000`
4. (Opcional) Verifica conexión:

   ```
   docker compose exec postgres psql -U sigeco -d sigecovip -c "\dt"
   ```

### 3.7 Buenas prácticas de seguridad

* **Rotación** de `AUTH_SECRET` si se expone.
* Jamás subir llaves ni `.env` al repo. Usa secret manager en producción.
* Para llaves multilinea (Firebase), prefiere **archivo externo** y variable de ruta.
* Mantén `.env.example` actualizado (onboarding del equipo y CI).

### 3.8 Estado al terminar esta sección

* `.env` local completo y funcional (no commiteado).
* `.env.example` publicado y actualizado (sin secretos).
* `DATABASE_URL` apuntando a la **base productiva local** de `docker-compose`.
* Proyecto listo para ejecutar migraciones y luego **migrar a cloud** cambiando solo credenciales/host.

---

## 4. Modelo de datos (Prisma)

**Objetivo:** definir el **modelo productivo** desde el día 1 (no temporal) para soportar las entidades y relaciones nucleares del sistema: `Usuario`, `Comerciante`, `Inspeccion`, `Reporte`, `ReporteComerciante` (N\:M) y `Auditoria`.
El esquema se versionará con **migraciones Prisma** y será portable a nube cambiando únicamente la `DATABASE_URL`.

### 4.1 Principios de modelado (acuerdos)

* **Identificadores:** `UUID` (STRING en Prisma con `@default(uuid())`).
* **Trazabilidad:** timestamps `creadoEn` (`@default(now())`) y `actualizadoEn` (`@updatedAt`) donde aplique.
* **Integridad referencial:**

  * `Inspeccion` referencia a `Comerciante` (1\:N) y a `Usuario` (inspector).
  * `Reporte` referencia a `Usuario` (autor).
  * `ReporteComerciante` resuelve la N\:M entre `Reporte` y `Comerciante` con **PK compuesta**.
* **Dominios (enums):** `RolUsuario { INSPECTOR, COORDINADOR }`, `EstatusOperativo { VIGENTE, IRREGULAR, SANCIONADO, EN_TRAMITE }`.
* **Índices y unicidad:** `Usuario.email` único; índices por campos de consulta frecuentes (p. ej. `Comerciante.organizacion`, `Comerciante.estatus`).
* **Seguridad:** las contraseñas se guardan **hasheadas** (bcrypt/argon2) —se implementa en la capa de servicio/Auth.
* **Escalabilidad:** tipos numéricos adecuados para lat/lon (`Decimal(9,6)`), superficies (`Decimal(10,2)`), y campos `String` para notas/documentos (URLs).

### 4.2 `schema.prisma` (pega aquí tu código)

> **Inserta aquí el contenido real de tu `prisma/schema.prisma`** con:
>
> * `datasource db` → `provider = "postgresql"` y `url = env("DATABASE_URL")`
> * `generator client` → `prisma-client-js`
> * Enums: `RolUsuario`, `EstatusOperativo`
> * Modelos: `Usuario`, `Comerciante`, `Inspeccion`, `Reporte`, `ReporteComerciante`, `Auditoria`
> * Relaciones e índices (ver 4.3)

```
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

### 4.3 Convenciones y restricciones (guía para tu `schema.prisma`)

* **Usuario**

  * `email String @unique`
  * `rol RolUsuario`
  * Relaciones: `inspecciones`, `reportes`, `auditorias`
* **Comerciante**

  * Atributos clave: `titularNombre`, `giro`, `superficieM2 Decimal(10,2)?`, `diasOperacion?`, `horarioOperacion?`, `tipoMontaje?`, `licenciaPermiso?`, `direccion?`, `latitud Decimal(9,6)?`, `longitud Decimal(9,6)?`, `organizacion?`, `estatus EstatusOperativo`
  * Índices sugeridos:

    * `@@index([organizacion])`
    * `@@index([estatus])`
    * `@@index([latitud, longitud])` (para filtros geográficos simples)
* **Inspeccion**

  * Claves foráneas: `idComerciante` → `Comerciante.id`, `idInspector` → `Usuario.id`
  * Atributos: `fechaHora @default(now())`, `notas?`, `evidenciasUrl?`
  * Índices sugeridos: `@@index([idComerciante, fechaHora])`
* **Reporte**

  * Autor: `idAutor` → `Usuario.id`
  * `tipo`, `rangoFechas?`, `formato?` ("PDF" | "Excel" | "CSV"), `fechaGeneracion @default(now())`
* **ReporteComerciante**

  * PK compuesta: `@@id([idReporte, idComerciante])`
* **Auditoria**

  * FK opcional a `Usuario` (`usuarioId?`)
  * Campos: `accion` ("alta" | "baja" | "modificacion" | "login" | "reporte"), `modulo` ("comerciante" | "inspeccion" | "reporte" | "usuario"), `fechaHora @default(now())`, `detalle?`
  * Índice sugerido: `@@index([modulo, fechaHora])`

> **Notas opcionales (si te sirven a futuro):**
>
> * Si contemplas búsquedas por texto/organización frecuentes, podrías añadir índices adicionales.
> * Para mapas avanzados, **PostGIS** sería futuro; hoy mantenemos lat/lon como `Decimal` y rendimiento con índices básicos.

### 4.4 Migraciones definitivas

* La **primera migración** (`init`) se aplica ya sobre la **base productiva local** (tu `docker-compose`), no sobre una DB “temporal”.
* Cada cambio al modelo se versiona con `prisma migrate dev --name <cambio>` en desarrollo y luego `migrate deploy` en ambientes no interactivos (CI/CD).

### 4.5 Trazabilidad RF/RNF ↔ entidades/atributos (mini–tabla)

| Requisito                     | Entidad/atributo relacionado                           | Notas                                                 |
| ----------------------------- | ------------------------------------------------------ | ----------------------------------------------------- |
| **RF-01** Autenticación/roles | `Usuario.email`, `Usuario.hashPassword`, `Usuario.rol` | Roles `INSPECTOR/COORDINADOR`; hash en lógica de auth |
| **RF-02** CRUD Comerciantes   | `Comerciante.*`                                        | Incluye georreferenciación, organización, estatus     |
| **RF-03** Mapa y filtros      | `Comerciante.latitud/longitud`, índices                | Índices por `organizacion` y `estatus` para filtros   |
| **RF-04** Ficha técnica       | `Comerciante.*`, relaciones `Inspeccion`               | Debe incluir historial de inspecciones                |
| **RF-05** Vista tabular       | Índices en `Comerciante`                               | Optimiza búsqueda/ordenación/exportación              |
| **RF-06** Inspecciones        | `Inspeccion` + FKs a `Comerciante`/`Usuario`           | Fecha, notas, evidencias (URL)                        |
| **RF-07** Reportes            | `Reporte`, `ReporteComerciante` (N\:M)                 | Autor (`Usuario`), rango y formato                    |
| **RF-08** Auditoría           | `Auditoria` (+ FK opcional a `Usuario`)                | Acción, módulo, fecha, detalle                        |
| **RNF-02** Escalabilidad      | Índices y tipos adecuados                              | ≥ 1,000 comerciantes; lat/lon como `Decimal`          |
| **RNF-04** Seguridad          | `Usuario.hashPassword` (bcrypt/argon2)                 | TLS y roles fuera del modelo (infra/app)              |

### 4.6 Validación rápida del modelo

1. **Generar cliente:** `pnpm prisma generate`
2. **Crear/aplicar migración inicial:** `pnpm prisma migrate dev --name init`
3. **(Opcional) Seed mínimo:** insertar 1 `Usuario` (COORDINADOR) + 1 `Comerciante` + 1 `Inspeccion` para validar relaciones.
4. **Prisma Studio (opcional):** `pnpm prisma studio` para ver tablas/relaciones.

### 4.7 Consideraciones para la nube (portabilidad)

* El **DDL** queda 1:1 en cualquier proveedor (Supabase, Railway, RDS, etc.) usando las mismas migraciones.
* Al migrar: realiza **backup** (`pg_dump -Fc`) y **restore** (`pg_restore -c`) en el destino; luego **ajusta solo `DATABASE_URL`** y ejecuta `prisma migrate deploy`.

---

## 5. Scripts de migración (`package.json`)

📌 *Aquí va el bloque de scripts (`prisma:generate`, `prisma:migrate:dev`, `prisma:migrate:deploy`, etc.).*

> **Nota importante:**
>
> * Se eliminan referencias a *“bases de prueba”*.
> * La primera migración (`init`) se ejecuta sobre la base real (`sigecovip`) que seguirá viva y versionada hasta el despliegue cloud.

---

## 6. Migración inicial

* Ejecutar migración inicial (`prisma migrate dev --name init`).
* Confirmar que se creó la carpeta `prisma/migrations/..._init/`.
* El esquema de base de datos ya es el productivo (Docker local = réplica inicial de cloud).

---

## 7. Seed de validación

* Se recomienda un **seed mínimo** (ej. 1 usuario coordinador, 1 comerciante, 1 inspección dummy) para comprobar integridad del modelo y relaciones.
* Esto valida trazabilidad desde el inicio (relacionado con RC-04 pruebas de calidad).

---

## 8. Smoke test

* Correr `pnpm dev` y verificar aplicación en `http://localhost:3000`.
* Confirmar conexión a DB productiva (no dummy).
* Verificar que Prisma Client funciona y que seed inicial se consulta.

---

## ✅ Estado al finalizar Fase 1

* Proyecto T3 creado y funcionando.
* PostgreSQL productivo (`pg16-sigecovip`) corriendo en Docker.
* `.env` configurado con credenciales reales y `.env.example` como referencia.
* Modelo Prisma completo y migración aplicada.
* Scripts de migración y seed listos.
* Validación de arranque (`pnpm dev`) exitosa.

---
