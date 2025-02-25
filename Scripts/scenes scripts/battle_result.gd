extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	randomize()
	if BattleManager.battle_result == "defeat":
		$Label.text = "Defeat!"
	elif BattleManager.battle_result == "victory":
		if BattleManager.get_battle_type() == BattleManager.BattleType.BOSS_BATTLE \
		and GameManager.current_run.current_floor > 4:
			$Label.text = "Victory!"
		else:
			$Label.text = "Good Stuff!"
	
	$"Gain gold button".text = str(int(randf_range(75,101))) + " gold"
	$Label2.text = "current gold: " + str(GameManager.current_run.gold)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_continue_button_pressed() -> void:
	if BattleManager.battle_result == "victory":
		if BattleManager.get_battle_type() == BattleManager.BattleType.BOSS_BATTLE:
			GameManager.current_run.advance_to_next_floor()
			if GameManager.current_run.current_floor > 4:
				GameManager.end_current_game(true)
				return
		var current_room = MapStateManager.get_current_room()
		MapStateManager.mark_room_as_cleared(current_room)
		
		get_tree().change_scene_to_file("res://Scenes/map_scene.tscn")
	
	elif BattleManager.battle_result == "defeat":
		GameManager.quit_to_main_menu()


func _on_gain_gold_button_pressed() -> void:
	var gold_number = $"Gain gold button".text.replace(" gold","")
	GameManager.current_run.gain_gold(int(gold_number))
	$"Gain gold button".hide()
	$Label2.text = "current gold: " + str(GameManager.current_run.gold)
