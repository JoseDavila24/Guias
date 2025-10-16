# Guía “LAB sin seguridad” (Postfix + Dovecot) con **IP directa** en el cliente

**Entorno esperado**

* **Virtualización:** Multipass
* **Ubuntu:** 24.04 LTS (VM nueva, IP por DHCP)
* **Dominio interno:** `jmrd.com`
* **FQDN del servidor:** `mail.jmrd.com` (solo para identidad del MTA; el cliente usará **IP**)

> **Objetivo:** correo **interno** `@jmrd.com` (sin TLS/STARTTLS ni SMTP AUTH). **No** exponer a Internet.

---

## 0) Crear la VM y **anotar la IP**

En **Windows** (PowerShell o CMD):

```bash
multipass launch 24.04 --name correo --cpus 2 --memory 2G --disk 10G
multipass info correo
# Anota la IPv4 que salga aquí (ej: 172.21.x.y).
```

> Esa IP será la que pondrás en **Thunderbird** como “Nombre del servidor” IMAP y SMTP.

---

## 1) Preparación básica dentro de la VM

Entra a la VM:

```bash
multipass shell correo
```

Configura nombre e identidad **locales** (el cliente no depende de esto, pero Postfix/Dovecot sí):

```bash
# Identidad del host/MTA
sudo hostnamectl set-hostname mail.jmrd.com
echo jmrd.com | sudo tee /etc/mailname
```

Ajusta `/etc/hosts` **sin** tocar Windows:

```bash
# Mapea el FQDN a 127.0.1.1 para resolver localmente sin depender de la IP de la NIC.
sudo bash -c 'cat >/etc/hosts <<EOF
127.0.0.1   localhost
127.0.1.1   mail.jmrd.com mail
EOF'
```

> Nota: mantenemos `localhost` **solo** en 127.0.0.1; no lo mezclamos con el FQDN. 

---

## 2) Instalar paquetes

```bash
sudo apt update && sudo apt -y upgrade
sudo apt -y install postfix dovecot-imapd mailutils
```

Durante Postfix:

* **Internet Site**
* **System mail name:** `jmrd.com`

---

## 3) Postfix (SMTP) — **mínimo sin autenticación**

Usa `postconf -e` para dejarlo listo:

```bash
# Identidad
sudo postconf -e "myhostname=mail.jmrd.com"
sudo postconf -e "mydomain=jmrd.com"
sudo postconf -e "myorigin=/etc/mailname"
sudo postconf -e "mydestination=\$myhostname, \$mydomain, localhost.\$mydomain, localhost"

# Red/protocolos
sudo postconf -e "inet_interfaces=all"
sudo postconf -e "inet_protocols=ipv4"

# Buzones en Maildir
sudo postconf -e "home_mailbox=Maildir/"

# Alias
sudo postconf -e "alias_maps=hash:/etc/aliases"
sudo postconf -e "alias_database=hash:/etc/aliases"

# No open relay (laboratorio, sin AUTH). 
# mynetworks SOLO loopback: los clientes externos podrán enviar a @jmrd.com (destino local),
# pero NO relé a dominios externos (lo bloqueará reject_unauth_destination).
sudo postconf -e "mynetworks=127.0.0.0/8"
sudo postconf -e "smtpd_relay_restrictions=permit_mynetworks, reject_unauth_destination"

sudo newaliases
```

### (Opcional) **Chequeo/override** de systemd para Postfix

> Rara vez, alguna instalación trae `ExecStart=/bin/true`. Si se detecta, aplicamos **override** (sin pisar archivos del paquete):

```bash
if systemctl cat postfix | grep -q 'ExecStart=/bin/true'; then
  echo "Corrigiendo unidad systemd de Postfix mediante override..."
  sudo mkdir -p /etc/systemd/system/postfix.service.d
  sudo tee /etc/systemd/system/postfix.service.d/override.conf > /dev/null << 'EOF'
[Service]
ExecStart=
ExecReload=
ExecStop=
Type=forking
PIDFile=/var/spool/postfix/pid/master.pid
ExecStart=/usr/sbin/postfix start
ExecReload=/usr/sbin/postfix reload
ExecStop=/usr/sbin/postfix stop
EOF
  sudo systemctl daemon-reload
fi

sudo systemctl enable --now postfix
sudo systemctl restart postfix
sudo postconf -n | sed -n '1,200p'
```

---

## 4) Dovecot (IMAP) — **texto claro, sin TLS**

```bash
# Ubicación de buzones
sudo sed -i 's|^#\?mail_location.*|mail_location = maildir:~/Maildir|' /etc/dovecot/conf.d/10-mail.conf

# Permitir autenticación en claro (modo laboratorio)
sudo sed -i 's/^#\?disable_plaintext_auth.*/disable_plaintext_auth = no/' /etc/dovecot/conf.d/10-auth.conf
sudo sed -i 's/^#\?auth_mechanisms.*/auth_mechanisms = plain login/' /etc/dovecot/conf.d/10-auth.conf

# Desactivar TLS/STARTTLS explícitamente
sudo sed -i 's/^#\?ssl = .*/ssl = no/' /etc/dovecot/conf.d/10-ssl.conf

sudo systemctl enable --now dovecot
sudo systemctl restart dovecot
sudo doveconf -n | sed -n '1,200p'
```

---

## 5) Usuarios y Maildir  **(con rutas absolutas y permisos por usuario)**

```bash
# Crea usuarios de prueba
sudo adduser juan
sudo adduser maria

# Crea Maildir con dueño correcto - USAR RUTAS ABSOLUTAS
sudo -u juan  maildirmake.dovecot /home/juan/Maildir
sudo -u maria maildirmake.dovecot /home/maria/Maildir

# Permisos individuales (evita fallos de globbing)
sudo chmod -R 700 /home/juan/Maildir
sudo chmod -R 700 /home/maria/Maildir
sudo chown -R juan:juan   /home/juan/Maildir
sudo chown -R maria:maria /home/maria/Maildir
```

> Esto evita errores de expansión con patrones como `/*/` y garantiza propiedad/permisos correctos.

---

## 6) Alias internos (útiles en práctica)

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

> Redirigir **postmaster**/**root** evita perder avisos del sistema. 

---

## 7) Verificaciones rápidas en el servidor

```bash
# Servicios y puertos
systemctl --no-pager status postfix dovecot
ss -lntp | grep -E ':25|:143'

# Autenticación Dovecot
sudo doveadm auth test juan
sudo doveadm auth test maria

# Entrega local (Juan → Maria)
printf "Subject: Test Local\n\nHola Maria\n" | sendmail -v maria@jmrd.com
sudo tail -n 80 /var/log/mail.log | tail
# Esperado: "status=sent (delivered to mailbox)"
```

---

## 8) Configurar **Thunderbird** usando **la IP** (sin tocar hosts)

1. En Windows, ejecuta:

   ```bash
   multipass info correo
   ```

   Copia la **IPv4** (ej: `172.21.46.52`).

2. **Thunderbird → Nueva → Cuenta de correo existente → Configuración manual**
   Usa **la IP** como “Nombre del servidor” (IMAP y SMTP):

| Parámetro     | IMAP (entrante)   | SMTP (saliente)                   |
| ------------- | ----------------- | --------------------------------- |
| **Servidor**  | **<IP de la VM>** | **<IP de la VM>**                 |
| **Puerto**    | **143**           | **25**                            |
| **Seguridad** | **Ninguna**       | **Ninguna**                       |
| **Auth**      | Contraseña normal | **Sin autenticación**             |
| **Usuario**   | juan              | *(se ignora en SMTP 25 sin AUTH)* |

3. **Probar**:

   * Desde `juan@jmrd.com` envía a `maria@jmrd.com`.
   * En la cuenta de María, pulsa **Recibir**.
   * En el servidor:

     ```bash
     sudo tail -n 50 /var/log/mail.log | grep maria
     ```

> **Envíos externos:** serán rechazados (no hay AUTH; `reject_unauth_destination` evita open relay).

---

## 9) Diagnóstico útil

```bash
# Conectividad (desde la VM)
ping -c 3 8.8.8.8 || true
# Si tienes 'nc' instalado:
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

**Problemas típicos**

* No llega al buzón → verifica `/etc/hosts`, existencia de `Maildir` y permisos (700).
* Thunderbird no conecta → `ssl = no` en Dovecot y **Seguridad: Ninguna** en el cliente.
* Alias no funciona → faltó `sudo newaliases`.

---

## 10) (Opcional) UFW

```bash
sudo ufw allow 25,143/tcp
sudo ufw enable
sudo ufw status
```

---

## 11) ¿Cambia la IP otra vez?

* **No cambies nada en el servidor.**
* En **Thunderbird**, edita la cuenta y **sustituye la IP** en los servidores IMAP/SMTP.
* Listo.

---

### ✅ Resumen

* Guía lista para VM nueva, **cliente con IP directa** (sin tocar `hosts` en Windows).
* Postfix/Dovecot en **modo laboratorio**: IMAP 143 en claro + SMTP 25 sin AUTH (solo entrega local `@jmrd.com`).
* Maildir **con rutas absolutas** y permisos/propiedad por usuario.
* Chequeo **systemd** opcional, seguro vía *override*.
* Basada y corregida a partir de tu documento original. 

Si quieres, al terminar pega `postconf -n` y `doveconf -n` y te valido que todo quedó al 100%.
