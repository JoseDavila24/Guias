# Fase 1 — Inicialización “sin errores” (SIGECOVIP)

## 1) Crear proyecto base (Create-T3-App)

```powershell
cd D:\Dev
pnpm.cmd dlx create-t3-app@latest sigecovip
```

Selecciona: **TypeScript**, **Tailwind**, **tRPC**, **Prisma**, **App Router**, **PostgreSQL**, **ESLint+Prettier**, **Init Git**, **Run pnpm install**, **@/**.

> Nota: si la plantilla ofrece NextAuth y aún no lo usarás, **no lo marques**; si lo marcas, no usaremos `protectedProcedure` en esta fase para evitar dependencias a tablas de auth.

---

## 2) PostgreSQL 16 en Docker (una sola línea, Windows)

```powershell
docker run --name pg-sigecovip -e POSTGRES_PASSWORD=postgres -e POSTGRES_USER=postgres -e POSTGRES_DB=sigecovip -p 5432:5432 -d postgres:16
```

**Si 5432 ya está ocupado**, usa 5433:

```powershell
docker run --name pg-sigecovip -e POSTGRES_PASSWORD=postgres -e POSTGRES_USER=postgres -e POSTGRES_DB=sigecovip -p 5433:5432 -d postgres:16
```

---

## 3) Variables de entorno

**`sigecovip/.env`** (local, NO versionar):

```env
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/sigecovip?schema=public"
NEXTAUTH_URL="http://localhost:3000"
NEXTAUTH_SECRET="cambia-esto-por-un-valor-largo-y-seguro"
NODE_ENV="development"
```

*Si usaste el puerto 5433, cambia `@localhost:5433`.*

**`sigecovip/.env.example`** (SÍ versionar):

```env
DATABASE_URL="postgresql://USER:PASSWORD@HOST:PORT/DB?schema=public"
NEXTAUTH_URL=""
NEXTAUTH_SECRET=""
NODE_ENV="development"
```

---

## 4) Prisma con **tu** `schema.prisma` (sin romper nada)

1. Copia tu archivo a `sigecovip/prisma/schema.prisma`.
2. Valida, genera y migra:

```powershell
pnpm.cmd prisma validate
pnpm.cmd prisma generate
pnpm.cmd prisma migrate dev --name init
```

> Estos comandos **no dependen** de routers ni de NextAuth. Si tu schema no incluye modelos de auth, no pasa nada: esta fase no los usa.

---

## 5) Scripts útiles (opcionales)

En `package.json`:

```json
"scripts": {
  "db:validate": "prisma validate",
  "db:generate": "prisma generate",
  "db:migrate": "prisma migrate dev",
  "db:deploy": "prisma migrate deploy",
  "lint": "next lint",
  "format": "prettier --write ."
}
```

---

## 6) tRPC — healthcheck **minimalista y desacoplado del esquema**

> No usa `protectedProcedure`, no toca DB, no importa modelos. 100% seguro.

Crea `src/server/api/routers/health.ts`:

```ts
import { createTRPCRouter, publicProcedure } from "@/server/api/trpc";

export const healthRouter = createTRPCRouter({
  ping: publicProcedure.query(() => ({ ok: true, ts: Date.now() })),
});
```

Regístralo en `src/server/api/root.ts`:

```ts
import { createTRPCRouter } from "@/server/api/trpc";
import { healthRouter } from "./routers/health";

export const appRouter = createTRPCRouter({
  health: healthRouter,
});
export type AppRouter = typeof appRouter;
```

Levanta dev y verifica:

```powershell
pnpm.cmd dev
```

En el panel de tRPC deberías ver `health.ping` respondiendo `{ ok: true, ts: ... }`.

---

## 7) Husky + lint-staged en **Windows** (fix definitivo)

> Evita el error “`lint-staged` no se reconoce…” usando `pnpm exec` y LF en el hook.

1. Instala:

```powershell
pnpm.cmd add -D husky lint-staged eslint prettier
```

2. Inicializa Husky:

```powershell
pnpm.cmd dlx husky-init
pnpm.cmd install
```

3. En `package.json`, añade:

```json
"lint-staged": {
  "*.{js,ts,tsx}": ["eslint --fix", "prettier --write"],
  "*.{json,md,css,scss}": ["prettier --write"]
}
```

4. Reemplaza `.husky/pre-commit` por EXACTAMENTE:

```sh
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

pnpm exec lint-staged
```

5. Asegura finales de línea LF en el hook:

```powershell
git config --global core.autocrlf input
```

6. Prueba:

```powershell
pnpm.cmd exec lint-staged --version
git add -A
git commit -m "test: husky ok"
```

---

## 8) Verificaciones rápidas (solo si aplica)

* **Puerto en uso** (5432/5433):

```powershell
netstat -a -n -o | findstr :5432
```

Si ocupado → usa la variante 5433 y ajusta `DATABASE_URL`.

* **Contenedor sano**:

```powershell
docker ps -a
docker logs pg-sigecovip --tail=50
```

* **Conexión a la DB**:

```powershell
docker exec -it pg-sigecovip psql -U postgres -d sigecovip -c "select 1;"
```

* **Prisma listo**:

```powershell
pnpm.cmd prisma validate
pnpm.cmd prisma generate
pnpm.cmd prisma migrate dev --name init
```

* **App arriba y tRPC OK**:

```powershell
pnpm.cmd dev
```

Abre la app, revisa `health.ping`.

---

## 9) Checklist de salida (Fase 1)

* [ ] Contenedor `pg-sigecovip` (`postgres:16`) corriendo en el puerto correcto.
* [ ] `.env` local correcto y **`.env.example`** versionado (sin secretos).
* [ ] Prisma `validate/generate/migrate` ejecutados **sobre tu schema** sin errores.
* [ ] tRPC **health** responde OK (sin depender de DB).
* [ ] Husky **pre-commit** corre `pnpm exec lint-staged` sin fallos en Windows.
* [ ] La app levanta con `pnpm dev` sin errores complejos.

---
