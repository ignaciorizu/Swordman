extends Control

const AUDIO_BUTTON: StringName = &"SelectButton"

func pause() -> void:
	get_tree().paused =! get_tree().paused
	visible = get_tree().paused

func _ready() -> void:
	visible = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_pause"):
		pause()

func _on_resume_buttom_pressed() -> void:
	AudioManager.play(AUDIO_BUTTON)
	pause()

func _on_restart_buttom_pressed() -> void:
	AudioManager.play(AUDIO_BUTTON)
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_main_menu_buttom_pressed() -> void:
	AudioManager.play(AUDIO_BUTTON)
	get_tree().paused = false
	get_tree().change_scene_to_file("res://src/scenes/levels/Start_Menu.tscn")

func _on_exit_buttom_pressed() -> void:
	AudioManager.play(AUDIO_BUTTON)
	get_tree().quit()
