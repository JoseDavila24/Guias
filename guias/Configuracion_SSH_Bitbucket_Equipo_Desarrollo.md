# Guía: Acceso por SSH a un Workspace de Bitbucket

Basado en la documentación oficial y lo que acabas de comprobar que funciona.

---

## Requisitos previos (para todos los miembros)

- Tener **Git for Windows** instalado (incluye Git Bash y OpenSSH).
- Usar **Git Bash** como terminal (PowerShell da problemas con rutas y el ssh-agent).
- El administrador del Workspace debe tener permisos de **Admin** para agregar claves SSH.

---

## 1. Generar una llave SSH (cada miembro en su máquina)

Cada persona abre **Git Bash** y ejecuta:

```bash
# Navegar a la carpeta home
cd ~

# Generar la llave Ed25519
ssh-keygen -t ed25519 -b 4096 -C "nombre-o-email-identificable" -f ~/.ssh/id_ed25519_bitbucket
```

**Explicación de las opciones:**
- `-t ed25519`: Tipo de llave (la más segura y recomendada por Bitbucket).
- `-b 4096`: Tamaño en bits (recomendado por la documentación oficial).
- `-C "comentario"`: Etiqueta para identificar tu llave (usa tu nombre o correo).
- `-f ~/.ssh/id_ed25519_bitbucket`: Ruta y nombre del archivo.

**Cuando pregunte "Enter passphrase":**
- Puedes dejarlo vacío (presiona Enter) o poner una contraseña.
- Si pones contraseña, deberás ingresarla cada vez que uses la llave.
- Es recomendable para mayor seguridad.

**Resultado:** Se crean dos archivos:
- `~/.ssh/id_ed25519_bitbucket` → Clave **privada** (⚠️ nunca la compartas)
- `~/.ssh/id_ed25519_bitbucket.pub` → Clave **pública** (esta se comparte)

---

## 2. Mostrar la clave pública

```bash
cat ~/.ssh/id_ed25519_bitbucket.pub
```

Copia **toda la línea** (debe empezar con `ssh-ed25519` y terminar con tu comentario).

---

## 3. Iniciar el SSH Agent y agregar la llave

```bash
# Iniciar el agente SSH
eval $(ssh-agent)

# Agregar tu llave privada al agente
ssh-add ~/.ssh/id_ed25519_bitbucket
```

**Para que el agente se inicie automáticamente** cada vez que abras Git Bash:

```bash
echo 'eval $(ssh-agent)' >> ~/.bashrc
```

---

## 4. Configurar el archivo SSH config

Crea o edita el archivo de configuración:

```bash
nano ~/.ssh/config
```

Agrega este contenido:

```
Host bitbucket.org
  AddKeysToAgent yes
  IdentityFile ~/.ssh/id_ed25519_bitbucket
```

Guarda con `Ctrl+O` → `Enter` → `Ctrl+X`.

Verifica que se guardó:

```bash
cat ~/.ssh/config
```

---

## 5. Agregar la clave pública al Workspace (ADMIN)

El administrador debe hacer esto por cada miembro:

1. Inicia sesión en [bitbucket.org](https://bitbucket.org)
2. Ve al Workspace → **Settings** (ícono de engrane) en la barra lateral
3. En el menú izquierdo, bajo **Security**, haz clic en **SSH keys**
4. Haz clic en **Add key**
5. Completa:
   - **Label**: Nombre descriptivo (ej: "Laptop de Juan", "PC María")
   - **Key**: Pega **todo** el contenido de la clave pública
   - **Expiry**: Selecciona **No expiry** (o establece una fecha)
6. Haz clic en **Add key**

---

## 6. Verificar la conexión SSH (cada miembro)

```bash
ssh -T git@bitbucket.org
```

**Respuesta esperada:**
```
authenticated via ssh key.

You can use git to connect to Bitbucket. Shell access is disabled
```

Si ves `Permission denied (publickey)`, verifica:
- Que la clave pública se copió completa (sin saltos de línea)
- Que se agregó en **Workspace settings → SSH keys** (no en el repositorio)

---

## 7. Clonar y trabajar con el repositorio

```bash
# Clonar usando SSH
git clone git@bitbucket.org:tecnm-itq-student-jmrd/sirecovip-fullstack.git

# Entrar al repositorio
cd sirecovip-fullstack

# Hacer cambios y subirlos
echo "Cambio de prueba" >> prueba.txt
git add prueba.txt
git commit -m "Commit de prueba SSH"
git push origin main
```

---

## Resumen de comandos (lista rápida)

| Paso | Comando |
|------|---------|
| Crear llave | `ssh-keygen -t ed25519 -b 4096 -C "tu-email" -f ~/.ssh/id_ed25519_bitbucket` |
| Ver clave pública | `cat ~/.ssh/id_ed25519_bitbucket.pub` |
| Iniciar agente | `eval $(ssh-agent)` |
| Agregar llave | `ssh-add ~/.ssh/id_ed25519_bitbucket` |
| Auto-iniciar agente | `echo 'eval $(ssh-agent)' >> ~/.bashrc` |
| Probar conexión | `ssh -T git@bitbucket.org` |
| Clonar repo | `git clone git@bitbucket.org:workspace/repositorio.git` |
