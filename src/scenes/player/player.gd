extends CharacterBody2D

@onready var _animation_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _sword_hitbox: Area2D = $sword_hitbox

const MOVEMENT_SPEED: float = 100.0
const RUN_SPEED_MULTIPLIER: float = 1.6
const HITBOX_OFFSET: float = 20.0

var active_movement_input: StringName = &""
var current_facing_direction: StringName = &"ui_down"
var run_ability_unlock: bool = false
var is_attacking: bool = false

func _ready() -> void:
	_animation_sprite.animation_finished.connect(resolve_attack_state)
	_sword_hitbox.monitoring = false

func _input(event: InputEvent) -> void:
	process_attack_input(event, &"ui_attack")
	process_directional_input(event, &"ui_up")
	process_directional_input(event, &"ui_down")
	process_directional_input(event, &"ui_left")
	process_directional_input(event, &"ui_right")

func process_attack_input(event: InputEvent, action: StringName) -> void:
	if not event.is_action_pressed(action) or is_attacking:
		return

	execute_attack()

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
	if not run_ability_unlock:
		return MOVEMENT_SPEED

	var is_run_pressed: bool = Input.is_action_pressed(&"ui_run")
	return MOVEMENT_SPEED * RUN_SPEED_MULTIPLIER if is_run_pressed else MOVEMENT_SPEED

func execute_attack() -> void:
	is_attacking = true
	apply_hitbox_transform()
	_sword_hitbox.set_deferred(&"monitoring", true)

	var current_state: StringName = determine_movement_state()
	play_contextual_attack_animation(current_state)

func apply_hitbox_transform() -> void:
	var transform_map := {
		&"ui_up": {"rotation": 0.0},
		&"ui_down": {"rotation": PI},
		&"ui_left": {"rotation": -PI / 2},
		&"ui_right": {"rotation": PI / 2}
	}
	
	var transform_data: Dictionary = transform_map.get(current_facing_direction, transform_map.get(&"ui_down"))
	_sword_hitbox.rotation = transform_data.get("rotation")

func determine_movement_state() -> StringName:
	if active_movement_input.is_empty():
		return &"Idle"
	if Input.is_action_pressed(&"ui_run") and run_ability_unlock:
		return &"Run"
	return &"Walk"

func play_contextual_attack_animation(state: StringName) -> void:
	var direction_suffix_map := {
		&"ui_up": &"Up",
		&"ui_down": &"Down",
		&"ui_left": &"Left",
		&"ui_right": &"Right"
	}
	
	var direction_suffix: StringName = direction_suffix_map.get(current_facing_direction, &"Down")
	var target_animation := StringName("Attack" + state + direction_suffix)
	
	_animation_sprite.play(target_animation)

func resolve_attack_state() -> void:
	if not is_attacking:
		return
		
	is_attacking = false
	_sword_hitbox.set_deferred(&"monitoring", false)

func dispatch_animation() -> void:
	if is_attacking:
		return
		
	if active_movement_input.is_empty():
		play_idle_animation()
	elif Input.is_action_pressed(&"ui_run") and run_ability_unlock:
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
