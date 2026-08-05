

En desarrollo

### Descripción

Esta es una capa HTTP para dar soporte a solicitudes REST.
Creo que el mejor caso de uso es un servidor para juegos por turnos.
El servidor te dará una respuesta a las solicitudes HTTP.
Este proyecto aún está en desarrollo y está implementado en GDScript.
La razón por la que comencé este proyecto es aprender algo de c++ mientras portaba este proyecto de GDScript a c++.

El soporte siempre es bienvenido.

### Servidor Web

Agrega tus archivos web a la carpeta pública.

Archivos compatibles: ```png, svg, css, html```

Inicia el "Juego" y abre [http://localhost:3560] en tu navegador.

### Servicio de ejemplo para comenzar rápidamente

Puedes probar las solicitudes compatibles con Swagger o Postman.

Revisa el archivo swagger.json con [Swagger-Editor](http://editor.swagger.io/#/)

### Envoltorio del cliente HTTP de Godot

https://github.com/AlexHolly/godot-http

### Verbos soportados

 * GET
 * POST
 * PUT
 * DELETE
 * UPDATE

### Agregar servicio automáticamente

- REST
 - Some1Service
 - Some2Service


El nodo REST agregará todos los métodos de sus hijos que tengan "Service" al final de su nombre.

Ejemplo de método en Some1Service.

Para usar variables en la URL, debes hacer que el primer carácter sea mayúscula, como "Id".

```gdscript
func get_test_Id(header_dict, body, params_dict, connection):
```

### Agregar servicio manualmente

Queremos agregar esta URL ```GET /user/test```


Crea la función que se ejecutará en las solicitudes ```GET /user/test``` y agrega esta función a la lista de servicios

```gdscript
func get_user_User(header_dict, body, params_dict, connection):
func _ready():
	add_service("GET", "user/User", [self,"get_user_User"])
```

### ¿Claves de encabezado IN/OUT en mayúsculas o minúsculas?
  Para dejar las claves de encabezado tal como llegan, configura:

        IN_HEADER_MODE = IN_HEADER_KEY_KEEP

  El valor predeterminado es ```IN_HEADER_KEY_LOWER```.

  Lo mismo para ```OUT_HEADER_KEY_MODE```.

### Función de servicio

Cada función entrega las siguientes variables

 * header_dict = Diccionario que contiene todos los encabezados de la solicitud
 * body = el objeto json como diccionario si se agrega como tipo compatible.
 * params_dict = Contiene todos los parámetros de la URL (ruta (/Name) y consulta (?Name=) )
 * connection = Debería ser ignorada. Contiene el StreamPeerTCP

### ¿Cómo agregar tipos compatibles?

### ¿Cómo usar parámetros en la URL?

 - Parámetros de consulta

  ```url: POST http://localhost:3560/register?user=test&password=123```

```gdscript
func post_register(header_dict, body, params_dict, connection):
	print(params) #output { "user":"test","password":123 }
```


 - Los parámetros de URL deben comenzar con una letra mayúscula ("Name") en el nombre de la función.

  ```url: GET http://localhost:3560/user/test?planet=moon```

```gdscript
func get_user_Name(header_dict, body, params_dict, connection):
	print(params) #output {"name":"test","planet":moon}
```

### PENDIENTE

 - agregar servicio de publicación/suscripción

   - modo pasivo

 - evitar espera ocupada (busy waiting), relacionado con https://github.com/godotengine/godot/issues/33479

 - agregar formatos/tipos aceptados por defecto ["application/json","bytestream","text/html","text/plain"]

 - transferencia fragmentada

 - seguridad (https,...)

 - enviar archivos/imágenes -> ¿bytestream?


### LICENCIA
[MIT](./LICENSE)
