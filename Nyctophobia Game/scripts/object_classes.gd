extends Node

class object: 
	var position := Vector2i(-1,-1)
	var type := "null_object"
	var connected_tiles := []
	var connected := false

class lamp_object extends object:
	var is_enabled := false
	
	func interact() -> void:
		is_enabled = not is_enabled
