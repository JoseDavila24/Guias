## 🧭 Paso 0 — Nombres y dominio que usaremos

* **Dominio interno:** `jmrd.com`
* **Hostname del servidor:** `mail.jmrd.com` (apuntando a **172.21.45.102**)

> Si cambias el dominio, reemplázalo en los comandos.

---

## 1) Preparar resolución de nombres

### 1.1. En **Windows** (donde usarás Thunderbird)

Abrir el bloc de notas **como Administrador** y editar:

```
C:\Windows\System32\drivers\etc\hosts
```

Añade esta línea y guarda:

```
172.21.45.102   mail.jmrd.com
```

### 1.2. En la **VM** (Multipass)

Entra a la VM y configura hostname y `/etc/hosts`:

```bash
multipass shell correo

# Hostname/FQDN
sudo hostnamectl set-hostname mail.jmrd.com
echo jmrd.com | sudo tee /etc/mailname

# /etc/hosts (NO mezclar localhost con la IP de la VM)
sudo bash -c 'cat >/etc/hosts <<EOF
127.0.0.1   localhost
172.21.45.102 mail.jmrd.com mail
EOF'
```

> Corregimos el error típico de poner `localhost` en la misma línea de la IP del servidor. 

---

## 2) Instalar paquetes mínimos

```bash
sudo apt update && sudo apt -y upgrade
sudo apt -y install postfix dovecot-imapd mailutils
```

Durante la instalación de **Postfix**:

* Tipo: **Internet Site**
* System mail name: **jmrd.com**

---

## 3) Postfix (SMTP) — configuración base + envío autenticado (587)

Edita `/etc/postfix/main.cf` y deja al menos esto:

```ini
# Identidad
myhostname = mail.jmrd.com
mydomain = jmrd.com
myorigin = /etc/mailname
mydestination = $myhostname, $mydomain, localhost.$mydomain, localhost

# Red / protocolos
inet_interfaces = all
inet_protocols = ipv4

# Buzones en formato Maildir
home_mailbox = Maildir/

# Mapas de alias
alias_maps = hash:/etc/aliases
alias_database = hash:/etc/aliases

# TLS (usar certificados "snakeoil" por simplicidad)
smtpd_tls_cert_file = /etc/ssl/certs/ssl-cert-snakeoil.pem
smtpd_tls_key_file  = /etc/ssl/private/ssl-cert-snakeoil.key
smtpd_tls_security_level = may
smtp_tls_security_level  = may

# SASL con Dovecot (para SMTP AUTH en puerto 587)
smtpd_sasl_type = dovecot
smtpd_sasl_path = private/auth
smtpd_sasl_auth_enable = yes
smtpd_sasl_security_options = noanonymous

# Reglas de relé (no ser open relay)
smtpd_relay_restrictions = permit_mynetworks, permit_sasl_authenticated, reject_unauth_destination
```

Activa el servicio **submission (587)** con TLS obligatorio y AUTH:

```bash
sudo postconf -M submission/inet='submission inet n - y - - smtpd'
sudo postconf -P 'submission/inet/syslog_name=postfix/submission'
sudo postconf -P 'submission/inet/smtpd_tls_security_level=encrypt'
sudo postconf -P 'submission/inet/smtpd_sasl_auth_enable=yes'
sudo postconf -P 'submission/inet/milter_macro_daemon_name=ORIGINATING'
```

> Añadimos también `alias_database` y reforzamos el relé con `smtpd_relay_restrictions`. 

Aplica cambios:

```bash
sudo newaliases
sudo systemctl restart postfix
sudo postconf -n | sed -n '1,200p'
```

---

## 4) Dovecot (IMAP) — Maildir + TLS + socket para Postfix

### 4.1. Ubicación de buzones

```
sudo sed -i 's|^#\?mail_location.*|mail_location = maildir:~/Maildir|' /etc/dovecot/conf.d/10-mail.conf
```

### 4.2. Autenticación segura

```
sudo sed -i 's/^#\?disable_plaintext_auth.*/disable_plaintext_auth = yes/' /etc/dovecot/conf.d/10-auth.conf
sudo sed -i 's/^#\?auth_mechanisms.*/auth_mechanisms = plain login/' /etc/dovecot/conf.d/10-auth.conf
```

### 4.3. SSL/TLS

```
sudo sed -i 's/^#\?ssl = .*/ssl = yes/' /etc/dovecot/conf.d/10-ssl.conf
sudo sed -i 's|^#\?ssl_cert =.*|ssl_cert = </etc/ssl/certs/ssl-cert-snakeoil.pem|' /etc/dovecot/conf.d/10-ssl.conf
sudo sed -i 's|^#\?ssl_key =.*|ssl_key = </etc/ssl/private/ssl-cert-snakeoil.key|' /etc/dovecot/conf.d/10-ssl.conf
```

### 4.4. Socket SASL para Postfix (imprescindible para AUTH)

Abre `/etc/dovecot/conf.d/10-master.conf` y asegúrate de **descomentar/añadir**:

```conf
service auth {
  unix_listener /var/spool/postfix/private/auth {
    mode = 0660
    user = postfix
    group = postfix
  }
}
```

Aplica cambios y verifica:

```bash
sudo systemctl restart dovecot
sudo doveconf -n | sed -n '1,200p'
```

> En tu guía original se utilizaba autenticación en texto plano “para taller”; aquí activamos STARTTLS y dejamos AUTH seguro como camino principal. 

---

## 5) Usuarios y Maildir

```bash
# Crea usuarios
sudo adduser juan
sudo adduser maria

# Crea Maildir con permisos correctos
sudo -u juan  maildirmake.dovecot ~/Maildir
sudo -u maria maildirmake.dovecot ~/Maildir
sudo chmod -R 700 /home/*/Maildir
```

---

## 6) Alias internos (incluye postmaster/root)

Edita `/etc/aliases` y añade (además de tus grupos):

```
postmaster: juan
root: juan
avisos: juan, maria
soporte: juan
direccion: maria
```

```bash
sudo newaliases
sudo postfix reload
```

> Redirigir `postmaster` y `root` a un buzón real es buena práctica y requerido por estándares. 

---

## 7) Pruebas rápidas en servidor

```bash
# Servicios y puertos
systemctl --no-pager status postfix dovecot
ss -lntp | grep -E ':25|:143|:587'

# Autenticación Dovecot
sudo doveadm auth test juan
sudo doveadm auth test maria

# Entrega local
printf "Subject: Test Local\n\nHola Maria\n" | sendmail -v maria@jmrd.com
sudo tail -n 80 /var/log/mail.log | tail
```

*Opcional TLS SMTP:*

```bash
# Comprobar que 587 acepta STARTTLS y AUTH
nc -vz mail.jmrd.com 587
```

---

## 8) Configurar Thunderbird (en Windows)

**Cuenta IMAP (recomendada):**

* **Nombre:** Juan Pérez
* **Correo:** `juan@jmrd.com`
* **Contraseña:** (la de `juan`)
* Ir a **Configuración manual** y usa:

| Parámetro     | Entrante (IMAP)   | Saliente (SMTP)   |
| ------------- | ----------------- | ----------------- |
| Servidor      | mail.jmrd.com     | mail.jmrd.com     |
| Puerto        | **143**           | **587**           |
| Seguridad     | **STARTTLS**      | **STARTTLS**      |
| Autenticación | Contraseña normal | Contraseña normal |
| Usuario       | juan              | juan              |

**Probar:**

* Desde `juan@jmrd.com`, envía a `maria@jmrd.com`.
* Revisa INBOX de María.
* En el servidor, valida:

  ```bash
  sudo tail -n 50 /var/log/mail.log | grep maria
  ```

> Nota: “From:” mostrará `usuario@jmrd.com`; los *Received:* del encabezado muestran el host `mail.jmrd.com`. 

---

## 9) (Opcional) Modo **solo laboratorio** (sin TLS y SMTP 25 sin AUTH)

> Úsalo solo en redes de práctica. Las contraseñas viajan en claro.

1. En **Dovecot** (`/etc/dovecot/conf.d/10-auth.conf`):

   ```
   disable_plaintext_auth = no
   ```
2. En **Thunderbird**:

   * IMAP 143 **Seguridad: Ninguna**
   * SMTP 25 **Autenticación: Sin autenticación**
3. (Si quieres permitir envío por red local sin AUTH) ajusta en `/etc/postfix/main.cf`:

   ```
   mynetworks = 127.0.0.0/8 172.21.45.0/24
   ```

   y reinicia Postfix.

   > Recuerda: esto solo funciona si el cliente realmente sale desde esa subred. 

---

## 10) Firewall (si usas UFW)

```bash
sudo ufw allow 25,143,587/tcp
sudo ufw enable
sudo ufw status
```

---

## 11) Diagnóstico express

```bash
# Log de Postfix y Dovecot
sudo tail -f /var/log/mail.log
sudo journalctl -u dovecot -f

# Buzones
ls -la /home/juan/Maildir
ls -la /home/maria/Maildir

# Verifica que Thunderbird use el SMTP correcto
```

---

## 12) Si cambia la IP de la VM

* Actualiza **Windows `hosts`** y **`/etc/hosts` de la VM** con la nueva IP.
* Si usas el modo laboratorio con `mynetworks`, ajusta el prefijo a la nueva subred.

---

### ✅ Resumen

* **Seguro por defecto:** IMAP 143/STARTTLS y SMTP 587/STARTTLS+AUTH.
* **Correcciones clave:** `/etc/hosts` limpio, `alias_database`, `submission` en 587, socket SASL Dovecot para Postfix, `postmaster/root` redirigidos. 
* **Listo para operar** como correo **interno** (pasivo) con alias y clientes Thunderbird.

Si te parece, al finalizar copia aquí la salida de:

```bash
postconf -n
doveconf -n
```

y reviso que todo haya quedado perfecto con tu IP **172.21.45.102**.
