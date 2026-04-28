class_name DualGridStack
extends Node2D
## DualGridStack manages the data stack containing the layered DualGrid
## objects.

## If [code]true[/code], empty space will [b]not[/b] be displayed using the 
## bottom-most layer's [code]0000b[/code] atlas cell.
@export var force_empty: bool = false

## Stack of DualGrid objects, each comprised of 
## two TileMapLayer nodes (world vs display).
var layer_stack: Array[DualGrid] = []
## Standard tile size for tilesets.
var tile_size: Vector2i = Vector2i(16, 16)

## Ordered neighborhood walk. We will step through this both backwards 
## and forwards:
## [br][br] - [b]Backwards[/b] to compute a [i]TOP_LEFT/TOP_RIGHT/BOT_LEFT/BOT_RIGHT[/i] bitmask.
## [br][br] - [b]Forwards[/b] to update display neighbors.
static var NEIGHBORS: Array[Vector2i] = [
	Vector2i(0, 0),
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(1, 1)
]

## 1D Look-Up array of TileAtlas coordinates indexed by 
## the bitmask generated from checking which neighboring 
## cells are populated with data on any given world TileMapLayer.
## [br]This is pregenerated and will always be accurate if you
## check neighbors in TOP_LEFT/TOP_RIGHT/BOT_LEFT/BOT_RIGHT order
## when calculating the bitwise tile-atlas index.
static var BITMASK_TO_ATLAS: Array[Vector2i] = [
	# Key:
	#   - NO DATA: 0, HAS DATA: 1
	# Ordering:
	#   - TOP LEFT / TOP RIGHT / BOT LEFT / BOT RIGHT
	Vector2i(0, 3), # 0000 - No corners
	Vector2i(1, 3), # 0001 - Outer bottom-right corner
	Vector2i(0, 0), # 0010 - Outer bottom-left corner
	Vector2i(3, 0), # 0011 - Bottom edge
	Vector2i(0, 2), # 0100 - Outer top-right corner
	Vector2i(1, 0), # 0101 - Right edge
	Vector2i(2, 3), # 0110 - Bottom-left top-right corner
	Vector2i(1, 1), # 0111 - Inner bottom-right corner
	Vector2i(3, 3), # 1000 - Outer top-left corner
	Vector2i(0, 1), # 1001 - Top-left down-right corners
	Vector2i(3, 2), # 1010 - Left edge
	Vector2i(2, 0), # 1011 - Inner bottom-left corner
	Vector2i(1, 2), # 1100 - Top edge
	Vector2i(2, 2), # 1101 - Inner top-right corner
	Vector2i(3, 1), # 1110 - Inner top-left corner
	Vector2i(2, 1)  # 1111 - All corners
]

func _ready() -> void:
	# In this stacked implementation, we treat "empty space" differently.
	# As such, what would be "empty space" is instead going to display a tile
	# from the bottom most layer of the DualGridStack. This bottom layer is
	# what I call a "BOT" tileset, and is drawn in an inversed fashion
	# from the standard 15-tile minimal tileset. The auto-tiling on this
	# "BOT" tileset results in creating empty space where "TOP" tilesets
	# would render sprites ("TOP" meaning the standard 15-tile minimal tileset).
	
	for layer: DualGrid in get_children():
		# As this is a stack, we push onto the front/head of the array.
		# We do this for two reasons:
		#  1) Godot renders node trees top-down, meaning if we want our top-most
		#     tileset to be rendered on top it must be drawn last. We take
		#     advantage of this render order to create inter-layer auto-tiling,
		#     making different tile types auto-tile together by stacking their
		#     rendering.
		#  2) Tracking our DualGridStack as an actual data stack lets us
		#     consider the array in the order of physical depth. Think of the
		#     front of the array as having the highest z-index. That way, we
		#     can "build up" and "dig down" into the stack to render tiles in
		#     much the same way as a player physically digging into the ground
		#     in-game. You can couple this with perlin noise for procedural
		#     generation, setting cells in the stack based on noise depth.
		layer_stack.push_front(layer)
		
		# perform our non-empty-space pass on the bottom-most layer of the stack
		if !force_empty:
			if layer_stack.size() == 1:
				for x in range(-20, 20):
					for y in range(-11, 11):
						layer.update_display_cells(Vector2i(x, y))
	
	# assert that we've populated the stack
	assert(!layer_stack.is_empty(), "DualGridStack is empty.")

## Calls [method TileMapLayer.local_to_map] on head of DualGridStack.
func local_to_map(local_pos: Vector2) -> Vector2i:
	return layer_stack.front().local_to_map(local_pos)

## Returns the top-most rendered tile type name as a [String].
func get_tile_type(xy: Vector2i) -> String:
	# dig down into the stack and stop on the first layer
	# that has populated data at the cell xy map location
	for i in range(layer_stack.size() - 1):
		if layer_stack[i].get_cell_tile_data(xy) != null:
			return layer_stack[i].name
	
	# return the bottom-most layer's tile name by default
	return layer_stack.back().name

## Populate the next cell upward in the stack that does not already have
## cell data present at the xy map location and update the display dual.
## [br]This is our [b]"build up"[/b] emulation.
func push_cell(xy: Vector2i) -> void:
	# Do a reverse walk of the stack ignoring the bottom-most layer.
	# We ignore the bottom-most layer because it's treated slightly differently
	# from the rest of the stack. That is to say, it renders display tiles
	# in an inversed fashion, resulting in it rendering tiles even without
	# tile data present.
	for i in range(layer_stack.size() - 2, -1, -1):
		# populate the first empty cell found and break
		if layer_stack[i].get_cell_tile_data(xy) == null:
			# this will set the layer's cell data and also update
			# the neighboring display tiles on the dual
			layer_stack[i].set_world_cell(xy)
			
			# Remember that our bottom-most layer is technically empty in
			# terms of having actual cell data due to its inversed nature.
			# So, when we actually set data on this inversed tilset, we
			# create empty space at the cell location in an auto-tiled
			# fashion. This is what gives us the water foam bordering
			# the Sand and Grass tiles.
			# Due to the small size of the stack, this is done on every
			# push. However, if you feel this isn't optimal, you can
			# puzzle out a smarter place to put this so it's not
			# getting performed redundantly.
			layer_stack.back().set_world_cell(xy)
			
			break

## Erase the top-most cell data at the xy map location and update the display
## dual.
## [br]This is our [b]"dig down"[/b] emulation.
func pop_cell(xy: Vector2i) -> void:
	# Do a top-down walk of the stack and erase the first populated cell found.
	# We will also perform some automatic cleanup of the bottom-most layer
	# if we detect that we've just exposed it in the stack.
	for i in range(layer_stack.size() - 1):
		if layer_stack[i].get_cell_tile_data(xy) != null:
			# this will erase the layer's cell data and also update
			# the neighboring display tiles on the dual
			layer_stack[i].erase_world_cell(xy)
			
			# If we've just erase the second-to-bottom-most-layer we must
			# also erase the cell data from the bottom-most layer. Otherwise,
			# we render truly empty space. You can try disabling this if you
			# want to know what that looks like.
			if i == layer_stack.size() - 2:
				layer_stack.back().erase_world_cell(xy)
			
			break
