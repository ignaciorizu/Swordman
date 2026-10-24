extends Area2D

const MAX_TRAVEL_DISTANCE: float = 100.0
const FADE_DURATION: float = 0.2
const OFFSET_ROTATION: float = -PI / 2.0

@export var speed : float = 100.0
@export var damage :int = 10

var move_direction: Vector2 = Vector2.ZERO
var distance_traveled: float = 0.0
var is_fading: bool = false

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	rotation = move_direction.angle() + OFFSET_ROTATION
	animated_sprite_2d.play("idle")

func _physics_process(delta: float) -> void:
	if is_fading:
		return
		
	var step_vector: Vector2 = move_direction * speed * delta
	position += step_vector
	distance_traveled += step_vector.length()
	
	if distance_traveled >= MAX_TRAVEL_DISTANCE:
		dissipation()

func dissipation() -> void:
	is_fading = true
	set_deferred(&"monitoring", false)
	
	var tween: Tween = create_tween()
	tween.tween_property(self, ^"modulate:a", 0.0, FADE_DURATION)
	tween.tween_callback(queue_free)

func _on_body_entered(body: Node2D) -> void:
	if is_fading:
		return
		
	if not body.is_in_group("player"):
		return
		
	body.take_damage(damage, global_position)
	dissipation()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
