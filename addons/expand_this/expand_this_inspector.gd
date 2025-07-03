class_name ExpandThisInspector
extends EditorInspectorPlugin

const GLOBAL_ON = preload("res://addons/expand_this/icons/global_on.svg")
const GLOBAL_OFF = preload("res://addons/expand_this/icons/global_off.svg")
const CATEGORY_ON = preload("res://addons/expand_this/icons/category_on.svg")
const CATEGORY_OFF = preload("res://addons/expand_this/icons/category_off.svg")
const OVERRIDDEN = preload("res://addons/expand_this/icons/overridden.svg")

const KEY_SEPARATOR: String = "/" # for EditorInspectorSections

var _prefs: ConfigFile
var _inspector_dock: Control
var _inspector: EditorInspector
var _auto_expand_section: CollapsibleContainer
var _sections: Array[ExpandThisSection] = []
var _current_category: String
var _edited_object: Object


func _init(prefs: ConfigFile, auto_expand_section: Control) -> void:
	_prefs = prefs
	_auto_expand_section = auto_expand_section

	# get a reference to the inspector dock
	_inspector_dock = EditorInterface.get_inspector().get_parent()
	
	_inspector = EditorInterface.get_inspector()
	_inspector.edited_object_changed.connect(_on_edited_object_changed)
	_inspector.resource_selected.connect(_on_resource_selected)
	_inspector.property_edited.connect(_on_property_edited)


func _on_edited_object_changed() -> void:
	_edited_object = _inspector.get_edited_object()
	
	if _edited_object == null:
		# no selection so update UI to reflect this
		_auto_expand_section.display_message("Please select a node")
		return

	if _edited_object.get_class() == "MultiNodeEdit":
		# multi node edit feature is not available yet
		_auto_expand_section.display_message("Sorry, but multi node edit feature is not available yet!")

	_sections.clear()
	_walk_categories_and_sections(_inspector, _sections)

	#for s in sections:
		#print("Section: ", s.group, " | Category: ", s.category, " | Parent: ", s.parent)

	_new_build_ui(_sections)


func _on_resource_selected(resource: Resource, path: String) -> void:
	prints("resource selected:", resource, path)


#func _get_group_key(section: ExpandThisSection) -> String:
	#return "%s%s%s" % [_edited_object.get_class(), ExpandThisSection.KEY_SEPARATOR, section.key]


func _set_group_rule(section: ExpandThisSection, enabled: bool) -> void:
	_prefs.set_value("groups", section.key, enabled)

	_save_prefs()


#func _set_category_expand(section: ExpandThisSection, enabled: bool) -> void:
	#var key: String = section.category_key
	#if enabled:
		#_prefs.set_value("categories", key, enabled)
	#else:
		#_prefs.erase_section_key("categories", key)
#
	#_save_prefs()


func _set_global_rule(section: ExpandThisSection, enabled: bool) -> void:
	var key: String = section.group
	if enabled:
		_prefs.set_value("global", key, enabled)
	else:
		_prefs.erase_section_key("global", key)

	_save_prefs()


func _save_prefs() -> void:
	var err: Error = _prefs.save(ExpandThis.global_config_path)
	if err != OK:
		push_warning("Error saving Expand This config: %s" % error_string(err))


func _get_auto_expand_states(section: ExpandThisSection) -> Dictionary[String, bool]:
	var states: Dictionary[String, bool] = {
		"global": false,
		#"category": false,
		"group": false,
		"override": false
	}

	# Check global
	if _prefs.has_section_key("global", section.group):
		states.global = true

	## Check category
	#if _prefs.has_section_key("categories", section.key):
		#states.category = true

	# Calculate fallback
	#var fallback := states.category or states.global

	# Check group setting
	if _prefs.has_section_key("groups", section.key):
		states.group = _prefs.get_value("groups", section.key)
		states.override = states.global
	else:
		states.group = states.global

	return states


func _on_group_toggled(pressed: bool, section: ExpandThisSection) -> void:
	if pressed:
		section.unfold()

	_set_group_rule(section, pressed)


func _on_global_toggled(pressed: bool, button: Button, section: ExpandThisSection) -> void:
	button.icon = GLOBAL_ON if pressed else GLOBAL_OFF
	
	_set_global_rule(section, pressed)

	for s in _sections:
		if s.group == section.group:
			var states := _get_auto_expand_states(s)
			s.group_button.set_pressed_no_signal(states.group)
			if states.group:
				s.unfold()

			# add override button if required
			#TODO code to add ovveride button


#func _on_category_toggled(pressed: bool, button: Button, section: ExpandThisSection) -> void:
	#button.icon = CATEGORY_ON if pressed else CATEGORY_OFF
#
	#_set_category_expand(section, pressed)
	# get effective value and unfold if true


func _on_override_removed(button: Button, section: ExpandThisSection) -> void:
	_prefs.erase_section_key("groups", section.key)

	_save_prefs()
	
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


func _build_button(toggle: bool, icon: Texture2D, tooltip: String, state: bool) -> Button:
		var button = Button.new()
		button.toggle_mode = toggle
		button.icon = icon
		button.flat = true
		button.tooltip_text = tooltip
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		button.button_pressed = state
		
		return button


func _on_property_edited(property: String) -> void:
	var edited_object := _inspector.get_edited_object()

	var prop_value = edited_object.get(property)
	#if prop_value == null:
		#call_deferred("_refresh_sections_after_property_cleared")


#func _refresh_sections_after_property_cleared() -> void:
	#var new_sections: Dictionary[String, Control] = _find_sections(_inspector_dock)
	#if new_sections.size() != _inspector_sections.size():
		#_build_ui(new_sections)


func _find_categories_and_sections() -> Array:
	var result: Array = []

	var categories_and_sections := []
	var current_category: String = ""

	for child in _inspector.get_children():
		_walk_categories_and_sections(child, result, current_category)

	return result


func _walk_categories_and_sections(node: Node, sections: Array, current_category: String = "Unknown", parent_section: ExpandThisSection = null) -> void:
	for child in node.get_children():
		if child.get_class() == "EditorInspectorCategory":
			var tooltip: String = child.tooltip_text
			if tooltip.begins_with("class|"):
				var parts := tooltip.split("|")
				current_category = parts[1] if parts.size() > 1 else "Unknown"
			else:
				current_category = tooltip

		elif child.get_class() == "EditorInspectorSection":
			var group: String = child.tooltip_text

			var section := ExpandThisSection.new()
			section.category = current_category
			section.group = group
			section.control = child
			section.parent = parent_section

			sections.append(section)

			# This section might have child sections, recurse with this as parent
			_walk_categories_and_sections(child, sections, current_category, section)
			continue

		# Generic recurse for other children
		_walk_categories_and_sections(child, sections, current_category, parent_section)


func _new_build_ui(sections: Array[ExpandThisSection]) -> void:
	# build auto expand section content
	var container := VBoxContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# used to control adding a label for each category
	var last_category: String
	
	# iterate the inspector_sections for consistent UI order
	for section in sections:
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
		var global_button = _build_button(
			true,
			GLOBAL_OFF,
			"Auto Expand all %s groups" % section.group,
			states.global
		)
		global_button.toggled.connect(_on_global_toggled.bind(global_button, section))
		row.add_child(global_button)
		section.global_button = global_button

		# add category icon button
		#var category_button = _build_button(
			#true,
			#CATEGORY_OFF,
			#"Auto Expand all %s groups in %s category" % [section.group, section.category],
			#states.category
		#)
		#category_button.toggled.connect(_on_category_toggled.bind(category_button, section))
		#row.add_child(category_button)
		
		# add group button
		var check_button = CheckButton.new()
		check_button.toggle_mode = true
		check_button.text = section.group
		check_button.tooltip_text = \
			"Auto Expand %s in %s nodes" % [section.group, section.category]
		check_button.toggled.connect(_on_group_toggled.bind(section))
		check_button.button_pressed = states.group
		row.add_child(check_button)
		section.group_button = check_button

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
