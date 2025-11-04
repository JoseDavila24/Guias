# Resumen General: Grupo y Correo Grupal

## 1. 🏗️ Crear Grupo y Agregar Usuarios
```bash
# Crear grupo
sudo groupadd sistemas

# Agregar usuarios
sudo usermod -a -G sistemas alma
sudo usermod -a -G sistemas carlos

# Verificar
getent group sistemas
```

## 2. 📧 Enviar Correo al Grupo

### Opción A: Listando usuarios
```bash
echo "Mensaje grupal" | mail -s "Asunto" alma@JMRD.lab carlos@JMRD.lab
```

### Opción B: Con alias (recomendado)
```bash
# Configurar alias permanente
sudo nano /etc/aliases
```
**Agregar:**
```
sistemas: alma, carlos
```
```bash
# Aplicar alias
sudo newaliases

# Usar alias
echo "Mensaje grupal" | mail -s "Asunto" sistemas@JMRD.lab
```

## 3. ✅ Comprobar
```bash
# Ver usuarios en grupo
groups alma
groups carlos

# Enviar correo de prueba
echo "Test grupo sistemas" | mail -s "Test" sistemas@JMRD.lab
```
