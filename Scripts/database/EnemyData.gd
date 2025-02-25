extends Node

class_name EnemyData

var enemy_name: String
var texture_path: String
var health: int
var traits: String # 特性描述文本
var special_action: String

func init(data: Dictionary) -> EnemyData:
		enemy_name = data.get("enemy_name", "")
		texture_path = data.get("texture_path", "")
		health = data.get("health", 0)
		traits = data.get("traits", "")
		special_action = data.get("special_action", "")
		return self
