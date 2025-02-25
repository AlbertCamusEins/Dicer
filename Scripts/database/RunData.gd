extends Node

class_name RunData

var current_floor: int = 1
var inventory: Inventory
var gold: int = 0
var goals_progress: Dictionary = {}
var reroll_count: int = 0


func _init():
	inventory = Inventory.new()
	
# 初始化新的游戏进程
func start_new_run() -> void:
	current_floor = 1
	gold = 0
	reroll_count = 0
	goals_progress.clear()
	
	# 清空并初始化仓库
	inventory.clear_all()
	
	#添加所有通用行动和施法行动
	var common_actions = GameDataManager.get_all_common_actions()
	var uncommon_actions = GameDataManager.get_all_uncommon_actions()
	for action in common_actions:
		inventory.add_face("common_action", action.action_name, {
			"action_name": action.action_name,
			"texture_path": action.texture_path,
			"effect": action.effect,
			"is_special": action.is_special
		})
	for action in uncommon_actions:
		if action.action_name == "Cast":
			inventory.add_face("uncommon_action", action.action_name, {
			"action_name": action.action_name,
			"texture_path": action.texture_path,
			"effect": action.effect,
			"is_special": action.is_special
		})


# 获得新的骰面
func acquire_face(face_type: String, face_id: String, face_data: Dictionary) -> void:
	inventory.add_face(face_type, face_id, face_data)

# 失去骰面
func lose_face(face_type: String, face_id: String) -> void:
	inventory.remove_face(face_type, face_id)

# 获得金币
func gain_gold(amount: int) -> void:
	gold += amount

# 消费金币
func spend_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		return true
	return false

# 更新目标进度
func update_goal_progress(goal_id: String, progress: float) -> void:
	goals_progress[goal_id] = progress

# 获取目标进度
func get_goal_progress(goal_id: String) -> float:
	return goals_progress.get(goal_id, 0.0)

# 进入下一层
func advance_to_next_floor() -> void:
	current_floor += 1
	MapStateManager.reset()

# 获得重投次数
func gain_reroll(amount: int = 1) -> void:
	reroll_count += amount

# 使用重投
func use_reroll() -> bool:
	if reroll_count > 0:
		reroll_count -= 1
		return true
	return false

# 导出存档数据
func save_data() -> Dictionary:
	return {
		"current_floor": current_floor,
		"inventory": inventory.save_data(),
		"gold": gold,
		"goals_progress": goals_progress,
		"reroll_count": reroll_count
	}

# 从存档数据加载
func load_data(data: Dictionary) -> void:
	current_floor = data.get("current_floor", 1)
	inventory.load_data(data.get("inventory", {}))
	gold = data.get("gold", 0)
	goals_progress = data.get("goals_progress", {})
	reroll_count = data.get("reroll_count", 0)
