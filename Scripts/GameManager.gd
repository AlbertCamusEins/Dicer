extends Node

# 当前游戏进程
var current_run: RunData = null
var pause_ui_instance: Node = null

# 全局游戏设置
var settings: Dictionary = {
	"sound_enabled": true,
	"music_enabled": true,
	"volume": 1.0
}

# 玩家的永久进度（解锁内容等）
var player_progress: Dictionary = {
	"unlocked_characters": [],  # 已解锁的角色
	"unlocked_actions": [],     # 已解锁的行动
	"unlocked_hexes": [],       # 已解锁的法术
	"achievements": {}          # 成就进度
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # 确保在游戏暂停时也能运行
	load_game()  # 加载存档

# 记录当前场景和状态
var current_scene_path: String = ""
var current_scene_state: Dictionary = {}

func save_current_scene_state() -> void:
	print("[GameManager] Saving current scene state")
	var current_scene = get_tree().current_scene
	
	# 保存当前场景路径
	current_scene_path = current_scene.scene_file_path
	print("[GameManager] Saved scene path:", current_scene_path)
	
	# 根据不同场景类型保存特定状态
	match current_scene_path:
		"res://Scenes/battle_scene.tscn":
			current_scene_state = {
				"battle_state": BattleManager.current_state,
				"battle_type": BattleManager.current_battle_type,
				"phase_count": BattleManager.phase_count,
				"player_data": BattleManager.player_data.player_characters.duplicate(true),
				"enemy_data": BattleManager.enemy_data.enemy_fiends.duplicate(true),
				"embedded_faces": EmbeddedDiceFaces.to_dict()
			}
		# 可以添加其他场景类型的状态保存
		"res://Scenes/map_scene.tscn":
			current_scene_state = MapStateManager.to_dict()
		"res://Scenes/shop_scene.tscn":
			# 保存商店状态
			var shop_state = {
				"items": [],
				"prices": {}
			}
			
			# 找到商店物品容器节点
			var shop_items = current_scene.get_node("ShopItems")
			
			# 保存未被购买的物品
			for item in shop_items.get_children():
				if item.visible:  # 只保存未被购买的物品
					var item_data = {}
					if item.character_data:
						item_data = {
							"type": "character",
							"data": {
								"character_name": item.character_data.character_name,
								"texture_path": item.character_data.texture_path,
								"health": item.character_data.health,
								"traits": item.character_data.traits,
								"prime_hex": item.character_data.prime_hex
							},
							"position": {"x": item.position.x, "y": item.position.y}
						}
					elif item.hex_data:
						item_data = {
							"type": "hex",
							"data": {
								"hex_name": item.hex_data.hex_name,
								"texture_path": item.hex_data.texture_path,
								"target_data": item.hex_data.target_data,
								"effect_data": item.hex_data.effect_data,
								"cast_condition": item.hex_data.cast_condition
							},
							"position": {"x": item.position.x, "y": item.position.y}
						}
					
					shop_state.items.append(item_data)
			
			# 保存价格标签信息
			var price_label = current_scene.get_node("Label2")
			if price_label and price_label.visible:
				shop_state.prices["current_price"] = int(price_label.text)
			
			current_scene_state = shop_state
	# 保存到磁盘
	save_game()

func clear_scene_state() -> void:
	current_scene_path = ""
	current_scene_state.clear()

# 开始新游戏
func start_new_game() -> void:
	current_run = RunData.new()
	EmbeddedDiceFaces.reset()
	MapStateManager.reset()
	save_game()
	get_tree().change_scene_to_file("res://Scenes/select_initial_friend.tscn")

# 结束当前游戏
func end_current_game(victory: bool) -> void:
	if victory:
		_handle_victory()
	else:
		_handle_defeat()
	
	current_run = null
	save_game()
	get_tree().change_scene_to_file("res://Scenes/main_menu_scene.tscn")

# 处理游戏胜利
func _handle_victory() -> void:
	# 更新解锁进度
	for face in current_run.inventory.get_faces("frien"):
		if not face.character_name in player_progress.unlocked_characters:
			player_progress.unlocked_characters.append(face.character_name)

	save_game()  # 保存进度

# 处理游戏失败
func _handle_defeat() -> void:
	# 可以在这里添加失败统计等逻辑
	pass

# 保存游戏进度
func save_game() -> void:
	var save_data = {
		"settings": settings,
		"player_progress": player_progress,
		"current_run": {
			"inventory": current_run.inventory.to_dict(),
			"gold": current_run.gold,
			"current_floor": current_run.current_floor,
			"scene_path": current_scene_path,
			"scene_state": current_scene_state,
			"map_state": MapStateManager.to_dict()
		} if current_run else null
	}
	
	var game_save = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	var json_string = JSON.stringify(save_data)
	game_save.store_line(json_string)
	print("[GameManager] Game saved successfully")

# 加载游戏进度
func load_game() -> void:
	if not FileAccess.file_exists("user://savegame.save"):
		print("[GameManager] No save file found")
		return
		
	var game_save = FileAccess.open("user://savegame.save", FileAccess.READ)
	var json_string = game_save.get_line()
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result == OK:
		var data = json.get_data()
		settings = data.get("settings", settings)
		player_progress = data.get("player_progress", player_progress)
		
		var run_data = data.get("current_run")
		if run_data:
			current_run = RunData.new()
			current_run.gold = run_data.get("gold", 0)
			current_run.current_floor = run_data.get("current_floor", 1)
			current_run.inventory.from_dict(run_data["inventory"])
			current_scene_path = run_data.get("scene_path", "")
			current_scene_state = run_data.get("scene_state", {})
			if run_data.has("map_state"):
				MapStateManager.from_dict(run_data.map_state)
			print("[GameManager] Loaded scene path:", current_scene_path)

# 暂停游戏
func pause_game() -> void:
	get_tree().paused = true
	var pause_screen = preload("res://Scenes/pause_screen.tscn")
	pause_ui_instance = pause_screen.instantiate()
	get_tree().current_scene.add_child(pause_ui_instance)

# 继续游戏
func resume_game() -> void:
	get_tree().paused = false
	if pause_ui_instance:
		pause_ui_instance.queue_free()
		pause_ui_instance = null

# 继续上次游戏
func continue_game() -> void:
	print("[GameManager] Attempting to continue game")
	load_game()
	
	if current_run and current_scene_path:
		print("[GameManager] Continuing to scene:", current_scene_path)
		get_tree().change_scene_to_file(current_scene_path)
	else:
		print("[GameManager] No saved game found")

# 退出到主菜单
func quit_to_main_menu() -> void:
	get_tree().paused = false
	save_current_scene_state()
	get_tree().change_scene_to_file("res://Scenes/main_menu_scene.tscn")

# 检查是否已解锁某个内容
func is_content_unlocked(content_type: String, content_id: String) -> bool:
	match content_type:
		"character":
			return content_id in player_progress.unlocked_characters
		"action":
			return content_id in player_progress.unlocked_actions
		"hex":
			return content_id in player_progress.unlocked_hexes
	return false

# 解锁新内容
func unlock_content(content_type: String, content_id: String) -> void:
	match content_type:
		"character":
			if not content_id in player_progress.unlocked_characters:
				player_progress.unlocked_characters.append(content_id)
		"action":
			if not content_id in player_progress.unlocked_actions:
				player_progress.unlocked_actions.append(content_id)
		"hex":
			if not content_id in player_progress.unlocked_hexes:
				player_progress.unlocked_hexes.append(content_id)
	
	save_game()  # 保存进度
