# Guía Completa: Servidor Ubuntu con DHCP + Correos Pasivos - DOMINIO JMRD.lab

## 📋 Tabla de Contenidos
1. [Configuración Inicial del Servidor](#configuración-inicial)
2. [Configuración de Red Dual Adaptador](#configuración-de-red)
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
**Confirmar interfaces:** `ens3` (administración) y `ens4` (LAB)

---

## 2. 🌐 Configuración de Red Dual Adaptador

### Configurar ambos adaptadores
```bash
sudo nano /etc/netplan/50-cloud-init.yaml
```

**Configuración completa:**
```yaml
network:
  version: 2
  ethernets:
    ens3:
      dhcp4: true
      optional: true
      
    ens4:
      dhcp4: no
      addresses: [192.168.1.1/24]
      gateway4: 192.168.1.1
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
        search: [JMRD.lab]
```

### Aplicar configuración
```bash
sudo netplan apply
```

### Verificar IPs
```bash
ip a show ens3
ip a show ens4
```

**Resultado esperado:**
- `ens3`: IP via DHCP
- `ens4`: IP estática `192.168.1.1`

---

## 3. 🔌 Servidor DHCP para LAB (ens4)

### Instalar DHCP Server
```bash
sudo apt install isc-dhcp-server -y
```

### Configurar interfaz DHCP específica para ens4
```bash
sudo nano /etc/default/isc-dhcp-server
```

**Configurar:**
```
INTERFACESv4="ens4"
INTERFACESv6=""
```

### Configurar dhcpd.conf con dominio JMRD.lab
```bash
sudo cp /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.backup
sudo nano /etc/dhcp/dhcpd.conf
```

**Configuración completa:**
```
# CONFIGURACIÓN GLOBAL JMRD.lab
option domain-name "JMRD.lab";
option domain-name-servers 8.8.8.8, 8.8.4.4;
default-lease-time 600;
max-lease-time 7200;
authoritative;

# SUBNET para ens4 - JMRD.lab
subnet 192.168.1.0 netmask 255.255.255.0 {
    range 192.168.1.100 192.168.1.200;
    option routers 192.168.1.1;
    option subnet-mask 255.255.255.0;
    option broadcast-address 192.168.1.255;
    option domain-name-servers 8.8.8.8, 8.8.4.4;
    option domain-name "JMRD.lab";
}

# RESERVAS OPCIONALES (para IPs fijas)
host pc-lubuntu-1 {
    hardware ethernet xx:xx:xx:xx:xx:xx;  # MAC PC1
    fixed-address 192.168.1.10;
    option host-name "pc1";
}

host pc-lubuntu-2 {
    hardware ethernet yy:yy:yy:yy:yy:yy;  # MAC PC2
    fixed-address 192.168.1.11;
    option host-name "pc2";
}
```

### Habilitar e iniciar DHCP
```bash
sudo systemctl start isc-dhcp-server
sudo systemctl enable isc-dhcp-server
sudo systemctl status isc-dhcp-server
```

---

## 4. 📧 Servidor de Correo Pasivo - DOMINIO JMRD.lab

### Instalar Postfix y Dovecot
```bash
sudo apt install postfix postfix-mysql dovecot-imapd dovecot-pop3d mailutils -y
```

### Durante instalación de Postfix:
- **Tipo de correo**: "Sitio de Internet"
- **Nombre del sistema**: `JMRD.lab`
- **Destinos**: Acepta los valores por defecto

### Configurar Postfix con dominio JMRD.lab
```bash
sudo nano /etc/postfix/main.cf
```

**Configuración completa:**
```
# CONFIGURACIÓN BÁSICA JMRD.lab
myhostname = servidor.JMRD.lab
mydomain = JMRD.lab
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

### Configurar /etc/hosts
```bash
sudo nano /etc/hosts
```

**Agregar:**
```
127.0.0.1 localhost
192.168.1.1 servidor.JMRD.lab servidor

# The following lines are desirable for IPv6 capable hosts
::1 localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
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

### Crear usuarios de correo para JMRD.lab
```bash
# Crear usuarios (repetir para cada usuario)
sudo adduser juan
sudo adduser maria
sudo adduser admin

# Establecer contraseñas
sudo passwd juan
sudo passwd maria
sudo passwd admin
```

**Direcciones de correo creadas:**
- `juan@JMRD.lab`
- `maria@JMRD.lab`
- `admin@JMRD.lab`

### Habilitar servicios de correo
```bash
sudo systemctl restart postfix
sudo systemctl restart dovecot
sudo systemctl enable postfix
sudo systemctl enable dovecot
```

---

## 5. 🔥 Configuración de Firewall para LAB

```bash
# Instalar UFW si no está
sudo apt install ufw -y

# Reglas básicas
sudo ufw allow 22/tcp                    # SSH

# Reglas específicas para LAB (ens4)
sudo ufw allow in on ens4 from 192.168.1.0/24
sudo ufw allow out on ens4 to 192.168.1.0/24
sudo ufw allow in on ens4 to any port 67/udp    # DHCP
sudo ufw allow in on ens4 to any port 25/tcp    # SMTP
sudo ufw allow in on ens4 to any port 110/tcp   # POP3
sudo ufw allow in on ens4 to any port 143/tcp   # IMAP

# Habilitar firewall
sudo ufw enable
```

---

## 6. 💻 Configuración de Clientes Lubuntu

### Configuración de red en clientes
1. **Conectar cable de red al switch que va a ens4**
2. **Ir a Configuración → Red**
3. **Configurar como DHCP/Automático**
4. **Verificar que obtienen IP del rango 192.168.1.100-200**

### Instalar Sylpheed en clientes
```bash
sudo apt update
sudo apt install sylpheed -y
```

### Configurar Sylpheed para SOLO RECIBIR - DOMINIO JMRD.lab

#### Para cuenta IMAP (Recomendado):
1. **Abrir Sylpheed → Cuenta → Agregar**
2. **Recepción:**
   - Nombre: `juan` (o el usuario correspondiente)
   - Protocolo: **IMAP**
   - Servidor: `servidor.JMRD.lab` o `192.168.1.1`
   - Usuario: `juan`
   - Contraseña: `contraseña-de-juan`
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

### Probar DHCP en ens4
```bash
# En servidor ver leases
sudo cat /var/lib/dhcp/dhcpd.leases

# En servidor ver logs específicos de ens4
sudo tail -f /var/log/syslog | grep dhcp | grep ens4

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

### Probar resolución de nombres
```bash
# En servidor
nslookup JMRD.lab
ping servidor.JMRD.lab

# En cliente después de obtener DHCP
nslookup JMRD.lab
ping servidor.JMRD.lab
```

### Enviar correo de prueba con dominio JMRD.lab
```bash
# Desde el servidor
echo "Bienvenido al sistema JMRD.lab" | mail -s "Test dominio JMRD" juan@JMRD.lab
echo "Correo de prueba Maria" | mail -s "Test JMRD" maria@JMRD.lab
echo "Sistema configurado correctamente" | mail -s "Configuración Exitosa" admin@JMRD.lab

# Verificar buzones
sudo ls -la /home/juan/Maildir/new/
sudo ls -la /home/maria/Maildir/new/
sudo ls -la /home/admin/Maildir/new/
```

### Probar conectividad de servicios
```bash
# Probar SMTP
telnet 192.168.1.1 25

# Probar IMAP
telnet 192.168.1.1 143

# Probar POP3
telnet 192.168.1.1 110
```

---

## 8. 🔄 Comandos Útiles para Mantenimiento

### Reiniciar servicios
```bash
sudo systemctl restart isc-dhcp-server postfix dovecot
```

### Ver logs en tiempo real
```bash
# Logs DHCP específicos de ens4
sudo tail -f /var/log/syslog | grep dhcp | grep ens4

# Logs correo
sudo tail -f /var/log/mail.log

# Logs generales
sudo journalctl -f
```

### Estadísticas del sistema
```bash
# Clientes DHCP conectados
sudo dhcp-lease-list

# Correos en cola
mailq

# Espacio de buzones
sudo du -sh /home/*/Maildir

# Ver conexiones activas por interfaz
sudo ss -tlnp | grep -E ':25|:110|:143|:67'
```

---

## 9. 🚨 Solución de Problemas Comunes

### Si DHCP no asigna IPs:
```bash
# Verificar interfaz ens4
sudo systemctl status isc-dhcp-server
sudo netplan apply
sudo systemctl restart isc-dhcp-server
```

### Si correo no funciona:
```bash
# Probar conexión local
telnet localhost 25
telnet localhost 143

# Verificar configuración
sudo postfix check
sudo doveconf -n

# Verificar dominio
postconf -n | grep mydomain
```

### Si clientes no pueden recibir correo:
- Verificar usuario/contraseña en Sylpheed
- Verificar que Dovecot está ejecutándose
- Revisar firewall no bloquea puertos en ens4
- Verificar que cliente obtuvo IP via DHCP de ens4

### Verificar configuración de dominio
```bash
# Ver hostname
hostname
hostname -f

# Ver configuración Postfix
postconf -n | grep -E 'mydomain|myhostname'
```

---

## 📊 Estructura Final del Sistema JMRD.lab

```
Servidor Ubuntu
├── 🌐 ens3 (DHCP) - Administración
└── 🔬 ens4 (192.168.1.1) - LAB JMRD.lab
    ├── 🔌 DHCP Server (rango: 192.168.1.100-200)
    ├── 📧 Postfix (servidor.JMRD.lab) - SOLO ENVÍA
    └── 📨 Dovecot (servidor.JMRD.lab) - SOLO RECIBE

Dominio: JMRD.lab
├── 👤 juan@JMRD.lab
├── 👤 maria@JMRD.lab
└── 👤 admin@JMRD.lab

Switch LAB → ens4
├── 💻 PC Lubuntu 1 (Sylpheed - juan@JMRD.lab)
└── 💻 PC Lubuntu 2 (Sylpheed - maria@JMRD.lab)
```

### Comando de verificación final:
```bash
# Verificar todo el sistema
echo "✅ Sistema JMRD.lab configurado exitosamente" | mail -s "Verificación Final" admin@JMRD.lab
```

**¡Sistema completo configurado!** Los clientes:
- ✅ Obtienen IP automáticamente via DHCP del adaptador ens4
- ✅ Pueden recibir correos con direcciones `usuario@JMRD.lab`
- ✅ Se conectan al servidor usando `servidor.JMRD.lab` o `192.168.1.1`
- ❌ **NO pueden enviar correos** (sistema pasivo)
