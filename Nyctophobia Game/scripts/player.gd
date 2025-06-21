extends Node2D

# Stores the player's position in relation to the tiles; "5, 4" is the center of a 11x9 room
var player_pos: Array[int] = [5, 4]
# For tweening (allows for smooth movement)
var tween_pos: Tween


func _ready() -> void:
	self.position = Vector2(player_pos[0] * 20, player_pos[1] * 20)


# Whether or not a move command is currently being enacted
var executing := false
# To store the next input given while the movement animation is playing
var move_cue := []


# Handles user inputs
func _input(event: InputEvent) -> void:
	# return if not an accepted input; allows one additional input to be cued
	if (
		not event is InputEventKey
		or event.as_text() not in ["Up", "Down", "Right", "Left"]
		or event.is_released()
		or move_cue.size() > 1
	):
		return
	# Stores the input as text ("Up", "Down", "Right", "Left")
	var key: String = event.as_text()
	# Stores the next input to be played once the current ends
	move_cue.append([1 if key == "Up" or key == "Down" else 0, 1 if key == "Down" or key == "Right" else -1, key])
	
	# If animation is currently playing (move being performed): return
	if executing:
		return
	executing = true
	
	# Move player position; animates the movent
	# NOTE: Waiting until the full movement ends before accepting another input felt unresponsive. \
		# This remedies that, though it also doesn't feel quite right
	# Performs the cued movement inputs
	while move_cue.size() != 0:
		player_pos[move_cue[0][0]] += move_cue[0][1]
		tween_pos = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		tween_pos.tween_property(self, "position", Vector2(player_pos[0] * 20, player_pos[1] * 20), 0.2)
		# Sets the animation according to the direction of the input
		match move_cue[0][2]:
			"Up": $AnimatableBody2D/Sprite2D.animation = "walk_up"
			"Down": $AnimatableBody2D/Sprite2D.animation = "walk_down"
			"Left": $AnimatableBody2D/Sprite2D.animation = "walk_left"
			"Right": $AnimatableBody2D/Sprite2D.animation = "walk_right"
		$AnimatableBody2D/Sprite2D.frame = 1
		move_cue.remove_at(0)
		await get_tree().create_timer(0.2).timeout
		$AnimatableBody2D/Sprite2D.frame = 0
	executing = false
