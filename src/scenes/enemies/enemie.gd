extends CharacterBody2D

enum CombatMode { MELEE, RANGED }

const KNOCKBACK_FORCE: float = 150.0
const KNOCKBACK_DURATION: float = 0.2
const MOVE_SPEED: float = 30.0
const ARRIVAL_TOLERANCE: float = 1.0
const MAX_PATROL_DEVIATION_SQUARED: float = 2000.0
const ATTACK_COOLDOWN: float = 2.0
const DAMAGE_COLOR: Color = Color(0.8, 0.1, 0.2, 1.0)
const NORMAL_COLOR: Color = Color.WHITE
const CORPSE_FADE_DURATION: float = 2.0
const TRANSPARENT_ALPHA: float = 0.0
const QUARTER_CIRCLE_RADIANS: float = PI / 4.0
const THREE_QUARTER_CIRCLE_RADIANS: float = (3.0 * PI) / 4.0
const INITIAL_PATROL_INDEX: int = 0
const INDEX_STEP: int = 1
const DEFAULT_SCORE_REWARD: int = 50

const GROUP_PLAYER: StringName = &"player"
const STATE_PATROL: StringName = &"Patrol"
const STATE_ATTACK: StringName = &"Attack"
const DIR_RIGHT: StringName = &"Right"
const DIR_LEFT: StringName = &"Left"
const DIR_UP: StringName = &"Up"
const DIR_DOWN: StringName = &"Down"
const AUDIO_ENEMY_DAMAGE: StringName = &"Danio_Enemigo"
const AUDIO_ENEMY_DETECTION: StringName = &"Deteccion_Enemigo"

@export var combat_mode: CombatMode = CombatMode.MELEE
@export var fire_ball: PackedScene
@export var fire_ball_speed: float = 100.0
@export var fire_ball_damage: float = 10.0
@export var max_health: int = 70
@export var attack_damage: int = 10
@export var score_reward: int = DEFAULT_SCORE_REWARD
@export var patrol_path: Path2D
@export var vision_square: float = 50.0

var is_knocked_back: bool = false
var is_dead: bool = false
var route_patrol: PackedVector2Array = []
var actual_point: int = INITIAL_PATROL_INDEX
var direction: StringName = DIR_DOWN
var state: StringName = STATE_PATROL
var player: Node2D = null
var is_attacking: bool = false
var can_shoot: bool = true
var life: int = 70

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var vision_zone: Area2D = $vision_zone
@onready var collision_shape_2d: CollisionShape2D = $vision_zone/CollisionShape2D
@onready var damage_zone: Area2D = $damage_zone
@onready var evil_particles: GPUParticles2D = $evil_particles

func _ready() -> void:
	configure_vision_radius()
	life = max_health
	animated_sprite_2d.animation_finished.connect(resolve_attack_state)
	initialize_patrol_route()

func configure_vision_radius() -> void:
	if not is_instance_valid(collision_shape_2d):
		return
		
	var custom_shape: RectangleShape2D = RectangleShape2D.new()
	custom_shape.size = Vector2(vision_square, vision_square)
	collision_shape_2d.shape = custom_shape

func initialize_patrol_route() -> void:
	if not is_instance_valid(patrol_path) or not is_instance_valid(patrol_path.curve):
		return
		
	if patrol_path.curve.point_count > INITIAL_PATROL_INDEX:
		var start_local_pos: Vector2 = patrol_path.curve.get_point_position(INITIAL_PATROL_INDEX)
		global_position = patrol_path.to_global(start_local_pos)
		
	extract_global_patrol_points()

func extract_global_patrol_points() -> void:
	route_patrol = patrol_path.curve.get_baked_points()
	for point_index in range(route_patrol.size()):
		route_patrol[point_index] = patrol_path.to_global(route_patrol[point_index])

func _physics_process(_delta: float) -> void:
	update_enemy_movement()
	move_and_slide()
	dispatch_enemy_animation()

func update_enemy_movement() -> void:
	if is_knocked_back or is_dead:
		return

	if is_attacking:
		velocity = Vector2.ZERO
		return

	var state_behavior_map: Dictionary = {
		STATE_PATROL: execute_patrol_movement,
		STATE_ATTACK: execute_combat_behavior
	}
	
	var behavior: Callable = state_behavior_map.get(state, execute_patrol_movement)
	behavior.call()

func execute_patrol_movement() -> void:
	if route_patrol.is_empty():
		velocity = Vector2.ZERO
		return

	var target_point: Vector2 = route_patrol[actual_point]
	if global_position.distance_to(target_point) < ARRIVAL_TOLERANCE:
		actual_point = (actual_point + INDEX_STEP) % route_patrol.size()
		return

	velocity = global_position.direction_to(target_point) * MOVE_SPEED

func execute_combat_behavior() -> void:
	if not is_instance_valid(player):
		state = STATE_PATROL
		return

	var combat_mode_map: Dictionary = {
		CombatMode.MELEE: execute_melee_chase,
		CombatMode.RANGED: execute_ranged_attack
	}
	
	var combat_action: Callable = combat_mode_map.get(combat_mode, execute_melee_chase)
	combat_action.call()

func execute_melee_chase() -> void:
	if has_exceeded_patrol_leash():
		state = STATE_PATROL
		return
		
	velocity = global_position.direction_to(player.global_position) * MOVE_SPEED

func has_exceeded_patrol_leash() -> bool:
	if route_patrol.is_empty():
		return false
		
	var point_count: int = route_patrol.size()
	var next_index: int = (actual_point + INDEX_STEP) % point_count
	var prev_index: int = wrapi(actual_point - INDEX_STEP, INITIAL_PATROL_INDEX, point_count)
	
	var dist_current: float = global_position.distance_squared_to(route_patrol[actual_point])
	var dist_next: float = global_position.distance_squared_to(route_patrol[next_index])
	var dist_prev: float = global_position.distance_squared_to(route_patrol[prev_index])
	
	return (
		dist_current > MAX_PATROL_DEVIATION_SQUARED
		and dist_next > MAX_PATROL_DEVIATION_SQUARED
		and dist_prev > MAX_PATROL_DEVIATION_SQUARED
	)

func execute_ranged_attack() -> void:
	velocity = Vector2.ZERO

	if not can_shoot:
		return
		
	var aim_vector: Vector2 = global_position.direction_to(player.global_position)
	resolve_facing_direction(aim_vector)
	fire_projectile()

func fire_projectile() -> void:
	if not is_instance_valid(fire_ball):
		return

	can_shoot = false
	is_attacking = true
	play_attack_animation()
	instantiate_fireball()
	get_tree().create_timer(ATTACK_COOLDOWN).timeout.connect(reset_shoot_cooldown)

func reset_shoot_cooldown() -> void:
	can_shoot = true

func instantiate_fireball() -> void:
	var new_fire_ball: Node2D = fire_ball.instantiate()
	new_fire_ball.global_position = global_position
	new_fire_ball.move_direction = global_position.direction_to(player.global_position)
	new_fire_ball.speed = fire_ball_speed
	new_fire_ball.damage = fire_ball_damage

	var level_root: Node = get_tree().current_scene
	if is_instance_valid(level_root):
		level_root.add_child(new_fire_ball)

func resolve_facing_direction(reference_vector: Vector2) -> void:
	if reference_vector == Vector2.ZERO:
		return
		
	var angle: float = reference_vector.angle()
	if absf(angle) <= QUARTER_CIRCLE_RADIANS:
		direction = DIR_RIGHT
	elif absf(angle) >= THREE_QUARTER_CIRCLE_RADIANS:
		direction = DIR_LEFT
	elif angle > QUARTER_CIRCLE_RADIANS:
		direction = DIR_DOWN
	else:
		direction = DIR_UP

func dispatch_enemy_animation() -> void:
	if velocity == Vector2.ZERO or is_attacking or is_knocked_back or is_dead:
		return

	resolve_facing_direction(velocity)
	play_walk_animation()

func play_walk_animation() -> void:
	var target_animation := StringName("Walk" + direction)
	animated_sprite_2d.play(target_animation)

func _on_vision_zone_body_entered(body: Node2D) -> void:
	if not body.is_in_group(GROUP_PLAYER) or state != STATE_PATROL or is_dead:
		return
		
	state = STATE_ATTACK
	player = body
	AudioManager.play(AUDIO_ENEMY_DETECTION)

func _on_vision_zone_body_exited(body: Node2D) -> void:
	if not body.is_in_group(GROUP_PLAYER) or state != STATE_ATTACK:
		return
		
	state = STATE_PATROL
	player = null

func _on_damage_zone_body_entered(body: Node2D) -> void:
	if not body.is_in_group(GROUP_PLAYER) or is_dead:
		return
		
	is_attacking = true
	if body.has_method(&"take_damage"):
		body.take_damage(attack_damage, global_position)
		
	deactivate_damage_zone()
	get_tree().create_timer(ATTACK_COOLDOWN).timeout.connect(activate_damage_zone)
	play_attack_animation()

func play_attack_animation() -> void:
	var target_animation := StringName("Attack" + direction)
	animated_sprite_2d.play(target_animation)

func resolve_attack_state() -> void:
	if not is_attacking:
		return
		
	is_attacking = false

func deactivate_damage_zone() -> void:
	damage_zone.set_deferred(&"monitoring", false)

func activate_damage_zone() -> void:
	if is_dead:
		return
	damage_zone.set_deferred(&"monitoring", true)

func take_damage(damage_amount: int, attacker_position: Vector2) -> void:
	if is_dead:
		return

	AudioManager.play(AUDIO_ENEMY_DAMAGE)
	life -= damage_amount
	if life <= 0:
		execute_death_sequence()
		return

	apply_knockback(attacker_position)

func apply_knockback(attacker_position: Vector2) -> void:
	is_knocked_back = true
	animated_sprite_2d.modulate = DAMAGE_COLOR
	play_hurt_animation()

	var knockback_direction: Vector2 = attacker_position.direction_to(global_position)
	velocity = knockback_direction * KNOCKBACK_FORCE
	
	get_tree().create_timer(KNOCKBACK_DURATION).timeout.connect(resolve_knockback_state)

func resolve_knockback_state() -> void:
	is_knocked_back = false
	animated_sprite_2d.modulate = NORMAL_COLOR

func play_hurt_animation() -> void:
	var target_animation := StringName("Hurt" + direction)
	animated_sprite_2d.play(target_animation)

func execute_death_sequence() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	set_physics_process(false)
	damage_zone.set_deferred(&"monitoring", false)
	vision_zone.set_deferred(&"monitoring", false)

	GameState.add_score(score_reward)
	disable_evil_particles()
	play_death_animation()
	fade_out_corpse()

func disable_evil_particles() -> void:
	if is_instance_valid(evil_particles):
		evil_particles.hide()

func play_death_animation() -> void:
	var death_animation_map: Dictionary = {
		DIR_LEFT: &"DiesLeft",
		DIR_UP: &"DiesLeft",
		DIR_DOWN: &"DiesLeft",
		DIR_RIGHT: &"DiesRight"
	}
	
	var target_animation: StringName = death_animation_map.get(direction, &"DiesLeft")
	animated_sprite_2d.play(target_animation)

func fade_out_corpse() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(animated_sprite_2d, ^"modulate:a", TRANSPARENT_ALPHA, CORPSE_FADE_DURATION)
	tween.tween_callback(queue_free)
