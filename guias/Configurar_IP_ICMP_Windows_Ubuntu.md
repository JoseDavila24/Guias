## **Configurar IP estática y permitir ICMP en Windows**

### **1. Cambiar IP en Windows**

**Método rápido (recomendado para la práctica):**
```
1. Abre "Panel de Control" → "Centro de redes y recursos compartidos"
2. Clic en "Cambiar configuración del adaptador"
3. Clic derecho en "Ethernet" → "Propiedades"
4. Selecciona "Protocolo de Internet versión 4 (TCP/IPv4)" → "Propiedades"
5. Selecciona "Usar la siguiente dirección IP":
   - Dirección IP: 192.168.20.4
   - Máscara de subred: 255.255.255.0
   - Puerta de enlace: (déjalo vacío, no hay router)
6. Selecciona "Usar las siguientes direcciones de servidor DNS":
   - DNS preferido: 8.8.8.8 (opcional)
7. Clic en "Aceptar" en todas las ventanas
```

**Método alternativo (Configuración de Windows):**
```
1. Presiona Windows + I → "Red e Internet"
2. "Configuración de red avanzada" → "Más opciones de adaptador de red"
3. Sigue los pasos anteriores desde el paso 3
```

### **2. Permitir respuestas ICMP (ping) en Windows**

**Método rápido (recomendado):**
```
1. Presiona Windows + R, escribe: wf.msc y presiona Enter
2. En la ventana "Firewall de Windows con seguridad avanzada":
   - Clic en "Reglas de entrada" (menú izquierdo)
   - Busca las reglas que contienen "Compartir archivos e impresoras"
   - Localiza "Compartir archivos e impresoras (Solicitud de eco ICMPv4 - Entrada)"
   - Haz clic derecho sobre ella → "Habilitar regla"
```

**Método detallado (crear regla personalizada) :**
```
1. Windows + R → wf.msc → Enter
2. Clic derecho en "Reglas de entrada" → "Nueva regla"
3. Selecciona:
   - "Personalizada" → Siguiente
   - "Todos los programas" → Siguiente
   - Tipo de protocolo: ICMPv4 → "Personalizar" → "Solicitud de eco" → Aceptar → Siguiente
   - "Cualquier dirección IP" (origen y destino) → Siguiente
   - "Permitir la conexión" → Siguiente
   - Marca los perfiles: Dominio, Privado, Público → Siguiente
   - Nombre: "Permitir Ping" → Finalizar
```

---

## **Configurar IP estática y permitir ICMP en Ubuntu**

### **1. Ver interfaces de red disponibles**

```bash
# Ver todas las interfaces
ip a
# O alternativamente
ifconfig
```
Identifica el nombre de tu interfaz (ej: enp0s3, ens33, eth0)

### **2. Cambiar IP en Ubuntu (Netplan) **

```bash
# Ver archivos de configuración netplan
ls /etc/netplan/

# Editar el archivo de configuración (el nombre puede variar)
sudo nano /etc/netplan/01-network-manager-all.yaml
# o
sudo nano /etc/netplan/50-cloud-init.yaml
```

**Configuración para IP estática:**
```yaml
network:
  version: 2
  ethernets:
    enp0s3:  # CAMBIA ESTO por tu interfaz
      dhcp4: no
      addresses:
        - 192.168.20.3/24
      gateway4:  # déjalo vacío, no hay router
      nameservers:
        addresses: [8.8.8.8, 1.1.1.1]
```

**Nota importante:** Usa espacios, NO tabulaciones. La indentación es crucial en YAML.

**Aplicar cambios:**
```bash
# Verificar la configuración antes de aplicar
sudo netplan try

# Si todo está bien, aplicar
sudo netplan apply

# Verificar nueva IP
ip a
```

### **3. Permitir respuestas ICMP en Ubuntu**

**Opción 1: Verificar/configurar kernel (recomendado)** :
```bash
# Verificar estado actual (0 = habilitado, 1 = bloqueado)
cat /proc/sys/net/ipv4/icmp_echo_ignore_all

# Si muestra "1", habilitar temporalmente:
sudo sysctl -w net.ipv4.icmp_echo_ignore_all=0
# O directamente:
echo 0 | sudo tee /proc/sys/net/ipv4/icmp_echo_ignore_all
```

**Opción 2: Configuración permanente (si es necesario):**
```bash
# Editar archivo sysctl
sudo nano /etc/sysctl.conf

# Agregar o modificar esta línea:
net.ipv4.icmp_echo_ignore_all = 0

# Aplicar cambios
sudo sysctl -p
```

**Opción 3: Verificar UFW (firewall):**
```bash
# Verificar estado del firewall
sudo ufw status

# Si está activo, permitir ICMP
sudo ufw allow out proto icmp
sudo ufw allow in proto icmp

# O deshabilitar temporalmente para pruebas
sudo ufw disable
```

---

## **Pruebas de conectividad**

### **Desde Ubuntu:**
```bash
# Ping a Windows
ping 192.168.20.4

# Ping continuo (detener con Ctrl+C)
ping -c 5 192.168.20.4  # 5 pings solamente
```

### **Desde Windows (CMD o PowerShell):**
```cmd
ping 192.168.20.3
ping -n 5 192.168.20.3  :: 5 pings solamente
```

### **Verificación desde switches:**
```bash
# Desde S1 hacia PC-A (Ubuntu)
S1# ping 192.168.20.3

# Desde S2 hacia PC-B (Windows)
S2# ping 192.168.20.4

# Ping entre switches (management)
S1# ping 192.168.10.12
S2# ping 192.168.10.11
```

## **Solución de problemas comunes**

| Problema | Posible solución |
|---------|------------------|
| Windows no responde ping | Verificar que la regla ICMP esté **habilitada** no solo creada |
| Ubuntu no responde ping | Verificar `icmp_echo_ignore_all` y UFW |
| IP no cambia en Ubuntu | Verificar sintaxis YAML (espacios, no tabs) y reiniciar netplan |
| "Permission denied" | Usar `sudo` antes de los comandos |
| Firewall bloquea | Temporalmente deshabilitar para pruebas: Ubuntu: `sudo ufw disable`; Windows: deshabilitar Firewall temporalmente |
