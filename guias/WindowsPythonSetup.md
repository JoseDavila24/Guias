# 🚀 Guía: Proyectos Python en Windows (PowerShell + Cookiecutter + GitHub)

## 0) Requisitos (solo una vez)

* **Python 3.11/3.12** instalado y en PATH

  ```powershell
  python --version
  ```
* **PowerShell** (abre normal; como admin solo si ajustas políticas).
* **Git**

  ```powershell
  git --version
  ```
* (Opcional) **GitHub CLI** (`gh`)

  ```powershell
  gh --version
  ```

---

## 1) Carpeta base + venv global (solo para generadores)

```powershell
# Ir a tu carpeta de usuario
cd $env:USERPROFILE

# Crear carpeta de proyectos
mkdir PythonProjects
cd PythonProjects

# Crear venv global para herramientas (cookiecutter, poetry, hatch, etc.)
python -m venv global-venv

# Activar (sin modificar políticas)
.\global-venv\Scripts\activate.bat
# Alternativa con .ps1 (si habilitaste RemoteSigned una vez):
#   Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
#   .\global-venv\Scripts\Activate.ps1
```

Instalar generadores:

```powershell
pip install --upgrade pip
pip install cookiecutter copier poetry hatch
```

👉 Este `global-venv` es **solo para scaffolds**. Cada proyecto tendrá su propio `.venv`.

---

## 2) Crear un proyecto con Cookiecutter

Ejemplo con [cookiecutter-pypackage](https://github.com/audreyfeldroy/cookiecutter-pypackage):

```powershell
cd $env:USERPROFILE\PythonProjects
cookiecutter https://github.com/audreyfeldroy/cookiecutter-pypackage
```

Responde los prompts según tu proyecto (nombre, email, descripción, etc.).

Estructura típica generada:

```
mi-paquete/
├─ .github/workflows/
├─ docs/
├─ src/mi_paquete/
├─ tests/
├─ pyproject.toml
└─ README.md
```

---

## 3) Crear y usar el venv del proyecto

```powershell
cd $env:USERPROFILE\PythonProjects\mi-paquete

# Crear venv
python -m venv .venv

# Activar
.\.venv\Scripts\activate.bat
# o (si habilitaste RemoteSigned)
# .\.venv\Scripts\Activate.ps1
```

Instalar dependencias:

```powershell
pip install --upgrade pip
pip install -e ".[dev]"
```

(Si falta algo como `pytest`, instálalo manualmente: `pip install pytest`).

---

## 4) Usar `requirements.txt` (recomendado)

Para que tus colaboradores no tengan que recordar `-e ".[dev]"`, crea en la raíz del proyecto un archivo **requirements.txt** con este contenido:

```txt
-e .[dev]
```

De esta forma, en cualquier sistema (Windows/Linux/Mac) basta con:

```bash
pip install -r requirements.txt
```

y se instalarán tanto tu proyecto como las dependencias de desarrollo.

---

## 5) Probar con tests mínimos

`tests/test_smoke.py`:

```python
def test_smoke():
    assert True
```

Ejecutar:

```powershell
pytest
```

Deberías ver ✅.

---

## 6) CLI mínimo (opcional)

Archivo `src/mi_paquete/cli.py`:

```python
import click

@click.command()
@click.argument("name", required=False)
def main(name: str | None = None):
    msg = f"Hola, {name}" if name else "CLI funcionando sin argumentos."
    click.echo(f"[mi-paquete] {msg}")

if __name__ == "__main__":
    main()
```

En `pyproject.toml`:

```toml
[project.scripts]
mi-cli = "mi_paquete.cli:main"
```

Reinstalar editable:

```powershell
pip install -e .
```

Probar:

```powershell
mi-cli
mi-cli Mundo
```

---

## 7) Flujo diario recomendado

1. Abrir PowerShell.
2. Ir al proyecto:

   ```powershell
   cd $env:USERPROFILE\PythonProjects\mi-paquete
   ```
3. Activar venv:

   ```powershell
   .\.venv\Scripts\activate.bat
   ```
4. Instalar dependencias (si eres colaborador nuevo o cambió `requirements.txt`):

   ```powershell
   pip install -r requirements.txt
   ```
5. Trabajar (editar código, `pytest`, etc.).
6. Salir:

   ```powershell
   deactivate
   ```

---

# Publicar en GitHub

## A) Con GitHub CLI (`gh`)

Autenticación inicial:

```powershell
gh auth login
```

Crear repo y subir:

```powershell
git init
git add .
git commit -m "chore: initial scaffold"
gh repo create usuario/mi-paquete --private --source=. --remote=origin --push
```

Opcional: rama dev

```powershell
git switch -c dev
git push -u origin dev
```

---

## B) Sin GitHub CLI (manual)

1. Crear repo vacío en GitHub.
2. Copiar URL HTTPS.
3. En local:

```powershell
git init
git add .
git commit -m "chore: initial scaffold"
git branch -M main
git remote add origin https://github.com/usuario/mi-paquete.git
git push -u origin main
```

---

## Extras recomendados

* **Conventional Commits** (`feat:`, `fix:`, `docs:`, etc.).
* **Pre-commit hooks**:

  ```powershell
  pip install pre-commit ruff black isort
  pre-commit install
  ```
* **CI**: workflows en `.github/workflows` para tests y linters.
* **README**: explica instalación, uso y tests.
* **LICENSE**: MIT suele ser lo más práctico.
* **Branch protection**: regla en `main` que requiera PRs y CI.

---

## Diagnóstico rápido

* **No puedes activar `.ps1`** → usa `.bat` o ejecuta una vez:

  ```powershell
  Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
  ```
* **No funciona `pytest`** → revisa que activaste `.venv` y corriste:

  ```powershell
  pip install -r requirements.txt
  ```
* **CI no corre en GitHub** → asegúrate de tener `.github/workflows/*.yml` y habilitar *Actions*.

---
