## Guía: Acceso por SSH a un Workspace de Bitbucket

### Requisitos previos (para todos los miembros)
- Tener **Git** instalado (en Windows, Git for Windows incluye OpenSSH).
- Tener una terminal disponible (PowerShell, Git Bash o Símbolo del sistema).
- El administrador del Workspace (tú) debe tener permisos de **Admin** en el Workspace para agregar claves SSH.

---

### 1. Generar una llave SSH (cada miembro y tú en su propia máquina)

Cada persona debe ejecutar estos comandos en su computadora. Si tú ya tienes tu llave, puedes saltar a la verificación.

1. Abre una terminal (PowerShell o Git Bash).  
2. Navega a tu carpeta de usuario:
   ```bash
   cd ~
   ```
3. Genera una llave Ed25519 (más segura y recomendada):
   ```bash
   ssh-keygen -t ed25519 -C "nombre-o-email-identificable" -f ~/.ssh/id_ed25519_bitbucket
   ```
   - Puedes cambiar `id_ed25519_bitbucket` por otro nombre descriptivo, como `bitbucket_equipo`.
   - La opción `-C` es un comentario para identificar la llave (usa tu nombre o correo, no es un requisito de Bitbucket).
   - Te preguntará si quieres añadir una contraseña (passphrase). Es opcional pero recomendable para proteger la clave privada. Si la pones, deberás ingresarla cada vez que uses la llave.

   Esto creará dos archivos:
   - **Clave privada** (nunca la compartas): `~/.ssh/id_ed25519_bitbucket`
   - **Clave pública** (se compartirá contigo): `~/.ssh/id_ed25519_bitbucket.pub`

4. Muestra el contenido de la clave pública:
   ```bash
   cat ~/.ssh/id_ed25519_bitbucket.pub
   ```
   Verás una sola línea larga que empieza con `ssh-ed25519 ...`. Esa línea es la que debes copiar íntegra.

---

### 2. Configurar el agente SSH (en Windows, si usas Git Bash)

Si estás en **Git Bash** o PowerShell, puedes agregar la llave al agente para no tener que especificarla manualmente cada vez:

```bash
# Iniciar el agente (si no está corriendo)
eval $(ssh-agent)

# Agregar la llave privada
ssh-add ~/.ssh/id_ed25519_bitbucket
```

Para hacerlo automático en Git Bash, puedes añadir esas líneas a tu archivo `~/.bashrc`.

---

### 3. Agregar la llave pública al Workspace (SOLO EL ADMINISTRADOR)

El administrador del Workspace (tú) debe recopilar todas las claves públicas de los miembros y agregarlas en el panel de Workspace.

1. Inicia sesión en Bitbucket con tu cuenta de administrador.
2. En la barra lateral izquierda, selecciona el **ícono de engranaje** junto al nombre del Workspace (`tecnm-itq-student-jmrd`). Se abrirá la configuración del Workspace.
3. En el menú de la izquierda, haz clic en **SSH keys** (está dentro de la sección "Security" o "Seguridad").
4. Verás una lista de claves ya agregadas. Haz clic en el botón **Add key**.
5. En el formulario:
   - **Label**: Pon un nombre descriptivo para identificar de quién es la llave, por ejemplo: "Laptop de Juan", "PC de María", "Mi PC principal".
   - **Key**: Pega **todo el contenido** de la clave pública (la línea que copiaste del archivo `.pub`), incluyendo el prefijo `ssh-ed25519` y el comentario final.
   - **Expiry**: Déjalo en "No expiry" o establece una fecha de vencimiento si lo deseas.
6. Haz clic en **Add key**.

Repite este paso para cada miembro del equipo (y también para tu propia llave si aún no la habías agregado a nivel Workspace; anteriormente parecía que solo la tenías a nivel repositorio, lo cual daba error de escritura). Las claves de Workspace conceden automáticamente **lectura y escritura** en todos los repositorios del Workspace.

---

### 4. Verificar la conexión SSH (cada miembro)

Después de que hayas agregado la llave pública de la persona, ella debe probar que la autenticación funciona:

```bash
ssh -T git@bitbucket.org
```

Si la llave fue agregada correctamente, verán un mensaje como:

```
authenticated via ssh key.

You can use git to connect to Bitbucket. Shell access is disabled
```

La advertencia sobre *"post-quantum key exchange"* puede aparecer pero es totalmente inofensiva; no afecta la funcionalidad.

Si el mensaje dice `Permission denied (publickey)`, algo falló. Revisa que la clave pública copiada sea exacta (sin saltos de línea extra) y que esté agregada en **Workspace settings → SSH keys** (no solo en el repositorio).

---

### 5. Clonar el repositorio y trabajar con él

Una vez verificada la conexión, cualquier miembro puede clonar el repositorio usando la URL SSH. Tú ya lo hiciste, pero para ellos sería:

```bash
git clone git@bitbucket.org:tecnm-itq-student-jmrd/sirecovip-fullstack.git
```

Luego, dentro de la carpeta del repositorio, pueden hacer cambios, commits y push normalmente:

```bash
cd sirecovip-fullstack
echo "Cambio de prueba" >> prueba.txt
git add prueba.txt
git commit -m "Commit de prueba de SSH"
git push origin main
```

Si todo sale bien, verán `Everything up-to-date` o el conteo de objetos enviados, sin el error `Unauthorized`.

---

### 6. Opcional: forzar el uso de una llave específica por persona

Si alguien tiene múltiples llaves SSH para distintos servicios, puede crear o modificar el archivo `~/.ssh/config` para indicar qué llave usar con Bitbucket. Ejemplo:

```
Host bitbucket.org
  HostName bitbucket.org
  User git
  IdentityFile ~/.ssh/id_ed25519_bitbucket
  AddKeysToAgent yes
```

Con esto, Git siempre usará la llave correcta.

---

### Resumen de responsabilidades

| Rol              | Acción |
|------------------|--------|
| **Administrador** | Recibir las claves públicas del equipo, agregarlas en **Workspace settings → SSH keys**, verificar que el rol del Workspace y repositorio permita escritura a "everyone" o a usuarios (en este caso las claves de Workspace funcionan sin usuarios). |
| **Cada miembro**  | Generar su par de llaves, enviar el `.pub` al administrador, configurar su agente SSH, y clonar/trabajar con la URL SSH. |

---

Con estos pasos tu equipo podrá colaborar directamente sin necesidad de crear cuentas de Bitbucket, y tú mantienes el control de quién puede escribir en el repositorio agregando o eliminando sus claves SSH del Workspace. ¡Todo listo!
