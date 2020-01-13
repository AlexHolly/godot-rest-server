#author https://github.com/AlexHolly
#version 0.1
extends Node


func response():
	var response = {}
	response["code"] = 200
	response["header"] = header()
	response["body"] = ""
	return response

func header():
	var rs = {}
	
	# Needed to make swagger requests work
	rs["Access-Control-Allow-Origin"] = "*"
	rs["Access-Control-Allow-Headers"] = "Origin, X-Requested-With, Content-Type, Accept"

	# Needed to make Postman work
	rs["content-length"] = str(0)
	
	return rs

var names = {}

func post_user(header_dict, body, params_dict, connection):
	var response = response()
	
	if("user" in params_dict):
		var user = params_dict["user"]
		names[user] = user
		response["code"] = 201
		response["body"] = user + " created"
	else:
		response["code"] = 404
		response["body"] = "parameter user not found"
		
	return response

func get_user_User(header_dict, body, params_dict, connection):
	var response = response()
	
	if("user" in params_dict):
		var user = params_dict["user"]
		if(user in names):
			response["code"] = 200
			response["body"] = names[user]
		else:
			response["code"] = 404
			response["body"] = "User not found"
	else:
		response["code"] = 404
		response["body"] = "parameter user not found"
		
	return response

func delete_user_User(header_dict, body, params_dict, connection):
	var response = response()
	
	if("user" in params_dict):
		var user = params_dict["user"]
		if(user in names):
			response["code"] = 200
			response["body"] = user + " deleted"
		else:
			response["code"] = 404
			response["body"] = "user not found"
	else:
		response["code"] = 404
		response["body"] = "parameter user not found"
	
	return response

func get_echo(header_dict, body, params_dict, connection):
	var response = response()
	
	if("echo" in params_dict):
		var echo = params_dict["echo"]
		response["code"] = 200
		response["body"] = echo
	else:
		response["code"] = 404
		response["body"] = "parameter user not found"
	
	return response

func _on_REST_onConnect( connection ):
	print("Someone Connected :)")

func _on_REST_onDisconnect( connection, ip ):
	print("Someone Disonnected :(")
