Quiero que actúes como **arquitecto y copiloto** para configurar un proyecto Next.js (plantilla **T3 mínima**) con estas opciones ya elegidas:

* **TypeScript**: Sí
* **TailwindCSS**: Sí
* **tRPC**: No
* **Autenticación**: NextAuth.js
* **ORM/DB**: Ninguno (por ahora)
* **App Router**: No (usar **Pages Router**)
* **ESLint/Prettier**: Sí
* **Alias de import**: `@/`
* **SO**: Windows, uso `pnpm.cmd`
* **Estructura**: `.env` y `.env.example` en la raíz

---

## Contexto del proyecto (SIGECOVIP)

Tengo tres archivos **ya cargados en este proyecto** y debes **apoyarte en ellos** para alinear términos, roles, glosario y alcance funcional (no los reescribas, solo **extrae lo necesario** y **mantén trazabilidad**):

* `Kodoma-Solutions-SIGECOVIP-Project-Charter.odt`
* `Kodoma-Solutions-SIGECOVIP-ERS-830 IEEE.odt`
* `Kodoma-Solutions-SIGECOVIP-Estudio de viabilidad y factibilidad técnica.odt`

**Reglas de trazabilidad**:

1. Alinea nomenclatura de actores/roles y objetivos con el **Project Charter**.
2. Asegura que el comportamiento de login/roles cumpla con el **ERS-830** (requisitos funcionales/no funcionales).
3. Respeta restricciones y riesgos relevantes del **Estudio de Viabilidad** (p. ej., minimalismo tecnológico, tiempos, y Windows).
4. Si detectas conflicto entre documentos, **indica el punto** y propone la mínima corrección coherente con el Charter.

> **Importante (permisos de dominio “Comerciantes”)**
>
> * **admin**: solo **gestiona roles/estado** de usuarios (asignar, revocar). **No** crea/edita/elimina comerciantes ni datos operativos.
> * **coordinator**: **crear, ver, editar y eliminar** comerciantes.
> * **inspector**: **crear y ver** comerciantes.
> * **pending**: acceso restringido; solo ve mensaje de espera.
> * **revoked**: acceso denegado.
>   Estos permisos aplican a las futuras vistas de gestión de comerciantes (cuando yo te lo pida). Hoy solo dejamos el esqueleto y la base de sesiones/roles.

---

## Objetivo de esta sesión

Entregar un **login con Google** funcional **hoy**, con **cambios mínimos** al esqueleto de la plantilla. A futuro quiero:

* Definir manualmente **qué correo es administrador** (no depende de dominio).
* El **admin** entra a una vista interna **solo para gestión de acceso/roles** (no de comerciantes):

  * ver usuarios que iniciaron sesión,
  * asignar rol (**coordinator**, **inspector**),
  * marcar **pending** o **revoked**.
* Si un usuario inicia sesión pero **no tiene rol** → **pending**:

  * ver mensaje “Tu correo está en espera de validación”,
  * sin acceso a funcionalidades.
* (Opcional, **solo cuando lo pida**): persistir usuarios con Prisma + PostgreSQL.

---

## Reglas de trabajo

1. **Nada de herramientas de más**: no agregues tRPC, UI kits grandes, ni DB hoy (salvo que explícitamente te pida activar Prisma).
2. **Respeta Pages Router**.
3. **Minimal diffs**: propone solo los archivos y líneas **estrictamente necesarios**.
4. **Windows-friendly**: comandos con `pnpm.cmd` y rutas coherentes.
5. **Cero ambigüedad**: cada paso debe indicar **archivo, ruta y contenido exacto**.
6. **Verificaciones al final de cada paso** (qué URL abrir, qué debería ver).
7. **No cambies** Tailwind, ESLint, `next.config.js` ni `tsconfig.json` si no es necesario.
8. **Trazabilidad**: cuando introduzcas nombres de roles, mensajes o flujos, di en una línea qué documento (Charter/ERS/Viabilidad) respalda esa decisión.

---

## Variables de entorno

En la raíz existen `.env` y `.env.example`. Guíame para dejarlas así (con mis valores reales):

```
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=<genera_un_secreto_fuerte>
GOOGLE_CLIENT_ID=<tu_client_id>.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=<tu_client_secret>
ADMIN_EMAIL=<correo_del_admin>
```

**Redirect URI** exacto a registrar en Google:
`http://localhost:3000/api/auth/callback/google`

---

## Entregables paso a paso (**pídemelos uno por uno**)

### 1) Paso 1: `.env` y comprobación previa

* Revisión de claves mínimas en `.env` y `.env.example`.
* Comando Windows para generar `NEXTAUTH_SECRET`.
* Verificar dependencias (`next-auth`) y arranque con `pnpm.cmd dev`.
* **Verificación**: URL a abrir y resultado esperado.

### 2) Paso 2: Config de NextAuth

* Crear `src/server/auth.ts` con **GoogleProvider**, `session.strategy = "jwt"`, `pages.signIn = "/login"`.
* **Callback `signIn`** debe:

  * aceptar siempre al `ADMIN_EMAIL` (rol “admin”),
  * registrar al resto como “pending” por defecto,
  * devolver `false` si el acceso está **revocado**.
* Incluir `role` en el JWT (`"admin" | "coordinator" | "inspector" | "pending" | "revoked"`).
* **Trazabilidad**: indica en una línea cómo esto refleja ERS y el Charter.

### 3) Paso 3: Handler API

* Crear `src/pages/api/auth/[...nextauth].ts` importando **exactamente** desde `../../../server/auth`.
* Explica cómo detectar error si me equivoco con los `../`.
* **Verificación**: prueba de login y estado del JWT en sesión.

### 4) Paso 4: Pantallas mínimas

* `src/pages/login.tsx`: botón “Continuar con Google”.
* `src/pages/_app.tsx`: envolver con `SessionProvider`.
* `src/pages/index.tsx`: protegido con `getServerSession`.
* **Comportamiento por rol**:

  * `admin`: acceso normal + **link solo a vista de gestión de roles** (no CRUD de comerciantes).
  * `coordinator` / `inspector`: acceso normal (futuras vistas de comerciantes se activarán después).
  * `pending`: mensaje “Tu correo está en espera de validación”.
  * `revoked`: mensaje “Acceso denegado”.
* **Verificación**: rutas a visitar y qué debe mostrarse.

### 5) Paso 5: Verificación funcional

* Check-list de navegación con distintos casos de rol.
* Tips de solución de errores comunes (redirect URI, variables faltantes, reloj del sistema, ruta del handler).
* **Trazabilidad**: confirma consistencia con ERS/Viabilidad.

### 6) (Opcional, **solo a petición**) Persistencia con Prisma + PostgreSQL

* Añadir: `pnpm.cmd add prisma @prisma/client @next-auth/prisma-adapter`
* `prisma/schema.prisma` mínimo (User/Account/Session/VerificationToken + `role`).
* Adaptar `authOptions` con Prisma Adapter.
* Mantener el resto **igual** (Pages Router, minimal diffs).
* **Trazabilidad**: mapea entidades a ERS-830.

---

## Formato de tu respuesta

* Dame **un solo paso a la vez** (empezando por el **Paso 1**).
* Para cada paso, entrega **exactamente**:

  * **rutas de archivo**,
  * **contenido completo** de cada archivo,
  * **comandos Windows** (`pnpm.cmd`),
  * una **verificación** (qué URL cargar / qué debería ver),
  * y **1 línea de trazabilidad** (qué documento respalda ese cambio).
* **No te adelantes** al siguiente paso hasta que yo diga **“listo”**.

---
