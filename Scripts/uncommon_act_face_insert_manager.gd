extends Node2D

const COLLISION_MASK_DICE_FACE = 1
const COLLISION_MASK_DICE_SLOT = 2

var screen_size 
var dice_face_being_dragged = null
var original_dice_slot
@onready var dice_face_copy = preload("res://Scenes/dice_face.tscn")


func _ready() -> void:
	screen_size = get_viewport_rect().size


func _process(_delta: float) -> void:
	if dice_face_being_dragged:
		# Update card position to follow the mouse
		var mouse_pos = get_global_mouse_position()
		dice_face_being_dragged.global_position = Vector2(clamp(mouse_pos.x, 0, screen_size.x), 
			clamp(mouse_pos.y, 0, screen_size.y))


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Check for a card under the mouse
			var dice_face = raycast_check_for_dice_face()
			var dice_slot_found = raycast_check_for_dice_slot()
			if dice_face:
				if dice_slot_found and dice_slot_found.dice_face_in_slot:
					start_drag(dice_face)
					dice_slot_found.dice_face_in_slot = false
					original_dice_slot = dice_slot_found
				else:
					start_copy(dice_face)
		else:
			if dice_face_being_dragged:
				finish_drag()


func start_drag(dice_face):
	dice_face_being_dragged = dice_face
	dice_face.scale = Vector2(1,1)

func start_copy(dice_face):
		var copy = dice_face_copy.instantiate()
		add_child(copy)
		copy.setup_action_data(dice_face.action_data)
		dice_face_being_dragged = copy
		copy.position = dice_face.position
		copy.scale = Vector2(1,1)
		copy.z_index = dice_face.z_index + 1


func finish_drag():
	var dice_slot_found = raycast_check_for_dice_slot()
	if dice_slot_found and not dice_slot_found.dice_face_in_slot:
		#Card dropped into empty card slot
		dice_face_being_dragged.position = dice_slot_found.position
		dice_face_being_dragged.name = dice_slot_found.name.replace("Dice Slot","")
		dice_slot_found.dice_face_in_slot = true
		var dice_face_str = str(dice_face_being_dragged.name)
		var sprite = get_node("./" + dice_face_str + "/Sprite2D")
		var texture_path = sprite.texture.resource_path
		var face_data = dice_face_being_dragged.action_data
		var action_dict = {
			"action_name": face_data.action_name,
			"texture_path": face_data.texture_path,
			"effect": face_data.effect,
			"is_special": face_data.is_special
		}
		DiceFaceChanger.update_dice_face("ac2", int(dice_face_str) - 1, (add_two(texture_path)))
		EmbeddedDiceFaces.update_dice_face("ac2", int(dice_face_str) - 1, action_dict)
	else:
		dice_face_being_dragged.queue_free()
		if original_dice_slot:
			var slot_number = original_dice_slot.name.replace("Dice Slot", "")
			for i in range(get_parent().stored_faces.size()):
				get_parent().remove_face_by_slot(slot_number)
	dice_face_being_dragged = null



func raycast_check_for_dice_slot() -> Node2D:
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_DICE_SLOT  # Adjust this mask based on your collision layer setup
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		print(result[0].collider.get_parent())
		return result[0].collider.get_parent()
	return null


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

func insert_string(original: String, insert_pos: int, insert_text: String) -> String:
	return original.substr(0, insert_pos) + insert_text + original.substr(insert_pos)

# 在倒数第五个位置（即扩展名前）插入 "2"
func add_two(original: String) -> String:
	# 这里计算插入位置，使得字符串最后 4 个字符不受影响（例如 ".png"）
	var pos = original.length() - 4
	return insert_string(original, pos, "2")
