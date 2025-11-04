# Guía Completa: Servidor Ubuntu con DHCP + Correos Pasivos

## 📋 Tabla de Contenidos
1. [Configuración Inicial del Servidor](#configuración-inicial)
2. [Configuración de Red e IP Estática](#configuración-de-red)
3. [Instalación y Configuración DHCP](#servidor-dhcp)
4. [Instalación y Configuración de Correo](#servidor-de-correo)
5. [Configuración de Clientes Lubuntu](#clientes-lubuntu)
6. [Pruebas y Verificación](#pruebas)

---

## 1. 🛠 Configuración Inicial del Servidor

### Actualizar sistema
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install net-tools
```

### Ver interfaces de red
```bash
ip a
```
**Anota el nombre de tu interfaz** (ej: ens33, eth0, enp0s3)

---

## 2. 🌐 Configuración de Red e IP Estática

### Configurar IP estática
```bash
sudo nano /etc/netplan/01-netcfg.yaml
```

**Ejemplo de configuración:**
```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    ens33:  # ¡CAMBIAR POR TU INTERFAZ!
      dhcp4: no
      addresses: [192.168.1.1/24]
      gateway4: 192.168.1.1
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
        search: [local.lan]
```

### Aplicar configuración
```bash
sudo netplan apply
```

### Verificar IP
```bash
ip a show ens33
```

---

## 3. 🔌 Servidor DHCP

### Instalar DHCP Server
```bash
sudo apt install isc-dhcp-server -y
```

### Configurar interfaz DHCP
```bash
sudo nano /etc/default/isc-dhcp-server
```

**Configurar:**
```
INTERFACESv4="ens33"  # ¡TU INTERFAZ!
INTERFACESv6=""
```

### Configurar dhcpd.conf
```bash
sudo cp /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.backup
sudo nano /etc/dhcp/dhcpd.conf
```

**Agregar esta configuración:**
```
# CONFIGURACIÓN GLOBAL
option domain-name "local.lan";
option domain-name-servers 8.8.8.8, 8.8.4.4;
default-lease-time 600;
max-lease-time 7200;
authoritative;

# SUBNET PRINCIPAL
subnet 192.168.1.0 netmask 255.255.255.0 {
    range 192.168.1.100 192.168.1.200;
    option routers 192.168.1.1;
    option subnet-mask 255.255.255.0;
    option broadcast-address 192.168.1.255;
    option domain-name-servers 8.8.8.8, 8.8.4.4;
}

# RESERVAS OPCIONALES (para IPs fijas)
host pc-lubuntu-1 {
    hardware ethernet xx:xx:xx:xx:xx:xx;  # MAC PC1
    fixed-address 192.168.1.10;
}

host pc-lubuntu-2 {
    hardware ethernet yy:yy:yy:yy:yy:yy;  # MAC PC2
    fixed-address 192.168.1.11;
}
```

### Habilitar e iniciar DHCP
```bash
sudo systemctl start isc-dhcp-server
sudo systemctl enable isc-dhcp-server
sudo systemctl status isc-dhcp-server
```

---

## 4. 📧 Servidor de Correo Pasivo

### Instalar Postfix y Dovecot
```bash
sudo apt install postfix postfix-mysql dovecot-imapd dovecot-pop3d mailutils -y
```

### Durante instalación de Postfix:
- **Tipo de correo**: "Sitio de Internet"
- **Nombre del sistema**: `local.lan` (o el que prefieras)
- **Destinos**: Acepta los valores por defecto

### Configurar Postfix
```bash
sudo nano /etc/postfix/main.cf
```

**Configuración completa:**
```
# CONFIGURACIÓN BÁSICA
myhostname = servidor.local.lan
mydomain = local.lan
myorigin = $mydomain
inet_interfaces = all
inet_protocols = all

# CONTROL DE DESTINOS
mydestination = $myhostname, localhost.$mydomain, localhost, $mydomain

# POLÍTICAS DE RED
mynetworks = 127.0.0.0/8 192.168.1.0/24
relay_domains = 
home_mailbox = Maildir/

# SEGURIDAD
smtpd_recipient_restrictions = permit_mynetworks, reject_unauth_destination
```

### Configurar Dovecot
```bash
sudo nano /etc/dovecot/dovecot.conf
```

**Agregar:**
```
protocols = imap pop3
listen = *
mail_location = maildir:~/Maildir
disable_plaintext_auth = no
```

```bash
sudo nano /etc/dovecot/conf.d/10-auth.conf
```
```
auth_mechanisms = plain login
!include auth-system.conf.ext
```

```bash
sudo nano /etc/dovecot/conf.d/10-mail.conf
```
```
mail_location = maildir:~/Maildir
```

### Crear usuarios de correo
```bash
# Crear usuarios (repetir para cada usuario)
sudo adduser usuario1
sudo adduser usuario2

# Establecer contraseñas
sudo passwd usuario1
sudo passwd usuario2
```

### Habilitar servicios de correo
```bash
sudo systemctl restart postfix
sudo systemctl restart dovecot
sudo systemctl enable postfix
sudo systemctl enable dovecot
```

---

## 5. 🔧 Configuración de Firewall

```bash
# Instalar UFW si no está
sudo apt install ufw -y

# Configurar reglas
sudo ufw allow 22/tcp                    # SSH
sudo ufw allow 67/udp                    # DHCP
sudo ufw allow 25/tcp                    # SMTP
sudo ufw allow 110/tcp                   # POP3
sudo ufw allow 143/tcp                   # IMAP
sudo ufw allow from 192.168.1.0/24       # Red local

# Habilitar firewall
sudo ufw enable
```

---

## 6. 💻 Configuración de Clientes Lubuntu

### Configuración de red en clientes
1. **Ir a Configuración → Red**
2. **Configurar como DHCP/Automático**
3. **Verificar que obtienen IP del rango 192.168.1.100-200**

### Instalar Sylpheed en clientes
```bash
sudo apt update
sudo apt install sylpheed -y
```

### Configurar Sylpheed para SOLO RECIBIR

#### Para cuenta IMAP (Recomendado):
1. **Abrir Sylpheed → Cuenta → Agregar**
2. **Recepción:**
   - Nombre: `usuario1`
   - Protocolo: **IMAP**
   - Servidor: `192.168.1.1`
   - Usuario: `usuario1`
   - Contraseña: `contraseña-de-usuario1`
   - Puerto: `143`

3. **Envío:**
   - **DEJAR TODO VACÍO**
   - No configurar servidor SMTP
   - No marcar "Usar SMTP"

#### Deshabilitar envío completo:
```
Configuración → Preferencias → Composición de correo
```
- Desmarcar: "Guardar copia en carpeta Enviados"
- Desmarcar: "Enviar correo inmediatamente"

---

## 7. 🧪 Pruebas y Verificación

### Probar DHCP
```bash
# En servidor ver leases
sudo cat /var/lib/dhcp/dhcpd.leases

# En servidor ver logs
sudo tail -f /var/log/syslog | grep dhcp

# En cliente ver IP asignada
ip a
```

### Probar servicios de correo
```bash
# Ver servicios activos
sudo systemctl status postfix
sudo systemctl status dovecot
sudo systemctl status isc-dhcp-server

# Ver puertos abiertos
sudo netstat -tlnp | grep -E ':25|:110|:143|:67'
```

### Enviar correo de prueba
```bash
# Desde el servidor
echo "Este es un correo de prueba" | mail -s "Bienvenido al sistema" usuario1@local.lan
echo "Correo para usuario 2" | mail -s "Test sistema" usuario2@local.lan
```

### Verificar correos en servidor
```bash
# Verificar buzones
sudo ls -la /home/usuario1/Maildir/
sudo ls -la /home/usuario2/Maildir/
```

---

## 8. 🔄 Comandos Útiles para Mantenimiento

### Reiniciar servicios
```bash
sudo systemctl restart isc-dhcp-server postfix dovecot
```

### Ver logs en tiempo real
```bash
# Logs DHCP
sudo tail -f /var/log/syslog | grep dhcp

# Logs correo
sudo tail -f /var/log/mail.log

# Logs generales
sudo journalctl -f
```

### Estadísticas del sistema
```bash
# Clientes DHCP conectados
dhcp-lease-list

# Correos en cola
mailq

# Espacio de buzones
du -sh /home/*/Maildir
```

---

## 9. 🚨 Solución de Problemas Comunes

### Si DHCP no asigna IPs:
```bash
sudo systemctl restart isc-dhcp-server
sudo netplan apply
```

### Si correo no funciona:
```bash
# Probar conexión local
telnet localhost 25
telnet localhost 143

# Verificar configuración
sudo postfix check
sudo doveconf -n
```

### Si clientes no pueden recibir correo:
- Verificar usuario/contraseña en Sylpheed
- Verificar que Dovecot está ejecutándose
- Revisar firewall no bloquea puertos

---

## 📊 Estructura Final del Sistema

```
Servidor Ubuntu (192.168.1.1)
├── 🔌 DHCP Server (rango: 192.168.1.100-200)
├── 📧 Postfix (SMTP - puerto 25) - SOLO ENVÍA
├── 📨 Dovecot (IMAP/POP3 - puertos 143/110) - SOLO RECIBE
└── 👥 Usuarios: usuario1, usuario2

Switch
├── 💻 PC Lubuntu 1 (Sylpheed - usuario1)
└── 💻 PC Lubuntu 2 (Sylpheed - usuario2)
```

**¡Sistema completo!** Los clientes:
- ✅ Obtienen IP automáticamente via DHCP
- ✅ Pueden recibir correos con Sylpheed
- ❌ **NO pueden enviar correos** (sistema pasivo)
