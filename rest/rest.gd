#author https://github.com/AlexHolly
#version 0.1
extends Node

var max_headers = 100
var max_header_size = 8190*max_headers

var OUT_HEADER_KEY_LOWER = 0
var OUT_HEADER_KEY_UPPER = 1
var OUT_HEADER_KEY_KEEP = 2

var OUT_HEADER_MODE = OUT_HEADER_KEY_LOWER

var IN_HEADER_KEY_LOWER = 3
var IN_HEADER_KEY_UPPER = 4
var IN_HEADER_KEY_KEEP = 5

var IN_HEADER_MODE = IN_HEADER_KEY_LOWER


var PUBLIC_PATH = "res://public"

var HTTP = "http"

var urls = {}

func header():
	var rs = {}
	return rs

func res():
	var response = {}
	response["code"] = 200
	response["header"] = header()
	response["body"] = ""
	return response

func _ready():
	if(PUBLIC_PATH!="" && Directory.new().dir_exists(PUBLIC_PATH)):
		add_service("GET", "/", [self,"get_File"])
		add_public_folder()
	add_service("GET", "myip", [self,"get_myip"])
	register_services()

func add_public_folder():
	add_folder( PUBLIC_PATH )
	
func add_folder(path):
	var d = Directory.new()
	if d.open(path)==0:
		d.list_dir_begin()
		var file_name = d.get_next()
		while(file_name!=""):
			if d.current_is_dir():#folder
				if(file_name!="." && file_name!=".." ):
					add_folder(path+"/"+file_name)
			else:#file
				if(path==PUBLIC_PATH):
					add_service("GET", file_name, [self,"get_File"])
				else:
					add_service("GET", path.replace(PUBLIC_PATH, "")+"/"+file_name, [self,"get_File"])
			file_name = d.get_next()
	else:
		print("public folder not found")

func register_services():
	for service in get_children():
		
		var name = service.get_name()
		if(name.find("Service")==name.length()-7):#childrens name that ends with Service
			
			for fun in service.get_method_list():
				
				if(fun["flags"] & METHOD_FLAG_FROM_SCRIPT):
					name = fun["name"]
					if( name.matchn("post_*") || name.matchn("get_*") || name.matchn("put_*") || name.matchn("delete_*") || name.matchn("patch_*") || name.matchn("option_*") || name.matchn("head_*") ):
						var verb_d = name.split("_")
						var verb = verb_d[0].to_upper()
							
						var url_d = name.right(verb.length())
						var url = url_d.replace("_","/")
		
						add_service(verb, url, [service, name])
		else:
			print("Name has no Service at the end")
	
func add_service(verb, url, funct):
	var paths = [url]
	if(url!="/"):
		paths = url.split("/",false)
	
	if !urls.has(verb):
		urls[verb] = {}
	
	var counter = 1
	var curr_verb = urls[verb]
	
	for path in paths:
		if( !curr_verb.has(path) ):#If thr route is not available
			if( path[0].to_upper() == path[0] && path[0]!="/" ):#is a variable param in url
				curr_verb["*"] = { "name":path }
				path = "*"
			else:
				curr_verb[path] = {}
			#last path entry add func
			if(counter==paths.size()):#last way of path?
				curr_verb[path]["func"] = funct
		else:#This Route is already available but contains no function
			if(counter==paths.size()):#last way of path?
				curr_verb[path]["func"] = funct
		curr_verb = curr_verb[path]
		counter+=1

#parse route
#needs some refactoring
func handle_request(request, connection):
	var header = request["header"]
	var body_dict = request["body"]
	var verb = header["verb"]
	
	var url = header["url"]
	var params = header["params"]
	
	var _func = ""
	var route = {}
	
	var paths = [url]
	if(url!="/"):
		paths = url.split("/", false)
	
	if !urls.has(verb):
		return response(404, {},"1.verb " + verb + " not found." , connection)
	
	var counter = 1
	var curr_verb = urls[verb]
	
	for path in paths:
		if(curr_verb.has(path)):
			if(counter==paths.size()):
				if(curr_verb[path].has("func")):#route found!
					var fun = curr_verb[path]["func"]
					var map = fun[0].call(fun[1], header, body_dict, params, connection)

					if(map!=null):# if something is returned handle.. what about a map that is returned header/body
						if(map.has("code") && map.has("header") && map.has("body")):
							return response(map["code"], map["header"], map["body"], connection)
						else:
							return response(404, {}, "2.Something wrong with response dictionary", connection)
					else:
						# TODO Maybe add some response error?
						pass
				else:
					return response(404, {},"3.No such service " + verb + " " + url, connection)
			else:
				#Route found but there could be more coming
				curr_verb = curr_verb[path]
			counter+=1 #Used to determaned end of route, maybe has some bug on longer routes needs testing
		elif(curr_verb.has("*")):
			var name = curr_verb["*"]["name"]
			params[name.to_lower()] = path
			
			path = "*"
			if(counter==paths.size()):
				if(curr_verb[path].has("func")):#route found
					var fun = curr_verb[path]["func"]
					var map = fun[0].call(fun[1], header, body_dict, params, connection)
					
					if(map!=null):# if something is returned handle.. what about a map that is returned header/body
							if(map.has("code") && map.has("header") && map.has("body")):
								return response(map["code"], map["header"], map["body"], connection)
							else:
								return response(404 , {}, "4.Something wrong with response dictionary", connection)
					else:
						# TODO Maybe add some response error?
						pass
				else:
					return response(404, {},"5.No such service " + verb + " " + url, connection)
			else:
				#Route found but there could be more coming
				curr_verb = curr_verb[path]
			counter+=1 #Used to determaned end of route, maybe has some bug on longer routes needs testing
		else:
			return response(404, {},"6.No such service " + verb + " " + url, connection)
	return response(404, {},"7.No such service " + verb + " " + url, connection)

func _parse_header(request):
	var requestLine = {}
	var lines = request.split("\r\n", true)
	
	#parse first request line 
	var line_split = lines[0].split(" ",true)
	
	requestLine["verb"] = line_split[0]
	
	if(requestLine["verb"]=="HTTP/1.1"):
		return -2
		
	requestLine["url"] = line_split[1]
	
	requestLine["version"] = line_split[2]
	requestLine["params"] = {}
	
	if(requestLine["url"].find("?", 0)>0):

		var url_query = requestLine["url"].split("?", true)
		if( url_query.size()>1 ):
			requestLine["url"] = url_query[0]
			var params_array = url_query[1].split("&", true)
			#to dict
			var params_map = requestLine["params"]
			for param in params_array:
				if param != "":
					# TODO keys_to_lower??
					var key_value = param.split("=", true)
					params_map[key_value[0].percent_decode()] = key_value[1].percent_decode()
		else:
			print("url query error")
			return -1
	else:
		#print("url has no params")
		pass
	
	lines.set(0, "")
	
	#parse header values
	for line in lines:
		if line != "":
			var pair = line.split(": ", true)
			if(IN_HEADER_MODE==IN_HEADER_KEY_LOWER):
				requestLine[pair[0].to_lower()] = pair[1]
			elif(IN_HEADER_MODE==IN_HEADER_KEY_UPPER):
				requestLine[pair[0].to_upper()] = pair[1]
			elif(IN_HEADER_MODE==IN_HEADER_KEY_KEEP):
				requestLine[pair[0]] = pair[1]
			else:
				print("WARN INVALID IN_HEADER_KEY")
				requestLine[pair[0]] = pair[1]

	return requestLine

func _parse_body(header, connection):
	var body = {}
	
	if ("content-length" in header && "content-type" in header):
		var content_length = header["content-length"].to_int()
		if (content_length != 0 ):
			var content_type = header["content-type"].to_lower()

			#ISSUE can't compare RawArray with -1 == not working
			#if(accepted_content_types.find(content_type)==-1):
			#	return -1
				
			if(content_type == "application/json"):
				body = parse_json(connection.get_data(content_length)[1].get_string_from_utf8())
				if(typeof(body)!=TYPE_DICTIONARY):
					print("Error: invalid json")
			elif(content_type == "bytestream"):
				body = connection.get_data(content_length)[1]
			elif(content_type == "text/plain" || content_type == "text/html"):
				body = connection.get_data(content_length)[1].get_string_from_utf8()
			else:
				print("Error: unsupported content-type")
		else:
			print("Error: invalid content-length")
	else:
		print("Error: missing content-type or content-length")
		
	return body

func response(code, header_adds, body, connection):
	
	var has_type = header_adds.has("Content-Type") || header_adds.has("content-type")
	#prepare body
	var header_body = default_body_parser[1].call(default_body_parser[0],body,has_type)
	
	#pass header as dict
	var di = merge_dict(header_adds, header_body[0])
	var header = build_header(code, di)
	#send response
	connection.put_data( (header + "\r\n").to_utf8()+header_body[1])
	
var default_body_parser = ["default_body_parser",self]

func default_body_parser(body, has_type):
	var raw_body = PoolByteArray()
	var header = {}
	if(typeof(body) == TYPE_RAW_ARRAY):
		raw_body = body
		
		if(raw_body.size()>0):
			header["content-length"] = str(raw_body.size())
			if(!has_type):
				header["content-type"] = "bytestream"
	elif(typeof(body) == TYPE_DICTIONARY):
		raw_body = body.to_json().to_utf8()
		
		if(raw_body.size()>0):
			header["content-length"] = str(raw_body.size())
			if(!has_type):
				header["content-type"] = "application/json; charset=utf-8"
	elif(typeof(body) == TYPE_STRING):
		raw_body = body.to_utf8()
		if(raw_body.size()>0):
			header["content-length"] = str(raw_body.size())
			if(!has_type):
				if(body.find("<!DOCTYPE html>",0)>-1):
					header["content-type"] = "text/html; charset=utf-8"
				else:
					header["content-type"] = "text/plain; charset=utf-8"
		#else:
			#raw_body = RawArray()
		#	header += "content-length: " + str(0) + "\r\n"
	else:
		header["content-length"] = str(0)
		print( "body type not supported" )
	
	return [header, raw_body]


func merge_dict(dict, dict_prefered):
	for key in dict_prefered:
		dict[key] = dict_prefered[key]
	return dict

func header_case(key):
	
	if(OUT_HEADER_MODE == OUT_HEADER_KEY_LOWER):
		return key.to_lower()
	elif(OUT_HEADER_MODE == OUT_HEADER_KEY_UPPER):
		return key.to_upper()
	elif(OUT_HEADER_MODE == OUT_HEADER_KEY_KEEP):
		return key
	else:
		print("WARN INVALID OUT_HEADER_KEY")
		return key

func build_header(code, header_dict):
	var header = "HTTP/1.1 " + str(code) + "\r\n"
	
	for keys in header_dict:
		var key = header_case(keys)
		header += key + ": "
		if(typeof(header_dict[keys]) == TYPE_ARRAY):
			
			var counter = 0
			for field in header_dict[keys]:
				
				counter += 1
				if(counter < header_dict[keys].size()):
					header += field + "; "
				else:
					header += field
		else:
			header += header_dict[keys]
		header += "\r\n"
	
	return header
	
#looks a bit dirty but keep the dictionary!!
#func merge_header(code, header_adds):
#	var header = "HTTP/1.1 " + str(code) + "\r\n"

	# TODO "Transfer-Encoding: chunked"?
	#header+= "Transfer-Encoding: chunked" + "\r\n"
	
#	var rs = {}
#	for key in header_adds:
#			rs[key.to_lower()] = header_adds[key]
#	
#	for keys in rs:
#		header += keys + ": "
#		if(typeof(rs[keys]) == TYPE_ARRAY):
#			
#			var counter = 0
#			for field in rs[keys]:
#				
#				counter += 1
#				if(counter < rs[keys].size()):
#					header += field + "; "
#				else:
#					header += field
#		else:
#			header += rs[keys]
#		header += "\r\n"
#	
#	return header
	
func get_File(header_map, body_map, params, connection):
	var response = res()
	var f = File.new()
	var path = header_map["url"]
	if(path=="/"):
		path = "/index.html"
	if(f.open(PUBLIC_PATH+path, File.READ)==0):
		var rs = ""
		if(path.get_extension()=="png" || path.get_extension()=="svg"):
			rs = f.get_buffer(f.get_len())
			response["header"]["content-type"] = "image/svg+xml"
			
			response["body"] = rs
		elif(path.get_extension()=="css"):
			rs = f.get_buffer(f.get_len())
			response["header"]["content-type"] = "text/css; charset=utf-8"
			response["body"] = rs
		elif(path.get_extension()=="html"):
			rs = f.get_as_text()
			response["header"]["content-type"] = "text/html; charset=utf-8"
			response["body"] = rs
		else:
			rs = f.get_as_text()
			response["header"]["content-type"] = "text/plain; charset=utf-8"
			response["body"] = rs
	else:
		response["code"] = 404
		response["body"] = "File not found"
	f.close()
	return response
	
func get_myip(header_map, body_map, params, connection):
	var response = res()
	response["body"] = { "ip":connection.get_connected_host() }
	return response
