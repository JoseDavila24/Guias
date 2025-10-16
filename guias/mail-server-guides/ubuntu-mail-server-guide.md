## 0) Resolución de nombres (Windows y VM)

### 0.1 En **Windows** (cliente Thunderbird)

Edita como **Administrador** el archivo:

```
C:\Windows\System32\drivers\etc\hosts
```

Agrega:

```
172.21.46.52   mail.jmrd.com
```

### 0.2 En la **VM** (Multipass)

```bash
multipass shell correo

# FQDN y /etc/mailname
sudo hostnamectl set-hostname mail.jmrd.com
echo jmrd.com | sudo tee /etc/mailname

# /etc/hosts  (⚠️ NO mezclar 'localhost' con la IP real)
sudo bash -c 'cat >/etc/hosts <<EOF
127.0.0.1   localhost
172.21.46.52 mail.jmrd.com mail
EOF'
```

*Motivo:* evitar que `localhost` resuelva a la IP del servidor. 

---

## 1) Paquetes mínimos

```bash
sudo apt update && sudo apt -y upgrade
sudo apt -y install postfix dovecot-imapd mailutils
```

Durante Postfix:

* Tipo: **Internet Site**
* System mail name: **jmrd.com**

---

## 2) Postfix (SMTP) — **básico sin autenticación**

Ajusta parámetros con `postconf -e` (más limpio que editar a mano):

```bash
# Identidad
sudo postconf -e "myhostname=mail.jmrd.com"
sudo postconf -e "mydomain=jmrd.com"
sudo postconf -e "myorigin=/etc/mailname"
sudo postconf -e "mydestination=\$myhostname, \$mydomain, localhost.\$mydomain, localhost"

# Red / protocolos
sudo postconf -e "inet_interfaces=all"
sudo postconf -e "inet_protocols=ipv4"

# Buzones Maildir
sudo postconf -e "home_mailbox=Maildir/"

# Alias
sudo postconf -e "alias_maps=hash:/etc/aliases"
sudo postconf -e "alias_database=hash:/etc/aliases"

# Anti-relé (solo lab, sin AUTH). Permite entrega local, bloquea relé externo.
sudo postconf -e "mynetworks=127.0.0.0/8 172.21.46.0/24"
sudo postconf -e "smtpd_relay_restrictions=permit_mynetworks, reject_unauth_destination"
sudo postconf -e "smtpd_recipient_restrictions=permit_mynetworks, reject_unauth_destination"

sudo newaliases
sudo systemctl restart postfix
sudo postconf -n | sed -n '1,200p'
```

> Para enviar **a @jmrd.com** no necesitas estar en `mynetworks`. `reject_unauth_destination` ya permite destino local y bloquea relé hacia dominios externos. 

---

## 3) Dovecot (IMAP) — **texto claro, sin TLS**

```bash
# Ubicación de buzones
sudo sed -i 's|^#\?mail_location.*|mail_location = maildir:~/Maildir|' /etc/dovecot/conf.d/10-mail.conf

# Permitir autenticación en claro (solo laboratorio)
sudo sed -i 's/^#\?disable_plaintext_auth.*/disable_plaintext_auth = no/' /etc/dovecot/conf.d/10-auth.conf
sudo sed -i 's/^#\?auth_mechanisms.*/auth_mechanisms = plain login/' /etc/dovecot/conf.d/10-auth.conf

# Desactivar TLS/STARTTLS
sudo sed -i 's/^#\?ssl = .*/ssl = no/' /etc/dovecot/conf.d/10-ssl.conf

sudo systemctl restart dovecot
sudo doveconf -n | sed -n '1,200p'
```

---

## 4) Usuarios y Maildir

```bash
# Crea usuarios de prueba
sudo adduser juan
sudo adduser maria

# Crea Maildir con dueño correcto
sudo -u juan  maildirmake.dovecot ~/Maildir
sudo -u maria maildirmake.dovecot ~/Maildir
sudo chmod -R 700 /home/*/Maildir
```

---

## 5) Alias internos (útiles en práctica)

```bash
sudo bash -c 'cat >>/etc/aliases <<EOF
postmaster: juan
root: juan
avisos: juan, maria
soporte: juan
direccion: maria
EOF'

sudo newaliases
sudo postfix reload
```

> Redirigir **postmaster**/**root** a un buzón real evita perder avisos del sistema. 

---

## 6) Verificaciones rápidas en servidor

```bash
# Servicios y puertos
systemctl --no-pager status postfix dovecot
ss -lntp | grep -E ':25|:143'

# Autenticación Dovecot (IMAP)
sudo doveadm auth test juan
sudo doveadm auth test maria

# Entrega local
printf "Subject: Test Local\n\nHola Maria\n" | sendmail -v maria@jmrd.com
sudo tail -n 80 /var/log/mail.log | tail
# Busca "status=sent (delivered to mailbox)"
```

---

## 7) Thunderbird (cliente) — **sin seguridad**

**Cuenta IMAP de Juan**

* Correo: `juan@jmrd.com`
* Contraseña: (la de `juan`)
* Configuración manual:

| Parámetro     | IMAP (entrante)   | SMTP (saliente)                     |
| ------------- | ----------------- | ----------------------------------- |
| Servidor      | mail.jmrd.com     | mail.jmrd.com                       |
| Puerto        | **143**           | **25**                              |
| Seguridad     | **Ninguna**       | **Ninguna**                         |
| Autenticación | Contraseña normal | **Sin autenticación**               |
| Usuario       | juan              | juan *(se ignora en SMTP sin AUTH)* |

**Prueba de punta a punta**

1. Desde `juan@jmrd.com`, enviar a `maria@jmrd.com`.
2. En la cuenta de María, **Recibir**.
3. En servidor:

```bash
sudo tail -n 50 /var/log/mail.log | grep maria
```

**Prueba de alias**

```bash
echo "Mensaje de prueba" | mail -s "Aviso Interno" avisos@jmrd.com
sudo tail -n 50 /var/log/mail.log | grep avisos
```

> **SMTP 25 sin AUTH**: entrega a `@jmrd.com` OK, **relé externo bloqueado** por `reject_unauth_destination`. 

---

## 8) Diagnóstico útil

```bash
# Conectividad básica
ping -c 3 mail.jmrd.com
nc -vz mail.jmrd.com 25
nc -vz mail.jmrd.com 143

# Logs en vivo
sudo tail -f /var/log/mail.log
sudo journalctl -u dovecot -f

# Revisar buzones y permisos
ls -la /home/juan/Maildir
ls -la /home/maria/Maildir
```

**Problemas típicos**

* **No llega al buzón:** revisa `/etc/hosts`, existencia/propiedad de `Maildir`.
* **Thunderbird no conecta:** confirma `ssl = no` en Dovecot y **Seguridad: Ninguna** en IMAP/SMTP.
* **Alias no funciona:** faltó `sudo newaliases`.

---

## 9) (Opcional) Firewall UFW

```bash
sudo ufw allow 25,143/tcp
sudo ufw enable
sudo ufw status
```

---

## 10) Si cambia la IP otra vez

* Actualiza **Windows `hosts`** y **`/etc/hosts`** con la IP nueva.
* Si usas `mynetworks`, ajusta a la subred correspondiente (p. ej. `172.21.47.0/24`).

---

### ✅ Resumen express

* **IP actual:** 172.21.46.52
* **Modo LAB (poco seguro):** IMAP 143 en claro + SMTP 25 sin AUTH.
* **No open relay:** se permite solo **entrega local** `@jmrd.com`.
* **Claves:** `/etc/hosts` limpio, `home_mailbox=Maildir/`, `alias_database` definido, `mynetworks=127.0.0.0/8 172.21.46.0/24`. 

Si quieres, pega ahora `postconf -n` y `doveconf -n` y te confirmo que está 100% alineado a este modo laboratorio.
