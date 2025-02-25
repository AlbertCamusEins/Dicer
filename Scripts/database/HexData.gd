extends Node


class_name HexData

var hex_name: String
var texture_path: String
var caster: String = "ally facing up"
var cast_condition: DiceFace = DiceFace.UP


enum TargetTeam { ALLY, ENEMY }
enum TargetType { CHARACTER, DICEFACE, DICE }
enum DiceType { FRIEND, ACTION, HEX }
enum DiceFace { UP, DOWN, SIDE }

var target_template = {
	"team": TargetTeam.ENEMY,        # 目标队伍
	"type": TargetType.CHARACTER,    # 目标类型
	"condition": {                   # 目标条件
		"dice_reference": {           # 通过骰子关联的条件
			"type": DiceType.FRIEND,  # 关联的骰子类型
			"face": DiceFace.UP,      # 关联的骰子朝向
		},
		"status_check": [],           # 状态检查条件
		"index": 0                    # 目标编号   
	}
}
var target_data:Array = []

enum EffectType { HEALTH_CHANGE, STATUS_APPLY }
enum StatusType { BUFF, DEBUFF, SPECIAL }

var effect_template = {
	"type": EffectType.HEALTH_CHANGE,   # 效果类型
	"value": 0,                         # 效果数值
	"status_info": {                    # 状态效果信息
		"status_type": StatusType.BUFF,
		"status_name": "",
		"duration": 0,                  # 持续回合数
		"stack_count": 1,               # 叠加层数
	},
	"target_index": [0,1]               # 对应目标编号
}

var effect_data:Array = []

var is_peak: bool = false #是否是进阶法术
var is_soul: bool = false #是否是魂镌法术
var owner_character: String = "" # 如果是魂镌法术，记录所属角色
	
func init(data: Dictionary) -> HexData:
	hex_name = data.get("hex_name", "")
	texture_path = data.get("texture_path", "")
	caster = data.get("caster", "ally facing up")
	cast_condition = data.get("cast_condition", DiceFace.UP)
	target_data = data.get("target_data",[])
	effect_data = data.get("effect_data",[])
	is_peak = data.get("is_peak", false)
	is_soul = data.get("is_soul", false)
	owner_character = data.get("owner_character", "")
	return self

func to_dict() -> Dictionary:
	var serialized_target_data = []
	for target in target_data:
		var serialized_target = target.duplicate(true)
		if target.has("team"):
			serialized_target["team"] = int(target["team"])
		if target.has("type"):
			serialized_target["type"] = int(target["type"])
		if target.has("condition") and target["condition"].has("dice_reference"):
			var dice_ref = target["condition"]["dice_reference"]
			if dice_ref.has("type"):
				serialized_target["condition"]["dice_reference"]["type"] = int(dice_ref["type"])
			if dice_ref.has("face"):
				serialized_target["condition"]["dice_reference"]["face"] = int(dice_ref["face"])
		serialized_target_data.append(serialized_target)

	var serialized_effect_data = []
	for effect in effect_data:
		var serialized_effect = effect.duplicate(true)
		if effect.has("type"):
			serialized_effect["type"] = int(effect["type"])
		if effect.has("status_info") and effect["status_info"].has("status_type"):
			serialized_effect["status_info"]["status_type"] = int(effect["status_info"]["status_type"])
		serialized_effect_data.append(serialized_effect)

	return {
		"hex_name": hex_name,
		"texture_path": texture_path,
		"target_data": serialized_target_data,
		"effect_data": serialized_effect_data,
		"cast_condition": int(cast_condition),
		"is_peak": is_peak,
		"is_soul": is_soul,
		"owner_character": owner_character
	}

func from_dict(data: Dictionary) -> void:
	hex_name = data.get("hex_name", "")
	texture_path = data.get("texture_path", "")
	cast_condition = data.get("cast_condition", DiceFace.UP)

	# 反序列化 target_data
	target_data = []
	for target in data.get("target_data", []):
		var deserialized_target = target.duplicate(true)
		if target.has("team"):
			deserialized_target["team"] = TargetTeam.values()[target["team"]]
		if target.has("type"):
			deserialized_target["type"] = TargetType.values()[target["type"]]
		if target.has("condition") and target["condition"].has("dice_reference"):
			var dice_ref = target["condition"]["dice_reference"]
			if dice_ref.has("type"):
				deserialized_target["condition"]["dice_reference"]["type"] = DiceType.values()[dice_ref["type"]]
			if dice_ref.has("face"):
				deserialized_target["condition"]["dice_reference"]["face"] = DiceFace.values()[dice_ref["face"]]
		target_data.append(deserialized_target)

	# 反序列化 effect_data
	effect_data = []
	for effect in data.get("effect_data", []):
		var deserialized_effect = effect.duplicate(true)
		if effect.has("type"):
			deserialized_effect["type"] = EffectType.values()[effect["type"]]
		if effect.has("status_info") and effect["status_info"].has("status_type"):
			deserialized_effect["status_info"]["status_type"] = StatusType.values()[effect["status_info"]["status_type"]]
		effect_data.append(deserialized_effect)

	is_peak = data.get("is_peak", false)
	is_soul = data.get("is_soul", false)
	owner_character = data.get("owner_character", "")
