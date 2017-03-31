extends "res://rest/rest.gd"

var running = true

#var server_url
var ip = null
var port = null

var connection = null
var thread_store = {}
var passiv_id = -1

#var util = load("res://services/util/util.gd")

signal onConnect( connection )
signal onDisconnect( connection )

func get_passiv_id():
	passiv_id
	
func _ready():
	#server_url = "http://" + ip + ":" + str(port)
	#connect_server(ip)
	#connect( "onConnect", self, "_onConnect")
	pass


func connect_to_server(ip, port):
	connection = StreamPeerTCP.new()
	connection.connect_to_host( ip, port )
	print( "Connected to " + ip + ":" + str(port) )
	
	set_process( true )

func header(verb, path, headers):
	var header = verb.to_upper() + " " + path + " " + "HTTP/1.1" + "\r\n"
	
	for key in headers:
		header+= key.to_lower() + ": " + headers[key] + "\r\n"
	header+="\r\n"
	
	return header

#requests
#func get(adress):
#	return http.get(adress)
	
#func put(adress,body=RawArray()):
#	return http.put(adress,body)
	
#func post(adress, body=RawArray()):
#	return http.post(adress,body)
	
#func delete(adress):
#	return http.delete(adress)

#This is all busy waiting very bad...
func _process(delta):
	
	if connection.get_status() == connection.STATUS_CONNECTED:
		
		
		var thread_rest_request = Thread.new()
		var verbindung = {}
		verbindung["thread"] = thread_rest_request
		verbindung["connection"] = connection
		#thread_store[thread_rest_request.get_id()] = verbindung
		
		thread_rest_request.start(self, "run_bg_request", verbindung)
		
		set_process( false )
		#http.set_connection(connection)
		#TODO check valid connection
		#http.connect(server_url)
		
		emit_signal("onConnect", connection)
		
	elif connection.get_status() == StreamPeerTCP.STATUS_CONNECTING:
		
		print( "Trying to connect " + ip + ":" + str(port) )
	
	elif connection.get_status() == connection.STATUS_NONE or connection.get_status() == StreamPeerTCP.STATUS_ERROR:
		
		print( "Couldn't connect to " + ip + " :" + str(port) )
		print( "Server disconnected? " )
		emit_signal("onDisconnect", connection)
		set_process( false )
	
func run_bg_request(verbindung):
	
		var connection = verbindung["connection"]
		var thread = verbindung["thread"]
		
		#read header string
		while(running):
			var header = ""
			var header_size = 0
			if(connection == null || !connection.is_connected_to_host()):
				return end(thread, connection)
			
			while(header.substr(header.length()-4, header.length()) != "\r\n\r\n"):
				
				if(connection == null || !connection.is_connected_to_host()):
					return end(thread, connection)
				#Waiting until data incoming
				header += connection.get_data(1)[1].get_string_from_utf8()
				header_size += 1
				#print(str(header_size))
				#if(header_size > max_header_size):
				#	header_error = true
			#print(header)
			var header_map = _parse_header(header)
			
			if(header_map==-1):
				return close_connection(431,"BYE" , connection, thread)
			#elif(header_map==-2):
			#	return close_connection(431,"BYE" , connection, thread)
			#print(header_map)
			
			#ISSUE:Can't find body end if no Content-Length given
			#chunked thransfer...
			print(header_map)
			var body = _parse_body(header_map, connection)
			
			var output = {}
			output["header"] = header_map
			output["body"] = body

			handle_request(output, connection)

func end(thread, connection):
	emit_signal("onDisconnect", connection)
	call_deferred( "close_thread", thread.get_id() )
	
func close_connection(code,message,connection,thread):
	response(code, {},message , connection)
	emit_signal("onDisconnect", connection)
	connection.disconnect_from_host()
	call_deferred( "close_thread", thread.get_id() )

func close_thread(thread_id):
	thread_store.erase(thread_id)
