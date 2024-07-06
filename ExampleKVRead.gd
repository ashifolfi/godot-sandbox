extends Control

var kvs

func _ready():
	kvs = KeyValues.new()
	kvs.parse(FileAccess.get_file_as_string("res://maps/src/testmap.vmf"))
	
	print(item_str(kvs._root))

func item_str(item: KeyValues.KV1Element):
	var str = item.key + ": "
	
	if (item.children.size() > 0):
		str += "\n"
		for citem in item.children:
			str += item_str(citem)
	else:
		str += item.value + "\n"

	str.indent("    ")
	return str
