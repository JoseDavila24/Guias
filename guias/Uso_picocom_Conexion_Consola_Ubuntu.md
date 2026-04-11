### 🔌 **Guía rápida para usar `picocom` (el "picomon")**

#### 1. **Instalación**
Primero, abre una terminal e instala el programa:
```bash
sudo apt update
sudo apt install picocom
```

#### 2. **Identificar el puerto de tu cable**
Conecta el cable USB a RJ45 al ordenador y al switch. Luego, en la terminal, ejecuta:
```bash
ls /dev/ttyUSB* /dev/ttyACM*
```
Si aparece algo como `/dev/ttyUSB0`, ese es tu puerto. Si no ves nada, prueba con el cable desconectado y luego conectado para identificar cuál aparece nuevo .

#### 3. **Conectarte al switch/router**
Ahora, usa este comando para conectarte (los valores estándar suelen ser 115200 baudios, 8 bits, sin paridad, 1 stop bit):
```bash
picocom -b 115200 /dev/ttyUSB0
```
Si ves un mensaje de error de permisos, prueba con `sudo`:
```bash
sudo picocom -b 115200 /dev/ttyUSB0
```

#### 4. **Navegar y salir de `picocom`**
- Una vez conectado, ya puedes escribir comandos en el switch (como `enable`, `configure terminal`, etc.).
- Para **salir** de `picocom`, pulsa: `Ctrl+A` seguido de `Ctrl+X`.

#### 5. **Solución rápida de problemas**
- **"Permission denied"**: Agrega tu usuario al grupo `dialout` para no tener que usar `sudo` siempre:
  ```bash
  sudo adduser tu-usuario dialout
  ```
  Luego cierra sesión y vuelve a entrar.
- **¿No sale nada en pantalla?**: Prueba cambiando la velocidad. Algunos switches usan 9600 en lugar de 115200:
  ```bash
  picocom -b 9600 /dev/ttyUSB0
  ```

#### 6. **Combinar `picocom` con interfaz gráfica**
Como ya hablamos, `picocom` es solo para terminal, pero puedes lograr la misma eficiencia con una interfaz gráfica fácil usando **`GTKterm`** o **`moserial`**. Ambos son igual de rápidos pero con ventanas y menús .

- **GTKterm** es el más parecido a `picocom` pero con botones.
- **Moserial** te permite guardar perfiles para cada dispositivo.

Para instalarlos:
```bash
sudo apt install gtkterm
# o
sudo apt install moserial
```

---

### ⚡ **Resumen de comandos útiles de `picocom`**

| Comando | Qué hace |
|:--------|:---------|
| `picocom -b 115200 /dev/ttyUSB0` | Conecta a 115200 baudios |
| `picocom -b 9600 /dev/ttyUSB0` | Conecta a 9600 baudios (para switches antiguos) |
| `Ctrl+A` `Ctrl+X` | Salir de `picocom` |
| `Ctrl+A` `Ctrl+Q` | Salir sin preguntar |

---

### 🧠 **Nota importante**
La herramienta se llama **`picocom`**, no "picomon". Es un pequeño error común, pero ahora ya sabes el nombre exacto para buscarla o pedir ayuda .

Si quieres, en unos segundos te puedo pasar los comandos específicos para el modelo de switch o router que estás configurando. ¿Cuál es exactamente?
