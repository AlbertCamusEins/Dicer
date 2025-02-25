extends Node2D

@onready var anim_sprite = $"Dice Animations"
var dice_type: String
var is_clickable: bool = false



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("dice")
	var original_frames = anim_sprite.sprite_frames
	var new_frames = original_frames.duplicate()
	anim_sprite.sprite_frames = new_frames
	
	randomize()
	anim_sprite.animation_finished.connect(_on_rotate_finished)
	DiceFaceChanger.connect("change_face",change_dice_face_image)
	DiceManager.dice_rolled.connect(_on_dice_rolled)
	
	print("[Dice] Node name: ", name)
	if name.begins_with("Frien"):
		dice_type = "frien"
	elif name.begins_with("Ac1"):
		dice_type = "ac1"
	elif name.begins_with("Ac2"):
		dice_type = "ac2"
	elif name.begins_with("Hex1"):
		dice_type = "hex1"
	elif name.begins_with("Hex2"):
		dice_type = "hex2"
	elif name.begins_with("Enemy_Frien"):
		dice_type = "enemy_frien"
	elif name.begins_with("Enemy_Ac1"):
		dice_type = "enemy_ac1"
	elif name.begins_with("Enemy_Ac2"):
		dice_type = "enemy_ac2"
	elif name.begins_with("Enemy_Hex1"):
		dice_type = "enemy_hex1"
	elif name.begins_with("Enemy_Hex2"):
		dice_type = "enemy_hex2"
	print("[Dice] Set dice type to:", dice_type)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not is_clickable:
		return
	
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed:
		play_rotate_animation()
		DiceManager.emit_signal("dice_rolled",dice_type)
		
		
func play_rotate_animation():
	if anim_sprite:
		print("[Dice] Starting rotate animation")
		anim_sprite.play("rotate")


func show_random_face():
	print("[Dice] Setting random face")
	anim_sprite.play("faces")
	anim_sprite.frame = randi() % 6
	anim_sprite.pause()
	var face_up_value = self.get_node("Dice Animations").frame
	BattleManager.update_dice_result(dice_type, face_up_value)
	
func _on_rotate_finished() -> void:
	print("[Dice] Animation finished:", anim_sprite.animation)
	if anim_sprite.animation == "rotate" :
		show_random_face()

func _on_dice_rolled(dice_type):
	DiceManager.disable_certain_dice(dice_type)

func change_dice_face_image(changed_type: String, frame_index: int, new_texture_path: String) -> void:
	if changed_type == dice_type:
		var new_texture = load(new_texture_path)
		# 将“faces”动画中 frame_index 帧替换为新图片
		anim_sprite.sprite_frames.set_frame("faces", frame_index, new_texture)

func set_clickable(clickable: bool):
	is_clickable = clickable
	modulate = Color(1,1,1,1.0 if clickable else 0.5)
