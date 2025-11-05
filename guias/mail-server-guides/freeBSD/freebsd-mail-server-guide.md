🔧 **ENTENDIDO - Configuración corregida:**

# 🚀 GUÍA FREEBSD - SSH + DHCP + POSTFIX (CONFIGURACIÓN CORREGIDA)

## ⌨️ PASO 0: CONFIGURAR TECLADO ESPAÑOL

```bash
sysrc keymap="es"
kbdcontrol -l es.kbd
```

---

## 🔐 PASO 1: CONFIGURAR SSH (Acceso Root Sin Seguridad)

### 1.1 Configurar SSH:
```bash
sysrc sshd_enable="YES"
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
echo "PermitEmptyPasswords yes" >> /etc/ssh/sshd_config
```

### 1.2 Quitar contraseña a root:
```bash
passwd -d root
```

### 1.3 Configurar vtnet1 para obtener IP por DHCP:
```bash
echo 'ifconfig_vtnet1="DHCP"' >> /etc/rc.conf
service netif restart vtnet1
```

### 1.4 Iniciar SSH:
```bash
service sshd start
```

---

## 🌐 PASO 2: CONFIGURAR SERVIDOR DHCP EN VNET0

### 2.1 Configurar IP fija para vtnet0 (red 172.16.50.0/24):
```bash
echo 'ifconfig_vtnet0="inet 172.16.50.10 netmask 255.255.255.0"' >> /etc/rc.conf
service netif restart vtnet0
```

### 2.2 Instalar DHCP:
```bash
pkg install -y isc-dhcp44-server
```

### 2.3 Crear configuración DHCP para red 172.16.50.0/24:
```bash
cat > /usr/local/etc/dhcpd.conf << 'EOF'
authoritative;
option domain-name "jmrd.com";
option domain-name-servers 8.8.8.8, 8.8.4.4;
option subnet-mask 255.255.255.0;
option routers 172.16.50.1;
option broadcast-address 172.16.50.255;

default-lease-time 3600;
max-lease-time 7200;

subnet 172.16.50.0 netmask 255.255.255.0 {
    range 172.16.50.100 172.16.50.200;
    option routers 172.16.50.1;
    option subnet-mask 255.255.255.0;
    option broadcast-address 172.16.50.255;
}
EOF
```

### 2.4 Configurar e iniciar DHCP:
```bash
sysrc dhcpd_enable="YES"
sysrc dhcpd_ifaces="vtnet0"
service isc-dhcpd start
```

---

## 📧 PASO 3: CONFIGURAR POSTFIX

### 3.1 Instalar y activar Postfix:
```bash
pkg install -y postfix
sysrc postfix_enable="YES"
```

### 3.2 Configurar mailer.conf:
```bash
cat > /etc/mail/mailer.conf << 'EOF'
sendmail        /usr/local/sbin/sendmail
send-mail       /usr/local/sbin/sendmail
mailq           /usr/local/sbin/mailq
newaliases      /usr/local/sbin/newaliases
EOF
```

### 3.3 Configurar Postfix:
```bash
postconf -e "myhostname = jmrd.com"
postconf -e "mydomain = jmrd.com"
postconf -e "myorigin = \$mydomain"
postconf -e "inet_interfaces = localhost, 172.16.50.10"
postconf -e "inet_protocols = ipv4"
postconf -e "mydestination = \$myhostname, localhost.\$mydomain, localhost, \$mydomain"
postconf -e "home_mailbox = Maildir/"
postconf -e "mynetworks = 127.0.0.0/8, 172.16.50.0/24"
postconf -e "smtpd_recipient_restrictions = permit_mynetworks, reject"
postconf -e "smtpd_tls_security_level = none"
```

### 3.4 Iniciar Postfix:
```bash
service postfix start
```

---

## ✅ PASO 4: VERIFICAR CONFIGURACIÓN

```bash
echo "=== CONFIGURACIÓN COMPLETADA ==="
echo "IP Administración (vtnet1): Obtendrá IP por DHCP"
echo "IP Servicios (vtnet0): 172.16.50.10"
echo "Red DHCP para clientes: 172.16.50.0/24"
echo "Rango DHCP: 172.16.50.100 - 172.16.50.200"
echo "Para conectar: Revisa la IP de vtnet1 con: ifconfig vtnet1"
```

**🎯 ORDEN DE EJECUCIÓN:**
1. **PASO 0** → Teclado
2. **PASO 1** → SSH + vtnet1 por DHCP
3. **PASO 2** → vtnet0 IP fija + DHCP Server
4. **PASO 3** → Postfix

**Después de configurar, verifica la IP de vtnet1 para conectarte:**
```bash
ifconfig vtnet1
```
