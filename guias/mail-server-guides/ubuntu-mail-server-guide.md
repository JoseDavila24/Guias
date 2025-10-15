# **Guía Completa: Implementación de Sistema de Correo Corporativo Pasivo en Ubuntu Server**

---

## **📋 Tabla de Contenidos**

1. [Introducción](#1-introducción)
2. [Arquitectura del Sistema](#2-arquitectura-del-sistema)
3. [Configuración del Servidor](#3-configuración-del-servidor)
4. [Configuración de Clientes](#4-configuración-de-clientes)
5. [Sistema de Correo Pasivo](#5-sistema-de-correo-pasivo)
6. [Evidencia de Funcionamiento](#6-evidencia-de-funcionamiento)
7. [Anexos Técnicos](#7-anexos-técnicos)
8. [Conclusión](#8-conclusión)

---

## **1. INTRODUCCIÓN**

### **1.1 Objetivo**

Implementar un **sistema de correo corporativo pasivo** sobre **Ubuntu Server 24.04 LTS**, utilizando **Postfix** como *Mail Transfer Agent (MTA)* y **Dovecot** como *Mail Delivery Agent (MDA)*, bajo el dominio corporativo **jmrd.com**.

### **1.2 Alcance**

* ✅ Correo interno corporativo
* ✅ Autenticación de usuarios locales
* ✅ Almacenamiento en buzones Maildir
* ✅ Acceso mediante cliente Thunderbird
* ❌ Comunicación con dominios externos
* ❌ Resolución DNS MX externa

### **1.3 Especificaciones Técnicas**

| Elemento           | Descripción             |
| ------------------ | ----------------------- |
| **Servidor**       | Ubuntu Server 24.04 LTS |
| **Virtualización** | Multipass con Hyper-V   |
| **Dirección IP**   | 172.19.69.99            |
| **Dominio**        | jmrd.com                |
| **Usuarios**       | juan, maria             |

---

## **2. ARQUITECTURA DEL SISTEMA**

### **2.1 Diagrama de Arquitectura**

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Thunderbird   │ ── │   Dovecot IMAP   │ ── │   Buzones       │
│   (Cliente)     │    │   (Recepción)    │    │   Maildir       │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                        │                        │
         └────────────────────────┼────────────────────────┘
                                  │
                         ┌──────────────────┐
                         │   Postfix SMTP   │
                         │   (Envío Local)  │
                         └──────────────────┘
```

### **2.2 Componentes Implementados**

| Componente      | Función                   | Estado         |
| --------------- | ------------------------- | -------------- |
| **Postfix**     | MTA – Envío SMTP          | ⚙️ Configurado |
| **Dovecot**     | MDA – Recepción IMAP/POP3 | ✅ Operativo    |
| **Thunderbird** | MUA – Cliente de correo   | ✅ Conectado    |
| **Multipass**   | Virtualización            | ✅ Operativo    |

---

## **3. CONFIGURACIÓN DEL SERVIDOR**

### **3.1 Entorno Multipass**

```bash
multipass launch 24.04 --name correo --cpus 2 --memory 2G --disk 10G
multipass info correo
```

**Ejemplo de salida:**
`Name: correo | State: Running | IPv4: 172.19.69.99`

---

### **3.2 Configuración Básica del Sistema**

```bash
multipass shell correo
sudo hostnamectl set-hostname mail.jmrd.com
sudo nano /etc/hosts
# 172.19.69.99 mail.jmrd.com mail localhost
```

---

### **3.3 Instalación de Servicios**

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install postfix dovecot-imapd dovecot-pop3d bsd-mailx mailutils -y
```

Durante la instalación de **Postfix**:

* Tipo: **Internet Site**
* System mail name: **jmrd.com**

---

### **3.4 Configuración de Postfix**

**Archivo:** `/etc/postfix/main.cf`

```bash
myhostname = mail.jmrd.com
mydomain = jmrd.com
myorigin = /etc/mailname
mydestination = $myhostname, $mydomain, localhost.$mydomain, localhost

mynetworks = 127.0.0.0/8 172.19.0.0/16 [::1]/128
smtpd_recipient_restrictions = permit_mynetworks, reject_unauth_destination

inet_interfaces = all
inet_protocols = ipv4
home_mailbox = Maildir/

local_recipient_maps = unix:passwd.byname $alias_maps
alias_maps = hash:/etc/aliases
```

**Verificación:**

```bash
sudo newaliases
sudo postfix reload
sudo postconf -n
```

---

### **3.5 Configuración de Dovecot**

**Archivo:** `/etc/dovecot/conf.d/10-mail.conf`

```conf
mail_location = maildir:~/Maildir
```

**Archivo:** `/etc/dovecot/conf.d/10-auth.conf`

```conf
disable_plaintext_auth = no
auth_mechanisms = plain login
```

**Verificación:**

```bash
sudo doveconf -n
sudo systemctl restart dovecot
```

---

### **3.6 Creación de Usuarios Corporativos**

```bash
sudo adduser juan
sudo adduser maria

sudo -u juan  maildirmake.dovecot ~/Maildir
sudo -u maria maildirmake.dovecot ~/Maildir
sudo chmod -R 700 /home/*/Maildir
```

---

### **3.7 Verificación Final de Servicios**

```bash
sudo systemctl status postfix
sudo systemctl status dovecot
sudo ss -tulpn | grep -E ':25|:110|:143'
sudo doveadm auth test juan
sudo doveadm auth test maria
```

---

### **3.8 Creación de Grupos de Correo (Listas Internas de Aviso)**

**Archivo:** `/etc/aliases`

```
avisos: juan, maria
soporte: juan
direccion: maria
```

```bash
sudo newaliases
sudo postfix reload
```

**Prueba:**

```bash
echo "Mensaje de prueba" | mail -s "Aviso Interno" avisos@jmrd.com
sudo tail -f /var/log/mail.log | grep avisos
```

---

## **4. CONFIGURACIÓN DE CLIENTES**

### **4.1 Thunderbird – Configuración Exitosa (Paso a Paso)**

#### **1. Preparación en el cliente**

* Asegúrate de poder hacer ping:

  ```bash
  ping mail.jmrd.com
  ```
* Verifica conectividad:

  ```bash
  telnet mail.jmrd.com 143
  telnet mail.jmrd.com 25
  ```

#### **2. Alta de cuenta**

1. Abre **Thunderbird** → **☰ → Nueva → Cuenta de correo existente**.
2. Datos:

   * **Nombre:** Juan Pérez
   * **Correo:** [juan@jmrd.com](mailto:juan@jmrd.com)
   * **Contraseña:** (la definida al crear el usuario)
3. Pulsa **Continuar → Configuración manual**.

#### **3. Configuración manual recomendada**

| Parámetro     | Entrante (IMAP)   | Saliente (SMTP)   |
| ------------- | ----------------- | ----------------- |
| Servidor      | mail.jmrd.com     | mail.jmrd.com     |
| Puerto        | 143               | 25                |
| Seguridad     | Ninguna           | Ninguna           |
| Autenticación | Contraseña normal | Sin autenticación |
| Usuario       | juan              | juan              |

Pulsa **Reprobar** y luego **Hecho**.

> 📘 Si activas SMTP AUTH en el futuro, usa puerto **587** y “Contraseña normal”.

---

#### **4. Ajustes de recepción**

* Configuración de la cuenta → **Sincronización y almacenamiento**:

  * ✅ Comprobar mensajes cada **1 minuto**.
  * ✅ Permitir conexión mantenida (IDLE).
* Click derecho sobre la cuenta → **Suscribirse…** → marca **INBOX**.
* Desactiva temporalmente el filtro de correo no deseado.

---

#### **5. Configurar SMTP correcto**

* Menú: **Configuración de la cuenta → Servidor de salida (SMTP)**.

  * Elige el servidor `mail.jmrd.com` (puerto 25, sin autenticación).
  * Marca **Establecer por defecto**.
  * Verifica que tu identidad “[juan@jmrd.com](mailto:juan@jmrd.com)” usa este SMTP.

---

#### **6. Prueba de envío y recepción**

* Desde `juan@jmrd.com`: redacta correo a `maria@jmrd.com`.
* Asunto: *Prueba interna Thunderbird*.
* Envía.
* En la cuenta de María, pulsa **Recibir**.
* Verifica llegada del correo en INBOX.

**En servidor:**

```bash
sudo tail -n 50 /var/log/mail.log | grep maria
```

**Salida esperada:**

```
status=sent (delivered to mailbox)
```

---

#### **7. Prueba con grupo de avisos**

* Desde Juan: enviar a `avisos@jmrd.com`.
* Verifica que tanto **Juan** como **María** reciben el mensaje.

```bash
sudo tail -n 50 /var/log/mail.log | grep avisos
```

---

#### **8. Buenas prácticas de uso**

* Compactar carpetas periódicamente.
* Revisar encabezados con **Ctrl+U** (verificar “From: mail.jmrd.com”).
* Mantener sincronización IMAP cada 1–2 min.
* Evitar usar “@jmrd.com” en el campo de usuario al autenticar.
* Revisar `mail.log` si algún correo no aparece.

---

### **4.2 Verificación de Conexión (Servidor)**

```bash
sudo journalctl -u dovecot | grep "Login: user"
sudo ss -tulpn | grep -E ':25|:143'
printf "Subject: Test\n\nHola\n" | sendmail -v maria@jmrd.com
sudo tail -n 60 /var/log/mail.log
```

---

## **5. SISTEMA DE CORREO PASIVO**

| Funcionalidad  | Estado         | Descripción                     |
| -------------- | -------------- | ------------------------------- |
| Recepción IMAP | ✅ Operativa    | Acceso a buzones desde clientes |
| Autenticación  | ✅ Operativa    | Validación de usuarios          |
| Almacenamiento | ✅ Operativo    | Maildir funcional               |
| Envío Local    | ⚙️ Configurado | Postfix escucha en puerto 25    |
| Envío Externo  | ❌ No requerido | Fuera del alcance pasivo        |

---

## **6. EVIDENCIA DE FUNCIONAMIENTO**

### **6.1 Servicios Activos**

```bash
sudo systemctl is-active postfix
sudo systemctl is-active dovecot
sudo ss -tulpn | grep :143
telnet localhost 25
```

### **6.2 Estructura de Buzones**

```bash
sudo ls -la /home/juan/Maildir/
sudo ls -la /home/maria/Maildir/
```

---

## **7. ANEXOS TÉCNICOS**

### **7.1 Monitoreo**

```bash
sudo journalctl -u dovecot -f
sudo tail -f /var/log/mail.log
sudo doveadm who
sudo doveadm mailbox status -u juan all
```

### **7.2 Solución de Problemas**

| Problema                    | Causa                                               | Solución                               |
| --------------------------- | --------------------------------------------------- | -------------------------------------- |
| No se pueden enviar correos | SMTP incorrecto                                     | Revisar “Servidor de salida (SMTP)”    |
| Thunderbird no recibe       | Carpeta INBOX no suscrita                           | Click derecho → Suscribirse…           |
| Autenticación falla         | Usuario usa “[juan@jmrd.com](mailto:juan@jmrd.com)” | Usar solo “juan”                       |
| No hay buzones              | Permisos erróneos                                   | `chown` y `chmod` en `/home/*/Maildir` |
| Alias no funciona           | Falta `newaliases`                                  | Ejecutar `sudo newaliases`             |

---

## **8. CONCLUSIÓN**

### **8.1 Objetivos Cumplidos**

✅ Sistema de correo corporativo pasivo operativo
✅ Autenticación y buzones Maildir configurados
✅ Clientes Thunderbird funcionales
✅ Alias internos implementados correctamente

---

### **8.2 Características Finales**

| Parámetro           | Valor                      |
| ------------------- | -------------------------- |
| **Tipo**            | Correo corporativo pasivo  |
| **Dominio**         | jmrd.com                   |
| **Usuarios**        | juan, maria                |
| **Grupos internos** | avisos, soporte, dirección |
| **Cliente**         | Thunderbird IMAP           |

---

### **8.3 Conclusión General**

La implementación demuestra el funcionamiento integral de un sistema de correo electrónico corporativo interno basado en Ubuntu Server.
Se comprendieron los roles del **MTA (Postfix)**, **MDA (Dovecot)** y **MUA (Thunderbird)**, así como la importancia de los alias y la correcta configuración del cliente para la recepción efectiva de mensajes.
El sistema resultante es **estable, funcional y didáctico**, adecuado para entornos académicos y prácticas universitarias en administración de sistemas.

---

📅 **Fecha de Implementación:** 14 de Octubre de 2025
👤 **Administrador:** Chema (José María Romero Dávila)
🏢 **Corporación:** JMRD
✅ **Estado de Práctica:** COMPLETADA Y VALIDADA

---
