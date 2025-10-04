# **Guía de Implementación de Correo Corporativo Pasivo en Ubuntu Server**

## 1. Introducción

El presente documento describe el procedimiento para implementar un **sistema de correo corporativo pasivo** sobre **Ubuntu Server**, utilizando **Postfix** como *Mail Transfer Agent (MTA)* y **Dovecot** como *Mail Delivery Agent (MDA)*.
El objetivo es que los estudiantes configuren un entorno práctico que permita el envío y recepción de correos internos bajo un dominio ficticio, aplicando conocimientos de administración de sistemas y redes.

📅 **Fecha límite de entrega:** 30 de octubre.
🔹 **Modalidad:** práctica individual con evidencia de pruebas.

---

## 2. Componentes del Sistema de Correo

1. **MTA (Mail Transfer Agent):** Se encarga de enviar y recibir correos electrónicos entre servidores. En este proyecto se usará **Postfix**.
2. **MDA (Mail Delivery Agent):** Entrega los correos en los buzones de usuario. Se utilizará **Dovecot**.
3. **MUA (Mail User Agent):** Cliente de correo usado por los usuarios finales (ejemplo: Thunderbird o mutt).

📌 Ejemplo de flujo:
Usuario A (MUA) → Postfix (MTA) → Dovecot (MDA) → Usuario B (MUA).

---

## 3. Preparación del Entorno

### 3.1. Requisitos

* Servidor con **Ubuntu Server 22.04 LTS** o superior.
* Conectividad de red activa.
* Acceso con privilegios de administrador (usuario con `sudo`).

### 3.2. Actualización del sistema

```bash
sudo apt update && sudo apt upgrade -y
```

---

## 4. Instalación y Configuración del Servidor de Correo

### 4.1. Instalación de Postfix y Dovecot

```bash
sudo apt install postfix dovecot-imapd dovecot-pop3d -y
```

Durante la instalación de Postfix:

* Seleccionar **Internet Site**.
* Nombre del correo del sistema: `JPL.com` (usar iniciales del alumno).

### 4.2. Configuración de Postfix

Archivo principal: `/etc/postfix/main.cf`

```bash
sudo nano /etc/postfix/main.cf
```

Configurar los siguientes parámetros básicos:

```
myhostname = mail.JPL.com
mydomain = JPL.com
myorigin = /etc/mailname
mydestination = $myhostname, localhost.$mydomain, localhost, $mydomain
relayhost =
inet_interfaces = all
inet_protocols = ipv4
home_mailbox = Maildir/
```

Guardar y reiniciar:

```bash
sudo systemctl restart postfix
```

### 4.3. Configuración de Dovecot

Archivo principal: `/etc/dovecot/dovecot.conf`

```bash
sudo nano /etc/dovecot/dovecot.conf
```

Agregar/modificar:

```
protocols = imap pop3
```

Configurar buzones en `/etc/dovecot/conf.d/10-mail.conf`:

```
mail_location = maildir:~/Maildir
```

Habilitar autenticación en `/etc/dovecot/conf.d/10-auth.conf`:

```
disable_plaintext_auth = no
auth_mechanisms = plain login
```

Reiniciar servicio:

```bash
sudo systemctl restart dovecot
```

---

## 5. Creación de Cuentas de Correo

Crear al menos dos usuarios del sistema que representarán las cuentas de correo:

```bash
sudo adduser juan
sudo adduser maria
```

Generar estructura de buzones:

```bash
sudo mkdir /home/juan/Maildir
sudo mkdir /home/maria/Maildir
sudo chown -R juan:juan /home/juan/Maildir
sudo chown -R maria:maria /home/maria/Maildir
```

---

## 6. Instalación y Configuración del Cliente de Correo (MUA)

### 6.1. Thunderbird (Windows/Linux)

* Instalar **Thunderbird** en el sistema cliente.
* Crear una nueva cuenta:

  * Nombre: Juan Pérez
  * Correo: `juan@JPL.com`
  * Servidor entrante: `mail.JPL.com` (IMAP o POP3, puerto 143/110)
  * Servidor saliente (SMTP): `mail.JPL.com` (puerto 25)
  * Usuario: nombre de usuario del sistema (ej. `juan`).

Repetir el procedimiento para el usuario `maria@JPL.com`.

---

## 7. Pruebas y Validación

### 7.1. Pruebas de red y resolución de nombres

```bash
ping mail.JPL.com
nslookup mail.JPL.com
```

### 7.2. Pruebas de conectividad a puertos

```bash
telnet mail.JPL.com 25   # SMTP
telnet mail.JPL.com 110  # POP3
telnet mail.JPL.com 143  # IMAP
```

### 7.3. Pruebas de envío y recepción

1. Desde Thunderbird de `juan@JPL.com`, enviar correo a `maria@JPL.com`.
2. Verificar recepción en la bandeja de María.
3. Responder el mensaje desde la cuenta de María a Juan.

📌 Evidencia esperada: capturas de pantalla mostrando el envío, recepción y encabezados de los correos.

---

## 8. Buenas Prácticas Mínimas

* **Seguridad:**

  * Deshabilitar el acceso anónimo.
  * Habilitar TLS (STARTTLS) si se busca producción.

* **Logs:**
  Revisar registros para diagnóstico:

  ```bash
  tail -f /var/log/mail.log
  ```

* **Colas de correo:**
  Verificar con:

  ```bash
  mailq
  ```

* **Mantenimiento:**
  Mantener el sistema actualizado y limpiar colas periódicamente.

---

## 9. Conclusiones

Este laboratorio permite a los estudiantes comprender los fundamentos de un sistema de correo electrónico corporativo, diferenciando los roles del MTA, MDA y MUA, así como la importancia de la correcta configuración de red, autenticación y pruebas de conectividad.

---
