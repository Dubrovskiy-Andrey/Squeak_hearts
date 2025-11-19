extends CharacterBody2D

enum State {
	IDLE,
	MOVE,
	JUMP,
	ATTACK
}

@export var move_speed: float = 250.0
@export var gravity: float = 800.0
@export var jump_force: float = -900.0
@export var attack_cooldown: float = 0.2

var state: State = State.IDLE
var can_attack: bool = true
var is_attacking: bool = false
var can_move: bool = true  # Добавляем переменную для управления движением
@onready var pickup_point = $PickupPoint
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	# Добавляем игрока в группу для управления
	add_to_group("players")

func enable_movement():
	can_move = true
	print("Движение разблокировано")

func disable_movement():
	can_move = false
	velocity = Vector2.ZERO  # Останавливаем игрока
	print("Движение заблокировано")

func _physics_process(delta: float) -> void:
	# Если движение заблокировано - выходим
	if not can_move:
		anim_player.play("Idle")
		return
	
	# Гравитация
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	# Проверка инвентаря — если открыт, останавливаем персонажа
	if $"../UserInterface/Inventory".visible:
		velocity.x = 0
		state = State.IDLE
		anim_player.play("Idle")

	# Машина состояний
	match state:
		State.IDLE:
			state_idle()
		State.MOVE:
			state_move()
		State.JUMP:
			state_jump()
		State.ATTACK:
			pass

	move_and_slide()

# Остальной код состояний без изменений...
func state_idle() -> void:
	if !$"../UserInterface/Inventory".visible:
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

	var dir := Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	velocity.x = dir * move_speed
	if dir != 0:
		sprite.flip_h = dir > 0

	if Input.is_action_just_pressed("attack") and can_attack:
		start_attack()

		if dir < 0:
			velocity.x = 50
		elif dir > 0:
			velocity.x = -50

	if is_on_floor():
		state = State.IDLE

func start_attack() -> void:
	if not can_attack:
		return

	can_attack = false
	is_attacking = true
	state = State.ATTACK
	velocity.x = 0

	anim_player.play("Attack")
	await anim_player.animation_finished
	
	await get_tree().create_timer(attack_cooldown).timeout
	state = State.IDLE
	is_attacking = false
	can_attack = true
	if velocity.y != 0:
		state = State.JUMP

func _input(event):
	if event.is_action_pressed("pickup"):
		if $PickupZone.items_in_range.size() > 0:
			var pickup_item = $PickupZone.items_in_range.values()[0]
			pickup_item.pick_up_item(self)
			$PickupZone.items_in_range.erase(pickup_item)
