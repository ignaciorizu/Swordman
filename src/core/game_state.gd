extends Node

const MAX_PLAYER_HEALTH: int = 100
const INITIAL_ESSENCES: int = 0
const INITIAL_LEVEL: int = 1

var current_player_health: int = MAX_PLAYER_HEALTH
var corrupted_essences: int = INITIAL_ESSENCES
var current_level: int = INITIAL_LEVEL

func _ready() -> void:
	EventBus.player_health_changed.connect(update_health_state)
	EventBus.essence_collected.connect(update_essence_state)

func update_health_state(new_health: int, _max_health: int) -> void:
	current_player_health = new_health

func update_essence_state(total_essences: int) -> void:
	corrupted_essences = total_essences

func reset_session() -> void:
	current_player_health = MAX_PLAYER_HEALTH
	corrupted_essences = INITIAL_ESSENCES
	current_level = INITIAL_LEVEL
