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
4. (Opcional) **Gestor de versiones** (`fnm` o `nvs`) para fijar LTS por proyecto.

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

---

## 0.6 WSL2 y Docker Desktop (imprescindible en Win10 Home)

### 0.6.1 Activar características (PowerShell **Administrador**)

```powershell
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```

Reinicia.

### 0.6.2 Instalar/actualizar WSL

* Instalar Ubuntu (si no la tienes):

  ```powershell
  wsl --install -d Ubuntu
  ```

* Actualizar kernel y fijar WSL2:

  ```powershell
  wsl --update
  wsl --set-default-version 2
  wsl --status
  ```

#### 🔍 Comandos útiles para listar y limpiar distribuciones

* Listar distribuciones instaladas:

  ```powershell
  wsl --list --verbose
  ```
* Eliminar una que no uses:

  ```powershell
  wsl --unregister <NombreDistribucion>
  ```
* Ver espacio usado por cada distro:

  ```powershell
  wsl --system
  ```

### 0.6.3 Instalar y configurar Docker Desktop

* **General**: activa **“Use the WSL 2 based engine”**.
* **Resources → WSL Integration**: habilita **Ubuntu**.
* **Resources → Advanced**: asigna **4 vCPU** y **6–8 GB RAM**.

#### 🔍 Comandos útiles para revisar y limpiar Docker

* Listar imágenes locales:

  ```powershell
  docker images
  ```
* Listar contenedores (activos e inactivos):

  ```powershell
  docker ps -a
  ```
* Eliminar contenedor que no usas:

  ```powershell
  docker rm <container_id>
  ```
* Eliminar imagen que ya no sirve:

  ```powershell
  docker rmi <image_id>
  ```
* Liberar espacio (¡cuidado, revisa antes!):

  ```powershell
  docker system df
  docker system prune -a
  ```

> Esta configuración soporta la infraestructura de pruebas piloto y despliegues CI/CD contemplados en el EVS.

---

## 0.7 PostgreSQL en contenedor — fija versión

* Evita `latest`. Fija **PostgreSQL 16** por compatibilidad.

  ```powershell
  docker pull postgres:16
  ```

---

## 0.8 Utilidades opcionales (útiles para el flujo de datos)

* **Cliente psql** en WSL:

  ```bash
  sudo apt update && sudo apt install -y postgresql-client
  psql --version
  ```

* **mkcert** (TLS local), **7-Zip/PeaZip** (backups/exports).

* **`.env.example`**: obligatorio desde esta fase. Debe incluir todas las variables del sistema **sin credenciales** (ejemplo: `DATABASE_URL`, `NEXTAUTH_URL`, `NEXT_PUBLIC_MAPBOX_TOKEN`).
  👉 Esto responde a los RNF-04 (seguridad de datos) y RNF-06 (compatibilidad tecnológica) definidos en el Charter/ERS.

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
* [ ] **`.env.example` creado** (sin credenciales, obligatorio).
* [ ] **Validar cumplimiento con RNF-06 (compatibilidad tecnológica) y RNF-02 (escalabilidad/disponibilidad)** del Charter/ERS.

---

### Buenas prácticas (orientadas a SIGECOVIP)

* **Version pinning**: Node LTS, `postgres:16`, acciones de CI (versionadas).
* **Reproducibilidad**: trabaja dentro de WSL para evitar sorpresas Win/Unix.
* **Secretos**: nunca comprometer `.env`; usa `.env.example`.
* **Espacio Docker**: planifica limpieza (`docker system prune`) para no saturar disco.
* **Rendimiento**: monitoriza RAM/CPU asignados a WSL/Docker según crezca la base y el scraping/cargas.

---
