extends Node2D
## Tall tiles are used for both the sand layer and an additional grass wall
## layer.
## 
## When exploring this demo object, pay special attention to the z-index
## of any given child. This is especially relevant to how YSort operates,
## due to Godot only YSorting nodes that share the same z-index.
##
## The objects of MOST importance to observe are the Sand and GrassTall
## exported "Display Tilesets." Note how the tile_size property is
## (16, 16) (this represents the base/bottom of a tile). Then observe
## the texture_region_size property and note that it's set to (16, 32).
## This tells Godot that we want a standard TileMap grid of squares (16, 16)
## pixels in size per-cell, but we'll be rendering textures of a different size
## onto those grid cells (that texture size being (16, 32) pixels per-cell).
## Because of this, Godot will naturally "overlay" tile sprites together while
## aligning the base of each tile to a square grid.
##
## In the TileSet docker tab, "Select" any of the TileSet cells for Sand
## or GrassTall and observe the rendering.texture_origin property. This
## tells Godot where the origin will be on these larger-than-grid-cell
## tile textures. For tile we want to extend upward (as for GrassTall walls),
## we simply set the texture_origin to the bottom-half's center of the cell.
## Also pay special attention to the rendering.y_sort_origin for each cell
## in GrassTall. Because the DualGrid System renders any given world tile
## as a collection of 4 display tiles, certain display tiles must have
## their YSort Origin offset downward to account for the fact that they
## represent only the upper-half of any given rendered tile.
## 
## We also force_empty on the stack, which allows us
## to play with transparency between layers and just fill the rest
## of the screen in with a background ColorRect.
## 
## Last thing to note is that we have physics colliders set up on the
## GrassTall world TileMapLayer (the base tile layer, NOT the display layer).
## Because any given displayed cell's base is really just a square on the
## square grid, we can use some optimal physics collision (Godot can easily
## merge uniformly square collision shapes). If you want more precise collision
## based on the display tiles, you can set collision up on the display tiles
## themselves and produce the same effect.

## Ref to our DualGrid stack.
@onready var dgs: DualGridStack = $YSort/DualGridStack
