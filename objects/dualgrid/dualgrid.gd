class_name DualGrid
extends TileMapLayer
## DualGrid is a TileMapLayer with another TileMapLayer as its child. This
## second TileMapLayer is offset by half a tile in the negative x and y
## directions.
## 
## This second TileMapLayer is also what's called the "dual" of
## the data grid. The DualGrid (root of this node) contains world data and does
## not do any rendering, however it is allowed to populate cell data. This
## will let you embed additional custom data behavior into different tile types
## should you want to. If you want to do physics or light occluders, those must
## be added to the DisplayLayer (the dual).

## TileSet to render for this tile type.
@export var display_tileset: TileSet

## If [code]true[/code], YSort will be enable for both the world and display
## layers.
@export var enable_y_sort: bool = false

## Ref to DisplayLayer (the dual).
@onready var display: TileMapLayer = $DisplayLayer

func _ready() -> void:
	display.tile_set = display_tileset
	y_sort_enabled = enable_y_sort
	display.y_sort_enabled = enable_y_sort

## Erase cell data at the xy map location and update the dual.
func erase_world_cell(xy: Vector2i) -> void:
	erase_cell(xy)
	update_display_cells(xy)

## Set cell data at the xy map location and update the dual.
func set_world_cell(xy: Vector2i) -> void:
	# We do an arbitrary set here of a "base tile" when considering world
	# data. This is because we only care about whether or not cell data
	# exists when looking at the world grid.
	set_cell(xy, 0, Vector2i.ZERO)
	update_display_cells(xy)

## Update the dual.
func update_display_cells(xy: Vector2i) -> void:
	# Every world cell has 4 corresponding display cells that render it.
	# We can find those by doing a forward neighbor walk and ADDING the
	# offset. This is because our DisplayLayer is offset in the negative
	# x and y directions, nudging the dual up and to the left to situate
	# four display tiles over each world cell.
	# 
	# For example, world tile (1, 1) is rendered by the display tiles:
	# (1, 1), (2, 1), (1, 2), (2, 2).
	for n_offset in DualGridStack.NEIGHBORS:
		set_display_cell(xy + n_offset)

## Set the dual's cell data based on custom auto-tile logic derived from
## a neighborhood bitmask.
func set_display_cell(xy: Vector2i):
	# begin with no bits flipped
	var n_bits: int = 0
	
	# Do a backward neighbor walk and SUBTRACT the offset. From the
	# perspective of the dual (DisplayLayer) looking down at the world
	# grid, each display tile hovers overtop of 4 world cells. This means
	# each corner of the display tile is touching the center of 4 world cells.
	# 
	# For each of these world cells, we check if data exists and flip a bit if
	# it does. The order in which we do this is the same order in which the
	# DualGridStack.BITMASK_TO_ATLAS Look-Up array was generated. Because of
	# that consistency, we can take our combination of 4 ones-and-zeros and
	# use them as a 4-bit unsigned integer. This integer ranges from 0-15,
	# precisely indexing into the DualGridStack.BITMASK_TO_ATLAS.
	for n_i in range(DualGridStack.NEIGHBORS.size() - 1, -1, -1):
		# Shift the bits to the left. We technically do this redundantly on the
		# first iteration of this for loop, but I find it cleaner than the 
		# alternatives.
		# Note: This bit shift will "zero-fill" the integer. Meaning bits
		# coming in from the right-most position default to 0.
		n_bits <<= 1
		
		# Flip the right-most 0 to a 1 if we detect cell data.
		# Note: I keep saying "flip" but we're technically just doing a
		# bitwise OR between two integers. Because our starting integer
		# is made up of zeros, it's "technically" flipping those bits
		# (semantically, we're just shoving a 1 bit into place based off
		# of a conditional and otherwise doing nothing for this shift,
		# leaving the zero from the bit shift intact).
		if get_cell_tile_data(xy - DualGridStack.NEIGHBORS[n_i]) != null:
			n_bits |= 1
	
	# Set the cell using the indexed atlas coordinates, using n_bits
	# as an index.
	display.set_cell(xy, 0, DualGridStack.BITMASK_TO_ATLAS[n_bits])
