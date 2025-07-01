class_name ExpandThisSection


const KEY_SEPARATOR: String = "|"

var object: String
var category: String
var group: String
var control: Control

var group_key: String:
	get:
		return "%s%s%s%s%s" % [object, KEY_SEPARATOR, category, KEY_SEPARATOR, group]

var category_key: String:
	get:
		return "%s%s%s" % [category, KEY_SEPARATOR, group]


func _init(_object: String, _category: String, _group: String) -> void:
	object = _object
	category = _category
	group = _group
