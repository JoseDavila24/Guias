🔧 **PRUEBAS PARA VERIFICAR QUE TODO FUNCIONA:**

## 🌐 **1. PRUEBA DE DHCP SERVER**

### Verificar que DHCP está escuchando:
```bash
echo "=== 🔍 VERIFICANDO DHCP ==="
sockstat -4 -l | grep :67
service isc-dhcpd status
```

### Ver configuración DHCP cargada:
```bash
echo "=== 📋 CONFIGURACIÓN DHCP ==="
cat /usr/local/etc/dhcpd.conf | grep -E '(range|subnet|option routers)'
```

### Ver logs de DHCP en tiempo real:
```bash
echo "=== 📊 MONITOREANDO DHCP ==="
tail -f /var/log/dhcpd.log
```
*(En otra terminal, conecta un cliente para ver las asignaciones)*

---

## 📧 **2. PRUEBAS DE POSTFIX**

### Verificar que Postfix está activo:
```bash
echo "=== 🔍 VERIFICANDO POSTFIX ==="
service postfix status
sockstat -4 -l | grep :25
```

### Probar envío de correo local:
```bash
echo "=== ✉️  PRUEBA DE CORREO ==="
echo "Este es un mensaje de prueba del servidor" | mail -s "Prueba de correo" root
echo "✅ Correo de prueba enviado a root"
```

### Verificar que el correo se procesó:
```bash
echo "=== 📨 VERIFICANDO ENTREGA ==="
tail -n 10 /var/log/maillog
```

### Probar con un usuario del sistema:
```bash
echo "=== 👤 PRUEBA CON USUARIO ==="
# Crear usuario de prueba si no existe
pw useradd -n prueba -m -s /bin/tcsh 2>/dev/null
echo "Mensaje para usuario prueba" | mail -s "Test Usuario" prueba
echo "✅ Correo enviado a usuario prueba"
```

---

## 🔄 **3. PRUEBAS DE CONECTIVIDAD DE RED**

### Verificar interfaces:
```bash
echo "=== 🌐 ESTADO DE INTERFACES ==="
ifconfig vtnet0
ifconfig vtnet1
```

### Probar conectividad en la red de servicios:
```bash
echo "=== 🧪 PRUEBAS DE RED vtnet0 ==="
ping -c 2 172.16.50.10  # Auto-ping
ping -c 2 172.16.50.1   # Gateway (si existe)
```

---

## 📊 **4. VERIFICACIÓN INTEGRAL AUTOMÁTICA**

### Script de verificación rápida:
```bash
cat > /root/verificar_servicios.sh << 'EOF'
#!/bin/sh
echo "=== ✅ VERIFICACIÓN RÁPIDA ==="
echo ""
echo "🔧 SERVICIOS:"
service isc-dhcpd status >/dev/null 2>&1 && echo "✅ DHCP - ACTIVO" || echo "❌ DHCP - INACTIVO"
service postfix status >/dev/null 2>&1 && echo "✅ POSTFIX - ACTIVO" || echo "❌ POSTFIX - INACTIVO"
echo ""
echo "📡 PUERTOS:"
sockstat -4 -l | grep -q ":67" && echo "✅ Puerto 67 (DHCP) - ESCUCHANDO" || echo "❌ Puerto 67 - NO escucha"
sockstat -4 -l | grep -q ":25" && echo "✅ Puerto 25 (SMTP) - ESCUCHANDO" || echo "❌ Puerto 25 - NO escucha"
echo ""
echo "🌐 REDES:"
echo "vtnet0 (Servicios): $(ifconfig vtnet0 | grep 'inet ' | awk '{print $2}')"
echo "vtnet1 (Admin): $(ifconfig vtnet1 | grep 'inet ' | awk '{print $2}')"
echo ""
echo "📊 DHCP CLIENTES:"
[ -f "/var/db/dhcpd/dhcpd.leases" ] && echo "✅ Archivo de leases activo" || echo "⚠️  Esperando clientes DHCP"
EOF

chmod +x /root/verificar_servicios.sh
/root/verificar_servicios.sh
```

---

## 🎯 **5. PRUEBAS CON CLIENTES REALES**

### Para probar DHCP:
1. **Conecta un cliente** a la misma red que vtnet0 (172.16.50.0/24)
2. **Configura el cliente** para obtener IP automáticamente
3. **Verifica** que recibe una IP del rango 172.16.50.100-200

### Para probar correo:
```bash
# Enviar correo de prueba masivo
echo "=== 📧 PRUEBA MASIVA DE CORREO ==="
for i in 1 2 3; do
    echo "Mensaje de prueba $i" | mail -s "Test $i" root
    echo "Enviado correo $i"
done

# Ver todos los logs recientes
echo "=== 📨 LOGS RECIENTES ==="
tail -20 /var/log/maillog
```

---

## 🛠️ **6. MONITOREO EN TIEMPO REAL**

### Ver todo en una sola terminal:
```bash
echo "=== 🔍 MONITOREO INTEGRAL ==="
echo "Presiona Ctrl+C para salir"
echo "DHCP Logs:"
tail -f /var/log/dhcpd.log &
echo "Mail Logs:"  
tail -f /var/log/maillog &
wait
```

**¿Qué prueba quieres ejecutar primero?** 🚀
