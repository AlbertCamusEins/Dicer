extends Node

var Dice_type = ["Frien","Ac1","Ac2","Hex1","Hex2","Enemy_Frien","Enemy_Ac1","Enemy_Ac2","Enemy_Hex1","Enemy_Hex2"]
var active_dice_type:Array = []

signal dice_rolled(dice_type: String, results: Dictionary)

func _ready() -> void:
	dice_rolled.connect(_on_certain_dice_rolled)

func spawn_dice_at_position(dice_type:String, dice_position:Vector2):
	print("[DiceManager] Spawning dice of type:", dice_type)
	var dice_node_scene = preload("res://Scenes/dice.tscn")
	var dice_node = dice_node_scene.instantiate()
	dice_node.name = dice_type + "-Dice"
	get_tree().current_scene.add_child(dice_node)
	dice_node.position = dice_position
	print("[DiceManager] Spawned dice with name:", dice_node.name)
	
func enable_certain_dice(dice_type:String):
	active_dice_type.append(dice_type)
	update_all_dice_states()
	

func disable_certain_dice(dice_type:String):
	active_dice_type.erase(dice_type)
	update_all_dice_states()

func update_all_dice_states():
	var dice_nodes = get_tree().get_nodes_in_group("dice")
	for dice in dice_nodes:
		var is_active = active_dice_type.has(dice.dice_type)
		dice.set_clickable(is_active)

func _on_certain_dice_rolled(dice_type):
	
	match dice_type:
		"frien":
			enable_certain_dice("ac1")
			enable_certain_dice("ac2")
		"ac1":
			enable_certain_dice("hex1")
			disable_certain_dice("ac2")
			show_certain_dice("hex1")
			hide_certain_dice("hex2")

		"ac2":
			enable_certain_dice("hex2")
			disable_certain_dice("ac1")
			show_certain_dice("hex2")
			hide_certain_dice("hex1")
		"enemy_ac1":
			show_certain_dice("enemy_hex1")
			hide_certain_dice("enemy_hex2")
		
		"enemy_ac2":
			show_certain_dice("enemy_hex2")
			hide_certain_dice("enemy_hex1")

func roll_certain_dice(dice_type):
	var dice_nodes = get_tree().get_nodes_in_group("dice")
	for dice in dice_nodes:
		if dice.dice_type == dice_type:
			dice.play_rotate_animation()
			await dice.anim_sprite.animation_finished

func show_certain_dice(dice_type):
	var dice_nodes = get_tree().get_nodes_in_group("dice")
	for dice in dice_nodes:
		if dice.dice_type == dice_type:
			dice.show()

func hide_certain_dice(dice_type):
	var dice_nodes = get_tree().get_nodes_in_group("dice")
	for dice in dice_nodes:
		if dice.dice_type == dice_type:
			dice.hide()

# 在 DiceManager.gd 中
func auto_fill_dice_faces(dice_type: String) -> void:
	var available_faces = []
	
	# 根据骰子类型获取可用的面板
	match dice_type:
		"frien":
			available_faces = GameManager.current_run.inventory.get_faces("frien")
		"ac1":
			available_faces = GameManager.current_run.inventory.get_faces("common_action")
		"ac2":
			available_faces = GameManager.current_run.inventory.get_faces("uncommon_action")
		"hex2":
			available_faces = GameManager.current_run.inventory.get_faces("hex2")
		"enemy_frien":
			available_faces = GameDataManager.get_all_enemies()
		"enemy_ac1":
			available_faces = GameDataManager.get_all_common_actions()
		"enemy_ac2":
			available_faces = GameDataManager.get_all_uncommon_actions()
		"enemy_hex2":
			available_faces = GameDataManager.get_all_hexes()
	
	# 如果没有可用的面板，直接返回
	if available_faces.is_empty():
		print("[DiceManager] No available faces for dice type:", dice_type)
		return
	
	# 创建足够的面板来填充6个位置
	var faces_to_use = []
	while faces_to_use.size() < 6:
		for face in available_faces:
			if faces_to_use.size() < 6:
				faces_to_use.append(face)
	
	# 随机打乱要使用的面板
	faces_to_use.shuffle()
	
	# 为6个位置填充面板
	for i in range(6):
		var face_data = faces_to_use[i]
		var data_dict = {}
		
		match dice_type:
			"frien":
				data_dict = {
					"character_name": face_data.character_name,
					"texture_path": face_data.texture_path,
					"health": face_data.health,
					"traits": face_data.traits
				}
			"ac1":
				data_dict = {
					"action_name": face_data.action_name,
					"texture_path": face_data.texture_path,
					"effect": face_data.effect,
					"is_special": face_data.is_special
				}
			"ac2":
				data_dict = {
					"action_name": face_data.action_name,
					"texture_path": face_data.texture_path,
					"effect": face_data.effect,
					"is_special": face_data.is_special
				}
			"hex2":
				data_dict = face_data.to_dict()
			"enemy_frien":
				data_dict = {
					"enemy_name": face_data.enemy_name,
					"texture_path": face_data.texture_path,
					"health": face_data.health,
					"traits": face_data.traits
				}
			"enemy_ac1":
				data_dict = {
					"action_name": face_data.action_name,
					"texture_path": face_data.texture_path,
					"effect": face_data.effect,
					"is_special": face_data.is_special
				}
			"enemy_ac2":
				data_dict = {
					"action_name": face_data.action_name,
					"texture_path": face_data.texture_path,
					"effect": face_data.effect,
					"is_special": face_data.is_special
				}
			"enemy_hex2":
				data_dict = face_data.to_dict()
		
		# 更新骰面
		DiceFaceChanger.update_dice_face(dice_type, i , face_data.texture_path)
		EmbeddedDiceFaces.update_dice_face(dice_type, i , data_dict)

func reset_dice_state() -> void:
	active_dice_type.clear()
