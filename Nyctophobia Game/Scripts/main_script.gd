extends Node

# Holds information for moving the camera around
const ORIGINAL_CAMERA_POS = Vector2i(110, 90)

# Defines what each atlas coord is in terms of building type
const BUILDING_TYPE_BY_ATLAS_COORDS = {
	"wall": [Vector2i(1, 1), Vector2i(0, 2), Vector2i(4, 2), Vector2i(1, 5), Vector2i(10, 1), Vector2i(11, 1)],
	"wall_corner": [Vector2i(0, 1), Vector2i(4, 1), Vector2i(0, 5), Vector2i(4, 5)],
	"floor": [Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2), Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 3), Vector2i(1, 4), Vector2i(2, 4), Vector2i(3, 4)],
	"window": [Vector2i(2, 1), Vector2i(0, 3), Vector2i(4, 3), Vector2i(2, 5)],
	"door_n": [Vector2i(3, 1)], 
	"door_w": [Vector2i(0, 4)], 
	"door_e": [Vector2i(4, 4)], 
	"door_s": [Vector2i(3, 5)]
}

const FURNITURE_TYPE_BY_ATLAS_COORDS = {
	"book_shelf": {Vector2i(0, 7): [], Vector2i(1, 7): [], Vector2i(1, 8): [], Vector2i(3, 7): []},
	"piano": {Vector2i(0, 9): [Vector2i(0, 1)], Vector2i(1, 9): [Vector2i(0, 1)], Vector2i(2, 9): [Vector2i(1, 0)], Vector2i(2, 10): [Vector2i(1, 0)]},
	"small_chair": {Vector2i(4, 7): [], Vector2i(4, 8): [], Vector2i(4, 9): [], Vector2i(4, 10): []},
	"bench": {Vector2i(7, 7): [Vector2i(0, 1)], Vector2i(8, 7): [Vector2i(0, 1)], Vector2i(9, 7): [Vector2i(1, 0)], Vector2i(9, 8): [Vector2i(1, 0)]},
	"night_stand": {Vector2i(5, 7): []},
	"small_night_stand": {Vector2i(5, 8): []},
	"stool": {Vector2i(5, 9): []},
	"plant": {Vector2i(5, 10): []},
	"lamp": {Vector2i(6, 7): []},
	
	"bed": {
		Vector2i(0, 15): [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)], 
		Vector2i(2, 15): [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
		Vector2i(2, 17): [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
		Vector2i(4, 15): [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
		},
	"small_television": {Vector2i(6, 15): []},
	
	"countertop": {Vector2i(3, 12): []},
	"sink": {Vector2i(4, 12): []},
	"oven": {Vector2i(5, 12): []},
	"fridge": {Vector2i(0, 12): []},
	"dining_table": {Vector2i(1, 12): [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]}
}

# Defines which objects can be walked through/over
const WALKABLE_OBJECTS = ["book_shelf"]

# Defines which objects are highlighted in the dark
var highlighted_objects = ["lamp"]

# Holds information about the size of the house in "rooms x rooms"
const HOUSE_SIZE = 2

# Holds information about the size of each room on the tilemap
const ROOM_SIZE_X = 11
const ROOM_SIZE_Y = 9

# Master grid for information about the house
var house_grid = []
var curr_room = Vector2i(0, 0)

# Holds information regarding the default room lighting
var room_lighting = 6 # 6
var window_emission = 1 # 1
var lamp_emission = 2 # 2

@onready var room_tilemap: TileMapLayer = $"TileSets/RoomTileMap"
@onready var objects_tilemap: TileMapLayer = $TileSets/ObjectsTileMap
@onready var shadow_tilemap: TileMapLayer = $"TileSets/ShadowTileMap"

@onready var player: Node2D = $"Player"
@onready var camera: Camera2D = $"Camera"

@onready var object_classes: Node = $"Object Classes"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Sets up the house grid to be a square 2D list
	for y in range(HOUSE_SIZE):
		house_grid.append([])
		for x in range(HOUSE_SIZE):
			house_grid[-1].append([])
	
	# Iterates through each room in the house
	for room_y in range(HOUSE_SIZE):
		for room_x in range(HOUSE_SIZE):
			# Creates 2D lists for each tile in the room
			for y in range(ROOM_SIZE_Y):
				house_grid[room_y][room_x].append([])
				for x in range(ROOM_SIZE_X):
					# Creates a default tile within the room
					house_grid[room_y][room_x][-1].append({
						"brightness": 6,
						"object_type": null,
						"object": null,
						"interactable": null,
						"type": null,
					})
	
	# Creates variables to hold the atlas coords and tile type
	var atlas_coords
	
	# Loops through all the rooms inside of the house
	for house_y in range(HOUSE_SIZE):
		for house_x in range(HOUSE_SIZE):
			# Loops through all the tiles in the room
			for room_y in range(ROOM_SIZE_Y):
				for room_x in range(ROOM_SIZE_X):
					## Applies the physical building to the house grid
					# Gets the tile from the room tilemap
					atlas_coords = room_tilemap.get_cell_atlas_coords(Vector2i(
						(house_x * (ROOM_SIZE_X + 1)) + room_x, 
						(house_y * (ROOM_SIZE_Y + 1)) + room_y
					))
					
					# Finds which type of building the tile is
					for type in BUILDING_TYPE_BY_ATLAS_COORDS.keys():
						if atlas_coords in BUILDING_TYPE_BY_ATLAS_COORDS[type]:
							# Sets the found tile type in the house grid
							house_grid[house_y][house_x][room_y][room_x]["type"] = type
							
							break
					
					## Applies the furniture to the house grid
					# Gets the tile from the room tilemap
					atlas_coords = objects_tilemap.get_cell_atlas_coords(Vector2i(
						(house_x * (ROOM_SIZE_X + 1)) + room_x, 
						(house_y * (ROOM_SIZE_Y + 1)) + room_y
					))
					
					# Finds which type of building the tile is
					for type in FURNITURE_TYPE_BY_ATLAS_COORDS.keys():
						if atlas_coords in FURNITURE_TYPE_BY_ATLAS_COORDS[type].keys():
							# Creates a new object class for the object depending on its type
							var furniture_object = object_classes.get_object_from_furniture_type(type)
							
							# Sets the found tile type in the house grid
							house_grid[house_y][house_x][room_y][room_x]["object_type"] = type
							house_grid[house_y][house_x][room_y][room_x]["object"] = furniture_object
							
							# Sets the connected tiles for the tile type in the house grid
							for connected_tile in FURNITURE_TYPE_BY_ATLAS_COORDS[type][atlas_coords]:
								house_grid[house_y][house_x][room_y + connected_tile.y][room_x + connected_tile.x]["object_type"] = type
							
							break
	
	shadow_tilemap.update_shadows()
	
	var room_metadata = house_grid[curr_room[1]][curr_room[0]]
	
	
	# Test
	var new_lamp_object = object_classes.lamp_object.new()
	print(new_lamp_object.type)


# Change room functions
func move_to_room(new_room: Vector2i, door_entered: String) -> bool:
	# Checks if the door is valid and unlocked
	if (
			# Checks that the expected room is within bounds
			new_room.x >= 0 
			and new_room.y >= 0 
			and new_room.x < HOUSE_SIZE 
			and new_room.y < HOUSE_SIZE
	):
		
		# Defines what door for the program to search for when determining where to place the player in the new room
		var new_door_dir: String
		match door_entered:
			"door_n": new_door_dir = "door_s"
			"door_e": new_door_dir = "door_w"
			"door_s": new_door_dir = "door_n"
			"door_w": new_door_dir = "door_e"
		
		# Gets the location of the determined door in the new room
		var new_room_door_location: Vector2i = get_door_location_in_room(new_room, new_door_dir)
		
		# Defines the offset from the door depending on what type it is
		var spawn_tile: Vector2i = new_room_door_location
		match door_entered:
			"door_n": spawn_tile += Vector2i(0, -1)
			"door_e": spawn_tile += Vector2i(1, 0)
			"door_s": spawn_tile += Vector2i(0, 1)
			"door_w": spawn_tile += Vector2i(-1, 0)
		
		# Updates the player's position
		player.player_pos = spawn_tile
		
		# Stop any ongoing movements
		player.tween_pos.kill()
		
		# Move the player's visual to the new location
		player.position = (spawn_tile + Vector2i(new_room[0] * 12, new_room[1] * 10)) * 20
		# BUG: performing (move_x + move_y + interact) actions as soon as the next input is accepted (WalkCooldown = 0.175s) \
				# the player position is incorrectly changed when moving into another room:
					# NW room, E door: (180.0, 40.0), bugged: (280.0, 60.0)
					# NE room, W door: (260.0, 60.0), bugged: (160.0, 40.0)
				
				# player.tween_pos is not running
				# the calculation for player.position is correct (NE-W bugged: (260.0, 60.0))
		
		# Update the camera's position to the new room
		camera.position = ORIGINAL_CAMERA_POS + Vector2i(new_room[0] * 12 * 20, new_room[1] * 10 * 20)
		
		# Update the current room to the new room
		curr_room = new_room
		
		# Update the shadows of the new room
		shadow_tilemap.update_shadows()
		
		return true
		
	else:
		print("The door is locked!")
		return false


func get_door_location_in_room(room_pos: Vector2i, door_direction: String) -> Vector2i:
	var new_room_grid = house_grid[room_pos.y][room_pos.x]
	
	# Searches the room for the specified door
	for room_y in range(len(new_room_grid)):
		for room_x in range(len(new_room_grid[room_y])):
			if new_room_grid[room_y][room_x]["type"] == door_direction:
				return Vector2i(room_x, room_y)
	
	# Returns -1 -1 as an error
	return Vector2i(-1, -1)
