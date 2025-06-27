@tool
class_name ExpandThis
extends EditorPlugin


const CHEVRON_DOWN = preload("res://addons/expand_this/icons/chevron-down.svg")
const CHEVRON_RIGHT = preload("res://addons/expand_this/icons/chevron-right.svg")

static var global_config_path: String = get_global_config_path()

var inspector_plugin: ExpandThisInspector
var _prefs := ConfigFile.new()
var _inspector_dock: Control


func _enter_tree():
	# load saved preferences
	_prefs.load(global_config_path)
	# find the inspector dock via a recursive search
	_inspector_dock = _find_inspector_dock(EditorInterface.get_base_control())
	# add a collapsible section at the bottom of the inspector dock
	if is_instance_valid(_inspector_dock):
		var auto_expand_section: Control = CollapsibleContainer.new("Auto Expand")
		_inspector_dock.add_child(auto_expand_section)
		inspector_plugin = ExpandThisInspector.new(_prefs, _inspector_dock, auto_expand_section)
		add_inspector_plugin(inspector_plugin)
	else:
		push_error("Cannot find the Inspector Dock, Auto Expand has encountered a critical error.")


func _exit_tree():
	remove_inspector_plugin(inspector_plugin)


static func get_global_config_path() -> String:
	var os_name := OS.get_name()
	match os_name:
		"Windows":
			return OS.get_environment("APPDATA") + "/Godot/expand_this.cfg"
		"macOS":
			return OS.get_environment("HOME") + "/Library/Application Support/Godot/expand_this.cfg"
		"X11":
			return OS.get_environment("HOME") + "/.local/share/godot/expand_this.cfg"
		_:
			push_warning("Unsupported OS — falling back to user://")
			return "user://expand_this.cfg"


func _find_inspector_dock(node: Object) -> Node:
	for child in node.get_children(true):
		if child.get_class() == "InspectorDock":
			return child
		var result = _find_inspector_dock(child)
		if result:
			return result
	return null


#func _add_collapsible_section(title: String, content: Control, top_margin: int = 0) -> MarginContainer:
	#var section := MarginContainer.new()
	#section.add_theme_constant_override("margin_top", top_margin)
#
	#var container := VBoxContainer.new()
	#section.add_child(container)
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
