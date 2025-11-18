# Guía Completa: Instalación de GNS3 con QEMU en Linux Mint

## 1. Preparación del Sistema

### Actualización del sistema
```bash
sudo apt update && sudo apt upgrade -y
```

### Instalación de paquetes requeridos
```bash
sudo apt install -y gns3-gui gns3-server qemu-kvm qemu-utils virt-manager \
bridge-utils xterm wireshark libvirt-daemon-system libvirt-clients
```

### Configuración de permisos de usuario
```bash
sudo usermod -aG kvm,libvirt,ubridge,wireshark,dialout $USER
```

**Importante**: Cierra sesión y vuelve a entrar o reinicia el sistema para aplicar los cambios de grupos.

## 2. Verificación de la instalación

### Comprobar virtualización
```bash
egrep -c '(vmx|svm)' /proc/cpuinfo
# Debe devolver un número mayor a 0
```

### Verificar KVM
```bash
kvm-ok
# Debe mostrar: "KVM acceleration can be used"
```

### Verificar grupos de usuario
```bash
groups
# Debe incluir: kvm, libvirt, ubridge, wireshark
```

## 3. Configuración inicial de GNS3

### Primera ejecución
```bash
gns3
```

Durante la configuración inicial:

1. **Tipo de servidor**: Selecciona "Local server"
2. **Configuración de QEMU**: Acepta la configuración por defecto
3. **Configuración de VPCS**: Acepta la configuración por defecto
4. **Configuración de Docker**: Puedes omitirla por ahora
5. **Configuración de ubridge**: Acepta la configuración por defecto

## 4. Preparación de imágenes QEMU

### Crear directorio para imágenes
```bash
mkdir -p ~/GNS3/images/QEMU
cd ~/GNS3/images/QEMU
```

### Descargar imágenes (ejemplos)
```bash
# Ubuntu Server (ejemplo)
wget https://releases.ubuntu.com/22.04/ubuntu-22.04.4-live-server-amd64.iso

# TinyCore Linux
wget http://tinycorelinux.net/13.x/x86_64/release/CorePlus-13.0.iso
```

## 5. Configuración de máquinas QEMU en GNS3

### Para Ubuntu Server

1. **Abrir GNS3** → **Edit** → **Preferences** → **QEMU** → **QEMU VMs**
2. **Click en New** y selecciona tu imagen ISO
3. **Configuración recomendada**:
   - **Name**: "Ubuntu Server Template"
   - **RAM**: 2048 MB
   - **Disk interface**: virtio
   - **Console type**: vnc
   - **KVM**: Habilitado

### Para TinyCore Linux

1. **Mismo procedimiento** pero con la imagen CorePlus
2. **Configuración recomendada**:
   - **Name**: "TinyCore GUI"
   - **RAM**: 1024 MB
   - **Disk interface**: virtio
   - **Console type**: vnc
   - **KVM**: Habilitado

## 6. Creación de un laboratorio básico

### Topología de ejemplo:
```
[PC GNS3] --- [Cloud] --- [Router Ubuntu] --- [TinyCore Workstation]
```

### Pasos en GNS3:

1. **Arrastra los dispositivos** desde el panel izquierdo
2. **Conecta los dispositivos** con cables Ethernet
3. **Configura las interfaces** de red según sea necesario

## 7. Configuración de redes

### Crear bridge manual (opcional)
```bash
# Crear bridge
sudo brctl addbr gns3bridge
sudo ip addr add 192.168.100.1/24 dev gns3bridge
sudo ip link set gns3bridge up

# Verificar
brctl show
```

### En GNS3 usar "Cloud" para conectar a redes físicas:
1. Arrastra "Cloud" al workspace
2. Configura las interfaces de red según necesites

## 8. Comandos útiles de QEMU

### Crear disco duro virtual
```bash
qemu-img create -f qcow2 disk.qcow2 10G
```

### Ejecutar VM manualmente (para testing)
```bash
qemu-system-x86_64 -enable-kvm -m 2048 -hda disk.qcow2 -cdrom ubuntu-22.04.4-live-server-amd64.iso -boot d -net nic -net user
```

## 9. Solución de problemas comunes

### Error de permisos con KVM:
```bash
sudo chmod 666 /dev/kvm
# O mejor: verificar que el usuario esté en grupo kvm
```

### Error de libvirt:
```bash
sudo systemctl enable libvirtd
sudo systemctl start libvirtd
```

### Wireshark sin permisos:
```bash
sudo dpkg-reconfigure wireshark-common
# Seleccionar "Yes" para permitir a usuarios no-root capturar paquetes
```

## 10. Optimizaciones

### Aumentar límites del sistema:
```bash
# Editar límites del sistema
sudo nano /etc/security/limits.conf
# Añadir al final:
* soft nofile 65536
* hard nofile 65536
```

### Configurar swap (si trabajas con muchas VMs):
```bash
sudo swapoff -a
sudo dd if=/dev/zero of=/swapfile bs=1G count=8
sudo mkswap /swapfile
sudo swapon /swapfile
```

## 11. Script de instalación automática

Crea un script `install_gns3_qemu.sh`:
```bash
#!/bin/bash
echo "Instalando GNS3 con QEMU..."
sudo apt update
sudo apt install -y gns3-gui gns3-server qemu-kvm qemu-utils virt-manager bridge-utils xterm wireshark libvirt-daemon-system libvirt-clients

sudo usermod -aG kvm,libvirt,ubridge,wireshark,dialout $USER

echo "Instalación completada. Por favor, reinicia tu sesión."
```

Hacer ejecutable y ejecutar:
```bash
chmod +x install_gns3_qemu.sh
./install_gns3_qemu.sh
```

## 12. Próximos pasos

1. **Practicar** con topologías simples
2. **Explorar** dispositivos preconfigurados en el mercado de GNS3
3. **Integrar** con Docker para contenedores ligeros
4. **Configurar** captura de paquetes con Wireshark
5. **Experimentar** con diferentes sistemas operativos

Esta guía te proporciona una base sólida para trabajar con GNS3 y QEMU en Linux Mint. ¡Comienza con topologías simples y ve incrementando la complejidad gradualmente!
