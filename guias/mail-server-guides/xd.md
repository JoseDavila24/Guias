# 📘 BITÁCORA MAESTRA DE INGENIERÍA: PROYECTO JMRD.LAB

## 1. 🪆 La Arquitectura: "Matryoshka" (Muñeca Rusa Digital)
Descubriste que tu laboratorio no es una simple virtualización, sino una compleja torre de capas anidadas (Nested Virtualization). Entender esto fue clave para saber por qué necesitabas activar extensiones en el procesador.

**Tus Capas de Abstracción:**
1.  🧱 **Hardware:** Tu Laptop "Aquiles" (Intel i5 11th Gen, 24GB RAM).
2.  🪟 **Host OS:** Windows 11 Pro.
3.  ⚡ **Hipervisor Nivel 1:** **Hyper-V** (Gestiona los recursos reales).
4.  🐧 **VM Intermedia:** **GNS3 VM** (Un servidor Linux corriendo sobre Hyper-V).
5.  ⚙️ **Emulador Nivel 2:** **QEMU/KVM** (Viviendo dentro de GNS3 VM).
6.  🖥️ **Guest VM:** Tus servidores finales (**FreeBSD / Ubuntu**).

**El Logro:** Para que la capa 6 funcionara, tuviste que usar PowerShell (`Set-VMProcessor ... -ExposeVirtualizationExtensions $true`) para "perforar" las capas intermedias y pasar las instrucciones del CPU hasta el fondo.

---

## 2. ⚔️ El Conflicto: Hyper-V vs FreeBSD
Te enfrentaste a un "Jefe Final" de compatibilidad.
* **El Síntoma:** Los `ping` (paquetes pequeños) funcionaban, pero `pkg install` (paquetes grandes/descargas) se congelaban al 0%.
* **La Causa:** Una incompatibilidad entre los drivers de red de FreeBSD y la función **RSC (Receive Segment Coalescing)** de los switches virtuales de Hyper-V. Hyper-V unía paquetes para optimizar, pero FreeBSD los recibía como "basura corrupta" y los descartaba.

---

## 3. 🌉 La Solución Ganadora: "El Puente Ubuntu"
Intentamos parches de software (MTU, TSO off), pero la solución definitiva fue arquitectónica. Usaste un sistema que *sí* se lleva bien con Hyper-V (Ubuntu) para salvar al que no (FreeBSD).

**Topología de Rescate:**
`FreeBSD` ➡️ `Ubuntu (Router/Gateway)` ➡️ `NAT (Internet)`

* **Cómo funcionó:**
    1.  Configuraste Ubuntu con dos tarjetas: una a Internet (NAT) y otra a una red privada interna.
    2.  Conectaste FreeBSD a esa red privada y usaste a Ubuntu como su Puerta de Enlace (Gateway).
    3.  **El Truco:** Ubuntu recibía los paquetes "sucios" de Hyper-V, los reensamblaba correctamente (porque sus drivers son mejores) y se los entregaba "limpios" a FreeBSD por la red interna.
* **Resultado:** Descarga exitosa de todas las herramientas sin congelamientos.

---

## 4. 📜 Infraestructura como Código (Scripting)
Una vez resuelta la red, pasaste a la automatización para no configurar a mano si el servidor moría.
* Creaste el script maestro **`install_full.sh`**.
* **Capacidades:**
    * Aplica parches de red (`mtu 1200`).
    * Instala paquetes (`-4` para forzar IPv4).
    * Escribe configuraciones de servicios (`dhcpd.conf`, `main.cf`).
    * Crea usuarios y alias automáticamente.

---

## 5. 🏢 Lógica de Negocio: El Depto. de RRHH
Implementaste un servidor de correo funcional con reglas de negocio reales.
* **Servicios:** **DHCP** (IPs dinámicas), **Postfix** (SMTP) y **Dovecot** (IMAP).
* **El Reto de Auth:** Descubriste que Dovecot necesita la instrucción `passdb { driver = pam }` para leer los usuarios del sistema FreeBSD, de lo contrario, rechazaba las conexiones.
* **Grupos y Alias:** Configuraste `nominas@jmrd.com` para que un solo correo se duplique y llegue a los buzones individuales de **Brenda** y **Wendy**.
* **Cliente:** Validaste todo desde un **Lubuntu** externo usando **Sylpheed**, demostrando comunicación real entre máquinas.
