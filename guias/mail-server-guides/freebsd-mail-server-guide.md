# Guía de Implementación — **Correo Corporativo Pasivo en FreeBSD (Postfix + Dovecot)**

**Materia:** Sistemas Operativos y Redes · **Sistema:** FreeBSD 13/14 · **Modalidad:** Laboratorio (red interna)
**Fecha límite de entrega:** **30 de octubre**

---

## 1. Objetivo y Alcance

Implementar un **servidor de correo pasivo** en **FreeBSD** accesible únicamente dentro de la red de laboratorio, usando **Postfix** como MTA y **Dovecot** como IMAP/POP (MDA/servidor de buzones). Se trabajará con un **dominio ficticio** basado en iniciales del alumno (p. ej., `alumnoJPL.local`) y al menos **dos cuentas** locales. El acceso de los clientes (Thunderbird o Mutt) será por **IMAP(S)**/**POP3(S)** y **Submission (587)** con autenticación.

> **Terminología clave:**
>
> * **MTA (Mail Transfer Agent):** transporta correo entre servidores (aquí, **Postfix**).
> * **MDA (Mail Delivery Agent) / IMAP/POP:** entrega y expone el buzón al cliente (aquí, **Dovecot**).
> * **MUA (Mail User Agent):** cliente de correo del usuario final (**Thunderbird** o **Mutt**).

---

## 2. Topología de Laboratorio y Nombres

* **Servidor FreeBSD:** `mail.alumnoJPL.local` (reemplazar por sus iniciales)
* **IP del servidor:** `192.168.56.10` (o la que corresponda en su laboratorio)
* **Dominio interno:** `alumnoJPL.local`
* **Usuarios:** `juan`, `ana` (use nombres equivalentes a su equipo)

> **Nota:** Al ser un entorno **pasivo** (sin DNS público), puede resolverse el nombre mediante **/etc/hosts** en el servidor y en los clientes.

---

## 3. Requisitos Previos

1. FreeBSD instalado y actualizado (`freebsd-update fetch install` si aplica).
2. Acceso como `root` (o con `doas/sudo`).
3. Conectividad IP entre clientes y servidor.
4. Reloj del sistema correcto (NTP) para evitar problemas de TLS.

---

## 4. Preparación del Sistema

### 4.1. Ajuste de hostname y resolución local

```sh
# Establecer hostname
sysrc hostname="mail.alumnoJPL.local"
service hostname restart

# /etc/hosts: añadir entrada local y de red
cat >> /etc/hosts <<'EOF'
127.0.0.1      localhost
192.168.56.10  mail.alumnoJPL.local mail
EOF
```

### 4.2. Paquetes necesarios

```sh
pkg update
pkg install -y postfix dovecot bind-tools ca_root_nss mutt openssl
# (Thunderbird en clientes FreeBSD: pkg install -y thunderbird)
```

> `bind-tools` provee **host/nslookup/dig** para pruebas.

---

## 5. Deshabilitar Sendmail y Activar Postfix/Dovecot

FreeBSD trae `sendmail` en base. Deshabilítelo y active Postfix/Dovecot:

```sh
# Deshabilitar todos los demonios de sendmail
sysrc sendmail_enable="NO"
sysrc sendmail_submit_enable="NO"
sysrc sendmail_outbound_enable="NO"
sysrc sendmail_msp_queue_enable="NO"

# Activar Postfix y Dovecot
sysrc postfix_enable="YES"
sysrc dovecot_enable="YES"

# Configurar mailer.conf para Postfix
cp /usr/local/share/postfix/mailer.conf /etc/mail/mailer.conf
```

---

## 6. Certificado TLS Autogenerado (laboratorio)

Para cifrar IMAP(S)/POP3(S) y Submission, genere un certificado **autofirmado**:

```sh
# Directorios (respetar permisos)
mkdir -p /usr/local/etc/ssl/{certs,private}
chmod 700 /usr/local/etc/ssl/private

# Clave y certificado (365 días; ajuste CN al FQDN del servidor)
openssl req -x509 -nodes -newkey rsa:2048 \
  -keyout /usr/local/etc/ssl/private/mail.key \
  -out /usr/local/etc/ssl/certs/mail.crt \
  -days 365 -subj "/CN=mail.alumnoJPL.local"

chmod 600 /usr/local/etc/ssl/private/mail.key
```

---

## 7. Configuración de Postfix (MTA)

### 7.1. `/usr/local/etc/postfix/main.cf` (plantilla mínima)

Edite o cree con el siguiente contenido (ajuste dominio/host/IP según su laboratorio):

```conf
# /usr/local/etc/postfix/main.cf
myhostname = mail.alumnoJPL.local
mydomain = alumnoJPL.local
myorigin = $mydomain
mydestination = $myhostname, localhost.$mydomain, localhost
inet_interfaces = all
inet_protocols = ipv4
mynetworks = 127.0.0.0/8

smtpd_banner = $myhostname ESMTP
home_mailbox = Maildir/

# TLS
smtpd_use_tls = yes
smtpd_tls_cert_file = /usr/local/etc/ssl/certs/mail.crt
smtpd_tls_key_file  = /usr/local/etc/ssl/private/mail.key
smtpd_tls_security_level = may
smtp_tls_security_level  = may

# SASL (autenticación SMTP mediante Dovecot)
smtpd_sasl_type = dovecot
smtpd_sasl_path = private/auth
smtpd_sasl_auth_enable = yes
smtpd_sasl_security_options = noanonymous

# Reglas básicas: permitir red local y usuarios autenticados
smtpd_recipient_restrictions =
    permit_mynetworks,
    permit_sasl_authenticated,
    reject_unauth_destination

# Aliases del sistema
alias_maps = hash:/etc/aliases
alias_database = hash:/etc/aliases
```

### 7.2. `/usr/local/etc/postfix/master.cf` (habilitar Submission 587)

Descomente/añada el bloque **submission**:

```conf
# /usr/local/etc/postfix/master.cf
submission inet n       -       n       -       -       smtpd
  -o syslog_name=postfix/submission
  -o smtpd_tls_security_level=encrypt
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_client_restrictions=permit_sasl_authenticated,reject
  -o milter_macro_daemon_name=ORIGINATING

# (Opcional) smtps 465
#smtps     inet  n       -       n       -       -       smtpd
#  -o syslog_name=postfix/smtps
#  -o smtpd_tls_wrappermode=yes
#  -o smtpd_sasl_auth_enable=yes
#  -o smtpd_client_restrictions=permit_sasl_authenticated,reject
```

---

## 8. Configuración de Dovecot (IMAP/POP y SASL)

Ficheros en `/usr/local/etc/dovecot/` (Dovecot trae `conf.d/`):

### 8.1. `dovecot.conf`

```conf
# /usr/local/etc/dovecot/dovecot.conf
!include conf.d/*.conf
protocols = imap pop3
listen = *
```

### 8.2. `conf.d/10-mail.conf`

```conf
# /usr/local/etc/dovecot/conf.d/10-mail.conf
mail_location = maildir:~/Maildir
```

### 8.3. `conf.d/10-auth.conf`

```conf
# /usr/local/etc/dovecot/conf.d/10-auth.conf
disable_plaintext_auth = yes
auth_mechanisms = plain login
!include auth-system.conf.ext   # PAM/usuarios del sistema
```

### 8.4. `conf.d/10-ssl.conf`

```conf
# /usr/local/etc/dovecot/conf.d/10-ssl.conf
ssl = yes
ssl_cert = </usr/local/etc/ssl/certs/mail.crt
ssl_key  = </usr/local/etc/ssl/private/mail.key
```

### 8.5. `conf.d/10-master.conf` (socket SASL para Postfix)

```conf
# /usr/local/etc/dovecot/conf.d/10-master.conf
service auth {
  unix_listener /var/spool/postfix/private/auth {
    mode = 0660
    user = postfix
    group = postfix
  }
}
```

---

## 9. Creación de Cuentas y Buzones (2+ usuarios)

Cree **usuarios del sistema** (p. ej., `juan` y `ana`) y sus **Maildir**:

```sh
pw useradd -n juan -m -s /bin/sh
passwd juan
pw useradd -n ana  -m -s /bin/sh
passwd ana

# Crear Maildir para cada usuario (estructura mínima)
mkdir -p /home/juan/Maildir/{cur,new,tmp}
chown -R juan:juan /home/juan/Maildir

mkdir -p /home/ana/Maildir/{cur,new,tmp}
chown -R ana:ana /home/ana/Maildir
```

---

## 10. Arranque y Verificación de Servicios

```sh
service postfix restart
service dovecot restart

# Comprobar puertos escuchando (25, 587, 110, 143, 993, 995 si los habilita)
sockstat -4 -l | egrep '(:25|:587|:110|:143|:993|:995)'
```

**Logs:**

* **Postfix/Dovecot:** `/var/log/maillog`
* Verifique que **syslogd** esté activo; FreeBSD ya registra `mail.*` ahí.

---

## 11. Cliente de Correo (MUA)

### 11.1. Thunderbird (recomendado en cliente Windows/Linux)

* **Servidor entrante (IMAP):** `mail.alumnoJPL.local`, **puerto** `993` (IMAPS), **seguridad** TLS/SSL, **método** contraseña normal.
* **Servidor saliente (SMTP Submission):** `mail.alumnoJPL.local`, **puerto** `587`, **seguridad** STARTTLS, **autenticación** usuario/clave del sistema (`juan`, `ana`).
* **Usuario/correo:** `juan@alumnoJPL.local` y `ana@alumnoJPL.local`.

> Con certificado **autofirmado**, Thunderbird solicitará **excepción de seguridad** (aceptar solo para fines de laboratorio).

### 11.2. Mutt (en el servidor o en un cliente UNIX)

Configuración mínima (~/.muttrc) para **juan**:

```conf
set realname="Juan Pérez"
set from="juan@alumnoJPL.local"

set folder="imaps://mail.alumnoJPL.local/"
set spoolfile="+INBOX"
set imap_user="juan"

set smtp_url="smtp://mail.alumnoJPL.local:587"
set smtp_pass="(se pedirá si se omite)"
set ssl_starttls=yes
set ssl_force_tls=yes
```

Ejecute: `mutt` → probar envío/lectura.

---

## 12. Pruebas y Validación

> **Sugerencia de capturas:** salida de cada comando clave y de `maillog`, configuración de cuenta en Thunderbird, y prueba de envío/recepción.

### 12.1. Conectividad y resolución de nombres

```sh
ping -c 3 mail.alumnoJPL.local

# host / nslookup (bind-tools)
host mail.alumnoJPL.local
nslookup mail.alumnoJPL.local
```

### 12.2. Pruebas de puertos

```sh
telnet mail.alumnoJPL.local 25
telnet mail.alumnoJPL.local 587
telnet mail.alumnoJPL.local 143
telnet mail.alumnoJPL.local 110
# TLS directos:
openssl s_client -connect mail.alumnoJPL.local:993 -quiet
openssl s_client -connect mail.alumnoJPL.local:995 -quiet
```

### 12.3. Prueba SMTP (manual vía telnet en 25 o 587)

Secuencia mínima (reemplazar usuarios/dominio):

```
EHLO cliente.local
AUTH LOGIN
(digite usuario en base64, luego contraseña en base64; o use 587 con STARTTLS previamente)
MAIL FROM:<juan@alumnoJPL.local>
RCPT TO:<ana@alumnoJPL.local>
DATA
Subject: Prueba interna

Hola Ana, prueba de laboratorio.
.
QUIT
```

### 12.4. Envío local rápido (comando `sendmail`)

```sh
printf "Subject: Prueba A->B\n\nHola Ana.\n" | sendmail -v ana@alumnoJPL.local
tail -n 50 /var/log/maillog
```

### 12.5. Recepción en IMAP

* Abrir **Thunderbird** como `ana` y verificar llegada del correo.
* Responder a `juan` y validar **ida y vuelta** en `/var/log/maillog`.

> **Criterio de validación:** “**Envío y recepción internos**” funcionan para **ambas** cuentas, y los registros en `maillog` no muestran errores.

---

## 13. Buenas Prácticas Mínimas (entorno académico)

1. **Seguridad de acceso**

   * Usar **Submission 587 + STARTTLS** y **IMAPS 993**.
   * **No** exponer el servidor fuera de la red de laboratorio.
2. **Manejo de logs**

   * Revisar `/var/log/maillog` tras cada cambio.
   * Configurar rotación con `newsyslog.conf` (FreeBSD lo hace por defecto).
3. **Organización de buzones**

   * Estándar **Maildir** por usuario (`~/Maildir`).
   * Respaldos de `/home/*/Maildir` y de `/usr/local/etc/postfix/` y `/usr/local/etc/dovecot/`.
4. **Actualizaciones**

   * `pkg upgrade` periódico en laboratorio controlado.
5. **Cuentas y contraseñas**

   * Contraseñas robustas; rotación si el laboratorio se prolonga.

> (Opcional para prácticas avanzadas): antispam/antivirus, políticas de contraseñas, **fail2ban** (paquete `py-fail2ban`) para limitar intentos.

---

## 14. Entregables (para el **30 de octubre**)

1. **Documento PDF** con:

   * Portada (equipo, grupo, fecha).
   * **Secciones numeradas** siguiendo esta guía.
   * **Capturas**: `sockstat`, `maillog`, `Thunderbird/Mutt`, pruebas (`host/nslookup/ping/telnet/openssl`).
   * Fragmentos de configuración: `main.cf`, `master.cf`, `dovecot.conf` y `conf.d/*` relevantes.
2. **Bitácora de pruebas** (paso a paso) con **resultado esperado** y **resultado obtenido**.
3. **Conclusiones**: problemas encontrados, cómo se resolvieron y recomendaciones.

---

## 15. Anexos — Plantillas completas

### A. `/usr/local/etc/postfix/main.cf` (referencia)

```conf
myhostname = mail.alumnoJPL.local
mydomain = alumnoJPL.local
myorigin = $mydomain
mydestination = $myhostname, localhost.$mydomain, localhost
inet_interfaces = all
inet_protocols = ipv4
mynetworks = 127.0.0.0/8

smtpd_banner = $myhostname ESMTP
home_mailbox = Maildir/

# TLS
smtpd_use_tls = yes
smtpd_tls_cert_file = /usr/local/etc/ssl/certs/mail.crt
smtpd_tls_key_file  = /usr/local/etc/ssl/private/mail.key
smtpd_tls_security_level = may
smtp_tls_security_level  = may
smtpd_tls_loglevel = 1

# SASL con Dovecot
smtpd_sasl_type = dovecot
smtpd_sasl_path = private/auth
smtpd_sasl_auth_enable = yes
smtpd_sasl_security_options = noanonymous

smtpd_recipient_restrictions =
    permit_mynetworks,
    permit_sasl_authenticated,
    reject_unauth_destination

alias_maps = hash:/etc/aliases
alias_database = hash:/etc/aliases
```

### B. `/usr/local/etc/postfix/master.cf` (referencia)

```conf
smtp      inet  n       -       n       -       -       smtpd
# habilitar submission (587):
submission inet n       -       n       -       -       smtpd
  -o syslog_name=postfix/submission
  -o smtpd_tls_security_level=encrypt
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_client_restrictions=permit_sasl_authenticated,reject
  -o milter_macro_daemon_name=ORIGINATING

# (opcional) smtps 465:
#smtps     inet  n       -       n       -       -       smtpd
#  -o syslog_name=postfix/smtps
#  -o smtpd_tls_wrappermode=yes
#  -o smtpd_sasl_auth_enable=yes
#  -o smtpd_client_restrictions=permit_sasl_authenticated,reject
```

### C. `/usr/local/etc/dovecot/dovecot.conf` y `conf.d/*` (referencia)

```conf
# dovecot.conf
!include conf.d/*.conf
protocols = imap pop3
listen = *
```

```conf
# 10-mail.conf
mail_location = maildir:~/Maildir
```

```conf
# 10-auth.conf
disable_plaintext_auth = yes
auth_mechanisms = plain login
!include auth-system.conf.ext
```

```conf
# 10-ssl.conf
ssl = yes
ssl_cert = </usr/local/etc/ssl/certs/mail.crt
ssl_key  = </usr/local/etc/ssl/private/mail.key
```

```conf
# 10-master.conf (bloque relevante)
service auth {
  unix_listener /var/spool/postfix/private/auth {
    mode = 0660
    user = postfix
    group = postfix
  }
}
```

---

## 16. Lista de Comprobación Final (Checklist)

* [ ] `hostname` y `/etc/hosts` correctos.
* [ ] `sendmail` deshabilitado; `postfix` y `dovecot` habilitados en `rc.conf`.
* [ ] Certificado TLS creado y referenciado en Postfix/Dovecot.
* [ ] `main.cf` y `master.cf` ajustados (incluir **Submission 587**).
* [ ] Dovecot configurado (Maildir, SSL, socket SASL).
* [ ] Usuarios locales creados y `Maildir` inicializado.
* [ ] Puertos abiertos: 25, 587, 143/993 (y 110/995 si aplica).
* [ ] Envío/recepción internos funcionando (dos direcciones).
* [ ] Evidencias en `/var/log/maillog` y capturas incluidas en el informe.

---

### Observaciones finales

* Esta guía privilegia **Postfix + Dovecot** por su claridad docente. También puede implementarse **Sendmail** o **Exim**, pero **debe** mantener:
  **(a)** dominio ficticio interno, **(b)** dos usuarios, **(c)** MUA configurado, **(d)** pruebas documentadas.
* El uso de certificados autofirmados es **solo** con fines académicos en red interna. En producción, emplee **certificados válidos** y políticas de seguridad adicionales.
