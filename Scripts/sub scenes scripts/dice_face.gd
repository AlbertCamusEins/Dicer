extends Node2D

var action_data: ActionData
var character_data: CharacterData
var hex_data: HexData

func setup_action_data(data: ActionData):
	action_data = data
	$Sprite2D.texture = load(action_data.texture_path)

func setup_character_data(data: CharacterData):
	character_data = data
	$Sprite2D.texture = load(character_data.texture_path)

func setup_hex_data(data: HexData):
	hex_data = data
	$Sprite2D.texture = load(hex_data.texture_path)
