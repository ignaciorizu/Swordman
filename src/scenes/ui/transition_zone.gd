extends Area2D

@export_file("*.tscn") var target_scene_path: String

func _ready() -> void:
	pass

func _on_body_entered(body: Node2D) -> void:
	if target_scene_path.is_empty() or not body.is_in_group(&"player"):
		return
		
	call_deferred(&"execute_scene_transition")

func execute_scene_transition() -> void:
	get_tree().change_scene_to_file(target_scene_path)
