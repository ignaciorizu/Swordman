extends CharacterBody2D

@onready var _animation_sprite: AnimatedSprite2D = $AnimatedSprite2D

const MOVEMENT_SPEED: float = 100.0
const RUN_SPEED_MULTIPLIER: float = 1.6

var active_movement_input: StringName = &""
var current_facing_direction: StringName = &"ui_down"
var run_ability_unlock: bool = false

func _input(event: InputEvent) -> void:
	process_directional_input(event, &"ui_up")
	process_directional_input(event, &"ui_down")
	process_directional_input(event, &"ui_left")
	process_directional_input(event, &"ui_right")

func process_directional_input(event: InputEvent, action: StringName) -> void:
	if event.is_action_pressed(action):
		active_movement_input = action
		current_facing_direction = action
	elif event.is_action_released(action) and active_movement_input == action:
		active_movement_input = &""

func _physics_process(_delta: float) -> void:
	update_velocity()
	move_and_slide()
	dispatch_animation()

func update_velocity() -> void:
	if active_movement_input.is_empty():
		velocity = Vector2.ZERO
		return
	
	var direction_vector: Vector2 = calculate_direction_vector(active_movement_input)
	var velocity_player: float = calculate_movement_speed()
	velocity = direction_vector * velocity_player
	
func calculate_direction_vector(input_move: StringName) -> Vector2:
	var direction_map := {
		&"ui_up": Vector2.UP,
		&"ui_down": Vector2.DOWN,
		&"ui_left": Vector2.LEFT,
		&"ui_right": Vector2.RIGHT
	}
	
	return direction_map.get(input_move, Vector2.ZERO)

func calculate_movement_speed() -> float:
	if run_ability_unlock:
		var is_run_pressed: bool = Input.is_action_pressed(&"ui_run")
		return MOVEMENT_SPEED * RUN_SPEED_MULTIPLIER if is_run_pressed else MOVEMENT_SPEED
	return MOVEMENT_SPEED

func dispatch_animation() -> void:
	if active_movement_input.is_empty():
		play_idle_animation()
	elif (Input.is_action_pressed(&"ui_run") and run_ability_unlock):
		play_run_animation()
	else:
		play_walk_animation()

func play_idle_animation() -> void:
	var idle_animation_map := {
		&"ui_up": &"IdleUp",
		&"ui_down": &"IdleDown",
		&"ui_left": &"IdleLeft",
		&"ui_right": &"IdleRight"
	}
	
	var target_animation: StringName = idle_animation_map.get(current_facing_direction, &"IdleDown")
		
	_animation_sprite.play(target_animation)
	
func play_walk_animation() -> void:
	var walk_animation_map := {
		&"ui_up": &"WalkUp",
		&"ui_down": &"WalkDown",
		&"ui_left": &"WalkLeft",
		&"ui_right": &"WalkRight"
	}
	
	var target_animation: StringName = walk_animation_map.get(current_facing_direction, &"WalkDown")
	_animation_sprite.play(target_animation)
	
func play_run_animation() -> void:
	var run_animation_map := {
		&"ui_up": &"RunUp",
		&"ui_down": &"RunDown",
		&"ui_left": &"RunLeft",
		&"ui_right": &"RunRight"
	}
	
	var target_animation: StringName = run_animation_map.get(current_facing_direction, &"RunDown")
	_animation_sprite.play(target_animation)
