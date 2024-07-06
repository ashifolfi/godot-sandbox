extends Node


var vmf_class_name: String = "UntitledClass"
var properties: Dictionary
var auto_properties: Array[String]
var children: Array


func _init(className: String) -> void:
	self.vmf_class_name = className	
	self.properties = {}
	self.auto_properties = []
	self.children = []

func getAsStr(tab_level: int = -1) -> String:
	var string: String = ""
	var tab_prefix: String = ""
	for i in range(tab_level):
		tab_prefix += "\t"
	var tab_prefix_inner = tab_prefix + "\t"
	if self.vmf_class_name != "":
		string += tab_prefix + self.vmf_class_name + "\n"
		string += tab_prefix + "{\n"
	for attr_name in self.auto_properties:
		var value = self.get(attr_name)
		if !(value == null):
			if value is bool:
				string += tab_prefix_inner + "\"" + str(attr_name) + "\" \"" + str(int(value)) + "\"\n"
			else:
				string += tab_prefix_inner + "\"" + str(attr_name) + "\" \"" + str(value) + "\"\n"
	for key in self.properties.keys():
		string += tab_prefix_inner + "\"" + str(key) + "\" " + "\"" + str(self.properties[key]) + "\"\n"
	for child in self.children:
		string += child.getAsStr(tab_level + 1)
	if self.vmf_class_name != "":
		string += tab_prefix + "}\n"
	return string

func _to_string() -> String:
	return self.getAsStr()
