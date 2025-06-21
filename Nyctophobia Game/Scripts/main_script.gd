extends Node

@onready var room_tilemap: TileMap = $"../Tile Sets/Room Tilemap"

# Master grid for information about the house
var house_grid = []

# Holds information about the size of the house in "rooms x rooms"
const house_size = 2

# Holds information about the size of each room on the tilemap
const room_size_x = 11
const room_size_y = 9

# Defines what each atlas coord is in terms of building type
const building_type_by_atlas_coords = {
	"wall": [Vector2i(0, 1), Vector2i(1, 1), Vector2i(4, 1), Vector2i(0, 2), Vector2i(4, 2), Vector2i(0, 5), Vector2i(1, 5), Vector2i(4, 5)],
	"floor": [Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2), Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 3), Vector2i(1, 4), Vector2i(2, 4), Vector2i(3, 4)],
	"window": [Vector2i(2, 1), Vector2i(0, 3), Vector2i(4, 3), Vector2i(2, 5)],
	"door": [Vector2i(3, 1), Vector2i(0, 4), Vector2i(4, 4), Vector2i(3, 5)]
	}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Sets up the house grid to be a square 2D list
	for y in range(house_size):
		house_grid.append([])
		for x in range(house_size):
			house_grid[-1].append([])
	
	# Iterates through each room in the house
	for room_y in range(house_size):
		for room_x in range(house_size):
			# Creates 2D lists for each tile in the room
			for y in range(room_size_y):
				house_grid[room_y][room_x].append([])
				for x in range(room_size_x):
					# Creates a default tile within the room
					house_grid[room_y][room_x][-1].append({
						"brightness": 5,
						"object": null,
						"interactable": null,
						"type": null,
					})
	
	# Creates variables to hold the atlas coords and tile type
	var atlas_coords
	var tile_type
	
	# Loops through all the rooms inside of the house
	for house_y in range(house_size):
		for house_x in range(house_size):
			# Loops through all the tiles in the room
			for room_y in range(room_size_y):
				for room_x in range(room_size_x):
					# Gets the tile from the tilemap
					atlas_coords = room_tilemap.get_cell_atlas_coords(0, Vector2(
						(house_x * (room_size_x + 1)) + room_x, 
						(house_y * (room_size_y + 1)) + room_y
						))
					# The default tile type is null
					tile_type = null
					
					# Finds which type of building the tile is
					for type in building_type_by_atlas_coords.keys():
						if atlas_coords in building_type_by_atlas_coords[type]:
							tile_type = type
							break
					
					# Sets the found tile type in the house grid
					house_grid[house_y][house_x][room_y][room_x]["type"] = tile_type

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
