extends Node

const MAX_PLAYER_HEALTH: int = 100
const INITIAL_ESSENCES: int = 0
const INITIAL_LEVEL: int = 1
const INITIAL_SCORE: int = 0
const LEVEL_TIME_LIMIT: int = 300
const TIMER_INTERVAL: float = 1.0
const DEATH_CAUSE_TIMEOUT: StringName = &"Tiempo Agotado"
const DEATH_CAUSE_UNKNOWN: StringName = &"Desconocida"
const GAME_OVER_SCENE_PATH: String = "res://src/scenes/levels/Game_Over.tscn"

var current_player_health: int = MAX_PLAYER_HEALTH
var corrupted_essences: int = INITIAL_ESSENCES
var current_level: int = INITIAL_LEVEL
var current_score: int = INITIAL_SCORE
var time_remaining: int = LEVEL_TIME_LIMIT
var last_death_cause: StringName = DEATH_CAUSE_UNKNOWN
var is_timer_active: bool = false

var global_timer: Timer

func _ready() -> void:
	setup_global_timer()
	EventBus.player_health_changed.connect(update_health_state)
	EventBus.essence_collected.connect(update_essence_state)
	EventBus.score_changed.connect(update_score_state)
	EventBus.player_died.connect(handle_player_death)

func setup_global_timer() -> void:
	global_timer = Timer.new()
	global_timer.wait_time = TIMER_INTERVAL
	global_timer.autostart = false
	global_timer.timeout.connect(process_time_tick)
	add_child(global_timer)

func start_level_timer() -> void:
	if is_timer_active:
		return
		
	is_timer_active = true
	global_timer.start()

func stop_level_timer() -> void:
	is_timer_active = false
	global_timer.stop()

func process_time_tick() -> void:
	if time_remaining <= 0:
		stop_level_timer()
		EventBus.time_expired.emit()
		EventBus.player_died.emit(DEATH_CAUSE_TIMEOUT)
		return
		
	time_remaining -= 1
	EventBus.time_updated.emit(time_remaining)

func handle_player_death(cause: StringName) -> void:
	stop_level_timer()
	last_death_cause = cause
	call_deferred(&"transition_to_game_over")

func transition_to_game_over() -> void:
	if not ResourceLoader.exists(GAME_OVER_SCENE_PATH):
		push_error("Ruta de escena Game Over invalida: " + GAME_OVER_SCENE_PATH)
		return
		
	get_tree().paused = false
	get_tree().change_scene_to_file(GAME_OVER_SCENE_PATH)

func update_health_state(new_health: int, _max_health: int) -> void:
	current_player_health = new_health

func update_essence_state(total_essences: int) -> void:
	corrupted_essences = total_essences

func update_score_state(new_score: int) -> void:
	current_score = new_score

func reset_session() -> void:
	stop_level_timer()
	current_player_health = MAX_PLAYER_HEALTH
	corrupted_essences = INITIAL_ESSENCES
	current_level = INITIAL_LEVEL
	current_score = INITIAL_SCORE
	time_remaining = LEVEL_TIME_LIMIT
	last_death_cause = DEATH_CAUSE_UNKNOWN
