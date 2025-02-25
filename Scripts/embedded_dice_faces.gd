extends Node


# 存储每种骰子的面板配置
var frien_dice_faces = {
	0: CharacterData.new(),
	1: CharacterData.new(),
	2: CharacterData.new(),
	3: CharacterData.new(),
	4: CharacterData.new(),
	5: CharacterData.new()
}

var ac1_dice_faces = {
	0: ActionData.new_common_action(),
	1: ActionData.new_common_action(),
	2: ActionData.new_common_action(),
	3: ActionData.new_common_action(),
	4: ActionData.new_common_action(),
	5: ActionData.new_common_action()
}

var ac2_dice_faces = {
	0: ActionData.new_uncommon_action(),
	1: ActionData.new_uncommon_action(),
	2: ActionData.new_uncommon_action(),
	3: ActionData.new_uncommon_action(),
	4: ActionData.new_uncommon_action(),
	5: ActionData.new_uncommon_action()
}

var hex_dice_faces = {
	0: HexData.new(),
	1: HexData.new(),
	2: HexData.new(),
	3: HexData.new(),
	4: HexData.new(),
	5: HexData.new()
}

var enemy_frien_dice_faces = {
	0: EnemyData.new(),
	1: EnemyData.new(),
	2: EnemyData.new(),
	3: EnemyData.new(),
	4: EnemyData.new(),
	5: EnemyData.new()
}

var enemy_ac1_dice_faces = {
	0: ActionData.new_common_action(),
	1: ActionData.new_common_action(),
	2: ActionData.new_common_action(),
	3: ActionData.new_common_action(),
	4: ActionData.new_common_action(),
	5: ActionData.new_common_action()
}

var enemy_ac2_dice_faces = {
	0: ActionData.new_uncommon_action(),
	1: ActionData.new_uncommon_action(),
	2: ActionData.new_uncommon_action(),
	3: ActionData.new_uncommon_action(),
	4: ActionData.new_uncommon_action(),
	5: ActionData.new_uncommon_action()
}

var enemy_hex_dice_faces = {
	0: HexData.new(),
	1: HexData.new(),
	2: HexData.new(),
	3: HexData.new(),
	4: HexData.new(),
	5: HexData.new()
}


# 更新指定骰子的面板配置
func update_dice_face(dice_type: String, face_index: int, face_data: Dictionary) -> void:
	match dice_type:
		"frien":
			frien_dice_faces[face_index].init(face_data)
		"ac1":
			ac1_dice_faces[face_index].init(face_data)
		"ac2":
			ac2_dice_faces[face_index].init(face_data)
		"hex2":
			hex_dice_faces[face_index].init(face_data)
		"enemy_frien":
			enemy_frien_dice_faces[face_index].init(face_data)
		"enemy_ac1":
			enemy_ac1_dice_faces[face_index].init(face_data)
		"enemy_ac2":
			enemy_ac2_dice_faces[face_index].init(face_data)
		"enemy_hex2":
			enemy_hex_dice_faces[face_index].init(face_data)



# 获取指定骰子的面板配置
func get_dice_faces(dice_type: String) -> Dictionary:
	match dice_type:
		"frien":
			return frien_dice_faces
		"ac1":
			return ac1_dice_faces
		"ac2":
			return ac2_dice_faces
		"hex2":
			return hex_dice_faces
		"enemy_frien":
			return enemy_frien_dice_faces
		"enemy_ac1":
			return enemy_ac1_dice_faces
		"enemy_ac2":
			return enemy_ac2_dice_faces
		"enemy_hex2":
			return enemy_hex_dice_faces
	return {}

# 检查单个骰面是否是初始值
func is_default_face(face_data) -> bool:
	if face_data is CharacterData:
		return face_data.character_name == "" and face_data.texture_path == ""
	elif face_data is ActionData:
		return face_data.action_name == "" and face_data.texture_path == ""
	elif face_data is HexData:
		return face_data.hex_name == "" and face_data.texture_path == ""
	elif face_data is EnemyData:
		return face_data.enemy_name == "" and face_data.texture_path == ""
	return true

# 检查指定类型的骰子是否全是初始值
func is_default_dice(dice_type: String) -> bool:
	var faces
	match dice_type:
		"frien":
			faces = frien_dice_faces
		"ac1":
			faces = ac1_dice_faces
		"ac2":
			faces = ac2_dice_faces
		"hex2":
			faces = hex_dice_faces
		"enemy_frien":
			faces = enemy_frien_dice_faces
		_:
			return true
			
	# 检查每个面
	for face in faces.values():
		if not is_default_face(face):
			return false
	
	return true

func to_dict() -> Dictionary:
	var embedded_faces_dict = {
		"frien": _faces_to_dict(frien_dice_faces, "character"),
		"ac1": _faces_to_dict(ac1_dice_faces, "action"),
		"ac2": _faces_to_dict(ac2_dice_faces, "action"),
		"hex": _faces_to_dict(hex_dice_faces, "hex"),
		"enemy_frien": _faces_to_dict(enemy_frien_dice_faces, "enemy"),
		"enemy_ac1": _faces_to_dict(enemy_ac1_dice_faces, "action"),
		"enemy_ac2": _faces_to_dict(enemy_ac2_dice_faces, "action"),
		"enemy_hex": _faces_to_dict(enemy_hex_dice_faces, "hex")
	}
	return embedded_faces_dict

func _faces_to_dict(faces: Dictionary, type: String) -> Dictionary:
	var faces_dict = {}
	for i in range(6):
		if faces.has(i):
			var face = faces[i]
			match type:
				"character":
					faces_dict[str(i)] = {
						"character_name": face.character_name,
						"texture_path": face.texture_path,
						"health": face.health,
						"traits": face.traits
					}
				"action":
					faces_dict[str(i)] = {
						"action_name": face.action_name,
						"texture_path": face.texture_path,
						"effect": face.effect,
						"is_special": face.is_special
					}
				"hex":
					faces_dict[str(i)] = face.to_dict()
					
				"enemy":
					faces_dict[str(i)] = {
						"enemy_name": face.enemy_name,
						"texture_path": face.texture_path,
						"health": face.health,
						"traits": face.traits
					}
	return faces_dict

func from_dict(dict: Dictionary) -> void:
	if dict.has("frien"):
		_dict_to_faces(dict.frien, frien_dice_faces, "character")
	if dict.has("ac1"):
		_dict_to_faces(dict.ac1, ac1_dice_faces, "action_common")
	if dict.has("ac2"):
		_dict_to_faces(dict.ac2, ac2_dice_faces, "action_uncommon")
	if dict.has("hex"):
		_dict_to_faces(dict.hex, hex_dice_faces, "hex")
	if dict.has("enemy_frien"):
		_dict_to_faces(dict.enemy_frien, enemy_frien_dice_faces, "enemy")
	if dict.has("enemy_ac1"):
		_dict_to_faces(dict.enemy_ac1, enemy_ac1_dice_faces, "action_common")
	if dict.has("enemy_ac2"):
		_dict_to_faces(dict.enemy_ac2, enemy_ac2_dice_faces, "action_uncommon")
	if dict.has("enemy_hex"):
		_dict_to_faces(dict.enemy_hex, enemy_hex_dice_faces, "hex")

func _dict_to_faces(faces_dict: Dictionary, target_faces: Dictionary, type: String) -> void:
	for i in range(6):
		var idx = str(i)
		if faces_dict.has(idx):
			match type:
				"character":
					target_faces[i] = CharacterData.new().init(faces_dict[idx])
				"action_common":
					target_faces[i] = ActionData.new_common_action().init(faces_dict[idx])
				"action_uncommon":
					target_faces[i] = ActionData.new_uncommon_action().init(faces_dict[idx])
				"hex":
					var hex_data = HexData.new()
					hex_data.from_dict(faces_dict[idx])
					target_faces[i] = hex_data
				"enemy":
					target_faces[i] = EnemyData.new().init(faces_dict[idx])

func reset() -> void:
	# 初始化所有骰子面板为新实例
	frien_dice_faces = {
		0: CharacterData.new(),
		1: CharacterData.new(),
		2: CharacterData.new(),
		3: CharacterData.new(),
		4: CharacterData.new(),
		5: CharacterData.new()
	}
	
	ac1_dice_faces = {
		0: ActionData.new_common_action(),
		1: ActionData.new_common_action(),
		2: ActionData.new_common_action(),
		3: ActionData.new_common_action(),
		4: ActionData.new_common_action(),
		5: ActionData.new_common_action()
	}
	
	ac2_dice_faces = {
		0: ActionData.new_uncommon_action(),
		1: ActionData.new_uncommon_action(),
		2: ActionData.new_uncommon_action(),
		3: ActionData.new_uncommon_action(),
		4: ActionData.new_uncommon_action(),
		5: ActionData.new_uncommon_action()
	}
	
	hex_dice_faces = {
		0: HexData.new(),
		1: HexData.new(),
		2: HexData.new(),
		3: HexData.new(),
		4: HexData.new(),
		5: HexData.new()
	}
	
	enemy_frien_dice_faces = {
		0: EnemyData.new(),
		1: EnemyData.new(),
		2: EnemyData.new(),
		3: EnemyData.new(),
		4: EnemyData.new(),
		5: EnemyData.new()
	}
	
	enemy_ac1_dice_faces = {
		0: ActionData.new_common_action(),
		1: ActionData.new_common_action(),
		2: ActionData.new_common_action(),
		3: ActionData.new_common_action(),
		4: ActionData.new_common_action(),
		5: ActionData.new_common_action()
	}
	
	enemy_ac2_dice_faces = {
		0: ActionData.new_uncommon_action(),
		1: ActionData.new_uncommon_action(),
		2: ActionData.new_uncommon_action(),
		3: ActionData.new_uncommon_action(),
		4: ActionData.new_uncommon_action(),
		5: ActionData.new_uncommon_action()
	}
	
	enemy_hex_dice_faces = {
		0: HexData.new(),
		1: HexData.new(),
		2: HexData.new(),
		3: HexData.new(),
		4: HexData.new(),
		5: HexData.new()
	}
