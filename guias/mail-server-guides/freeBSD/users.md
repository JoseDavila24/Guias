# 👥 CREACIÓN DE USUARIOS Y CONFIGURACIÓN CORREO

## PASO 1: CREAR GRUPO Y USUARIOS

### 1.1 Crear grupo recursoshumanos:
```bash
pw groupadd recursoshumanos
```

### 1.2 Crear usuario brenda:
```bash
pw useradd brenda -c "Brenda - Recursos Humanos" -m -s /bin/tcsh -G recursoshumanos
echo "1234" | pw mod user brenda -h 0```

### 1.3 Crear usuario wendy:
```bash
pw useradd wendy -c "Wendy - Recursos Humanos" -m -s /bin/tcsh -G recursoshumanos
echo "1234" | pw mod user wendy -h 0
```

### 1.4 Crear buzones Maildir:
```bash
su - brenda -c "mkdir -p ~/Maildir/{cur,new,tmp}"
su - wendy -c "mkdir -p ~/Maildir/{cur,new,tmp}"
```

---

## PASO 2: CONFIGURAR DOVECOT (IMAP)

### 2.1 Instalar Dovecot:
```bash
pkg install -y dovecot
```

### 2.2 Configurar Dovecot:
```bash
sysrc dovecot_enable="YES"

# Configuración básica
cat > /usr/local/etc/dovecot/dovecot.conf << 'EOF'
listen = *
protocols = imap
mail_location = maildir:~/Maildir
ssl = no
disable_plaintext_auth = no
auth_mechanisms = plain login
EOF

# Iniciar Dovecot
service dovecot start
```

---

## PASO 3: CONFIGURAR ALIASES DE CORREO

### 3.1 Crear aliases para el grupo:
```bash
cat >> /etc/mail/aliases << 'EOF'

# Recursos Humanos
brenda: brenda
wendy: wendy
rrhh: brenda,wendy
recursoshumanos: brenda,wendy
nominas: brenda,wendy
contrataciones: brenda,wendy
EOF

newaliases
```

---

## PASO 4: ENVIAR MENSAJES DE BIENVENIDA

### 4.1 Enviar mensaje a cada usuario:
```bash
echo "Bienvenida Brenda al sistema de correo de Recursos Humanos" | mail -s "Bienvenida al Sistema" brenda
echo "Bienvenida Wendy al sistema de correo de Recursos Humanos" | mail -s "Bienvenida al Sistema" wendy
```

### 4.2 Enviar mensaje al grupo:
```bash
echo "Mensaje de prueba para todo el departamento de Recursos Humanos" | mail -s "Prueba de Grupo RRHH" rrhh
```

---

## 📱 PASO 5: CONFIGURACIÓN EN CLIENTES (Sylpheed/Thunderbird)

### **Configuración para Sylpheed/Cliente IMAP:**

**Cuenta de Brenda:**
```
Nombre: Brenda
Email: brenda@jmrd.com
Usuario: brenda
Contraseña: 1234

Servidor IMAP: 172.16.50.10
Puerto IMAP: 143
Seguridad: Sin SSL/TLS

Servidor SMTP: 172.16.50.10  
Puerto SMTP: 25
Seguridad: Sin SSL/TLS
Autenticación: Ninguna
```

**Cuenta de Wendy:**
```
Nombre: Wendy
Email: wendy@jmrd.com
Usuario: wendy
Contraseña: 1234

Servidor IMAP: 172.16.50.10
Puerto IMAP: 143
Seguridad: Sin SSL/TLS

Servidor SMTP: 172.16.50.10
Puerto SMTP: 25
Seguridad: Sin SSL/TLS
Autenticación: Ninguna
```

---

## ✅ PASO 6: VERIFICACIÓN

### 6.1 Verificar usuarios creados:
```bash
echo "=== USUARIOS CREADOS ==="
id brenda
id wendy
pw groupshow recursoshumanos
```

### 6.2 Verificar servicios:
```bash
echo "=== SERVICIOS ACTIVOS ==="
service dovecot status
sockstat -4 -l | grep :143
```

### 6.3 Probar recepción de correos:
```bash
echo "=== PRUEBA DE CORREOS ==="
su - brenda -c "ls ~/Maildir/new/"
su - wendy -c "ls ~/Maildir/new/"
```

---

## 🎯 RESUMEN PARA CLIENTES:

**Información para configurar en Sylpheed:**
```
Servidor: 172.16.50.10
IMAP: Puerto 143 (sin SSL)
SMTP: Puerto 25 (sin SSL) 
Usuarios: brenda / wendy
Contraseña: 1234
Dominio: jmrd.com
```

**Listas de correo disponibles:**
- `brenda@jmrd.com` - Brenda individual
- `wendy@jmrd.com` - Wendy individual  
- `rrhh@jmrd.com` - Todo el departamento
- `recursoshumanos@jmrd.com` - Todo el departamento
- `nominas@jmrd.com` - Ambas usuarias
- `contrataciones@jmrd.com` - Ambas usuarias

**¡Los usuarios están listos para usar el correo!** 📧
