class_name CollapsibleContainer
extends MarginContainer


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
	#section.add_theme_constant_override("margin_top", top_margin)
	var container := VBoxContainer.new()
	add_child(container)
	
	_toggle_button = Button.new()
	_toggle_button.icon = icon_closed
	_toggle_button.text = title
	_toggle_button.flat = true
	_toggle_button.focus_mode = Control.FOCUS_NONE
	_toggle_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_toggle_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_toggle_button.custom_minimum_size = Vector2(0, 24)
	_toggle_button.pressed.connect(_on_toggle)
	container.add_child(_toggle_button)

	_content = VBoxContainer.new()
	container.add_child(_content)
	_content.visible = false


func _on_toggle() -> void:
	_content.visible = !_content.visible
	_toggle_button.icon = icon_open if _content.visible else icon_closed


func set_content(content: Control) -> void:
	# remove existing content
	for child in _content.get_children():
		child.queue_free()
	# add new content
	_content.add_child(content)
