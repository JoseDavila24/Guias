## 🎯 **Creación de grupos y configuración de listas de correo**

### **Paso 1: Crear los grupos en el sistema**
```bash
# Crear grupos
sudo groupadd desarrolladores
sudo groupadd soporte

# Agregar usuarios a los grupos
sudo usermod -a -G desarrolladores carlos
sudo usermod -a -G desarrolladores juan
sudo usermod -a -G soporte abner
sudo usermod -a -G soporte juan  # Juan puede estar en ambos grupos
```

### **Paso 2: Verificar la membresía de grupos**
```bash
# Verificar a qué grupos pertenecen los usuarios
groups carlos
groups juan  
groups abner
```

### **Paso 3: Crear alias de correo para los grupos**
```bash
# Editar archivo de aliases
sudo nano /etc/aliases
```

**Agregar estas líneas:**
```
# Grupos de correo
desarrolladores: carlos, juan
soporte: abner, juan
equipo: carlos, juan, abner
```

### **Paso 4: Compilar los aliases**
```bash
# Compilar la base de datos de aliases
sudo newaliases

# Verificar que se compilaron correctamente
sudo postalias /etc/aliases
```

## 🚀 **Prueba de los grupos de correo**

### **Enviar correo a grupos desde el servidor:**
```bash
# Enviar a todo el equipo de desarrolladores
echo "Reunión de desarrolladores mañana a las 10:00" | mail -s "Reunión Desarrolladores" desarrolladores@jmrd.local

# Enviar al equipo de soporte  
echo "Nuevo ticket de soporte asignado" | mail -s "Ticket de Soporte" soporte@jmrd.local

# Enviar a todo el equipo completo
echo "Comunicado general para todo el equipo" | mail -s "Comunicado General" equipo@jmrd.local
```

### **Verificar recepción:**
```bash
# Verificar que los correos llegaron a todos los miembros
sudo ls -la /var/mail/
```

## 📧 **Direcciones de correo de grupo disponibles:**
- **desarrolladores@jmrd.local** → Carlos y Juan
- **soporte@jmrd.local** → Abner y Juan  
- **equipo@jmrd.local** → Carlos, Juan y Abner

## ❓ **¿Procedemos con la creación de los grupos?**

**Una vez configurado, podrás:**
- Enviar un correo y que llegue automáticamente a todo el grupo
- Tener distribución organizada por departamentos
- Mantener la configuración "pasiva" (solo recepción)
