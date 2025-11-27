extends CharacterBody2D

# Сигналы для здоровья и смерти
signal health_changed(current_health, max_health)
signal player_died()

enum State { IDLE, MOVE, JUMP, ATTACK }

@export var move_speed: float = 250.0
@export var gravity: float = 800.0
@export var jump_force: float = -900.0
@export var attack_cooldown: float = 0.2
@export var max_health: float = 100.0
@export var attack_damage: int = 20

@export var inventory_path = "../UserInterface/Inventory"
var inventory_node

var state: State = State.IDLE
var can_attack: bool = true
var is_attacking: bool = false
var can_move: bool = true
var current_health: float = max_health

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var pickup_point = $PickupPoint
@onready var attack_range = $AttackRange
@onready var hit_box = $HitBox

var enemies_in_attack_range: Array = []

func _ready():
	add_to_group("players")
	current_health = max_health
	emit_signal("health_changed", current_health, max_health)
	
	if inventory_path:
		inventory_node = get_node(inventory_path)
	
	# Подключаем сигналы для системы боя
	attack_range.body_entered.connect(_on_attack_range_body_entered)
	attack_range.body_exited.connect(_on_attack_range_body_exited)
	hit_box.area_entered.connect(_on_hit_box_area_entered)

func _input(event):
	if event.is_action_pressed("inventory") and inventory_node:
		inventory_node.visible = !inventory_node.visible
		can_move = not inventory_node.visible

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

	# Атака при нажатии кнопки, независимо от наличия врагов
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

	# Атака при нажатии кнопки, независимо от наличия врагов
	if Input.is_action_just_pressed("attack") and can_attack and not is_attacking:
		start_attack()
		return

func state_jump():
	anim_player.play("Jump")
	var dir = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	velocity.x = dir * move_speed
	if dir != 0:
		sprite.flip_h = dir > 0

	# Атака в прыжке
	if Input.is_action_just_pressed("attack") and can_attack and not is_attacking:
		start_attack()

	if is_on_floor():
		state = State.IDLE

# ----------------- Атака -----------------
func start_attack():
	if not can_attack or is_attacking:
		return
	
	can_attack = false
	is_attacking = true
	state = State.ATTACK
	velocity.x = 0
	anim_player.play("Attack")
	print("Игрок начинает атаку")
	
	# Ждем момент в анимации когда нужно нанести урон
	await get_tree().create_timer(0.2).timeout
	
	# Наносим урон всем врагам в зоне атаки
	apply_attack_damage()
	
	await anim_player.animation_finished
	await get_tree().create_timer(attack_cooldown).timeout
	
	state = State.IDLE
	is_attacking = false
	can_attack = true
	
	# Если в прыжке - возвращаемся в состояние прыжка
	if not is_on_floor():
		state = State.JUMP

# Функция нанесения урона
func apply_attack_damage():
	if enemies_in_attack_range.size() > 0:
		for enemy in enemies_in_attack_range:
			if is_instance_valid(enemy):
				print("Игрок атаковал врага! Урон: ", attack_damage)
				enemy.take_damage(attack_damage)
	else:
		print("Игрок атаковал, но врагов нет в зоне")

# ----------------- Система боя -----------------
func _on_attack_range_body_entered(body):
	if body.is_in_group("enemies"):
		if not enemies_in_attack_range.has(body):
			enemies_in_attack_range.append(body)
			print("Враг в зоне атаки. Всего врагов в зоне: ", enemies_in_attack_range.size())

func _on_attack_range_body_exited(body):
	if body.is_in_group("enemies"):
		enemies_in_attack_range.erase(body)
		print("Враг вышел из зоны атаки. Осталось врагов: ", enemies_in_attack_range.size())

func _on_hit_box_area_entered(area):
	if area.is_in_group("enemy_attack"):
		take_damage(area.damage)

# ----------------- Здоровье -----------------
func take_damage(damage: float) -> void:
	current_health -= damage
	current_health = max(0, current_health)
	emit_signal("health_changed", current_health, max_health)
	print("Игрок получил урон:", damage, " Текущее здоровье:", current_health)
	
	# Анимация получения урона
	if $AnimationPlayer.has_animation("hit_effect"):
		$AnimationPlayer.play("hit_effect")
	
	if current_health <= 0:
		die()

func heal(heal_amount: float) -> void:
	current_health += heal_amount
	current_health = min(current_health, max_health)
	emit_signal("health_changed", current_health, max_health)
	print("Игрок вылечен на:", heal_amount, " Текущее здоровье:", current_health)

func die() -> void:
	print("Игрок умер!")
	emit_signal("player_died")
	anim_player.play("Death")
	set_physics_process(false)
