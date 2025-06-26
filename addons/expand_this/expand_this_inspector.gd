class_name ExpandThisInspector
extends EditorInspectorPlugin


var _object_properties_popupmenu: PopupMenu = null
var _expand_all_menu_item_id: int = -1

var _prefs: ConfigFile


func _init(prefs: ConfigFile) -> void:
	_prefs = prefs


func _can_handle(object):
	# handle only Node and its derivatives
	return object is Node or object is Resource


func _parse_begin(object: Object):
	# defer the popupmenu search if we don't have it or it's invalid
	if not _object_properties_popupmenu or not is_instance_valid(_object_properties_popupmenu):
			call_deferred("_deferred_find_inspector_dock")

	var auto_expand: bool = _get_auto_expand(object)
	_add_auto_expand_ui(object, auto_expand)

	if auto_expand:
		call_deferred("_expand_all")


func _deferred_find_inspector_dock() -> void:
	var dock: Node =  _find_inspector_dock(EditorInterface.get_base_control())
	
	if not dock:
		push_warning("Inspector Dock not found.")
		return
		
	var result: Array = _find_popupmenu_with_item(dock, "Expand All")
	_object_properties_popupmenu = result[0]
	_expand_all_menu_item_id = result[1]
	
	if not _object_properties_popupmenu:
		push_warning("Expand All PopupMenu not found.")


func _find_inspector_dock(node: Object) -> Node:
	for child in node.get_children(true):
		if child.get_class() == "InspectorDock":
			return child
		var result = _find_inspector_dock(child)
		if result != null:
			return result
	return null


func _find_popupmenu_with_item(node: Object, item_text: String) -> Array:
	for child in node.get_children(true):
		if child is PopupMenu:
			for i in range(child.item_count):
				if child.get_item_text(i) == item_text:
					return [child, child.get_item_id(i)]
		var result = _find_popupmenu_with_item(child, item_text)
		if result[0] != null:
			return result
	return [null, -1]


func _add_auto_expand_ui(object: Object, auto_expand_state: bool) -> void:
	var container := HBoxContainer.new()
	container.custom_minimum_size = Vector2(0, 20)
	
	var check_button = CheckButton.new()
	check_button.toggle_mode = true
	check_button.text = "Auto Expand"
	check_button.tooltip_text = "Automatically expand all %s" % object.get_class()
	check_button.toggled.connect(_on_toggle_pressed.bind(object))
	check_button.button_pressed = auto_expand_state
	container.add_child(check_button)
	
	add_custom_control(container)


func _get_auto_expand(object: Object) -> bool:
	return _prefs.has_section_key("objects", object.get_class())


func _set_auto_expand_enabled(object: Object, enabled: bool) -> void:
	var section := "objects"
	var key := object.get_class()
	if enabled:
		_prefs.set_value(section, key, true)  # value doesn't even matter
	else:
		_prefs.erase_section_key(section, key)

	var err: Error = _prefs.save(ExpandThis.global_config_path)
	if err != OK:
		push_warning("An error occurred saving the Expand This config file: %s" % error_string(err))

func _on_toggle_pressed(pressed: bool, object: Object) -> void:
	if pressed:
		_expand_all()
	
	_set_auto_expand_enabled(object, pressed)


func _expand_all() -> void:
	if _object_properties_popupmenu and \
		is_instance_valid(_object_properties_popupmenu) and \
			_expand_all_menu_item_id >= 0:
		_object_properties_popupmenu.id_pressed.emit(_expand_all_menu_item_id)
