🎯 **SCRIPT CON BANNER PARA MENSAJES PASIVOS**

```bash
cat > /usr/local/bin/enviar_aviso << 'EOF'
#!/bin/sh

# Banner colorizado
BANNER="
╔══════════════════════════════════════════════╗
║             🎯 SISTEMA DE AVISOS             ║
║              📧 jmrd.com - RRHH              ║
╚══════════════════════════════════════════════╝
"

# Mensajes predefinidos
MENSAJE_REUNION="Reunión de equipo programada para mañana a las 10:00 AM en sala de conferencias."
MENSAJE_NOMINAS="Recordatorio: Nóminas deben ser procesadas antes del viernes a las 5:00 PM."
MENSAJE_MANTENIMIENTO="Mantenimiento del sistema: El servidor se reiniciará hoy a las 18:00 horas."
MENSAJE_URGENTE="⚠️  AVISO URGENTE: Revisar correo para información importante."
MENSAJE_BIENVENIDA="¡Bienvenida al sistema! Tu cuenta de correo está activa y funcionando."
MENSAJE_CAPACITACION="Capacitación programada: Curso de seguridad informática el próximo miércoles."
MENSAJE_FELICITACION="¡Felicitaciones! Gracias por tu excelente trabajo este trimestre."

mostrar_menu() {
    clear
    echo "$BANNER"
    echo "📋 MENÚ DE AVISOS RÁPIDOS:"
    echo ""
    echo "1) 📅 Reunión de equipo"
    echo "2) 💰 Recordatorio nóminas" 
    echo "3) 🔧 Aviso mantenimiento"
    echo "4) ⚠️  Aviso urgente"
    echo "5) 👋 Mensaje bienvenida"
    echo "6) 🎓 Aviso capacitación"
    echo "7) 🏆 Mensaje felicitación"
    echo "8) ✏️  Mensaje personalizado"
    echo "9) 📊 Estado del sistema"
    echo "0) 🚪 Salir"
    echo ""
    echo -n "Selecciona una opción [0-9]: "
}

enviar_mensaje() {
    local destino=$1
    local asunto=$2
    local mensaje=$3
    
    echo "$mensaje" | mail -s "$asunto" "$destino"
    echo "✅ Aviso enviado a: $destino"
}

estado_sistema() {
    echo ""
    echo "📊 ESTADO DEL SISTEMA:"
    echo "----------------------"
    echo "📧 Correos en buzón Brenda: $(find /home/brenda/Maildir -name '*' -type f 2>/dev/null | wc -l)"
    echo "📧 Correos en buzón Wendy: $(find /home/wendy/Maildir -name '*' -type f 2>/dev/null | wc -l)"
    echo "🔄 Servicio Postfix: $(service postfix status 2>/dev/null | grep -q 'running' && echo '✅ ACTIVO' || echo '❌ INACTIVO')"
    echo "📨 Servicio Dovecot: $(service dovecot status 2>/dev/null | grep -q 'running' && echo '✅ ACTIVO' || echo '❌ INACTIVO')"
    echo ""
}

# Main script
while true; do
    mostrar_menu
    read opcion
    
    case $opcion in
        1)
            enviar_mensaje "rrhh" "📅 Reunión de Equipo" "$MENSAJE_REUNION"
            ;;
        2)
            enviar_mensaje "nominas" "💰 Recordatorio Nóminas" "$MENSAJE_NOMINAS"
            ;;
        3)
            enviar_mensaje "todos" "🔧 Mantenimiento del Sistema" "$MENSAJE_MANTENIMIENTO"
            ;;
        4)
            enviar_mensaje "rrhh" "⚠️  AVISO URGENTE" "$MENSAJE_URGENTE"
            ;;
        5)
            enviar_mensaje "brenda" "👋 Bienvenida al Sistema" "$MENSAJE_BIENVENIDA"
            enviar_mensaje "wendy" "👋 Bienvenida al Sistema" "$MENSAJE_BIENVENIDA"
            ;;
        6)
            enviar_mensaje "recursoshumanos" "🎓 Capacitación Programada" "$MENSAJE_CAPACITACION"
            ;;
        7)
            enviar_mensaje "rrhh" "🏆 Felicitaciones" "$MENSAJE_FELICITACION"
            ;;
        8)
            echo ""
            echo -n "Destino (brenda/wendy/rrhh/nominas/todos): "
            read destino_custom
            echo -n "Asunto: "
            read asunto_custom
            echo -n "Mensaje: "
            read mensaje_custom
            enviar_mensaje "$destino_custom" "$asunto_custom" "$mensaje_custom"
            ;;
        9)
            estado_sistema
            ;;
        0)
            echo ""
            echo "👋 ¡Hasta pronto!"
            echo ""
            exit 0
            ;;
        *)
            echo ""
            echo "❌ Opción inválida. Presiona Enter para continuar..."
            read
            ;;
    esac
    
    echo ""
    echo "Presiona Enter para continuar..."
    read
done
EOF

# Hacer ejecutable
chmod +x /usr/local/bin/enviar_aviso

# Crear alias para fácil acceso
echo "alias avisos='enviar_aviso'" >> /root/.cshrc
```

## 🚀 **SCRIPT RÁPIDO PARA AVISOS DIRECTOS:**

```bash
cat > /usr/local/bin/aviso_rapido << 'EOF'
#!/bin/sh

# Script rápido para avisos desde línea de comandos
case "$1" in
    "reunion")
        echo "Reunión programada" | mail -s "📅 Reunión Equipo" rrhh
        echo "✅ Aviso de reunión enviado"
        ;;
    "nominas")
        echo "Procesar nóminas antes del viernes" | mail -s "💰 Nóminas Pendientes" nominas
        echo "✅ Recordatorio nóminas enviado"
        ;;
    "mantenimiento")
        echo "Mantenimiento programado para hoy 18:00" | mail -s "🔧 Mantenimiento Sistema" todos
        echo "✅ Aviso mantenimiento enviado"
        ;;
    "urgente")
        echo "Revisar información urgente en correo" | mail -s "⚠️ URGENTE" rrhh
        echo "✅ Aviso urgente enviado"
        ;;
    "estado")
        echo "Sistema operativo al $(date)" | mail -s "📊 Estado Sistema" rrhh
        echo "✅ Estado del sistema enviado"
        ;;
    *)
        echo "Uso: aviso_rapido [reunion|nominas|mantenimiento|urgente|estado]"
        echo "Ejemplo: aviso_rapido reunion"
        ;;
esac
EOF

chmod +x /usr/local/bin/aviso_rapido
```

## 📋 **USO DE LOS SCRIPTS:**

### **Script interactivo con banner:**
```bash
enviar_aviso
```

### **Script rápido desde terminal:**
```bash
aviso_rapido reunion
aviso_rapido nominas  
aviso_rapido mantenimiento
aviso_rapido urgente
aviso_rapido estado
```

## 🎯 **DESTINOS DISPONIBLES:**
- `brenda` - Solo Brenda
- `wendy` - Solo Wendy  
- `rrhh` - Ambas usuarias
- `nominas` - Ambas usuarias
- `recursoshumanos` - Ambas usuarias
- `todos` - Ambas usuarias
- `contrataciones` - Ambas usuarias

## ✅ **INSTALACIÓN COMPLETA:**

```bash
# Recargar alias
source /root/.cshrc

# Probar el script
enviar_aviso
```

**¡El sistema de avisos pasivos está listo!** 🚀 Los usuarios recibirán mensajes automáticamente en sus clientes de correo (Sylpheed).
