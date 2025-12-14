extends CharacterBody2D

const ACCELERATION = 460
const MAX_SPEED = 550

var item_name: String = "Crystal"
var being_picked_up: bool = false
var player = null
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready():
	add_to_group("crystals")
	_start_animation()

func _physics_process(delta):
	if not being_picked_up:
		velocity = velocity.move_toward(Vector2(0, MAX_SPEED), ACCELERATION * delta)
	else:
		if not is_instance_valid(player):
			queue_free()
			return
		
		var target = player.pickup_point.global_position
		var dir = (target - global_position)
		if dir.length() > 0:
			dir = dir.normalized()
		velocity = dir * MAX_SPEED

		if global_position.distance_to(target) < 12:
			player._auto_pick_crystal(self)
			queue_free()

	move_and_slide()

func pick_up(by_player):
	player = by_player
	being_picked_up = true

func _start_animation():
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(sprite, "rotation", PI * 2, 3.0)
	
	var tween2 = create_tween()
	tween2.set_loops()
	tween2.tween_property(sprite, "modulate:a", 0.8, 0.8)
	tween2.tween_property(sprite, "modulate:a", 1.0, 0.8)
