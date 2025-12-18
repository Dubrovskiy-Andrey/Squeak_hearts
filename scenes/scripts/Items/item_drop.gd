extends CharacterBody2D

const ACCELERATION = 460
const MAX_SPEED = 550

@export var item_id: String = "item_"
var my_unique_id: String = ""
var enemy_id: String = ""
var item_name: String = "Trash"
var being_picked_up: bool = false
var player = null
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	if enemy_id != "":
		my_unique_id = enemy_id + "_" + item_id
	else:
		my_unique_id = item_id + "_" + str(int(global_position.x)) + "_" + str(int(global_position.y)) + "_" + name
	
	if save_system and save_system.is_item_collected(my_unique_id):
		print("Предмет уже собран, удаляем: ", my_unique_id)
		queue_free()
		return
	
	add_to_group("item_drop")

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
			if player.has_method("_auto_pick_item"):
				player._auto_pick_item(self)
			queue_free()

	move_and_slide()

func pick_up_item(by_player):
	player = by_player
	being_picked_up = true
	
	if save_system and my_unique_id != "":
		save_system.mark_item_collected(my_unique_id)
		print("Предмет помечен как собранный: ", my_unique_id)

func set_enemy_id(id: String):
	enemy_id = id
	if enemy_id != "":
		my_unique_id = enemy_id + "_" + item_id
