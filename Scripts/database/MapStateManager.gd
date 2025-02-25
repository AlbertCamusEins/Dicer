extends Node

# 单例，管理地图状态
var cleared_rooms: Array[Vector2i] = []
var current_room_position: Vector2i
var current_map_data: Dictionary = {}

func mark_room_as_cleared(pos: Vector2i) -> void:
	if not cleared_rooms.has(pos):
		cleared_rooms.append(pos)

func is_room_cleared(pos: Vector2i) -> bool:
	return cleared_rooms.has(pos)

func set_current_room(pos: Vector2i) -> void:
	current_room_position = pos

func get_current_room() -> Vector2i:
	return current_room_position

func save_map_data(data: Dictionary) -> void:
	current_map_data = data

func get_map_data() -> Dictionary:
	return current_map_data

func to_dict() -> Dictionary:
	var serialized_rooms = []
	for room in cleared_rooms:
		serialized_rooms.append({"x": room.x, "y": room.y})
	
	return {
		"cleared_rooms": serialized_rooms,
		"current_room": {
			"x": current_room_position.x,
			"y": current_room_position.y
		},
		"map_data": current_map_data
	}

func from_dict(data: Dictionary) -> void:
	cleared_rooms.clear()
	if data.has("cleared_rooms"):
		for room in data.cleared_rooms:
			cleared_rooms.append(Vector2i(room.x, room.y))
	
	if data.has("current_room"):
		current_room_position = Vector2i(
			data.current_room.x,
			data.current_room.y
		)
	
	if data.has("map_data"):
		current_map_data = data.map_data

func reset() -> void:
	cleared_rooms.clear()
	current_room_position = Vector2i()
	current_map_data.clear()
