extends Node

# 定义 "change_face" 信号，带两个参数：帧索引和新纹理路径
signal change_face(dice_type, frame_index, new_texture_path)
signal change_face_inventory


# 当骰子面更新时调用该函数，发射信号
func update_dice_face(dice_type: String, frame_index: int, new_texture_path: String) -> void:
	emit_signal("change_face", dice_type, frame_index, new_texture_path)

func update_dice_face_inventory():
	emit_signal("change_face_inventory")
