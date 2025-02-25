extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_button_pressed() -> void:
		get_tree().change_scene_to_file("res://Scenes/custom_dice_scene.tscn")


func _on_common_acts_pressed() -> void:
		get_tree().change_scene_to_file("res://Scenes/ac_1_dice_custom_scene.tscn")


func _on_uncommon_acts_pressed() -> void:
		get_tree().change_scene_to_file("res://Scenes/ac_2_dice_custom_scene.tscn")
