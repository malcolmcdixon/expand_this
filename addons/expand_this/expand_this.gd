@tool
class_name ExpandThis
extends EditorPlugin

var inspector_plugin: ExpandThisInspector
var _prefs := ConfigFile.new()


func _enter_tree():
	_prefs.load("user://expand_this.cfg")
	inspector_plugin = ExpandThisInspector.new(_prefs)
	add_inspector_plugin(inspector_plugin)


func _exit_tree():
	remove_inspector_plugin(inspector_plugin)
