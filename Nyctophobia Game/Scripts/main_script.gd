extends Node

@onready var room_tilemap: TileMap = $"../Tile Sets/Room Tilemap"
@onready var player: Node2D = $"../Player"
@onready var camera: Camera2D = $"../Camera"

# Master grid for information about the house
var house_grid = []
var curr_room = Vector2(0, 0)

# Holds information about the size of the house in "rooms x rooms"
const house_size = 2

# Holds information about the size of each room on the tilemap
const room_size_x = 11
const room_size_y = 9

# Holds information for moving the camera around
const original_camera_pos = Vector2(110, 90)

# Defines what each atlas coord is in terms of building type
const building_type_by_atlas_coords = {
	"wall": [Vector2i(0, 1), Vector2i(1, 1), Vector2i(4, 1), Vector2i(0, 2), Vector2i(4, 2), Vector2i(0, 5), Vector2i(1, 5), Vector2i(4, 5)],
	"floor": [Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2), Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 3), Vector2i(1, 4), Vector2i(2, 4), Vector2i(3, 4)],
	"window": [Vector2i(2, 1), Vector2i(0, 3), Vector2i(4, 3), Vector2i(2, 5)],
	"door_n": [Vector2i(3, 1)], 
	"door_w": [Vector2i(0, 4)], 
	"door_e": [Vector2i(4, 4)], 
	"door_s": [Vector2i(3, 5)]
	}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Provides a pointer to the main script for the player
	player.main_script = self
	
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


func move_to_room(new_room, door_entered) -> void:
	# Checks if the door is valid and unlocked
	if (
		# Checks that the expected room is within bounds
		new_room.x >= 0 and new_room.y >= 0 and new_room.x < house_size and new_room.y < house_size
		):
		
		# Defines what door for the program to search for when determining where to place the player in the new room
		var new_door_direction = (
			"door_n" if door_entered == "door_s" else 
			"door_e" if door_entered == "door_w" else 
			"door_s" if door_entered == "door_n" else 
			"door_w"
		)
		
		# Gets the location of the determined door in the new room
		var new_room_door_location = get_door_location_in_room(new_room, new_door_direction)
		
		# Defines the offset from the door depending on what type it is
		var spawn_tile = new_room_door_location + ( 
			Vector2(0, -1) if door_entered == "door_n" else
			Vector2(1, 0) if door_entered == "door_e" else
			Vector2(0, 1) if door_entered == "door_s" else
			Vector2(-1, 0)
			)
		
		# Updates the player's position
		player.player_pos = spawn_tile
		# Stop any ongoing movements
		player.tween_pos.stop()
		# Move the player's visual to the new location
		player.position = (spawn_tile + Vector2(new_room[0] * 12, new_room[1] * 10)) * 20
		
		# Update the camera's position to the new room
		camera.position = original_camera_pos + Vector2(new_room[0] * 12 * 20, new_room[1] * 10 * 20)
		
		# Update the current room to the new room
		curr_room = new_room
		
	else:
		print("The door is locked!")

func get_door_location_in_room(room_pos, door_direction) -> Vector2:
	var new_room_grid = house_grid[room_pos.y][room_pos.x]
	
	for room_y in range(len(new_room_grid)):
		for room_x in range(len(new_room_grid[room_y])):
			if new_room_grid[room_y][room_x]["type"] == door_direction:
				return Vector2(room_x, room_y)
	
	return Vector2(-1, -1)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
