extends TileMapLayer

const SHADOW_CHECKS = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, 0)]

var room_metadata: Array

@onready var main_script: Node = $"../../"

func update_shadows():
	# Updates the metadata for the current room
	room_metadata = main_script.house_grid[main_script.curr_room[1]][main_script.curr_room[0]]
	
	# Resets the shadows within the room
	reset_shadows()
	
	# Initializes variables for the update
	var lowest_shadow_value
	var new_tile_location: Vector2i
	var previous_room: Array
	
	# Sets the emissions for sources
	set_emissions()
	
	# Loops through the tiles to even out the light
	for i in range(4):
		# Duplicates the room metadata
		previous_room = room_metadata.duplicate(true)
		
		# Loops over all tiles in the room
		for room_y in range(len(previous_room)):
			for room_x in range(len(previous_room[room_y])):
				# Only affects floor tiles
				if previous_room[room_y][room_x]["type"] == "floor":
					# Resets the lowest shadow value and determines the global tile location of the tile in the room
					lowest_shadow_value = null
					
					# Loops over the surrounding tiles
					for floor_check in SHADOW_CHECKS:
						# Determines the local position of the checked tile
						new_tile_location = Vector2i(room_x + floor_check.x, room_y + floor_check.y)
						# Checks if the tile is within the room
						if (
								new_tile_location.y >= 0 
								and new_tile_location.y < len(previous_room)
								and new_tile_location.x >= 0 
								and new_tile_location.x < len(previous_room[new_tile_location.y])
						):
							# Checks if the checked tile is of type floor, and checks if the brightness is lower than the current lowest brightness
							if (
									previous_room[new_tile_location.y][new_tile_location.x]["type"] == "floor"
									and (lowest_shadow_value == null or previous_room[new_tile_location.y][new_tile_location.x]["brightness"] < lowest_shadow_value["brightness"])
							):
								# Sets the current lowest brightness to the new lowest brightness
								lowest_shadow_value = previous_room[new_tile_location.y][new_tile_location.x]
								lowest_shadow_value["location"] = Vector2i(new_tile_location.x, new_tile_location.y)
					
					# If a lowest shadow value was found...
					if lowest_shadow_value:
						# Set the metadata for the tile's brightness to 1 more than the found tile, with a maximum value of 5 if the player is standing on the tile, otherwise 6
						room_metadata[room_y][room_x]["brightness"] = min(lowest_shadow_value["brightness"] + 1, main_script.room_lighting)
		
		set_emissions()
	
	# Caps the brightness of the tile the player is standing on to 5
	cap_tile_brightness(main_script.player.player_pos, 5)
	
	# Highlight tiles with objects on them close to the player
	for floor_check in SHADOW_CHECKS:
		# Determines the local position of the checked tile
		new_tile_location = Vector2i(main_script.player.player_pos.x + floor_check.x, main_script.player.player_pos.y + floor_check.y)
		# Checks if the tile is within the room, has an object on it, and is not walkable
		if (
				new_tile_location.y >= 0 
				and new_tile_location.y < len(room_metadata)
				and new_tile_location.x >= 0 
				and new_tile_location.x < len(room_metadata[new_tile_location.y])
				and room_metadata[new_tile_location.y][new_tile_location.x]["object_type"] != null
				and room_metadata[new_tile_location.y][new_tile_location.x]["object_type"] not in main_script.WALKABLE_OBJECTS
		):
			# Highlight the object's tile
			cap_tile_brightness(new_tile_location, 5)
	
	# Highlight important objects as defined in the main script
	for room_y in range(len(previous_room)):
		for room_x in range(len(previous_room[room_y])):
			if previous_room[room_y][room_x]["object_type"] in main_script.highlighted_objects:
				cap_tile_brightness(Vector2i(room_x, room_y), 5)
	
	# Update the shadows for the walls
	for room_y in range(len(room_metadata)):
		for room_x in range(len(room_metadata[room_y])):
			# Only affects valid non-floor tiles
			if room_metadata[room_y][room_x]["type"] != "floor" and room_metadata[room_y][room_x]["type"] != null:
				# Resets the lowest shadow value and determines the global tile location of the tile in the room
				lowest_shadow_value = null
				
				# Loops over the surrounding tiles
				for floor_check in SHADOW_CHECKS:
					# Determines the local position of the checked tile
					new_tile_location = Vector2i(room_x + floor_check.x, room_y + floor_check.y)
					# Checks if the tile is within the room
					if (
							new_tile_location.y >= 0 
							and new_tile_location.y < len(room_metadata)
							and new_tile_location.x >= 0 
							and new_tile_location.x < len(room_metadata[new_tile_location.y])
					):
						# Checks if the checked tile is of type floor, and checks if the brightness is lower than the current lowest brightness
						if (
								room_metadata[new_tile_location.y][new_tile_location.x]["type"] == "floor"
								and (lowest_shadow_value == null or room_metadata[new_tile_location.y][new_tile_location.x]["brightness"] <= lowest_shadow_value["brightness"])
						):
							# Sets the current lowest brightness to the new lowest brightness
							lowest_shadow_value = room_metadata[new_tile_location.y][new_tile_location.x].duplicate(true)
							lowest_shadow_value["location"] = Vector2i(new_tile_location.x, new_tile_location.y)
				
				# If a lowest shadow value was found...
				if lowest_shadow_value:
					# Set the metadata for the tile's brightness to the found tile
					room_metadata[room_y][room_x]["brightness"] = lowest_shadow_value["brightness"]
	
	
	# Updates the shadows for corners
	for room_y in range(len(room_metadata)):
		for room_x in range(len(room_metadata[room_y])):
			# Only affects valid non-floor tiles
			if room_metadata[room_y][room_x]["type"] != "floor" and room_metadata[room_y][room_x]["type"] != null:
				# Resets the lowest shadow value and determines the global tile location of the tile in the room
				lowest_shadow_value = null
				
				# Loops over the surrounding tiles
				for floor_check in SHADOW_CHECKS:
					# Determines the local position of the checked tile
					new_tile_location = Vector2i(room_x + floor_check.x, room_y + floor_check.y)
					# Checks if the tile is within the room
					if (
							new_tile_location.y >= 0 
							and new_tile_location.y < len(room_metadata)
							and new_tile_location.x >= 0 
							and new_tile_location.x < len(room_metadata[new_tile_location.y])
					):
						# Checks if the tile is a wall corner, and checks if the checked tile's brightness is lower than the current lowest brightness
						if (
								(room_metadata[room_y][room_x]["type"] == "wall_corner")
								and (lowest_shadow_value == null or room_metadata[new_tile_location.y][new_tile_location.x]["brightness"] <= lowest_shadow_value["brightness"])
						):
							# Sets the current lowest brightness to the new lowest brightness
							lowest_shadow_value = room_metadata[new_tile_location.y][new_tile_location.x].duplicate(true)
							lowest_shadow_value["location"] = Vector2i(new_tile_location.x, new_tile_location.y)
				
				# If a lowest shadow value was found...
				if lowest_shadow_value:
					room_metadata[room_y][room_x]["brightness"] = lowest_shadow_value["brightness"]
	
	# Updates the shadows onto the tilemap
	draw_shadows()


# Resets the shadows for the room back to the default room lighting
func reset_shadows():
	# Resets the shadows for the floors
	for room_y in range(len(room_metadata)):
		for room_x in range(len(room_metadata[room_y])):
			room_metadata[room_y][room_x]["brightness"] = main_script.room_lighting

# Sets the emissions for light sources
func set_emissions():
	# Sets the emissions for light sources
	for room_y in range(len(room_metadata)):
		for room_x in range(len(room_metadata[room_y])):
			# Only affects window tiles
			if room_metadata[room_y][room_x]["type"] == "window":
				update_emissions_for_tile(Vector2(room_x, room_y), main_script.window_emission)
			elif room_metadata[room_y][room_x]["object_type"] == "lamp" and room_metadata[room_y][room_x]["object"].is_enabled:
				update_emissions_for_tile(Vector2(room_x, room_y), main_script.lamp_emission)


# Helper function to cap the brightness for certain tiles given the location and maximum value
func cap_tile_brightness(tile_location: Vector2i, maximum_value: int) -> void:
	room_metadata[tile_location.y][tile_location.x]["brightness"] = min(room_metadata[tile_location.y][tile_location.x]["brightness"], maximum_value)

# Helper function to update the emissions given the type, location, and strength 
# Removed tile_type as it was unused
func update_emissions_for_tile(tile_location: Vector2, emission_strength: int) -> void:
	var new_tile_location: Vector2i
	# Determines the global tile location of the tile in the room
	
	# Loops over the surrounding tiles
	for floor_check in SHADOW_CHECKS:
		# Determines the local position of the checked tile
		new_tile_location = Vector2i(tile_location.x + floor_check.x, tile_location.y + floor_check.y)
		# Checks if the tile is within the room and is of type floor
		if (
				new_tile_location.y >= 0 
				and new_tile_location.y < len(room_metadata)
				and new_tile_location.x >= 0 
				and new_tile_location.x < len(room_metadata[new_tile_location.y])
				and room_metadata[new_tile_location.y][new_tile_location.x]["type"] == "floor"
		):
			# Sets the brightness of the tile to be equal to the emission value defined in the main script if the tile is darker than the emission value
			room_metadata[new_tile_location.y][new_tile_location.x]["brightness"] = min(emission_strength, room_metadata[new_tile_location.y][new_tile_location.x]["brightness"])


# Updates the shadow tilemap to display the shadow values to the player
func draw_shadows():
	var tile_true_location: Vector2i
	
	# Change the shadows for the floors
	for room_y in range(len(room_metadata)):
		for room_x in range(len(room_metadata[room_y])):
			# If the tile type is valid...
			if room_metadata[room_y][room_x]["type"] != null:
				# Determines the global tile location of the tile in the room
				tile_true_location = Vector2i( (main_script.curr_room.x * 12) + room_x, (main_script.curr_room.y * 10) + room_y )
				
				# Updates the tile on the tilemap to be equal to the brightness value of the tile
				set_cell(tile_true_location, 0, Vector2i(0, 0), room_metadata[room_y][room_x]["brightness"])


# Helper function to calculate the stress deficit
func get_shadow_level_at_coord(tile_location: Vector2):
	return room_metadata[tile_location.y][tile_location.x]["brightness"]
