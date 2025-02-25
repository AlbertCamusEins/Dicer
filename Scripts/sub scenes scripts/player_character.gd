extends Node2D

var character_data: CharacterData

func _ready() -> void:
	BattleManager.allied_health_changed.connect(_on_health_changed)
	BattleManager.allied_shield_changed.connect(_on_shield_changed)

func setup_character(data: CharacterData):
	character_data = data
	$Sprite2D.texture = load(BattleManager.player_data.player_characters[data.character_name]["texture_path"])
	$Sprite2D.scale = Vector2(10,10)
	$TextureProgressBar.max_value = BattleManager.player_data.player_characters[data.character_name]["max_health"]
	$TextureProgressBar.value = BattleManager.player_data.player_characters[data.character_name]["current_health"]
	$Label.text = $Label.text + str(BattleManager.player_data.player_characters[data.character_name]["current_health"]) + "/" + str(BattleManager.player_data.player_characters[data.character_name]["max_health"])
	$"Ui-shield".hide()

func _on_health_changed(amount):
	if amount < 0:
		$"Ui-shield".hide()
		$Label2.hide()
	$TextureProgressBar.value = BattleManager.player_data.player_characters[character_data.character_name]["current_health"]
	$Label.text = str(BattleManager.player_data.player_characters[character_data.character_name]["current_health"]) + "/" + str(BattleManager.player_data.player_characters[character_data.character_name]["max_health"])

func _on_shield_changed(player_character, remaining_shield):
	if player_character.name == character_data.character_name:
		if remaining_shield == 0:
			$"Ui-shield".hide()
			$Label2.text = ""
		else:
			$Label2.show()
			$Label2.text = str(BattleManager.player_data.player_characters[character_data.character_name]["shield"])
			$"Ui-shield".show()
