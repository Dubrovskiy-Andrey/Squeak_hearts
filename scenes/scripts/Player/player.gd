extends CharacterBody2D

signal health_changed(current_health, max_health)
signal player_died()
signal currency_changed(new_amount)
signal cheese_changed(cheese_states)
signal cheese_bite_added(cheese_index, new_state)
signal cheese_consumed(cheese_index)
signal super_attack_used()

enum State { IDLE, MOVE, JUMP, ATTACK, SUPER_JUMP, SUPER_LAND }

@export var move_speed: float = 250.0
@export var gravity: float = 800.0
@export var jump_force: float = -900.0
@export var super_jump_force: float = -1200.0
@export var attack_cooldown: float = 0.5
@export var super_attack_cooldown: float = 2.0
@export var max_health: float = 100.0
@export var attack_damage: int = 20
@export var super_attack_damage: int = 50
@export var inventory_path: NodePath = "../UserInterface/Inventory"
@export var hud_path: NodePath = "../UserInterface/HUD"

# Система сыра
@export var max_cheese: int = 3
var cheese_bites: Array = []  # 0-пустой, 1-маленький, 2-средний, 3-полный
var bites_per_cheese: int = 3
var current_hit_count: int = 0

var inventory_node: Node = null
var hud_node: Control = null
var state: State = State.IDLE
var can_attack: bool = true
var can_super_attack: bool = true
var is_attacking: bool = false
var can_move: bool = true
var current_health: float
var currency: int = 0

# Бонусы от талисманов
var talisman_hp_bonus: int = 0
var talisman_damage_bonus: int = 0
var talisman_speed_bonus: int = 0
var talisman_cooldown_bonus: int = 0
var talisman_cheese_bonus: int = 0

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var pickup_point: Node2D = $PickupPoint
@onready var attack_range: Area2D = $AttackRange
@onready var hit_box: Area2D = $HitBox
@onready var super_attack_area: Area2D = $SuperAttackArea

@export var health_bar_path: NodePath = "../UserInterface/HUD/HealthBar"
@export var currency_label_path: NodePath = "../UserInterface/HUD/CurrencyLabel"

var health_bar: TextureProgressBar
var currency_label: Label

var enemies_in_attack_range: Array = []
var enemies_in_super_range: Array = []
var stats_panel: Control = null

# Для супер-атаки
var is_super_jumping: bool = false
var original_gravity: float = 0

func _ready():
	add_to_group("players")
	load_saved_data()
	
	original_gravity = gravity
	_init_cheese()
	
	bites_per_cheese = max(1, 3 + talisman_cheese_bonus)
	print("Для полного сыра нужно ударов: ", bites_per_cheese)
	
	if health_bar_path and has_node(health_bar_path):
		health_bar = get_node(health_bar_path)
		health_bar.max_value = max_health + talisman_hp_bonus
		health_bar.value = current_health + talisman_hp_bonus
		
	if currency_label_path and has_node(currency_label_path):
		currency_label = get_node(currency_label_path)
		currency_label.text = str(currency)

	if hud_path and has_node(hud_path):
		hud_node = get_node(hud_path)

	emit_signal("health_changed", current_health + talisman_hp_bonus, max_health + talisman_hp_bonus)
	emit_signal("currency_changed", currency)
	emit_cheese_changed()

	if inventory_path and has_node(inventory_path):
		inventory_node = get_node(inventory_path)
		call_deferred("_ensure_stats_panel_found")

	# Подключаем сигналы подбора
	for child in get_children():
		if child is Area2D and child.name == "PickupZone":
			if child.body_entered.is_connected(_on_pickup_zone_body_entered):
				child.body_entered.disconnect(_on_pickup_zone_body_entered)
			child.body_entered.connect(_on_pickup_zone_body_entered)

	attack_range.body_entered.connect(Callable(self, "_on_attack_range_body_entered"))
	attack_range.body_exited.connect(Callable(self, "_on_attack_range_body_exited"))
	hit_box.area_entered.connect(Callable(self, "_on_hit_box_area_entered"))
	
	if super_attack_area:
		super_attack_area.body_entered.connect(Callable(self, "_on_super_attack_area_body_entered"))
		super_attack_area.body_exited.connect(Callable(self, "_on_super_attack_area_body_exited"))

func _init_cheese():
	cheese_bites.clear()
	# Начинаем с ПОЛНЫХ сыров (3 кусочка из 3)
	for i in range(max_cheese):
		cheese_bites.append(3)  # Полный сыр!
	
	current_hit_count = 0
	
	print("🧀 Инициализировано ", max_cheese, " полных сыров")

func emit_cheese_changed():
	var states = []
	for bites in cheese_bites:
		states.append(bites)
	cheese_changed.emit(states)

func load_saved_data():
	if save_system:
		var player_data = save_system.get_player_data()
		
		currency = player_data.get("currency", 0)
		current_health = player_data.get("health", max_health)
		max_health = player_data.get("max_health", max_health)
		attack_damage = player_data.get("damage", attack_damage)
		
		if player_data.has("cheese_bites") and player_data["cheese_bites"] is Array:
			cheese_bites = player_data["cheese_bites"].duplicate()
		else:
			_init_cheese()
		
		current_hit_count = player_data.get("current_hit_count", 0)
		
		if player_data.has("position_x") and player_data.has("position_y"):
			var pos = Vector2(player_data["position_x"], player_data["position_y"])
			if pos != Vector2.ZERO:
				global_position = pos
	else:
		current_health = max_health
		currency = 0
		_init_cheese()

func update_save_data():
	if save_system:
		save_system.update_player_data(self)

func apply_upgrade(health_bonus: int, damage_bonus: int, crystal_cost: int = 0, currency_cost: int = 0) -> bool:
	if currency_cost > 0 and currency < currency_cost:
		return false
	
	if crystal_cost > 0 and PlayerInventory.get_crystal_count() < crystal_cost:
		return false
	
	if currency_cost > 0:
		currency -= currency_cost
		emit_signal("currency_changed", currency)
	
	if crystal_cost > 0:
		PlayerInventory.spend_crystals(crystal_cost)
	
	max_health += health_bonus
	current_health += health_bonus
	attack_damage += damage_bonus
	
	if health_bar:
		health_bar.max_value = max_health + talisman_hp_bonus
		health_bar.value = current_health + talisman_hp_bonus
	
	if currency_label:
		currency_label.text = str(currency)
	
	update_save_data()
	_refresh_inventory_stats()
	emit_signal("health_changed", current_health + talisman_hp_bonus, max_health + talisman_hp_bonus)
	return true

func _ensure_stats_panel_found():
	if inventory_node:
		stats_panel = inventory_node.get_node_or_null("StatsPanel")

func _input(event):
	if event.is_action_pressed("inventory") and inventory_node:
		inventory_node.visible = not inventory_node.visible
		can_move = not inventory_node.visible
		
		if hud_node:
			hud_node.visible = not inventory_node.visible
		
		if inventory_node.visible:
			_refresh_inventory_stats()
	
	if event.is_action_pressed("super_attack") and can_super_attack and not is_super_jumping and can_move:
		try_super_attack()
	
	# Сохранение без восстановления (одиночный ESC)
	if event.is_action_pressed("ui_cancel"):
		save_without_restore()
	
	# Выход в меню (Ctrl + ESC)
	if event.is_action_pressed("ui_cancel") and (Input.is_key_pressed(KEY_SHIFT) or Input.is_key_pressed(KEY_SHIFT)):
		return_to_main_menu()
		get_viewport().set_input_as_handled()  # Обрабатываем событие чтобы не вызывалось дважды

func save_without_restore():
	if save_system:
		print("💾 Сохранение игры (без восстановления)...")
		save_system.save_game(self)
		_show_notification("Игра сохранена!")
	else:
		print("❌ SaveSystem не найден!")

func _physics_process(delta: float):
	if not can_move or is_super_jumping:
		move_and_slide()
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
		State.SUPER_JUMP: _state_super_jump(delta)
		State.SUPER_LAND: _state_super_land(delta)
	
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

func _state_super_jump(delta: float):
	velocity.y += gravity * delta
	anim_player.play("Jump")

func _state_super_land(delta: float):
	velocity.y += gravity * delta * 3.0  # Ускоренное падение
	anim_player.play("Jump")

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
	
	var actual_cooldown = attack_cooldown
	if talisman_cooldown_bonus > 0:
		actual_cooldown = attack_cooldown * (1.0 - talisman_cooldown_bonus / 100.0)
		actual_cooldown = max(actual_cooldown, 0.1)
	
	await get_tree().create_timer(actual_cooldown).timeout
	
	is_attacking = false
	can_attack = true
	
	if not is_on_floor():
		state = State.JUMP
	else:
		state = State.IDLE

func _apply_attack_damage():
	var total_damage = attack_damage + talisman_damage_bonus
	var hit_landed = false
	
	for enemy in enemies_in_attack_range:
		if is_instance_valid(enemy) and enemy.has_method("take_damage"):
			enemy.take_damage(total_damage)
			hit_landed = true
	
	if hit_landed:
		add_cheese_bite()

func _on_attack_range_body_entered(body):
	if body.is_in_group("enemies") and not enemies_in_attack_range.has(body):
		enemies_in_attack_range.append(body)

func _on_attack_range_body_exited(body):
	if body.is_in_group("enemies"):
		enemies_in_attack_range.erase(body)

func _on_super_attack_area_body_entered(body):
	if body.is_in_group("enemies") and not enemies_in_super_range.has(body):
		enemies_in_super_range.append(body)

func _on_super_attack_area_body_exited(body):
	if body.is_in_group("enemies"):
		enemies_in_super_range.erase(body)

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

func _auto_pick_item(item):
	if not is_instance_valid(item):
		return
	
	if item.item_name == "Trash":
		currency += 1000
		
		if currency_label:
			currency_label.text = str(currency)
		
		if save_system:
			save_system.add_currency(1000)
		
		emit_signal("currency_changed", currency)
		_refresh_inventory_stats()
	elif item.item_name == "Crystal":
		_auto_pick_crystal(item)
	else:
		PlayerInventory.add_item(item.item_name, item.item_quantity)
		_refresh_inventory_stats()
	item.queue_free()

func _auto_pick_crystal(crystal):
	if not is_instance_valid(crystal):
		return
	
	PlayerInventory.add_item("Crystal", 10)
	_show_pickup_notification("Кристалл +1")
	
	_refresh_inventory_stats()
	crystal.queue_free()

func _show_pickup_notification(text: String):
	var notification = Label.new()
	notification.text = text
	notification.position = global_position + Vector2(0, -50)
	get_parent().add_child(notification)
	
	var tween = create_tween()
	tween.tween_property(notification, "position:y", notification.position.y - 30, 0.5)
	tween.parallel().tween_property(notification, "modulate:a", 0, 0.5)
	
	await get_tree().create_timer(1.0).timeout
	notification.queue_free()

func _show_notification(text: String):
	var notification = Label.new()
	notification.text = text
	notification.position = global_position + Vector2(0, -80)
	get_parent().add_child(notification)
	
	notification.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
	notification.add_theme_font_size_override("font_size", 16)
	
	var tween = create_tween()
	tween.tween_property(notification, "position:y", notification.position.y - 30, 0.5)
	tween.parallel().tween_property(notification, "modulate:a", 0, 0.8)
	
	await get_tree().create_timer(1.0).timeout
	notification.queue_free()

func _refresh_inventory_stats():
	if stats_panel:
		stats_panel.refresh_stats()

func take_damage(damage: float) -> void:
	current_health = max(current_health - damage, 0)
	
	var total_current = current_health + talisman_hp_bonus
	var total_max = max_health + talisman_hp_bonus
	
	if health_bar:
		health_bar.value = total_current
	
	emit_signal("health_changed", total_current, total_max)
	
	if anim_player.has_animation("hit_effect"):
		anim_player.play("hit_effect")
	
	if current_health <= 0:
		die()
	
	_refresh_inventory_stats()

func heal(amount: float) -> void:
	current_health = min(current_health + amount, max_health)
	
	var total_current = current_health + talisman_hp_bonus
	var total_max = max_health + talisman_hp_bonus
	
	if health_bar:
		health_bar.value = total_current
	
	emit_signal("health_changed", total_current, total_max)
	
	_refresh_inventory_stats()

func die() -> void:
	emit_signal("player_died")
	anim_player.play("Death")
	set_physics_process(false)
	await get_tree().create_timer(1.0).timeout
	get_tree().reload_current_scene()

# =================================================
# СИСТЕМА СЫРА
# =================================================

func add_cheese_bite():
	if cheese_bites.size() == 0:
		return
	
	# Ищем самый правый неполный сыр (с конца массива)
	var cheese_to_fill = -1
	
	for i in range(cheese_bites.size() - 1, -1, -1):
		if cheese_bites[i] < 3:  # Нашли неполный сыр
			cheese_to_fill = i
			break
	
	# Если все сыры полные
	if cheese_to_fill == -1:
		print("Все сыры полные!")
		return
	
	# Увеличиваем счетчик ударов
	current_hit_count += 1
	
	# Рассчитываем новое состояние сыра
	var hits_needed = bites_per_cheese
	var progress = float(current_hit_count) / float(hits_needed)
	
	# Определяем состояние сыра:
	var new_state = 0
	if progress >= 1.0:
		new_state = 3  # полный
	elif progress >= 2.0/3.0:
		new_state = 2  # средний
	elif progress >= 1.0/3.0:
		new_state = 1  # маленький
	
	
	# Обновляем состояние сыра
	if new_state != cheese_bites[cheese_to_fill]:
		cheese_bites[cheese_to_fill] = new_state
		cheese_bite_added.emit(cheese_to_fill, new_state)
	
	# Если сыр стал полным
	if new_state == 3:
		print("🎉 Сыр ", cheese_to_fill, " стал полным!")
		current_hit_count = 0  # Сбрасываем счетчик для следующего сыра
	
	emit_cheese_changed()

func consume_cheese() -> bool:
	# Ищем самый правый полный сыр (с конца массива)
	for i in range(cheese_bites.size() - 1, -1, -1):
		if cheese_bites[i] == 3:  # Если сыр полный
			cheese_bites[i] = 0  # Обнуляем сыр
			current_hit_count = 0  # Сбрасываем счетчик ударов
			
			cheese_consumed.emit(i)
			emit_cheese_changed()
			print("🧀 Потрачен правый сыр ", i)
			return true
	return false

func restore_all_cheese():
	for i in range(cheese_bites.size()):
		cheese_bites[i] = 3  # Делаем все сыры полными
	
	current_hit_count = 0
	
	emit_cheese_changed()
	print("🧀 Все сыры восстановлены!")

func get_full_cheese_count() -> int:
	var count = 0
	for bites in cheese_bites:
		if bites == 3:
			count += 1
	return count

func has_full_cheese() -> bool:
	for bites in cheese_bites:
		if bites == 3:
			return true
	return false

func get_cheese_state(index: int) -> int:
	if index >= 0 and index < cheese_bites.size():
		return cheese_bites[index]
	return 0

func update_cheese_bonus():
	bites_per_cheese = max(1, 3 + talisman_cheese_bonus)
	print("Для полного сыра теперь нужно ударов: ", bites_per_cheese)

# =================================================
# СУПЕР-АТАКА
# =================================================

func try_super_attack():
	if not has_full_cheese():
		print("❌ Недостаточно сыра для супер-удара!")
		return
	
	if not can_super_attack or is_super_jumping:
		return
	
	print("💥 Запускаем супер-атаку...")
	
	# Тратим самый правый полный сыр
	if consume_cheese():
		start_super_jump()
	else:
		print("❌ Не удалось использовать сыр для супер-удара")

func start_super_jump():
	can_super_attack = false
	is_super_jumping = true
	state = State.SUPER_JUMP
	can_move = false
	can_attack = false
	
	print("🔼 Супер-прыжок!")
	
	# Прыжок вверх
	velocity.y = super_jump_force
	velocity.x = 0
	
	# Визуальный эффект
	anim_player.play("Jump")
	sprite.modulate = Color(1, 0.8, 0.5, 1)  # Золотистый
	
	# Ждем достижения пика прыжка (примерно 0.4 секунды)
	await get_tree().create_timer(0.4).timeout
	
	print("🔽 Начинаем быстрое падение...")
	state = State.SUPER_LAND
	
	# Увеличиваем гравитацию для быстрого падения
	var fast_fall_gravity = original_gravity * 3.0
	
	# Быстрое падение
	var fall_timer = 0.0
	var max_fall_time = 1.5  # Максимальное время падения
	
	while not is_on_floor() and fall_timer < max_fall_time:
		velocity.y += fast_fall_gravity * get_physics_process_delta_time()
		fall_timer += get_physics_process_delta_time()
		await get_tree().physics_frame
	
	# Удар при приземлении
	print("💥 Удар при приземлении!")
	
	# Восстанавливаем нормальную гравитацию
	gravity = original_gravity
	
	# Наносим урон
	_apply_super_attack_damage()
	
	# Анимация удара
	anim_player.play("Attack")
	sprite.modulate = Color(1, 0.5, 0.5, 1)  # Красный
	
	await get_tree().create_timer(0.2).timeout
	
	# Возвращаем нормальный цвет
	sprite.modulate = Color(1, 1, 1, 1)
	
	# Ждем окончания анимации
	await get_tree().create_timer(0.3).timeout
	
	print("✅ Супер-атака завершена!")
	
	# Восстанавливаем управление
	is_super_jumping = false
	can_move = true
	can_attack = true
	state = State.IDLE
	
	emit_signal("super_attack_used")
	
	# КД супер-атаки
	await get_tree().create_timer(super_attack_cooldown).timeout
	can_super_attack = true

func _apply_super_attack_damage():
	var total_damage = super_attack_damage + talisman_damage_bonus
	
	print("💥 Супер-удар! Урон: ", total_damage)
	
	# Урон всем врагам в области супер-атаки
	var damaged_enemies = 0
	for enemy in enemies_in_super_range:
		if is_instance_valid(enemy) and enemy.has_method("take_damage"):
			enemy.take_damage(total_damage)
			damaged_enemies += 1
	
	# Также урон врагам в обычной области атаки
	for enemy in enemies_in_attack_range:
		if is_instance_valid(enemy) and enemy.has_method("take_damage") and not enemies_in_super_range.has(enemy):
			enemy.take_damage(total_damage)
			damaged_enemies += 1
	
	if damaged_enemies > 0:
		print("🎯 Поражено врагов: ", damaged_enemies)

# =================================================
# ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
# =================================================

func get_player_health() -> String:
	var total_hp = max_health + talisman_hp_bonus
	var total_current = current_health + talisman_hp_bonus
	return str(int(total_current)) + "/" + str(int(total_hp))

func get_player_damage() -> int:
	return attack_damage + talisman_damage_bonus

func get_player_currency() -> int:
	return currency

func return_to_main_menu():
	print("🚪 Возврат в главное меню...")
	save_without_restore()
	await get_tree().create_timer(0.3).timeout
	get_tree().change_scene_to_file("res://scenes/menu/menu.tscn")

func quick_save():
	save_without_restore()

func set_can_move(value: bool):
	can_move = value
	if not can_move:
		velocity = Vector2.ZERO
		state = State.IDLE
		anim_player.play("Idle")
	print("Движение игрока:", "разблокировано" if value else "заблокировано")
