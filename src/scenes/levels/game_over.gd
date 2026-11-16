extends Control

const SECONDS_PER_MINUTE: int = 60
const MINIMUM_SECONDS: int = 0
const TIME_FORMAT_TEMPLATE: String = "%02d:%02d"
const LABEL_PREFIX_SCORE: String = "Puntos: "
const LABEL_PREFIX_TIME_PLAYED: String = "Tiempo Jugado: "
const LABEL_PREFIX_TIME_REMAINING: String = "Tiempo Restante: "
const LABEL_PREFIX_CAUSE: String = "Causa: "
const LEVEL_1_SCENE_PATH: String = "res://src/scenes/levels/Level1.tscn"
const MAIN_MENU_SCENE_PATH: String = "res://src/scenes/levels/Start_Menu.tscn"

@onready var score_label: Label = $Status/Score
@onready var time_played_label: Label = $Status/TimePlayed
@onready var time_remaining_label: Label = $Status/TimeRemaining
@onready var cause_label: Label = $Status/Cause

func _ready() -> void:
	get_tree().paused = false
	visible = true
	populate_statistics(GameState.last_death_cause)

func populate_statistics(cause: StringName) -> void:
	if not are_status_labels_valid():
		push_error("Faltan referencias de nodos Label dentro del contenedor Status en Game_Over")
		return
		
	var time_played: int = GameState.LEVEL_TIME_LIMIT - GameState.time_remaining
	
	score_label.text = LABEL_PREFIX_SCORE + str(GameState.current_score)
	time_played_label.text = LABEL_PREFIX_TIME_PLAYED + format_seconds_to_clock(time_played)
	time_remaining_label.text = LABEL_PREFIX_TIME_REMAINING + format_seconds_to_clock(GameState.time_remaining)
	cause_label.text = LABEL_PREFIX_CAUSE + String(cause)

func are_status_labels_valid() -> bool:
	var required_labels: Array[Label] = [
		score_label,
		time_played_label,
		time_remaining_label,
		cause_label
	]
	
	for label_node in required_labels:
		if not is_instance_valid(label_node):
			return false
			
	return true

func format_seconds_to_clock(total_seconds: int) -> String:
	var clamped_seconds: int = maxi(MINIMUM_SECONDS, total_seconds)
	var minutes: int = clamped_seconds / SECONDS_PER_MINUTE
	var seconds: int = clamped_seconds % SECONDS_PER_MINUTE
	return TIME_FORMAT_TEMPLATE % [minutes, seconds]

func _on_retry_button_pressed() -> void:
	navigate_to_scene(LEVEL_1_SCENE_PATH)

func _on_main_menu_button_pressed() -> void:
	navigate_to_scene(MAIN_MENU_SCENE_PATH)

func _on_exit_button_pressed() -> void:
	get_tree().quit()

func navigate_to_scene(target_path: String) -> void:
	if not ResourceLoader.exists(target_path):
		push_error("Ruta de escena inexistente: " + target_path)
		return
		
	get_tree().paused = false
	GameState.reset_session()
	get_tree().change_scene_to_file(target_path)
