extends CharacterBody2D

signal health_changed(current_health, max_health)
signal player_died()

enum State { IDLE, MOVE, JUMP, ATTACK }

@export var move_speed: float = 250.0
@export var gravity: float = 800.0
@export var jump_force: float = -900.0
@export var attack_cooldown: float = 0.5
@export var max_health: float = 100.0
@export var attack_damage: int = 20
@export var inventory_path = "../UserInterface/Inventory" # при необходимости

var inventory_node: Node = null
var state: State = State.IDLE
var can_attack: bool = true
var is_attacking: bool = false
var can_move: bool = true
var current_health: float
var currency: int = 0

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var pickup_point: Node2D = $PickupPoint
@onready var attack_range: Area2D = $AttackRange
@onready var hit_box: Area2D = $HitBox
@export var health_bar_path: NodePath = "../UserInterface/HUD/HealthBar"
@export var currency_label_path: NodePath = "../UserInterface/HUD/CurrencyLabel"
var health_bar: TextureProgressBar
var currency_label: Label

var enemies_in_attack_range: Array = []

func _ready():
	add_to_group("players")
	current_health = max_health
	
	if health_bar_path and has_node(health_bar_path):
		health_bar = get_node(health_bar_path)
		health_bar.max_value = max_health
		health_bar.value = current_health
		
	if currency_label_path and has_node(currency_label_path):
		currency_label = get_node(currency_label_path)
		currency_label.text = str(currency)

	emit_signal("health_changed", current_health, max_health)

	if inventory_path and has_node(inventory_path):
		inventory_node = get_node(inventory_path)

	# Сигналы
	attack_range.body_entered.connect(Callable(self, "_on_attack_range_body_entered"))
	attack_range.body_exited.connect(Callable(self, "_on_attack_range_body_exited"))
	hit_box.area_entered.connect(Callable(self, "_on_hit_box_area_entered"))

func _input(event):
	if event.is_action_pressed("inventory") and inventory_node:
		inventory_node.visible = not inventory_node.visible
		can_move = not inventory_node.visible

func _physics_process(delta: float):
	if not can_move:
		anim_player.play("Idle")
		velocity = Vector2.ZERO
		return

	# Гравитация
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	match state:
		State.IDLE:
			_state_idle()
		State.MOVE:
			_state_move()
		State.JUMP:
			_state_jump()
		State.ATTACK:
			pass  # управление через start_attack

	move_and_slide()

# ---------- состояния ----------
func _state_idle():
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

func _state_move():
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

func _state_jump():
	anim_player.play("Jump")
	var dir = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	velocity.x = dir * move_speed
	if dir != 0:
		sprite.flip_h = dir > 0

	if Input.is_action_just_pressed("attack") and can_attack and not is_attacking:
		start_attack()

	if is_on_floor():
		state = State.IDLE

# ---------- атака ----------
func start_attack() -> void:
	if not can_attack or is_attacking:
		return
	can_attack = false
	is_attacking = true
	state = State.ATTACK
	velocity.x = 0
	anim_player.play("Attack")

	await get_tree().create_timer(0.18).timeout
	_apply_attack_damage()

	await anim_player.animation_finished
	await get_tree().create_timer(attack_cooldown).timeout

	is_attacking = false
	can_attack = true
	if not is_on_floor():
		state = State.JUMP
	else:
		state = State.IDLE

func _apply_attack_damage():
	for enemy in enemies_in_attack_range:
		if is_instance_valid(enemy) and enemy.has_method("take_damage"):
			enemy.take_damage(attack_damage)
			print("Игрок нанес урон:", attack_damage, " врагу:", enemy)

# ---------- зоны ----------
func _on_attack_range_body_entered(body):
	if body.is_in_group("enemies"):
		if not enemies_in_attack_range.has(body):
			enemies_in_attack_range.append(body)

func _on_attack_range_body_exited(body):
	if body.is_in_group("enemies"):
		enemies_in_attack_range.erase(body)

func _on_hit_box_area_entered(area):
	if area.is_in_group("enemy_attack"):
		if area.has_meta("damage"):
			take_damage(float(area.get_meta("damage")))
		else:
			take_damage(20.0)

# ---------- здоровье ----------
func take_damage(damage: float) -> void:
	current_health -= damage
	current_health = max(current_health, 0)
	if health_bar:
		health_bar.value = current_health
	emit_signal("health_changed", current_health, max_health)
	print("Игрок получил урон:", damage, " HP:", current_health)
	if anim_player.has_animation("hit_effect"):
		anim_player.play("hit_effect")
	if current_health <= 0:
		die()

func heal(amount: float) -> void:
	current_health = min(current_health + amount, max_health)
	if health_bar:
		health_bar.value = current_health
	emit_signal("health_changed", current_health, max_health)

# ---------- смерть ----------
func die() -> void:
	print("Игрок умер")
	emit_signal("player_died")
	anim_player.play("Death")
	set_physics_process(false)
	await get_tree().create_timer(1.0).timeout
	get_tree().reload_current_scene()

# ---------- автоматический подбор предметов ----------
func _auto_pick_item(item):
	if not is_instance_valid(item):
		return

	if item.item_name == "Trash":
		currency += 10
		if currency_label:
			currency_label.text = str(currency)
		print("Подобран Trash! Валюта:", currency)

	# Тут можно добавить добавление предмета в инвентарь
	# PlayerInventory.add_item(item.item_name, 1)

	item.queue_free()
