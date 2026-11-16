extends Node2D

func _ready() -> void:
	GameState.start_level_timer()
	EventBus.time_updated.emit(GameState.time_remaining)
	EventBus.score_changed.emit(GameState.current_score)
