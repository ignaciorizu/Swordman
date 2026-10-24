extends CharacterBody2D

const KNOCKBACK_FORCE: float = 150.0
const KNOCKBACK_DURATION: float = 0.2
const MOVE_SPEED: float = 30.0
const ARRIVAL_TOLERANCE: float = 1
const MAX_DISTANCE: float = 1500
const ATTACK_COOLDOWN: float = 1.2
const DAMAGE_COLOR: Color = Color(0.8, 0.1, 0.2, 1.0) 
const NORMAL_COLOR: Color = Color.WHITE

@export var max_health: int = 70
@export var attack_damage: int = 10
@export var patrol_path: Path2D

var is_knocked_back: bool = false
var route_patrol: PackedVector2Array = []
var actual_point: int = 0
var direction: StringName = &""
var state: StringName = &"Patrol"
var player: Node2D = null
var is_attacking: bool = false
var life = 70

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var vision_zone: Area2D = $vision_zone
@onready var damage_zone: Area2D = $damage_zone

func _ready() -> void:
	animated_sprite_2d.animation_finished.connect(resolve_attack_state)
	global_position = patrol_path.to_global(patrol_path.curve.get_point_position(0))
	get_route()

func get_route():
	life = max_health
	route_patrol = patrol_path.curve.get_baked_points()
	for point in range(route_patrol.size()):
		route_patrol[point] = patrol_path.to_global(route_patrol[point])

func _physics_process(_delta: float) -> void:
	move_enemie()
	move_and_slide()
	enemie_animation()

func move_enemie():
	if is_knocked_back:
		return

	if is_attacking:
		velocity = Vector2.ZERO
		return

	if state == &"Patrol":
		patrol_move()
	elif state == &"Attack":
		attack_move()

func patrol_move():
	if route_patrol.is_empty():
		velocity = Vector2.ZERO
		return

	var point: Vector2 = route_patrol[actual_point]
	if global_position.distance_to(point) < 1:
		actual_point = (actual_point + 1) % route_patrol.size()
		return

	velocity = global_position.direction_to(point) * MOVE_SPEED

func attack_move():
	if ((global_position.distance_squared_to(route_patrol[actual_point]) > MAX_DISTANCE) 
		and (global_position.distance_squared_to(route_patrol[actual_point + 1]) > MAX_DISTANCE)
		and (global_position.distance_squared_to(route_patrol[actual_point - 1]) > MAX_DISTANCE)):
		state = &"Patrol"
	velocity = global_position.direction_to(player.global_position) * MOVE_SPEED
	
func direction_enemie():
	var angle_enemie: float = velocity.angle()
	if angle_enemie > -PI/4 and angle_enemie < PI/4:
		direction = &"Right"
	elif angle_enemie > PI/4 and angle_enemie < (3*PI)/4:
		direction = &"Down"
	elif (angle_enemie > (3*PI)/4 and angle_enemie < (5*PI)/4 ) or (angle_enemie > (-5*PI)/4 and angle_enemie < (-3*PI)/4):
		direction = &"Left"
	elif angle_enemie > (-3*PI)/4 and angle_enemie < PI/4:
		direction = &"Up"

func enemie_animation() -> void:
	if velocity == Vector2.ZERO or is_attacking or is_knocked_back:
		return

	direction_enemie()
	play_walk_animation()

func play_walk_animation():
	var target_animation := StringName("Walk" + direction)
	animated_sprite_2d.play(target_animation)

func _on_vision_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and state == &"Patrol":
		state = &"Attack"
		player = body

func _on_vision_zone_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and state == &"Attack":
		state = &"Patrol"
		player = null

func _on_damage_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_attacking = true
		body.take_damage(attack_damage, global_position)
		deactivate_damage_zone()
		get_tree().create_timer(ATTACK_COOLDOWN).timeout.connect(activate_damage_zone)
		play_attack_animation()

func play_attack_animation():
	var target_animation := StringName("Attack" + direction)
	animated_sprite_2d.play(target_animation)

func resolve_attack_state() -> void:
	if not is_attacking:
		return
		
	is_attacking = false

func deactivate_damage_zone():
	damage_zone.set_deferred("monitoring", false)

func activate_damage_zone():
	damage_zone.set_deferred("monitoring", true)
	
func take_damage(damage_amount: int, attacker_position: Vector2) -> void:
	life -= damage_amount
	if life <= 0:
		die()
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
	assert(animated_sprite_2d.sprite_frames.has_animation(target_animation), "Animacion inexistente")
	animated_sprite_2d.play(target_animation)

func die() -> void:
	set_physics_process(false)
	damage_zone.set_deferred(&"monitoring", false)
	vision_zone.set_deferred(&"monitoring", false)
	
	queue_free()
