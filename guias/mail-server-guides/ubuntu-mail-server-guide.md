**Windows (como Administrador) – `C:\Windows\System32\drivers\etc\hosts`:**

```
172.21.46.52   mail.jmrd.com
```

**En la VM:**

```bash
# /etc/hosts (NO mezclar 'localhost' con la IP real)
sudo bash -c 'cat >/etc/hosts <<EOF
127.0.0.1   localhost
172.21.46.52 mail.jmrd.com mail
EOF'

# Si usaste mynetworks con la subred anterior, actualiza a /24 de 172.21.46.0
sudo postconf -e 'mynetworks = 127.0.0.0/8 172.21.46.0/24'
sudo systemctl restart postfix dovecot
```

---

# Guía “Solo laboratorio” (Ubuntu 24.04 + Multipass) — **IP 172.21.46.52**

**Entorno**

* **VM:** `correo` (Multipass)
* **Ubuntu:** 24.04.3 LTS
* **IP:** **172.21.46.52**
* **Dominio:** `jmrd.com`
* **FQDN:** `mail.jmrd.com`
* **Usuarios de prueba:** `juan`, `maria`

> Esta guía usa **IMAP 143 en texto claro** y **SMTP 25 sin autenticación**. No la expongas a Internet. 

---

## 0) Resolución de nombres (Windows + VM)

### 0.1 Windows (Thunderbird)

Edita **como Administrador** `C:\Windows\System32\drivers\etc\hosts` y añade:

```
172.21.46.52   mail.jmrd.com
```

### 0.2 VM (Multipass)

```bash
multipass shell correo

# Nombre de host y /etc/mailname
sudo hostnamectl set-hostname mail.jmrd.com
echo jmrd.com | sudo tee /etc/mailname

# /etc/hosts (⚠️ no mezcles 'localhost' en la línea de la IP)
sudo bash -c 'cat >/etc/hosts <<EOF
127.0.0.1   localhost
172.21.46.52 mail.jmrd.com mail
EOF'
```

> Evita poner `localhost` junto a la IP real del servidor. 

---

## 1) Paquetes mínimos

```bash
sudo apt update && sudo apt -y upgrade
sudo apt -y install postfix dovecot-imapd mailutils
```

Durante Postfix:

* **Internet Site**
* **System mail name:** `jmrd.com`

---

## 2) Postfix (SMTP) — básico sin AUTH

Edita `/etc/postfix/main.cf` y deja al menos:

```ini
# Identidad
myhostname = mail.jmrd.com
mydomain   = jmrd.com
myorigin   = /etc/mailname
mydestination = $myhostname, $mydomain, localhost.$mydomain, localhost

# Red / protocolos
inet_interfaces = all
inet_protocols = ipv4

# Formato de buzones
home_mailbox = Maildir/

# Alias
alias_maps     = hash:/etc/aliases
alias_database = hash:/etc/aliases

# Antirrelé (solo laboratorio, sin AUTH)
mynetworks = 127.0.0.0/8 172.21.46.0/24
smtpd_relay_restrictions    = permit_mynetworks, reject_unauth_destination
smtpd_recipient_restrictions = permit_mynetworks, reject_unauth_destination
```

Aplica:

```bash
sudo newaliases
sudo systemctl restart postfix
sudo postconf -n | sed -n '1,200p'
```

> Para **entrega local a @jmrd.com**, no necesitas estar en `mynetworks`. Esa lista solo importará si intentas relé a dominios externos (lo cual aquí no haremos). 

---

## 3) Dovecot (IMAP) — texto claro (sin TLS)

```bash
# Ubicación de buzones
sudo sed -i 's|^#\?mail_location.*|mail_location = maildir:~/Maildir|' /etc/dovecot/conf.d/10-mail.conf

# Permitir autenticación en texto claro (solo laboratorio)
sudo sed -i 's/^#\?disable_plaintext_auth.*/disable_plaintext_auth = no/' /etc/dovecot/conf.d/10-auth.conf
sudo sed -i 's/^#\?auth_mechanisms.*/auth_mechanisms = plain login/' /etc/dovecot/conf.d/10-auth.conf

# Desactivar TLS/STARTTLS explícitamente
sudo sed -i 's/^#\?ssl = .*/ssl = no/' /etc/dovecot/conf.d/10-ssl.conf

sudo systemctl restart dovecot
sudo doveconf -n | sed -n '1,200p'
```

---

## 4) Usuarios y Maildir

```bash
sudo adduser juan
sudo adduser maria

sudo -u juan  maildirmake.dovecot ~/Maildir
sudo -u maria maildirmake.dovecot ~/Maildir
sudo chmod -R 700 /home/*/Maildir
```

---

## 5) Alias internos (útiles en laboratorio)

Edita `/etc/aliases`:

```
postmaster: juan
root: juan
avisos: juan, maria
soporte: juan
direccion: maria
```

Aplica:

```bash
sudo newaliases
sudo postfix reload
```

---

## 6) Verificaciones en servidor

```bash
# Servicios y puertos
systemctl --no-pager status postfix dovecot
ss -lntp | grep -E ':25|:143'

# Autenticación Dovecot
sudo doveadm auth test juan
sudo doveadm auth test maria

# Entrega local
printf "Subject: Test Local\n\nHola Maria\n" | sendmail -v maria@jmrd.com
sudo tail -n 80 /var/log/mail.log | tail
```

Salida esperada: `status=sent (delivered to mailbox)`.

---

## 7) Thunderbird (cliente) — **sin seguridad**

**Cuenta IMAP:**

* **Correo:** `juan@jmrd.com`
* **Contraseña:** (la de `juan`)
* **Configuración manual:**

| Parámetro     | IMAP (entrante)   | SMTP (saliente)                     |
| ------------- | ----------------- | ----------------------------------- |
| Servidor      | mail.jmrd.com     | mail.jmrd.com                       |
| Puerto        | **143**           | **25**                              |
| Seguridad     | **Ninguna**       | **Ninguna**                         |
| Autenticación | Contraseña normal | **Sin autenticación**               |
| Usuario       | juan              | juan *(se ignora en SMTP sin AUTH)* |

**Probar:** desde `juan@jmrd.com` envía a `maria@jmrd.com`.
Servidor:

```bash
sudo tail -n 50 /var/log/mail.log | grep maria
```

> **SMTP 25 sin AUTH** acepta envíos al dominio local `@jmrd.com` y **rechaza relé externo** por `reject_unauth_destination`. 

---

## 8) Diagnóstico express

```bash
# Conectividad
ping -c 3 mail.jmrd.com
nc -vz mail.jmrd.com 25
nc -vz mail.jmrd.com 143

# Logs en vivo
sudo tail -f /var/log/mail.log
sudo journalctl -u dovecot -f

# Buzones
ls -la /home/juan/Maildir
ls -la /home/maria/Maildir
```

### Problemas típicos

* **No llega al buzón:** revisa `/etc/hosts` y propiedad/permisos de `Maildir`.
* **Thunderbird no conecta:** confirma `ssl = no` en Dovecot y **Seguridad: Ninguna** en IMAP/SMTP.
* **Alias no funciona:** faltó `newaliases`.

---

## 9) Firewall (si usas UFW)

```bash
sudo ufw allow 25,143/tcp
sudo ufw enable
sudo ufw status
```

---

## 10) Si vuelve a cambiar la IP

* Actualiza **Windows `hosts`** y **`/etc/hosts`** con la nueva IP.
* Si usaste `mynetworks`, ajusta a la **subred /24** que corresponda (p. ej., `172.21.47.0/24`).

---

### ✅ Resumen

* **IP actual:** **172.21.46.52**
* **Modo laboratorio:** IMAP 143 (texto claro) + SMTP 25 sin AUTH.
* **No open relay:** `reject_unauth_destination` bloquea relé externo; entrega local a `@jmrd.com` operativa.
* **Puntos clave:** `/etc/hosts` limpio, `mynetworks` a **172.21.46.0/24**, `ssl = no` en Dovecot, `alias_database` definido. 

Si quieres, pega ahora `postconf -n` y `doveconf -n` y reviso que todo haya quedado exacto con la IP **172.21.46.52**.
