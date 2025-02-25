extends Node2D

var selected_character: CharacterData = null
var character_buttons: Array = []
const CHARACTER_BUTTON_POSITIONS = [
	Vector2(400, 400),
	Vector2(800, 400),
	Vector2(1200, 400)
]

@onready var done_button = $DoneButton

func _ready():
	# 初始化三个随机角色选项
	var all_characters = GameDataManager.get_all_characters()
	var random_characters = select_random_characters(all_characters, 3)
	create_character_buttons(random_characters)
	
	# 初始化完成按钮
	done_button.disabled = true

func select_random_characters(characters: Array, count: int) -> Array:
	var available_characters = characters.duplicate()
	var selected = []
	
	# 随机选择指定数量的角色
	while selected.size() < count and not available_characters.is_empty():
		var index = randi() % available_characters.size()
		selected.append(available_characters.pop_at(index))
	
	return selected

func create_character_buttons(characters: Array) -> void:
	for i in range(characters.size()):
		var character = characters[i]
		var button = create_character_button(character, CHARACTER_BUTTON_POSITIONS[i])
		character_buttons.append(button)
		add_child(button)

func create_character_button(character: CharacterData, pos: Vector2) -> Button:
	var button = Button.new()
	button.position = Vector2(pos.x + 20, pos.y + 112)
	button.text = "You"
	
	# 添加角色图片
	var texture_rect = TextureRect.new()
	texture_rect.texture = load(character.texture_path)
	texture_rect.scale = Vector2(4,4)
	add_child(texture_rect)
	texture_rect.position = pos
	
	
	# 设置按钮的切换模式并连接信号
	button.toggle_mode = true
	button.button_group = ButtonGroup.new()  # 使用按钮组确保只能选择一个
	button.pressed.connect(_on_character_button_pressed.bind(character))
	
	return button

func _on_character_button_pressed(character: CharacterData) -> void:
	selected_character = character
	done_button.disabled = false

func _on_done_button_pressed() -> void:
	if selected_character:
		
		# 准备角色数据字典
		var character_dict = {
			"character_name": selected_character.character_name,
			"texture_path": selected_character.texture_path,
			"health": selected_character.health,
			"traits": selected_character.traits,
			"prime_hex": selected_character.prime_hex
		}
		var prime_hex_name = selected_character.prime_hex
		if prime_hex_name != "":
			var prime_hex = GameDataManager.hexes.get(prime_hex_name)
			var prime_hex_dict ={
				"hex_name": prime_hex.hex_name,
				"texture_path": prime_hex.texture_path,
				"target_data": prime_hex.target_data,
				"effect_data": prime_hex.effect_data,
				"cast_condition": prime_hex.cast_condition
			}
			GameManager.current_run.inventory.add_face("hex2", prime_hex_name, prime_hex_dict)
		GameManager.current_run.inventory.add_face("frien",selected_character.character_name, character_dict)

		var current_room = MapStateManager.get_current_room()
		MapStateManager.mark_room_as_cleared(current_room)
				
		GameManager.save_game()

		# 切换到下一个场景（比如第一场战斗或地图场景）
		get_tree().change_scene_to_file("res://Scenes/custom_dice_scene.tscn")
