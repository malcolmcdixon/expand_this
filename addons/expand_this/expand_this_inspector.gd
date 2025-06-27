class_name ExpandThisInspector
extends EditorInspectorPlugin

#const CHEVRON_DOWN = preload("res://addons/expand_this/icons/chevron-down.svg")
#const CHEVRON_RIGHT = preload("res://addons/expand_this/icons/chevron-right.svg")
const GLOBAL_ON = preload("res://addons/expand_this/icons/global_on.svg")
const GLOBAL_OFF = preload("res://addons/expand_this/icons/global_off.svg")

var _object_properties_popupmenu: PopupMenu = null
var _expand_all_menu_item_id: int = -1

var _prefs: ConfigFile
var _inspector_dock: Control
var _auto_expand_section: CollapsibleContainer
var _groups: Array[String]
var _sections: Dictionary[String, Control]


func _init(prefs: ConfigFile, inspector_dock: Control, auto_expand_section: Control) -> void:
	_prefs = prefs
	_inspector_dock = inspector_dock
	_auto_expand_section = auto_expand_section


func _can_handle(object):
	# handle only Node and Resource objects and their derivatives
	return object is Node or object is Resource


func _parse_begin(object: Object):
	# clear groups and sections arrays
	_groups.clear()
	_sections.clear()
	
	# defer the popupmenu search if we don't have it or it's invalid
	#if not _object_properties_popupmenu or not is_instance_valid(_object_properties_popupmenu):
		#call_deferred("_deferred_find_inspector_dock")
		#_deferred_find_inspector_dock()	

	#var auto_expand: bool = _get_auto_expand(object)
	#_add_auto_expand_ui(object, auto_expand)
#
	#if auto_expand:
		#call_deferred("_expand_all")


func _parse_group(object: Object, group: String) -> void:
	_groups.append(group)


func _parse_end(object: Object) -> void:
	
	#var base := EditorInterface.get_base_control()
	#prints("Base:", base)
	#if base:
		#var theme := base.get_theme()
		#prints("Theme:", theme)
	#else:
		#push_warning("Base control is null in _parse_end")
		

	# find group controls
	var group_containers: Array = _find_sections(_inspector_dock)

	# ensure group containers size matches groups size else something went wrong
	if _groups.size() != group_containers.size():
		push_warning("Error parsing sections, cannot match groups to sections")
		return
	
	# build sections dictionary
	for index: int in range(_groups.size()):
		_sections[_groups[index]] = group_containers[index]
	
	# add a container control
	#var container := VBoxContainer.new()
	#var label := Label.new()
	#label.text = "Auto Expand Groups:"
	#container.add_child(label)
	
	var flow := FlowContainer.new()
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
	for section in _sections:
		var global_button = Button.new()
		global_button.toggle_mode = true
		global_button.icon = GLOBAL_OFF
		global_button.flat = true
		global_button.tooltip_text = "Auto Expand all %s groups" % section
		global_button.focus_mode = Control.FOCUS_NONE
		global_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		global_button.toggled.connect(_on_global_toggled.bind(global_button, _sections[section]))
		flow.add_child(global_button)
		
		var check_button = CheckButton.new()
		check_button.toggle_mode = true
		check_button.text = section
		check_button.tooltip_text = \
			"Auto Expand %s in %s nodes" % [section, object.get_class()]
		check_button.toggled.connect(_on_group_toggled.bind(_sections[section]))
		#check_button.button_pressed = auto_expand_state
		flow.add_child(check_button)

	_auto_expand_section.set_content(flow)
	#var section: Control = _add_collapsible_section("Auto Expand", flow)
	#add_custom_control(section)
	#_inspector_dock.add_child(section)


#func _add_collapsible_section(title: String, content: Control, top_margin: int = 0) -> MarginContainer:
	#var section := MarginContainer.new()
	#section.add_theme_constant_override("margin_top", top_margin)
#
	#var container := VBoxContainer.new()
	#section.add_child(container)
#
	## Separator
	##var sep := HSeparator.new()
	##container.add_child(sep)
#
	#var toggle_button := Button.new()
	#toggle_button.icon = CHEVRON_DOWN
	#toggle_button.text = title
	#toggle_button.flat = true
	#toggle_button.focus_mode = Control.FOCUS_NONE
	#toggle_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	#toggle_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	#toggle_button.custom_minimum_size = Vector2(0, 24)
#
	#var inner := VBoxContainer.new()
	#inner.add_child(content)
#
	#toggle_button.pressed.connect(func():
		#inner.visible = !inner.visible
		#toggle_button.icon = CHEVRON_DOWN if inner.visible else CHEVRON_RIGHT
	#)
#
	#container.add_child(toggle_button)
	#container.add_child(inner)
#
	#return section


func _print_container_children(node: Node, indent: int = 0) -> void:
	if not node.get_child_count():
		return
	for child in node.get_children(true):
		prints(" ".repeat(indent), child.name, child)
		_print_container_children(child, indent + 4)


func _find_sections(node: Node) -> Array[Control]:
	var result: Array[Control] = []
	for child in node.get_children():
		if child.get_class() == "EditorInspectorSection":
			result.append(child)
		result += _find_sections(child)
	return result


#func _deferred_find_inspector_dock() -> void:
	#_inspector_dock = _find_inspector_dock(EditorInterface.get_base_control())
	#
	#if not _inspector_dock:
		#push_warning("Inspector Dock not found.")
		#return
	
	#_print_container_children(_inspector_dock)
	#var result: Array = _find_popupmenu_with_item(_inspector_dock, "Expand All")
	#_object_properties_popupmenu = result[0]
	#_expand_all_menu_item_id = result[1]
	#
	#if not _object_properties_popupmenu:
		#push_warning("Expand All PopupMenu not found.")


#func _find_inspector_dock(node: Object) -> Node:
	#for child in node.get_children(true):
		#if child.get_class() == "InspectorDock":
			#return child
		#var result = _find_inspector_dock(child)
		#if result != null:
			#return result
	#return null


#func _find_popupmenu_with_item(node: Object, item_text: String) -> Array:
	#for child in node.get_children(true):
		#if child is PopupMenu:
			#for i in range(child.item_count):
				#if child.get_item_text(i) == item_text:
					#return [child, child.get_item_id(i)]
		#var result = _find_popupmenu_with_item(child, item_text)
		#if result[0] != null:
			#return result
	#return [null, -1]

#
#func _add_auto_expand_ui(object: Object, auto_expand_state: bool) -> void:
	#var container := HBoxContainer.new()
	#container.custom_minimum_size = Vector2(0, 20)
	#
	#var check_button = CheckButton.new()
	#check_button.toggle_mode = true
	#check_button.text = "Auto Expand"
	#check_button.tooltip_text = "Automatically expand all %s" % object.get_class()
	#check_button.toggled.connect(_on_toggle_pressed.bind(object))
	#check_button.button_pressed = auto_expand_state
	#container.add_child(check_button)
	#
	#add_custom_control(container)


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

func _on_group_toggled(pressed: bool, section: Control) -> void:
	if pressed:
		section.unfold()
	else:
		section.fold()
	
	#_set_auto_expand_enabled(object, pressed)


func _on_global_toggled(pressed: bool, button: Button, section: Control) -> void:
	button.icon = GLOBAL_ON if pressed else GLOBAL_OFF
