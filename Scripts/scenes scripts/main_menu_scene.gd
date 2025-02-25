extends Node2D

func _ready() -> void:
	var has_save = FileAccess.file_exists("user://savegame.save")
	var is_run_active = false
	
	if has_save:
		var game_save = FileAccess.open("user://savegame.save", FileAccess.READ)
		var json_string = game_save.get_line()
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		if parse_result == OK:
			var data = json.get_data()
			is_run_active = data.has("current_run") and data.current_run != null
	
	$"Continue Button".disabled = not (has_save and is_run_active)


func _on_start_new_game_pressed():
	GameManager.start_new_game()
	GameManager.current_run.start_new_run()


func _on_exit_game_button_pressed() -> void:
	get_tree().quit()


func _on_continue_button_pressed() -> void:
	GameManager.continue_game()
