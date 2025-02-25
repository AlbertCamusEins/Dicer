extends Node

signal allied_health_changed(amount)
signal enemy_health_changed(amount)
signal allied_shield_changed(player_character, remaining_shield)
signal enemy_shield_changed(enemy_character, remaining_shield)
signal battle_won


var phase_count:int = 1
var current_state: BattleState = BattleState.ENEMY_ROLLING
var player_data = PlayerData.new()
var enemy_data = EnemyTeam.new()
var rolled_dice: Array =[]
var battle_result: String = ""

var current_caster = null
var last_target = null

var current_battle_type: BattleType = BattleType.BATTLE

enum BattleType {BATTLE, ELITE_BATTLE, BOSS_BATTLE}
enum TargetTeam { ALLY, ENEMY }
enum TargetType { CHARACTER, DICEFACE, DICE }
enum DiceType { FRIEND, ACTION, HEX }
enum DiceFace { UP, DOWN, SIDE }

enum EffectType { HEALTH_CHANGE, STATUS_APPLY }
enum StatusType { BUFF, DEBUFF, SPECIAL }



class PlayerData:
	var player_characters: Dictionary = {}
	func init_characters(char_data: CharacterData):
		var character_state = {
			"name": char_data.character_name,
			"texture_path": ("res://Assets/char-" + char_data.character_name + ".png"),
			"current_health": char_data.health,
			"max_health": char_data.health,
			"traits": char_data.traits,
			"shield": 0
		}
		player_characters[char_data.character_name] = character_state

class EnemyTeam:
	var enemy_fiends: Dictionary = {}
	func init_enemies(enemy_data: EnemyData):
		var enemy_state = {
			"name": enemy_data.enemy_name,
			"texture_path": ("res://Assets/enemy-" + enemy_data.enemy_name + ".png"),
			"current_health": enemy_data.health,
			"max_health": enemy_data.health,
			"traits": enemy_data.traits,
			"shield": 0
		}
		enemy_fiends[enemy_data.enemy_name] = enemy_state


enum BattleState {
	ENEMY_ROLLING,
	PLAYER_ROLLING,
	DICE,
	ENEMY_ACT,
	FINISHED
}

class DiceResult:
	var dice_type: String
	var face_up_value: int
	var face_down_value: int

var dice_result = DiceResult.new()
var dice_results: Array = []

@onready var character_scene = preload("res://Scenes/player_character.tscn")
@onready var enemy_scene = preload("res://Scenes/enemy_character.tscn")


@warning_ignore("unused_signal")
signal battle_state_changed(new_state: BattleState)
signal battle_ended(victory: bool)
signal phase_changed

func spawn_portraits():
	var character_array = GameManager.current_run.inventory.get_faces("frien")
	for character in character_array:
		player_data.init_characters(character)
	
	var character_offset = Vector2(200, 0)  # 角色之间的间距
	var ally_base_position = Vector2(200, 600)  # 第一个角色的位置
	
	for i in range(character_array.size()):
		var character = character_array[i]
		var spawn_position = ally_base_position + (character_offset * i)
		spawn_character_at_position(character, spawn_position)
	
	var enemy_offset = Vector2(-200, 0)
	var enemy_base_position = Vector2(1800, 600)
	
	var enemy_array = GameDataManager.enemies.values()
	for enemy in enemy_array:
		enemy_data.init_enemies(enemy)
	
	for i in range(enemy_array.size()):
		var enemy = enemy_array[i]
		var spawn_position = enemy_base_position + (enemy_offset * i)
		spawn_enemy_at_position(enemy, spawn_position)

func set_battle_type(type: BattleType) -> void:
	current_battle_type = type

func get_battle_type() -> BattleType:
	return current_battle_type

func start_new_battle() -> void:
	battle_result = ""
	player_data.player_characters.clear()
	enemy_data.enemy_fiends.clear()
	current_state = BattleState.ENEMY_ROLLING
	
	spawn_portraits()
	
	emit_signal("battle_state_changed", current_state)
	_enemy_roll_phase()
	
func start_battle() -> void:
	current_state = BattleState.ENEMY_ROLLING
	spawn_portraits()
	
	emit_signal("battle_state_changed", current_state)
	_enemy_roll_phase()

func _enemy_roll_phase():
	current_state = BattleState.PLAYER_ROLLING
	emit_signal("battle_state_changed", current_state)

func enter_next_phase():
	rolled_dice.clear()
	dice_results.clear()
	phase_count += 1
	emit_signal("phase_changed")
	current_state = BattleState.ENEMY_ROLLING
	emit_signal("battle_state_changed", current_state)
	_enemy_roll_phase()

func clear_all_player_shield():
	for character in player_data.player_characters:
		player_data.player_characters[character]["shield"] = 0
		emit_signal("allied_shield_changed", player_data.player_characters[character],0)

func clear_all_enemy_shield():
	for enemy in enemy_data.enemy_fiends:
		enemy_data.enemy_fiends[enemy]["shield"] = 0
		emit_signal("enemy_shield_changed", enemy_data.enemy_fiends[enemy],0)	

func spawn_character_at_position(character_data:CharacterData, pos: Vector2):
	var character = character_scene.instantiate()
	character.setup_character(character_data)
	character.name = character_data.character_name
	get_tree().current_scene.add_child(character)
	character.position = pos

func spawn_enemy_at_position(enemy_data:EnemyData, pos: Vector2):
	var enemy = enemy_scene.instantiate()
	enemy.setup_enemy(enemy_data)
	enemy.name = enemy_data.enemy_name
	get_tree().current_scene.add_child(enemy)
	enemy.position = pos

func update_character_health(character_name:String, amount:int):
	print("starting to update health")
	if player_data.player_characters.has(character_name):
		var char_state = player_data.player_characters[character_name]
		print("[BattleManager] Current player health: ", char_state.current_health)
		
		if amount < 0 :
			var shield_absorbed = min(abs(amount), char_state.shield)
			char_state.shield -= shield_absorbed
			var remaining_shield = char_state.shield
			amount += shield_absorbed
			print("[BattleManager] Shield absorbed: ", shield_absorbed, " remaining: ", remaining_shield)
			
			if remaining_shield > 0:
				print("shield remained")
				emit_signal("allied_shield_changed", player_data.player_characters[character_name], remaining_shield)
			elif amount < 0:
				print("shield broken")
				char_state.current_health = clamp(
		char_state.current_health + amount, 0, char_state.max_health
		)
				print("deal ", abs(amount)," damage to ally")
				emit_signal("allied_health_changed", amount)
		
		elif amount >= 0:
			char_state.current_health = clamp(
			char_state.current_health + amount, 0, char_state.max_health
		)
			emit_signal("allied_health_changed", amount)
	elif enemy_data.enemy_fiends.has(character_name):
		var char_state = enemy_data.enemy_fiends[character_name]
		print("[BattleManager] Current enemy health: ", char_state.current_health)
		
		if amount < 0 :
			var shield_absorbed = min(abs(amount), char_state.shield)
			char_state.shield -= shield_absorbed
			var remaining_shield = char_state.shield
			amount += shield_absorbed
			print("[BattleManager] Shield absorbed: ", shield_absorbed, " remaining: ", remaining_shield)
			
			if remaining_shield > 0:
				print("shield remained")
				emit_signal("enemy_shield_changed", enemy_data.enemy_fiends[character_name], remaining_shield)
			elif amount < 0:
				print("shield broken")
				char_state.current_health = clamp(
		char_state.current_health + amount, 0, char_state.max_health
		)
				print("deal ", abs(amount)," damage to enemy")
				emit_signal("enemy_health_changed", amount)
		
		elif amount >= 0:
			char_state.current_health = clamp(
			char_state.current_health + amount, 0, char_state.max_health
		)
			emit_signal("enemy_health_changed", amount)


func cast_hex(hex_data: HexData, caster) -> void:
	print("[BattleManager] Cast hex called with data:", JSON.stringify({
		"hex_name": hex_data.hex_name,
		"effect_data": hex_data.effect_data,
		"target_data": hex_data.target_data
	}))
	current_caster = caster
	last_target = null
	var targets = get_all_targets(hex_data)
	print("[BattleManager] Got targets:", targets)
	apply_all_effects(hex_data, targets)



func get_all_targets(hex_data: HexData) -> Dictionary:
	var targets = {}
	for i in range(hex_data.target_data.size()):
		targets[i] = get_targets(hex_data.target_data[i])
		if not targets[i].is_empty():
			last_target = targets[i][0]
	print("Final targets:", targets)
	return targets

func get_targets(target_info: Dictionary) -> Array:
	print("[BattleManager] Full target_info structure:", JSON.stringify(target_info))
	var results = []
	print("Getting targets with info: ", target_info)
	
	# 获取目标池
	var team = player_data.player_characters if target_info.team == TargetTeam.ALLY else enemy_data.enemy_fiends
	
	# 特殊条件处理
	if target_info.has("condition"):
		var condition = target_info.condition
		if condition.has("is_self") and condition.is_self:
			return [current_caster]
	
		# 根据目标类型处理
		match target_info.type:
			TargetType.CHARACTER:
				if condition.has("dice_reference"):
					var dice_ref = condition.dice_reference
					var face_value = -1
					
					print("Dice reference type:", dice_ref.type)
					print("HexData.DiceType.FRIEND =", HexData.DiceType.FRIEND)
					print("HexData.DiceType.ACTION =", HexData.DiceType.ACTION)
					print("HexData.DiceType.HEX =", HexData.DiceType.HEX)
					
					# 根据team和dice_type确定需要查找的骰子类型
					var dice_type_to_find = ""
					if target_info.team == 1: #TargetTeam.ENEMY
						print("Targeting enemy team")
						if dice_ref.type == 0: #friend
							dice_type_to_find = "enemy_frien"
							print("Selected enemy_frien")
						elif dice_ref.type == 1: #action
							dice_type_to_find = "enemy_ac1"
							print("Selected enemy_ac1")
						elif dice_ref.type == 2:  # HEX
							dice_type_to_find = "enemy_hex1"
							print("Selected enemy_hex1")
					else:
						match dice_ref.type:
							DiceType.FRIEND: dice_type_to_find = "frien"
							DiceType.ACTION: dice_type_to_find = "ac1"
							DiceType.HEX: dice_type_to_find = "hex1"
					
					print("Looking for dice type: ", dice_type_to_find)
					
					# 查找对应类型的最后一次投掷结果
					for result in dice_results:
						if result.dice_type == dice_type_to_find:
							if dice_ref.face == DiceFace.UP:
								face_value = result.face_up_value
							elif dice_ref.face == DiceFace.DOWN:
								face_value = result.face_down_value
							break
					
					print("Found face value: ", face_value)
					
					# 找到有效的骰子面后处理
					if face_value != -1:
						var dice_faces
						if dice_type_to_find.begins_with("enemy_"):
							dice_faces = EmbeddedDiceFaces.enemy_frien_dice_faces
						else:
							dice_faces = EmbeddedDiceFaces.frien_dice_faces
						
						print("Checking dice faces: ", dice_faces)
						
						if dice_faces and dice_faces.has(face_value):
							var target_char_name
							if dice_type_to_find.begins_with("enemy_"):
								target_char_name = dice_faces[face_value].enemy_name
							else:
								target_char_name = dice_faces[face_value].character_name
							
							print("Looking for character: ", target_char_name)
							if team.has(target_char_name):
								var target_data = team[target_char_name].duplicate(true)
								target_data["index"] = target_info.index
								results.append(target_data)
								print("Found target: ", target_char_name)
				else:
					# 如果没有骰子引用，添加所有有效目标
					for char_name in team:
						var target_data = team[char_name].duplicate()
						target_data["index"] = target_info.index
						results.append(target_data)
						
	
	return results

func apply_all_effects(hex_data: HexData, targets: Dictionary) -> void:
	print("[BattleManager] Applying all effects for hex:", hex_data.hex_name)
	print("[BattleManager] Effect data:", hex_data.effect_data)
	
	for effect in hex_data.effect_data:
		print("[BattleManager] Processing effect:", effect)
		var target_indices = effect.target_index
		print("[BattleManager] Target indices:", target_indices)
		
		if typeof(target_indices) != TYPE_ARRAY:
			target_indices = [target_indices]
			print("[BattleManager] Converted target indices to array:", target_indices)
		
		print("[BattleManager] Processing effect with target indices:", target_indices)
		for index in target_indices:
			print("[BattleManager] Processing target index:", index)
			var int_index = int(index)
			print("[BattleManager] targets with index: ", targets.has(index))
			if targets.has(int_index):
				print("[BattleManager] Applying effect to targets at index:", index)
				print("[BattleManager] Target data:", targets[int_index])
				apply_effect(effect, targets[int_index])
			else:
				print("[BattleManager] No targets found for index:", index)

# 应用单个效果
func apply_effect(effect: Dictionary, targets: Array) -> void:
	print("[BattleManager] Starting apply_effect")
	print("[BattleManager] Effect:", effect)
	print("[BattleManager] Targets:", targets)
	
	if not effect.has("type"):
		print("[BattleManager] ERROR: Effect has no type")
		return
	
	match effect.type:
		EffectType.HEALTH_CHANGE:
			print("[BattleManager] Applying health change effect")
			apply_health_change(effect, targets)
		EffectType.STATUS_APPLY:
			print("[BattleManager] Applying status effect")
			apply_status(effect, targets)
		_:
			print("[BattleManager] Unknown effect type:", effect.type)

func apply_health_change(effect:Dictionary, targets: Array) -> void:
	print("[BattleManager] Starting health change application")
	var value = effect.value
	print("[BattleManager] Health change value:", value)
	for target in targets:
		print("[BattleManager] Applying health change to target:", target.name)
		update_character_health(target.name, value)
		
func apply_status(effect:Dictionary, targets:Array) -> void:
	pass

func update_dice_result(dice_type:String, face_up_value:int) -> void:
	var result = DiceResult.new()
	result.dice_type = dice_type
	result.face_up_value = face_up_value
	result.face_down_value = 5 - face_up_value
	dice_result = result
	dice_results.append(result)
	rolled_dice.append(dice_type)
	print(dice_type, " dice rolled")
	print("last rolled dice: ", dice_type, " dice result: ", dice_result.face_up_value)

func get_certain_dice_result(dice_type:String):
	var face_up_index: int
	for dice_face_result in dice_results:
		if dice_face_result.dice_type == dice_type:
			face_up_index = dice_face_result.face_up_value
	return face_up_index

func check_hex_triggers(caster) -> void:
	# 遍历法术骰的六个面
	for face_index in [0,1,2,3,4,5]:
		var hex_data = EmbeddedDiceFaces.hex_dice_faces[face_index]
		if not hex_data or hex_data.hex_name.is_empty():
			continue
			
		# 检查是否满足触发条件
		match hex_data.cast_condition:
			DiceFace.UP:
				# 如果是正面触发且当前在正面
				if face_index == get_certain_dice_result("hex2"):
					print("cast hex faced up: ",hex_data)
					cast_hex(hex_data, caster)
			
			DiceFace.DOWN:
				# 如果是底面触发且当前在底面
				if face_index == dice_result.face_down_value:
					cast_hex(hex_data, caster)
			
			DiceFace.SIDE:
				# 如果是侧面触发且当前在侧面
				if face_index != dice_result.face_up_value and face_index != dice_result.face_down_value:
					cast_hex(hex_data, caster)

func check_action_triggers(caster) -> void:
	# 检查AC1骰子结果
	for result in dice_results:
		if result.dice_type == "ac1":
			var action_faces = EmbeddedDiceFaces.ac1_dice_faces
			var action_data = action_faces[result.face_up_value]
			
			# 获取hex1的值来决定行动强度
			var hex_value = 0
			for hex_result in dice_results:
				if hex_result.dice_type == "hex1":
					hex_value = hex_result.face_up_value + 1  # 转换为1-6范围
					break
			
			if hex_value > 0:
				resolve_action(action_data.action_name, hex_value)

func check_enemy_action_triggers(caster) -> void:
	# 检查ENEMY_AC1骰子结果
	for result in dice_results:
		if result.dice_type == "enemy_ac1":
			var action_faces = EmbeddedDiceFaces.enemy_ac1_dice_faces
			var action_data = action_faces[result.face_up_value]
			
			# 获取hex1的值来决定行动强度
			var hex_value = 0
			for hex_result in dice_results:
				if hex_result.dice_type == "enemy_hex1":
					hex_value = hex_result.face_up_value + 1  # 转换为1-6范围
					break
			
			if hex_value > 0:
				resolve_enemy_action(action_data.action_name, hex_value)

func resolve_action(action_name: String, hex_value: int) -> void:
	var action_value = calculate_action_value(hex_value)
	print("[BattleManager] Resolving player action: ", action_name, " with value: ", action_value)
	
	# 从骰子结果中获取当前正面角色
	var active_character = null
	var enemy_character = null
	
	for result in dice_results:
		if result.dice_type == "frien":
			var frien_faces = EmbeddedDiceFaces.frien_dice_faces
			active_character = player_data.player_characters[frien_faces[result.face_up_value].character_name]
		elif result.dice_type == "enemy_frien":
			var enemy_faces = EmbeddedDiceFaces.enemy_frien_dice_faces
			enemy_character = enemy_data.enemy_fiends[enemy_faces[result.face_up_value].enemy_name]
			print("[BattleManager] Active enemy character: ", enemy_character.name)
	
	if active_character and enemy_character:
		match action_name:
			"Attack":
				# 攻击敌方正面角色
				print("[BattleManager] Player attacking enemy for ", action_value, " damage")
				update_character_health(enemy_character.name, -action_value)
			"Shield":
				# 为我方正面角色添加护盾
				print("[BattleManager] Player shielding ally for ",action_value, " amount")
				active_character.shield += action_value
				emit_signal("allied_shield_changed", active_character, active_character.shield)

func resolve_enemy_action(action_name: String, hex_value: int) -> void:
	var action_value = calculate_action_value(hex_value)
	print("[BattleManager] Resolving enemy action: ", action_name, " with value: ", action_value)
	
	# 从骰子结果中获取当前正面角色
	var active_character = null
	var enemy_character = null
	
	for result in dice_results:
		if result.dice_type == "frien":
			var frien_faces = EmbeddedDiceFaces.frien_dice_faces
			active_character = player_data.player_characters[frien_faces[result.face_up_value].character_name]
		elif result.dice_type == "enemy_frien":
			var enemy_faces = EmbeddedDiceFaces.enemy_frien_dice_faces
			enemy_character = enemy_data.enemy_fiends[enemy_faces[result.face_up_value].enemy_name]
	
	if active_character and enemy_character:
		match action_name:
			"Attack":
				# 攻击我方正面角色
				print("[BattleManager] Enemy attacking player for ", action_value, " damage")
				update_character_health(active_character.name, -action_value)
			"Shield":
				# 为敌方正面角色添加护盾
				enemy_character.shield += action_value
				print("[BattleManager] Enemy shielding enemy for ",action_value, " amount")
				emit_signal("enemy_shield_changed", enemy_character, enemy_character.shield)

func calculate_action_value(hex_value: int) -> int:
	match hex_value:
		1,2: return 3
		3,4: return 5
		5,6: return 7
	return 0 



# 在 BattleManager.gd 中添加重置函数
func reset_battle_state() -> void:
	phase_count = 1
	current_state = BattleState.ENEMY_ROLLING
	rolled_dice.clear()
	dice_results.clear()
	current_caster = null
	last_target = null
	player_data = PlayerData.new()
	enemy_data = EnemyTeam.new()

# 检查战斗是否结束
func _check_battle_end():
	var player_defeated = _is_team_defeated(player_data.player_characters)
	var enemy_defeated = _is_team_defeated(enemy_data.enemy_fiends)
	
	if player_defeated:
		#GameManager.end_current_game(false)
		battle_result = "defeat"
	elif enemy_defeated:
		battle_result = "victory"  # 敌人被击败，玩家胜利
		emit_signal("battle_won")


# 检查队伍是否战败
func _is_team_defeated(team: Dictionary) -> bool:
	if team.is_empty():
		return false
		
	# 检查所有角色的生命值
	for character in team.values():
		if character.current_health > 0:
			return false  # 只要有一个角色存活就没有失败
	
	return true  # 所有角色都失败了
