extends Node2D


var enemy_data: EnemyData

func _ready() -> void:
	BattleManager.enemy_health_changed.connect(_on_health_changed)
	BattleManager.enemy_shield_changed.connect(_on_shield_changed)
	

func setup_enemy(data: EnemyData):
	enemy_data = data
	$Sprite2D.texture = load(BattleManager.enemy_data.enemy_fiends[data.enemy_name]["texture_path"])
	$Sprite2D.scale = Vector2(9,9)
	$TextureProgressBar.max_value = BattleManager.enemy_data.enemy_fiends[data.enemy_name]["max_health"]
	$TextureProgressBar.value = BattleManager.enemy_data.enemy_fiends[data.enemy_name]["current_health"]
	$Label.text = $Label.text + str(BattleManager.enemy_data.enemy_fiends[data.enemy_name]["current_health"]) + "/" + str(BattleManager.enemy_data.enemy_fiends[data.enemy_name]["max_health"])
	$Label2.text = $Label2.text + str(BattleManager.enemy_data.enemy_fiends[data.enemy_name]["name"])
	$"Ui-shield".hide()
	

func _on_health_changed(amount):
	if amount < 0:
		$"Ui-shield".hide()
		$Label3.hide()
	$TextureProgressBar.value = BattleManager.enemy_data.enemy_fiends[enemy_data.enemy_name]["current_health"]
	$Label.text = str(BattleManager.enemy_data.enemy_fiends[enemy_data.enemy_name]["current_health"]) + "/" + str(BattleManager.enemy_data.enemy_fiends[enemy_data.enemy_name]["max_health"])

func _on_shield_changed(enemy_character, remaining_shield):
	if enemy_character.name == enemy_data.enemy_name:
		if remaining_shield == 0:
			$"Ui-shield".hide()
			$Label3.text = ""
		else:
			$Label3.show()
			$Label3.text = str(BattleManager.enemy_data.enemy_fiends[enemy_data.enemy_name]["shield"])
			$"Ui-shield".show()
