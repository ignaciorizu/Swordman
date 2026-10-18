extends CharacterBody2D

const MOVE_SPEED = 30.0
const ARRIVAL_TOLERANCE: float = 1

var route_patrol: PackedVector2Array = []
var actual_point: int = 0
var direction: StringName = &""

@export var patrol_path: Path2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	global_position = patrol_path.to_global(patrol_path.curve.get_point_position(0))
	get_route()

func get_route():
	route_patrol = patrol_path.curve.get_baked_points()
	for point in range(route_patrol.size()):
		route_patrol[point] = patrol_path.to_global(route_patrol[point])

func _physics_process(delta: float) -> void:
	patrol_Move()
	move_and_slide()
	animation_enemie()

func patrol_Move():
	if route_patrol.is_empty():
		velocity = Vector2.ZERO
		return

	var point: Vector2 = route_patrol[actual_point]
	if global_position.distance_to(point) < 1:
		actual_point = (actual_point + 1) % route_patrol.size()
		return

	velocity = global_position.direction_to(point) * MOVE_SPEED

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

func animation_enemie() -> void:
	if velocity == Vector2.ZERO:
		return
	
	direction_enemie()
	var target_animation := StringName("Walk" + direction)
	assert(animated_sprite_2d.sprite_frames.has_animation(target_animation), "Animacion inexistente: " + target_animation)
	animated_sprite_2d.play(target_animation)
