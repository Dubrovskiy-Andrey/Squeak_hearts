extends CharacterBody2D

signal health_changed(current_health, max_health)
signal player_died()
signal currency_changed(new_amount)

enum State { IDLE, MOVE, JUMP, ATTACK }

@export var move_speed: float = 250.0
@export var gravity: float = 800.0
@export var jump_force: float = -900.0
@export var attack_cooldown: float = 0.5
@export var max_health: float = 100.0
@export var attack_damage: int = 20
@export var inventory_path: NodePath = "../UserInterface/Inventory"
@export var hud_path: NodePath = "../UserInterface/HUD"

var inventory_node: Node = null
var hud_node: Control = null
var state: State = State.IDLE
var can_attack: bool = true
var is_attacking: bool = false
var can_move: bool = true
var current_health: float
var currency: int = 0

# Бонусы от талисманов
var talisman_hp_bonus: int = 0
var talisman_damage_bonus: int = 0
var talisman_speed_bonus: int = 0

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
var stats_panel: Control = null

func _ready():
	add_to_group("players")
	load_saved_data()
	
	if health_bar_path and has_node(health_bar_path):
		health_bar = get_node(health_bar_path)
		health_bar.max_value = max_health
		health_bar.value = current_health
		
	if currency_label_path and has_node(currency_label_path):
		currency_label = get_node(currency_label_path)
		currency_label.text = str(currency)

	if hud_path and has_node(hud_path):
		hud_node = get_node(hud_path)

	# Отправляем начальные сигналы с учетом бонусов талисманов
	var total_current = current_health + talisman_hp_bonus
	var total_max = max_health + talisman_hp_bonus
	emit_signal("health_changed", total_current, total_max)
	emit_signal("currency_changed", currency)

	if inventory_path and has_node(inventory_path):
		inventory_node = get_node(inventory_path)
		call_deferred("_ensure_stats_panel_found")

	_connect_pickup_signals()

	attack_range.body_entered.connect(Callable(self, "_on_attack_range_body_entered"))
	attack_range.body_exited.connect(Callable(self, "_on_attack_range_body_exited"))
	hit_box.area_entered.connect(Callable(self, "_on_hit_box_area_entered"))

func load_saved_data():
	if save_system:
		var player_data = save_system.get_player_data()
		
		if "currency" in player_data:
			currency = player_data["currency"]
		else:
			currency = 0
		
		if "health" in player_data:
			current_health = player_data["health"]
		else:
			current_health = max_health
		
		if "max_health" in player_data:
			max_health = player_data["max_health"]
		
		if "damage" in player_data:
			attack_damage = player_data["damage"]
		
		if "position_x" in player_data and "position_y" in player_data:
			var saved_position = Vector2(player_data["position_x"], player_data["position_y"])
			if saved_position != Vector2.ZERO:
				global_position = saved_position
	else:
		current_health = max_health
		currency = 0

func update_save_data():
	if save_system:
		save_system.update_player_data(self)

func apply_upgrade(health_bonus: int, damage_bonus: int, cost: int) -> bool:
	if currency >= cost:
		currency -= cost
		max_health += health_bonus
		current_health += health_bonus
		attack_damage += damage_bonus
		
		if health_bar:
			health_bar.max_value = max_health
			health_bar.value = current_health
		
		if currency_label:
			currency_label.text = str(currency)
		
		# Отправляем сигналы с учетом бонусов талисманов
		var total_current = current_health + talisman_hp_bonus
		var total_max = max_health + talisman_hp_bonus
		emit_signal("health_changed", total_current, total_max)
		emit_signal("currency_changed", currency)
		
		update_save_data()
		
		return true
	else:
		return false

func _ensure_stats_panel_found():
	if inventory_node:
		stats_panel = inventory_node.get_node_or_null("StatsPanel")
		if stats_panel:
			print("StatsPanel найден:", stats_panel.name)

func _connect_pickup_signals():
	for child in get_children():
		if child is Area2D and child.name == "PickupZone":
			if child.body_entered.is_connected(Callable(self, "_on_pickup_zone_body_entered")):
				child.body_entered.disconnect(Callable(self, "_on_pickup_zone_body_entered"))
			child.body_entered.connect(Callable(self, "_on_pickup_zone_body_entered"))
			return

# В функции _input обновите вызов save_game:
func _input(event):
	if event.is_action_pressed("inventory") and inventory_node:
		inventory_node.visible = not inventory_node.visible
		can_move = not inventory_node.visible

		if hud_node:
			hud_node.visible = not inventory_node.visible

		if inventory_node.visible:
			_refresh_inventory_stats()
	
	if event.is_action_pressed("ui_select") and save_system:
		# Используем только 2 аргумента
		save_system.save_game(self)
	
	if event.is_action_pressed("ui_cancel"):
		return_to_main_menu()

func _physics_process(delta: float):
	if not can_move:
		anim_player.play("Idle")
		velocity = Vector2.ZERO
		return

	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	match state:
		State.IDLE: _state_idle()
		State.MOVE: _state_move()
		State.JUMP: _state_jump()
		State.ATTACK: pass

	move_and_slide()

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
	var speed_multiplier = 1.0 + (talisman_speed_bonus / 100.0)
	velocity.x = dir * move_speed * speed_multiplier
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
	var speed_multiplier = 1.0 + (talisman_speed_bonus / 100.0)
	velocity.x = dir * move_speed * speed_multiplier
	if dir != 0:
		sprite.flip_h = dir > 0

	if Input.is_action_just_pressed("attack") and can_attack and not is_attacking:
		start_attack()

	if is_on_floor():
		state = State.IDLE

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
	var total_damage = attack_damage + talisman_damage_bonus
	for enemy in enemies_in_attack_range:
		if is_instance_valid(enemy) and enemy.has_method("take_damage"):
			enemy.take_damage(total_damage)

func _on_attack_range_body_entered(body):
	if body.is_in_group("enemies") and not enemies_in_attack_range.has(body):
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

func _on_pickup_zone_body_entered(body):
	if body.is_in_group("item_drop") and body.has_method("pick_up_item"):
		body.pick_up_item(self)
	if body.is_in_group("crystals") and body.has_method("pick_up"):
		body.pick_up(self)

func take_damage(damage: float) -> void:
	current_health = max(current_health - damage, 0)
	if health_bar:
		health_bar.value = current_health
	
	# Отправляем сигнал с учетом бонусов талисманов
	var total_current = current_health + talisman_hp_bonus
	var total_max = max_health + talisman_hp_bonus
	emit_signal("health_changed", total_current, total_max)
	
	if anim_player.has_animation("hit_effect"):
		anim_player.play("hit_effect")
	
	if current_health <= 0:
		die()
	
	_refresh_inventory_stats()

func heal(amount: float) -> void:
	current_health = min(current_health + amount, max_health)
	if health_bar:
		health_bar.value = current_health
	
	# Отправляем сигнал с учетом бонусов талисманов
	var total_current = current_health + talisman_hp_bonus
	var total_max = max_health + talisman_hp_bonus
	emit_signal("health_changed", total_current, total_max)
	
	_refresh_inventory_stats()

func die() -> void:
	emit_signal("player_died")
	anim_player.play("Death")
	set_physics_process(false)
	await get_tree().create_timer(1.0).timeout
	get_tree().reload_current_scene()

func _auto_pick_item(item):
	if not is_instance_valid(item):
		return
	
	if item.item_name == "Trash":
		currency += 10
		
		if currency_label:
			currency_label.text = str(currency)
		
		if save_system:
			save_system.add_currency(10)
		
		emit_signal("currency_changed", currency)
		_refresh_inventory_stats()
		
		print("Подобрана валюта: +10, всего: ", currency)
	elif item.item_name == "Crystal":
		_auto_pick_crystal(item)
		return
	
	_refresh_inventory_stats()
	item.queue_free()

func _auto_pick_crystal(crystal):
	if not is_instance_valid(crystal):
		return
	
	if inventory_node and inventory_node.has_method("add_item"):
		inventory_node.add_item("Crystal", 1)
		_show_pickup_notification("Кристалл +1")
	else:
		print("Ошибка: инвентарь не найден!")
	
	_refresh_inventory_stats()
	crystal.queue_free()

func _show_pickup_notification(text: String):
	var notification = Label.new()
	notification.text = text
	notification.modulate = Color(1, 1, 1, 1)
	notification.position = Vector2(global_position.x, global_position.y - 50)
	get_parent().add_child(notification)
	
	var tween = create_tween()
	tween.tween_property(notification, "position:y", notification.position.y - 30, 0.5)
	tween.parallel().tween_property(notification, "modulate:a", 0, 0.5)
	
	await get_tree().create_timer(1.0).timeout
	notification.queue_free()

func _refresh_inventory_stats():
	if stats_panel:
		stats_panel.refresh_stats()

func get_player_health() -> String:
	var total_hp = max_health + talisman_hp_bonus
	var total_current = current_health + talisman_hp_bonus
	return str(int(total_current)) + "/" + str(int(total_hp))

func get_player_damage() -> int:
	return attack_damage + talisman_damage_bonus

func get_player_currency() -> int:
	return currency

func return_to_main_menu():
	if save_system:
		save_system.save_game(self)
	await get_tree().create_timer(0.3).timeout
	get_tree().change_scene_to_file("res://scenes/menu/menu.tscn")

func quick_save():
	if save_system:
		save_system.save_game(self)
