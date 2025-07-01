class_name ExpandThisInspector
extends EditorInspectorPlugin

const GLOBAL_ON = preload("res://addons/expand_this/icons/global_on.svg")
const GLOBAL_OFF = preload("res://addons/expand_this/icons/global_off.svg")
const CATEGORY_ON = preload("res://addons/expand_this/icons/category_on.svg")
const CATEGORY_OFF = preload("res://addons/expand_this/icons/category_off.svg")
const OVERRIDDEN = preload("res://addons/expand_this/icons/overridden.svg")

const KEY_SEPARATOR: String = "/" # for EditorInspectorSections
#var _object_properties_popupmenu: PopupMenu = null
#var _expand_all_menu_item_id: int = -1

#var _editor_theme: Theme
var _prefs: ConfigFile
var _inspector_dock: Control
var _inspector: EditorInspector
var _auto_expand_section: CollapsibleContainer
var _parsed_groups: Dictionary[String, ExpandThisSection]
var _inspector_sections: Dictionary[String, Control]
var _current_category: String


func _init(prefs: ConfigFile, inspector_dock: Control, auto_expand_section: Control) -> void:
	_prefs = prefs
	_inspector_dock = inspector_dock
	_auto_expand_section = auto_expand_section
	
	for signal_info in _inspector_dock.get_signal_list():
		print(signal_info)
	
	## get editor theme
	#_editor_theme = EditorInterface.get_editor_theme()
	
	# detect inspector selection change
	EditorInterface.get_selection().selection_changed.connect(_on_selection_changed)
	
	_inspector = EditorInterface.get_inspector()
	_inspector.property_edited.connect(_on_property_edited)


func _can_handle(object):
	# handle only Node and Resource objects and their derivatives
	prints("can handle object:", object.get_class())
	return object is Node or object is Resource #or object.get_class() == "MultiNodeEdit"


func _parse_begin(object: Object):
	# set current category to the object being parsed
	_current_category = object.get_class()
	print("========== PARSE BEGIN ==========")


func _parse_category(object: Object, category: String) -> void:
	prints("CATEGORY:", object.get_class(), category)
	_current_category = category


func _parse_group(object: Object, group: String) -> void:
	var section := ExpandThisSection.new(object.get_class(), _current_category, group)
	_parsed_groups[group] = section
	prints("GROUP:", object.get_class(),"-", group)


func _parse_end(object: Object) -> void:
	print("========== PARSE END ==========")

	# find EditorInspectorSection controls
	_inspector_sections = _find_sections(_inspector_dock)
	#for section: String in inspector_sections.keys():
		#print("inspector section:", section)

	# ensure group containers size matches groups size else something went wrong
	if _parsed_groups.size() != _inspector_sections.size():
		push_warning("Error parsing sections, cannot match parsed groups to sections")
		return

	# build auto expand section content
	var container := VBoxContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# used to control adding a label for each category
	var last_category: String
	
	# iterate the inspector_sections for consistent UI order
	for key in _inspector_sections.keys():
		var section := _parsed_groups.get(key, null)
		if section == null:
			continue # skip if no matching parsed group, should NOT happen!
		
		# set ExpandThisSection control property
		_parsed_groups[key].control = _inspector_sections[key]
		
		# get auto expand states
		var states: Dictionary[String, bool] = _get_auto_expand_states(section)
		
		# add a category label if this section has a different category
		if section.category != last_category:
			last_category = section.category

			var icon = EditorInterface.get_editor_theme().get_icon(section.category, "EditorIcons")

			var header: PanelContainer = _build_header(icon, section.category)
			container.add_child(header)

		# add an hbox container for each section
		var row := HBoxContainer.new()

		# add global icon button
		var global_button = Button.new()
		global_button.toggle_mode = true
		global_button.icon = GLOBAL_OFF
		global_button.flat = true
		global_button.tooltip_text = "Auto Expand all %s groups" % section.group
		global_button.focus_mode = Control.FOCUS_NONE
		global_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		global_button.toggled.connect(_on_global_toggled.bind(global_button, section))
		global_button.button_pressed = states.global
		row.add_child(global_button)

		# add category icon button
		var category_button = Button.new()
		category_button.toggle_mode = true
		category_button.icon = CATEGORY_OFF
		category_button.flat = true
		category_button.tooltip_text = "Auto Expand all %s groups in %s category" % [section.group, section.category]
		category_button.focus_mode = Control.FOCUS_NONE
		category_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		category_button.toggled.connect(_on_category_toggled.bind(category_button, section))
		category_button.button_pressed = states.category
		row.add_child(category_button)
		
		# add group check button
		var check_button = CheckButton.new()
		check_button.toggle_mode = true
		check_button.text = section.group
		check_button.tooltip_text = \
			"Auto Expand %s in %s nodes" % [section.group, section.object]
		check_button.toggled.connect(_on_group_toggled.bind(section))
		check_button.button_pressed = states.group
		row.add_child(check_button)

		# add override button if a group rule exists
		# along with a global or category rule
		if states.override:
			var override_button = Button.new()
			override_button.icon = OVERRIDDEN
			override_button.tooltip_text = "Remove group override rule"
			override_button.flat = true
			override_button.pressed.connect(_on_override_removed.bind(override_button, section))
			row.add_child(override_button)

		# add row to container
		container.add_child(row)

	_auto_expand_section.set_content(container)


func _on_selection_changed() -> void:
	print("selection changed in scene tree")
	_parsed_groups.clear()
	var nodes := EditorInterface.get_selection().get_selected_nodes()
	prints("selected nodes:", nodes)
	if nodes.is_empty():
		# no selection so update UI to reflect this
		_auto_expand_section.display_message("Please select a node")
		return
	
	if nodes.size() > 1:
		# multi node edit feature is not available yet
		_auto_expand_section.display_message("Sorry, but multi node edit feature is not available yet!")


func _print_container_children(node: Node, indent: int = 0) -> void:
	if not node.get_child_count():
		return
	for child in node.get_children(true):
		prints(" ".repeat(indent), child.name, child)
		_print_container_children(child, indent + 4)


func _find_sections(node: Node, key: String = "") -> Dictionary[String, Control]:
	var result: Dictionary[String, Control] = {}
	for child in node.get_children():
		if child.get_class() == "EditorInspectorSection":
			result[key + child.tooltip_text] = child
			result.merge(_find_sections(child, key + child.tooltip_text + KEY_SEPARATOR))
		else:
			result.merge(_find_sections(child, key))
	return result


func _set_group_expand(section: ExpandThisSection, enabled: bool) -> void:
	_prefs.set_value("groups", section.group_key, enabled)

	var err: Error = _prefs.save(ExpandThis.global_config_path)
	if err != OK:
		push_warning("Error saving Expand This config: %s" % error_string(err))


func _set_category_expand(section: ExpandThisSection, enabled: bool) -> void:
	var key: String = section.category_key
	if enabled:
		_prefs.set_value("categories", key, enabled)
	else:
		_prefs.erase_section_key("categories", key)

	var err: Error = _prefs.save(ExpandThis.global_config_path)
	if err != OK:
		push_warning("Error saving Expand This config: %s" % error_string(err))


func _set_global_expand(section: ExpandThisSection, enabled: bool) -> void:
	var key: String = section.group
	if enabled:
		_prefs.set_value("global", section.group, enabled)
	else:
		_prefs.erase_section_key("global", key)

	var err: Error = _prefs.save(ExpandThis.global_config_path)
	if err != OK:
		push_warning("Error saving Expand This config: %s" % error_string(err))


func _get_auto_expand_states(section: ExpandThisSection) -> Dictionary[String, bool]:
	var states: Dictionary[String, bool] = {
		"global": false,
		"category": false,
		"group": false,
		"override": false
	}

	# Check global
	if _prefs.has_section_key("global", section.group):
		states.global = true

	# Check category
	if _prefs.has_section_key("categories", section.category_key):
		states.category = true

	# Calculate fallback
	var fallback := states.category or states.global

	# Check group setting
	var group_key := section.group_key
	if _prefs.has_section_key("groups", group_key):
		states.group = _prefs.get_value("groups", group_key)
		states.override = fallback
	else:
		states.group = fallback

	return states


func _on_group_toggled(pressed: bool, section: ExpandThisSection) -> void:
	if pressed:
		section.control.unfold()

	_set_group_expand(section, pressed)
	
	# check if this is an override, if so add the overrideen button


func _on_global_toggled(pressed: bool, button: Button, section: ExpandThisSection) -> void:
	button.icon = GLOBAL_ON if pressed else GLOBAL_OFF
	
	_set_global_expand(section, pressed)


func _on_category_toggled(pressed: bool, button: Button, section: ExpandThisSection) -> void:
	button.icon = CATEGORY_ON if pressed else CATEGORY_OFF

	_set_category_expand(section, pressed)


func _on_override_removed(button: Button, section: ExpandThisSection) -> void:
	_prefs.erase_section_key("groups", section.group_key)

	var err: Error = _prefs.save(ExpandThis.global_config_path)
	if err != OK:
		push_warning("Error saving Expand This config: %s" % error_string(err))
	
	# Remove the override button
	button.queue_free()


func _build_header(icon: Texture2D, title: String) -> PanelContainer:
	var header := PanelContainer.new()

	var sb = StyleBoxFlat.new()
	sb.bg_color = EditorInterface.get_editor_theme().get_color("prop_category", "Editor")
	header.add_theme_stylebox_override("panel", sb)
	
	var inner = HBoxContainer.new()
	inner.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var texture_rect = TextureRect.new()
	texture_rect.texture = icon
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED

	var label = Label.new()
	label.text = title
	
	inner.add_child(texture_rect)
	inner.add_child(label)
	header.add_child(inner)

	return header


func _on_property_edited(property: String) -> void:
	print("Property Edited:", property)
	var edited_object := _inspector.get_edited_object()

	print("edited object:", edited_object)
	var prop_value = edited_object.get(property)

	if prop_value == null:
		call_deferred("_refresh_sections_after_property_cleared")

func _refresh_sections_after_property_cleared() -> void:
	var new_sections: int = _find_sections(_inspector_dock).size()
	prints("new sections count:", new_sections)
	prints("existing sections count:", _inspector_sections.size())
