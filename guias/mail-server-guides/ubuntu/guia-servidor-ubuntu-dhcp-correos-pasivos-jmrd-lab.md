# Guía Completa: Servidor Ubuntu con DHCP + Correos Pasivos (JMRD.lab)

## 📋 Configuración Específica para tu Entorno
- **Interfaz de red**: `ens4`
- **Dominio**: `JMRD.lab`
- **IP del servidor**: `192.168.1.1`
- **Red**: `192.168.1.0/24`

---

## 1. 🛠 Configuración Inicial del Servidor

### Actualizar sistema
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install net-tools -y
```

### Verificar interfaz ens4
```bash
ip a show ens4
```

---

## 2. 🌐 Configuración de Red e IP Estática

### Configurar IP estática en ens4
```bash
sudo nano /etc/netplan/01-netcfg.yaml
```

**Configuración específica para JMRD.lab:**
```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    ens4:  # TU ADAPTADOR DEL LAB
      dhcp4: no
      addresses: [192.168.1.1/24]
      routes:
        - to: default
          via: 192.168.1.1
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
        search: [JMRD.lab]
```

### Aplicar configuración
```bash
sudo chmod 600 /etc/netplan/01-netcfg.yaml
sudo netplan apply
```

### Verificar IP
```bash
ip a show ens4
```
**Debe mostrar:** `inet 192.168.1.1/24`

---

## 3. 🔌 Servidor DHCP para ens4

### Instalar DHCP Server
```bash
sudo apt install isc-dhcp-server -y
```

### Configurar interfaz DHCP para ens4
```bash
sudo nano /etc/default/isc-dhcp-server
```

**Configurar:**
```
INTERFACESv4="ens4"  # TU ADAPTADOR DEL LAB
INTERFACESv6=""
```

### Configurar dhcpd.conf para JMRD.lab
```bash
sudo cp /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.backup
sudo nano /etc/dhcp/dhcpd.conf
```

**Configuración completa para JMRD.lab:**
```
# CONFIGURACIÓN GLOBAL JMRD.lab
option domain-name "JMRD.lab";
option domain-name-servers 8.8.8.8, 8.8.4.4;
default-lease-time 600;
max-lease-time 7200;
authoritative;

# SUBNET PRINCIPAL JMRD.lab
subnet 192.168.1.0 netmask 255.255.255.0 {
    range 192.168.1.100 192.168.1.200;
    option routers 192.168.1.1;
    option subnet-mask 255.255.255.0;
    option broadcast-address 192.168.1.255;
    option domain-name-servers 8.8.8.8, 8.8.4.4;
    option domain-name "JMRD.lab";
}

# RESERVAS OPCIONALES
# host pc-lab1 {
#     hardware ethernet xx:xx:xx:xx:xx:xx;  # MAC PC1
#     fixed-address 192.168.1.10;
# }
# 
# host pc-lab2 {
#     hardware ethernet yy:yy:yy:yy:yy:yy;  # MAC PC2
#     fixed-address 192.168.1.11;
# }
```

### Habilitar e iniciar DHCP
```bash
sudo systemctl start isc-dhcp-server
sudo systemctl enable isc-dhcp-server
sudo systemctl status isc-dhcp-server
```

---

## 4. 📧 Servidor de Correo Pasivo para JMRD.lab

### Instalar Postfix y Dovecot
```bash
sudo apt install postfix postfix-mysql dovecot-imapd dovecot-pop3d mailutils -y
```

### Durante instalación de Postfix:
- **Tipo de correo**: "Sitio de Internet"
- **Nombre del sistema**: `JMRD.lab`
- **Destinos**: Acepta los valores por defecto

### Configurar Postfix para JMRD.lab
```bash
sudo nano /etc/postfix/main.cf
```

**Configuración completa JMRD.lab:**
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

# SEGURIDAD - SOLO RECEPCIÓN INTERNA
smtpd_recipient_restrictions = permit_mynetworks, reject_unauth_destination

# LIMITAR SOLO A RED LOCAL PARA ENVÍO
smtpd_client_restrictions = permit_mynetworks, reject
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
# Crear usuarios del laboratorio
sudo adduser juan
sudo adduser maria
sudo adduser admin

# Establecer contraseñas
sudo passwd juan
sudo passwd maria
sudo passwd admin
```

### Habilitar servicios de correo
```bash
sudo systemctl restart postfix
sudo systemctl restart dovecot
sudo systemctl enable postfix
sudo systemctl enable dovecot
```

---

## 5. 🔧 Configuración de Firewall para ens4

```bash
# Instalar UFW si no está
sudo apt install ufw -y

# Configurar reglas específicas para el lab
sudo ufw allow 22/tcp                    # SSH
sudo ufw allow 67/udp                    # DHCP
sudo ufw allow 25/tcp                    # SMTP
sudo ufw allow 110/tcp                   # POP3
sudo ufw allow 143/tcp                   # IMAP
sudo ufw allow from 192.168.1.0/24       # Red local del lab

# Habilitar firewall
sudo ufw enable
```

---

## 6. 💻 Configuración de Clientes Lubuntu (JMRD.lab)

### Configuración de red en clientes
1. **Conectar cable a switch → adaptador ens4**
2. **Ir a Configuración → Red**
3. **Configurar como DHCP/Automático**
4. **Deben obtener IP del rango 192.168.1.100-200**

### Instalar Sylpheed en clientes
```bash
sudo apt update
sudo apt install sylpheed -y
```

### Configurar Sylpheed para SOLO RECIBIR

#### Para usuario Juan:
1. **Abrir Sylpheed → Cuenta → Agregar**
2. **Recepción:**
   - Nombre: `Juan - JMRD Lab`
   - Protocolo: **IMAP**
   - Servidor: `192.168.1.1`
   - Usuario: `juan`
   - Contraseña: `contraseña-de-juan`
   - Puerto: `143`

3. **Envío:**
   - **DEJAR TODO VACÍO**
   - No configurar servidor SMTP
   - No marcar "Usar SMTP"

#### Para usuario Maria:
1. **Abrir Sylpheed → Cuenta → Agregar**
2. **Recepción:**
   - Nombre: `Maria - JMRD Lab`
   - Protocolo: **IMAP**
   - Servidor: `192.168.1.1`
   - Usuario: `maria`
   - Contraseña: `contraseña-de-maria`
   - Puerto: `143`

3. **Envío:**
   - **DEJAR TODO VACÍO**

#### Deshabilitar envío completo en Sylpheed:
```
Configuración → Preferencias → Composición de correo
```
- Desmarcar: "Guardar copia en carpeta Enviados"
- Desmarcar: "Enviar correo inmediatamente"
- Desmarcar: "Usar servidor SMTP"

---

## 7. 🧪 Pruebas y Verificación para JMRD.lab

### Probar DHCP en ens4
```bash
# En servidor ver leases
sudo cat /var/lib/dhcp/dhcpd.leases

# En servidor ver logs específicos de ens4
sudo tail -f /var/log/syslog | grep -i "dhcp.*ens4"

# Ver estado del servicio
sudo systemctl status isc-dhcp-server
```

### Probar servicios de correo JMRD.lab
```bash
# Ver servicios activos
sudo systemctl status postfix
sudo systemctl status dovecot

# Ver puertos abiertos en ens4
sudo netstat -tlnp | grep -E ':25|:110|:143|:67'

# Probar DNS local
nslookup JMRD.lab
```

### Enviar correos de prueba desde servidor
```bash
# Correos de bienvenida
echo "Bienvenido al sistema de correo JMRD.lab" | mail -s "Bienvenido Juan" juan@JMRD.lab
echo "Bienvenida al sistema de correo JMRD.lab" | mail -s "Bienvenida Maria" maria@JMRD.lab
echo "Configuración completada exitosamente" | mail -s "Sistema Listo" admin@JMRD.lab

# Correo con contenido más elaborado
cat << EOF | mail -s "Instrucciones del Sistema" juan@JMRD.lab
Hola Juan,

El sistema de correo JMRD.lab está configurado correctamente.

Características:
- Solo recepción de correos
- Servidor: 192.168.1.1
- Usa IMAP en puerto 143

Saludos,
Administrador JMRD.lab
EOF
```

### Verificar buzones en servidor
```bash
# Verificar que se crearon los buzones
sudo ls -la /home/juan/Maildir/
sudo ls -la /home/maria/Maildir/
sudo ls -la /home/admin/Maildir/

# Ver correos entregados
sudo tail -f /var/log/mail.log
```

---

## 8. 🔄 Comandos Útiles para Mantenimiento JMRD.lab

### Reiniciar todos los servicios
```bash
sudo systemctl restart isc-dhcp-server postfix dovecot
```

### Ver logs específicos del lab
```bash
# Logs DHCP en ens4
sudo journalctl -u isc-dhcp-server -f

# Logs de correo
sudo tail -f /var/log/mail.log | grep JMRD.lab

# Estado general
sudo systemctl status isc-dhcp-server postfix dovecot
```

### Monitoreo del sistema
```bash
# Clientes DHCP conectados al lab
dhcp-lease-list

# Correos en cola
mailq

# Espacio de buzones del lab
du -sh /home/juan/Maildir /home/maria/Maildir /home/admin/Maildir
```

---

## 9. 🚨 Solución de Problemas Específicos

### Si DHCP no funciona en ens4:
```bash
# Verificar interfaz
ip a show ens4

# Reiniciar servicios
sudo systemctl restart isc-dhcp-server
sudo netplan apply

# Ver errores
sudo journalctl -u isc-dhcp-server -n 50
```

### Si correo no funciona:
```bash
# Probar servicios localmente
telnet localhost 25
telnet localhost 143

# Verificar configuración de dominio
sudo postconf -n | grep JMRD
sudo doveconf -n | grep JMRD
```

### Si clientes no pueden recibir correo:
- Verificar que están en la red 192.168.1.0/24
- Verificar usuario/contraseña en Sylpheed
- Confirmar que Dovecot está ejecutándose
- Revisar firewall no bloquea puertos

---

## 📊 Estructura Final del Sistema JMRD.lab

```
Servidor Ubuntu (192.168.1.1 - ens4)
├── 🔌 DHCP Server (rango: 192.168.1.100-200)
├── 📧 Postfix (SMTP - puerto 25) - SOLO ENVÍA INTERNO
├── 📨 Dovecot (IMAP/POP3 - puertos 143/110) - SOLO RECIBE
└── 👥 Usuarios: juan, maria, admin @JMRD.lab

Switch (Conectado a ens4)
├── 💻 PC Lubuntu 1 (Sylpheed - juan@JMRD.lab)
└── 💻 PC Lubuntu 2 (Sylpheed - maria@JMRD.lab)
```

**¡Sistema JMRD.lab completo!** Los clientes:
- ✅ Obtienen IP automáticamente via DHCP en ens4
- ✅ Pueden recibir correos @JMRD.lab con Sylpheed
- ❌ **NO pueden enviar correos** (sistema pasivo)
