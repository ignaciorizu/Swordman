extends Control

func _ready() -> void:
	AudioManager.play("Fondo")

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://src/scenes/levels/Level1.tscn")


func _on_options_pressed() -> void:
	pass # Replace with function body.


func _on_credits_pressed() -> void:
	AudioManager.stop("Fondo")
	get_tree().change_scene_to_file("res://src/scenes/levels/Creditos.tscn")


func _on_exit_pressed() -> void:
	AudioManager.stop("Fondo")
	get_tree().quit()
