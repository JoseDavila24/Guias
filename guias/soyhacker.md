## 🔥 **HERRAMIENTAS PARA ATAQUE DHCP ROGUE**

### **HERRAMIENTAS OFENSIVAS:**
1. **Yersinia** - Rey de ataques DHCP (más potente)
2. **dnsmasq** - Todo-en-uno (DHCP + DNS spoofing) 
3. **isc-dhcp-server** - Servidor DHCP profesional
4. **Scapy (Python)** - Ataques personalizados
5. **dhcpig** - Específico para rogue DHCP

### **ESTRATEGIA DE ATAQUE COMBINADO:**
1. **DHCP Starvation** - Consumir IPs del servidor legítimo
2. **DHCP Flood** - Saturar con respuestas falsas  
3. **Rogue DHCP Server** - Ofrecer servicio "mejor"
4. **DNS Spoofing** - Redirigir tráfico a sitios maliciosos
5. **ARP Poisoning** - Como respaldo si DHCP falla

### **FLUJO DE ATAQUE:**
```
Cliente pide IP → Nuestro Rogue responde más rápido → Cliente recibe:
- IP de nuestro pool
- Gateway malicioso (nuestra IP)
- DNS malicioso (nuestra IP)
- Todo el tráfico pasa por nosotros
```

---

## 🛡️ **MITIGACIONES EN SWITCHES**

### **EN SWITCH CISCO:**
```bash
# DHCP Snooping - Bloquea servidores DHCP no autorizados
Switch(config)# ip dhcp snooping
Switch(config)# ip dhcp snooping vlan 1
Switch(config)# interface range fastethernet 0/1-24
Switch(config-if)# ip dhcp snooping trust
# Solo marcar como trust el puerto del servidor DHCP legítimo
```

### **EN VYOS (Tu switch actual):**
```bash
# Configurar DHCP Guard
set service dhcp-server global-parameters "authoritative;"
set service dhcp-server shared-network-name LAN subnet 192.168.100.0/24 static-mapping CLIENT1 ip-address 192.168.100.101
set service dhcp-server shared-network-name LAN subnet 192.168.100.0/24 static-mapping CLIENT1 mac-address '00:11:22:33:44:55'

# Opcional: Configurar DHCPv6 Guard
set service dhcpv6-server guard
```

### **MITIGACIONES ADICIONALES:**
- **Port Security** - Limitar direcciones MAC por puerto
- **DAI (Dynamic ARP Inspection)** - Previene ARP spoofing
- **IP Source Guard** - Filtra tráfico basado en DHCP binding
- **VLANs** - Aislar redes críticas
- **802.1X** - Autenticación de dispositivos

---

## 🎯 **RECOMENDACIÓN FINAL:**

**Para tu demostración usa:**
1. **Yersinia** para el ataque DHCP principal
2. **dnsmasq** como servidor rogue persistente  
3. **Ettercap** como respaldo para ARP poisoning

**Mitigación a mostrar:**
- **Cisco**: DHCP Snooping
- **VyOS**: DHCP Guard + asignaciones estáticas

**Esta combinación es:** 
- ✅ **Muy efectiva** para robar clientes
- ✅ **Fácil de demostrar** 
- ✅ **Tiene mitigaciones claras** para mostrar
- ✅ **Muestra el riesgo real** de redes no protegidas

¿Quieres que procedamos con la implementación de esta estrategia?
