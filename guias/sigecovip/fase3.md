# Fase 3 — CRUD sólido + Inspecciones + Auditoría básica (sin romper nada)

## Objetivos (alcance mínimo y seguro)

1. **Comerciantes**: completar CRUD (create ya existe) con **update** y **delete** seguros.
2. **Inspecciones**: router mínimo (listar por comerciante y crear).
3. **Auditoría básica**: registrar altas/ediciones/bajas con un helper reutilizable.
4. **Páginas simples** en Next.js para probar (sin login).
5. **Validaciones** y **manejo de errores** consistentes (Zod + try/catch).
6. **Comprobaciones** al final para garantizar que nada se rompió.

> Nota: no toco Auth ni providers. Cuando quieras, en una fase futura activamos NextAuth y conmutamos `publicProcedure` → `protectedProcedure`.

---

## 1) Utilidades comunes (Zod y helpers)

Crea `src/server/api/validators/comerciante.ts`:

```ts
import { z } from "zod";

export const comercianteCreateSchema = z.object({
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
});

export const comercianteUpdateSchema = comercianteCreateSchema.partial().extend({
  id: z.string().uuid(),
});
```

Crea `src/server/api/utils/auditoria.ts`:

```ts
import type { PrismaClient } from "@prisma/client";

type Accion = "alta" | "modificacion" | "baja" | "reporte" | "login";
type Modulo = "comerciante" | "inspeccion" | "reporte" | "usuario";

/**
 * Inserta una entrada en Auditoria. No depende de sesión en esta fase.
 * En fase futura, pasa el userId desde la sesión.
 */
export async function addAudit(
  db: PrismaClient,
  params: { usuarioId?: string | null; accion: Accion; modulo: Modulo; detalle?: string }
) {
  const usuarioId = params.usuarioId ?? "00000000-0000-0000-0000-000000000000"; // placeholder
  await db.auditoria.create({
    data: {
      usuarioId,
      accion: params.accion,
      modulo: params.modulo,
      detalle: params.detalle,
    },
  });
}
```

> No cambio tu tabla `Auditoria`. Si luego migras a enums en acciόn/módulo, solo ajustas los tipos del helper.

---

## 2) Router de Comerciantes — añadir **update** y **delete**

Edita `src/server/api/routers/comerciante.ts` para sumar dos procedimientos:

```ts
import { z } from "zod";
import { createTRPCRouter, publicProcedure } from "@/server/api/trpc";
import { comercianteCreateSchema, comercianteUpdateSchema } from "../validators/comerciante";
import { addAudit } from "../utils/auditoria";

export const comercianteRouter = createTRPCRouter({
  // ... list, getById, create (los que ya tienes) ...

  update: publicProcedure
    .input(comercianteUpdateSchema)
    .mutation(async ({ ctx, input }) => {
      const { id, ...changes } = input;
      try {
        const updated = await ctx.db.comerciante.update({
          where: { id },
          data: {
            ...changes,
            // si tu schema usa Decimal, Prisma castea automáticamente los numbers
          },
        });
        await addAudit(ctx.db, {
          accion: "modificacion",
          modulo: "comerciante",
          detalle: `Actualización comerciante ${id}`,
        });
        return updated;
      } catch (err: any) {
        // p.ej. Prisma.PrismaClientKnownRequestError
        throw new Error(`No se pudo actualizar: ${err?.message ?? "error desconocido"}`);
      }
    }),

  delete: publicProcedure
    .input(z.object({ id: z.string().uuid() }))
    .mutation(async ({ ctx, input }) => {
      try {
        // BORRADO FÍSICO (simple). Si prefieres soft-delete, agrega un campo 'activo' en el schema (futuro).
        const deleted = await ctx.db.comerciante.delete({
          where: { id: input.id },
        });
        await addAudit(ctx.db, {
          accion: "baja",
          modulo: "comerciante",
          detalle: `Baja comerciante ${input.id}`,
        });
        return deleted;
      } catch (err: any) {
        throw new Error(`No se pudo eliminar: ${err?.message ?? "error desconocido"}`);
      }
    }),
});
```

> **No rompe nada**: sin sesiones ni cambios de schema. Los `try/catch` devuelven mensajes claros.

---

## 3) Router de **Inspecciones** (listar por comerciante y crear)

Crea `src/server/api/routers/inspeccion.ts`:

```ts
import { z } from "zod";
import { createTRPCRouter, publicProcedure } from "@/server/api/trpc";
import { addAudit } from "../utils/auditoria";

export const inspeccionRouter = createTRPCRouter({
  listByComerciante: publicProcedure
    .input(z.object({ comercianteId: z.string().uuid() }))
    .query(async ({ ctx, input }) => {
      return ctx.db.inspeccion.findMany({
        where: { comercianteId: input.comercianteId },
        orderBy: { fechaHora: "desc" },
        select: {
          id: true,
          fechaHora: true,
          notas: true,
          evidencias: true,
          inspectorId: true,
        },
      });
    }),

  create: publicProcedure
    .input(
      z.object({
        comercianteId: z.string().uuid(),
        notas: z.string().min(1),
        evidencias: z.array(z.string().url()).optional(),
        // En fase futura, inspectorId vendrá de la sesión; por ahora lo dejamos opcional
        inspectorId: z.string().uuid().optional(),
      })
    )
    .mutation(async ({ ctx, input }) => {
      const created = await ctx.db.inspeccion.create({
        data: {
          comercianteId: input.comercianteId,
          notas: input.notas,
          evidencias: input.evidencias ?? [],
          inspectorId: input.inspectorId ?? "00000000-0000-0000-0000-000000000000",
        },
      });
      await addAudit(ctx.db, {
        accion: "alta",
        modulo: "inspeccion",
        detalle: `Alta inspección ${created.id} en comerciante ${input.comercianteId}`,
      });
      return created;
    }),
});
```

Regístralo en `src/server/api/root.ts`:

```ts
import { inspeccionRouter } from "./routers/inspeccion";
export const appRouter = createTRPCRouter({
  // ... health, comerciante ...
  inspeccion: inspeccionRouter,
});
```

> **No rompe nada**: usa tus tablas existentes (`Inspeccion`, `Auditoria`). En fase futura, conectaremos `inspectorId` con la sesión real.

---

## 4) Páginas simples (tabla + detalle + inspecciones)

### 4.1 `/comerciantes` (añadir acciones Update/Delete opcionales)

Extiende tu página `src/app/comerciantes/page.tsx`. Añade botones y formulario modal **opcional**. Para no alargar, te doy un ejemplo mínimo de **Delete** client-side:

```tsx
// dentro del map de filas:
<button
  className="px-2 py-1 text-white bg-red-600 rounded"
  onClick={async () => {
    if (!confirm("¿Eliminar este comerciante?")) return;
    try {
      await api.comerciante.delete.mutate({ id: c.id });
      await refetch();
      alert("Eliminado");
    } catch (e: any) {
      alert(e?.message ?? "Error al eliminar");
    }
  }}
>
  Eliminar
</button>
```

> Para **update**, añade un modal con inputs ligados a `comercianteUpdateSchema` y llama `api.comerciante.update.mutate(...)`. Es totalmente compatible con lo ya hecho.

### 4.2 Página de inspecciones por comerciante (simple)

Crea `src/app/comerciantes/[id]/inspecciones/page.tsx`:

```tsx
"use client";
import { useParams } from "next/navigation";
import { api } from "@/trpc/react";
import { useState } from "react";

export default function InspeccionesByComerciante() {
  const params = useParams();
  const comercianteId = params?.id as string;

  const { data, isLoading, error, refetch } = api.inspeccion.listByComerciante.useQuery({ comercianteId });
  const createMutation = api.inspeccion.create.useMutation();

  const [notas, setNotas] = useState("");

  return (
    <main className="p-6">
      <h1 className="text-xl font-semibold mb-4">Inspecciones</h1>

      <form
        className="mb-4 flex gap-2"
        onSubmit={async (e) => {
          e.preventDefault();
          try {
            await createMutation.mutateAsync({ comercianteId, notas });
            setNotas("");
            await refetch();
          } catch (err: any) {
            alert(err?.message ?? "Error al crear inspección");
          }
        }}
      >
        <input
          value={notas}
          onChange={(e) => setNotas(e.target.value)}
          placeholder="Notas de la inspección"
          className="border rounded px-3 py-2 w-full"
        />
        <button className="px-4 py-2 rounded bg-black text-white">Agregar</button>
      </form>

      {isLoading && <p>Cargando…</p>}
      {error && <p className="text-red-600">Error: {error.message}</p>}
      {data && (
        <ul className="space-y-2">
          {data.map((i) => (
            <li key={i.id} className="border rounded p-3">
              <div className="text-sm text-gray-500">{new Date(i.fechaHora).toLocaleString()}</div>
              <div className="font-medium">{i.notas}</div>
            </li>
          ))}
        </ul>
      )}
    </main>
  );
}
```

> **No rompe nada**: consume el router y muestra lista. Crea inspecciones con un input. Evidencias/inspector se agregan en fases siguientes.

---

## 5) Comprobaciones (paso a paso, Windows)

### DB/Contenedor

```powershell
docker ps -a
docker logs pg-sigecovip --tail=50
```

### Prisma

```powershell
pnpm.cmd prisma validate
pnpm.cmd prisma generate
# si añadiste nuevas migraciones, aplícalas:
# pnpm.cmd prisma migrate dev --name fase3
```

### App

```powershell
pnpm.cmd dev
```

* `/comerciantes` lista y elimina.
* `/comerciantes/[id]/inspecciones` muestra y crea inspecciones.
* No hay errores en consola.

### Hooks (Husky) siguen bien

```powershell
git add -A
git commit -m "feat: fase3 CRUD + inspecciones + auditoria basica"
```

---

## 6) Qué quedó y por qué es seguro

* **Nada de Auth** todavía: cero dependencias frágiles. En una fase futura cambiamos a `protectedProcedure`.
* **Sin cambios de schema**: todo trabaja con tu `schema.prisma` actual.
* **Auditoría** opcional y simple con helper reutilizable (no afecta flujos).
* **Errores contenidos**: cada mutación hace `try/catch` y devuelve mensaje claro.

---
