extends Node2D

const COLLISION_MASK_DICE_FACE = 1
@onready var shop_items = $ShopItems
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if GameManager.current_scene_path == scene_file_path and not GameManager.current_scene_state.is_empty():
		print("[ShopScene] Restoring saved state")
		_restore_shop_state()
	else:
		load_one_hex_face_item()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$Label3.text = "current gold: " + str(GameManager.current_run.gold)
	if int($Label2.text) > GameManager.current_run.gold:
		$Label2.add_theme_color_override("font_color",Color.RED)
	else:
		$Label2.add_theme_color_override("font_color",Color.WHITE)

func _restore_shop_state() -> void:
	# 清除现有物品
	for child in shop_items.get_children():
		child.queue_free()
	
	var shop_state = GameManager.current_scene_state
	
	# 恢复物品
	for item_data in shop_state.items:
		var pos = Vector2(item_data.position.x, item_data.position.y)
		
		match item_data.type:
			"hex":
				var hex_data = HexData.new()
				hex_data.init(item_data.data)
				spawn_hex_at_position(hex_data, pos)
			# 可以根据需要添加其他类型
	
	# 恢复价格
	if shop_state.prices.has("current_price"):
		$Label2.text = str(shop_state.prices.current_price)
		$Label2.show()
	else:
		$Label2.hide()

func _exit_tree() -> void:
	GameManager.save_current_scene_state()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var dice_face = raycast_check_for_dice_face()
			if dice_face:
				# 获取物品价格并检查是否有足够金币
				var price = int($Label2.text)
				if not GameManager.current_run.spend_gold(price):
					# 金币不足，直接返回
					print("Not enough gold to purchase!")
					return
				
				# 金币足够，继续处理购买逻辑
				GameManager.current_run.spend_gold(price)
				if dice_face.character_data:
					var char_dict = {
						"character_name": dice_face.character_data.character_name,
						"texture_path": dice_face.character_data.texture_path,
						"health": dice_face.character_data.health,
						"traits": dice_face.character_data.traits,
						"prime_hex": dice_face.character_data.prime_hex
					}
					GameManager.current_run.inventory.add_face("frien", dice_face.character_data.character_name, char_dict)
				
				elif dice_face.action_data:
					var action_dict = {
						"action_name": dice_face.action_data.action_name,
						"texture_path": dice_face.action_data.texture_path,
						"effect": dice_face.action_data.effect,
						"is_special": dice_face.action_data.is_special
					}
					var action_type = "uncommon_action" if dice_face.action_data.is_special else "common_action"
					GameManager.current_run.inventory.add_face(action_type, dice_face.action_data.action_name, action_dict)
				
				elif dice_face.hex_data:
					var hex_dict = {
						"hex_name": dice_face.hex_data.hex_name,
						"texture_path": dice_face.hex_data.texture_path,
						"target_data": dice_face.hex_data.target_data,
						"effect_data": dice_face.hex_data.effect_data,
						"cast_condition": dice_face.hex_data.cast_condition
					}
					GameManager.current_run.inventory.add_face("hex2", dice_face.hex_data.hex_name, hex_dict)
				
				# 保存游戏状态
				GameManager.save_game()
				
				# 隐藏已购买的骰面
				dice_face.hide()
				$Label2.hide()

func load_one_hex_face_item():
	var loaded_face = GameDataManager.get_all_hexes()
	var selected_face = select_one_random_hexes(loaded_face, 1)
	var load_pos = Vector2(800,400)

	spawn_hex_at_position(selected_face, load_pos)

func spawn_hex_at_position(hex_data: HexData, pos: Vector2):
	var dice_face_scene = preload("res://Scenes/dice_face.tscn")
	var dice_face = dice_face_scene.instantiate()
	dice_face.setup_hex_data(hex_data)
	dice_face.name = hex_data.hex_name
	shop_items.add_child(dice_face)
	dice_face.position = pos


func select_one_random_hexes(hexes: Array, count: int):
	var available_hexes = hexes.duplicate()
	var selected = []
	
	# 随机选择指定数量的角色
	while selected.size() < count and not available_hexes.is_empty():
		var index = randi() % available_hexes.size()
		selected.append(available_hexes.pop_at(index))
	
	return selected[0]

func raycast_check_for_dice_face() -> Node2D:
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_DICE_FACE  # Adjust this mask based on your collision layer setup
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		print(result[0].collider.get_parent())
		return result[0].collider.get_parent()
	return null


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/map_scene.tscn")
