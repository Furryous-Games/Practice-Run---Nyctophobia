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

@onready var room_tilemap: TileMapLayer = $"../TileSets/RoomTilemap"
@onready var shadow_tilemap: TileMapLayer = $"../TileSets/ShadowTilemap"

@onready var player: Node2D = $"../Player"
@onready var camera: Camera2D = $"../Camera"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Provides a pointer to the main script for the player
	player.main_script = self
	shadow_tilemap.main_script = self
	
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
						"object": null,
						"interactable": null,
						"type": null,
					})
	
	# Creates variables to hold the atlas coords and tile type
	var atlas_coords
	var tile_type
	
	# Loops through all the rooms inside of the house
	for house_y in range(HOUSE_SIZE):
		for house_x in range(HOUSE_SIZE):
			# Loops through all the tiles in the room
			for room_y in range(ROOM_SIZE_Y):
				for room_x in range(ROOM_SIZE_X):
					# Gets the tile from the tilemap
					atlas_coords = room_tilemap.get_cell_atlas_coords(Vector2i(
						(house_x * (ROOM_SIZE_X + 1)) + room_x, 
						(house_y * (ROOM_SIZE_Y + 1)) + room_y
					))
					# The default tile type is null
					tile_type = null
					
					# Finds which type of building the tile is
					for type in BUILDING_TYPE_BY_ATLAS_COORDS.keys():
						if atlas_coords in BUILDING_TYPE_BY_ATLAS_COORDS[type]:
							tile_type = type
							break
					
					# Sets the found tile type in the house grid
					house_grid[house_y][house_x][room_y][room_x]["type"] = tile_type
					
					
					# TEST
					if tile_type == "floor":
						house_grid[house_y][house_x][room_y][room_x]["brightness"] = (randi()) % 6 + 1
	
	
	shadow_tilemap.update_shadows()


# Change room functions
func move_to_room(new_room, door_entered) -> void:
	# Checks if the door is valid and unlocked
	if (
			# Checks that the expected room is within bounds
			new_room.x >= 0 
			and new_room.y >= 0 
			and new_room.x < HOUSE_SIZE 
			and new_room.y < HOUSE_SIZE
	):
		
		# Defines what door for the program to search for when determining where to place the player in the new room
		var new_door_direction = (
			"door_n" if door_entered == "door_s"
			else "door_e" if door_entered == "door_w"
			else "door_s" if door_entered == "door_n"
			else "door_w"
		)
		
		# Gets the location of the determined door in the new room
		var new_room_door_location = get_door_location_in_room(new_room, new_door_direction)
		
		# Defines the offset from the door depending on what type it is
		var spawn_tile = new_room_door_location + ( 
			Vector2i(0, -1) if door_entered == "door_n"
			else Vector2i(1, 0) if door_entered == "door_e"
			else Vector2i(0, 1) if door_entered == "door_s"
			else Vector2i(-1, 0)
		)
		
		# Updates the player's position
		player.player_pos = spawn_tile
		# Stop any ongoing movements
		player.tween_pos.stop()
		# Move the player's visual to the new location
		player.position = (spawn_tile + Vector2i(new_room[0] * 12, new_room[1] * 10)) * 20
		
		# Update the camera's position to the new room
		camera.position = ORIGINAL_CAMERA_POS + Vector2i(new_room[0] * 12 * 20, new_room[1] * 10 * 20)
		
		# Update the current room to the new room
		curr_room = new_room
		
		# Update the shadows of the new room
		shadow_tilemap.update_shadows()
		
	else:
		print("The door is locked!")


func get_door_location_in_room(room_pos, door_direction) -> Vector2i:
	var new_room_grid = house_grid[room_pos.y][room_pos.x]
	
	# Searches the room for the specified door
	for room_y in range(len(new_room_grid)):
		for room_x in range(len(new_room_grid[room_y])):
			if new_room_grid[room_y][room_x]["type"] == door_direction:
				return Vector2i(room_x, room_y)
	
	# Returns -1 -1 as an error
	return Vector2i(-1, -1)
