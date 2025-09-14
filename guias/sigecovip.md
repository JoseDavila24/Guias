# Fase 0 — Preparación del entorno en Windows 10 Home (versión revisada)

## 0.1 Requisitos del sistema y políticas del SO

* **Windows 10 Home 20H2+** actualizado.
* CPU con **VT-x/AMD-V** habilitado en BIOS/UEFI.
* **RAM**: 16 GB recomendados (mínimo 8 GB). **Disco**: ≥ 30 GB libres (mejor 50–80 GB si usarás imágenes Docker y datos).
* **Red** con salida a `registry.npmjs.org` y registros de contenedores (Docker Hub/GHCR).
* **Rutas largas** (evita errores en `node_modules`):

  ```powershell
  git config --global core.longpaths true
  ```

  Y, si puedes, habilita “Enable Win32 long paths” en Windows.
* **Fin de línea** coherente (evita CRLF):

  ```powershell
  git config --global core.autocrlf input
  ```
* **Energía**: Perfil **Alto rendimiento** (mejora estabilidad del hypervisor).
* **Registra en el Manual**: versión de Windows, CPU, RAM, disco, confirmación de virtualización habilitada.

---

## 0.2 PowerShell y ejecución de scripts (evitar bloqueos)

Si PowerShell bloquea `*.ps1`, tienes tres opciones. En Windows 10 Home lo más práctico es **usar wrappers `.cmd`**:

1. **Wrappers `.cmd`** (recomendado): `npm.cmd`, `pnpm.cmd`, `npx.cmd`.
2. Permitir scripts para tu usuario:

   ```powershell
   Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
   ```
3. Solo para la sesión:

   ```powershell
   Set-ExecutionPolicy -Scope Process Bypass
   ```

> Con esto evitas “la ejecución de scripts está deshabilitada”.

---

## 0.3 Node.js LTS + Corepack (pnpm) y gestor de versiones (opcional)

1. Instala **Node.js LTS** (incluye `npm` y **Corepack**).
2. Habilita pnpm vía Corepack:

   ```powershell
   corepack enable
   corepack prepare pnpm@latest --activate
   ```
3. Verifica (usa `.cmd` donde aplique):

   ```powershell
   node -v
   npm.cmd -v
   corepack --version
   pnpm.cmd -v
   ```
4. (Opcional pero recomendable) **Gestor de versiones** para fijar LTS por proyecto:

   * `fnm` o `nvs` según prefieras; así evitas “drift” de versiones entre máquinas.

> Si `pnpm` sin `.cmd` falla, usa siempre `pnpm.cmd` o aplica 0.2.

---

## 0.4 Git y GitHub CLI

1. Instala **Git** (marca “Git from command line”).
2. Configura identidad:

   ```powershell
   git config --global user.name  "Tu Nombre"
   git config --global user.email "tu@email"
   git config --global init.defaultBranch main
   git config --global core.autocrlf input
   git config --global core.longpaths true
   ```
3. (Opcional) **GitHub CLI**:

   ```powershell
   gh --version
   gh auth login
   ```

---

## 0.5 VS Code (trabajo dentro de WSL) + extensiones

* **VS Code** actualizado.
* Extensiones mínimas: **ESLint**, **Prettier**, **Tailwind CSS IntelliSense**, **Prisma**, **Docker**, **GitHub Actions**, **Remote – WSL**.
* Ajustes sugeridos (`.vscode/settings.json`):

  ```json
  {
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": { "source.fixAll.eslint": true },
    "eslint.validate": ["typescript", "typescriptreact", "javascript"]
  }
  ```

> Abre el proyecto **desde WSL (Ubuntu)** con la extensión **Remote – WSL**. Minimiza problemas de paths, watchers y CRLF.

---

## 0.6 WSL2 y Docker Desktop (imprescindible en Win10 Home)

### 0.6.1 Activar características (PowerShell **Administrador**)

```powershell
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```

Reinicia.

### 0.6.2 Instalar/actualizar WSL

* Instala Ubuntu (si no la tienes):

  ```powershell
  wsl --install -d Ubuntu
  ```
* Actualiza kernel y fija WSL2 por defecto:

  ```powershell
  wsl --update
  wsl --set-default-version 2
  wsl --status
  ```

### 0.6.3 Instalar y configurar Docker Desktop

* **General**: activa **“Use the WSL 2 based engine”**.
* **Resources → WSL Integration**: habilita **Ubuntu**.
* **Resources → Advanced**: asigna **4 vCPU** y **6–8 GB RAM** (flujo cómodo con Next.js + Prisma + Postgres).
* **Smoke test**:

  ```powershell
  docker version
  docker info
  docker run --rm hello-world
  ```

> Limpieza prudente: `docker system prune` (verifica antes qué se eliminará).

---

## 0.7 PostgreSQL en contenedor — fija versión

* Evita `latest`. Fija **PostgreSQL 16** por compatibilidad amplia hoy.

  ```powershell
  docker pull postgres:16
  ```

> Si eliges 17, sé consistente en **todos** los entornos (local, CI/CD, cloud).

---

## 0.8 Utilidades opcionales (útiles para el flujo de datos)

* **Cliente psql** en WSL:

  ```bash
  sudo apt update && sudo apt install -y postgresql-client
  psql --version
  ```
* **mkcert** (TLS local), **7-Zip/PeaZip** (backups/exports).
* Prepara un **`.env.example`** (sin credenciales) desde ya.

---

## 0.9 Validaciones finales (checklist)

* [ ] `node -v`, `npm.cmd -v`, `pnpm.cmd -v`, `corepack --version` OK.
* [ ] Política de ejecución decidida o uso de wrappers `.cmd`.
* [ ] **WSL2** por defecto y `wsl --update` aplicado.
* [ ] **Docker Desktop** con engine WSL2 y `hello-world` OK.
* [ ] Imagen Postgres **fijada**: `postgres:16` descargada.
* [ ] **VS Code** con ESLint/Prettier/Docker/**Remote – WSL**.
* [ ] **Git** configurado (nombre/email, `core.autocrlf input`, `core.longpaths true`).
* [ ] Red sin bloqueos a npm y registros de contenedores.

---

### Buenas prácticas (orientadas a SIGECOVIP)

* **Version pinning**: Node LTS, `postgres:16`, acciones de CI (versionadas).
* **Reproducibilidad**: trabaja **dentro de WSL** para evitar sorpresas Win/Unix.
* **Secretos**: nunca comprometer `.env`; usa `.env.example` y define estrategia para CI/Cloud.
* **Espacio Docker**: planifica limpieza/volúmenes (SIGECOVIP almacenará imágenes/archivos).
* **Rendimiento**: monitoriza RAM/CPU asignados a WSL/Docker según crezca la base y el scraping/cargas.

---
