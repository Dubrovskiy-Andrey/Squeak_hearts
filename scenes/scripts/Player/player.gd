extends CharacterBody2D

enum State { IDLE, MOVE, JUMP, ATTACK }

@export var move_speed: float = 250.0
@export var gravity: float = 800.0
@export var jump_force: float = -900.0
@export var attack_cooldown: float = 0.2
@export var max_health: float = 100.0

@export var inventory_path = "../UserInterface/Inventory"  # путь к Inventory в сцене
var inventory_node

var state: State = State.IDLE
var can_attack: bool = true
var is_attacking: bool = false
var can_move: bool = true
var current_health: float = max_health

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var pickup_point = $PickupPoint

func _ready():
	add_to_group("players")
	current_health = max_health
	if inventory_path:
		inventory_node = get_node(inventory_path)

func _input(event):
	if event.is_action_pressed("inventory") and inventory_node:
		inventory_node.visible = !inventory_node.visible
		can_move = not inventory_node.visible  # блокируем движение при открытом инвентаре

	if event.is_action_pressed("pickup") and $PickupZone.items_in_range.size() > 0:
		var pickup_item = $PickupZone.items_in_range.values()[0]
		pickup_item.pick_up_item(self)
		$PickupZone.items_in_range.erase(pickup_item)

func _physics_process(delta: float) -> void:
	if not can_move:
		anim_player.play("Idle")
		velocity = Vector2.ZERO
		return

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
			pass

	move_and_slide()

# ----------------- Состояния -----------------
func state_idle():
	var dir = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
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

func state_move():
	var dir = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
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

func state_jump():
	anim_player.play("Jump")
	var dir = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	velocity.x = dir * move_speed
	if dir != 0:
		sprite.flip_h = dir > 0

	if Input.is_action_just_pressed("attack") and can_attack:
		start_attack()

	if is_on_floor():
		state = State.IDLE

# ----------------- Атака -----------------
func start_attack():
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

# ----------------- Здоровье -----------------
func take_damage(damage: float) -> void:
	current_health -= damage
	current_health = max(0, current_health)
	print("Игрок получил урон:", damage, "Текущее здоровье:", current_health)
	if current_health <= 0:
		die()

func heal(heal_amount: float) -> void:
	current_health += heal_amount
	current_health = min(current_health, max_health)
	print("Игрок вылечен на:", heal_amount, "Текущее здоровье:", current_health)

func die() -> void:
	print("Игрок умер!")
