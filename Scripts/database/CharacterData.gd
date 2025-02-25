extends Node

class_name CharacterData

var character_name: String
var texture_path: String
var health: int
var traits: String # 特性描述文本
var special_action: String
var experience: int
var prime_hex: String
var peak_hex: String
var soul_hex: String

const unlock_level: int = 2 # 解锁进阶法术所需等级

const level_data: Dictionary = {
		1: {"exp_required" : 100, "health_gain" : 2},
		2: {"exp_required" : 150, "health_gain" : 2}
	}

func init(data: Dictionary) -> CharacterData:
		character_name = data.get("character_name", "")
		texture_path = data.get("texture_path", "")
		health = data.get("health", 0)
		traits = data.get("traits", "")
		special_action = data.get("special_action", "")
		experience = data.get("experience", 0)
		prime_hex = data.get("prime_hex", "")
		peak_hex = data.get("peak_hex", "")
		soul_hex = data.get("soul_hex", "")
		return self
