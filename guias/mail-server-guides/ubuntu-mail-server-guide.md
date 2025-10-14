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

| Componente      | Función                   | Estado             |
| --------------- | ------------------------- | ------------------ |
| **Postfix**     | MTA – Envío SMTP          | ⚙️ **Configurado** |
| **Dovecot**     | MDA – Recepción IMAP/POP3 | ✅ **Operativo**    |
| **Thunderbird** | MUA – Cliente de correo   | ✅ **Conectado**    |
| **Multipass**   | Virtualización            | ✅ **Operativo**    |

---

## **3. CONFIGURACIÓN DEL SERVIDOR**

### **3.1 Entorno Multipass**

```bash
# Creación de la instancia
multipass launch 24.04 --name correo --cpus 2 --memory 2G --disk 10G

# Verificación
multipass info correo
# Name: correo | State: Running | IPv4: 172.19.69.99
```

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
sudo apt install postfix dovecot-imapd dovecot-pop3d -y
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
mydestination = $myhostname, jmrd.com, mail.jmrd.com, localhost.jmrd.com, localhost
relayhost =
inet_interfaces = all
inet_protocols = all
home_mailbox = Maildir/
```

**Verificación:**

```bash
sudo postconf -n
sudo systemctl status postfix
```

---

### **3.5 Configuración de Dovecot**

**Archivo:** `/etc/dovecot/conf.d/10-mail.conf`

```bash
mail_location = maildir:~/Maildir
```

**Archivo:** `/etc/dovecot/conf.d/10-auth.conf`

```bash
disable_plaintext_auth = no
auth_mechanisms = plain login
```

**Verificación:**

```bash
sudo doveconf -n
sudo systemctl status dovecot
```

---

### **3.6 Creación de Usuarios Corporativos**

```bash
sudo adduser juan
sudo adduser maria

sudo mkdir -p /home/juan/Maildir/{cur,new,tmp}
sudo mkdir -p /home/maria/Maildir/{cur,new,tmp}
sudo chown -R juan:juan /home/juan/Maildir
sudo chown -R maria:maria /home/maria/Maildir
sudo chmod -R 700 /home/*/Maildir
```

---

### **3.7 Verificación Final de Servicios**

```bash
sudo systemctl status dovecot
sudo systemctl status postfix
sudo ss -tulpn | grep -E ':25|:110|:143'
sudo doveadm auth test juan
sudo doveadm auth test maria
```

---

### **3.8 Creación de Grupos de Correo (Listas Internas de Aviso)**

#### **Objetivo**

Habilitar direcciones internas compartidas que envíen un mismo mensaje a varios buzones locales (por ejemplo, `avisos@jmrd.com` → juan, maria).

#### **Procedimiento**

1. **Editar archivo de alias**

   ```bash
   sudo nano /etc/aliases
   ```

   Agregar:

   ```
   # Grupo general de avisos
   avisos: juan, maria

   # Grupo soporte técnico
   soporte: juan

   # Grupo dirección
   direccion: maria
   ```

2. **Compilar los alias**

   ```bash
   sudo newaliases
   ```

3. **Verificar configuración**

   ```bash
   sudo postconf alias_maps
   ```

   Si es necesario:

   ```bash
   sudo postconf -e "alias_maps = hash:/etc/aliases"
   sudo systemctl restart postfix
   ```

4. **Prueba de funcionamiento**

   ```bash
   echo "Mensaje de prueba para grupo avisos" | mail -s "Aviso Interno" avisos@jmrd.com
   ```

   Ambos usuarios (`juan` y `maria`) deben recibir el mensaje.

5. **Verificación de entrega**

   ```bash
   sudo tail -f /var/log/mail.log | grep avisos
   ```

#### **Resultado Esperado**

| Grupo     | Dirección Interna                               | Entrega a   | Estado     |
| --------- | ----------------------------------------------- | ----------- | ---------- |
| avisos    | [avisos@jmrd.com](mailto:avisos@jmrd.com)       | juan, maria | ✅ Correcto |
| soporte   | [soporte@jmrd.com](mailto:soporte@jmrd.com)     | juan        | ✅ Correcto |
| direccion | [direccion@jmrd.com](mailto:direccion@jmrd.com) | maria       | ✅ Correcto |

**Conclusión:**
Esta configuración permite enviar notificaciones internas a diferentes áreas corporativas, simulando listas de distribución reales sin necesidad de servicios externos.

---

## **4. CONFIGURACIÓN DE CLIENTES**

### **4.1 Thunderbird – Configuración Exitosa**

| Parámetro         | Valor                        |
| ----------------- | ---------------------------- |
| **Servidor IMAP** | 172.19.69.99                 |
| **Puerto**        | 143                          |
| **SSL**           | Ninguno                      |
| **Autenticación** | Contraseña normal            |
| **Usuario**       | juan o maria                 |
| **Contraseña**    | Definida durante la creación |

---

### **4.2 Verificación de Conexión**

```bash
sudo journalctl -u dovecot | grep "Login: user"
```

**Salida esperada:**

```
imap-login: Login: user=<juan>, method=PLAIN, rip=172.19.64.1, lip=172.19.69.99
imap-login: Login: user=<maria>, method=PLAIN, rip=172.19.64.1, lip=172.19.69.99
```

---

## **5. SISTEMA DE CORREO PASIVO**

| Funcionalidad  | Estado         | Descripción                     |
| -------------- | -------------- | ------------------------------- |
| Recepción IMAP | ✅ Operativa    | Acceso a buzones desde clientes |
| Autenticación  | ✅ Operativa    | Validación de usuarios          |
| Almacenamiento | ✅ Operativo    | Maildir funcional               |
| Envío Local    | ⚙️ Configurado | Postfix escuchando en puerto 25 |
| Envío Externo  | ❌ No requerido | Fuera del alcance pasivo        |

---

## **6. EVIDENCIA DE FUNCIONAMIENTO**

### **6.1 Servicios Activos**

```bash
sudo systemctl is-active dovecot
sudo systemctl is-active postfix
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

| Problema                           | Causa                       | Solución                               |
| ---------------------------------- | --------------------------- | -------------------------------------- |
| Autenticación falla en Thunderbird | Usuario usa `juan@jmrd.com` | Ingresar solo `juan`                   |
| Postfix no inicia proceso          | Modo pasivo                 | Verificar que escuche puerto 25        |
| No hay buzones                     | Permisos incorrectos        | `chown` y `chmod` en `/home/*/Maildir` |

---

## **8. CONCLUSIÓN**

### **8.1 Objetivos Cumplidos**

✅ Sistema de correo corporativo pasivo operativo
✅ Autenticación y buzones Maildir configurados
✅ Clientes Thunderbird funcionales
✅ Alias internos implementados para avisos corporativos

### **8.2 Características Finales**

| Parámetro           | Valor                      |
| ------------------- | -------------------------- |
| **Tipo**            | Correo corporativo pasivo  |
| **Dominio**         | jmrd.com                   |
| **Usuarios**        | juan, maria                |
| **Grupos internos** | avisos, soporte, dirección |
| **Cliente**         | Thunderbird IMAP           |

### **8.3 Conclusión General**

La implementación demuestra el funcionamiento integral de un sistema de correo corporativo interno basado en Ubuntu Server. Se comprendieron los roles del **MTA (Postfix)**, **MDA (Dovecot)** y **MUA (Thunderbird)**, además de la creación de **grupos internos de notificación** para comunicación interdepartamental, consolidando una infraestructura funcional de correo electrónico corporativo pasivo.

---

📅 **Fecha de Implementación:** 14 de Octubre de 2025
👤 **Administrador:** Chema (José María Romero Dávila)
🏢 **Corporación:** JMRD
✅ **Estado de Práctica:** COMPLETADA Y VALIDADA
