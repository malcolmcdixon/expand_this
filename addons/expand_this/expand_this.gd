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

#========== MEMBER VARIABLES ==========

var _inspector_plugin: ExpandThisInspector
static var _global_config_path: String
static var _prefs := ConfigFile.new()
var _dock: Control
var _opened_height: float = 300.0
#var _settings: EditorSettings:
	#get:
		#return EditorInterface.get_editor_settings()


#========== OVERRIDDEN VIRTUAL METHODS ==========

func _enter_tree():
	_global_config_path = _get_global_config_path()
	# load saved preferences
	_prefs.load(_global_config_path)

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
	
	# get last dock height from settings section in Config File
	if _prefs.has_section_key("settings", "dock_height"):
		_opened_height = _prefs.get_value("settings", "dock_height")
	 	
	auto_expand_section.toggled.connect(
		func(expanded):
			if expanded:
				_dock.set_height(_opened_height)
			else:
				_dock.set_height(_dock.min_height)
	)
	
	_dock.height_changed.connect(_on_dock_height_changed)

	_dock.call_deferred("set_content", auto_expand_section)
	add_control_to_container(CONTAINER_INSPECTOR_BOTTOM, _dock)
	
	_inspector_plugin = ExpandThisInspector.new(_prefs, auto_expand_section)
	add_inspector_plugin(_inspector_plugin)


func _exit_tree():
	remove_control_from_container(CONTAINER_INSPECTOR_BOTTOM, _dock)
	_dock.free()
	remove_inspector_plugin(_inspector_plugin)


#========== PUBLIC METHODS ==========

static func save_prefs() -> void:
	var err: Error = _prefs.save(_global_config_path)
	if err != OK:
		push_warning("Error saving Expand This config: %s" % error_string(err))


#========== PRIVATE METHODS ==========

static func _get_global_config_path() -> String:
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


#========== SIGNAL HANDLERS ==========

func _on_dock_height_changed(size: float) -> void:
	_opened_height = size
	
	# save user's last preferred height
	_prefs.set_value("settings", "dock_height", size)
	save_prefs()
