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

---

## 3. Variables de entorno

* Archivo `.env` configurado con:

  * **NextAuth** (`AUTH_SECRET`, `NEXTAUTH_URL`).
  * **Tokens externos** (Mapbox, Firebase/Auth, en blanco si no se usan aún).
  * **DATABASE\_URL** con la conexión a PostgreSQL productivo (no de prueba).

* Se mantiene un `.env.example` sin credenciales, para cumplir RNF-04 (seguridad de datos).

---

## 4. Modelo de datos (Prisma)

📌 *Aquí pegas el bloque de código del `schema.prisma` con todas las entidades (`Usuario`, `Comerciante`, `Inspección`, `Reporte`, `Auditoría`).*

✅ Este modelo corresponde directamente a los requisitos del ERS:

* RF-02 (CRUD Comerciantes) → `Comerciante`.
* RF-06 (Inspecciones) → `Inspección`.
* RF-07 (Reportes) → `Reporte` y `ReporteComerciante`.
* RF-08 (Auditoría) → `Auditoría`.

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
