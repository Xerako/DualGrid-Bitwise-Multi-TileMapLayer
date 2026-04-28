class_name Game
extends Node2D
## Game contains a static camera, some UI elements, and the DualGridStack.

## Ref to mouse UI object to have it track the mouse's global position.
@onready var mouse_ui: Control = $Mouse
## Display mouse map position and hovered tile type.
@onready var mouse_label: Label = $Mouse/MarginContainer/VBoxContainer/MarginContainer/MouseLabel

## Ref to the DemoLoader responsible for handling which DualGridStack demo
## is actively loaded.
@onready var demo_loader: DemoLoader = $DemoLoader

## Ref to our DualGrid stack through the demo loader.
var dgs: DualGridStack:
	get:
		return demo_loader.dgs

## Color for the drawn rect at the mouse's hovered cell.
var hover_color: Color = Color.WHITE

## Global mouse position.
var mouse_pos: Vector2
## Map position translated from global mouse position.
var mouse_map_pos: Vector2i
## Track the last known mouse map position for smarter cell setting.
var last_mouse_map_pos: Variant

func _ready() -> void:
	hover_color.a = 0.5

func _process(_delta: float) -> void:
	_update_mouse()
	_handle_input()
	
	# set mouse UI to follow the global mouse position
	mouse_ui.global_position = mouse_pos + Vector2(8, 8)
	# set mouse map position and hovered cell text
	mouse_label.text = str(mouse_map_pos, "\n", dgs.get_tile_type(mouse_map_pos))
	# this makes sure we're updating our manually drawn hovered cell rect
	queue_redraw()

## Update global and map positional variables for the mouse
func _update_mouse() -> void:
	mouse_pos = get_global_mouse_position()
	mouse_map_pos = dgs.local_to_map(mouse_pos)

## Capture user input for tile interaction
func _handle_input() -> void:
	# In each case, we allow an interaction event when the mouse has moved to 
	# a new cell or a new click event has been detected within the same cell.
	# This way, we can just hold down LMB or RMB and only issue cell 
	# changes when they'd be meaningful.
	
	if Input.is_action_pressed("lmb"):
		if last_mouse_map_pos == null || last_mouse_map_pos != mouse_map_pos:
			last_mouse_map_pos = mouse_map_pos
			# fill cell data bottom-up
			dgs.push_cell(mouse_map_pos)
	if Input.is_action_pressed("rmb"):
		if last_mouse_map_pos == null || last_mouse_map_pos != mouse_map_pos:
			last_mouse_map_pos = mouse_map_pos
			# erase cell data top-down
			dgs.pop_cell(mouse_map_pos)
	if Input.is_action_just_released("lmb") || Input.is_action_just_released("rmb"):
		last_mouse_map_pos = null

func _unhandled_key_input(event: InputEvent) -> void:
	# hitting ESC will close the game
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()

func _draw() -> void:
	# draw a rect at the mouse's current hovered tile cell
	draw_rect(Rect2(mouse_map_pos * dgs.tile_size, dgs.tile_size), hover_color, false, 2)
