extends Node2D

var main_script = null

@onready var player_sprite: AnimatedSprite2D = $"Player Sprite"
@onready var walk_cooldown: Timer = $"Walk Cooldown"

# Stores the player's position in relation to the tiles; "5, 4" is the center of a 11x9 room
var player_pos = Vector2(5, 4)
# For tweening (allows for smooth movement)
var tween_pos: Tween

func _ready() -> void:
	self.position = Vector2(player_pos[0] * 20, player_pos[1] * 20)

# Whether or not a move command is currently being enacted
var executing := false
# To store the next input given while the movement animation is playing
var next_movement = null


# Handles user inputs
func _input(event: InputEvent) -> void:
	if event.is_pressed():
		# Handles events for when a directional key is pressed
		if event.as_text() in ["Up", "Down", "Right", "Left", "W", "A", "S", "D"]:
			# return if not an accepted input; allows one additional input to be cued
			if (
				not event is InputEventKey
				or next_movement != null
			):
				return
			
			# Stores the input as text ("Up", "Down", "Right", "Left")
			var key: String = event.as_text()
			
			# Converts WASD keys into directional keys
			if key in ["W", "A", "S", "D"]:
				key = "Up" if key == "W" else "Right" if key == "D" else "Down" if key == "S" else "Left"
			
			var expected_movement = [
				Vector2(0 if not key in ["Left", "Right"] else 1 if key == "Right" else -1,
				0 if not key in ["Up", "Down"] else 1 if key == "Down" else -1),
				key
				]
			
			# Checks to ensure that the expected tile is clear
			var expected_tile_pos = player_pos + expected_movement[0]
			var expected_tile_metadata = main_script.house_grid[main_script.curr_room[1]][main_script.curr_room[0]][expected_tile_pos[1]][expected_tile_pos[0]]
			
			if expected_tile_metadata["type"] != "floor" or expected_tile_metadata["object"] != null:
				return
			
			# Stores the next input to be played once the current ends
			next_movement = expected_movement
			
			# If animation is currently playing (move being performed): return
			if executing:
				return
			executing = true
			
			# Move player position; animates the movent
			# NOTE: Waiting until the full movement ends before accepting another input felt unresponsive. \
				# This remedies that, though it also doesn't feel quite right
			# Performs the cued movement inputs
			move_player()
		
		# Handles events for when an interact key is pressed
		if event.as_text() in ["E", "Enter"]:
			var expected_tile_pos
			var expected_tile_metadata
			
			# Checks the surrounding tiles for interactable objects
			for check_tile_pos in [Vector2(0, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0)]:
				expected_tile_pos = player_pos + check_tile_pos
				expected_tile_metadata = main_script.house_grid[main_script.curr_room[1]][main_script.curr_room[0]][expected_tile_pos[1]][expected_tile_pos[0]]
				
				var door_room_change = {
					"door_n": Vector2(0, -1),
					"door_e": Vector2(1, 0),
					"door_s": Vector2(0, 1),
					"door_w": Vector2(-1, 0),
				}
				
				# Checks if the object is a door
				if expected_tile_metadata["type"] in door_room_change.keys():
					var expected_room = main_script.curr_room + door_room_change[expected_tile_metadata["type"]]
					print("There is a door here!")
					main_script.move_to_room(expected_room, expected_tile_metadata["type"])
					break

func move_player() -> void:
	# Checks if there is a cued movement
	if next_movement != null:
		# Updates the player's current position
		player_pos += next_movement[0]
		
		# Moves the player's visual smoothly along the planned path
		tween_pos = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		tween_pos.tween_property(self, "position", Vector2(player_pos[0] + (main_script.curr_room[0] * 12), player_pos[1] + (main_script.curr_room[1] * 10)) * 20, 0.2)
		
		# Sets the animation according to the direction of the input
		match next_movement[1]:
			"Up": player_sprite.animation = "walk_up"
			"Down": player_sprite.animation = "walk_down"
			"Left": player_sprite.animation = "walk_left"
			"Right": player_sprite.animation = "walk_right"
		player_sprite.frame = 1
		
		# Clears the player's next movement
		next_movement = null
		walk_cooldown.start()

func _on_walk_cooldown_timeout() -> void:
	player_sprite.frame = 0
	
	executing = false
	
	move_player()
