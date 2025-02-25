extends Node

class_name Inventory

# 存储所有类型的骰面，包括角色、普通行动、特殊行动和法术
var frien_faces: Dictionary = {}  # 角色骰面
var common_action_faces: Dictionary = {}  # 普通行动骰面
var uncommon_action_faces: Dictionary = {}  # 特殊行动骰面
var hex_faces: Dictionary = {}  # 法术骰面

signal inventory_updated

func _init():
	# 初始化空的骰面集合
	frien_faces.clear()
	common_action_faces.clear()
	uncommon_action_faces.clear()
	hex_faces.clear()

# 添加新的骰面
func add_face(face_type: String, face_id: String, face_data: Dictionary) -> void:
	match face_type:
		"frien":
			if not frien_faces.has(face_id):
				var character = CharacterData.new()
				character.init(face_data)
				frien_faces[face_id] = character
		"common_action":
			if not common_action_faces.has(face_id):
				var action = ActionData.new_common_action()
				action.init(face_data)
				common_action_faces[face_id] = action
		"uncommon_action":
			if not uncommon_action_faces.has(face_id):
				var action = ActionData.new_uncommon_action()
				action.init(face_data)
				uncommon_action_faces[face_id] = action
		"hex2":
			if not hex_faces.has(face_id):
				var hex = HexData.new()
				hex.init(face_data)
				hex_faces[face_id] = hex
	
	emit_signal("inventory_updated")

# 移除骰面
func remove_face(face_type: String, face_id: String) -> void:
	match face_type:
		"frien":
			frien_faces.erase(face_id)
		"common_action":
			common_action_faces.erase(face_id)
		"uncommon_action":
			uncommon_action_faces.erase(face_id)
		"hex2":
			hex_faces.erase(face_id)
	
	emit_signal("inventory_updated")

# 获取特定类型的所有骰面
func get_faces(face_type: String) -> Array:
	match face_type:
		"frien":
			return frien_faces.values()
		"common_action":
			return common_action_faces.values()
		"uncommon_action":
			return uncommon_action_faces.values()
		"hex2":
			return hex_faces.values()
	return []

# 检查是否拥有特定骰面
func has_face(face_type: String, face_id: String) -> bool:
	match face_type:
		"frien":
			return frien_faces.has(face_id)
		"common_action":
			return common_action_faces.has(face_id)
		"uncommon_action":
			return uncommon_action_faces.has(face_id)
		"hex2":
			return hex_faces.has(face_id)
	return false

# 获取特定骰面数据
func get_face_data(face_type: String, face_id: String):
	match face_type:
		"frien":
			return frien_faces.get(face_id)
		"common_action":
			return common_action_faces.get(face_id)
		"uncommon_action":
			return uncommon_action_faces.get(face_id)
		"hex2":
			return hex_faces.get(face_id)
	return null

# 清空所有骰面（用于新游戏开始）
func clear_all() -> void:
	frien_faces.clear()
	common_action_faces.clear()
	uncommon_action_faces.clear()
	hex_faces.clear()
	emit_signal("inventory_updated")

# 导出存档数据
func save_data() -> Dictionary:
	return {
		"frien_faces": frien_faces,
		"common_action_faces": common_action_faces,
		"uncommon_action_faces": uncommon_action_faces,
		"hex_faces": hex_faces
	}

# 从存档数据加载
func load_data(data: Dictionary) -> void:
	clear_all()
	
	# 加载每种类型的骰面
	for face_id in data.get("frien_faces", {}):
		add_face("frien", face_id, data["frien_faces"][face_id])
	
	for face_id in data.get("common_action_faces", {}):
		add_face("common_action", face_id, data["common_action_faces"][face_id])
	
	for face_id in data.get("uncommon_action_faces", {}):
		add_face("uncommon_action", face_id, data["uncommon_action_faces"][face_id])
	
	for face_id in data.get("hex_faces", {}):
		add_face("hex", face_id, data["hex_faces"][face_id])


func to_dict() -> Dictionary:
	print("[Inventory] Converting to dictionary")
	var dict = {
		"frien_faces": {},
		"common_action_faces": {},
		"uncommon_action_faces": {},
		"hex_faces": {}
	}
	
	# 转换角色面数据
	for face_id in frien_faces:
		var face = frien_faces[face_id]
		dict["frien_faces"][face_id] = {
			"character_name": face.character_name,
			"texture_path": face.texture_path,
			"health": face.health,
			"traits": face.traits,
			"prime_hex": face.prime_hex,
			"peak_hex": face.peak_hex,
			"soul_hex": face.soul_hex,
			"experience": face.experience
		}
	
	# 转换普通行动面数据
	for face_id in common_action_faces:
		var face = common_action_faces[face_id]
		dict["common_action_faces"][face_id] = {
			"action_name": face.action_name,
			"texture_path": face.texture_path,
			"effect": face.effect,
			"is_special": face.is_special,
			"owner_character": face.owner_character
		}
	
	# 转换特殊行动面数据
	for face_id in uncommon_action_faces:
		var face = uncommon_action_faces[face_id]
		dict["uncommon_action_faces"][face_id] = {
			"action_name": face.action_name,
			"texture_path": face.texture_path,
			"effect": face.effect,
			"is_special": face.is_special,
			"owner_character": face.owner_character
		}
	
	# 转换法术面数据
	for face_id in hex_faces:
		var face = hex_faces[face_id]
		dict["hex_faces"][face_id] = face.to_dict()
	
	print("[Inventory] Dictionary conversion completed")
	return dict

func from_dict(dict: Dictionary) -> void:
	print("[Inventory] Loading from dictionary")
	clear_all()  # 清空现有数据
	
	# 加载角色面数据
	if dict.has("frien_faces"):
		for face_id in dict["frien_faces"]:
			var face_data = dict["frien_faces"][face_id]
			add_face("frien", face_id, face_data)
	
	# 加载普通行动面数据
	if dict.has("common_action_faces"):
		for face_id in dict["common_action_faces"]:
			var face_data = dict["common_action_faces"][face_id]
			add_face("common_action", face_id, face_data)
	
	# 加载特殊行动面数据
	if dict.has("uncommon_action_faces"):
		for face_id in dict["uncommon_action_faces"]:
			var face_data = dict["uncommon_action_faces"][face_id]
			add_face("uncommon_action", face_id, face_data)
	
	# 加载法术面数据
	if dict.has("hex_faces"):
		for face_id in dict["hex_faces"]:
			var hex = HexData.new()
			hex.from_dict(dict["hex_faces"][face_id])
			hex_faces[face_id] = hex
	
	print("[Inventory] Dictionary loading completed")
	emit_signal("inventory_updated")
