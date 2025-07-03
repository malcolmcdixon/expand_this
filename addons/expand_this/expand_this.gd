@tool
class_name ExpandThis
extends EditorPlugin


## ExpandThis
##
## Main plugin script for the Expand This Godot Editor plugin.
## Handles initialization, UI dock setup, preference loading/saving,
## and integration with the inspector via an inspector plugin.
##
## Provides a dock at the bottom of the inspector for managing
## auto-expand preferences for EditorInspectorSections.

#========== CONSTANTS ==========

const CHEVRON_DOWN = preload("res://addons/expand_this/icons/chevron-down.svg")
const CHEVRON_RIGHT = preload("res://addons/expand_this/icons/chevron-right.svg")

const FAKE_DOCK = preload("res://addons/expand_this/fake_dock/fake_dock.tscn")

#========== STATIC VARIABLES ==========

static var global_config_path: String = get_global_config_path()

#========== MEMBER VARIABLES ==========

var _inspector_plugin: ExpandThisInspector
var _prefs := ConfigFile.new()
var _dock: Control
var _opened_height: float = 300.0


#========== STATIC METHODS ==========

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


#========== OVERRIDDEN VIRTUAL METHODS ==========

func _enter_tree():
	# load saved preferences
	_prefs.load(global_config_path)

	# add a collapsible section at the bottom of the inspector dock
	var auto_expand_section: Control = CollapsibleContainer.new("Auto Expand Preferences")
	
	_dock = FAKE_DOCK.instantiate()
	_dock.theme = EditorInterface.get_editor_theme()
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = _dock.theme.get_color("dark_color_1", "Editor")
	sb.set_corner_radius_all(
		EditorInterface.get_editor_settings()
			.get_setting("interface/theme/corner_radius"))
	_dock.add_theme_stylebox_override("panel", sb)
	
	auto_expand_section.toggled.connect(
		func(expanded):
			if expanded:
				_dock.set_height(_opened_height)
			else:
				_dock.set_height(_dock.min_height)
	)
	
	_dock.height_changed.connect(
		func(size):
			prints("dragged:", size)
			_opened_height = size
	)

	_dock.call_deferred("set_content", auto_expand_section)
	add_control_to_container(CONTAINER_INSPECTOR_BOTTOM, _dock)
	
	_inspector_plugin = ExpandThisInspector.new(_prefs, auto_expand_section)
	add_inspector_plugin(_inspector_plugin)


func _exit_tree():
	remove_control_from_container(CONTAINER_INSPECTOR_BOTTOM, _dock)
	_dock.free()
	remove_inspector_plugin(_inspector_plugin)
