#author https://github.com/AlexHolly
#version 0.1
extends "res://rest/rest.gd"

var default_port = 3560

signal onConnect( connection )
signal onDisconnect( connection, ip )

var server # for holding your TCP_Server object
var thread_store = {}
var header_error = false

func _ready():
	PUBLIC_PATH = "res://public"
	start_server(default_port)

func start_server(port):
	server = TCP_Server.new()
	if server.listen( port ) == 0:
		print( "Server started on port "+str(port) )
		set_process( true )

	else:
		print( "Failed to start server on port "+str(port) )
		start_server(port+1)

#This is all busy waiting very bad...
func _process(delta):

	if server!=null && server.is_connection_available():

		var connection = server.take_connection() # accept connection

		emit_signal("onConnect", connection)
	
		#Request needs to run in background seperate Thread
		var thread_rest_request = Thread.new()
		
		var verbindung = {}
		verbindung["thread"] = thread_rest_request
		verbindung["connection"] = connection
		
		thread_store[thread_rest_request.get_id()] = verbindung
		
		thread_rest_request.start(self, "run_bg_request", verbindung)


func run_bg_request(verbindung):
	
		var connection = verbindung["connection"]
		var thread = verbindung["thread"]
		var keep_alive = true
		
		while(keep_alive):
			
			# check someone disconnected
			if(connection != null && !connection.is_connected_to_host()):
				return end(thread, connection)
				
			# read header string
			
			var header = ""
			var header_size = 0
			
			while(!header_error && header.substr(header.length()-4, header.length()) != "\r\n\r\n"):
				
				# check someone disconnected
				if(connection != null && !connection.is_connected_to_host()):
					return end(thread, connection)
				
				# Waiting until data incoming
				header += connection.get_data(1)[1].get_string_from_utf8()

				header_size += 1
				if(header_size > max_header_size):
					header_error = true
					
			if(header_size > max_header_size):
				return close_connection(431,"BYE" , connection, thread)
			
			var header_map = _parse_header(header)

			if !(header_map is Dictionary):
				if(header_map==-2):
					print("Invalid header")
					return null
				
				if(header_map==-1):
					return close_connection(431,"BYE" , connection, thread)
				
			# ISSUE:Can't find body end if no Content-Length given, only on keep connection open?
			#chunked thransfer...
			var body = _parse_body(header_map, connection)
			#print(body)
			#if(body==-1):
			#	return close_connection(406,"Not Acceptable" , connection, thread)
			
			var output = {}
			output["header"] = header_map
			output["body"] = body
			
			handle_request(output, connection)
			
			if(output["header"].has("connection")):
				if(output["header"]["connection"]=="keep-alive"):
					#print("keep connection open")
					keep_alive = true
				else:
					return close_connection(431,"BYE" , connection, thread)
			#else:
			#	return close_connection(431,"BYE" , connection, thread_id)

func end(thread, connection):
	emit_signal("onDisconnect", connection, connection.get_connected_host())
	call_deferred( "close_thread", thread.get_id() )
	
func close_connection(code,message,connection,thread):
	response(code, {},message , connection)
	emit_signal("onDisconnect", connection, connection.get_connected_host())
	connection.disconnect()
	call_deferred( "close_thread", thread.get_id() )

func close_thread(thread_id):
	thread_store.erase(thread_id)
