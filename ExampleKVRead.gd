extends Control

var kvs

func _ready():
	kvs = KeyValues.new()
	kvs.parse(FileAccess.get_file_as_string("res://maps/src/testmap.vmf"))
	
	print(str(kvs))
