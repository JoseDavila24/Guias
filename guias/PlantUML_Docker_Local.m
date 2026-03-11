### Mini Guía: Cómo usar PlantUML en tu computadora con Docker

Esta guía te permitirá levantar un servidor de PlantUML en tu máquina local para crear diagramas de código (UML, etc.) de manera privada y rápida.

#### **Requisito previo**
*   Tener **Docker** instalado en tu computadora. Puedes descargarlo desde [docker.com](https://www.docker.com/).

#### **Paso 1: Ejecutar el servidor PlantUML**
Vas a usar el contenedor oficial de `plantuml-server`. Abre tu terminal (Command Prompt, PowerShell o Terminal) y ejecuta uno de los siguientes comandos:

*   **Opción Jetty** (recomendada por ser ligera):
    ```bash
    docker run -d -p 8080:8080 plantuml/plantuml-server:jetty
    ```
*   **Opción Tomcat** (si prefieres el servidor Tomcat):
    ```bash
    docker run -d -p 8080:8080 plantuml/plantuml-server:tomcat
    ```

**Explicación del comando:**
*   `docker run`: Le dice a Docker que ejecute un contenedor.
*   `-d`: Ejecuta el contenedor en segundo plano (modo "detached").
*   `-p 8080:8080`: Conecta el puerto `8080` de tu computadora con el puerto `8080` del contenedor. Así podrás acceder a él desde tu navegador.
*   `plantuml/plantuml-server:jetty`: Es el nombre de la imagen oficial que vamos a usar (la etiqueta `jetty` o `tomcat` indica la versión).

#### **Paso 2: Verificar que funciona**
1.  Abre tu navegador web favorito.
2.  Ve a la dirección: `http://localhost:8080`
3.  Deberías ver la interfaz web de PlantUML. Si ves un editor con un ejemplo de código y un botón para generar el diagrama, ¡todo está funcionando correctamente!

#### **Paso 3: Crear tu primer diagrama**
1.  En la página `http://localhost:8080`, verás un recuadro con un código de ejemplo.
2.  Prueba copiando y pegando este ejemplo clásico (reemplaza el que viene por defecto):
    ```plantuml
    @startuml
    Alice -> Bob: Hola
    Bob -> Alice: ¿Cómo estás?
    @enduml
    ```
3.  Haz clic en el botón **"Submit"** o **"Enviar"** (suele estar al lado del editor).
4.  ¡El diagrama de secuencia se generará automáticamente!

#### **Paso 4: Usarlo desde tus herramientas**
Una de las grandes ventajas de tener el servidor local es que puedes integrarlo con editores de código o generadores de documentación.

*   **Integración con VS Code**: Si usas Visual Studio Code, instala la extensión "PlantUML". En la configuración de la extensión, busca la opción `plantuml.server` y pónla en `http://localhost:8080`. Así, cada vez que renderices un diagrama, usará tu servidor local (más rápido y privado).
*   **Uso manual**: Puedes generar imágenes enviando peticiones a tu servidor. Por ejemplo, si guardas tu código PlantUML en un archivo `diagrama.txt`, podrías generar una imagen PNG con:
    ```bash
    # En Linux/Mac
    curl -X POST -H "Content-Type: text/plain" --data-binary @diagrama.txt http://localhost:8080/png -o diagrama.png

    # En Windows PowerShell
    (Get-Content diagrama.txt -Raw) | Set-Content -Path temp.txt -NoNewline; curl.exe -X POST -H "Content-Type: text/plain" --data-binary @temp.txt http://localhost:8080/png -o diagrama.png
    ```

#### **Paso a paso resumido**
1.  Instala Docker.
2.  `docker run -d -p 8080:8080 plantuml/plantuml-server:jetty`
3.  Abre `http://localhost:8080`
4.  Escribe tu diagrama y haz clic en Submit.
5.  ¡Listo! Tienes PlantUML corriendo 100% local.

#### **Para detener el servidor**
Cuando termines de usarlo y quieras liberar recursos, puedes detener el contenedor:
1.  `docker ps` (para listar los contenedores activos y encontrar el ID o nombre del de plantuml)
2.  `docker stop <ID_o_NOMBRE_del_contenedor>`

¡Y eso es todo! Ahora tienes tu propia estación de diagramas PlantUML sin depender de internet.
