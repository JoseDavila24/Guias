## 0) Datos que vas a usar

* **Dominio**: `jmrd.com`
* **IP de la VM (FreeBSD en Hyper‑V)**: la llamaremos **`VM_IP`** (ej. `192.168.100.10`)
* **Red del lab en CIDR**: la llamaremos **`LAB_CIDR`** (ej. `192.168.100.0/24`)
* **Interfaz en Hyper‑V**: normalmente `hn0` en FreeBSD (driver Hyper‑V)

Encuentra la IP real y tu red:

```sh
ifconfig hn0 | grep -E 'inet '           # mira la IP (VM_IP)
netstat -rn | head -n 5                  # te ayuda a deducir el LAB_CIDR
```

> Si no quieres comerte la cabeza con CIDR, usa la subred /24 donde está tu IP (p.ej. si VM_IP es 192.168.100.10, pon LAB_CIDR=192.168.100.0/24).

---

## 1) Preparar el sistema

**(a) Hostname y resolución local (opcional pero recomendado)**

```sh
sysrc hostname="jmrd.com"
hostname jmrd.com
```

En **/etc/hosts** de clientes y del propio servidor, puedes añadir (si quieres resolver el nombre además de usar la IP):

```
VM_IP jmrd.com
```

**(b) Paquetes**

```sh
pkg update
pkg install -y postfix dovecot
sysrc postfix_enable=YES
sysrc dovecot_enable=YES
```

**(c) mailer.conf → Postfix**
Asegúrate de que las utilidades “sendmail” apuntan a Postfix:

Edita **/etc/mail/mailer.conf** y déjalo así:

```
sendmail        /usr/local/sbin/sendmail
send-mail       /usr/local/sbin/sendmail
mailq           /usr/local/sbin/mailq
newaliases      /usr/local/sbin/newaliases
```

---

## 2) Crear usuarios del sistema

```sh
pw useradd -n roberto   -m -s /bin/sh && passwd roberto
pw useradd -n francisco -m -s /bin/sh && passwd francisco
pw useradd -n mauricio  -m -s /bin/sh && passwd mauricio

# (Opcional) Pre-crear Maildir
su - roberto   -c 'mkdir -p ~/Maildir/{cur,new,tmp}'
su - francisco -c 'mkdir -p ~/Maildir/{cur,new,tmp}'
su - mauricio  -c 'mkdir -p ~/Maildir/{cur,new,tmp}'
```

---

## 3) Alias/grupos

Edita **/etc/mail/aliases**:

```
# Usuarios
roberto:    roberto
francisco:  francisco
mauricio:   mauricio

# Listas
avisos:     roberto, francisco, mauricio
sistemas:   roberto, francisco
otro:       mauricio
```

Compila:

```sh
newaliases
```

---

## 4) Configurar **Postfix** (SMTP local + acceso desde la IP de la VM)

Queremos que Thunderbird pueda conectarse al **SMTP de la VM** usando la **IP** (servidor de salida), pero que **solo acepte destinatarios del propio dominio/local** y **rechace** relé hacia dominios externos. Además, entrega en **Maildir**.

> Sustituye **VM_IP** y **LAB_CIDR** por tus valores reales.

```sh
# Identidad y dominios locales
postconf -e "myhostname = jmrd.com"
postconf -e "mydomain = jmrd.com"
postconf -e "myorigin = \$mydomain"

# Escuchar en la IP de la VM (y en todas) para que Thunderbird pueda usarla
postconf -e "inet_interfaces = all"
postconf -e "inet_protocols = ipv4"

# Destinos que este Postfix considera "locales"
postconf -e "mydestination = \$myhostname, localhost.\$mydomain, localhost, \$mydomain"

# Entrega en Maildir bajo $HOME
postconf -e "home_mailbox = Maildir/"

# Alias locales
postconf -e "alias_maps = hash:/etc/mail/aliases"
postconf -e "alias_database = hash:/etc/mail/aliases"

# --- Seguridad mínima y límites de alcance ---

# 1) Solo clientes de tu LAN pueden abrir sesión SMTP (el resto se rechaza)
postconf -e "mynetworks = 127.0.0.0/8, LAB_CIDR"
postconf -e "smtpd_client_restrictions = permit_mynetworks, reject"

# 2) No relé a dominios externos: acepta solo destinatarios locales
postconf -e "smtpd_relay_restrictions = reject_unauth_destination"

# 3) Rechazar destinatarios inexistentes localmente (evita colas inútiles)
postconf -e "local_recipient_maps = unix:passwd.byname \$alias_maps"

# 4) Sin TLS (laboratorio; para que TB use “Sin cifrado”)
postconf -e "smtpd_tls_security_level = none"

service postfix restart
```

> Con esto, **Thunderbird** podrá **enviar** al SMTP de la VM **solo** a cuentas/alias locales de `jmrd.com`. Si alguien intenta `usuario@otrodominio.com`, será **rechazado** en RCPT (no hace relé).

> **¿Quieres “solo recibir” sin que Thunderbird pueda enviar?** En ese caso, cambia:
>
> ```
> postconf -e "inet_interfaces = loopback-only"
> service postfix restart
> ```
>
> y Thunderbird **no** podrá usar la IP para SMTP. (Tú decides; por tu última petición te dejo habilitado el SMTP en la IP de la VM.)

---

## 5) Configurar **Dovecot** (IMAP/POP3 sin TLS, solo lab)

Copia la config de ejemplo si aún no existe:

```sh
[ -f /usr/local/etc/dovecot/dovecot.conf ] || \
  cp -R /usr/local/etc/dovecot/example-config/* /usr/local/etc/dovecot/
```

Ajustes mínimos:

* **/usr/local/etc/dovecot/conf.d/10-mail.conf**

```
mail_location = maildir:~/Maildir
```

* **/usr/local/etc/dovecot/conf.d/10-ssl.conf**

```
ssl = no
```

* **/usr/local/etc/dovecot/conf.d/10-auth.conf**

```
disable_plaintext_auth = no
auth_mechanisms = plain login
```

* **/usr/local/etc/dovecot/dovecot.conf** (asegúrate de escuchar en todas las IP)

```
listen = *
protocols = imap pop3
```

Reinicia:

```sh
service dovecot restart
```

---

## 6) Comprobaciones rápidas

```sh
# Ver puertos escuchando (25 SMTP, 110 POP3, 143 IMAP en 0.0.0.0)
sockstat -4 -l | egrep '(:25|:110|:143)'

# Postfix efectivo
postconf -n | egrep '^(myhostname|mydomain|myorigin|inet_interfaces|inet_protocols|mydestination|home_mailbox|mynetworks|smtpd_client_restrictions|smtpd_relay_restrictions|local_recipient_maps|smtpd_tls_security_level)'

# Dovecot efectivo
doveconf -n | egrep '^(listen|protocols|mail_location|ssl|disable_plaintext_auth|auth_mechanisms)'
```

---

## 7) Prueba de entrega interna (desde el servidor)

```sh
printf "Hola Roberto.\n"          | mail -s "Prueba usuario" roberto@jmrd.com
printf "Aviso para sistemas.\n"   | mail -s "Prueba lista"   sistemas@jmrd.com
printf "Mensaje general.\n"       | mail -s "Prueba avisos"  avisos@jmrd.com

tail -n 50 /var/log/maillog
```

---

## 8) Configurar **Thunderbird** usando **la IP de la VM** (entrante y salida)

> Sustituye `VM_IP` por tu IP real (ej. `192.168.100.10`).

**Cuenta de correo (por ejemplo, Roberto)**

* **Nombre**: Roberto
* **Dirección de correo**: `roberto@jmrd.com`
* **Nombre de usuario** (login): `roberto`
* **Contraseña**: la de la cuenta del sistema

**Servidor entrante (IMAP recomendado)**

* Servidor: `VM_IP`
* Puerto: **143**
* Conexión: **Ninguna**
* Autenticación: **Contraseña normal**

*(Si prefieres POP3: puerto **110**, misma seguridad y autenticación.)*

**Servidor de salida (SMTP)**

* Servidor: `VM_IP`
* Puerto: **25**
* Conexión: **Ninguna**
* Autenticación: **Ninguna** (como estás dentro de **LAB_CIDR**, Postfix te dejará entregar **solo** a `@jmrd.com`)

**Prueba desde Thunderbird**

* Enviar a: `francisco@jmrd.com`, `avisos@jmrd.com`, etc.
* Recibir con IMAP/POP3 y verifica que llegan a las bandejas correctas.

---

## 9) Bloques “todo en uno” (para ir más rápido)

> Edita las variables **VM_IP** y **LAB_CIDR** antes de pegar.

```sh
# === VARIABLES ===
VM_IP="192.168.100.10"           # <-- cambia por la IP real de tu VM
LAB_CIDR="192.168.100.0/24"      # <-- cambia por tu subred real
DOMAIN="jmrd.com"

# === HOSTNAME (opcional) ===
sysrc hostname="$DOMAIN"
hostname "$DOMAIN"

# === PAQUETES ===
pkg update
pkg install -y postfix dovecot

# === ACTIVAR SERVICIOS ===
sysrc postfix_enable=YES
sysrc dovecot_enable=YES

# === mailer.conf -> Postfix ===
cat > /etc/mail/mailer.conf <<'EOF'
sendmail        /usr/local/sbin/sendmail
send-mail       /usr/local/sbin/sendmail
mailq           /usr/local/sbin/mailq
newaliases      /usr/local/sbin/newaliases
EOF

# === USUARIOS ===
for u in roberto francisco mauricio; do
  id "$u" >/dev/null 2>&1 || pw useradd -n "$u" -m -s /bin/sh
  su - "$u" -c 'mkdir -p ~/Maildir/{cur,new,tmp}'
done
echo ">>> Establece contraseñas con:  passwd roberto|francisco|mauricio"

# === ALIASES ===
cat > /etc/mail/aliases <<'EOF'
postmaster: root
root:       root

roberto:    roberto
francisco:  francisco
mauricio:   mauricio

avisos:     roberto, francisco, mauricio
sistemas:   roberto, francisco
otro:       mauricio
EOF
newaliases

# === POSTFIX ===
postconf -e "myhostname = $DOMAIN"
postconf -e "mydomain = $DOMAIN"
postconf -e "myorigin = \$mydomain"

postconf -e "inet_interfaces = all"
postconf -e "inet_protocols = ipv4"
postconf -e "mydestination = \$myhostname, localhost.\$mydomain, localhost, \$mydomain"
postconf -e "home_mailbox = Maildir/"
postconf -e "alias_maps = hash:/etc/mail/aliases"
postconf -e "alias_database = hash:/etc/mail/aliases"

postconf -e "mynetworks = 127.0.0.0/8, $LAB_CIDR"
postconf -e "smtpd_client_restrictions = permit_mynetworks, reject"
postconf -e "smtpd_relay_restrictions = reject_unauth_destination"
postconf -e "local_recipient_maps = unix:passwd.byname \$alias_maps"
postconf -e "smtpd_tls_security_level = none"

service postfix restart

# === DOVECOT ===
[ -f /usr/local/etc/dovecot/dovecot.conf ] || \
  cp -R /usr/local/etc/dovecot/example-config/* /usr/local/etc/dovecot/

sed -i '' -e 's|^#\?listen =.*|listen = *|' \
          -e 's|^#\?protocols =.*|protocols = imap pop3|' /usr/local/etc/dovecot/dovecot.conf

sed -i '' -e 's|^#\?mail_location =.*|mail_location = maildir:~/Maildir|' \
          /usr/local/etc/dovecot/conf.d/10-mail.conf

sed -i '' -e 's|^#\?ssl =.*|ssl = no|' \
          /usr/local/etc/dovecot/conf.d/10-ssl.conf

sed -i '' -e 's|^#\?disable_plaintext_auth =.*|disable_plaintext_auth = no|' \
          -e 's|^#\?auth_mechanisms =.*|auth_mechanisms = plain login|' \
          /usr/local/etc/dovecot/conf.d/10-auth.conf

service dovecot restart

# === CHEQUEOS ===
echo ">>> Puertos abiertos (25/110/143):"
sockstat -4 -l | egrep '(:25|:110|:143)'

echo ">>> Postfix:"
postconf -n | egrep '^(myhostname|mydomain|inet_interfaces|mydestination|mynetworks|smtpd_client_restrictions|smtpd_relay_restrictions|home_mailbox)'

echo ">>> Dovecot:"
doveconf -n | egrep '^(listen|protocols|mail_location|ssl|disable_plaintext_auth)'

echo ">>> Envía pruebas:"
echo 'printf "Hola.\n" | mail -s "Prueba" avisos@jmrd.com'
```

---

## 10) Variantes y notas útiles

* **Solo recepción (bloquear envío desde Thunderbird):**
  Cambia `inet_interfaces = loopback-only` y reinicia Postfix. Listo.
* **Permitir envío, pero con usuario/contraseña (SASL via Dovecot):**
  No es “mínimo”, pero si quisieras, se habilita `smtpd_sasl_type = dovecot`, `smtpd_sasl_path = private/auth`, `smtpd_sasl_auth_enable = yes` y en Dovecot el socket `auth` para Postfix. (Puedo darte la receta si te interesa endurecer un poco.)
* **TLS para IMAP/POP3/SMTP (IMAPS/POP3S/Submission 587):**
  Solo si sales del lab. Requiere certificados (self‑signed u otros) y cambiar `ssl = yes` en Dovecot y los listeners `submission` en Postfix.

---

### ¿Qué queda listo con esto?

* Cuentas **roberto**, **francisco**, **mauricio** con buzón **Maildir**.
* Alias **avisos**, **sistemas**, **otro**.
* **Dovecot** sirviendo **IMAP (143)** y **POP3 (110)** sin TLS.
* **Postfix** escuchando en **VM_IP:25**, aceptando **solo** clientes de tu **LAB_CIDR** y **solo** destinatarios locales `@jmrd.com`.
* **Thunderbird** apunta a la **IP** de la VM como servidor entrante y de salida.

Si me dices **cuál es la IP real de tu VM** y **cuál es tu subred**, te devuelvo el bloque “todo en uno” ya **rellenado** para copiar/pegar sin tocar nada.
