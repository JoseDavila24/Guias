## 🔐 PASO 1: CONFIGURAR SSH (Acceso Remoto)

### 1.1 Activar SSH en el arranque:
```bash
sysrc sshd_enable="YES"
```

### 1.2 Configurar seguridad SSH:
```bash
echo "PermitRootLogin no" >> /etc/ssh/sshd_config
echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
echo "MaxAuthTries 3" >> /etc/ssh/sshd_config
```

### 1.3 Iniciar servicio:
```bash
service sshd start
```

### 1.4 Verificar:
```bash
sockstat -4 -l | grep :22
```

**✅ Ahora conectate desde otra terminal:**
```bash
ssh usuario@ip_del_servidor
```

---

## 🌐 PASO 2: CONFIGURAR DHCP SERVER

### 2.1 Instalar DHCP:
```bash
pkg update
pkg install -y isc-dhcp44-server
```

### 2.2 Crear configuración DHCP:
```bash
cat > /usr/local/etc/dhcpd.conf << 'EOF'
authoritative;
option domain-name "jmrd.com";
option domain-name-servers 8.8.8.8, 8.8.4.4;
default-lease-time 3600;
max-lease-time 7200;

subnet 192.168.100.0 netmask 255.255.255.0 {
    range 192.168.100.100 192.168.100.200;
    option routers 192.168.100.1;
}
EOF
```

### 2.3 Configurar interfaz:
```bash
INTERFACE=$(ifconfig -l | awk '{print $1}')
sysrc dhcpd_enable="YES"
sysrc dhcpd_ifaces="$INTERFACE"
```

### 2.4 Iniciar servicio:
```bash
service isc-dhcpd start
```

### 2.5 Verificar:
```bash
service isc-dhcpd status
sockstat -4 -l | grep :67
```

---

## 📧 PASO 3: CONFIGURAR POSTFIX (Email)

### 3.1 Instalar Postfix:
```bash
pkg install -y postfix
```

### 3.2 Configurar servicio:
```bash
sysrc postfix_enable="YES"
```

### 3.3 Configuración básica:
```bash
postconf -e "myhostname = jmrd.com"
postconf -e "mydomain = jmrd.com"
postconf -e "inet_interfaces = localhost"
```

### 3.4 Configurar redes permitidas:
```bash
VM_IP=$(ifconfig | grep 'inet ' | grep -v 127.0.0.1 | awk '{print $2}' | head -1)
NETWORK=$(echo $VM_IP | cut -d. -f1-3)
postconf -e "mynetworks = 127.0.0.0/8, ${NETWORK}.0/24"
```

### 3.5 Iniciar servicio:
```bash
service postfix start
```

### 3.6 Verificar:
```bash
service postfix status
sockstat -4 -l | grep :25
```

---

## ✅ PASO 4: VERIFICACIÓN FINAL

### 4.1 Revisar todos los servicios:
```bash
echo "=== ESTADO DE SERVICIOS ==="
service sshd status && echo "✅ SSH OK"
service isc-dhcpd status && echo "✅ DHCP OK" 
service postfix status && echo "✅ Postfix OK"
```

### 4.2 Ver puertos escuchando:
```bash
echo "=== PUERTOS ACTIVOS ==="
sockstat -4 -l | grep -E '(:22|:25|:67)'
```

### 4.3 Probar servicios:
```bash
echo "=== PRUEBAS RÁPIDAS ==="
# Probar SSH local
ssh localhost echo "✅ SSH funciona"

# Probar Postfix
echo "Test email" | mail -s "Test" root
```

---

## 🛠️ PASO 5: TROUBLESHOOTING RÁPIDO

### Si hay problemas:

**DHCP no inicia:**
```bash
tail -f /var/log/messages
service isc-dhcpd restart
```

**Postfix con errores:**
```bash
tail -f /var/log/maillog
postfix check
```

**SSH no conecta:**
```bash
service sshd restart
sshd -t
```

---

## 📋 RESUMEN EJECUTAR EN ORDEN:

1. **PASO 1** - SSH (para acceso remoto)
2. **PASO 2** - DHCP Server  
3. **PASO 3** - Postfix Email
4. **PASO 4** - Verificación
5. **PASO 5** - Troubleshooting (si es necesario)
