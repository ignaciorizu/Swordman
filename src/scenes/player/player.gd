extends CharacterBody2D

@onready var animation_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sword_hitbox: Area2D = $sword_hitbox
@onready var camera_2d: Camera2D = $Camera2D

const MOVEMENT_SPEED: float = 70.0
const RUN_SPEED_MULTIPLIER: float = 1.6
const HITBOX_OFFSET: float = 20.0
const KNOCKBACK_FORCE: float = 120.0
const KNOCKBACK_DURATION: float = 0.2
const INVULNERABILITY_DURATION: float = 0.5
const SHAKE_INTENSITY: float = 4.0
const SHAKE_DURATION: float = 0.3
const SWORD_DAMAGE: int = 15
const DAMAGE_COLOR: Color = Color(0.8, 0.1, 0.2, 1.0) 
const NORMAL_COLOR: Color = Color.WHITE
const AUDIO_STEP: StringName = &"Pasos"
const AUDIO_SWORD: StringName = &"Espada"
const AUDIO_DAMAGE: StringName = &"Danio"

var active_movement_input: StringName = &""
var current_facing_direction: StringName = &"ui_down"
var run_ability_unlock: bool = false
var is_attacking: bool = false
var is_knocked_back: bool = false
var is_invulnerable: bool = false
var camera_shake_time: float = 0.0
var is_dead: bool = false

var life: int = 100

func _ready() -> void:
	sword_hitbox.monitoring = false

func _input(event: InputEvent) -> void:
	process_attack_input(event, &"ui_attack")

func process_attack_input(event: InputEvent, action: StringName) -> void:
	if not event.is_action_pressed(action) or is_attacking or is_dead:
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
	if is_knocked_back:
		return

	if is_attacking or is_dead:
		velocity = Vector2.ZERO
		return

	var input_vector: Vector2 = Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down")
	
	if input_vector == Vector2.ZERO:
		velocity = Vector2.ZERO
		return
		
	resolve_facing_direction(input_vector)
	var current_speed: float = calculate_movement_speed()
	velocity = input_vector * current_speed
	
func resolve_facing_direction(direction: Vector2) -> void:
	if direction.x != 0.0:
		current_facing_direction = &"ui_right" if direction.x > 0 else &"ui_left"
	elif direction.y != 0.0:
		current_facing_direction = &"ui_down" if direction.y > 0 else &"ui_up"

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
	sword_hitbox.set_deferred(&"monitoring", true)

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
	sword_hitbox.rotation = transform_data.get("rotation")

func determine_movement_state() -> StringName:
	var input_vector: Vector2 = Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down")
	if input_vector == Vector2.ZERO:
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
	
	animation_sprite.play(target_animation)

func dispatch_animation() -> void:
	if is_attacking or is_knocked_back or is_dead:
		return
		
	var input_vector: Vector2 = Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down")
	
	if input_vector == Vector2.ZERO:
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
	animation_sprite.play(target_animation)
	
func play_walk_animation() -> void:
	var walk_animation_map := {
		&"ui_up": &"WalkUp",
		&"ui_down": &"WalkDown",
		&"ui_left": &"WalkLeft",
		&"ui_right": &"WalkRight"
	}
	
	var target_animation: StringName = walk_animation_map.get(current_facing_direction, &"WalkDown")
	animation_sprite.play(target_animation)
	
func play_run_animation() -> void:
	var run_animation_map := {
		&"ui_up": &"RunUp",
		&"ui_down": &"RunDown",
		&"ui_left": &"RunLeft",
		&"ui_right": &"RunRight"
	}
	
	var target_animation: StringName = run_animation_map.get(current_facing_direction, &"RunDown")
	animation_sprite.play(target_animation)

func take_damage(damage: int, attacker_position: Vector2):
	if is_invulnerable or is_dead:
		return

	life -= damage
	if life - damage <= 0:
		player_dies()
		return
	
	apply_knockback(attacker_position)
	trigger_camera_shake(SHAKE_DURATION)
	activate_invulnerability()
	
func apply_knockback(attacker_position: Vector2) -> void:
	is_knocked_back = true
	play_hurt_animation()
	var knockback_direction: Vector2 = attacker_position.direction_to(global_position)
	velocity = knockback_direction * KNOCKBACK_FORCE
	
	get_tree().create_timer(KNOCKBACK_DURATION).timeout.connect(resolve_knockback_state)

func resolve_knockback_state() -> void:
	is_knocked_back = false

func activate_invulnerability() -> void:
	is_invulnerable = true
	animation_sprite.modulate = DAMAGE_COLOR
	get_tree().create_timer(INVULNERABILITY_DURATION).timeout.connect(resolve_invulnerability_state)

func resolve_invulnerability_state() -> void:
	is_invulnerable = false
	animation_sprite.modulate = NORMAL_COLOR

func play_hurt_animation():
	var hurt_animation_map := {
		&"ui_up": &"HurtUp",
		&"ui_down": &"HurtDown",
		&"ui_left": &"HurtLeft",
		&"ui_right": &"HurtRight"
	}

	var target_animation: StringName = hurt_animation_map.get(current_facing_direction, &"HurtDown")
	animation_sprite.play(target_animation)

func trigger_camera_shake(duration: float) -> void:
	camera_shake_time = duration

func process_camera_shake(delta: float) -> void:
	if camera_shake_time <= 0.0:
		camera_2d.offset = Vector2.ZERO
		return
		
	camera_shake_time -= delta
	camera_2d.offset = Vector2(randf_range(-SHAKE_INTENSITY, SHAKE_INTENSITY), randf_range(-SHAKE_INTENSITY, SHAKE_INTENSITY))

func player_dies():
	if is_dead:
		return

	play_dies_animation()
	is_dead = true
	velocity = Vector2.ZERO

func play_dies_animation():
	var dies_animation_map := {
		&"ui_up": &"DiesUp",
		&"ui_down": &"DiesDown",
		&"ui_left": &"DiesLeft",
		&"ui_right": &"DiesRight"
	}

	var target_animation: StringName = dies_animation_map.get(current_facing_direction, &"DiesDown")
	animation_sprite.play(target_animation)

func _on_sword_hitbox_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(SWORD_DAMAGE, global_position)

	if body.has_method("process_impact"):
		body.process_impact(sword_hitbox.global_position)

func _on_animated_sprite_2d_frame_changed() -> void:
	var current_anim: String = animation_sprite.animation
	var current_frame: int = animation_sprite.frame
	
	var audio_trigger_map := {
		"Walk": {"frames": [1, 3, 5], "sound": AUDIO_STEP},
		"Run": {"frames": [1, 3, 5], "sound": AUDIO_STEP},
		"Attack": {"frames": [0], "sound": AUDIO_SWORD},
		"Hurt": {"frames": [1], "sound": AUDIO_DAMAGE}
	}
	
	for action_prefix in audio_trigger_map:
		if current_anim.begins_with(action_prefix):
			process_audio_trigger(audio_trigger_map.get(action_prefix), current_frame)
			return

func process_audio_trigger(config: Dictionary, frame: int) -> void:
	var valid_frames: Array = config.get("frames", [])
	
	if frame not in valid_frames:
		return
		
	var sound_name: StringName = config.get("sound", &"")
	AudioManager.play(sound_name)


func _on_animated_sprite_2d_animation_finished() -> void:
	if not is_attacking:
		return
		
	is_attacking = false
	sword_hitbox.set_deferred(&"monitoring", false)
