# Fase 1 — App con login listo (ruta sencilla)

## 1) Crear el proyecto con T3 (App Router)

```powershell
cd D:\Dev
pnpm.cmd dlx create-t3-app@latest sigecovip
```

Selecciona: **TypeScript**, **Tailwind**, **tRPC**, **Prisma**, **App Router**, **NextAuth**, **PostgreSQL**, **ESLint+Prettier**, **Init Git**, **Run pnpm install**, alias **@/**.
(Esto encaja con el entorno y prácticas fijadas en tu Fase 0).&#x20;

## 2) PostgreSQL 16 en Docker (pin de versión)

```powershell
docker run --name pg-sigecovip `
  -e POSTGRES_PASSWORD=postgres -e POSTGRES_USER=postgres -e POSTGRES_DB=sigecovip `
  -p 5432:5432 -d postgres:16
```

Si 5432 está ocupado, usa `-p 5433:5432` y ajusta la URL. (Pin de versión y checks tal como definiste antes).&#x20;

## 3) Variables de entorno

**`sigecovip/.env`** (local):

```env
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/sigecovip?schema=public"
NEXTAUTH_URL="http://localhost:3000"
NEXTAUTH_SECRET="cambia-esto-por-un-valor-largo-y-seguro"
NODE_ENV="development"
```

**`sigecovip/.env.example`** (versionado, sin secretos):

```env
DATABASE_URL="postgresql://USER:PASSWORD@HOST:PORT/DB?schema=public"
NEXTAUTH_URL=""
NEXTAUTH_SECRET=""
NODE_ENV="development"
```

(Política de `.env.example` desde Fase 0/guía previa).

## 4) Prisma: modelo mínimo de usuarios

Edita `prisma/schema.prisma` a algo mínimo y funcional (puedes ampliar luego):

```prisma
generator client { provider = "prisma-client-js" }
datasource db { provider = "postgresql"; url = env("DATABASE_URL") }

model User {
  id            String   @id @default(uuid())
  name          String?
  email         String   @unique
  passwordHash  String   // para Credentials
  role          String   @default("INSPECTOR")
  createdAt     DateTime @default(now())
  updatedAt     DateTime @updatedAt

  @@index([email])
}
```

Genera y migra:

```powershell
pnpm.cmd prisma validate
pnpm.cmd prisma generate
pnpm.cmd prisma migrate dev --name init_user
```

(Valida/migra como en tu flujo estándar).&#x20;

## 5) Seed: crear un usuario de prueba

Crea `prisma/seed.ts`:

```ts
import { PrismaClient } from "@prisma/client";
import bcrypt from "bcryptjs";
const prisma = new PrismaClient();

async function main() {
  const email = "demo@sigecovip.local";
  const password = "Demo.1234"; // cámbialo después
  const passwordHash = await bcrypt.hash(password, 12);

  await prisma.user.upsert({
    where: { email },
    update: { passwordHash },
    create: { email, name: "Usuario Demo", passwordHash, role: "INSPECTOR" },
  });
  console.log("Seed OK:", email, password);
}

main().finally(() => prisma.$disconnect());
```

Instala la dependencia y corre el seed:

```powershell
pnpm.cmd add -D ts-node @types/bcryptjs
pnpm.cmd add bcryptjs
```

En `package.json`:

```json
"prisma": { "seed": "ts-node prisma/seed.ts" }
```

Ejecuta:

```powershell
pnpm.cmd prisma db seed
```

## 6) NextAuth (Credentials Provider) — App Router

Crea `src/server/auth.ts` (config compartida):

```ts
import { PrismaClient } from "@prisma/client";
import CredentialsProvider from "next-auth/providers/credentials";
import type { NextAuthOptions } from "next-auth";
import bcrypt from "bcryptjs";

const prisma = new PrismaClient();

export const authOptions: NextAuthOptions = {
  session: { strategy: "jwt" },
  providers: [
    CredentialsProvider({
      name: "Credenciales",
      credentials: {
        email: { label: "Email", type: "email" },
        password: { label: "Contraseña", type: "password" },
      },
      async authorize(credentials) {
        if (!credentials?.email || !credentials?.password) return null;
        const user = await prisma.user.findUnique({ where: { email: credentials.email } });
        if (!user) return null;
        const ok = await bcrypt.compare(credentials.password, user.passwordHash);
        if (!ok) return null;
        return { id: user.id, name: user.name ?? user.email, email: user.email };
      },
    }),
  ],
  pages: { signIn: "/login" },
};
```

Crea el **route handler** para NextAuth en App Router: `src/app/api/auth/[...nextauth]/route.ts`

```ts
import NextAuth from "next-auth";
import { authOptions } from "@/server/auth";

const handler = NextAuth(authOptions);
export { handler as GET, handler as POST };
```

## 7) Página de Login y acciones

`src/app/login/page.tsx`:

```tsx
"use client";
import { signIn } from "next-auth/react";
import { useState } from "react";

export default function LoginPage() {
  const [email, setEmail] = useState(""); 
  const [password, setPassword] = useState("");

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    const res = await signIn("credentials", {
      email, password, callbackUrl: "/dashboard", redirect: true,
    });
  }

  return (
    <div className="min-h-screen grid place-items-center">
      <form onSubmit={onSubmit} className="w-full max-w-sm space-y-4 p-6 rounded-2xl shadow">
        <h1 className="text-xl font-semibold">Iniciar sesión</h1>
        <input className="w-full border p-2 rounded" placeholder="Email" value={email} onChange={e=>setEmail(e.target.value)} />
        <input className="w-full border p-2 rounded" placeholder="Contraseña" type="password" value={password} onChange={e=>setPassword(e.target.value)} />
        <button className="w-full p-2 rounded-2xl shadow">Entrar</button>
      </form>
    </div>
  );
}
```

## 8) Rutas protegidas (middleware) + Dashboard

Crea `src/middleware.ts`:

```ts
export { default } from "next-auth/middleware";
export const config = { matcher: ["/dashboard/:path*"] };
```

Crea `src/app/dashboard/page.tsx`:

```tsx
import { getServerSession } from "next-auth";
import { authOptions } from "@/server/auth";
import Link from "next/link";

export default async function Dashboard() {
  const session = await getServerSession(authOptions);
  return (
    <main className="p-6 space-y-4">
      <h1 className="text-2xl font-bold">Dashboard</h1>
      <p>Hola, {session?.user?.name ?? session?.user?.email}.</p>
      <Link href="/api/auth/signout">Cerrar sesión</Link>
    </main>
  );
}
```

> Con esto:
> • `/login` permite entrar con el usuario seed.
> • `/dashboard` exige sesión (middleware).
> • Puedes añadir enlaces de `signIn/signOut` en tu layout cuando quieras.

## 9) tRPC “health” (opcional, para comprobar vida)

Tal cual tu guía previa: crea un router `health.ping` y revisa en el panel de tRPC que responde. (Desacoplado de DB; útil para sanity-check).&#x20;

## 10) Ejecutar todo

```powershell
# DB en docker (si no está ya)
docker start pg-sigecovip

# Prisma y seed
pnpm.cmd prisma validate
pnpm.cmd prisma generate
pnpm.cmd prisma migrate dev --name init_user
pnpm.cmd prisma db seed

# App
pnpm.cmd dev
```

Visita `http://localhost:3000/login`, entra con `demo@sigecovip.local` / `Demo.1234` y verifica `/dashboard`.

## 11) Checklist de salida (Fase 1)

* [ ] Contenedor `postgres:16` corriendo y accesible (5432/5433).&#x20;
* [ ] `.env` correcto y **`.env.example`** versionado (sin secretos).&#x20;
* [ ] `prisma migrate` + `db seed` OK y `User` creado.&#x20;
* [ ] **NextAuth Credentials** operando, `/login` → `/dashboard`.
* [ ] **Middleware** protegiendo `/dashboard`.
* [ ] (Opcional) tRPC `health.ping` responde OK.&#x20;

---
