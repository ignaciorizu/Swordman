extends Area2D

const GROUP_PLAYER: String = "player"	

func _on_body_entered(body: Node2D) -> void:
	var is_valid_player: bool = body != null and body.is_in_group(GROUP_PLAYER)

	if(is_valid_player):
		_active_player_run(body)

func _active_player_run(body: Node2D) -> void:
	body.run_ability_unlock = true
	queue_free()
