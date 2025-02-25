extends Node2D


@onready var dice_face_container = $DiceFaceContainer
@onready var done_button = $Done
@onready var face_insert_manager = $"Dice Face Insert Manager"

static var stored_faces = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if EmbeddedDiceFaces.is_default_dice("hex2"):
		stored_faces.clear()
	
	load_available_hexes()
	apply_stored_player_hex_dice_faces()
	restore_stored_faces()
	update_done_button_state()

func _exit_tree() -> void:
	stored_faces.clear()
	store_faces()

func remove_face_by_slot(slot_number):
	# 倒序遍历数组，确保删除后不影响剩余元素的索引
	for i in range(stored_faces.size() - 1, -1, -1):
		if stored_faces[i]["slot_number"] == slot_number:
			stored_faces.remove_at(i)
			break


func store_faces():
	for child in face_insert_manager.get_children():
		stored_faces.append(
			{"position": child.position,
			"hex_data": child.hex_data,
			"child_name": child.name,
			"slot_number": child.name
			}
		)

func store_face_by_slot(dice_face_being_dragged, slot_number):
	stored_faces.append({
		"position": dice_face_being_dragged.position,
		"hex_data": dice_face_being_dragged.hex_data,
		"child_name": dice_face_being_dragged.name,
		"slot_number": slot_number
	})

func restore_stored_faces():
	# 恢复之前保存的骰子面
	for face_data in stored_faces:
		var dice_face = preload("res://Scenes/dice_face.tscn").instantiate()
		face_insert_manager.add_child(dice_face)
		dice_face.setup_hex_data(face_data.hex_data)
		dice_face.name = face_data.child_name
		dice_face.position = face_data.position


func load_available_hexes():
	var available_hexes = GameManager.current_run.inventory.get_faces("hex2")
	var container_pos = dice_face_container.position
	var cell_side_length = 112
	var grid_cols = 3
	var _grid_rows = 2
	
	for i in range(available_hexes.size()):
		var hex = available_hexes[i]
		
		@warning_ignore("integer_division")
		var row = i / grid_cols
		var col = i % grid_cols
		
		var pos = Vector2(
			container_pos.x - 112 + (col * cell_side_length),
			container_pos.y - 56 + (row * cell_side_length)
		)
		
		spawn_hex_at_position(hex, pos)


func spawn_hex_at_position(hex_data: HexData, pos: Vector2):
	var dice_face_scene = preload("res://Scenes/dice_face.tscn")
	var dice_face = dice_face_scene.instantiate()
	dice_face.setup_hex_data(hex_data)
	dice_face.name = hex_data.hex_name
	add_child(dice_face)
	dice_face.position = pos


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	update_done_button_state()

func _on_done_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/custom_dice_scene.tscn")


func apply_stored_player_hex_dice_faces() ->void:
	var hex_faces = EmbeddedDiceFaces.get_dice_faces("hex2")

	for face_index in hex_faces.keys():
		var hex_data = hex_faces[face_index]
		if hex_data.texture_path != "":
			DiceFaceChanger.update_dice_face("hex2", face_index, hex_data.texture_path)

func update_done_button_state():
	var face_count = 0
	for child in $"Dice Face Insert Manager".get_children():
		if child.name in ["1","2","3","4","5","6"]:
			face_count += 1
	done_button.disabled = face_count < 6
	


func _on_autofillhex_dice_button_pressed() -> void:
	for child in face_insert_manager.get_children():
		child.queue_free()
	# 等待一帧确保清除完成
	await get_tree().process_frame
	
	DiceManager.auto_fill_dice_faces("hex2")
	apply_stored_player_hex_dice_faces()
		# 清除当前Dice Face Insert Manager中的所有子节点
	for child in face_insert_manager.get_children():
		child.queue_free()
	
	# 根据EmbeddedDiceFaces中的数据创建新的骰面
	var hex_faces = EmbeddedDiceFaces.get_dice_faces("hex2")
	for face_index in hex_faces.keys():
		var hex_data = hex_faces[face_index]
		if hex_data.texture_path != "":
			var dice_face = preload("res://Scenes/dice_face.tscn").instantiate()
			face_insert_manager.add_child(dice_face)
			dice_face.setup_hex_data(hex_data)
			dice_face.name = str(face_index + 1)  # 使用1-6作为名称
			
			# 设置位置到对应的骰子槽
			var slot = get_node("Dice Slot" + str(face_index + 1))
			if slot:
				dice_face.position = slot.position
	store_faces()
