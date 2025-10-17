# Guía exprés — FreeBSD + Postfix + Dovecot (LAB sin seguridad, con IP)

**Escenario**

* **Hypervisor:** VirtualBox
* **SO:** FreeBSD 13/14
* **Dominio interno:** `jmrd.local` (puedes cambiarlo)
* **FQDN del servidor:** `mail.jmrd.local` (solo identidad local)
* **Cliente:** Windows + Thunderbird (usará **la IP** del servidor)

> **Red de VM:** usa **Bridged** o **Host‑Only** (recomendado). **NAT** puro no permite conexiones entrantes desde Windows sin *port‑forwarding*.

---

## 0) Antes de empezar

1. Arranca FreeBSD y **anota la IP** de la interfaz que Windows puede alcanzar (ej.: `192.168.56.10` si es Host‑Only, o la de tu LAN si es Bridged):

   ```sh
   ifconfig -a | egrep 'inet '
   ```
2. (Opcional) Actualiza base:

   ```sh
   freebsd-update fetch install
   ```

---

## 1) Paquetes

```sh
pkg update
pkg install -y postfix dovecot
```

---

## 2) Desactivar sendmail, activar Postfix/Dovecot

```sh
# Desactivar todos los demonios de sendmail (base)
sysrc sendmail_enable="NO"
sysrc sendmail_submit_enable="NO"
sysrc sendmail_outbound_enable="NO"
sysrc sendmail_msp_queue_enable="NO"

# Activar Postfix y Dovecot al arrancar
sysrc postfix_enable="YES"
sysrc dovecot_enable="YES"

# mailer.conf -> que 'sendmail/newaliases' apunten a Postfix
cp /usr/local/share/postfix/mailer.conf /etc/mail/mailer.conf
```

---

## 3) Identidad local y hosts (solo en el **servidor**)

> Usamos **FQDN local**; el **cliente** usará **IP directa**, sin tocar `hosts` en Windows.

```sh
# Hostname del sistema
sysrc hostname="mail.jmrd.local"
service hostname restart

# /etc/hosts (NO mezclar 'localhost' con la IP real)
cat > /etc/hosts <<EOF
127.0.0.1       localhost
# Sustituye por TU IP real alcanzable desde Windows:
192.168.56.10   mail.jmrd.local mail
EOF
```

*(Evita poner `localhost` en la misma línea de la IP — clásico error.)* 

---

## 4) Postfix (SMTP 25, sin AUTH, entrega local)

```sh
# Fichero principal: /usr/local/etc/postfix/main.cf  (usamos postconf -e)
postfix set-permissions   # opcional, normaliza permisos

postconf -e "myhostname=mail.jmrd.local"
postconf -e "mydomain=jmrd.local"
postconf -e "myorigin=jmrd.local"
postconf -e "mydestination=\$myhostname, \$mydomain, localhost.\$mydomain, localhost"
postconf -e "inet_interfaces=all"
postconf -e "inet_protocols=ipv4"
postconf -e "home_mailbox=Maildir/"
postconf -e "mynetworks=127.0.0.0/8"
postconf -e "smtpd_relay_restrictions=permit_mynetworks, reject_unauth_destination"

# Alias del sistema (minimos recomendados)
grep -q '^postmaster:' /etc/aliases || cat >> /etc/aliases <<'EOF'
postmaster: root
root:       juan
avisos:     juan, maria
EOF

newaliases
service postfix restart
```

> Con esto, **solo** se entrega a destinatarios **locales** `@jmrd.local`. Se **rechaza** relé externo (por `reject_unauth_destination`). Igual que en Ubuntu LAB. 

---

## 5) Dovecot (IMAP 143, en claro)

Ficheros en `/usr/local/etc/dovecot/`:

```sh
# /usr/local/etc/dovecot/dovecot.conf
printf '%s\n' '!include conf.d/*.conf' 'protocols = imap' 'listen = *' > /usr/local/etc/dovecot/dovecot.conf

# /usr/local/etc/dovecot/conf.d/10-mail.conf
sed -i '' 's|^#\?mail_location.*|mail_location = maildir:~/Maildir|' /usr/local/etc/dovecot/conf.d/10-mail.conf

# /usr/local/etc/dovecot/conf.d/10-auth.conf
sed -i '' 's/^#\?disable_plaintext_auth.*/disable_plaintext_auth = no/' /usr/local/etc/dovecot/conf.d/10-auth.conf
sed -i '' 's/^#\?auth_mechanisms.*/auth_mechanisms = plain login/' /usr/local/etc/dovecot/conf.d/10-auth.conf

# /usr/local/etc/dovecot/conf.d/10-ssl.conf
sed -i '' 's/^#\?ssl = .*/ssl = no/' /usr/local/etc/dovecot/conf.d/10-ssl.conf

service dovecot restart
```

---

## 6) Usuarios y Maildir (rutas absolutas + permisos por usuario)

```sh
# Cuentas de ejemplo
pw useradd -n juan -m -s /bin/sh && passwd juan
pw useradd -n maria -m -s /bin/sh && passwd maria

# Inicializar Maildir (estructura mínima)
mkdir -p /home/juan/Maildir/{cur,new,tmp}
mkdir -p /home/maria/Maildir/{cur,new,tmp}
chmod -R 700 /home/juan/Maildir /home/maria/Maildir
chown -R juan:juan /home/juan/Maildir
chown -R maria:maria /home/maria/Maildir
```

*(Las rutas absolutas y permisos por usuario evitan errores de propiedad/expansión. Igual que en la guía de Ubuntu.)* 

---

## 7) Verificación rápida (servidor)

```sh
# Puertos
sockstat -4 -l | egrep '(:25|:143)'

# Autenticación IMAP (texto claro)
doveadm auth test juan
doveadm auth test maria

# Envío local (Juan -> María)
printf "Subject: Test A->B\n\nHola Maria\n" | sendmail -v maria@jmrd.local
tail -n 50 /var/log/maillog
```

**Esperado:** `status=sent (delivered to mailbox)`.

---

## 8) Thunderbird en Windows (con **IP** directa)

1. Asegúrate de que el Windows llega a la IP de la VM (misma red Host‑Only/Bridged).
2. **Crear cuenta** → **Configuración manual**:

   * **IMAP**: **Servidor = <IP de la VM>**, **Puerto 143**, **Seguridad: Ninguna**, **Auth: Contraseña normal**, **Usuario: juan**.
   * **SMTP**: **Servidor = <IP de la VM>**, **Puerto 25**, **Seguridad: Ninguna**, **Auth: Sin autenticación**.
3. **Probar**: enviar desde `juan@jmrd.local` a `maria@jmrd.local`; en la cuenta de María, **Recibir**.

> Si la IP del FreeBSD cambia, **solo** actualiza esa IP en Thunderbird (no hay que tocar el servidor).

---

## 9) Diagnóstico útil

```sh
# Logs en vivo
tail -f /var/log/maillog

# Ver buzones
ls -la /home/juan/Maildir/new/
ls -la /home/maria/Maildir/new/

# Conectividad desde Windows (opcional)
#   telnet <IP> 25
#   telnet <IP> 143
```

---

### Notas finales

* **Seguridad mínima**: IMAP 143 en claro + SMTP 25 sin AUTH (solo entrega local).
* **Sin tocar Windows hosts**: el cliente usa la **IP**.
* **No open relay**: bloqueado por `reject_unauth_destination`.
* **Buenas prácticas mínimas**: alias `postmaster/root`, Maildir con permisos 700, revisar `maillog`.
* Esta guía es la **versión FreeBSD** de tu laboratorio en Ubuntu, con los mismos principios y correcciones clave. 
