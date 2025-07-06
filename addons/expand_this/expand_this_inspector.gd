class_name ExpandThisInspector
extends EditorInspectorPlugin


## ExpandThisInspector.gd
##
## This plugin class integrates with the Godot EditorInspector to provide
## custom "Auto Expand" controls for inspector categories and groups.
##
## Core Responsibilities:
## - Walks the Inspector’s node tree to identify sections and their hierarchy.
## - Uses ExpandThisSection and ExpandThisUIRow to deduplicate and manage
##   unique category/group combinations.
## - Builds a custom UI with toggle buttons to control auto-expansion rules.
## - Persists user preferences in a ConfigFile and updates them live.
## - Reacts to Inspector changes (node selection, sub-resource editing)
##   and refreshes the UI dynamically.
##
## Connected Signals:
## - Monitors EditorInspector’s edited_object_changed to rebuild the UI.
## - Connects dynamically to EditorPropertyResource and EditorInspector nodes
##   to detect when sub-resources are opened or closed.
##
## Main Methods:
## - _on_edited_object_changed(): Entry point to refresh when selection changes.
## - _walk_categories_and_sections(): Recursively parses Inspector sections.
## - _build_ui(): Generates the custom dock UI based on current rows.
## - _set_*() & _get_auto_expand_states(): Manage and query preference states.
##
## Dependencies:
## - ExpandThisSection: Represents a single inspector section, its hierarchy,
##   and supports unfolding.
## - ExpandThisUIRow: Deduplicates sections into unique rows, holds buttons.


#========== CONSTANTS ==========

const GLOBAL_ON = preload("res://addons/expand_this/icons/global_on.svg")
const GLOBAL_OFF = preload("res://addons/expand_this/icons/global_off.svg")
const OVERRIDDEN = preload("res://addons/expand_this/icons/overridden.svg")
const RESOURCE = preload("res://addons/expand_this/icons/resource.svg")

#========== MEMBER VARIABLES ==========

var _prefs: ConfigFile
var _inspector_dock: Control
var _inspector: EditorInspector
var _auto_expand_section: CollapsibleContainer
var _current_category: String
var _edited_object: Object


#========== OVERRIDDEN VIRTUAL METHODS ==========

func _init(prefs: ConfigFile, auto_expand_section: Control) -> void:
	_prefs = prefs
	_auto_expand_section = auto_expand_section

	# get a reference to the inspector dock
	_inspector_dock = EditorInterface.get_inspector().get_parent()
	
	_inspector = EditorInterface.get_inspector()
	_inspector.edited_object_changed.connect(_on_edited_object_changed)
	
	call_deferred("_on_edited_object_changed")


#========== PRIVATE METHODS ==========

func _walk_categories_and_sections(
	node: Node,
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
			# skip sections without a tooltip, e.g. Bones in Skeleton3D
			if group == "":
				continue
				
			var section := ExpandThisSection.new()
			section.category = current_category
			section.group = group
			section.control = child
			section.parent = parent_section
			
			# create unique ExpandThisRow for creating UI
			ExpandThisUIRow.create(section)

			# This section might have child sections, recurse with this as parent
			_walk_categories_and_sections(child, current_category, section)
			continue

		# Generic recurse for other children
		_walk_categories_and_sections(child, current_category, parent_section)


func _build_ui() -> void:
	# build auto expand section content
	var container := VBoxContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# used to control adding a label for each category
	var last_category: String
	
	# iterate the inspector_sections for consistent UI order
	for ui_row in ExpandThisUIRow.get_rows():
		# get auto expand states
		var states: Dictionary[String, bool] = _get_auto_expand_states(ui_row)
		
		# add a category label if this section has a different category
		if ui_row.category != last_category:
			last_category = ui_row.category

			var icon: Texture2D
			var theme = EditorInterface.get_editor_theme()
			if theme.has_icon(ui_row.category, "EditorIcons"):
				icon = theme.get_icon(ui_row.category, "EditorIcons")
			else:
				icon = RESOURCE

			var header: PanelContainer = _build_header(icon, ui_row.category)
			container.add_child(header)

		# add an hbox container for each section
		var row := HBoxContainer.new()

		# add global icon button
		var global_button = _build_button(
			true,
			GLOBAL_OFF,
			"Auto Expand all %s groups" % ui_row.group,
		)
		global_button.toggled.connect(_on_global_toggled.bind(global_button, ui_row))
		row.add_child(global_button)
		ui_row.global_button = global_button

		# add group button
		var check_button = CheckButton.new()
		check_button.text = ui_row.group
		check_button.tooltip_text = \
			"Auto Expand %s in %s nodes" % [ui_row.group, ui_row.category]
		check_button.toggled.connect(_on_group_toggled.bind(ui_row))
		row.add_child(check_button)
		ui_row.group_button = check_button

		_update_ui_row(ui_row)

		# add row to container
		container.add_child(row)

	_auto_expand_section.set_content(container)


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


func _add_override_button(ui_row: ExpandThisUIRow) -> void:
	# ensure button not added if already exists
	if ui_row.override_button:
		return

	var override_button = _build_button(
		false,
		OVERRIDDEN,
		"Remove group override rule"
	)
	override_button.pressed.connect(_on_override_removed.bind(override_button, ui_row))
	ui_row.group_button.add_sibling(override_button)
	ui_row.override_button = override_button


func _update_ui_row(ui_row: ExpandThisUIRow) -> void:
	var states := _get_auto_expand_states(ui_row)

	if ui_row.global_button:
		ui_row.global_button.icon = GLOBAL_ON if states.global else GLOBAL_OFF
		ui_row.global_button.set_pressed_no_signal(states.global)

	if ui_row.group_button:
		ui_row.group_button.set_pressed_no_signal(states.group)

	if states.group:
		for section in ui_row.sections:
			section.unfold()

	if states.override and not ui_row.override_button:
		_add_override_button(ui_row)
	elif not states.override and ui_row.override_button:
		ui_row.override_button.queue_free()
		ui_row.override_button = null


func _rebuild_ui() -> void:
	ExpandThisUIRow.clear()

	_walk_categories_and_sections(_inspector, _edited_object.get_class())
	
	_build_ui()


func _get_auto_expand_states(ui_row: ExpandThisUIRow) -> Dictionary[String, bool]:
	var states: Dictionary[String, bool] = {
		"global": false,
		"group": false,
		"override": false
	}

	# Check global
	if _prefs.has_section_key("global", ui_row.group):
		states.global = true

	# Check group setting
	if _prefs.has_section_key("groups", ui_row.key):
		states.group = _prefs.get_value("groups", ui_row.key)
		states.override = states.global
	else:
		states.group = states.global

	return states


func _set_global_rule(ui_row: ExpandThisUIRow, enabled: bool) -> void:
	var key: String = ui_row.group
	if enabled:
		_prefs.set_value("global", key, enabled)
	else:
		_prefs.erase_section_key("global", key)

	ExpandThis.save_prefs()


func _set_group_rule(ui_row: ExpandThisUIRow, enabled: bool) -> void:
	_prefs.set_value("groups", ui_row.key, enabled)

	ExpandThis.save_prefs()


#========== SIGNAL HANDLERS ==========

func _on_edited_object_changed() -> void:
	_edited_object = _inspector.get_edited_object()
	
	if _edited_object == null:
		# no selection so update UI to reflect this
		_auto_expand_section.display_message("Please select a node")
		return

	if _edited_object.get_class() == "MultiNodeEdit":
		# multi node edit feature is not available yet
		_auto_expand_section.display_message("Sorry, but multi node edit feature is not available yet!")
		return

	call_deferred("_rebuild_ui")


func _on_resource_child_entered(child: Node) -> void:
	if child is EditorInspector:
		# Sub-inspector opened so rebuild UI
		call_deferred("_rebuild_ui")

		# connect to Inspector's exit signal to know when it closes
		child.tree_exited.connect(_on_resource_tree_exited)


func _on_resource_tree_exited() -> void:
	# Sub-inspector closed so rebuild UI
	call_deferred("_rebuild_ui")


func _on_global_toggled(pressed: bool, button: Button, ui_row: ExpandThisUIRow) -> void:
	_set_global_rule(ui_row, pressed)
	_update_ui_row(ui_row)


func _on_group_toggled(pressed: bool, ui_row: ExpandThisUIRow) -> void:
	if ui_row.sections.any(func(s): return not is_instance_valid(s.control)):
		call_deferred("_rebuild_ui")
		# Find the matching row again
		for new_row in ExpandThisUIRow.get_rows():
			if new_row.key == ui_row.key:
				ui_row = new_row

	_set_group_rule(ui_row, pressed)
	_update_ui_row(ui_row)


func _on_override_removed(button: Button, ui_row: ExpandThisUIRow) -> void:
	_prefs.erase_section_key("groups", ui_row.key)
	ExpandThis.save_prefs()
	_update_ui_row(ui_row)
