# 📚 Mini Guía - Herramientas de Red en Kubuntu

## 🚀 **INSTALACIÓN COMPLETA**
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y screen minicom picocom putty wireshark tcpdump nmap net-tools git python3-pip
```

---

## 🔌 **CONEXIÓN CON CABLE DE CONSOLA**

### **1. Picocom (Recomendado - Más simple)**
```bash
# Conectar
sudo picocom -b 9600 /dev/ttyUSB0

# Comandos dentro de picocom:
# Ctrl+A, Ctrl+X → Salir
# Ctrl+A, Ctrl+H → Ayuda
```

### **2. Minicom (Más funciones)**
```bash
# Configurar primera vez
sudo minicom -s
# Configurar: /dev/ttyUSB0, 9600 8N1, Flow Control: No

# Conectar
sudo minicom -D /dev/ttyUSB0

# Comandos dentro de minicom:
# Ctrl+A, X → Salir
# Ctrl+A, Z → Menú de ayuda
```

### **3. Screen (Súper simple)**
```bash
# Conectar
sudo screen /dev/ttyUSB0 9600

# Salir: Ctrl+A, luego K, luego Y
```

### **4. PuTTY (Interfaz gráfica)**
```bash
# Abrir
putty
```
**Configurar:**
- Connection type: Serial
- Serial line: `/dev/ttyUSB0`
- Speed: `9600`
- En Serial: 8 data bits, 1 stop bit, No parity, No flow control

---

## 📡 **HERRAMIENTAS DE ANÁLISIS**

### **Wireshark**
```bash
# Analizar tráfico de red
sudo wireshark

# Capturar de interfaz específica
sudo wireshark -i eth0

# Capturar a archivo
sudo wireshark -k -i eth0 -w captura.pcap
```

### **tcpdump**
```bash
# Capturar todo en eth0
sudo tcpdump -i eth0

# Capturar a archivo
sudo tcpdump -i eth0 -w captura.pcap

# Filtrar por IP
sudo tcpdump -i eth0 host 192.168.1.1

# Ver HTTP traffic
sudo tcpdump -i eth0 port 80
```

### **nmap (Escaneo de red)**
```bash
# Escanear red local
nmap -sP 192.168.1.0/24

# Escanear puertos de un equipo
nmap -sV 192.168.1.1

# Escaneo completo
nmap -A -T4 192.168.1.1
```

---

## 🖥️ **GESTIÓN DE SESIONES CON SCREEN**

### **Comandos esenciales de Screen**
```bash
# Iniciar nueva sesión
screen -S switch_session

# Listar sesiones
screen -ls

# Re-conectar a sesión
screen -r switch_session

# Salir (detach) de sesión actual
Ctrl+A, D

# Crear nueva ventana en misma sesión
Ctrl+A, C

# Cambiar entre ventanas
Ctrl+A, N  # Siguiente
Ctrl+A, P  # Anterior

# Ver todas las ventanas
Ctrl+A, "

# Dividir pantalla horizontal
Ctrl+A, S

# Cambiar entre divisiones
Ctrl+A, Tab

# Cerrar sesión (terminar)
exit
```

### **Uso práctico para switches:**
```bash
# Sesión para múltiples conexiones
screen -S networking

# En cada ventana puedes conectar a diferente equipo:
# Ventana 1: Switch principal
sudo picocom -b 9600 /dev/ttyUSB0

# Ventana 2: Router
sudo minicom -D /dev/ttyUSB1

# Ventana 3: Monitoreo
sudo tcpdump -i eth0
```

---

## 📝 **CAPTURAR SESIONES DE CONSOLA**

### **Con script (captura TODO)**
```bash
# Iniciar captura
script -f captura_switch.log

# Conectar al switch
sudo picocom -b 9600 /dev/ttyUSB0

# Salir: En picocom Ctrl+A, Ctrl+X
# Luego en script: Ctrl+D
```

### **Con tee (ver y capturar)**
```bash
sudo picocom -b 9600 /dev/ttyUSB0 2>&1 | tee captura.log
```

---

## 🐍 **AUTOMATIZACIÓN CON PYTHON**

### **Instalar Netmiko**
```bash
pip3 install netmiko paramiko

# Ejemplo de conexión básica
python3 -c "
from netmiko import ConnectHandler

device = {
    'device_type': 'cisco_ios',
    'host': '192.168.1.1',
    'username': 'admin',
    'password': 'password',
}

connection = ConnectHandler(**device)
output = connection.send_command('show version')
print(output)
connection.disconnect()
"
```

### **Script simple para backup**
```bash
#!/bin/bash
# backup_switch.sh
DATE=$(date +%Y%m%d)
sudo picocom -b 9600 /dev/ttyUSB0 > backup_switch_$DATE.txt
```

---

## 🔧 **COMANDOS ÚTILES DE DIAGNÓSTICO**

### **Ver puertos seriales**
```bash
ls /dev/ttyUSB*
ls /dev/ttyACM*
dmesg | grep tty
```

### **Ver conexiones de red**
```bash
# Interfaces
ip a
ifconfig

# Tabla ARP
arp -a

# Tabla de rutas
route -n
ip route

# Conexiones activas
netstat -tulpn
ss -tulpn
```

---

## 💾 **ALIAS ÚTILES para ~/.bashrc**
```bash
# Conexiones rápidas
alias switch='sudo picocom -b 9600 /dev/ttyUSB0'
alias switch-minicom='sudo minicom -D /dev/ttyUSB0'
alias switch-screen='sudo screen /dev/ttyUSB0 9600'

# Redes
alias myip='hostname -I'
alias scanlan='nmap -sn 192.168.1.0/24'
alias ports='netstat -tulpn'

# Capturas
alias capturar-switch='script -f "switch_$(date +%Y%m%d_%H%M).log" -c "sudo picocom -b 9600 /dev/ttyUSB0"'
```

---

## 🗂️ **ESTRUCTURA DE DIRECTORIOS RECOMENDADA**
```bash
mkdir -p ~/redes/{backups,configs,capturas,scripts,logs}
cd ~/redes

# backups/    → Configuraciones de equipos
# configs/    → Archivos de configuración
# capturas/   → Capturas de tráfico
# scripts/    → Scripts de automatización
# logs/       → Logs de sesiones
```

---

## ⚡ **COMANDOS RÁPIDOS DE EMERGENCIA**

### **Si no funciona el serial:**
```bash
# Ver permisos
ls -l /dev/ttyUSB0

# Dar permisos temporales
sudo chmod 666 /dev/ttyUSB0

# Ver procesos usando el puerto
sudo lsof /dev/ttyUSB0

# Matar procesos
sudo kill -9 <PID>
```

### **Probar diferentes baud rates:**
```bash
for baud in 9600 115200 38400 57600 19200; do
    echo "Probando $baud baudios..."
    timeout 2 sudo picocom -b $baud /dev/ttyUSB0
done
```

---

## 🎯 **FLUJO DE TRABAJO TÍPICO**
```
1. Conectar cable consola a /dev/ttyUSB0
2. Conectar con: sudo picocom -b 9600 /dev/ttyUSB0
3. Presionar Enter varias veces
4. Si necesita login: usuario/contraseña
5. Configurar switch/router
6. Para capturar: usar script o tee
7. Para múltiples equipos: usar screen
8. Para análisis: wireshark o tcpdump
```

---

## 📚 **RECURSOS ADICIONALES**

### **Documentación local:**
```bash
# Manuales
man picocom
man minicom
man screen
man tcpdump
```

### **Páginas de ayuda:**
```bash
# Ayuda interactiva
picocom --help
minicom --help
```

---

**¿Listo para configurar tu primer switch?** ¡Con esta guía tienes todo lo esencial!
