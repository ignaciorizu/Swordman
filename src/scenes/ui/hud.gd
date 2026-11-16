extends Control

const SECONDS_PER_MINUTE: int = 60
const TIME_FORMAT_TEMPLATE: String = "%02d:%02d"

@onready var health_bar: TextureProgressBar = $MarginContainer/HBoxContainer/HealthBar
@onready var score_label: Label = $MarginContainer/HBoxContainer/Score
@onready var time_label: Label = $MarginContainer/HBoxContainer/Time

func _ready() -> void:
	EventBus.player_health_changed.connect(update_health_display)
	EventBus.score_changed.connect(update_score_display)
	EventBus.time_updated.connect(update_time_display)
	
	update_health_display(GameState.current_player_health, GameState.MAX_PLAYER_HEALTH)
	update_score_display(GameState.current_score)
	update_time_display(GameState.time_remaining)
	GameState.start_level_timer()

func update_health_display(current_health: int, max_health: int) -> void:
	health_bar.max_value = max_health
	health_bar.value = current_health

func update_score_display(new_score: int) -> void:
	score_label.text = "Puntos: " + str(new_score)

func update_time_display(time_left: int) -> void:
	var minutes: int = time_left / SECONDS_PER_MINUTE
	var seconds: int = time_left % SECONDS_PER_MINUTE
	time_label.text = TIME_FORMAT_TEMPLATE % [minutes, seconds]
