# Fase 2 — Funcionalidad mínima del dominio (segura y sin sorpresas)

## Objetivos de la fase

* tRPC con router de **Comerciantes** (listar, consultar por id y crear).
* **Página** simple `/comerciantes` (tabla read-only) y detalle.
* **Seed** de datos para ambiente local.
* **CI Lite** (sin base de datos) que verifique lint y build.
* Mantener cero dependencias frágiles (no exigimos sesión ni providers de Auth).

---

## 1) Router de Comerciantes (tRPC)

Crea `src/server/api/routers/comerciante.ts`:

```ts
import { z } from "zod";
import { createTRPCRouter, publicProcedure } from "@/server/api/trpc";

// Nota: usamos publicProcedure para evitar dependencias a Auth en esta fase.
// Si ya tienes NextAuth y quieres proteger "create", lo cambiamos a protectedProcedure más adelante.

export const comercianteRouter = createTRPCRouter({
  list: publicProcedure
    .input(
      z.object({
        q: z.string().optional(),     // búsqueda simple (por nombre/organización)
        page: z.number().int().min(1).default(1),
        pageSize: z.number().int().min(1).max(100).default(20),
      }).optional()
    )
    .query(async ({ ctx, input }) => {
      const page = input?.page ?? 1;
      const pageSize = input?.pageSize ?? 20;
      const q = input?.q?.trim();

      const where = q
        ? {
            OR: [
              { titularNombre: { contains: q, mode: "insensitive" } },
              { organizacion: { contains: q, mode: "insensitive" } },
              { giro: { contains: q, mode: "insensitive" } },
            ],
          }
        : {};

      const [total, items] = await Promise.all([
        ctx.db.comerciante.count({ where }),
        ctx.db.comerciante.findMany({
          where,
          orderBy: { actualizadoEn: "desc" },
          skip: (page - 1) * pageSize,
          take: pageSize,
          select: {
            id: true,
            titularNombre: true,
            giro: true,
            organizacion: true,
            estatus: true,
            latitud: true,
            longitud: true,
            actualizadoEn: true,
          },
        }),
      ]);

      return { total, page, pageSize, items };
    }),

  getById: publicProcedure
    .input(z.object({ id: z.string().uuid() }))
    .query(async ({ ctx, input }) => {
      return ctx.db.comerciante.findUnique({
        where: { id: input.id },
      });
    }),

  create: publicProcedure // <- luego lo cambiamos a protectedProcedure cuando actives Auth
    .input(
      z.object({
        titularNombre: z.string().min(1),
        giro: z.string().min(1),
        superficieM2: z.number().positive(),
        diasOperacion: z.string().min(1),
        horarioOperacion: z.string().min(1),
        tipoMontaje: z.string().min(1),
        licenciaPermiso: z.string().optional(),
        direccion: z.string().min(1),
        latitud: z.number().min(-90).max(90),
        longitud: z.number().min(-180).max(180),
        organizacion: z.string().optional(),
        estatus: z.enum(["VIGENTE", "IRREGULAR", "SANCIONADO", "EN_TRAMITE"]),
        fotos: z.array(z.string().url()).optional(),
        documentos: z.array(z.string().url()).optional(),
      })
    )
    .mutation(async ({ ctx, input }) => {
      return ctx.db.comerciante.create({
        data: {
          ...input,
          // Prisma espera Decimal en superficie/lat/long si tu schema los define como Decimal.
          // Si definiste Decimal, no pasa nada: Prisma hace casting de number->Decimal internamente.
          fotos: input.fotos ?? undefined,
          documentos: input.documentos ?? undefined,
        },
      });
    }),
});
```

Regístralo en `src/server/api/root.ts`:

```ts
import { createTRPCRouter } from "@/server/api/trpc";
import { healthRouter } from "./routers/health";
import { comercianteRouter } from "./routers/comerciante";

export const appRouter = createTRPCRouter({
  health: healthRouter,
  comerciante: comercianteRouter,
});
export type AppRouter = typeof appRouter;
```

> **Seguro con tu `schema.prisma`**: solo usa el modelo `Comerciante` y selects básicos. Si tus nombres difieren, ajusta los campos en el `select`/`data` (no afecta la estructura general).

---

## 2) Página `/comerciantes` (read-only)

Crea `src/app/comerciantes/page.tsx`:

```tsx
"use client";
import { api } from "@/trpc/react";
import { useState } from "react";

export default function ComerciantesPage() {
  const [q, setQ] = useState("");
  const { data, isLoading, error, refetch } = api.comerciante.list.useQuery(
    { q, page: 1, pageSize: 20 },
    { keepPreviousData: true }
  );

  return (
    <main className="p-6">
      <h1 className="text-2xl font-semibold mb-4">Comerciantes</h1>

      <div className="flex gap-2 mb-4">
        <input
          value={q}
          onChange={(e) => setQ(e.target.value)}
          placeholder="Buscar por nombre, organización o giro…"
          className="border rounded px-3 py-2 w-full"
        />
        <button
          onClick={() => refetch()}
          className="px-4 py-2 rounded bg-black text-white"
        >
          Buscar
        </button>
      </div>

      {isLoading && <p>Cargando…</p>}
      {error && <p className="text-red-600">Error: {error.message}</p>}
      {!isLoading && data && (
        <>
          <p className="text-sm mb-2">
            {data.total} resultado(s) • mostrando {data.items.length}
          </p>
          <div className="overflow-x-auto">
            <table className="min-w-full border">
              <thead className="bg-gray-50">
                <tr>
                  <th className="p-2 text-left border">Titular</th>
                  <th className="p-2 text-left border">Giro</th>
                  <th className="p-2 text-left border">Organización</th>
                  <th className="p-2 text-left border">Estatus</th>
                  <th className="p-2 text-left border">Lat</th>
                  <th className="p-2 text-left border">Lng</th>
                </tr>
              </thead>
              <tbody>
                {data.items.map((c) => (
                  <tr key={c.id} className="odd:bg-white even:bg-gray-50">
                    <td className="p-2 border">{c.titularNombre}</td>
                    <td className="p-2 border">{c.giro}</td>
                    <td className="p-2 border">{c.organizacion ?? "—"}</td>
                    <td className="p-2 border">{c.estatus}</td>
                    <td className="p-2 border">{String(c.latitud)}</td>
                    <td className="p-2 border">{String(c.longitud)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </>
      )}
    </main>
  );
}
```

> **No rompe nada:** es “client-side” y solo llama al procedimiento `list`. No requiere login.

---

## 3) Seed de datos (opcional, muy útil)

Archivo `prisma/seed.ts`:

```ts
import { PrismaClient } from "@prisma/client";
const prisma = new PrismaClient();

async function main() {
  const total = await prisma.comerciante.count();
  if (total > 0) {
    console.log("Seed omitido: ya existen comerciantes.");
    return;
  }

  await prisma.comerciante.createMany({
    data: [
      {
        id: crypto.randomUUID(),
        titularNombre: "Juan Pérez",
        giro: "Elotes",
        superficieM2: 4.5,
        diasOperacion: "Lun-Vie",
        horarioOperacion: "10:00-18:00",
        tipoMontaje: "Semifijo",
        licenciaPermiso: null,
        direccion: "Calle 1, Col. Centro",
        latitud: 20.593000,
        longitud: -100.392000,
        organizacion: "Org A",
        estatus: "VIGENTE",
        fotos: [],
        documentos: [],
      },
      {
        id: crypto.randomUUID(),
        titularNombre: "María López",
        giro: "Gorditas",
        superficieM2: 6.0,
        diasOperacion: "Mar-Dom",
        horarioOperacion: "09:00-17:00",
        tipoMontaje: "Fijo",
        licenciaPermiso: "LIC-123",
        direccion: "Calle 2, Col. Cimatario",
        latitud: 20.590500,
        longitud: -100.390100,
        organizacion: null,
        estatus: "IRREGULAR",
        fotos: [],
        documentos: [],
      },
    ],
  });

  console.log("Seed listo.");
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
```

Agrega el script en `package.json`:

```json
"scripts": {
  "db:seed": "tsx prisma/seed.ts"
}
```

Instala `tsx` si no lo tienes:

```powershell
pnpm.cmd add -D tsx
```

Ejecuta el seed:

```powershell
pnpm.cmd db:seed
```

> **Seguro con tu schema**: solo usa el modelo `Comerciante`. Si tu `schema.prisma` define `Decimal`, Prisma acepta `number` en JS y hace el casting.

---

## 4) CI “Lite” (sin DB) — no rompe builds

Archivo `.github/workflows/ci-lite.yml`:

```yaml
name: CI Lite
on: [push, pull_request]

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: pnpm
      - run: corepack enable
      - run: pnpm install --frozen-lockfile
      - run: pnpm lint
      - run: pnpm build
```

> *No usa Postgres en CI.* Solo valida lint y build. Cuando cierres modelo/diseño, puedes pasar a un CI con DB en otra fase.

---

## 5) Comprobaciones finales (Windows)

**Base de datos** (elige tu puerto; 5432 por defecto):

```powershell
netstat -a -n -o | findstr :5432
docker ps -a
docker logs pg-sigecovip --tail=50
```

**Migraciones** (con tu esquema):

```powershell
pnpm.cmd prisma validate
pnpm.cmd prisma generate
pnpm.cmd prisma migrate dev --name init
```

**Seed (opcional)**:

```powershell
pnpm.cmd db:seed
```

**App en dev**:

```powershell
pnpm.cmd dev
```

* Abre `/comerciantes` → ves tabla con datos.
* Panel de tRPC: `comerciante.list` y `comerciante.getById` responden.
* Health (`health.ping`) sigue OK.

**Husky** sigue funcionando (de Fase 1):

```powershell
git add -A
git commit -m "feat: fase2 mínima comerciante"
```

---

## 6) Qué quedó listo y por qué no rompe nada

* **Router desacoplado de Auth**: `publicProcedure`. Puedes activar `protectedProcedure` después sin reescribir todo.
* **UI read-only**: no exige sesión; consume `list` solamente.
* **Seed opcional**: si ya tienes datos, lo detecta y no duplica.
* **CI Lite**: evita errores por DB hasta que lo decidas.

---
