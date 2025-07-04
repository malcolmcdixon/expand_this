class_name ExpandThisInspector
extends EditorInspectorPlugin

const GLOBAL_ON = preload("res://addons/expand_this/icons/global_on.svg")
const GLOBAL_OFF = preload("res://addons/expand_this/icons/global_off.svg")
const CATEGORY_ON = preload("res://addons/expand_this/icons/category_on.svg")
const CATEGORY_OFF = preload("res://addons/expand_this/icons/category_off.svg")
const OVERRIDDEN = preload("res://addons/expand_this/icons/overridden.svg")

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


func _on_edited_object_changed() -> void:
	_edited_object = _inspector.get_edited_object()
	
	if _edited_object == null:
		# no selection so update UI to reflect this
		_auto_expand_section.display_message("Please select a node")
		return

	prints("edited object:", _edited_object.get_class())

	if _edited_object.get_class() == "MultiNodeEdit":
		# multi node edit feature is not available yet
		_auto_expand_section.display_message("Sorry, but multi node edit feature is not available yet!")
		return

	_rebuild_ui()

	#_print_inspector_hierarchy(_inspector)


func _print_inspector_hierarchy(node: Node, indent: int = 0) -> void:
	var prefix := " ".repeat(indent * 2)
	var info: Variant
	if node is EditorInspector:
		info  = node.get_edited_object().get_class()
	else:
		info = node.get("tooltip_text")
		
	print("%s%s | %s" % [prefix, node.get_class(), info])

	for child in node.get_children():
		_print_inspector_hierarchy(child, indent + 1)


func _set_group_rule(section: ExpandThisSection, enabled: bool) -> void:
	_prefs.set_value("groups", section.key, enabled)

	ExpandThis.save_prefs()


func _set_global_rule(section: ExpandThisSection, enabled: bool) -> void:
	var key: String = section.group
	if enabled:
		_prefs.set_value("global", key, enabled)
	else:
		_prefs.erase_section_key("global", key)

	ExpandThis.save_prefs()


func _get_auto_expand_states(section: ExpandThisSection) -> Dictionary[String, bool]:
	var states: Dictionary[String, bool] = {
		"global": false,
		"group": false,
		"override": false
	}

	# Check global
	if _prefs.has_section_key("global", section.group):
		states.global = true

	# Check group setting
	if _prefs.has_section_key("groups", section.key):
		states.group = _prefs.get_value("groups", section.key)
		states.override = states.global
	else:
		states.group = states.global

	return states


func _on_group_toggled(pressed: bool, section: ExpandThisSection) -> void:
	_set_group_rule(section, pressed)
	_update_section_ui(section)


func _on_global_toggled(pressed: bool, button: Button, section: ExpandThisSection) -> void:
	_set_global_rule(section, pressed)

	for s in _sections:
		if s.group == section.group:
			_update_section_ui(s)


func _on_override_removed(button: Button, section: ExpandThisSection) -> void:
	_prefs.erase_section_key("groups", section.key)
	ExpandThis.save_prefs()
	_update_section_ui(section)


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


func _build_button(toggle: bool, icon: Texture2D, tooltip: String) -> Button:
		var button = Button.new()
		button.toggle_mode = toggle
		button.icon = icon
		button.flat = true
		button.tooltip_text = tooltip
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		return button


#func _on_property_edited(property: String) -> void:
	#print("on property edited")
	#call_deferred("_rebuild_ui")


func _rebuild_ui() -> void:
	print("===== REBUILDING UI =====")
	_sections.clear()
	_walk_categories_and_sections(_inspector, _sections, _edited_object.get_class())

	_build_ui(_sections)


func _walk_categories_and_sections(
	node: Node,
	sections: Array,
	current_category: String,
	parent_section: ExpandThisSection = null
) -> void:
	for child in node.get_children():
		if child.get_class() == "EditorPropertyResource":
			if not child.child_entered_tree.is_connected(_on_resource_child_entered):
				child.child_entered_tree.connect(_on_resource_child_entered)

		elif child.get_class() == "EditorInspector":
			current_category = child.get_edited_object().get_class()

		elif child.get_class() == "EditorInspectorCategory":
			var tooltip: String = child.tooltip_text
			if tooltip != "":
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


func _on_resource_child_entered(child: Node) -> void:
	if child is EditorInspector:
		print("Sub-inspector opened:", child)

		# Rebuild UI now if needed
		call_deferred("_rebuild_ui")

		# Optionally, connect to its exit to know when it closes
		child.tree_exited.connect(_on_resource_tree_exited)


func _on_resource_tree_exited() -> void:
	print("Sub-inspector closed")
	_rebuild_ui()


func _build_ui(sections: Array[ExpandThisSection]) -> void:
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
		)
		global_button.toggled.connect(_on_global_toggled.bind(global_button, section))
		row.add_child(global_button)
		section.global_button = global_button

		# add group button
		var check_button = CheckButton.new()
		check_button.text = section.group
		check_button.tooltip_text = \
			"Auto Expand %s in %s nodes" % [section.group, section.category]
		check_button.toggled.connect(_on_group_toggled.bind(section))
		row.add_child(check_button)
		section.group_button = check_button

		_update_section_ui(section)

		# add row to container
		container.add_child(row)

	_auto_expand_section.set_content(container)


func _add_override_button(section: ExpandThisSection) -> void:
	# ensure button not added if already exists
	if section.override_button:
		return

	var override_button = _build_button(
		false,
		OVERRIDDEN,
		"Remove group override rule"
	)
	override_button.pressed.connect(_on_override_removed.bind(override_button, section))
	section.group_button.add_sibling(override_button)
	section.override_button = override_button


func _update_section_ui(section: ExpandThisSection) -> void:
	var states := _get_auto_expand_states(section)

	if section.global_button:
		section.global_button.icon = GLOBAL_ON if states.global else GLOBAL_OFF
		section.global_button.set_pressed_no_signal(states.global)

	if section.group_button:
		section.group_button.set_pressed_no_signal(states.group)

	if states.group:
		section.unfold()

	if states.override and not section.override_button:
		_add_override_button(section)
	elif not states.override and section.override_button:
		section.override_button.queue_free()
		section.override_button = null
