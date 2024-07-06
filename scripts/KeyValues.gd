class_name KeyValues extends Node

## Class for handling data from a Valve KeyValues file
##
## Class used to handle all operations on a Valve KeyValues format file.
## Including, parsing, getting data, storing data, writing, etc.
##
## @tutorial(KeyValues Documentation): https://developer.valvesoftware.com/wiki/KeyValues

const TK_BLOCK_START = '{'
const TK_BLOCK_END = '}'

func _is_new_line(c: String) -> bool:
	return (c == '\n' or c == '\r')
