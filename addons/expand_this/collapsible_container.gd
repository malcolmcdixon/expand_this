class_name CollapsibleContainer
extends MarginContainer

signal toggled(toggled: bool)

const CHEVRON_DOWN = preload("res://addons/expand_this/icons/chevron-down.svg")
const CHEVRON_RIGHT = preload("res://addons/expand_this/icons/chevron-right.svg")

@export var title: String:
	set(value):
		title = value
		_toggle_button.text = title

@export var icon_open: Texture = CHEVRON_DOWN
@export var icon_closed: Texture = CHEVRON_RIGHT

var _toggle_button: Button
var _content: VBoxContainer


func _init(title: String = "Section") -> void:
	add_theme_constant_override("margin_top", 6)
	add_theme_constant_override("margin_bottom", 6)
	add_theme_constant_override("margin_left", 6)
	add_theme_constant_override("margin_right", 6)
	
	var container := VBoxContainer.new()
	add_child(container)
	
	var panel := PanelContainer.new()
	
	_toggle_button = Button.new()
	_toggle_button.icon = icon_closed
	_toggle_button.text = title
	_toggle_button.text_overrun_behavior = TextServer.OVERRUN_TRIM_CHAR
	_toggle_button.flat = true
	_toggle_button.focus_mode = Control.FOCUS_NONE
	_toggle_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_toggle_button.toggle_mode = true
	_toggle_button.toggled.connect(_on_toggle)
	
	panel.add_child(_toggle_button)
	container.add_child(panel)
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = EditorInterface.get_editor_theme().get_color("prop_category", "Editor")
	panel.add_theme_stylebox_override("panel", sb)

	_content = VBoxContainer.new()
	container.add_child(_content)
	_content.visible = false


func _on_toggle(toggled: bool) -> void:
	_content.visible = toggled
	_toggle_button.icon = icon_open if toggled else icon_closed
	self.toggled.emit(toggled)


func set_content(content: Control) -> void:
	# clear and add new content
	clear_content()
	_content.add_child(content)


func clear_content() -> void:
	# remove existing content
	for child in _content.get_children():
		child.queue_free()


func display_message(message: String) -> void:
	var label := Label.new()
	label.text = message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	set_content(label)
