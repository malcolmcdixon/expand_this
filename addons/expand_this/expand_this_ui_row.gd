class_name ExpandThisUIRow


#========== CONSTANTS ==========

const KEY_SEPARATOR: String = "|"

#========== STATIC VARIABLES ==========

static var _rows: Dictionary[String, ExpandThisUIRow]= {}
static var _allow_creation: bool = false

#========== MEMBER VARIABLES ==========

var category: String
var group: String
var sections: Array[ExpandThisSection] = []
var global_button: Button
var group_button: Button
var override_button: Button

var key: String:
	get:
		return "%s%s%s" % [category, KEY_SEPARATOR, group]


func _init(_category: String, _group: String) -> void:
	if not _allow_creation:
		push_error("Use ExpandThisUIRow.create() instead of new()!")
		return

	category = _category
	group = _group


func _to_string() -> String:
	return "Category: %s, Group: %s, Sections: %s, Buttons: %s, %s, %s" % \
		[category, group, sections, global_button, group_button, override_button]


static func create(section: ExpandThisSection) -> ExpandThisUIRow:
	if _rows.has(section.key):
		_rows[section.key].sections.append(section)
		return _rows[section.key]

	_allow_creation = true
	var row = ExpandThisUIRow.new(section.category, section.group)
	_allow_creation = false
	row.sections.append(section)
	_rows[section.key] = row
	return row


static func get_rows() -> Array:
	return _rows.values()


static func clear() -> void:
	_rows.clear()
