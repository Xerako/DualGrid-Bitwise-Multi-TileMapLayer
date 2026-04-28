class_name DemoLoader
extends Node2D
## Switches and loads demo scenes.

## Ref to our DualGrid stack.
var dgs: DualGridStack

func _ready() -> void:
	_set_dgs_ref()

func _set_dgs_ref() -> void:
	dgs = get_child(0).dgs

func _load_demo(path: String) -> void:
	var demo: PackedScene = load(path)
	add_child(demo.instantiate())
	remove_child(get_child(0))
	_set_dgs_ref()

func _load_demo_flat() -> void:
	_load_demo("res://objects/demos/flat/demo_flat_dual_grid_stack.tscn")

func _load_demo_tall() -> void:
	_load_demo("res://objects/demos/tall/demo_tall_dual_grid_stack.tscn")

func _on_load_flat_pressed() -> void:
	_load_demo_flat()

func _on_load_tall_pressed() -> void:
	_load_demo_tall()
