extends Node
class_name LevelMapGenerator

enum NodeType { START, BATTLE, ELITE, SHOP, REST, BOSS }
enum Direction { UP = 0, RIGHT = 1, DOWN = 2, LEFT = 3 }

const CONFIG = {
	"max_width": 9,
	"max_height": 7,
	"rooms_per_level": {
		1: 14,  # 第一层房间数
		2: 18,  # 第二层房间数
		3: 22,  # 第三层房间数
		4: 26   # 第四层房间数
	},
	"min_dead_ends": {
		1: 4,   # 第一层最少4条死路
		2: 5,   # 其他层最少5条死路
		3: 5,
		4: 5
	},
	"max_dead_ends": {
		1: 5,   # 第一层最多5条死路
		2: 6,   # 其他层最多6条死路
		3: 6,
		4: 6
	},
	"elite_chance": 20
}

class MapNode:
	var type: NodeType
	var position: Vector2
	var grid_position: Vector2i
	
	func _init(n_type: NodeType, grid_pos: Vector2i):
		type = n_type
		grid_position = grid_pos
		position = Vector2(grid_pos.x * 112 + 500, grid_pos.y * 112 + 300)

	func to_dict() -> Dictionary:
		return {
			"type": int(type),  # 假设你用数字表示枚举
			"position": {"x": position.x, "y": position.y},
			"grid_position": {"x": grid_position.x, "y": grid_position.y}
	}

var grid: Dictionary = {}  # Vector2i -> MapNode
var start_node: MapNode
var boss_node: MapNode
var current_level: int = 1
var current_dead_ends: Array = []  # 当前的死路节点列表

func serialize_grid() -> Dictionary:
	var serialized = {}
	for key in grid.keys():
		# 将 Vector2i 键转换为字符串，例如 "x_y"
		var key_str = str(key.x) + "_" + str(key.y)
		serialized[key_str] = grid[key].to_dict()
	return serialized


func generate_level(level: int) -> bool:
	print("\n=== Starting map generation for level", level, "===")
	current_level = level
	grid.clear()
	current_dead_ends.clear()
	
	# 在中心位置生成起始房间
	var center = Vector2i(CONFIG.max_width/2, CONFIG.max_height/2)
	start_node = MapNode.new(NodeType.START, center)
	grid[center] = start_node
	print("Created start node at", center)
	
	# 生成房间
	if _generate_rooms():
		# 选择最长的死路放置Boss
		print("Successfully generated rooms")
		var longest_dead_end = _find_longest_dead_end()
		if longest_dead_end:
			longest_dead_end.type = NodeType.BOSS
			boss_node = longest_dead_end
			print("Placed boss room at", longest_dead_end.grid_position)
			
			# 放置特殊房间
			if _place_special_rooms():
				print("Successfully placed special rooms")
				_set_elite_battles()
				_print_grid_state()
				return true
			else:
				print("Failed to place special rooms")
	else:
		print("failed to generate rooms")
	return false

func _generate_rooms() -> bool:
	var rooms_to_generate = CONFIG.rooms_per_level[current_level]
	print("\nStarting room generation. Need", rooms_to_generate, "rooms")
	var rooms_created = 1  # 已创建起始房间
	var expansion_positions = [start_node.grid_position]
	
	while rooms_created < rooms_to_generate and not expansion_positions.is_empty():
		var current_pos = expansion_positions.pop_front()
		print("\nProcessing position:", current_pos)
		# 检查当前位置是否是死路
		if not _is_dead_end(current_pos) and not (current_pos ==start_node.grid_position):
			print("Current position is invalid, skipping")
			continue
			
		var available_directions = _get_available_directions(current_pos)
		print("Available directions:", available_directions)
		available_directions.shuffle()
		
		for direction in available_directions:
			if rooms_created >= rooms_to_generate:
				break
				
			var next_pos = _get_next_position(current_pos, direction)
			print("Trying to place room at:", next_pos)
			if _can_place_room(next_pos):
				# 检查放置新房间后的死路数量
				if _would_exceed_max_dead_ends(next_pos):
					print("Would exceed max dead ends, skipping")
					continue
					
				var new_node = MapNode.new(NodeType.BATTLE, next_pos)
				grid[next_pos] = new_node
				expansion_positions.append(next_pos)
				rooms_created += 1
				print("Room placed. Total rooms:", rooms_created)
				print("Current expansion positions:", expansion_positions)
				# 更新死路列表
				_update_dead_ends(next_pos)
				print("Current dead ends:", current_dead_ends.size())
				
				# 如果已经达到最小死路数量，只在死路尾部继续扩展
				if current_dead_ends.size() >= CONFIG.min_dead_ends[current_level]:
					for pos in current_dead_ends:
						expansion_positions.append(pos)
					print("Reached min dead ends, filtering expansion positions")
					print("Remaining valid positions:", expansion_positions.size())
	print("\nRoom generation finished")
	print("Rooms created:", rooms_created)
	print("Dead ends:", current_dead_ends.size())
	print("Dead ends required: ", CONFIG.min_dead_ends[current_level], "-", CONFIG.max_dead_ends[current_level])
	# 检查最终的死路数量是否在允许范围内
	return (current_dead_ends.size() >= CONFIG.min_dead_ends[current_level] and 
			current_dead_ends.size() <= CONFIG.max_dead_ends[current_level])

func _would_exceed_max_dead_ends(new_pos: Vector2i) -> bool:
	# 计算添加新房间后可能的死路数量
	var temp_dead_ends = current_dead_ends.duplicate()
	print("\nChecking dead ends for position:", new_pos)
	print("Current dead ends:", temp_dead_ends.size())
	
	# 移除不再是死路的位置
	for direction in Direction.values():
		var check_pos = _get_next_position(new_pos, direction)
		if grid.has(check_pos) and _is_dead_end(check_pos):
			temp_dead_ends.erase(check_pos)
			print("Removed dead end at:", check_pos)
	
	# 检查新位置是否会成为死路
	if _would_be_dead_end(new_pos):
		temp_dead_ends.append(new_pos)
		print("Position would be new dead end")
	print("Projected dead ends:", temp_dead_ends.size())
	return temp_dead_ends.size() > CONFIG.max_dead_ends[current_level]

func _would_be_dead_end(pos: Vector2i) -> bool:
	var connected_count = 0
	for direction in Direction.values():
		var check_pos = _get_next_position(pos, direction)
		if grid.has(check_pos):
			connected_count += 1
	return connected_count == 1

func _update_dead_ends(new_pos: Vector2i) -> void:
	print("\nUpdating dead ends")
	var removed = []
	for pos in current_dead_ends.duplicate():
		if not _is_dead_end(pos):
			current_dead_ends.erase(pos)
			removed.append(pos)
	
	if removed:
		print("Removed dead ends:", removed)
	
	if _is_dead_end(new_pos):
		current_dead_ends.append(new_pos)
		print("Added new dead end:", new_pos)

func _filter_dead_end_positions(positions: Array) -> Array:
	var filtered = []
	for pos in positions:
		if _is_dead_end(pos):
			filtered.append(pos)
	return filtered

func _get_available_directions(pos: Vector2i) -> Array:
	var directions = []
	for direction in Direction.values():
		var next_pos = _get_next_position(pos, direction)
		if _can_place_room(next_pos) and not _would_create_loop(next_pos):
			directions.append(direction)
	return directions

func _would_create_loop(pos: Vector2i) -> bool:
	var adjacent_rooms = 0
	for direction in Direction.values():
		var check_pos = _get_next_position(pos, direction)
		if grid.has(check_pos):
			adjacent_rooms += 1
			if adjacent_rooms > 1:
				return true
	return false

func _can_place_room(pos: Vector2i) -> bool:
	return (pos.x >= 0 and pos.x < CONFIG.max_width and 
			pos.y >= 0 and pos.y < CONFIG.max_height and 
			not grid.has(pos))

func _get_next_position(current: Vector2i, direction: Direction) -> Vector2i:
	match direction:
		Direction.UP: return Vector2i(current.x, current.y - 1)
		Direction.RIGHT: return Vector2i(current.x + 1, current.y)
		Direction.DOWN: return Vector2i(current.x, current.y + 1)
		Direction.LEFT: return Vector2i(current.x - 1, current.y)
	return current

func _is_dead_end(pos: Vector2i) -> bool:
	if grid[pos].type == NodeType.START:
		return false
		
	var connected_rooms = 0
	for direction in Direction.values():
		var check_pos = _get_next_position(pos, direction)
		if grid.has(check_pos):
			connected_rooms += 1
	
	return connected_rooms == 1

func _find_longest_dead_end() -> MapNode:
	var longest_length = 0
	var longest_dead_end = null
	
	for pos in current_dead_ends:
		var length = _calculate_path_length(pos)
		if length > longest_length:
			longest_length = length
			longest_dead_end = grid[pos]
	
	return longest_dead_end

func _calculate_path_length(end_pos: Vector2i) -> int:
	var length = 0
	var current_pos = end_pos
	var visited = {}
	
	while true:
		visited[current_pos] = true
		
		if grid[current_pos].type == NodeType.START:
			break
			
		var found_next = false
		for direction in Direction.values():
			var next_pos = _get_next_position(current_pos, direction)
			if grid.has(next_pos) and not visited.has(next_pos):
				current_pos = next_pos
				length += 1
				found_next = true
				break
				
		if not found_next:
			return 0
	
	return length

func _place_special_rooms() -> bool:
	var available_rooms = []
	
	for pos in grid:
		var node = grid[pos]
		if node.type == NodeType.BATTLE:
			var can_be_special = true
			for direction in Direction.values():
				var check_pos = _get_next_position(pos, direction)
				if grid.has(check_pos):
					var check_node = grid[check_pos]
					if check_node.type in [NodeType.START, NodeType.BOSS, NodeType.SHOP, NodeType.REST]:
						can_be_special = false
						break
			if can_be_special:
				available_rooms.append(node)
	
	if available_rooms.size() < 2:
		return false
		
	available_rooms.shuffle()
	available_rooms[0].type = NodeType.SHOP
	available_rooms[1].type = NodeType.REST
	
	return true

func _set_elite_battles() -> void:
	for node in grid.values():
		if node.type == NodeType.BATTLE:
			if randi() % 100 < CONFIG.elite_chance:
				node.type = NodeType.ELITE

func get_node_scene(node: MapNode) -> String:
	match node.type:
		NodeType.START: return ""
		NodeType.BATTLE: return "res://Scenes/battle_scene.tscn"
		NodeType.ELITE: return "res://Scenes/battle_scene.tscn"
		NodeType.SHOP: return "res://Scenes/shop_scene.tscn"
		NodeType.REST: return "res://Scenes/temp_campfire_scene.tscn"
		NodeType.BOSS: return "res://Scenes/battle_scene.tscn"
	return ""

func _print_grid_state() -> void:
	print("\n=== Current Grid State ===")
	var min_x = 999
	var max_x = -999
	var min_y = 999
	var max_y = -999
	
	for pos in grid.keys():
		min_x = mini(min_x, pos.x)
		max_x = maxi(max_x, pos.x)
		min_y = mini(min_y, pos.y)
		max_y = maxi(max_y, pos.y)
	
	for y in range(min_y, max_y + 1):
		var line = ""
		for x in range(min_x, max_x + 1):
			var pos = Vector2i(x, y)
			if grid.has(pos):
				match grid[pos].type:
					NodeType.START: line += "S "
					NodeType.BATTLE: line += "B "
					NodeType.ELITE: line += "E "
					NodeType.SHOP: line += "$ "
					NodeType.REST: line += "R "
					NodeType.BOSS: line += "! "
			else:
				line += ". "
		print(line)
	print("=== End Grid State ===\n")
