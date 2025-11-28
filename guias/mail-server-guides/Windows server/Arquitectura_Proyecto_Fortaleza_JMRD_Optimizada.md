# 📘 GUÍA MAESTRA: FORTALEZA JMRD (Edición All-in-One)

**Configuración de Puertos:** Port A (LAN) / Port B (WAN)

-----

## 🗺️ 1. ARQUITECTURA LÓGICA Y FÍSICA

[Image of network topology with perimeter firewall DMZ and LAN zones]

```mermaid
graph TD
    %% Nodos de Infraestructura Hyper-V
    Host((PC Host Aquiles))
    DefSw[vSwitch: Default Switch <br/> NAT + Gestión]
    PrivSw[vSwitch: JMRD_LAN_Privada <br/> Aislamiento Total]

    %% Máquinas Virtuales
    Sophos[VM: Sophos XG Firewall]
    WinSrv[VM: JMRD-Server-AIO <br/> AD + Exchange]
    Win10[VM: JMRD-Cliente <br/> Win 10]

    %% Estilos
    style Host fill:#f9f,stroke:#333
    style DefSw fill:#ffcccc,stroke:#f00
    style PrivSw fill:#ccffcc,stroke:#0f0
    style Sophos fill:#ff9900,stroke:#333,stroke-width:4px
    style WinSrv fill:#e1f5fe,stroke:#0277bd
    style Win10 fill:#fff9c4,stroke:#fbc02d

    %% --- CONEXIONES ---
    
    %% INTERNET / WAN (Port B)
    Host --- DefSw
    DefSw ---|Port B - WAN <br/> (DHCP)| Sophos
    
    %% LAN PRIVADA (Port A)
    Sophos ===|Port A - LAN <br/> (10.10.10.1)| PrivSw
    
    %% SERVIDORES Y CLIENTES
    PrivSw ===|NIC 2 - LAN <br/> (10.10.10.10)| WinSrv
    PrivSw ===|NIC Única| Win10
    
    %% GESTIÓN SERVIDOR (Opcional, para RDP directo)
    DefSw -.->|NIC 1 - Gestión| WinSrv

    subgraph HYPER-V
    DefSw
    PrivSw
    Sophos
    WinSrv
    Win10
    end
```

### 📋 Tabla de Direccionamiento IP

| Interfaz Sophos | Zona | Conexión Hyper-V | IP Configurada | Función |
| :--- | :--- | :--- | :--- | :--- |
| **Port A** | **LAN** | `JMRD_LAN_Privada` | **10.10.10.1** | Gateway para tus VMs |
| **Port B** | **WAN** | `Default Switch` | **DHCP** | Salida a Internet |

-----

## 🛠️ FASE 0: PREPARACIÓN DE INFRAESTRUCTURA

1.  **Switch Privado:**
      * En Hyper-V, crea un Nuevo Conmutador Virtual.
      * Tipo: **Privado**.
      * Nombre: **`JMRD_LAN_Privada`**.

-----

## 🛡️ FASE 1: DESPLIEGUE DE SOPHOS (EL ORDEN ES CLAVE)

Para que Sophos detecte el Port A como LAN y el Port B como WAN automáticamente, debemos agregar los adaptadores en el orden correcto en Hyper-V.

### 1\. Crear la VM `JMRD-Sophos`

  * **Generación:** 1.
  * **Memoria:** 4096 MB.
  * **Disco:** 20 GB.
  * **Red Inicial (Primer Adaptador):** Selecciona **`JMRD_LAN_Privada`**.
      * *Esto hará que el primer adaptador (Port A) sea la LAN.*

### 2\. Configurar el Segundo Adaptador (WAN)

  * Ve a Configuración de la VM \> Agregar Hardware \> Adaptador de Red.
  * Conéctalo a: **`Default Switch`**.
      * *Esto hará que el segundo adaptador (Port B) sea la WAN.*

### 3\. Habilitar MAC Spoofing (OBLIGATORIO)

  * En la configuración de la VM, despliega el `+` de **AMBOS** adaptadores.
  * Ve a **Características avanzadas**.
  * Marca: **"Habilitar suplantación de direcciones MAC"**.

### 4\. Configuración Inicial (Consola Negra)

Instala Sophos. Al terminar, entra con `admin` y ve a **Network Configuration (1)** -\> **Interface Configuration (1)**.

  * **Port A (LAN):**
      * IP Estática: **10.10.10.1**
      * Netmask: `/24` (255.255.255.0)
  * **Port B (WAN):**
      * IP: **DHCP** (Debe recibir IP del Default Switch).

-----

## 🧠 FASE 2: EL SERVIDOR "TODO EN UNO"

### 1\. Crear la VM `JMRD-Server-AIO`

  * **Generación:** 2.
  * **Memoria:** **12 GB** (Recomendado para Exchange).
  * **Instalación:** Windows Server 2019 Standard (Desktop Experience).

### 2\. Adaptadores de Red (Hyper-V)

Agrega dos adaptadores para tener gestión fácil + producción:

1.  **Adaptador 1:** `Default Switch` (Para RDP y bajar updates rápido).
2.  **Adaptador 2:** `JMRD_LAN_Privada` (Para ser el DC de la red interna).

### 3\. Configuración IP (Dentro de Windows)

Identifica cuál es cuál (puedes desconectar uno en Hyper-V para ver cuál se cae).

  * **NIC 1 (Gestión):** Déjala en DHCP (Recibirá IP de Hyper-V, ej. 172.x.x.x).
  * **NIC 2 (Producción - JMRD.corp):**
      * **IP:** `10.10.10.10`
      * **Mascara:** `255.255.255.0`
      * **Gateway:** `10.10.10.1` (Apunta al Port A del Sophos).
      * **DNS:** `127.0.0.1`.

### 4\. Instalación de Roles

  * **Active Directory:** Promover a `JMRD.corp`.
  * **DHCP:**
      * Crear Scope `10.10.10.50 - .200`.
      * Opción 003 Router: `10.10.10.1`.
      * Opción 006 DNS: `10.10.10.10`.
  * **Exchange 2019:** Instalar prerrequisitos y luego el Setup.exe (Mailbox Role).

-----

## 💻 FASE 3: EL CLIENTE (WINDOWS 10)

### 1\. Crear la VM `JMRD-Cliente`

  * **Red:** Conéctala **ÚNICAMENTE** a `JMRD_LAN_Privada`.
      * *Así garantizamos que no tenga internet "gratis" del Default Switch.*

### 2\. Integración y Prueba

  * Verifica que reciba IP automática (ej. `10.10.10.50`).
  * Verifica Ping a `10.10.10.1` (Sophos) y `10.10.10.10` (Server).
  * Une al dominio `JMRD.corp`.

-----

## ✅ FASE 4: REGLAS DE FIREWALL (SOPHOS WEB)

Desde el cliente Windows 10 (usando Firefox/Chrome):

1.  Entra a `https://10.10.10.1:4444`.
2.  Ve a **Rules and Policies**.
3.  Crea la regla de salida:
      * **Source Zone:** LAN.
      * **Dest Zone:** WAN.
      * **Action:** Accept.
      * **NAT:** Masquerading (MASQ) activado.
