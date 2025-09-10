# Guía Básica y Universal para Activar y Utilizar SSH

## 1. Introducción: ¿Qué es SSH?

**SSH (Secure Shell)** es un protocolo de comunicación que permite establecer conexiones seguras entre equipos remotos. A través de él es posible:

* Administrar servidores y sistemas.
* Transferir archivos de manera cifrada.
* Ejecutar comandos de forma remota.

Es una herramienta fundamental en la administración de sistemas y redes.

---

## 2. Requisitos previos

1. Un equipo que funcionará como **servidor SSH** (generalmente con Linux, aunque también es posible en Windows).
2. Un equipo que actuará como **cliente SSH** (Linux, macOS o Windows).
3. Conectividad entre ambos sistemas:

   * En una **red local**.
   * O mediante **dirección IP pública** y acceso a Internet.

---

## 3. Instalación y activación del servidor SSH

### En Linux (todas las distribuciones)

1. Instalar OpenSSH:

```bash
sudo apt install openssh-server     # Debian/Ubuntu
sudo dnf install openssh-server     # Fedora/RHEL
sudo pacman -S openssh              # Arch
```

2. Habilitar y arrancar el servicio:

```bash
sudo systemctl enable ssh
sudo systemctl start ssh
```

3. Verificar estado del servicio:

```bash
sudo systemctl status ssh
```

---

### En Windows

#### Opción A: Servidor SSH nativo (Windows 10/11 Pro)

En PowerShell con privilegios de administrador:

```powershell
Add-WindowsCapability -Online -Name OpenSSH.Server
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'
```

#### Opción B: WSL (Windows Subsystem for Linux)

Dentro de la distribución Linux instalada en WSL:

```bash
sudo apt install openssh-server
sudo service ssh start
```

---

## 4. Configuración básica de seguridad

Archivo de configuración en Linux:

```bash
sudo nano /etc/ssh/sshd_config
```

Recomendaciones mínimas:

```ini
Port 2222                   # Cambiar puerto por seguridad
PermitRootLogin no          # Deshabilitar acceso directo como root
PasswordAuthentication yes  # Permitir autenticación con contraseña
PermitEmptyPasswords no     # No permitir contraseñas vacías
AllowUsers usuario1 usuario2 # (opcional) Restringir usuarios autorizados
UseDNS no
```

Aplicar cambios:

```bash
sudo systemctl restart ssh
```

---

## 5. Obtener la dirección IP del servidor

* **Linux:**

  ```bash
  ip a   # o: hostname -I
  ```
* **Windows:**

  ```powershell
  ipconfig
  ```

---

## 6. Autenticación mediante claves (opcional y recomendado)

1. Generar un par de claves en el cliente:

```bash
ssh-keygen -t ed25519
```

2. Copiar la clave pública al servidor:

```bash
ssh-copy-id -p 2222 usuario@ip-del-servidor
```

*(En Windows, copiar manualmente el contenido de `id_ed25519.pub` a `~/.ssh/authorized_keys` del servidor.)*

---

## 7. Conexión desde el cliente

* **Desde Linux o macOS:**

```bash
ssh -p 2222 usuario@192.168.1.X
```

* **Desde Windows (PowerShell o CMD):**

```powershell
ssh -p 2222 usuario@192.168.1.X
```

* **Cliente gráfico PuTTY:**

  1. Descargar desde [https://www.putty.org](https://www.putty.org).
  2. Configurar:

     * Host: `192.168.1.X`
     * Puerto: `2222`
     * Tipo de conexión: `SSH`
  3. Seleccionar **Open** e iniciar sesión.

---

## 8. Configuración del cortafuegos (opcional y recomendable)

* **Linux (UFW como ejemplo):**

```bash
sudo apt install ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 2222/tcp
sudo ufw enable
```

* **Windows:**
  Configurar **Firewall de Windows Defender** para permitir el puerto definido (ej. 2222 TCP).

---

## 9. Comprobación de la conexión

Desde cualquier cliente:

```bash
ssh -p 2222 usuario@192.168.1.X
```

---

## 10. Herramientas útiles para la administración remota (Linux)

Se recomienda instalar las siguientes utilidades:

```bash
sudo apt install vim htop curl wget git rsync tmux net-tools
```

---

## Recomendaciones finales

* Cambiar el puerto por defecto (22 → uno alternativo).
* Deshabilitar el inicio de sesión remoto como **root**.
* Usar claves SSH en lugar de contraseñas cuando sea posible.
* Mantener el sistema y OpenSSH siempre actualizados.
* Revisar periódicamente los registros:

```bash
sudo journalctl -u ssh
```
