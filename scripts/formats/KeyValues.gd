class_name KeyValues extends Resource

## Class for handling data from a Valve KeyValues file
##
## Class used to handle all operations on a Valve KeyValues format file.
## Including, parsing, getting data, storing data, writing, etc.
##
## @tutorial(KeyValues Documentation): https://developer.valvesoftware.com/wiki/KeyValues

const TK_BLOCK_START = '{'
const TK_BLOCK_END = '}'
const TK_COND_START = '['
const TK_COND_END = ']'
const DEF_STRING_START = '"'
const DEF_STRING_END = '"'
const DEF_SINGLE_LINE_COMMENT_START = "//"

var stri: int = 0
var _root: KV1Element

var children: Array[KV1Element]:
	get:
		return _root.children

func _is_new_line(c: String) -> bool:
	return (c == '\n' or c == '\r')

func _is_whitespace(c: String) -> bool:
	return (c == ' ' or c == '\a' or c == '\f' or c == '\t' or c == '\v' or _is_new_line(c))

func _eat_single_line_comment(contents: String):
	while (!_is_new_line(contents[stri])):
		stri += 1
		if (stri >= contents.length()): return

func _eat_whitespace_and_slcomments(contents: String):
	while (_is_whitespace(contents[stri])):
		stri += 1
		if (stri >= contents.length()): return
	
	if (contents.substr(stri, 2) == DEF_SINGLE_LINE_COMMENT_START):
		_eat_single_line_comment(contents)
		_eat_whitespace_and_slcomments(contents)
		return

func _read_string(contents: String, use_escape_sequences: bool, start_char: String = DEF_STRING_START, end_char: String = DEF_STRING_END) -> String:
	var str = ""
	
	var stop_at_whitespace = true
	if (contents[stri] == start_char):
		stop_at_whitespace = false
	else:
		str += contents[stri]
	
	stri += 1
	while (contents[stri] != end_char):
		if (stri >= contents.length()): break
		
		if (stop_at_whitespace and _is_whitespace(contents[stri])):
			break
		
		if (use_escape_sequences and contents[stri] == '\\'):
			stri += 1
			if (stop_at_whitespace and _is_whitespace(contents[stri])):
				break
			
			if (contents[stri] == 'n'):
				str += "\n"
			elif (contents[stri] == 't'):
				str += "\t"
			elif (contents[stri] == '\\' or contents[stri] == '"'):
				str += contents[stri]
			else:
				str += contents[stri - 1] + contents[stri]
		else:
			str += contents[stri]
		
		stri += 1
	stri += 1

	return str

func _read_element(contents: String, use_escape_sequences: bool):
	var elements: Array[KV1Element] = []
	while (true):
		if (stri >= contents.length()): break
		_eat_whitespace_and_slcomments(contents)
		if (stri >= contents.length()): break
		
		# check if we've reached the end of the block
		if (contents[stri] == TK_BLOCK_END):
			stri += 1
			break
		
		# read key
		var childKey = _read_string(contents, use_escape_sequences)
		elements.push_back(KV1Element.new())
		elements.back().key = childKey
		_eat_whitespace_and_slcomments(contents)
		
		# read value
		if (contents[stri] != TK_BLOCK_START):
			elements.back().value = _read_string(contents, use_escape_sequences)
			_eat_whitespace_and_slcomments(contents)
		
		# read conditional
		if (contents[stri] == TK_COND_START):
			elements.back().conditional = _read_string(contents, use_escape_sequences, TK_COND_START, TK_COND_END)
			_eat_whitespace_and_slcomments(contents)
		
		# read block
		if (contents[stri] == TK_BLOCK_START):
			stri += 1
			_eat_whitespace_and_slcomments(contents)
			if (contents[stri] != TK_BLOCK_END):
				elements.back().children = _read_element(contents, use_escape_sequences)
			else:
				stri += 1
	
	return elements

func _init():
	_root = KV1Element.new()

func parse(contents: String, use_escape_sequences: bool = false):
	stri = 0
	_root.children = _read_element(contents, use_escape_sequences)

func _to_string():
	return _root._to_string()

class KV1Element:
	var key: String = ""
	var conditional: String = ""
	var value: String = ""
	var children: Array[KV1Element] = []
	
	func _to_string():
		var ostr = "\"" + key + "\""
		
		if (value != ""):
			ostr += " \"" + value + "\""
		
		if (conditional != ""):
			ostr += " [" + conditional + "]"
		
		if (children.size() > 0):
			ostr += "\n{"
			for child in children:
				ostr += "\n" + str(child).indent("\t")
			ostr += "\n}"
		
		return ostr
