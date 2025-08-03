# 🧩 Guía Universal para Activar y Usar SSH (Windows & Linux)

## ✅ 1. ¿Qué es SSH y para qué sirve?

**SSH (Secure Shell)** es un protocolo que permite conectarse de forma segura a otro equipo remoto para administrar, transferir archivos o ejecutar comandos, todo desde una terminal o aplicación gráfica.

---

## 🛠️ 2. Requisitos generales

* Acceso a un sistema que **actúe como servidor** (Linux, Windows, WSL).
* Otro sistema que se usará como **cliente SSH**.
* Ambos deben estar en la **misma red local** o tener direcciones IP públicas accesibles.

---

## 📦 3. Activar o instalar el servidor SSH

### 🔸 En Linux (cualquier distribución):

1. Instala el servicio OpenSSH:

   ```bash
   sudo apt install openssh-server     # Debian/Ubuntu
   sudo dnf install openssh-server     # Fedora/RHEL
   sudo pacman -S openssh              # Arch
   ```

2. Activa y arranca el servicio:

   ```bash
   sudo systemctl enable ssh
   sudo systemctl start ssh
   ```

3. Verifica que esté activo:

   ```bash
   sudo systemctl status ssh
   ```

---

### 🔸 En Windows (opciones posibles):

#### Opción A: Activar el servidor SSH nativo (Windows 10/11 Pro)

1. Abre PowerShell como administrador.
2. Ejecuta:

   ```powershell
   Add-WindowsCapability -Online -Name OpenSSH.Server
   Start-Service sshd
   Set-Service -Name sshd -StartupType 'Automatic'
   ```

> Esto habilita el servidor SSH de forma permanente.

#### Opción B: Usar WSL (Windows Subsystem for Linux)

Si tienes una distro Linux en WSL (como Ubuntu):

1. Instala el servidor SSH en WSL:

   ```bash
   sudo apt install openssh-server
   sudo service ssh start
   ```

> Solo funciona dentro del entorno WSL, ideal para pruebas.

---

## 🔒 4. Configurar parámetros de seguridad

Edición del archivo (solo en Linux):

```bash
sudo nano /etc/ssh/sshd_config
```

Recomendaciones:

```ini
Port 2222                   # Cambia el puerto (opcional)
PermitRootLogin no          # No permitir acceso como root
PasswordAuthentication yes  # Permitir contraseña (puedes cambiar luego)
PermitEmptyPasswords no
AllowUsers tu_usuario       # (opcional) Restringir usuarios autorizados
UseDNS no
```

Reinicia el servicio para aplicar los cambios:

```bash
sudo systemctl restart ssh
```

---

## 🌐 5. Conocer la IP del servidor

En Linux:

```bash
ip a   # o bien: hostname -I
```

En Windows:

```powershell
ipconfig
```

> Necesitarás esta IP para conectarte desde otro dispositivo.

---

## 🔐 6. (Opcional) Autenticación sin contraseña con clave SSH

En el **cliente** (Linux, macOS, WSL o PowerShell con OpenSSH):

1. Genera una clave:

   ```bash
   ssh-keygen -t ed25519
   ```

2. Copia la clave al servidor:

   ```bash
   ssh-copy-id -p 2222 usuario@ip-del-servidor   # En Linux
   ```

> En Windows, puedes copiar manualmente el contenido de `~/.ssh/id_ed25519.pub` al archivo `~/.ssh/authorized_keys` del servidor.

---

## 🪟 7. Conexión desde Windows

### ✅ Opción A: PowerShell o CMD

```powershell
ssh -p 2222 usuario@192.168.1.X
```

> SSH ya viene instalado en Windows 10/11 por defecto.

---

### ✅ Opción B: Cliente gráfico PuTTY

1. Descarga desde: [https://www.putty.org](https://www.putty.org)

2. Configura:

   * Host Name: `192.168.1.X`
   * Port: `2222`
   * Connection Type: `SSH`

3. Clic en **Open**, inicia sesión con tu usuario.

---

## 🐧 8. Conexión desde Linux/macOS

```bash
ssh -p 2222 usuario@192.168.1.X
```

---

## 🔐 9. Activar Firewall (opcional, recomendado)

### En Linux (UFW como ejemplo):

```bash
sudo apt install ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 2222/tcp
sudo ufw enable
```

### En Windows:

* Usa el **Firewall de Windows Defender** para permitir el puerto 2222 TCP.

---

## 📊 10. (Opcional) Dashboard en la terminal

En Linux/macOS/WSL, edita `~/.bash_profile` o `~/.bashrc`:

```bash
clear
echo "🖥️  $HOSTNAME - $USER"
echo "📅 Fecha: $(date)"
echo "💡 Uptime: $(uptime -p)"
echo "📈 Carga: $(uptime | awk -F'load average:' '{ print $2 }')"
```

---

## 🧪 Verifica tu conexión

Desde cualquier cliente compatible:

```bash
ssh -p 2222 usuario@192.168.1.X
```

---

## 🧰 Extras recomendados para administración remota (Linux)

```bash
sudo apt install vim htop curl wget git rsync tmux net-tools
```
