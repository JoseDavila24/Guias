# Fase 0 — Preparación del entorno en Windows 10 Home (técnico/profesional)

> Objetivo: dejar el equipo listo para desarrollar SIGECOVIP con **Create-T3-App (Next.js + TypeScript + tRPC + Prisma + Tailwind)**, **PostgreSQL en Docker**, e integraciones modulares (Mapbox/Firebase) bajo el enfoque **Opción C (híbrida)** que ya definiste en tus documentos.

---

## 0.1 Requisitos del sistema

* **Windows 10 Home** actualizado (20H2+ recomendado).
* CPU con **virtualización** habilitada (Intel VT-x/AMD-V) en BIOS/UEFI.
* 16 GB RAM (mínimo 8 GB), 30+ GB libres en disco.
* Conectividad de red sin bloqueo a `registry.npmjs.org` y `ghcr.io`.

> En el Manual Técnico registra: versión de Windows, CPU, RAM, disco y confirmación de virtualización.

---

## 0.2 PowerShell y política de ejecución

Para evitar bloqueos al usar herramientas **pnpm/npx** en PS:

* Opción segura (por sesión):

  ```powershell
  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
  ```
* Opción persistente (recomendada para tu usuario):

  ```powershell
  Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
  ```

> Nota: Siempre puedes invocar **`pnpm.cmd`** para saltar restricciones si fuese necesario.

---

## 0.3 Node.js + Corepack (pnpm)

1. **Instala Node.js LTS** (o superior).
2. **Habilita Corepack** y activa pnpm:

   ```powershell
   corepack enable
   corepack prepare pnpm@latest --activate
   pnpm.cmd -v
   ```

   Si quieres usar `pnpm` (sin `.cmd`), asegúrate de haber aplicado 0.2.

**Comprobaciones**

```powershell
node -v
npm -v
corepack --version
pnpm.cmd -v
```

---

## 0.4 Git y GitHub CLI

1. **Instala Git** (habilita “Git from command line”).
2. Configura identidad global:

   ```powershell
   git config --global user.name  "Tu Nombre"
   git config --global user.email "tu@email"
   git config --global init.defaultBranch main
   ```
3. **GitHub CLI (opcional, recomendado)**:

   ```powershell
   gh --version
   gh auth login
   ```

---

## 0.5 VS Code y extensiones

* **VS Code** actualizado.
* Extensiones mínimas:

  * **ESLint**, **Prettier**, **Prisma**, **Tailwind CSS IntelliSense**, **Docker**, **GitHub Actions**.
* Ajustes recomendados (`.vscode/settings.json` del repo más adelante):

  * `"editor.formatOnSave": true`
  * `"eslint.validate": ["typescript","typescriptreact","javascript"]`

---

## 0.6 WSL2 y Docker Desktop (imprescindible en Win10 Home)

### 0.6.1 Activar características de Windows

Ejecuta PowerShell **Administrador**:

```powershell
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```

Reinicia.

### 0.6.2 Instalar distribución WSL y configurar WSL2

```powershell
wsl --install -d Ubuntu
wsl --set-default-version 2
wsl --status
```

### 0.6.3 Instalar y configurar Docker Desktop

* En **Settings → General**: activa **“Use the WSL 2 based engine”**.
* En **Resources → WSL Integration**: habilita tu distro (Ubuntu).
* En **Resources → Advanced**: reserva **CPU/RAM** (ej. 4 vCPU / 6-8 GB) para cargas con Postgres, Prisma y el frontend.

**Pruebas rápidas Docker**

```powershell
docker version
docker info
docker run --rm hello-world
docker pull postgres:16
```

> Tu arquitectura (Docker + PostgreSQL) está alineada al diseño y RNF de compatibilidad y escalabilidad definidos.

---

## 0.7 Utilidades opcionales (recomendadas)

* **7-Zip** o **PeaZip** (manejo de backups/exports).
* **mkcert** (TLS local, si pruebas HTTPS).
* **PostgreSQL client** (`psql`) dentro de WSL o contenedor:

  ```bash
  # en Ubuntu (WSL)
  sudo apt update && sudo apt install -y postgresql-client
  psql --version
  ```

---

## 0.8 Validaciones finales (checklist)

* [ ] `node -v`, `npm -v`, `pnpm.cmd -v`, `corepack --version` OK.
* [ ] PS con ExecutionPolicy ajustada (o decidido usar `pnpm.cmd`).
* [ ] Docker Desktop operativo con WSL2 engine; `docker run hello-world` OK.
* [ ] Imagen `postgres:16` descargada.
* [ ] VS Code con extensiones instaladas.
* [ ] Git configurado (`git config --global --list`).
* [ ] (Opcional) `gh auth login` realizado.

> **Registro en Manual Técnico** (sección “Requisitos del entorno”): versiones instaladas, política de ejecución adoptada, capturas de `docker info` y `pnpm.cmd -v`, y observaciones de red/seguridad. Esta sección conecta con el stack y compatibilidad documentados en ERS/Manual.

---

## 0.9 Notas operativas (riesgos tempranos)

* **Antivirus/Firewall corporativo**: puede interferir con `registry.npmjs.org` o sockets Docker. Documenta exclusiones si aplica.
* **Espacio en disco**: Docker y volúmenes de Postgres crecen; planifica limpieza con `docker system prune` (con cuidado).
* **Telemetría/privacidad**: registra en el Manual cómo se resguardarán `.env` y secretos (se usan en fases siguientes).

---
