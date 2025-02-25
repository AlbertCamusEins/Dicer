extends Node2D

@onready var return_to_map_button = $"Return to map button"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	return_to_map_button.disabled = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if not EmbeddedDiceFaces.is_default_dice("frien") \
	and not EmbeddedDiceFaces.is_default_dice("ac1") \
	and not EmbeddedDiceFaces.is_default_dice("ac2") \
	and not EmbeddedDiceFaces.is_default_dice("hex2"):
		return_to_map_button.disabled = false



func _on_frien_dice_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/frien_dice_custom_scene.tscn")


func _on_ac_dice_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/ac_dice_custom_scene.tscn")


func _on_hex_dice_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/hex_dice_custom_scene.tscn")


func _on_return_to_map_pressed() -> void:
	GameManager.save_game()
	get_tree().change_scene_to_file("res://Scenes/map_scene.tscn")
