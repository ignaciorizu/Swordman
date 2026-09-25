extends CharacterBody2D

const SPEED: float = 100.0
var active_direction_name: StringName = &"";

func _input(event: InputEvent) -> void:
	process_movement_input(event, &"ui_up")
	process_movement_input(event, &"ui_down")
	process_movement_input(event, &"ui_left")
	process_movement_input(event, &"ui_right")

func process_movement_input(event: InputEvent, action: StringName) -> void:
	if event.is_action_pressed(action):
		active_direction_name = action
	elif event.is_action_released(action) and active_direction_name == action:
		active_direction_name = &""

func _physics_process(delta: float) -> void:
	movePlayer()
	move_and_slide()
	
func movePlayer() -> void:
	if active_direction_name.is_empty():
		velocity = Vector2.ZERO
		return
		
	var direction_map := {
		&"ui_up": Vector2.UP,
		&"ui_down": Vector2.DOWN,
		&"ui_left": Vector2.LEFT,
		&"ui_right": Vector2.RIGHT
	}
	
	var direction_vector: Vector2 = direction_map.get(active_direction_name, Vector2.ZERO)
	velocity = direction_vector * SPEED
