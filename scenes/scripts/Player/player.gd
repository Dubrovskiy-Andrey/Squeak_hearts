extends CharacterBody2D

enum State {
	IDLE,
	MOVE,
	JUMP,
	ATTACK
}

@export var move_speed: float = 250.0
@export var gravity: float = 800.0
@export var jump_force: float = -1000.0
@export var attack_cooldown: float = 0.2

var state: State = State.IDLE
var can_attack: bool = true
var is_attacking: bool = false
@onready var pickup_point = $PickupPoint
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	# Гравитация
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	# Машина состояний
	match state:
		State.IDLE:
			state_idle()
		State.MOVE:
			state_move()
		State.JUMP:
			state_jump()
		State.ATTACK:
			# атака обрабатывается один раз при входе
			pass

	move_and_slide()

# ------------------ Состояния ------------------

func state_idle() -> void:
	var dir := Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")

	if dir != 0:
		state = State.MOVE
		return

	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = jump_force
		anim_player.play("Jump")
		state = State.JUMP
		return

	if Input.is_action_just_pressed("attack") and can_attack and not is_attacking:
		start_attack()
		return

	anim_player.play("Idle")
	velocity.x = move_toward(velocity.x, 0, move_speed)

func state_move() -> void:
	var dir := Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	velocity.x = dir * move_speed

	if dir != 0:
		sprite.flip_h = dir > 0
		anim_player.play("Walk")
	else:
		state = State.IDLE
		return

	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = jump_force
		anim_player.play("Jump")
		state = State.JUMP
		return

	if Input.is_action_just_pressed("attack") and can_attack and not is_attacking:
		start_attack()
		return

func state_jump() -> void:
	anim_player.play("Jump")

	# движение в воздухе
	var dir := Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	velocity.x = dir * move_speed
	if dir != 0:
		sprite.flip_h = dir > 0
	
	# атака в прыжке с отбрасыванием в противоположную сторону
	if Input.is_action_just_pressed("attack") and can_attack and not is_attacking:
		start_attack()

		# если влево — отбрасываем вправо
		if Input.is_action_pressed("ui_left"):
			velocity.x = 1200
		# если вправо — отбрасываем влево
		elif Input.is_action_pressed("ui_right"):
			velocity.x = -1200

	# переход на землю
	if is_on_floor():
		state = State.IDLE

# ------------------ Атака ------------------

func start_attack() -> void:
	if is_attacking:
		return

	is_attacking = true
	can_attack = false
	state = State.ATTACK
	velocity.x = 0

	anim_player.play("Attack")
	await anim_player.animation_finished

	await get_tree().create_timer(attack_cooldown).timeout
	state = State.IDLE
	is_attacking = false
	can_attack = true


func _input(event):
	if event.is_action_pressed("pickup"):
		if $PickupZone.items_in_range.size() > 0:
			var pickup_item = $PickupZone.items_in_range.values()[0]
			pickup_item.pick_up_item(self)
			$PickupZone.items_in_range.erase(pickup_item)
