# Guía de Uso: Sistema de Mensajes JMRD.lab

## 📋 Descripción
Script simple para enviar mensajes de alerta y notificaciones dentro del laboratorio JMRD.lab

## 🚀 Instalación Rápida

### 1. Crear el script
```bash
nano mensajes.sh
```

### 2. Pegar este contenido:
```bash
#!/bin/bash

while true; do
    clear
    echo "╔══════════════════════════════╗"
    echo "║       ENVIAR MENSAJES        ║"
    echo "║         JMRD.lab             ║"
    echo "╚══════════════════════════════╝"
    echo ""
    echo "¿A QUIÉN QUIERES MENSAJEAR?"
    echo "1) 📧 Grupo Sistemas"
    echo "2) 👤 Alma"
    echo "3) 👤 Carlos" 
    echo "4) 👤 Admin"
    echo "5) ❌ Salir"
    echo ""
    read -p "Elige opción: " opcion

    case $opcion in
        1) destino="sistemas@JMRD.lab" ; nombre="Grupo Sistemas" ;;
        2) destino="alma@JMRD.lab" ; nombre="Alma" ;;
        3) destino="carlos@JMRD.lab" ; nombre="Carlos" ;;
        4) destino="admin@JMRD.lab" ; nombre="Admin" ;;
        5) echo "¡Hasta luego!"; exit 0 ;;
        *) echo "Opción inválida"; sleep 2; continue ;;
    esac

    clear
    echo "Destino: $nombre"
    echo ""
    echo "¿QUÉ TIPO DE MENSAJE?"
    echo "1) 🚨 Servidor web caído"
    echo "2) 🚨 Base de datos lenta"
    echo "3) 🚨 Disco lleno"
    echo "4) ✅ Backup exitoso"
    echo "5) 🔧 Mantenimiento"
    echo "6) 💬 Mensaje personalizado"
    echo ""
    read -p "Elige opción: " mensaje_opcion

    case $mensaje_opcion in
        1)
            asunto="🚨 ALERTA: Servidor web caído"
            mensaje="El servidor Apache no responde. Por favor llamar a Carlos para reiniciar. ID: $(whoami) - Hora: $(date)"
            ;;
        2)
            asunto="🚨 ALERTA: Base de datos lenta" 
            mensaje="MySQL está muy lento. Llamar a Alma para revisar. ID: $(whoami) - Hora: $(date)"
            ;;
        3)
            asunto="🚨 ALERTA: Disco lleno"
            mensaje="Solo queda 1% de espacio. Llamar a Admin para limpiar. ID: $(whoami) - Hora: $(date)"
            ;;
        4)
            asunto="✅ BACKUP: Exitoso"
            mensaje="Backup completado correctamente. ID: $(whoami) - Hora: $(date)"
            ;;
        5)
            asunto="🔧 MANTENIMIENTO: Programado"
            mensaje="Necesita actualización de seguridad. ID: $(whoami) - Hora: $(date)"
            ;;
        6)
            echo ""
            read -p "Asunto: " asunto
            echo "Mensaje: "
            read mensaje
            mensaje="$mensaje - ID: $(whoami) - Hora: $(date)"
            ;;
        *)
            echo "Opción inválida"
            sleep 2
            continue
            ;;
    esac

    # Enviar mensaje
    echo "$mensaje" | mail -s "$asunto" "$destino"
    echo ""
    echo "✅ Mensaje enviado a: $nombre"
    echo ""
    read -p "Presiona Enter para continuar..."
done
```

### 3. Hacer ejecutable
```bash
chmod +x mensajes.sh
```

## 🎯 Cómo Usar

### Ejecutar el script:
```bash
./mensajes.sh
```

### Pasos de uso:
1. **Elegir destinatario** (opciones 1-4)
2. **Seleccionar tipo de mensaje** (opciones 1-6)  
3. **El mensaje se envía automáticamente**

### Destinatarios disponibles:
- 📧 **Grupo Sistemas** - Alma y Carlos
- 👤 **Alma** - Mensaje individual
- 👤 **Carlos** - Mensaje individual
- 👤 **Admin** - Mensaje al administrador

### Tipos de mensaje:
- 🚨 **Alertas** - Problemas del sistema
- ✅ **Confirmaciones** - Tareas completadas  
- 🔧 **Mantenimiento** - Trabajos programados
- 💬 **Personalizado** - Cualquier mensaje

## ✨ Características
- ✅ **Incluye ID del remitente** automáticamente
- ✅ **Agrega fecha/hora** del mensaje
- ✅ **Interfaz simple** con menús claros
- ✅ **Sugiere a quién contactar** para cada problema

## 🐛 Solución de Problemas

Si los mensajes no llegan:
```bash
# Verificar que el alias 'sistemas' existe
sudo cat /etc/aliases | grep sistemas

# Si no existe, crearlo:
sudo nano /etc/aliases
# Agregar: sistemas: alma, carlos
sudo newaliases
sudo systemctl restart postfix
```
