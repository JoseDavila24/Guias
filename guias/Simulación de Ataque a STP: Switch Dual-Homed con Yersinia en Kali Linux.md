## 📚 **Guía Completa: Ataque 4 – Simulating a Dual-Homed Switch**

---

### 🔹 **Objetivo del ataque**

Simular un switch conectado a dos switches reales (dual-homed), enviar BPDUs falsos para proclamarse **Root Bridge** y redirigir el tráfico a través del atacante, usando **Yersinia** sobre **Kali Linux**.

---

### 🔧 **Requisitos**

* 2 switches Cisco **Catalyst 2950**
* 1 PC con **Kali Linux**
* **2 interfaces Ethernet activas en la PC**
* **Yersinia** instalado (`sudo apt install yersinia`)
* Cables Ethernet y una red de laboratorio (controlada)

---

### 📌 **Topología del ataque**

```
[Switch1] ─────┐
               ├──> [Kali Linux con Yersinia] <───[Switch2]
[PC Víctima] ──┘                     eth0   eth1
```

---

### 🧰 **Preparación**

#### 1. **Conecta Kali a ambos switches**

* `eth0` → puerto de **Switch1** (ej. fa0/1)
* `eth1` → puerto de **Switch2** (ej. fa0/2)

#### 2. **Activa las interfaces en Kali**

```bash
sudo ip link set eth0 up
sudo ip link set eth1 up
```

#### 3. **Verifica conexión**

```bash
ip a
```

Asegúrate de que ambas interfaces estén activas.

---

### 🧨 **Ejecutar el ataque con Yersinia**

#### 1. **Abre Yersinia en modo interactivo**

```bash
sudo yersinia -I
```

#### 2. **Inicia el ataque Dual-Homed**

En la interfaz de Yersinia:

* Presiona `P` → selecciona **STP**
* Presiona `a` → elige la opción:

  > **"Claiming Root Role Dual-Home (MITM)"**
* Verifica que el ataque esté activo (aparece en la lista)
* Deja correr el ataque unos minutos

---

### 🔍 **Verificación desde los switches**

Ejecuta en ambos Catalyst 2950:

```bash
show spanning-tree
```

Revisa:

* Si el **Root Bridge cambió** a la MAC de tu Kali
* Si los puertos **modificaron su estado**
* Si aparece tráfico dirigido hacia Kali

---

### 🛡️ **Mitigación del ataque**

#### ✅ **Usar BPDU Guard en puertos de acceso**

```bash
conf t
interface range fa0/1 - 24
 spanning-tree portfast
 spanning-tree bpduguard enable
end
```

🧠 **Qué hace:** Desactiva automáticamente cualquier puerto que reciba BPDUs (como los que envía Kali).

---

#### 🛑 **Usar Root Guard en troncales o uplinks**

```bash
conf t
interface fa0/24
 spanning-tree guard root
end
```

🧠 **Qué hace:** Evita que el puerto acepte a un nuevo Root Bridge no autorizado.

---

### 🧯 **Recuperación de puertos bloqueados por BPDU Guard**

```bash
conf t
interface fa0/1
 shutdown
 no shutdown
end
```

**O bien:**

```bash
errdisable recovery cause bpduguard
errdisable recovery interval 30
```

---

### 🧪 **Verificación post-defensa**

```bash
show errdisable recovery
show spanning-tree inconsistentports
show interface status
```

---

## 🧾 **Resumen del ataque y defensa**

| Etapa        | Acción realizada                                            |
| ------------ | ----------------------------------------------------------- |
| Inicio       | Kali se conecta a 2 switches por NICs                       |
| Ataque       | Yersinia simula un switch dual-homed y se autoproclama root |
| Impacto      | Tráfico redirigido al atacante (MITM)                       |
| Mitigación 1 | `bpduguard` bloquea puertos que reciben BPDUs inesperados   |
| Mitigación 2 | `rootguard` evita cambios de root no autorizados            |
| Verificación | `show spanning-tree`, `show errdisable`, `show interface`   |

---
