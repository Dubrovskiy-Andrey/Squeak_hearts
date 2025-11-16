extends CharacterBody2D

const ACCELERATION = 460
const MAX_SPEED = 550

var item_name = "Trash"
var being_picked_up = false
var player = null

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta):
	if not being_picked_up:
		# падает вниз
		velocity = velocity.move_toward(Vector2(0, MAX_SPEED), ACCELERATION * delta)
	else:
		# отключаем гравитацию и летим строго к игроку
		var direction = global_position.direction_to(player.pickup_point.global_position)
		velocity = direction * MAX_SPEED
		
		if global_position.distance_to(player.pickup_point.global_position) < 10:
			PlayerInventory.add_item(item_name, 1)
			queue_free()

	move_and_slide()

func pick_up_item(body):
	player = body
	being_picked_up = true
