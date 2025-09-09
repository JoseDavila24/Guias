# Guía pulida: Windows + PowerShell + Cookiecutter + GitHub

## 0) Requisitos (una vez)

* **Python 3.11/3.12** instalado y en PATH (`python --version`).
* **PowerShell** (abre normal; para cambiar políticas, ábrelo como administrador).
* **Git** (`git --version`).
* (Opcional) **GitHub CLI** `gh` (`gh --version`) para automatizar GitHub.

---

## 1) Carpeta base y venv global (solo generadores)

```powershell
# Ir a tu carpeta de usuario (ej. C:\Users\Jose)
cd $env:USERPROFILE

# Crear carpeta “contenedor” de proyectos
mkdir PythonProjects
cd PythonProjects

# Crear venv global para HERRAMIENTAS (cookiecutter, copier, poetry, etc.)
python -m venv global-venv

# Activar (sin tocar políticas):
.\global-venv\Scripts\activate.bat
# (Alternativa) Activar con .ps1 (si habilitas scripts locales una sola vez):
#   - Abre PowerShell como Administrador y ejecuta:
#     Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
#   - Luego:
#     .\global-venv\Scripts\Activate.ps1
```

Instala generadores en ese venv global:

```powershell
pip install --upgrade pip
pip install cookiecutter copier poetry hatch
```

> Este `global-venv` es **solo** para crear scaffolds. Cada proyecto tendrá su **propio** `.venv`.

---

## 2) Generar un proyecto con plantilla completa

Usaremos **cookiecutter-pypackage** (estándar y sólida):

```powershell
cd $env:USERPROFILE\PythonProjects
cookiecutter https://github.com/audreyfeldroy/cookiecutter-pypackage
```

### Respuestas sugeridas (adaptadas a Drawio Generator)

* `full_name`: **José Romero**
* `email`: **[tu\_correo@ejemplo.com](mailto:tu_correo@ejemplo.com)**
* `github_username`: **romerodavilajm**
* `project_name`: **Drawio Generator**
* `pypi_package_name`: **drawio-generator**  *(minúsculas con guiones)*
* `project_slug`: **drawio\_generator**        *(minúsculas con guion\_bajo)*
* `project_short_description`: **CLI tool that converts photos of diagrams into editable .drawio files**
* `pypi_username`: **romerodavilajm**
* `version`: **0.1.0**
* Licencia: **MIT** (bien por defecto)

Estructura esperada (resumen):

```
drawio-generator/
├─ .github/workflows/
├─ docs/
├─ src/drawio_generator/
├─ tests/
├─ pyproject.toml
└─ README.md
```

---

## 3) Crear y usar el venv del proyecto

> De aquí en adelante, **ya no uses** el venv global: úsalo solo para generar plantillas.

```powershell
cd $env:USERPROFILE\PythonProjects\drawio-generator

# Crear venv del proyecto
python -m venv .venv

# Activar (elige una opción)
.\.venv\Scripts\activate.bat
# o (si habilitaste RemoteSigned alguna vez)
# .\.venv\Scripts\Activate.ps1
```

Instalar dependencias (incluye dev si la plantilla las define):

```powershell
pip install --upgrade pip
pip install -e ".[dev]"
```

> Si `pytest` no aparece, instálalo explícitamente:
> `pip install pytest`

---

## 4) Probar tests mínimos

Si no hay tests, crea uno rápido:

`tests/test_smoke.py`

```python
def test_smoke():
    assert True
```

Ejecuta:

```powershell
pytest
```

Deberías ver tests pasando ✅.

---

## 5) (Opcional) CLI mínimo

Crea `src/drawio_generator/cli.py`:

```python
import click

@click.command()
@click.argument("input_image", required=False)
def main(input_image: str | None = None):
    msg = f"Procesando {input_image}" if input_image else "CLI ok, sin archivo."
    click.echo(f"[drawio-generator] {msg}")

if __name__ == "__main__":
    main()
```

Registra el entrypoint en `pyproject.toml` (si no lo trae):

```toml
[project.scripts]
drawio-gen = "drawio_generator.cli:main"
```

(Re)instala editable si tocaste `pyproject.toml`:

```powershell
pip install -e .
```

Prueba:

```powershell
drawio-gen
drawio-gen input.jpg
```

Test rápido para el CLI:

`tests/test_cli.py`

```python
from click.testing import CliRunner
from drawio_generator.cli import main

def test_cli_runs():
    r = CliRunner().invoke(main, [])
    assert r.exit_code == 0
    assert "[drawio-generator]" in r.output
```

Corre:

```powershell
pytest
```

---

## 6) Flujo diario recomendado

1. Abrir PowerShell.
2. `cd $env:USERPROFILE\PythonProjects\drawio-generator`
3. Activar venv del proyecto: `.\.venv\Scripts\activate.bat`
4. Trabajar (editar, `pytest`, etc.).
5. Salir: `deactivate`.

---

# Publicar en GitHub de forma eficiente

Tienes **dos caminos**: con **GitHub CLI (`gh`)** o “a mano” con `git` + web.

## A) Con GitHub CLI (rápido y automatizado)

Primero, autentícate una vez:

```powershell
gh auth login
# Sigue el asistente (GitHub.com, HTTPS, abrir navegador, etc.)
```

Desde la raíz del proyecto:

```powershell
# Inicializar repo si aún no lo es
git init
git add .
git commit -m "chore: initial scaffold (cookiecutter-pypackage)"

# Crear el repo remoto en tu cuenta y empujar todo
gh repo create romerodavilajm/drawio-generator --private --source=. --remote=origin --push

# (Opcional) Crear rama de desarrollo y empujarla
git switch -c dev
git push -u origin dev
```

### Recomendado: protección de ramas y PRs (desde la web)

* En GitHub → **Settings → Branches → Add rule** a `main`:

  * Require a pull request before merging (1 review mínimo).
  * Require status checks to pass (tu workflow en `.github/workflows` ya corre CI en PRs).
* Activa **Actions** si te pide permiso la primera vez.

### Flujos útiles con `gh`

* Crear PR desde `dev` a `main`:

  ```powershell
  gh pr create --base main --head dev --title "feat: initial CLI" --body "Adds CLI stub and tests"
  ```

* Ver/merge PRs:

  ```powershell
  gh pr status
  gh pr view --web
  gh pr merge --merge
  ```

* Crear release (tag) cuando tengas una versión estable:

  ```powershell
  git switch main
  git pull
  # Actualiza versión en pyproject.toml si aplica
  git commit -am "chore: bump version to 0.1.0"
  git tag v0.1.0
  git push origin main --tags
  gh release create v0.1.0 --title "v0.1.0" --notes "First public seed"
  ```

## B) Sin GitHub CLI (manual con `git` + web)

1. Crea un repo vacío en GitHub (tú eliges privado/público).
2. Copia la URL del remoto (HTTPS).
3. En el proyecto local:

```powershell
git init
git add .
git commit -m "chore: initial scaffold (cookiecutter-pypackage)"
git branch -M main
git remote add origin https://github.com/romerodavilajm/drawio-generator.git
git push -u origin main

# (opcional) rama dev
git switch -c dev
git push -u origin dev
```

4. Configura **Branch protection** en `main` (igual que arriba).
5. Abre un **Pull Request** de `dev` → `main` desde la web.

---

## Buenas prácticas extra (opcionales pero útiles)

* **Conventional Commits**: `feat:`, `fix:`, `docs:`, `chore:`, etc.
* **Pre-commit hooks** (si no vienen):

  ```powershell
  pip install pre-commit ruff black isort
  pre-commit install
  ```
* **CI**: asegúrate que `.github/workflows` tenga un workflow que corra `pytest` y linters en PRs.
* **README**: añade comandos rápidos (activar venv, instalar deps, correr tests, usar CLI).
* **LICENSE**: MIT facilita contribuciones.
* **Issues/Projects**: crea issues iniciales y un board (To do / In progress / Done).

---

## Diagnóstico rápido (si algo falla)

* **No puedes activar `.ps1`** → usa `.bat` o corre **una vez**:
  `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`
* **`pytest` no existe** → el venv del proyecto no está activo **o** falta instalar:
  `.\.venv\Scripts\activate.bat` y luego `pip install -e ".[dev]"` (o mínimo `pip install pytest`)
* **CI no corre en GitHub** → revisa que exista `.github/workflows/*.yml` y que Actions esté habilitado en el repo.

