class_name KeyValues extends Node

## Class for handling data from a Valve KeyValues file
##
## Class used to handle all operations on a Valve KeyValues format file.
## Including, parsing, getting data, storing data, writing, etc.
##
## @tutorial(KeyValues Documentation): https://developer.valvesoftware.com/wiki/KeyValues

const TK_BLOCK_START = '{'
const TK_BLOCK_END = '}'
const DEF_STRING_START = '"'
const DEF_STRING_END = '"'
const DEF_SINGLE_LINE_COMMENT_START = "//"

var stri: int = 0
var kvdict: Dictionary

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

func _read_element(contents: String):
	var dict = {}
	while (true):
		if (stri >= contents.length()): break
		_eat_whitespace_and_slcomments(contents)
		if (stri >= contents.length()): break
		
		# check if we've reached the end of the block
		if (contents[stri] == TK_BLOCK_END):
			stri += 1
			break
		
		# read key
		var childKey = _read_string(contents, true)
		_eat_whitespace_and_slcomments(contents)
		
		# read value
		if (contents[stri] != TK_BLOCK_START):
			dict[childKey] = _read_string(contents, true)
			_eat_whitespace_and_slcomments(contents)
		
		# todo: conditionals
		
		# read block
		if (contents[stri] == TK_BLOCK_START):
			stri += 1
			_eat_whitespace_and_slcomments(contents)
			if (contents[stri] != TK_BLOCK_END):
				dict[childKey] = _read_element(contents)
			else:
				stri += 1
	
	return dict

func parse(contents: String):
	stri = 0
	kvdict = _read_element(contents)
