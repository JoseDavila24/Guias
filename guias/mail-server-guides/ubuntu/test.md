# Mini Guía - Gestión del Sistema de Correos Pasivos

## 1. Añadir Nuevos Usuarios

```bash
# Crear usuario nuevo
sudo adduser pedro

# Crear su buzón Maildir
sudo -u pedro maildirmake.dovecot /home/pedro/Maildir
sudo chmod -R 700 /home/pedro/Maildir
sudo chown -R pedro:pedro /home/pedro/Maildir
```

## 2. Crear Grupos (Alias)

### Editar archivo de aliases:
```bash
sudo nano /etc/aliases
```

### Ejemplos de grupos:
```
# Grupos existentes
postmaster: juan
root: juan
avisos: juan, maria
soporte: juan
direccion: maria

# NUEVOS GRUPOS
desarrollo: juan, pedro
gerencia: maria, juan
todos: juan, maria, pedro
ventas: pedro
```

### Aplicar cambios:
```bash
sudo newaliases
sudo postfix reload
```

## 3. Enviar Correos desde el Servidor

### Método 1: Usando `sendmail`
```bash
# A usuario individual
echo "Asunto: Mensaje importante" | sendmail -v maria@jmrd.com

# Con cuerpo de mensaje
printf "Subject: Reunión mañana\n\nHola María,\n\nTe espero en la reunión a las 10:00.\n\nSaludos\n" | sendmail -v juan@jmrd.com

# A un grupo completo
printf "Subject: Aviso a todos\n\nEste mensaje es para todo el equipo.\n" | sendmail -v todos@jmrd.com
```

### Método 2: Usando `mail` command
```bash
# Instalar si no está
sudo apt install mailutils

# Enviar correo simple
echo "Cuerpo del mensaje" | mail -s "Asunto del correo" pedro@jmrd.com

# Enviar a múltiples destinatarios
echo "Mensaje grupal" | mail -s "Aviso general" juan@jmrd.com maria@jmrd.com pedro@jmrd.com
```

### Método 3: Desde archivo
```bash
# Crear archivo con el mensaje
cat > mensaje.txt << EOF
Subject: Informe mensual

Estimados todos,

Adjunto encontrarán el informe del mes.

Saludos cordiales.
EOF

# Enviar desde archivo
sendmail -v desarrollo@jmrd.com < mensaje.txt
```

## 4. Comandos Útiles de Verificación

### Verificar entrega de correos:
```bash
# Monitorear logs en tiempo real
sudo tail -f /var/log/mail.log

# Ver buzones de usuarios
sudo ls -la /home/juan/Maildir/new/
sudo ls -la /home/maria/Maildir/new/

# Ver contenido de correos (solo lectura)
sudo cat /home/juan/Maildir/new/*

# Probar autenticación de nuevo usuario
sudo doveadm auth test pedro
```

### Verificar configuración de aliases:
```bash
# Ver aliases activos
sudo postalias /etc/aliases

# Probar expansión de alias
postmap -q todos hash:/etc/aliases
```

## 5. Ejemplos Prácticos de Uso

### Notificación del sistema:
```bash
# Notificación de backup (va a postmaster -> juan)
echo "Backup completado exitosamente" | mail -s "Backup Diario" postmaster@jmrd.com
```

### Aviso a departamento:
```bash
printf "Subject: Reunión de desarrollo\n\nEquipo de desarrollo:\nReunión hoy a las 15:00 en sala 2.\n" | sendmail -v desarrollo@jmrd.com
```

### Mensaje a toda la empresa:
```bash
echo "Mañana es feriado nacional. Oficinas cerradas." | mail -s "Aviso Feriado" todos@jmrd.com
```

## 6. Resumen Rápido

```bash
# Flujo completo para nuevo usuario + enviar mensaje:
sudo adduser ana
sudo -u ana maildirmake.dovecot /home/ana/Maildir
sudo chmod -R 700 /home/ana/Maildir
sudo chown -R ana:ana /home/ana/Maildir

# Agregar a grupos (editar /etc/aliases y luego):
sudo newaliases
sudo postfix reload

# Enviar mensaje de bienvenida:
echo "Bienvenida al equipo Ana!" | mail -s "Bienvenida" ana@jmrd.com
```

**Recordatorio:** Los usuarios en Thunderbird solo pueden recibir, no enviar. Todo el envío se hace desde la línea de comandos del servidor.
