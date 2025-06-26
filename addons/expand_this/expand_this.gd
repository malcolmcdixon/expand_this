@tool
class_name ExpandThis
extends EditorPlugin


const GLOBAL_CONFIG_PATH = "user://../editor_prefs/expand_this.cfg"

var inspector_plugin: ExpandThisInspector
var _prefs := ConfigFile.new()


func _enter_tree():
	_prefs.load(GLOBAL_CONFIG_PATH)
	inspector_plugin = ExpandThisInspector.new(_prefs)
	add_inspector_plugin(inspector_plugin)


func _exit_tree():
	remove_inspector_plugin(inspector_plugin)
