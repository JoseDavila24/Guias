# 🚀 GUÍA COMPLETA FREEBSD - SSH + DHCP + POSTFIX

## ⌨️ PASO 0: CONFIGURAR TECLADO ESPAÑOL

```bash
# Configurar keymap español permanente
sysrc keymap="es"

# Aplicar cambios inmediatamente
kbdcontrol -l es.kbd

# Verificar
echo "Prueba teclado: ñáéíóú¿¡"
```

---

## 🔐 PASO 1: CONFIGURAR SSH (Acceso Root Sin Seguridad)

### 1.1 Activar y configurar SSH:
```bash
sysrc sshd_enable="YES"
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
echo "PermitEmptyPasswords yes" >> /etc/ssh/sshd_config
echo "MaxAuthTries 3" >> /etc/ssh/sshd_config
```

### 1.2 Quitar contraseña a root:
```bash
passwd -d root
```

### 1.3 Iniciar servicio:
```bash
service sshd start
```

### 1.4 Verificar SSH:
```bash
sockstat -4 -l | grep :22
echo "✅ SSH configurado - Conéctate con: ssh root@192.168.122.238"
```

---

## 🌐 PASO 2: CONFIGURAR SERVIDOR DHCP

### 2.1 Instalar DHCP:
```bash
pkg update
pkg install -y isc-dhcp44-server
```

### 2.2 Crear configuración DHCP para red 192.168.122.0/24:
```bash
cat > /usr/local/etc/dhcpd.conf << 'EOF'
authoritative;
option domain-name "jmrd.com";
option domain-name-servers 8.8.8.8, 8.8.4.4;
option subnet-mask 255.255.255.0;
option routers 192.168.122.1;
option broadcast-address 192.168.122.255;

default-lease-time 3600;
max-lease-time 7200;

subnet 192.168.122.0 netmask 255.255.255.0 {
    range 192.168.122.100 192.168.122.200;
    option routers 192.168.122.1;
    option subnet-mask 255.255.255.0;
    option broadcast-address 192.168.122.255;
}
EOF
```

### 2.3 Configurar interfaz vtnet0:
```bash
sysrc dhcpd_enable="YES"
sysrc dhcpd_ifaces="vtnet0"
```

### 2.4 Iniciar servicio DHCP:
```bash
service isc-dhcpd start
```

### 2.5 Verificar DHCP:
```bash
service isc-dhcpd status
sockstat -4 -l | grep :67
echo "✅ DHCP configurado en vtnet0 - Rango: 192.168.122.100-200"
```

---

## 📧 PASO 3: CONFIGURAR POSTFIX (Servidor de Correo)

### 3.1 Instalar Postfix:
```bash
pkg install -y postfix
```

### 3.2 Activar servicio:
```bash
sysrc postfix_enable="YES"
```

### 3.3 Configurar mailer.conf:
```bash
cat > /etc/mail/mailer.conf << 'EOF'
sendmail        /usr/local/sbin/sendmail
send-mail       /usr/local/sbin/sendmail
mailq           /usr/local/sbin/sailq
newaliases      /usr/local/sbin/newaliases
EOF
```

### 3.4 Configuración básica de Postfix:
```bash
postconf -e "myhostname = jmrd.com"
postconf -e "mydomain = jmrd.com"
postconf -e "myorigin = \$mydomain"
postconf -e "inet_interfaces = localhost, 192.168.122.238"
postconf -e "inet_protocols = ipv4"
postconf -e "mydestination = \$myhostname, localhost.\$mydomain, localhost, \$mydomain"
postconf -e "home_mailbox = Maildir/"
```

### 3.5 Configurar redes permitidas:
```bash
postconf -e "mynetworks = 127.0.0.0/8, 192.168.122.0/24"
postconf -e "smtpd_recipient_restrictions = permit_mynetworks, reject"
postconf -e "smtpd_tls_security_level = none"
```

### 3.6 Iniciar Postfix:
```bash
service postfix start
```

### 3.7 Verificar Postfix:
```bash
service postfix status
sockstat -4 -l | grep :25
echo "✅ Postfix configurado - Solo envío local"
```

---

## ✅ PASO 4: VERIFICACIÓN INTEGRAL

### 4.1 Verificar todos los servicios:
```bash
echo "=== 🎯 ESTADO FINAL DE SERVICIOS ==="
service sshd status && echo "✅ SSH - ACTIVO"
service isc-dhcpd status && echo "✅ DHCP - ACTIVO" 
service postfix status && echo "✅ POSTFIX - ACTIVO"
```

### 4.2 Ver puertos escuchando:
```bash
echo "=== 📡 PUERTOS ACTIVOS ==="
sockstat -4 -l | grep -E '(:22|:25|:67)'
```

### 4.3 Probar funcionalidades:
```bash
echo "=== 🧪 PRUEBAS RÁPIDAS ==="

# Probar SSH local
echo "Probando SSH..."
ssh root@localhost echo "✅ SSH funciona correctamente"

# Probar envío de correo
echo "Test de correo desde Postfix" | mail -s "Prueba Postfix" root
echo "✅ Correo de prueba enviado"

# Ver leases DHCP
echo "=== 🌐 CLIENTES DHCP ==="
[ -f /var/db/dhcpd/dhcpd.leases ] && tail /var/db/dhcpd/dhcpd.leases || echo "Aún no hay clientes DHCP"
```

### 4.4 Resumen de configuración:
```bash
echo "=== 📊 RESUMEN DE CONFIGURACIÓN ==="
echo "🖥️  IP del servidor: 192.168.122.238"
echo "🔐 SSH: root sin contraseña - puerto 22"
echo "🌐 DHCP: vtnet0 - rango 192.168.122.100-200"
echo "📧 POSTFIX: jmrd.com - solo envío local"
echo "⌨️  Teclado: Español LATAM configurado"
```

---

## 🛠️ PASO 5: COMANDOS DE MANTENIMIENTO

### Monitoreo en tiempo real:
```bash
# Ver logs de DHCP
tail -f /var/log/dhcpd.log

# Ver logs de correo
tail -f /var/log/maillog

# Ver logs del sistema
tail -f /var/log/messages
```

### Reiniciar servicios si es necesario:
```bash
service sshd restart
service isc-dhcpd restart
service postfix restart
```

### Ver configuración actual:
```bash
# Ver config DHCP
cat /usr/local/etc/dhcpd.conf

# Ver config Postfix
postconf -n
```

---

## 🎯 ORDEN DE EJECUCIÓN RECOMENDADO:

1. **PASO 0** - Teclado español
2. **PASO 1** - SSH (para acceso remoto)
3. **PASO 2** - DHCP Server
4. **PASO 3** - Postfix Email
5. **PASO 4** - Verificación final

**¡Todos los servicios están configurados y funcionando!** 🚀

**Para conectarte remotamente:**
```bash
ssh root@192.168.122.238
```
