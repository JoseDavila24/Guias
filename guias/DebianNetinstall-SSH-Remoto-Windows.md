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

## 🔐 2. Accede como root e instala `sudo` (si es necesario)

```bash
su -
apt update
apt install sudo
usermod -aG sudo jose
exit
```

> `sudo` permite que tu usuario normal ejecute comandos administrativos sin usar root directamente (más seguro y práctico).

---

## 📦 3. Instalar y configurar OpenSSH Server

### (Si no lo instalaste durante la instalación)

```bash
sudo apt install openssh-server
sudo systemctl enable ssh
sudo systemctl start ssh
```

> Esto instala el servicio SSH, lo activa y lo inicia automáticamente en cada arranque, permitiendo el acceso remoto.

---

## 🌐 4. Obtener IP de tu sistema Debian

```bash
ip a
```

> Necesitas saber la IP para conectarte remotamente desde otra máquina. Asegúrate de estar en la **misma red local**.

---

## 🔒 5. Fortalecer SSH (hardenización)

Edita la configuración:

```bash
sudo nano /etc/ssh/sshd_config
```

Agrega o ajusta estas líneas:

```ini
Port 2222
PermitRootLogin no
PasswordAuthentication yes
PermitEmptyPasswords no
AllowUsers jose
UseDNS no
```

### ¿Por qué?

* `Port 2222`: Cambia el puerto por defecto 22 para evitar bots automatizados.
* `PermitRootLogin no`: Evita accesos directos como root, aumenta la seguridad.
* `PasswordAuthentication yes`: Permite iniciar sesión con contraseña (puedes desactivarlo más adelante si usas solo claves).
* `AllowUsers jose`: Restringe quién puede iniciar sesión por SSH.
* `UseDNS no`: Evita demoras por resolución inversa de DNS.

Reinicia el servicio:

```bash
sudo systemctl restart ssh
```

> Aplicará los cambios inmediatamente.

---

## 🛡️ 6. Activar firewall UFW (opcional pero recomendado)

```bash
sudo apt install ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 2222/tcp
sudo ufw enable
```

> UFW ("Uncomplicated Firewall") protege tu sistema limitando conexiones entrantes. Solo el puerto 2222 (SSH) estará abierto.

---

## 🔑 7. (Opcional) Configurar acceso sin contraseña con clave SSH

### En tu PC cliente (Linux/macOS/WSL):

```bash
ssh-keygen -t ed25519
ssh-copy-id -p 2222 jose@192.168.1.105
```

> Las claves SSH son mucho más seguras que las contraseñas. Además, te permiten conectarte automáticamente sin escribirla cada vez.

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

> Este script se ejecutará cada vez que te conectes, mostrando un resumen útil del sistema al iniciar sesión.

---

## 💻 9. Conexión remota por SSH desde otro equipo Linux/macOS

```bash
ssh -p 2222 jose@192.168.1.105
```

> Te conecta directamente al sistema Debian desde otra máquina, usando tu nombre de usuario.

---

## 🪟 10. CONEXIÓN DESDE **WINDOWS**

### 🔹 OPCIÓN A: PowerShell o CMD (sin instalar nada)

1. Abre **PowerShell** o **CMD**
2. Ejecuta:

```powershell
ssh -p 2222 jose@192.168.1.105
```

> Windows 10/11 incluye `ssh` por defecto. Esta es la forma más rápida de conectarte por consola sin instalar software adicional.

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

> PuTTY es útil si prefieres interfaz gráfica o trabajas en una versión antigua de Windows sin cliente SSH.

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

> Estas herramientas te permiten administrar, monitorear, automatizar y manipular el sistema desde la terminal de manera eficiente.

---
