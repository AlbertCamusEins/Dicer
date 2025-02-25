extends Node2D

var map_generator: LevelMapGenerator
var map_nodes: Dictionary = {}  # Vector2i -> Node2D
var room_scene = preload("res://Scenes/room.tscn")
var room_texture = {
	LevelMapGenerator.NodeType.START: preload("res://Assets/room-start.png"),
	LevelMapGenerator.NodeType.BATTLE: preload("res://Assets/room-battle.png"),
	LevelMapGenerator.NodeType.ELITE: preload("res://Assets/room-elite.png"),
	LevelMapGenerator.NodeType.SHOP: preload("res://Assets/room-shop.png"),
	LevelMapGenerator.NodeType.REST: preload("res://Assets/room-rest.png"),
	LevelMapGenerator.NodeType.BOSS: preload("res://Assets/room-boss.png")
}



func _ready() -> void:
	# 如果当前保存的场景是map场景，并且有保存的状态，就恢复状态
	if GameManager.current_scene_path == scene_file_path and not GameManager.current_scene_state.is_empty():
		print("[MapScene] Restoring saved state")
		_restore_map_state()
	else:
		print("[MapScene] Initializing new map")
		_initialize_map()
	
	# 更新已清理房间的视觉效果
	for room_pos in MapStateManager.cleared_rooms:
		if map_nodes.has(room_pos):
			_update_room_visual_state(room_pos)
	
	$Label2.text = "Floor " + str(GameManager.current_run.current_floor)

func _update_room_visual_state(pos: Vector2i) -> void:
	if map_nodes.has(pos):
		var room = map_nodes[pos]
		room.modulate = Color(0.5, 0.5, 0.5, 1.0)
		var area = room.get_node("Area2D")
		area.input_pickable = false

func _initialize_map() -> void:
	randomize()
	map_generator = LevelMapGenerator.new()
	var current_level = GameManager.current_run.current_floor
	
	if map_generator.generate_level(current_level):
		_create_map_visualization()
		MapStateManager.save_map_data(map_generator.serialize_grid())
	else:
		push_error("Failed to generate map")

func _restore_map_state() -> void:
	var map_data = MapStateManager.get_map_data()
	if map_data.size() > 0:
		map_generator = LevelMapGenerator.new()
		for key_str in map_data.keys():
			var data = map_data[key_str]
			var parts = key_str.split("_")
			if parts.size() == 2:
				var grid_pos = Vector2i(parts[0].to_int(), parts[1].to_int())
				var node_type = data.get("type", LevelMapGenerator.NodeType.BATTLE)
				var map_node = LevelMapGenerator.MapNode.new(node_type, grid_pos)
				map_generator.grid[grid_pos] = map_node
	else:
		_initialize_map()

	_create_map_visualization()

func _create_map_visualization():
	# 清除现有的节点
	for node in map_nodes.values():
		node.queue_free()
	map_nodes.clear()
	
	# 创建新节点
	for pos in map_generator.grid:
		var map_node = map_generator.grid[pos]
		var room = _create_room_node(map_node)
		map_nodes[pos] = room

func _create_room_node(map_node: LevelMapGenerator.MapNode) -> Node2D:
	var room = room_scene.instantiate()
	add_child(room)
	
	# 设置位置
	room.position = map_node.position
	
	# 设置texture
	var room_sprite = room.get_child(0)
	room_sprite.texture = room_texture[map_node.type]
	
	# 添加点击检测
	var area = room.get_node("Area2D")
	# 断开可能的现有连接
	for connection in area.input_event.get_connections():
		area.input_event.disconnect(connection.callable)
	# 连接新的信号
	area.input_event.connect(_on_room_input_event.bind(map_node))
	
	return room

func _on_room_input_event(_viewport, event: InputEvent, _shape_idx: int, map_node: LevelMapGenerator.MapNode):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not MapStateManager.is_room_cleared(map_node.grid_position):
			MapStateManager.set_current_room(map_node.grid_position)
			_enter_room(map_node)


func _enter_room(map_node: LevelMapGenerator.MapNode):
	GameManager.current_scene_state["current_room_position"] = map_node.grid_position
	# 如果房间已被清理，则不再进入
	if MapStateManager.is_room_cleared(map_node.grid_position):
		return
	
	# 获取对应场景路径
	var scene_path = map_generator.get_node_scene(map_node)
	
	match map_node.type:
		LevelMapGenerator.NodeType.BATTLE:
			BattleManager.set_battle_type(BattleManager.BattleType.BATTLE)
		LevelMapGenerator.NodeType.ELITE:
			BattleManager.set_battle_type(BattleManager.BattleType.ELITE_BATTLE)
		LevelMapGenerator.NodeType.BOSS:
			BattleManager.set_battle_type(BattleManager.BattleType.BOSS_BATTLE)
	
	# 切换到相应场景
	if scene_path != "":
		get_tree().change_scene_to_file(scene_path)


# 响应自定义骰子按钮
func _on_custom_dice_pressed():
	get_tree().change_scene_to_file("res://Scenes/custom_dice_scene.tscn")


func _on_pause_button_pressed() -> void:
	GameManager.pause_game()

func _exit_tree() -> void:
	GameManager.save_current_scene_state()
