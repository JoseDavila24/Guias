# 1) Preparación en GNS3 (Linux Mint)

## 1.1 Instalar/activar QEMU en GNS3

1. Abre **GNS3 (2.2+)** → `Edit > Preferences > QEMU > Qemu VMs`.
2. Verifica que GNS3 detecta QEMU/KVM (aceleración por hardware).
3. Crea **plantilla QEMU** para:

   * **Ubuntu Server** (ISO oficial).
   * **Debian 13.1.0 amd64 netinst XFCE**:

     * RAM: 2048–3072 MB (clientes: 1536–2048 MB).
     * vCPU: 2.
     * NICs: `virtio-net-pci`.
     * Disco: qcow2 20–30 GB.
     * Adjunta `debian-13.1.0-amd64-netinst.iso` como CD al primer arranque (luego quítalo).
4. Añade **Cloud (NAT)**:

   * En el proyecto, arrastra **Cloud** (`NAT`) para acceso a Internet temporal durante instalaciones.

## 1.2 Crear el proyecto y la topología base

Topología objetivo:

```
[Debian-Cli1]--\
[Debian-Cli2]---(switch2)----(switch1)----[Ubuntu-Server]
[Debian-Cli3]--/                       \
                                     (cloud-NAT)   <-- SOLO en Fase 1
```

* **switch1** y **switch2**: usa “Ethernet switch” de GNS3 (no gestionable, suficiente para L2).
* Conecta:

  * `clientes (3x Debian XFCE)` → **switch2**
  * **switch2** → **switch1**
  * **switch1** → **Ubuntu Server**
* Para **Fase 1**, conecta **switch1** (o el servidor) al **Cloud NAT** para Internet temporal:

  * Opción A (sencilla): Conecta **Ubuntu-Server** directamente al Cloud NAT con una **2ª NIC**.
  * Opción B: Conecta **switch1** al Cloud NAT (todos tendrán salida). Tras la fase, **elimina este enlace**.

> Recomendación: Para alinearnos con la **Fase 2** (puente SSH), usa **Opción A** desde el principio:
>
> * `eth0` = red interna aislada (192.168.100.0/24)
> * `eth1` = interfaz “temporal” (primero a NAT para instalar paquetes; luego a **Cloud de gestión 192.168.56.0/24**)

---

# 2) Fase 1 – Instalación con Internet temporal

## 2.1 Arranque e instalación SO

* **Ubuntu Server**: instala base mínima + `openssh-server`.
* **Debian clientes (XFCE)**: instala XFCE, red por DHCP temporal (NAT), usuario local estándar.

## 2.2 Paquetes (cuando haya Internet)

**Servidor (Ubuntu):**

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y isc-dhcp-server postfix mailutils bind9 net-tools openssh-server dovecot-imapd dovecot-pop3d
```

> He añadido **Dovecot (IMAP/POP3)**: Thunderbird necesita un **servidor de buzones** para “recibir” el correo. Postfix (MTA) + Dovecot (IMAP) = combo clásico. POP3 es opcional; mantendremos **IMAP**.

**Clientes (Debian XFCE):**

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y xfce4 thunderbird wireshark tcpdump net-tools bind9-dnsutils
```

## 2.3 Comprobaciones rápidas

```bash
# En servidor y clientes
ip a
ping -c3 8.8.8.8
```

---

# 3) Fase 2 – Aislamiento + Puente temporal SSH

## 3.1 Desconexión de Internet

* Quita el enlace **Cloud NAT** (o cambia el cable de `eth1` del servidor: de NAT al **Cloud de gestión**).

## 3.2 Red de gestión (puente SSH) 192.168.56.0/24

**En GNS3:**

* Añade un **Cloud** que bridgee con una interfaz del **host Linux Mint** (por ejemplo, un adaptador puente/host-only).
* Conecta **eth1** del **Ubuntu Server** a este Cloud.

**Servidor Ubuntu (eth1 gestión):**

```bash
sudo ip addr add 192.168.56.10/24 dev eth1
sudo ip link set eth1 up
sudo systemctl enable ssh
sudo systemctl start ssh
```

**Netplan persistente (Ubuntu):**

```bash
sudo nano /etc/netplan/01-netcfg.yaml
```

Ejemplo mínimo (ajusta nombres reales de interfaces):

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: no
      addresses: [192.168.100.10/24]
    eth1:
      dhcp4: no
      addresses: [192.168.56.10/24]
```

Aplica:

```bash
sudo netplan apply
```

**Host Linux Mint (interfaz bridge/host-only):**

```bash
# Sustituye <ifc_hostonly> por la interfaz del host conectada al Cloud
sudo ip addr add 192.168.56.1/24 dev <ifc_hostonly>
sudo ip link set <ifc_hostonly> up
```

**Prueba SSH desde el host:**

```bash
ssh <usuario-servidor>@192.168.56.10
```

> Cuando todo esté estable, podrás **desconectar** este puente si quieres aislamiento total, o dejarlo solo para admin.

---

# 4) Fase 3 – Red aislada principal

* **Subred interna**: `192.168.100.0/24`
* **Servidor Ubuntu (eth0)**: `192.168.100.10/24`
* **Clientes**: por **DHCP** `192.168.100.100–150`

**Servidor (IP fija en eth0 ya definida en Netplan):**

```bash
ip a show eth0
```

**Clientes (Debian):**

* Configura **DHCP** en su única NIC (por defecto suele venir así).
* Si no, edita `/etc/network/interfaces` (legacy) o usa NetworkManager para “**Automático (DHCP)**”.

---

# 5) Servicios en el servidor (Ubuntu)

## 5.1 DHCP – `isc-dhcp-server`

**/etc/dhcp/dhcpd.conf**

```
authoritative;
option domain-name "jmrd.local";
option domain-name-servers 192.168.100.10;
option subnet-mask 255.255.255.0;
option routers 192.168.100.10;

subnet 192.168.100.0 netmask 255.255.255.0 {
    range 192.168.100.100 192.168.100.150;
    option broadcast-address 192.168.100.255;
    default-lease-time 600;
    max-lease-time 7200;
}
```

**Associar a la interfaz interna:**

```bash
sudo sed -i 's/INTERFACESv4=.*/INTERFACESv4="eth0"/' /etc/default/isc-dhcp-server
sudo systemctl enable isc-dhcp-server
sudo systemctl restart isc-dhcp-server
sudo systemctl status isc-dhcp-server --no-pager
```

## 5.2 DNS – Bind9 (zona jmrd.local)

**/etc/bind/named.conf.options** (habilita consultas internas, sin reenviadores):

```bash
options {
    directory "/var/cache/bind";
    recursion yes;
    allow-recursion { 192.168.100.0/24; localhost; };
    listen-on { 192.168.100.10; 127.0.0.1; };
    listen-on-v6 { none; };
    dnssec-validation no;
};
```

**/etc/bind/named.conf.local**

```bash
zone "jmrd.local" {
    type master;
    file "/etc/bind/db.jmrd.local";
};

zone "100.168.192.in-addr.arpa" {
    type master;
    file "/etc/bind/db.192.168.100";
};
```

**Archivo de zona directa – `/etc/bind/db.jmrd.local`**

```
$TTL    86400
@       IN      SOA     server.jmrd.local. admin.jmrd.local. (
                        2025103101 ; Serial
                        3600       ; Refresh
                        1800       ; Retry
                        604800     ; Expire
                        86400 )    ; Negative Cache TTL
;
@       IN      NS      server.jmrd.local.
server  IN      A       192.168.100.10
cli1    IN      A       192.168.100.101
cli2    IN      A       192.168.100.102
cli3    IN      A       192.168.100.103
; Alias de servicios
imap    IN      CNAME   server
smtp    IN      CNAME   server
```

**Archivo de zona inversa – `/etc/bind/db.192.168.100`**

```
$TTL    86400
@       IN      SOA     server.jmrd.local. admin.jmrd.local. (
                        2025103101
                        3600
                        1800
                        604800
                        86400 )
@       IN      NS      server.jmrd.local.
10      IN      PTR     server.jmrd.local.
101     IN      PTR     cli1.jmrd.local.
102     IN      PTR     cli2.jmrd.local.
103     IN      PTR     cli3.jmrd.local.
```

**Recarga Bind:**

```bash
sudo named-checkconf
sudo named-checkzone jmrd.local /etc/bind/db.jmrd.local
sudo named-checkzone 100.168.192.in-addr.arpa /etc/bind/db.192.168.100
sudo systemctl enable bind9
sudo systemctl restart bind9
```

## 5.3 Postfix (solo LAN, “pasivo”)

**/etc/postfix/main.cf** (fragmento clave)

```
myhostname = server.jmrd.local
mydomain = jmrd.local
inet_interfaces = 192.168.100.10, localhost
mynetworks = 127.0.0.0/8, 192.168.100.0/24
mydestination = $myhostname, localhost.$mydomain, localhost, $mydomain
compatibility_level = 3.6
# Evitar relay fuera (no hay salida a Internet y no hacemos smarthost)
relayhost =
```

**Asegura que solo escucha en la interfaz interna** (ya definido por `inet_interfaces`).

```bash
sudo postconf -n
sudo systemctl enable postfix
sudo systemctl restart postfix
```

## 5.4 Dovecot (IMAP para clientes)

**/etc/dovecot/dovecot.conf**

```
listen = 192.168.100.10, 127.0.0.1
```

**/etc/dovecot/conf.d/10-mail.conf**

```
mail_location = mbox:~/mail:INBOX=/var/mail/%u
```

*(o usa Maildir si prefieres: `mail_location = maildir:~/Maildir`)*

**/etc/dovecot/conf.d/10-auth.conf**

```
disable_plaintext_auth = no
auth_mechanisms = plain login
```

**/etc/dovecot/conf.d/10-ssl.conf** (opcional en lab aislado; sin SSL para simplificar pruebas)

```
ssl = no
```

**Activar:**

```bash
sudo systemctl enable dovecot
sudo systemctl restart dovecot
sudo ss -ltnp | egrep ':(25|143)\s'
```

> Usuarios locales del sistema = buzones. Crea usuarios para pruebas:

```bash
sudo adduser alice
sudo adduser bob
echo 'Prueba Dovecot+Postfix' | sudo tee /etc/motd
```

---

# 6) Clientes (Debian XFCE)

## 6.1 Red por DHCP

* Asegúrate que la NIC esté en **DHCP**. Comprueba:

```bash
ip a
ip r
cat /etc/resolv.conf
```

Deberías ver:

* IP en `192.168.100.100–150`
* `nameserver 192.168.100.10`
* `search jmrd.local`

## 6.2 Thunderbird

* **Servidor IMAP**: `server.jmrd.local` (o `imap.jmrd.local`)
* **Puerto**: 143 (SIN TLS en este lab)
* **Usuario/Contraseña**: cuenta local creada (p. ej. `alice`)
* **SMTP**: `server.jmrd.local` puerto 25, autent. desactivada (LAN confiable), **solo dominio local**.

---

# 7) Verificación y pruebas

## 7.1 Scripts útiles (en el servidor)

**check_net.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail
echo "[*] Interfaces:"
ip -brief a
echo "[*] Ping clientes (si ya tienen IP):"
for ip in 192.168.100.101 192.168.100.102 192.168.100.103; do
  ping -c2 -W1 "$ip" || true
done
```

**check_dhcp.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail
echo "[*] Leases DHCP recientes:"
sudo tail -n 50 /var/lib/dhcp/dhcpd.leases
sudo systemctl status isc-dhcp-server --no-pager
```

**check_dns.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail
dig @192.168.100.10 server.jmrd.local A +short
dig @192.168.100.10 cli1.jmrd.local A +short
dig @192.168.100.10 -x 192.168.100.10 +short
```

**mail_loopback.sh** (prueba local de correo)

```bash
#!/usr/bin/env bash
set -euo pipefail
echo "Hola Bob, prueba interna" | mail -s "Test local" bob@jmrd.local
sleep 2
sudo ls -l /var/mail/bob || true
```

**check_mail_ports.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail
ss -ltnp | egrep ':(25|143)\s' || true
systemctl --no-pager status postfix dovecot
```

Dales permisos:

```bash
chmod +x *.sh
```

## 7.2 Flujo de prueba end-to-end

1. En **clientes**, confirma IP y DNS:

   ```bash
   ip a; ip r; dig server.jmrd.local A +short
   ```
2. Crea usuarios en el **servidor** (`alice`, `bob`).
3. Desde **alice** (cliente/Thunderbird), envía a **[bob@jmrd.local](mailto:bob@jmrd.local)**.
4. Verifica recepción en **Thunderbird** de **bob** (IMAP).
5. Prueba **DNS inverso** desde clientes:

   ```bash
   dig -x 192.168.100.10 +short
   ```
6. **Ping** entre nodos:

   ```bash
   ping -c3 server.jmrd.local
   ping -c3 cli2.jmrd.local
   ```

---

# 8) Procedimiento: Internet → Aislamiento → Puente SSH (resumen exacto)

1. **Instalación (con NAT)**

   * Conecta **eth1** del servidor al `Cloud NAT`.
   * Instala paquetes (sección 2.2).

2. **Corte de Internet**

   * Desconecta `eth1` del `Cloud NAT`.

3. **Puente SSH temporal**

   * Conecta `eth1` al **Cloud de gestión** (bridged/host-only).
   * Asigna:

     * Servidor: `192.168.56.10/24` (Netplan + comandos ya dados)
     * Host Mint: `192.168.56.1/24` en su interfaz bridge
   * Verifica:

     ```bash
     ssh <usuario>@192.168.56.10
     ```

4. **(Opcional) Retirar puente** cuando acabes:

   * Quita el cable de `eth1` o baja la interfaz:

     ```bash
     sudo ip link set eth1 down
     ```
   * Mantenerlo es válido si solo es para administración.

---

# 9) Diagramas por fase

**Fase 1 (instalación):**

```
[Cli1][Cli2][Cli3] -- switch2 -- switch1 -- [Ubuntu-Server:eth0]
                                     \
                                      \-- [Ubuntu-Server:eth1] -- (Cloud NAT)
```

**Fase 2 (aislada + gestión SSH):**

```
[Cli1][Cli2][Cli3] -- switch2 -- switch1 -- [Ubuntu-Server:eth0 192.168.100.10]
                                             [Ubuntu-Server:eth1 192.168.56.10] -- (Cloud gestión) -- [Host Mint 192.168.56.1]
```

**Fase 3 (operación normal):**

```
[Cli1 DHCP][Cli2 DHCP][Cli3 DHCP] -- switch2 -- switch1 -- [Ubuntu-Server 192.168.100.10]
```

---

# 10) Endurecimiento y contención (recomendado para tu “correo pasivo”)

* **Cortafuegos (servidor)**: sólo puertos LAN necesarios.

```bash
sudo apt install -y ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow in on eth0 to any port 25 proto tcp
sudo ufw allow in on eth0 to any port 143 proto tcp
sudo ufw allow in on lo
# (solo si dejas gestión) sudo ufw allow in on eth1 to any port 22 proto tcp
sudo ufw enable
sudo ufw status verbose
```

* **Postfix**: ya limitado a `inet_interfaces = 192.168.100.10, localhost`.
* **Bind9**: recursion solo para la LAN; sin reenvío a Internet.
* **DHCP**: atado a `eth0`.
* **Logs**: revisa `/var/log/syslog`, `/var/log/mail.log`, `/var/log/dovecot*`.

---

## Parámetros de cuenta Thunderbird (resumen para fichas de configuración)

* **Correo entrante (IMAP)**

  * Servidor: `server.jmrd.local`
  * Puerto: `143` (sin SSL en el lab)
  * Autenticación: usuario del sistema (p. ej. `alice`)
* **Correo saliente (SMTP)**

  * Servidor: `server.jmrd.local`
  * Puerto: `25`
  * Autenticación: no (LAN confiable) / o “igual que entrante” si lo prefieres
