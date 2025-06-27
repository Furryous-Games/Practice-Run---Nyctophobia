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
	"Water Plants": {"Weight": 1, "Abnormality": 0},
	"Make Food": {"Weight": 1, "Abnormality": 0},
	"Wash Dishes": {"Weight": 1, "Abnormality": 0},
	"Organize Bookshelf": {"Weight": 1, "Abnormality": 0},
	#"Task 1": {"Weight": 1, "Abnormality": 0},
	#"Task 2": {"Weight": 1, "Abnormality": 0},
	#"Task 3": {"Weight": 1, "Abnormality": 0},
}

# Timer wait times
const TIMER := {
	&"toggle_on": 1,
	&"toggle_tween": 0.4,
	&"fade_in_tween": 1,
	&"fade_out": 1.5,
	&"fade_out_l": 2,
}

# Master grid for information about the house
var house_grid: Array = []
var curr_room := Vector2i(0, 0)

# Holds information regarding the default room lighting; 1-6, Bright -> Dark
var room_lighting: int = 6 # 6
var window_emission: int = 1 # 1
var lamp_emission: int = 2 # 2

# Defines which objects are highlighted in the dark
var highlighted_objects = ["lamp"]

# The current day
var day: int = 0
# What tasks are added to the selection pool according to their abnormality
var abnormality_level: int = 0
# Animation sequences on day start
var day_sequence: int = 0

# The number of tasks each day
var task_quantity: int = 4
# The tasks assigned each day
var task_list: Array[String]
# Assosiates each task_node's id with their respective task
var task_node_id: Dictionary
# Is the task list display toggled on
var is_task_list_toggled := false
# Can the player toggle the task list display
var toggle_lock := false

@onready var room_tilemap: TileMapLayer = $"TileSets/RoomTileMap"
@onready var objects_tilemap: TileMapLayer = $TileSets/ObjectsTileMap
@onready var shadow_tilemap: TileMapLayer = $"TileSets/ShadowTileMap"

@onready var player: Node2D = $"Player"
@onready var camera: Camera2D = $"Camera"

@onready var object_classes: Node = $"ObjectClasses"

@onready var sequence_timer: Timer = $SequenceTimer
@onready var ui_screen_fade: ColorRect = $UI/ScreenFade
@onready var ui_day: Label = $UI/ScreenFade/Day

@onready var ui_task_panel: Panel = $UI/TaskPanel
@onready var ui_heading: Label = $UI/TaskPanel/Heading
@onready var ui_task_list: VBoxContainer = $UI/TaskPanel/TaskListDisplay
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
						"object_type": null,
						"object": null,
						"interactable": null,
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

	ui_screen_fade.visible = true
	
	# To skip the opening sequence:
	#toggle_lock = true
	#day += 1
	#day_sequence = 3 
	
	day_sequence = 1
	new_day_sequence()


# Updates day-sensitive events (tasks, shadow progression, etc.)
# The animations, etc. to be played sequencially at day start
func new_day_sequence() -> void:
	match day_sequence:
		0: # Screen fade out, lock manual toggling (Day 2+ only)
			if is_task_list_toggled:
				toggle_task_list()
			toggle_lock = true
			
			var tween_fade: Tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
			tween_fade.tween_property(ui_screen_fade, "modulate:a", 2, 1.5)
			sequence_timer.wait_time = TIMER[&"fade_out"]
			sequence_timer.start()
		
		1: # Set day, lock manual toggling, text fade in, update light strength
			toggle_lock = true
			day += 1
			ui_day.text = "Day " + str(day)
			var tween_text_fade: Tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
			tween_text_fade.tween_property(ui_day, "self_modulate:a", 2, 1.5)
			sequence_timer.wait_time = TIMER[&"fade_out"]
			sequence_timer.start()
			
			ui_task_panel.size.y = 68
			# Adjusts the light strength according to the day
			if day == 1:
				if "lamp" not in highlighted_objects:
					highlighted_objects.append("lamp")
				room_lighting = 5
				window_emission = 1
				task_quantity = 4
				abnormality_level = 0
			elif day >= 7:
				room_lighting = 6
				window_emission = 6
				highlighted_objects.clear()
				if task_quantity < TASK_LIBRARY.size():
					task_quantity += 1
					ui_task_panel.size.y += 10
			else:
				room_lighting = 6
				window_emission = day - 1
				# Increase the number of tasks by 1 on days 2, 4, and 6
				#if day in [2, 4, 6]:
					#task_quantity += 1
					#ui_task_panel.size.y += 10
				#elif day == 5:
					#abnormality_level = 1
			
			shadow_tilemap.update_shadows()
		
		2: # Text fade out
			var tween_text_fade: Tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
			tween_text_fade.tween_property(ui_day, "self_modulate:a", 0, 2)
			sequence_timer.wait_time = TIMER[&"fade_out_l"]
			sequence_timer.start()
		
		3: # Set task list, screen fade in
			ui_heading.text = "DAY " + str(day) + ", TASKS:"
			add_tasks(true)
			
			var tween_fade: Tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
			tween_fade.tween_property(ui_screen_fade, "modulate:a", 0, 1.5)
			sequence_timer.wait_time = TIMER[&"fade_in_tween"]
			sequence_timer.start()
			
		4: # Start auto-toggle-on timer, enables player movement
			player.can_move = true
			sequence_timer.wait_time = TIMER[&"toggle_on"]
			sequence_timer.start()
			
		5: # Auto-open task list, unlock manual toggling, start auto-toggle-off timer
			toggle_task_list()
			toggle_lock = false
			auto_toggle.start()
		
		6: # End of day tasks
			ui_task_panel.size.y = 43
			add_tasks(false)
			toggle_task_list()
			toggle_lock = false
			auto_toggle.start()


# Adds tasks to the task list (randomized)
func add_tasks(day_start: bool) -> void:	
	task_list.clear()
	task_node_id.clear()
	
	# Tasks to be completed during the day
	if day_start:
		# Adds an additional copy of a task to the selection list according to their Weight value
		# Filters out tasks whose Abnormality is higher than the abnormality_level
		var weighted_task_list: Array
		for task_key in TASK_LIBRARY.keys().filter(func(is_abnormal): return TASK_LIBRARY[is_abnormal]["Abnormality"] <= abnormality_level):
			for i in TASK_LIBRARY[task_key]["Weight"]:
				weighted_task_list.append(task_key)
		
		# Adds tasks, filters out tasks already in list
		for i in task_quantity:
			task_list.append(weighted_task_list.filter(func(is_repeat): return is_repeat not in task_list).pick_random())

	# Tasks to end the day
	else:
		task_list.append_array(["Turn On TV", "Go To Bed"])
	
	# Creates Label nodes for each task as children of TaskListDisplay
	if ui_task_list.get_child_count() < (task_quantity if day_start else task_list.size()):
		for i in (task_quantity if day_start else task_list.size()) - ui_task_list.get_child_count():
			var task_node := Label.new()
			task_node.label_settings = preload("res://assets/label_settings/ui_text.tres")
			ui_task_list.add_child(task_node)
			task_node.text = "* " + task_list[i]
			task_node_id[task_list[i]] = task_node


# Handles input unrelated to the player character.
func _input(_devent: InputEvent) -> void:
	# Toggle task list [TAB, C]
	if Input.is_action_just_pressed(&"toggle_task_list"):
		if not toggle_lock:
			toggle_task_list()
			# Stops the auto toggle timer if the task list is manually detoggled then retoggled before the timer timeout
			if auto_toggle:
				auto_toggle.stop()
	
	# TEST Advances the day [Backspace, X]
	if Input.is_action_just_pressed(&"Interact2"):
		# Clears the task list
		for i in ui_task_list.get_child_count():
			ui_task_list.get_child(0).free()
		day_sequence = 0
		new_day_sequence()


# Clears the task after completion
func complete_task(complete: String) -> void:
	task_list.erase(complete)
	task_node_id[complete].free()
	task_node_id.erase(complete)
	
	# if task_list is empty add the end-of-day tasks
	if task_list.is_empty():
		toggle_lock = true
		if is_task_list_toggled:
			toggle_task_list()
		
		sequence_timer.wait_time = TIMER["fade_out"]
		sequence_timer.start()
			
	elif not is_task_list_toggled:
		toggle_task_list()
		auto_toggle.start()
	

# Toggles the task list
func toggle_task_list() -> void:
	var tween_panel: Tween = create_tween().set_ease(Tween.EASE_IN if is_task_list_toggled else Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
	tween_panel.tween_property(ui_task_panel, "position:x", -120 if is_task_list_toggled else 0, 0.4)
	is_task_list_toggled = not is_task_list_toggled


# Change room functions
func move_to_room(new_room: Vector2i, door_entered: String) -> bool:
	# Checks if the door is valid and unlocked
	if (
			# Checks that the expected room is within bounds
			new_room.x >= 0 and new_room.y >= 0 
			and new_room.x < HOUSE_SIZE.x and new_room.y < HOUSE_SIZE.y
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


# Increments day_sequence and calls new_day_sequence
func _on_sequence_timeout() -> void:
	day_sequence += 1
	new_day_sequence()


# Automatically detoggles the auto toggle
func _on_auto_toggle_timeout() -> void:
	if is_task_list_toggled:
		toggle_task_list()
