extends Node2D

var dice_face_in_slot = false
@onready var CustomScene = self.get_parent()

func _process(_delta) -> void:
	dice_face_in_slot = false
	# 检查 ac_1_dice_custom_scene 中的 stored_faces
	if not CustomScene.stored_faces.is_empty():
		# 检查是否有对应这个槽位的存储数据
		var slot_number = name.replace("Dice Slot", "")
		for face_data in CustomScene.stored_faces:
			if face_data.slot_number == slot_number:
				dice_face_in_slot = true
				break
