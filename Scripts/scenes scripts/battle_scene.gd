extends Node2D

var cast_hex: bool = false
@onready var dice_container = $DiceContainer
@onready var switch_button = $Switch


func _ready() ->void:
	# 检查是否有保存的状态要恢复
	if GameManager.current_scene_path == scene_file_path and not GameManager.current_scene_state.is_empty():
		print("[BattleScene] Restoring saved state")
		_restore_battle_state()
	else:
		print("[BattleScene] Starting new battle")
		_initialize_new_battle()
	
	
	var uncommon_act_dice = $".".get_node("Ac2-Dice")
	var enemy_uncommon_act_dice = $".".get_node("Enemy_Ac2-Dice")
	var hex2_dice = $".".get_node("Hex2-Dice")
	var enemy_hex2_dice = $".".get_node("Enemy_Hex2-Dice")
	
	uncommon_act_dice.hide()
	hex2_dice.hide()
	enemy_uncommon_act_dice.hide()
	enemy_hex2_dice.hide()
	

func _restore_battle_state() -> void:
	var state = GameManager.current_scene_state
	
	# 恢复战斗状态
	BattleManager.phase_count = state.get("phase_count", 1)
	BattleManager.current_state = state.get("battle_state", BattleManager.BattleState.ENEMY_ROLLING)
	
	# 恢复角色数据
	if state.has("player_data"):
		BattleManager.player_data = BattleManager.PlayerData.new()
		for char_name in state["player_data"]:
			var char_state = state["player_data"][char_name]
			BattleManager.player_data.player_characters[char_name] = char_state.duplicate(true)
	
	if state.has("enemy_data"):
		BattleManager.enemy_data = BattleManager.EnemyTeam.new()
		for enemy_name in state["enemy_data"]:
			var enemy_state = state["enemy_data"][enemy_name]
			BattleManager.enemy_data.enemy_fiends[enemy_name] = enemy_state.duplicate(true)
	
	# 恢复骰面数据
	if state.has("embedded_faces"):
		EmbeddedDiceFaces.from_dict(state.embedded_faces)
	
	# 重新加载场景元素
	load_available_die_and_else()
	
	# 恢复玩家骰子骰面
	apply_stored_player_frien_dice_faces()
	apply_stored_player_common_ac_dice_faces()
	apply_stored_player_uncommon_ac_dice_faces()
	apply_stored_player_hex_dice_faces()
	
	# 恢复敌人骰子骰面
	apply_stored_enemy_dice_faces()
	
	# 重新连接信号
	if not BattleManager.is_connected("battle_state_changed", _on_battle_state_changed):
		BattleManager.connect("battle_state_changed", _on_battle_state_changed)
	
	BattleManager.start_battle()

func _initialize_new_battle() -> void:
	# 原有的初始化代码
	randomize()
	load_available_die_and_else()
	apply_stored_player_frien_dice_faces()
	apply_stored_player_common_ac_dice_faces()
	apply_stored_player_uncommon_ac_dice_faces()
	apply_stored_player_hex_dice_faces()
	DiceManager.auto_fill_dice_faces("enemy_frien")
	DiceManager.auto_fill_dice_faces("enemy_ac1")
	DiceManager.auto_fill_dice_faces("enemy_ac2")
	DiceManager.auto_fill_dice_faces("enemy_hex2")
	
	if not BattleManager.is_connected("battle_state_changed", _on_battle_state_changed):
		BattleManager.connect("battle_state_changed", _on_battle_state_changed)
	
	BattleManager.start_new_battle()

func _on_battle_state_changed(current_state: BattleManager.BattleState) -> void:
	match current_state:
		BattleManager.BattleState.ENEMY_ROLLING:
			await DiceManager.roll_certain_dice("enemy_frien")
			#var coin_index = randi() % 2 
			var coin_index = 0
			match coin_index:
				0:
					DiceManager.hide_certain_dice("enemy_ac2")
					DiceManager.hide_certain_dice("enemy_hex2")
					DiceManager.show_certain_dice("enemy_ac1")
					DiceManager.show_certain_dice("enemy_hex1")
					await DiceManager.roll_certain_dice("enemy_ac1")
					await DiceManager.roll_certain_dice("enemy_hex1")
				1:
					DiceManager.show_certain_dice("enemy_ac2")
					DiceManager.show_certain_dice("enemy_hex2")
					DiceManager.hide_certain_dice("enemy_ac1")
					DiceManager.hide_certain_dice("enemy_hex1")
					await DiceManager.roll_certain_dice("enemy_ac2")
					await DiceManager.roll_certain_dice("enemy_hex2")
			print("enemy rolled")
		BattleManager.BattleState.PLAYER_ROLLING:
			DiceManager.enable_certain_dice("frien")
			print("player roll")

		BattleManager.BattleState.FINISHED:
			print("battle end")
			
			

func load_available_die_and_else():
	var available_die = DiceManager.Dice_type
	var container_pos = dice_container.position
	var cell_side_length = 112
	var grid_cols = 3
	var _grid_rows = 2
	
	for i in range(available_die.size()):
		var dice_type = available_die[i]
		var merge_count = 0
		if i >= 2:
			merge_count += 1
		if i >= 4:
			merge_count += 1
		if i >= 7:
			merge_count += 1
		if i >= 9:
			merge_count += 1
		
		var effective_index = i - merge_count
		@warning_ignore("integer_division")
		var row = effective_index / grid_cols
		var col = effective_index % grid_cols
		
		var pos = Vector2(
			container_pos.x - 112 + (col * cell_side_length),
			container_pos.y - 56 + (row * cell_side_length)
		)
		
		DiceManager.spawn_dice_at_position(dice_type, pos)
		print(dice_type, pos)
	
	switch_button.position = Vector2(
			container_pos.x -112 + ((1 % grid_cols) * cell_side_length) - (switch_button.size.x / 2),
			container_pos.y -150 + (1 / grid_cols * cell_side_length) - (switch_button.size.y / 2)
		)



func apply_stored_player_frien_dice_faces() ->void:
	var friend_faces = EmbeddedDiceFaces.get_dice_faces("frien")

	for face_index in friend_faces.keys():
		var character_data = friend_faces[face_index]
		if character_data.texture_path != "":
			DiceFaceChanger.update_dice_face("frien", face_index, character_data.texture_path)

func apply_stored_player_common_ac_dice_faces() ->void:
	var action_faces = EmbeddedDiceFaces.get_dice_faces("ac1")

	for face_index in action_faces.keys():
		var action_data = action_faces[face_index]
		if action_data.texture_path != "":
			DiceFaceChanger.update_dice_face("ac1", face_index, action_data.texture_path)

func apply_stored_player_uncommon_ac_dice_faces() ->void:
	var action_faces = EmbeddedDiceFaces.get_dice_faces("ac2")

	for face_index in action_faces.keys():
		var action_data = action_faces[face_index]
		if action_data.texture_path != "":
			DiceFaceChanger.update_dice_face("ac2", face_index, action_data.texture_path)

func apply_stored_player_hex_dice_faces() ->void:
	var hex_faces = EmbeddedDiceFaces.get_dice_faces("hex2")

	for face_index in hex_faces.keys():
		var hex_data = hex_faces[face_index]
		if hex_data.texture_path != "":
			DiceFaceChanger.update_dice_face("hex2", face_index, hex_data.texture_path)

func apply_stored_enemy_dice_faces() -> void:
	# 恢复敌方角色骰子
	var enemy_faces = EmbeddedDiceFaces.get_dice_faces("enemy_frien")
	for face_index in enemy_faces.keys():
		var enemy_data = enemy_faces[face_index]
		if enemy_data.texture_path != "":
			DiceFaceChanger.update_dice_face("enemy_frien", face_index, enemy_data.texture_path)
	
	# 恢复敌方普通行动骰子
	var enemy_ac1_faces = EmbeddedDiceFaces.get_dice_faces("enemy_ac1")
	for face_index in enemy_ac1_faces.keys():
		var action_data = enemy_ac1_faces[face_index]
		if action_data.texture_path != "":
			DiceFaceChanger.update_dice_face("enemy_ac1", face_index, action_data.texture_path)
	
	# 恢复敌方特殊行动骰子
	var enemy_ac2_faces = EmbeddedDiceFaces.get_dice_faces("enemy_ac2")
	for face_index in enemy_ac2_faces.keys():
		var action_data = enemy_ac2_faces[face_index]
		if action_data.texture_path != "":
			DiceFaceChanger.update_dice_face("enemy_ac2", face_index, action_data.texture_path)
	
	# 恢复敌方法术骰子
	var enemy_hex_faces = EmbeddedDiceFaces.get_dice_faces("enemy_hex")
	for face_index in enemy_hex_faces.keys():
		var hex_data = enemy_hex_faces[face_index]
		if hex_data.texture_path != "":
			DiceFaceChanger.update_dice_face("enemy_hex", face_index, hex_data.texture_path)


func _on_switch_pressed() -> void:
	if not cast_hex:
		$".".get_node("Ac1-Dice").hide()
		$".".get_node("Ac2-Dice").show()
		cast_hex = true
	else:
		$".".get_node("Ac2-Dice").hide()
		$".".get_node("Ac1-Dice").show()
		cast_hex = false


func _on_d_ice_pressed() -> void:
	var caster
	for result in BattleManager.dice_results:
		if result.dice_type == "frien":
			caster = EmbeddedDiceFaces.frien_dice_faces[result.face_up_value]
	
	var enemy_caster
	for result in BattleManager.dice_results:
		if result.dice_type == "enemy_frien":
			enemy_caster = EmbeddedDiceFaces.enemy_frien_dice_faces[result.face_up_value]
	# 检查是否投掷了ac1骰子（普通行动）
	if "ac1" in BattleManager.rolled_dice:
		BattleManager.clear_all_player_shield()
		BattleManager.check_action_triggers(caster)
		await get_tree().create_timer(1.0).timeout
	elif "ac2" in BattleManager.rolled_dice:
		BattleManager.clear_all_player_shield()
		BattleManager.check_hex_triggers(caster)
		await get_tree().create_timer(1.0).timeout
	
	if "enemy_ac1" in BattleManager.rolled_dice:
		BattleManager.clear_all_enemy_shield()
		BattleManager.check_enemy_action_triggers(enemy_caster)
		await get_tree().create_timer(1.0).timeout
	
	BattleManager._check_battle_end()
	if BattleManager.battle_result != "":
		get_tree().change_scene_to_file("res://Scenes/battle_result.tscn")


func _on_next_round_pressed() -> void:
	BattleManager.enter_next_phase()

func _exit_tree() -> void:
	if BattleManager.battle_result != "victory":
		GameManager.save_current_scene_state()
	
	BattleManager.reset_battle_state()
	DiceManager.reset_dice_state()
	
	# 断开所有信号连接
	BattleManager.disconnect("battle_state_changed", _on_battle_state_changed)
	
	# 清理场景中的所有角色
	for child in get_children():
		if child.is_in_group("characters") or child.is_in_group("dice"):
			child.queue_free()


func _on_pause_button_pressed() -> void:
	GameManager.pause_game()
