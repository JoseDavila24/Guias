# Guía “LAB sin seguridad” (Postfix + Dovecot) **con IP directa en el cliente**

**Entorno previsto**

* **Virtualización:** Multipass
* **Ubuntu:** 24.04 LTS (VM recién creada, IP por DHCP)
* **Dominio interno:** `jmrd.com`
* **FQDN del servidor:** `mail.jmrd.com` (para identidad local; **Thunderbird usará la IP**)

> **Modo laboratorio:** sin TLS/STARTTLS y **sin SMTP AUTH**. **No** exponer a Internet.

---

## 0) Crear VM y anotar la IP

En **Windows** (PowerShell/CMD):

```bash
multipass launch 24.04 --name correo --cpus 2 --memory 2G --disk 10G
multipass info correo
# Anota la IPv4 (ej. 172.21.X.Y)
```

> Esa IP la pondrás en Thunderbird como “Nombre del servidor” IMAP y SMTP (no usaremos `hosts` en Windows).

---

## 1) Preparación básica dentro de la VM

Entrar a la VM:

```bash
multipass shell correo
```

Identidad del host/MTA:

```bash
sudo hostnamectl set-hostname mail.jmrd.com
echo jmrd.com | sudo tee /etc/mailname
```

`/etc/hosts` **solo local** (no dependemos de la IP de la NIC):

```bash
# ⚠️ No mezcles 'localhost' con el FQDN en la misma línea
sudo bash -c 'cat >/etc/hosts <<EOF
127.0.0.1   localhost
127.0.1.1   mail.jmrd.com mail
EOF'
```

> Mantener `localhost` en 127.0.0.1 evita errores de resolución. 

---

## 2) Instalar paquetes

```bash
sudo apt update && sudo apt -y upgrade
sudo apt -y install postfix dovecot-imapd mailutils
```

Durante Postfix:

* Tipo: **Internet Site**
* System mail name: **jmrd.com**

---

## 3) Postfix (SMTP) — mínimo, sin AUTH (no open relay)

> **Importante:** No crear *overrides* de systemd. Usaremos la unidad de paquete tal como viene.

Ajustar parámetros con `postconf -e`:

```bash
# Identidad
sudo postconf -e "myhostname=mail.jmrd.com"
sudo postconf -e "mydomain=jmrd.com"
sudo postconf -e "myorigin=jmrd.com"   # explícito para evitar confusión
sudo postconf -e "mydestination=\$myhostname, \$mydomain, localhost.\$mydomain, localhost"

# Red / protocolos
sudo postconf -e "inet_interfaces=all"
sudo postconf -e "inet_protocols=ipv4"

# Buzones Maildir
sudo postconf -e "home_mailbox=Maildir/"

# Alias
sudo postconf -e "alias_maps=hash:/etc/aliases"
sudo postconf -e "alias_database=hash:/etc/aliases"

# Anti‑relé (lab sin AUTH): entrega local permitida; relé externo bloqueado
sudo postconf -e "mynetworks=127.0.0.0/8"
sudo postconf -e "smtpd_relay_restrictions=permit_mynetworks, reject_unauth_destination"

# Aplicar mapas de alias
sudo newaliases

# Preferir 'reload' (idempotente) para evitar "already running"
sudo systemctl enable --now postfix
sudo systemctl reload postfix
sudo postconf -n | sed -n '1,200p'
```

> **Nota:** `myorigin=/etc/mailname` es **válido** (Postfix acepta rutas que contienen el dominio), pero aquí usamos `myorigin=jmrd.com` para simplificar. Si otro día prefieres `/etc/mailname`, asegúrate de que su contenido sea exactamente `jmrd.com`.

> **Si alguna vez creaste un override** en `/etc/systemd/system/postfix.service.d/`: bórralo y recarga demonios:
> `sudo rm -rf /etc/systemd/system/postfix.service.d && sudo systemctl daemon-reload && sudo systemctl reset-failed postfix && sudo systemctl reload postfix`

---

## 4) Dovecot (IMAP) — texto claro (sin TLS)

```bash
# Buzones Maildir
sudo sed -i 's|^#\?mail_location.*|mail_location = maildir:~/Maildir|' /etc/dovecot/conf.d/10-mail.conf

# Autenticación en claro (solo laboratorio)
sudo sed -i 's/^#\?disable_plaintext_auth.*/disable_plaintext_auth = no/' /etc/dovecot/conf.d/10-auth.conf
sudo sed -i 's/^#\?auth_mechanisms.*/auth_mechanisms = plain login/' /etc/dovecot/conf.d/10-auth.conf

# Desactivar TLS/STARTTLS explícitamente
sudo sed -i 's/^#\?ssl = .*/ssl = no/' /etc/dovecot/conf.d/10-ssl.conf

sudo systemctl enable --now dovecot
sudo systemctl restart dovecot
sudo doveconf -n | sed -n '1,200p'
```

---

## 5) Usuarios y Maildir  **(rutas absolutas y permisos por usuario)**

```bash
# Usuarios de prueba
sudo adduser juan
sudo adduser maria

# Crear Maildir con rutas absolutas (evita fallos de expansión)
sudo -u juan  maildirmake.dovecot /home/juan/Maildir
sudo -u maria maildirmake.dovecot /home/maria/Maildir

# Permisos y propiedad (por usuario)
sudo chmod -R 700 /home/juan/Maildir
sudo chmod -R 700 /home/maria/Maildir
sudo chown -R juan:juan   /home/juan/Maildir
sudo chown -R maria:maria /home/maria/Maildir
```

---

## 6) Alias internos (útiles)

```bash
sudo tee -a /etc/aliases > /dev/null << 'EOF'
postmaster: juan
root: juan
avisos: juan, maria
soporte: juan
direccion: maria
EOF

sudo newaliases
sudo postfix reload
```

> Redirigir **postmaster/root** a un buzón real evita perder avisos. 

---

## 7) Verificaciones en el servidor

```bash
# Servicios y puertos
systemctl --no-pager status postfix dovecot
ss -lntp | grep -E ':25|:143'

# Autenticación Dovecot
sudo doveadm auth test juan
sudo doveadm auth test maria

# Entrega local (Juan → María)
printf "Subject: Test Local\n\nHola Maria\n" | sendmail -v maria@jmrd.com
sudo tail -n 80 /var/log/mail.log | tail
# Esperado: "status=sent (delivered to mailbox)"
```

---

## 8) Configurar **Thunderbird** usando **la IP** (sin tocar `hosts`)

1. En Windows, obtén la IP:

   ```bash
   multipass info correo
   ```
2. En **Thunderbird** → **☰ → Nueva → Cuenta de correo existente → Configuración manual**.
   Usa **la IP** como “Servidor” (IMAP y SMTP):

| Parámetro     | IMAP (entrante)   | SMTP (saliente)                |
| ------------- | ----------------- | ------------------------------ |
| **Servidor**  | **<IP de la VM>** | **<IP de la VM>**              |
| **Puerto**    | **143**           | **25**                         |
| **Seguridad** | **Ninguna**       | **Ninguna**                    |
| **Auth**      | Contraseña normal | **Sin autenticación**          |
| **Usuario**   | juan              | *(se ignora en SMTP sin AUTH)* |

**Prueba:** desde `juan@jmrd.com` envía a `maria@jmrd.com`; en la cuenta de María pulsa **Recibir**.
En el servidor:

```bash
sudo tail -n 50 /var/log/mail.log | grep maria
```

> **SMTP 25 sin AUTH** permite envíos al dominio local `@jmrd.com` y **bloquea relé externo** por `reject_unauth_destination`.

---

## 9) Diagnóstico rápido (útil)

```bash
# Conectividad (instala netcat si hace falta)
sudo apt -y install netcat-openbsd
nc -vz 127.0.0.1 25
nc -vz 127.0.0.1 143

# Logs en vivo
sudo tail -f /var/log/mail.log
sudo journalctl -u dovecot -f

# Buzones y permisos
ls -la /home/juan/Maildir
ls -la /home/maria/Maildir
```

**Problemas típicos y solución**

* **“already running” al reiniciar Postfix:** usa `sudo postfix status`; luego `sudo systemctl reload postfix` (idempotente). Si alguna vez creaste un *override*, elimínalo como arriba.
* **No llega al buzón:** verifica `/etc/hosts`, existencia de `Maildir` y permisos (700).
* **Thunderbird no conecta:** confirma `ssl = no` en Dovecot y **Seguridad: Ninguna** en el cliente.
* **Alias no funciona:** faltó `sudo newaliases`.

---

## 10) (Opcional) UFW

```bash
sudo ufw allow 25,143/tcp
sudo ufw enable
sudo ufw status
```

---

## 11) Si la IP cambia otra vez

* No toques el servidor.
* En **Thunderbird**, edita la cuenta y **sustituye la IP** en IMAP/SMTP.
* Vuelve a probar envío y recepción.

---

### ✅ Resumen

* **LAB sin seguridad:** IMAP 143 en claro + SMTP 25 sin AUTH (solo entrega local `@jmrd.com`).
* **Postfix sin overrides:** usamos `reload` para aplicar cambios (evita el “already running”).
* **Maildir robusto:** rutas absolutas + permisos/propiedad por usuario.
* **Thunderbird:** usa **IP directa** (no se modifica `hosts` en Windows).
* Guía corregida partiendo de tu documento original. 
