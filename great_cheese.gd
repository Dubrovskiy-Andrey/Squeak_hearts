extends Area2D

@export var max_health: float = 1000.0
@export var current_health: float = 1000.0

signal health_changed(current, max)
signal destroyed

@onready var sprite: Sprite2D = $Sprite2D

var is_destroyed: bool = false

func _ready():
	print("🧀 Сыр создан!")
	
	# Применяем бонус HP от улучшения Salli
	if save_system:
		var cheese_level = save_system.get_npc_upgrade_level("salli_cheese_health")
		if cheese_level > 0:
			var bonus_hp = cheese_level * 200  # +200 HP за уровень
			max_health += bonus_hp
			current_health = max_health
			print("🧀 Бонус HP от Salli: +", bonus_hp, " HP. Теперь HP:", current_health, "/", max_health)
	
	print("🧀 Итоговое HP сыра: ", current_health, "/", max_health)
	
	# ТОЛЬКО ГРУППА, коллизии в инспекторе
	add_to_group("great_cheese")
	print("✅ Сыр добавлен в группу 'great_cheese'")
	
	# ПОДКЛЮЧАЕМ СИГНАЛЫ ДЛЯ СНАРЯДОВ
	area_entered.connect(_on_area_entered)
	
	# Проверяем что в группе
	print("🔍 Объектов в группе 'great_cheese':", get_tree().get_nodes_in_group("great_cheese").size())

# НОВЫЙ МЕТОД: обработка попадания снарядов
func _on_area_entered(area: Area2D):
	if is_destroyed:
		return
	
	print("🎯 Область вошла в сыр: ", area.name)
	print("🎯 Группы области: ", area.get_groups())
	
	# Проверяем, является ли это снарядом врага
	if area.is_in_group("enemy_projectiles"):
		print("🎯 Снаряд попал в сыр!")
		if area.has_method("get_damage"):
			var damage = area.get_damage()
			take_damage(damage)
		elif area.has_meta("damage"):
			var damage = area.get_meta("damage")
			take_damage(float(damage))
		else:
			# Урон по умолчанию
			take_damage(10.0)

func take_damage(damage: float):
	if is_destroyed:
		return
	
	current_health -= damage
	current_health = max(current_health, 0)
	
	print("🧀 Сыр получил урон:", damage, " HP:", current_health, "/", max_health)
	health_changed.emit(current_health, max_health)
	
	# Визуальный эффект
	if sprite:
		sprite.modulate = Color(1, 0.5, 0.5, 1)
		await get_tree().create_timer(0.1).timeout
		sprite.modulate = Color(1, 1, 1, 1)
	
	if current_health <= 0:
		destroy()

func destroy():
	if is_destroyed:
		print("⚠️ Сыр уже уничтожен, игнорируем повторный вызов")
		return
	
	is_destroyed = true
	print("💀 Сыр уничтожен! Начинаю процедуру завершения игры...")
	
	# 1. Отключаем коллизии и видимость
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	
	if sprite:
		sprite.modulate = Color(0.3, 0.3, 0.3, 0.5)
		sprite.scale = Vector2(0.8, 0.8)
	
	# 2. ГАРАНТИРОВАННО отправляем сигнал (ОДИН РАЗ)
	destroyed.emit()
	print("📢 Сигнал destroyed отправлен (единожды)")
	
	# 3. Ждем небольшую паузу для анимации
	await get_tree().create_timer(0.5).timeout
	
	# 4. НЕ вызываем немедленное завершение - только сигнал
	# Арена сама обработает завершение через подключенный сигнал
	print("✅ Сигнал отправлен, арена сама завершит игру")

func heal(amount: float):
	if is_destroyed:
		return
	
	current_health = min(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)
	print("🧀 Сыр исцелён на", amount, " HP:", current_health)

# Метод для получения урона извне
func get_damage() -> float:
	return 10.0  # или любое другое значение
