extends Node2D

# Sets the player spawn coordinates, (5, 4) is the center of a 11x9 room
const PLAYER_SPAWN = Vector2i(5, 4)

# Stores the player's position in relation to the tiles
var player_pos: Vector2i

# For tweening
var tween_pos: Tween

# Whether or not a move command is currently being enacted
var executing := false

# Stores the next input given while the current movement is being executed
var next_movement = null

@onready var main_script: Node = $"../"
@onready var player_sprite: AnimatedSprite2D = $"PlayerSprite"
@onready var input_cooldown: Timer = $"InputCooldown"


func _ready() -> void:
	position = PLAYER_SPAWN * 20
	player_pos = PLAYER_SPAWN


# Handles user inputs
func _input(event: InputEvent) -> void:
	if not event.is_pressed() or executing:
		return
		
	# Handles directional inputs
	if (
			Input.is_action_pressed(&"move_up")
			or Input.is_action_pressed(&"move_right")
			or Input.is_action_pressed(&"move_down")
			or Input.is_action_pressed(&"move_left")
	):
		# Return if an input is cued or being executed
		if next_movement != null:
			return
		
		# Determines and stores the directional input
		var dir: StringName
		for input in [&"move_up", &"move_right", &"move_down", &"move_left"]:
			if Input.is_action_pressed(input):
				dir = input
				break
		
		# Stores the inputed vector2 position change and directional movement 
		var expected_movement := [
			Vector2i(
				int(Input.get_axis(&"move_left", &"move_right")) if dir in [&"move_left", &"move_right"] else 0,
				int(Input.get_axis(&"move_up", &"move_down")) if dir in [&"move_up", &"move_down"] else 0
			), 
			dir
		]
		
		# Checks to ensure that the expected tile is clear
		var expected_tile_pos: Vector2i = player_pos + expected_movement[0]
		var expected_tile_metadata: Dictionary = main_script.house_grid[main_script.curr_room[1]][main_script.curr_room[0]][expected_tile_pos[1]][expected_tile_pos[0]]
		
		if expected_tile_metadata["type"] != "floor" or (expected_tile_metadata["object"] != null and expected_tile_metadata["object"].type not in main_script.WALKABLE_OBJECTS):
			# Sets the animation according to the action
			match dir:
				&"move_up": player_sprite.animation = "walk_up"
				&"move_right": player_sprite.animation = "walk_right"
				&"move_down": player_sprite.animation = "walk_down"
				&"move_left": player_sprite.animation = "walk_left"
			player_sprite.frame = 0
			return
		
		# Stores the next input to be played once the current ends
		next_movement = expected_movement
		executing = true
		
		# Performs the cued movement inputs
		move_player()
	
	# Handles events for when an interact key is pressed
	elif Input.is_action_pressed(&"interact"):
		var expected_tile_pos
		var expected_tile_metadata
		
		var player_interacted = false
		
		var door_room_change = {
			"door_n": Vector2i(0, -1),
			"door_e": Vector2i(1, 0),
			"door_s": Vector2i(0, 1),
			"door_w": Vector2i(-1, 0),
		}
		
		# Checks the surrounding tiles for doors
		for check_tile_pos in [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]:
			expected_tile_pos = player_pos + check_tile_pos
			expected_tile_metadata = main_script.house_grid[main_script.curr_room[1]][main_script.curr_room[0]][expected_tile_pos[1]][expected_tile_pos[0]]
			
			# Checks if the object is a door
			if expected_tile_metadata["type"] in door_room_change.keys():
				var expected_room = main_script.curr_room + door_room_change[expected_tile_metadata["type"]]
				#print("There is a door here!")
				if main_script.move_to_room(expected_room, expected_tile_metadata["type"]):
					player_interacted = true
					break
		
		if not player_interacted:
			# Checks the surrounding tiles for interactable objects
			for check_tile_pos in [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]:
				expected_tile_pos = player_pos + check_tile_pos
				expected_tile_metadata = main_script.house_grid[main_script.curr_room[1]][main_script.curr_room[0]][expected_tile_pos[1]][expected_tile_pos[0]]
				
				# Checks if the player can interact with the object
				if expected_tile_metadata["object"] != null:
					expected_tile_metadata["object"].interact()
					
					# Updates the room's shadows
					main_script.shadow_tilemap.update_shadows()
					break


func move_player() -> void:
	# Checks if there is a cued movement
	if next_movement != null:
		# Updates the player's current position
		player_pos += next_movement[0]
		
		# Moves the player's visual smoothly along the planned path
		tween_pos = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		#tween_pos.tween_property(self, "position", Vector2(player_pos[0] + (main_script.curr_room[0] * 12), player_pos[1] + (main_script.curr_room[1] * 10)) * 20, 0.4)
		tween_pos.tween_property(self, "position", Vector2(player_pos[0] + (main_script.curr_room[0] * 12), player_pos[1] + (main_script.curr_room[1] * 10)) * 20, 0.2)
		
		# Sets the animation according to the direction of the input
		match next_movement[1]:
			&"move_up": player_sprite.animation = "walk_up"
			&"move_down": player_sprite.animation = "walk_down"
			&"move_left": player_sprite.animation = "walk_left"
			&"move_right": player_sprite.animation = "walk_right"
		player_sprite.frame = 1
		
		# Clears the player's next movement
		next_movement = null
		input_cooldown.start()
		
		# Updates the room's shadows
		main_script.shadow_tilemap.update_shadows()


# Timer before inputs are accepted
func _on_input_cooldown_timeout() -> void:
	player_sprite.frame = 0
	executing = false
	move_player()
