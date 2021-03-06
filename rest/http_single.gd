#author https://github.com/AlexHolly 
#v0.4
extends Node

var timeout_sec = 1

var ERR_ADRESS = "Invalid http request, maybe adress is empty?"
var ERR_BODY = "Parse Error unsupported body"
var ERR_CONN = "Connection error, can't reach host"
var ERR_REQUEST = "Request failed, invalid params?"

func error(code):
	var rs = {}
	
	rs["header"] = {}
	rs["body"] = str(code)
	rs["code"] = 404
	return rs
	
func default_headers():
	return {
				"User-Agent": "Pirulo/1.0 (Godot)",
				"Accept": "*/*",
				"connection": "keep-alive"
			}

var headers = default_headers()

func set_headers(_headers):
	headers = _headers

func dict_to_array(dict):
	var rs = []
	
	for key in dict:
		rs.append(key + ": " + str(dict[key]))
	return rs
	
var HTTP = "http://"
var HTTPS = "https://"

# TODO Was machen mit players wie werden sie geupdated siehe board get players problem
# TODO Asynchrone anfragen einbauen? Etwas komplizierter für anfragenden, muss call back funktion mit geben?
# TODO ssl immer port 443???? nicht unbedingt oder?

var http = HTTPClient.new() # Create the Client

func set_connection(peer):
	http.set_connection( peer )
	
func connect(adress):

	var uri_dict = get_link_address_port_path(adress)
	
	var serverAdress = uri_dict["host"]
	var port = uri_dict["port"]
	var path = uri_dict["path"]
	var fullhost = uri_dict["fullhost"]
	
	var ssl = uri_dict["ssl"]
	
	http.set_blocking_mode( true ) #wait untl all data is available on response

	var err = http.connect(serverAdress,port,ssl) # Connect to host/port
	
	if(!err):
		var start = OS.get_unix_time()
		while( http.get_status()==HTTPClient.STATUS_CONNECTING or http.get_status()==HTTPClient.STATUS_RESOLVING):
			if(OS.get_unix_time()-start>timeout_sec):
				return [HTTPClient.STATUS_CANT_CONNECT,fullhost]
			else:
				http.poll()
		return [http,fullhost,path]
	else:
		return [HTTPClient.STATUS_CANT_CONNECT,fullhost]

	
func req(verb,adress,body1):
	if(adress==""):
		return error(ERR_ADRESS)
		
	var headers_body = handle_body(body1)
	var header = headers_body[0]
	var body = headers_body[1]

	if( header==ERR_BODY ):
		return error(ERR_BODY)
	
	var uri_dict = get_link_address_port_path(adress)
	
	var path = uri_dict["path"]
	
	if(typeof(http)==TYPE_OBJECT):
		var err = http.request_raw(verb, path, dict_to_array(header), body)
		if(!err):
			return getResponse()
		else:
			return error(ERR_REQUEST)
	return error(ERR_CONN)
	
func get(adress):
	return req(HTTPClient.METHOD_GET,adress,PoolByteArray())
	
func put(adress,body=PoolByteArray([])):
	return req(HTTPClient.METHOD_PUT,adress,body)
	
func post(adress, body=PoolByteArray([])):
	return req(HTTPClient.METHOD_POST,adress,body)
	
func delete(adress):
	return req(HTTPClient.METHOD_DELETE, adress,PoolByteArray())

func handle_body(body):
	var header = headers
		
	if(typeof(body)==TYPE_RAW_ARRAY):
		if(body.size()>0):
			header["Content-Type"] = "bytestream"
		return [header,body]
	elif(typeof(body)==TYPE_DICTIONARY):
		if(!body.empty()):
			header["Content-Type"] = "application/json"
			body = body.to_json().to_utf8()
		return [header,body]
	elif(typeof(body)==TYPE_STRING):
		if(body.length()>0):
			header["Content-Type"] = "text/plain"
			body = body.to_utf8()
		return [header,body]
	else:
		print("unsupported type")
		return [ERR_BODY,ERR_BODY]

func get_link_address_port_path(uri):
	var left = ""
	var link = ""
	var ssl = false
	
	if(uri.begins_with(HTTPS)):
		ssl = true
		link = uri.replace(HTTPS, "")
		left+=HTTPS
	else:
		link = uri.replace(HTTP, "")
		left+=HTTP
		
	var hostport = link.split("/", true)[0]
	
	left+=hostport
	
	var host_port = hostport.split(":", true)
	var host = host_port[0]
	
	# TODO ssl immer port 443???? nicht unbedingt oder?
	# TEST Falls kein port angegeben "" -> führt zu einem freeze 
	# TODO check if https -> ssl/tls 443
	var port = "80"
	if(host_port.size()>1):
		port = host_port[1]

	if(uri.begins_with(HTTPS)):
		port = "443"
	
	var path = uri.replace(left,"")
	
	return {
			"uri":uri, 
			"host":host,
			"port":int(port),
			"path":path,
			"ssl":ssl,
			"fullhost":hostport
			#query missing
			#fragment missing
			}

func getResponse():

	var rs = {}
	
	rs["header"] = {}
	rs["body"] = ""
	rs["code"] = 404
	
	# Keep polling until the request is going on
	while (http.get_status() == HTTPClient.STATUS_REQUESTING):
		http.poll()
	
	rs["code"] = http.get_response_code()
	
	# If there is header content(more than first line)
	if (http.has_response()):
		# Get response headers
		var headers = http.get_response_headers_as_dictionary()
		
		for key in headers:
			rs["header"][key.to_lower()] = headers[key]

		var cache = headers
		
		var rb = RawArray() #array that will hold the data
		
		while(http.get_status()==HTTPClient.STATUS_BODY):
			#http.set_read_chunk_size( http.get_response_body_length() )
			rb += http.read_response_body_chunk()
		
		if("content-length" in rs["header"] && rs["header"]["content-length"]!="0"):
			rs["body"] = parse_body_to_var(rb, rs["header"]["content-type"])
		else:
			rs["body"] = ""
		return rs
	else:
		return rs

func parse_body_to_var(body, content_type):
	
	if(content_type.find("application/json")!=-1):
		
		var bodyDict = {}
		body = body.get_string_from_utf8()
		
		#print(body)
		
		if( bodyDict.parse_json( body ) == 0 ):
			body = bodyDict
			print("make dict")
		else:
			print("Error beim body to dict json wandel")
		
	elif(content_type.find("text/plain")!=-1||content_type.find("text/html")!=-1):
		body = body.get_string_from_utf8()
	elif(content_type.find("bytestream")!=-1):
		pass#return body
	return body
