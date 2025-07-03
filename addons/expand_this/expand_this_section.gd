class_name ExpandThisSection


## ExpandThisSection
##
## Stores information about a parsed inspector section,
## category, group, its control and parent control.
## Provides unique keys for group and category matching.

#========== CONSTANTS ==========

const KEY_SEPARATOR: String = "|"

#========== MEMBER VARIABLES ==========

var category: String
var group: String
var control: Control
var parent: ExpandThisSection
var global_button: Button
var group_button: Button

var key: String:
	get:
		return "%s%s%s" % [category, KEY_SEPARATOR, group]


#========== OVERRIDDEN VIRTUAL METHODS ==========

func _init(_category: String = "", _group: String = "") -> void:
	category = _category
	group = _group


#========== PUBLIC METHODS ==========

func unfold() -> void:
	var path: Array[Control] = []

	var current := self
	while current != null and current.control != null:
		path.append(current.control)
		current = current.parent

	# traverse back down to unfold in order
	path.reverse()
	for ctrl in path:
		if ctrl.has_method("unfold"):
			ctrl.unfold()
