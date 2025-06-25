extends Node

func get_object_from_furniture_type(type) -> Object:
	# Defines what furniture type corresponds to what object class
	return {
		"book_shelf": null,
		"piano": null,
		"small_chair": null,
		"bench": null,
		"night_stand": null,
		"small_night_stand": null,
		"stool": null,
		"plant": null,
		"lamp": lamp_object.new(),
		
		"bed": null,
		"small_television": null,
		
		"countertop": null,
		"sink": null,
		"oven": null,
		"fridge": null,
		"dining_table": null,
	} [type]

class lamp_object:
	var type = "lamp"
	var is_enabled = false
	
	func interact() -> void:
		is_enabled = not is_enabled
