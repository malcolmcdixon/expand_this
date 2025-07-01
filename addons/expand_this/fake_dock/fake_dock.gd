@tool

class_name FakeDock
extends PanelContainer


## FakeDock
##
## A custom dock UI for the Expand This plugin.
## Provides a scrollable panel with adjustable height via drag handle,
## supports adding dynamic content and displaying fallback messages.

#========== SIGNALS ==========

signal height_changed(new_size: float)

#========== CONSTANTS ==========

const INSPECTOR_MIN_HEIGHT = 360.0

#========== EXPORT VARIABLES ==========

@export var min_height := 80.0

#========== ONREADY VARIABLES ==========

@onready var _drag_handle = %DragHandle
@onready var _scroll_area = %ScrollArea
@onready var _content: VBoxContainer = %ScrollContent
@onready var _drag_indicator: PanelContainer = %DragIndicator

#========== MEMBER VARIABLES ==========

var _dragging := false
var _inspector_dock: Control
var _max_height: float


#========== OVERRIDDEN VIRTUAL METHODS ==========

func _ready():
	_inspector_dock = get_parent()
	_inspector_dock.resized.connect(_set_max_height)

	# initialise the max scroll area height
	_set_max_height()
	
	_drag_handle.mouse_default_cursor_shape = Control.CURSOR_VSPLIT
	_drag_handle.gui_input.connect(_on_drag_handle_input)
	_drag_handle.mouse_entered.connect(func(): _drag_indicator.visible = true)
	_drag_handle.mouse_exited.connect(func(): if not _dragging: _drag_indicator.visible = false)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_dragging = false


#========== PUBLIC METHODS ==========
## Sets the dock content, replacing any existing children.
func set_content(content: Control) -> void:
	# clear and add new content
	clear_content()
	_content.add_child(content)


## Clears any content currently in the dock.
func clear_content() -> void:
	# remove existing content
	for child in _content.get_children():
		child.queue_free()



## Displays a centered message label in place of content.
func display_message(message: String) -> void:
	var label := Label.new()
	label.text = message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	set_content(label)


## Returns the current minimum height of the scroll area.
func get_min_height() -> float:
	return _scroll_area.custom_minimum_size.y


## Sets the dock height, clamped within allowed bounds.
func set_height(height: float) -> void:
	_set_custom_minimum_size(height)


#========== PRIVATE METHODS ==========

func _set_max_height() -> void:
	_max_height = _inspector_dock.size.y - INSPECTOR_MIN_HEIGHT


func _set_custom_minimum_size(height: float) -> void:
	_scroll_area.custom_minimum_size.y = clamp(
		height,
		min_height,
		_max_height
	)


#========== SIGNAL HANDLERS ==========

func _on_drag_handle_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
		if not _dragging:
			height_changed.emit(_scroll_area.custom_minimum_size.y)
			

	elif event is InputEventMouseMotion and _dragging:
		var delta = -event.relative.y
		_scroll_area.custom_minimum_size.y += delta
		_set_custom_minimum_size(_scroll_area.custom_minimum_size.y)
