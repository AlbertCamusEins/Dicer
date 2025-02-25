extends Node2D


func _on_continue_button_pressed() -> void:
	GameManager.resume_game()


func _on_return_to_main_menu_button_pressed() -> void:
	GameManager.quit_to_main_menu()
