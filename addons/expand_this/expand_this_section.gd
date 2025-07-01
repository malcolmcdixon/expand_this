class_name ExpandThisSection


## ExpandThisSection
##
## Stores information about a parsed inspector section,
## including the object type, category, group, and its control.
## Provides unique keys for group and category matching.

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
