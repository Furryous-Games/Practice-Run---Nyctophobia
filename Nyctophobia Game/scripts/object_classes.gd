extends Node

class object: 
	var main_script
	var position := Vector2i(-1,-1)
	var type := "null_object"
	var connected_tiles := []
	var connected := false

class lamp_object extends object:
	var is_enabled := false
	
	func interact() -> void:
		is_enabled = not is_enabled

class bed_object extends object:
	
	func _init(node) -> void:
		main_script = node
	
	func interact() -> void:
		main_script.new_day()
