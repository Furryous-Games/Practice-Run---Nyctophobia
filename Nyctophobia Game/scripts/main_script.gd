extends Node

# Holds information for moving the camera around
const ORIGINAL_CAMERA_POS := Vector2i(110, 90)

# Defines what each atlas coord is in terms of building type
const BUILDING_TYPE_BY_ATLAS_COORDS = {
	"wall": [Vector2i(1, 1), Vector2i(0, 2), Vector2i(4, 2), Vector2i(1, 5), Vector2i(10, 1), Vector2i(11, 1)],
	"wall_corner": [Vector2i(0, 1), Vector2i(4, 1), Vector2i(0, 5), Vector2i(4, 5)],
	"floor": [Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2), Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 3), Vector2i(1, 4), Vector2i(2, 4), Vector2i(3, 4)],
	"window": [Vector2i(2, 1), Vector2i(0, 3), Vector2i(4, 3), Vector2i(2, 5)],
	"door_n": [Vector2i(3, 1)], 
	"door_w": [Vector2i(0, 4)], 
	"door_e": [Vector2i(4, 4)], 
	"door_s": [Vector2i(3, 5)],
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
	"dining_table": {Vector2i(1, 12): [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]},
}

# Defines which objects can be walked through/over
const WALKABLE_OBJECTS := ["book_shelf"]

# Holds information about the size of the house in "rooms x rooms"

const HOUSE_SIZE = Vector2i(4, 3)

# Holds information about the size of each room on the tilemap
const ROOM_SIZE_X: int = 11
const ROOM_SIZE_Y: int = 9

# All tasks and their information
const TASK_LIBRARY := {
	"Make Bed": {"Weight": 1, "Abnormality": 0},
	"Water Plants": {"Weight": 1, "Abnormality": 0},
	"Make Food": {"Weight": 1, "Abnormality": 0},
	"Wash Dishes": {"Weight": 1, "Abnormality": 0},
	"Organize Bookshelf": {"Weight": 1, "Abnormality": 0},
}

# Master grid for information about the house
var house_grid: Array = []
var curr_room := Vector2i(0, 0)

# Holds information regarding the default room lighting

var room_lighting: int = 6 # 6
var window_emission: int = 1 # 1
var lamp_emission: int = 2 # 2

# Defines which objects are highlighted in the dark
var highlighted_objects = ["lamp"]

# The current day
var day: int = 0
# What tasks are added to the selection pool according to their abnormality
var abnormality_level: int = 0

# Holds information regarding tasks
var task_list: Array
var task_quantity: int = 4
var task_list_open := false
var completed_tasks: Array

@onready var room_tilemap: TileMapLayer = $"TileSets/RoomTileMap"
@onready var objects_tilemap: TileMapLayer = $TileSets/ObjectsTileMap
@onready var shadow_tilemap: TileMapLayer = $"TileSets/ShadowTileMap"

@onready var player: Node2D = $"Player"
@onready var camera: Camera2D = $"Camera"

@onready var object_classes: Node = $"ObjectClasses"

@onready var task_panel: Panel = $UI/TaskPanel
@onready var ui_heading: Label = $UI/TaskPanel/Heading
@onready var ui_list: VBoxContainer = $UI/TaskPanel/List
@onready var auto_toggle: Timer = $UI/AutoToggle


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Sets up the house grid to be a square 2D list
	for y in range(HOUSE_SIZE.y):
		house_grid.append([])
		for x in range(HOUSE_SIZE.x):
			house_grid[-1].append([])
	
	# Iterates through each room in the house
	for room_y in range(HOUSE_SIZE.y):
		for room_x in range(HOUSE_SIZE.x):
			# Creates 2D lists for each tile in the room
			for y in range(ROOM_SIZE_Y):
				house_grid[room_y][room_x].append([])
				for x in range(ROOM_SIZE_X):
					# Creates a default tile within the room
					house_grid[room_y][room_x][-1].append({
						"brightness": 6,
						"object": null,
						"type": null,
					})
	
	# Creates variables to hold the atlas coords and tile type
	var atlas_coords
	
	# Loops through all the rooms inside of the house
	for house_y in range(HOUSE_SIZE.y):
		for house_x in range(HOUSE_SIZE.x):
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
						if atlas_coords in FURNITURE_TYPE_BY_ATLAS_COORDS[type].keys() and house_grid[house_y][house_x][room_y][room_x]["object"] == null:
							# Creates a new object class for the object depending on its type
							match type:
								"lamp":
									house_grid[house_y][house_x][room_y][room_x]["object"] = object_classes.lamp_object.new()
								
								_: 
									house_grid[house_y][house_x][room_y][room_x]["object"] = object_classes.object.new()
							
							house_grid[house_y][house_x][room_y][room_x]["object"].type = type
							house_grid[house_y][house_x][room_y][room_x]["object"].position = Vector2i(room_y,room_x)
							
							# Sets the connected tiles for the tile type in the house grid
							
							for connected_tile in FURNITURE_TYPE_BY_ATLAS_COORDS[type][atlas_coords]:
								
								house_grid[house_y][house_x][room_y][room_x]["object"].connected_tiles.append(Vector2i(room_y + connected_tile.y, room_x + connected_tile.x))
								
								match type:
									
									_: 
										house_grid[house_y][house_x][room_y + connected_tile.y][room_x + connected_tile.x]["object"] = object_classes.object.new()
									
								house_grid[house_y][house_x][room_y + connected_tile.y][room_x + connected_tile.x]["object"].type = type
								house_grid[house_y][house_x][room_y + connected_tile.y][room_x + connected_tile.x]["object"].connected = true
								
							break
	
	shadow_tilemap.update_shadows()
	
	new_day()
	
	# Test
	#var new_lamp_object = object_classes.lamp_object.new()
	#print(new_lamp_object.type)


# Checks if the tile we want to move to is not an object, is a floor tile, and is not directly adfjacent to a door. 
func find_empty_tile(house_y, house_x, room_y, room_x, movement_y, movement_x, type, atlas_coords) -> bool:
	
	# Out of bounds checks.
	if room_y + movement_y < 0 or room_y + movement_y > 8:
		return false
	
	if room_x + movement_x < 0 or room_x + movement_x > 10:
		return false
	
	if atlas_coords != null:
		for connected_tile in FURNITURE_TYPE_BY_ATLAS_COORDS[type][atlas_coords]:
			if room_y + connected_tile.y + movement_y < 0 or room_y + connected_tile.y + movement_y > 8:
				return false
			
			if room_x + connected_tile.x + movement_x < 0 or room_x + connected_tile.x + movement_x > 10:
				return false
	
	# Check if the tile we want to move to is not an object and is a floor
	if house_grid[house_y][house_x][room_y + movement_y][room_x + movement_x]["object_type"] != null or house_grid[house_y][house_x][room_y + movement_y][room_x + movement_x]["type"] != "floor":
		return false
	
	# Check if the tile we want to move to is not an object and is a floor for the connected tiles 
	if atlas_coords != null:
		for connected_tile in FURNITURE_TYPE_BY_ATLAS_COORDS[type][atlas_coords]:
			if house_grid[house_y][house_x][room_y + connected_tile.y + movement_y][room_x + connected_tile.x + movement_x]["object_type"] != null or house_grid[house_y][house_x][room_y + connected_tile.y + movement_y][room_x + connected_tile.x + movement_x]["type"] != "floor":
				return false

	# Check that the tiles directly down, up, right, and left are not doors. 
	if room_y + movement_y + 1 < 9 and house_grid[house_y][house_x][room_y + movement_y + 1][room_x + movement_x]["type"] == "door_s":
		return false
	
	if room_y + movement_y - 1 > 0 and house_grid[house_y][house_x][room_y + movement_y - 1][room_x + movement_x]["type"] == "door_n":
		return false
	
	if room_x + movement_x + 1 < 11 and house_grid[house_y][house_x][room_y + movement_y][room_x + movement_x + 1]["type"] == "door_e":
		return false

	if room_x + movement_x - 1 > 0 and house_grid[house_y][house_x][room_y + movement_y][room_x + movement_x - 1]["type"] == "door_w":
		return false

	# Return if tile is empty (true) or not (false)
	return true


# This function moves the object and its connected tiles to a new tile. 
func move_object(house_y, house_x, room_y, room_x, movement_y, movement_x, type, atlas_coords) -> void:
	
	# Set the new tile to the objects type and atlas coords.
	house_grid[house_y][house_x][room_y + movement_y][room_x + movement_x]["object_type"] == type
	house_grid[house_y][house_x][room_y + movement_y][room_x + movement_x]["atlas_coords"] == atlas_coords
	
	# Set the previous tile to be null (empty).
	house_grid[house_y][house_x][room_y][room_x]["object_type"] == null
	house_grid[house_y][house_x][room_y][room_x]["atlas_coords"] == null
	
	# Set the connected tiles new tiles to the objects type and set their previous tiles to be null (empty).
	if atlas_coords != null:
		for connected_tile in FURNITURE_TYPE_BY_ATLAS_COORDS[type][atlas_coords]:
			house_grid[house_y][house_x][room_y + movement_y + connected_tile.y][room_x + movement_x + connected_tile.x]["object_type"] = type
			house_grid[house_y][house_x][room_y + connected_tile.y][room_x + connected_tile.x]["object_type"] = null


# Iterates over 
func check_objects_to_move(variation) -> void:
	
	var rng = RandomNumberGenerator.new()
	
	# Iterates over each room in the house
	for house_y in range(HOUSE_SIZE.y):
		for house_x in range(HOUSE_SIZE.x):
			
			# Iterates over each tile in each room
			for room_y in range(ROOM_SIZE_Y):
				for room_x in range(ROOM_SIZE_X):
					
					# Store tiles type and atlas coords temporarily
					var type = house_grid[house_y][house_x][room_y][room_x]["object_type"]
					var atlas_coords = house_grid[house_y][house_x][room_y][room_x]["atlas_coords"]
					
					# Check if object on tile
					if type != null:
						
						var movement_x
						var movement_y 
						var moved = false
						
						var iterations = 0
						
						while moved == false and iterations < 8:
							movement_y = rng.randi_range(-variation,variation)
							movement_x = rng.randi_range(-variation,variation)
							
							if find_empty_tile(house_y, house_x, room_y, room_x, movement_y, movement_x, type, atlas_coords) and moved == false:
								move_object(house_y, house_x, room_y, room_x, movement_y, movement_x, type, atlas_coords)
								moved == true
								
								# Test
								print("Object: ", type, " moved from (", room_y, " , ", room_x, ") to (", room_y + movement_y, " , ", room_x + movement_x, ").")
								
								break
							
							#Test
							if room_y + movement_y < 9 and room_y + movement_y > 0 and room_x + movement_x < 11 and room_x + movement_x > 0:
								print("Couldnt move object to tile (", room_y + movement_y, " , ", room_x + movement_x, ") due to a ", house_grid[house_y][house_x][room_y + movement_y][room_x + movement_x]["object_type"], house_grid[house_y][house_x][room_y + movement_y][room_x + movement_x]["type"], " blocking the tile.")
							else:
								print("Couldnt move object to tile (", room_y + movement_y, " , ", room_x + movement_x, ").")
								
							iterations += 1

# randomly moves objects in the rooms with later days having larger variation in object placement. 
func object_movement_and_variation(day) -> void:
	
	if day == 0 or day == 1:
		return
	else:
		check_objects_to_move(day)


# Updates day-sensitive events (tasks, shadow progression, etc.)
func new_day() -> void:
	day += 1
	ui_heading.text = "Day " + str(day) + ", TASKS:"
	
	## Randomizes Tasks
	completed_tasks.clear()
	task_list.clear()
	
	# Adds an additional copy of a task to the selection list according to their Weight values, increasing their odds of selection
	# Filters out tasks whose Abnormality is higher than the abnormality_level
	var weighted_task_list: Array
	for task_key in TASK_LIBRARY.keys().filter(func(is_abnormal): return TASK_LIBRARY[is_abnormal]["Abnormality"] <= abnormality_level):
		for i in TASK_LIBRARY[task_key]["Weight"]:
			weighted_task_list.append(task_key)
	
	# Adds tasks, filters out tasks already in list
	for i in task_quantity:
		task_list.append(weighted_task_list.filter(func(is_repeat): return is_repeat not in task_list).pick_random())

	# Creates Label nodes for each task as children of ListUI
	if ui_list.get_child_count() < task_quantity:
		for i in task_quantity - ui_list.get_child_count():
			var task_node := Label.new()
			task_node.name = task_list[i]
			task_node.label_settings = preload("res://assets/label_settings/task_lebel.tres")
			ui_list.add_child(task_node)
	
	# Assigns task name to each task node
	for task in task_list.size():
		ui_list.get_child(task).text = "- " + task_list[task]

	# Automattically opens the task list and detoggles it after 5 seconds
	if not task_list_open: 
		toggle_task_list()
	auto_toggle.start()		


# Handles input unrelated to the player character.
func _input(event: InputEvent) -> void:
	# Toggle task list [TAB, C]
	if Input.is_action_pressed(&"toggle_task_list"):
		toggle_task_list()
	
	# TEST
	# Clears task at index 0 [Backspace, X]
	if Input.is_action_pressed(&"Interact2"):
		if ui_list.get_child_count() > 0:
			task_list.remove_at(0)
			ui_list.get_child(0).free()
	
	# TEST
	if event.as_text() == "Space" and event.is_pressed():
		new_day()
		object_movement_and_variation(day)


# Toggles the task list
func toggle_task_list() -> void:
	var tween_panel: Tween = create_tween().set_ease(Tween.EASE_IN if task_list_open else Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
	tween_panel.tween_property(task_panel, "position:x", -100 if task_list_open else 0, 0.4)
	task_list_open = not task_list_open
	
	# Stops the auto detoggle timer if the task list is manually detoggled then retoggled before the timer timeout at the beginning of the day
	if auto_toggle:
		auto_toggle.stop()


# Change room functions
func move_to_room(new_room: Vector2i, door_entered: String) -> bool:
	# Checks if the door is valid and unlocked
	if (
			# Checks that the expected room is within bounds
			new_room.x >= 0 
			and new_room.y >= 0 
			and new_room.x < HOUSE_SIZE.x
			and new_room.y < HOUSE_SIZE.y
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


# Automatically detoggles the task list's initial auto-opening at the start of the day
func _on_auto_toggle_timeout() -> void:
	if task_list_open:
		toggle_task_list()
