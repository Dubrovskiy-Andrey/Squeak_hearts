extends Area2D

@export var max_health: float = 1000.0
@export var current_health: float = 1000.0

signal health_changed(current, max)
signal destroyed

@onready var sprite: Sprite2D = $Sprite2D

var is_destroyed: bool = false  # Флаг для предотвращения повторного уничтожения

func _ready():
	print("🧀 Сыр создан! HP:", current_health, "/", max_health)
	
	# ТОЛЬКО ГРУППА, коллизии в инспекторе
	add_to_group("great_cheese")
	print("✅ Сыр добавлен в группу 'great_cheese'")
	
	# Проверяем что в группе
	print("🔍 Объектов в группе 'great_cheese':", get_tree().get_nodes_in_group("great_cheese").size())

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
