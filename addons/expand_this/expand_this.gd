@tool
class_name ExpandThis
extends EditorPlugin


static var global_config_path: String = get_global_config_path()
var inspector_plugin: ExpandThisInspector
var _prefs := ConfigFile.new()


func _enter_tree():
	_prefs.load(global_config_path)
	inspector_plugin = ExpandThisInspector.new(_prefs)
	add_inspector_plugin(inspector_plugin)


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
