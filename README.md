WIP

### Desciption

This is an HTTP layer to support REST requests.
I think the best use case is a server for turn based games.
The server will give you a response to HTTP requests.
This Project is still WIP and implemented in GDScript.
The reason I started this project is to learn some c++ while porting this project from GDScript to c++.

Support is always welcome.

### Web-server

Add your web files to the public folder.

Supported files: ```png, svg, css, html```

Start the "Game" and open [http://localhost:3560] in your browser.

### Example-Service to quickstart

You can test the supported requests with Swagger or Postman.

Checkout the swagger.json file with [Swagger-Editor](http://editor.swagger.io/#/)

### Godot HTTP client wrapper

https://github.com/AlexHolly/godot-http

### Supported verbs

 * GET
 * POST
 * PUT
 * DELETE
 * UPDATE

### Add service automatically

- REST
 - Some1Service
 - Some2Service


The REST Node will add all methods from his children that have "Service" at the end of there name.

Method example in Some1Service.

To use variables in the url you need to make the first character uppercase "Id".

```gdscript
func get_test_Id(header_dict, body, params_dict, connection):
```

### Add service manually

We want to add this url ```GET /user/test```


Create the function that will be executed on ```GET /user/test``` requests and add this function to the service list

```gdscript
func get_user_User(header_dict, body, params_dict, connection):
func _ready():
	add_service("GET", "user/User", [self,"get_user_User"])
```

### Header keys IN/OUT upper or lower case?
  To leave header keys as they come set

        IN_HEADER_MODE = IN_HEADER_KEY_KEEP

  Default is ```IN_HEADER_KEY_LOWER```.

  Same for ```OUT_HEADER_KEY_MODE```.

### Service function

Each function delivers the following variables

 * header_dict = Dictionary that contains all headers from the request
 * body = the json object as dictionary if added as supported type.
 * header_dict = Contains all params from the url(path (/Name) and query (?Name=) )
 * connection = Should be ignored. It contains the StreamPeerTCP

### How to add supported types?

### How to use parameters in url?

 - Query parameters

  ```url: POST http://localhost:3560/register?user=test&password=123```

```gdscript
func post_register(header_dict, body, params_dict, connection):
	print(params) #output { "user":"test","password":123 }
```


 - URL parameters need to start with an upper_case ("Name") in the function name.

  ```url: GET http://localhost:3560/user/test?planet=moon```

```gdscript
func get_user_Name(header_dict, body, params_dict, connection):
	print(params) #output {"name":"test","planet":moon}
```

### TODO

 - add publish/subscribe service

   - passive mode

 - no busy waiting, related https://github.com/godotengine/godot/issues/33479

 - add accepted formats/ types defaults ["application/json","bytestream","text/html","text/plain"]

 - chunked-transfer

 - security(https,...)

 - send files/images -> bytestream?


### LICENSE
[MIT](./LICENSE)
