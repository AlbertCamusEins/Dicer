extends Label



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	text = text + str(BattleManager.phase_count)
	BattleManager.phase_changed.connect(_on_phase_changed)
	
func _on_phase_changed():
	text = "Round " + str(BattleManager.phase_count)
