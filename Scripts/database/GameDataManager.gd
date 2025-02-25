extends Node

# 数据存储
var characters: Dictionary = {}
var actions: Dictionary = {}
var hexes: Dictionary = {}

# 可以添加其他数据字典
var traits: Dictionary = {}
var effects: Dictionary = {}

func _ready():
	load_all_game_data()

func load_all_game_data() -> void:
	print("[GameDataManager] Loading game data...")
	load_characters()
	load_actions()
	load_hexes()
	# 之后可以添加
	# load_traits()
	# load_effects()

func load_characters() -> void:
	var json_data = load_json_file("res://GameData/characters.json")
	if json_data:
		characters = json_data.characters
		print("[GameDataManager] Loaded", characters.size(), "characters")

func load_actions() -> void:
	var json_data = load_json_file("res://GameData/actions.json")
	if json_data:
		actions = json_data.actions
		print("[GameDataManager] Loaded", actions.size(), "actions")

func load_hexes() -> void:
	var json_data = load_json_file("res://GameData/hexes.json")
	if json_data:
		hexes = json_data.hexes
		print("[GameDataManager] Loaded", hexes.size(), "hexes")

func load_json_file(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		print("[GameDataManager] Error: File not found:", file_path)
		return {}

	var json_file = FileAccess.open(file_path, FileAccess.READ)
	var json_text = json_file.get_as_text()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	
	if parse_result != OK:
		print("[GameDataManager] JSON Parse Error:", json.get_error_message())
		return {}
		
	return json.get_data()

# 获取数据的辅助函数
func get_character_data(id: String) -> Dictionary:
	if characters.has(id):
		return characters[id]
	print("[GameDataManager] Character not found:", id)
	return {}

func get_action_data(id: String) -> Dictionary:
	if actions.has(id):
		return actions[id]
	print("[GameDataManager] Action not found:", id)
	return {}

func get_hex_data(id: String) -> Dictionary:
	if hexes.has(id):
		return hexes[id]
	print("[GameDataManager] Hex not found:", id)
	return {}

# 获取所有数据的函数（为了保持现有功能）
func get_all_characters() -> Array:
	return characters.values()

func get_all_actions() -> Array:
	return actions.values()

func get_all_hexes() -> Array:
	return hexes.values()

# 通过名称查找ID的辅助函数
func get_character_id_by_name(name: String) -> String:
	for id in characters:
		if characters[id].name == name:
			return id
	return ""

func get_action_id_by_name(name: String) -> String:
	for id in actions:
		if actions[id].name == name:
			return id
	return ""

func get_hex_id_by_name(name: String) -> String:
	for id in hexes:
		if hexes[id].name == name:
			return id
	return ""
