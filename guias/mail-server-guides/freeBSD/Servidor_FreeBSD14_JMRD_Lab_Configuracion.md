# 📘 GUÍA MAESTRA: SERVIDOR JMRD.LAB (FreeBSD 14)

**Servicios:** Red + DHCP + Correo (Postfix/Dovecot) + Usuarios RRHH
**Entorno:** GNS3 en Hyper-V (Drivers e1000)

-----

## 🛠️ PASO 1: CONFIGURACIÓN DE RED ROBUSTA (Hyper-V Fix)

Aquí aplicamos los parches para que las descargas no se congelen y definimos las interfaces correctas (`em0`/`em1`).

```bash
# 1. Limpiar configuraciones previas
sysrc -x ifconfig_DEFAULT

# 2. Configurar WAN/Internet (em0)
# NOTA CRÍTICA: 'mtu 1200' y desactivar offloading (-tso -lro) evita bloqueos en Hyper-V
sysrc ifconfig_em0="DHCP mtu 1200 -rxcsum -txcsum -lro -tso"

# 3. Configurar LAN JMRD (em1)
# Esta es la IP fija de tu servidor para la red interna
sysrc ifconfig_em1="inet 172.16.50.10 netmask 255.255.255.0"

# 4. Asegurar DNS estable (Google)
echo "nameserver 8.8.8.8" > /etc/resolv.conf
# (Opcional: bloquear archivo con 'chflags schg /etc/resolv.conf')

# 5. Aplicar cambios
service netif restart
service routing restart
```

-----

## 📦 PASO 2: INSTALACIÓN DE PAQUETES

Instalamos todo de golpe forzando IPv4 para evitar errores de red.

```bash
pkg -4 bootstrap -f
pkg -4 install -y isc-dhcp44-server postfix dovecot nano bash
```

-----

## 🌐 PASO 3: CONFIGURACIÓN DHCP (Servidor de IPs)

Configuramos el servidor para que entregue IPs a los clientes (Lubuntu) en la red interna.

**Corrección aplicada:** La IP del router ahora coincide con la del servidor (`.10`).

```bash
# 1. Habilitar servicio en la interfaz LAN
sysrc dhcpd_enable="YES"
sysrc dhcpd_ifaces="em1"

# 2. Crear archivo de configuración
cat > /usr/local/etc/dhcpd.conf << 'EOF'
authoritative;
option domain-name "jmrd.com";
option domain-name-servers 8.8.8.8, 8.8.4.4;
default-lease-time 3600;
max-lease-time 7200;

subnet 172.16.50.0 netmask 255.255.255.0 {
    range 172.16.50.100 172.16.50.200;
    option routers 172.16.50.10;     # <-- CORREGIDO (Antes decía .1)
    option subnet-mask 255.255.255.0;
    option broadcast-address 172.16.50.255;
}
EOF

# 3. Iniciar servicio
service isc-dhcpd restart
```

-----

## 📧 PASO 4: CONFIGURACIÓN DE CORREO (Postfix + Dovecot)

Configuramos SMTP (envío) e IMAP (recepción) para que los clientes puedan leer los correos.

### 4.1 Postfix (SMTP)

**Corrección aplicada:** IP de escucha corregida a `.10` y enlace simbólico para `newaliases`.

```bash
sysrc postfix_enable="YES"

# Configurar mailer.conf
cat > /etc/mail/mailer.conf << 'EOF'
sendmail        /usr/local/sbin/sendmail
send-mail       /usr/local/sbin/sendmail
mailq           /usr/local/sbin/mailq
newaliases      /usr/local/sbin/newaliases
EOF

# Crear enlace simbólico necesario para alias
ln -sf /usr/local/sbin/sendmail /usr/local/sbin/newaliases

# Configurar main.cf
postconf -e "myhostname = jmrd.com"
postconf -e "mydomain = jmrd.com"
postconf -e "myorigin = \$mydomain"
postconf -e "inet_interfaces = localhost, 172.16.50.10" # <-- CORREGIDO (Antes .101)
postconf -e "inet_protocols = ipv4"
postconf -e "mydestination = \$myhostname, localhost.\$mydomain, localhost, \$mydomain"
postconf -e "home_mailbox = Maildir/"
postconf -e "mynetworks = 127.0.0.0/8, 172.16.50.0/24"
postconf -e "smtpd_recipient_restrictions = permit_mynetworks, reject"
postconf -e "smtpd_tls_security_level = none"
```

### 4.2 Dovecot (IMAP)

Este paso faltaba en la guía original y es vital para Sylpheed.

```bash
sysrc dovecot_enable="YES"

cat > /usr/local/etc/dovecot/dovecot.conf << 'EOF'
listen = *
protocols = imap
mail_location = maildir:~/Maildir
ssl = no
disable_plaintext_auth = no
auth_mechanisms = plain login
# Configuración para usar usuarios del sistema
passdb {
  driver = pam
}
userdb {
  driver = passwd
}
EOF
```

-----

## 👥 PASO 5: RECURSOS HUMANOS (Usuarios y Alias)

Creamos el departamento, las usuarias y las listas de distribución.

```bash
# 1. Crear grupo y usuarios
pw groupadd recursoshumanos
# Brenda
pw useradd brenda -c "Brenda RRHH" -m -s /bin/tcsh -G recursoshumanos
echo "1234" | pw mod user brenda -h 0
# Wendy
pw useradd wendy -c "Wendy RRHH" -m -s /bin/tcsh -G recursoshumanos
echo "1234" | pw mod user wendy -h 0

# 2. Crear carpetas Maildir (Evita errores en Dovecot)
su - brenda -c "mkdir -p ~/Maildir/{cur,new,tmp}"
su - wendy -c "mkdir -p ~/Maildir/{cur,new,tmp}"

# 3. Configurar Alias
cat >> /etc/mail/aliases << 'EOF'
# DEPARTAMENTO RRHH
brenda: brenda
wendy: wendy
rrhh: brenda,wendy
nominas: brenda,wendy
contrataciones: brenda,wendy
EOF

# 4. Regenerar base de datos de alias
newaliases
```

-----

## 🔐 PASO 6: ACCESO REMOTO (SSH)

Habilitamos el acceso root para administración fácil.

```bash
sysrc sshd_enable="YES"
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
service sshd restart
```

-----

## 🚀 PASO FINAL: ARRANQUE Y VERIFICACIÓN

Reiniciamos todos los servicios para asegurar que la configuración es persistente.

```bash
service netif restart
service isc-dhcpd restart
service postfix restart
service dovecot restart
```

### Comandos de Verificación:

  * **Ver puertos:** `sockstat -4 -l` (Debes ver puertos 67, 25, 143 y 22).
  * **Ver IP:** `ifconfig em1` (Debe ser 172.16.50.10).
  * **Ver IP de Gestión:** `ifconfig em0` (Úsala para conectar PuTTY).

-----

### 📝 DATOS PARA EL CLIENTE (Sylpheed en Lubuntu)

  * **IP Servidor:** `172.16.50.10`
  * **Protocolo:** IMAP4
  * **Puertos:** IMAP (143), SMTP (25)
  * **SSL:** **NO** (Desactivar SSL/TLS en ambas pestañas)
  * **Usuario:** `brenda` / `wendy`
  * **Contraseña:** `1234`

¡Esta es tu guía definitiva\! Guárdala bien, porque funciona a prueba de balas en tu entorno. ¡Éxito\! 🚀
