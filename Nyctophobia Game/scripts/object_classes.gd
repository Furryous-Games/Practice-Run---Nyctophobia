class_name Objects
extends Node

func get_object_from_furniture_type(type) -> Object:
	# Defines what furniture type corresponds to what object class
	return {
		"book_shelf": book_shelf_object.new(),
		"piano": null,
		"small_chair": null,
		"bench": null,
		"night_stand": null,
		"small_night_stand": null,
		"stool": null,
		"plant": plant_object.new(),
		"lamp": lamp_object.new(),
		
		"bed": bed_object.new(),
		"small_television": null,
		
		"countertop": countertop_object.new(),
		"sink": sink_object.new(),
		"oven": null,
		"fridge": null,
		"dining_table": null,
	} [type]


class lamp_object:
	var type := "lamp"
	var is_enabled := false
	
	func interact() -> void:
		is_enabled = not is_enabled


class book_shelf_object:
	var type := "Organize Bookshelf"
	var is_completed
	
	func interact() -> void:
		is_completed = true


class plant_object:
	var type := "Water Plants" # associated task
	var is_completed
	
	func interact() -> void:
		is_completed = true


class bed_object:
	var type := "bed"


class sink_object:
	var type := "Wash Dishes"
	var is_completed
	
	func interact() -> void:
		is_completed = true


class countertop_object:
	var type := "Make Food"
	var is_completed
	
	func interact() -> void:
		is_completed = true
