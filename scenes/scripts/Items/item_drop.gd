extends CharacterBody2D

const ACCELERATION = 460
const MAX_SPEED = 550

var item_name: String = "Trash"
var being_picked_up: bool = false
var player = null
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	add_to_group("item_drop")

func _physics_process(delta):
	if not being_picked_up:
		# падаем вниз
		velocity = velocity.move_toward(Vector2(0, MAX_SPEED), ACCELERATION * delta)
	else:
		# летим к игроку
		if not is_instance_valid(player):
			queue_free()
			return
		var target = player.pickup_point.global_position
		var dir = (target - global_position)
		if dir.length() > 0:
			dir = dir.normalized()
		velocity = dir * MAX_SPEED

		if global_position.distance_to(target) < 12:
			# вызываем функцию на игроке для добавления валюты / инвентаря
			player._auto_pick_item(self)
			queue_free()

	move_and_slide()

func pick_up_item(by_player):
	player = by_player
	being_picked_up = true
