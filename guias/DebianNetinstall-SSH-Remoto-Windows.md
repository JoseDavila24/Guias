# 🧰 GUÍA COMPLETA: Debian Netinstall + SSH Remoto + Conexión desde Windows

## 🔧 1. Instalar Debian Netinstall (Minimal, sin GUI)

### ✅ Requisitos:

* ISO: [https://www.debian.org/distrib/netinst](https://www.debian.org/distrib/netinst)
* Crea USB booteable con `Rufus` o `dd`
* Conecta a red por cable (mejor compatibilidad)

### ⚙️ Durante la instalación:

* Desmarca **"Entorno de escritorio Debian"**
* Solo selecciona:

  * “Utilidades estándar del sistema”
  * “Servidor SSH” ✅ (si no lo hiciste, lo instalas luego)

---

## 🔐 2. Accede como root e instala sudo (si es necesario)

```bash
su -
apt update
apt install sudo
usermod -aG sudo jose
exit
```

---

## 📦 3. Instalar y configurar OpenSSH Server

### (Si no lo instalaste durante la instalación)

```bash
sudo apt install openssh-server
sudo systemctl enable ssh
sudo systemctl start ssh
```

---

## 🌐 4. Obtener IP de tu sistema Debian

```bash
ip a
```

Busca una línea como:

```
inet 192.168.1.105/24
```

---

## 🔒 5. Fortalecer SSH (hardenización)

Edita la configuración:

```bash
sudo nano /etc/ssh/sshd_config
```

Asegúrate de que contenga:

```ini
Port 2222
PermitRootLogin no
PasswordAuthentication yes
PermitEmptyPasswords no
AllowUsers jose
UseDNS no
```

Reinicia SSH:

```bash
sudo systemctl restart ssh
```

---

## 🛡️ 6. Activar firewall UFW (opcional)

```bash
sudo apt install ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 2222/tcp
sudo ufw enable
```

---

## 🔑 7. (Opcional) Configurar acceso sin contraseña con clave SSH

### En tu PC cliente (Linux/macOS/WSL):

```bash
ssh-keygen -t ed25519
ssh-copy-id -p 2222 jose@192.168.1.105
```

---

## 🧠 8. Crear un mini dashboard CLI al conectarte por SSH

Edita:

```bash
nano ~/.bash_profile
```

Y agrega:

```bash
clear
echo "🖥️  Bienvenido, $USER"
echo "📅 Fecha: $(date)"
echo "🌐 IP: $(hostname -I)"
echo "💡 Uptime: $(uptime -p)"
echo "🧠 RAM libre: $(free -h | grep Mem | awk '{print $4}')"
echo "💾 Espacio libre:"
df -h | grep '^/dev/'
echo "📊 Carga: $(uptime | awk -F'load average:' '{ print $2 }')"
```

---

## 💻 9. Conexión remota por SSH desde otro equipo Linux/macOS

```bash
ssh -p 2222 jose@192.168.1.105
```

---

## 🪟 10. CONEXIÓN DESDE **WINDOWS**

### 🔹 OPCIÓN A: PowerShell o CMD

1. Abre **PowerShell** o **CMD**
2. Ejecuta:

```powershell
ssh -p 2222 jose@192.168.1.105
```

> Te pedirá contraseña o usará tu clave si la configuraste.

---

### 🔹 OPCIÓN B: Usar **PuTTY** (interfaz gráfica)

1. Descarga desde: [https://www.putty.org/](https://www.putty.org/)
2. Abre `putty.exe`
3. Configura:

   * **Host Name**: `192.168.1.105`
   * **Port**: `2222`
   * **Connection Type**: SSH
4. Clic en **Open**
5. Inicia sesión como `jose`

> (Opcional) Puedes guardar sesión en PuTTY para acceder con doble clic.

---

## 🧪 Verifica tu conexión

Desde Windows (PowerShell):

```powershell
ssh -p 2222 jose@192.168.1.105
```

Desde Linux/macOS:

```bash
ssh -p 2222 jose@192.168.1.105
```

---

## 🎯 Extras recomendados

Instala herramientas CLI útiles:

```bash
sudo apt install vim htop curl wget git rsync tmux net-tools ufw
```

---
