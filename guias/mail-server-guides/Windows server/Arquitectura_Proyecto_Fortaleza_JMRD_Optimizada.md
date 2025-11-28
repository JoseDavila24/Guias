# 📘 GUÍA MAESTRA: FORTALEZA JMRD (HYPER-V NATIVO)

**Objetivo:** Infraestructura Empresarial (AD + Exchange + Firewall) Segura y Aislada.
**Hardware:** Host Windows 11 Pro (24GB+ RAM).

---

## 🗺️ LA ARQUITECTURA LÓGICA

En Hyper-V no usamos cables, usamos **Conmutadores (Switches)**.



[Image of network topology with perimeter firewall DMZ and LAN zones]


### 1. Las Redes (Los Rieles)
* **🌐 Default Switch (Gestión/WAN):**
    * **Función:** Provee Internet (NAT) y acceso desde tu PC Host.
    * **Seguridad:** Tu PC ve a las VMs, pero las VMs están "detrás" de una NAT. Seguro.
* **🔒 JMRD_LAN_Privada (Producción/LAN):**
    * **Función:** Red interna pura (`10.10.10.0/24`).
    * **Seguridad:** **AISLAMIENTO TOTAL.** El tráfico de aquí (DHCP, DNS, Dominio) **no puede** escapar a tu tarjeta Wi-Fi física. Es un vacío digital.

### 2. Los Actores (Las VMs)
1.  **🛡️ Sophos XG:** El puente entre el mundo exterior (Default) y el interior (Privada).
2.  **🧠 JMRD-DC (Server Core):** Controlador de Dominio y DHCP. Vive en ambas redes (para que lo administres) o solo en la privada.
3.  **📧 JMRD-Exchange:** Servidor de Correo. Vive en la privada (pero con acceso a gestión).
4.  **💻 Cliente Win10:** Vive **SOLO** en la privada. Su único camino a internet es cruzar el Sophos.

---

## 🛠️ FASE 0: PREPARACIÓN DEL TERRENO (INFRAESTRUCTURA)

### Paso 1: Crear el Switch Aislado
1.  Abre **Administrador de Hyper-V**.
2.  Panel derecho: **Administrador de conmutadores virtuales**.
3.  Nuevo conmutador de red virtual > Tipo: **Privado**.
4.  Clic en **Crear**.
5.  Nombre: `JMRD_LAN_Privada`.
6.  Aceptar.

### Paso 2: Descargar Materiales (ISOs)
Asegúrate de tener:
* `Sophos XG Firewall (Versión para Hyper-V/Intel)`.
* `Windows Server 2019`.
* `Windows 10 Enterprise LTSC` (o Pro).
* `Exchange Server 2019`.

---

## 🛡️ FASE 1: DESPLIEGUE DEL GUARDIÁN (SOPHOS)

### 1. Crear la VM
* **Nombre:** `JMRD-Sophos`.
* **Generación:** **Generación 1** (Vital para compatibilidad con Sophos).
* **Memoria:** 4096 MB (Desmarca "Memoria Dinámica").
* **Red:** Conéctala a **Default Switch** (Esta será la WAN).
* **Disco:** 20 GB.
* **ISO:** Carga la imagen de Sophos.

### 2. Configurar la Segunda Pata (LAN)
Una vez creada, **no la enciendas aún**. Clic derecho > **Configuración**:
1.  **Agregar Hardware** > Adaptador de Red > Agregar.
2.  Conéctalo a: `JMRD_LAN_Privada`.
3.  **⚠️ TRUCO VITAL (MAC Spoofing):**
    * Despliega el menú (+) de **ambos** adaptadores de red.
    * Ve a **Características avanzadas**.
    * Marca la casilla: **"Habilitar suplantación de direcciones MAC"**.
    * *(Sin esto, Sophos no puede enrutar tráfico en Hyper-V).*

### 3. Instalación y IP
* Instala Sophos.
* En la consola negra, configura:
    * **Port A (WAN):** DHCP.
    * **Port B (LAN):** IP Estática `10.10.10.1` / `/24`.

---

## 🧠 FASE 2: EL CEREBRO (CONTROLADOR DE DOMINIO)

### 1. Crear la VM
* **Nombre:** `JMRD-DC`.
* **Generación:** **Generación 2** (Moderna y rápida).
* **Memoria:** 2048 MB.
* **Red:** Conéctala a **Default Switch** (Para gestión y updates).

### 2. Agregar Pata LAN
* Configuración > Agregar Hardware > Adaptador de Red.
* Conéctalo a: `JMRD_LAN_Privada`.

### 3. Configuración Interna (Post-Install)
* Renombrar adaptadores (WAN / LAN).
* **IP LAN:** `10.10.10.10`.
* **Gateway LAN:** `10.10.10.1` (Apunta al Sophos).
* **DNS:** `127.0.0.1` (Se apuntará a sí mismo cuando sea DC).
* **Rol:** Instalar Active Directory y configurar dominio `JMRD.corp`.
* **Rol:** Instalar DHCP (Scope `10.10.10.50` - `.200`).

---

## 💻 FASE 3: EL CLIENTE (LA PRUEBA DE AISLAMIENTO)

### 1. Crear la VM
* **Nombre:** `JMRD-Cliente`.
* **Generación:** 2.
* **Memoria:** 2048 MB.
* **Red:** **SOLO** conecta a `JMRD_LAN_Privada`.
    * *Al no conectarlo al Default Switch, garantizamos que si navega, es gracias a tu configuración.*

### 2. Prueba de Fuego
* Unir al dominio `JMRD.corp`.
* Navegar en Internet (Debe pasar por: Cliente -> Switch Privado -> Sophos -> Default Switch -> Internet).

---

## 📧 FASE 4: EL GIGANTE (EXCHANGE SERVER)

### 1. Crear la VM
* **Nombre:** `JMRD-Exchange`.
* **Generación:** 2.
* **Memoria:** 8192 MB (Mínimo recomendado).
* **Red:** Doble pata (Default + Privada) igual que el DC.

### 2. Despliegue
* Unir al dominio.
* Instalar prerrequisitos.
* Instalar Exchange 2019.

---

### 📝 Resumen de IPs (Para no perdernos)

| Dispositivo | Interfaz WAN (Gestión) | Interfaz LAN (Privada) | Gateway |
| :--- | :--- | :--- | :--- |
| **Sophos** | DHCP (172.x or 192.x) | **10.10.10.1** | (Del ISP) |
| **DC (AD/DNS)** | DHCP | **10.10.10.10** | 10.10.10.1 |
| **Exchange** | DHCP | **10.10.10.15** | 10.10.10.1 |
| **Cliente** | --- | *DHCP (.50+)* | 10.10.10.1 |

**¿Estás listo para iniciar la FASE 0 y crear los switches en Hyper-V?**
