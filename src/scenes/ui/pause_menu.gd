extends Control

func pause() -> void:
	get_tree().paused =! get_tree().paused
	visible = get_tree().paused

func _ready() -> void:
	pause()
	pause()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_pause"):
		pause()

func _on_resume_buttom_pressed() -> void:
	pause()

func _on_restart_buttom_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_main_menu_buttom_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://src/scenes/levels/Level1.tscn")

func _on_exit_buttom_pressed() -> void:
	get_tree().quit()
