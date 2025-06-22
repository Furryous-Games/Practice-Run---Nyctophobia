extends TileMapLayer

var main_script = null

const wall_shadow_checks = [Vector2(0, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0)]

func update_shadows():
	var player_pos = Vector2i( (main_script.curr_room.x * 12) + main_script.player.player_pos.x, (main_script.curr_room.y * 10) + main_script.player.player_pos.y )
	
	var room_metadata = main_script.house_grid[main_script.curr_room[1]][main_script.curr_room[0]]
	var tile_brightness
	var tile_true_location
	
	# Resets the shadows for the floors
	for room_y in range(len(room_metadata)):
		for room_x in range(len(room_metadata[room_y])):
			room_metadata[room_y][room_x]["brightness"] = main_script.room_lighting
	
	
	# Update the shadows for the floors
	for room_y in range(len(room_metadata)):
		for room_x in range(len(room_metadata[room_y])):
			if room_metadata[room_y][room_x]["type"] == "floor":
				tile_true_location = Vector2i( (main_script.curr_room.x * 12) + room_x, (main_script.curr_room.y * 10) + room_y )
				tile_brightness = room_metadata[room_y][room_x]["brightness"]
				
				if tile_brightness > 5 and tile_true_location == player_pos:
					tile_brightness = 5
				
				room_metadata[room_y][room_x]["brightness"] = tile_brightness
	
	
	# Update the shadows for the walls
	var lowest_shadow_value
	var new_tile_location
	
	for room_y in range(len(room_metadata)):
		for room_x in range(len(room_metadata[room_y])):
			if room_metadata[room_y][room_x]["type"] != "floor" and room_metadata[room_y][room_x]["type"] != null:
				lowest_shadow_value = null
				
				tile_true_location = Vector2i( (main_script.curr_room.x * 12) + room_x, (main_script.curr_room.y * 10) + room_y )
				
				for floor_check in wall_shadow_checks:
					new_tile_location = Vector2i(room_x + floor_check.x, room_y + floor_check.y)
					if (
						new_tile_location.y >= 0 and new_tile_location.y < len(room_metadata) and 
						new_tile_location.x >= 0 and new_tile_location.x < len(room_metadata[new_tile_location.y])
						):
						if (
							room_metadata[new_tile_location.y][new_tile_location.x]["type"] == "floor" and 
							(lowest_shadow_value == null or room_metadata[new_tile_location.y][new_tile_location.x]["brightness"] <= lowest_shadow_value["brightness"])
							):
							lowest_shadow_value = room_metadata[new_tile_location.y][new_tile_location.x]
							lowest_shadow_value["location"] = Vector2i(new_tile_location.x, new_tile_location.y)
				
				if lowest_shadow_value:
					if lowest_shadow_value["brightness"] > 5 and lowest_shadow_value["location"] == player_pos:
						tile_brightness = 5
					else:
						tile_brightness = lowest_shadow_value["brightness"]
					
					room_metadata[room_y][room_x]["brightness"] = tile_brightness
	
	
	# Updates the shadows for corners
	for room_y in range(len(room_metadata)):
		for room_x in range(len(room_metadata[room_y])):
			if room_metadata[room_y][room_x]["type"] != "floor" and room_metadata[room_y][room_x]["type"] != null:
				lowest_shadow_value = null
				
				tile_true_location = Vector2i( (main_script.curr_room.x * 12) + room_x, (main_script.curr_room.y * 10) + room_y )
				
				for floor_check in wall_shadow_checks:
					new_tile_location = Vector2i(room_x + floor_check.x, room_y + floor_check.y)
					if (
						new_tile_location.y >= 0 and new_tile_location.y < len(room_metadata) and 
						new_tile_location.x >= 0 and new_tile_location.x < len(room_metadata[new_tile_location.y])
						):
						if (
							(room_metadata[room_y][room_x]["type"] == "wall_corner") and 
							(lowest_shadow_value == null or room_metadata[new_tile_location.y][new_tile_location.x]["brightness"] <= lowest_shadow_value["brightness"])
							):
							lowest_shadow_value = room_metadata[new_tile_location.y][new_tile_location.x]
							lowest_shadow_value["location"] = Vector2i(new_tile_location.x, new_tile_location.y)
				
				if lowest_shadow_value:
					if lowest_shadow_value["brightness"] > 5 and lowest_shadow_value["location"] == player_pos:
						tile_brightness = 5
					else:
						tile_brightness = lowest_shadow_value["brightness"]
					
					room_metadata[room_y][room_x]["brightness"] = tile_brightness
	
	draw_shadows()



func draw_shadows():
	var room_metadata = main_script.house_grid[main_script.curr_room[1]][main_script.curr_room[0]]
	var tile_true_location
	var tile_brightness
	
	# Change the shadows for the floors
	for room_y in range(len(room_metadata)):
		for room_x in range(len(room_metadata[room_y])):
			if room_metadata[room_y][room_x]["type"] != null:
				tile_true_location = Vector2i( (main_script.curr_room.x * 12) + room_x, (main_script.curr_room.y * 10) + room_y )
				tile_brightness = room_metadata[room_y][room_x]["brightness"]
				
				set_cell(tile_true_location, 0, Vector2i(0, 0), tile_brightness)
