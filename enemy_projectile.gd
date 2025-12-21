extends Area2D

# Экспортируемые параметры
@export var speed: float = 300.0
@export var damage: float = 15.0
@export var max_distance: float = 600.0
@export var lifetime: float = 3.0

# Переменные
var velocity: Vector2 = Vector2.ZERO
var direction: Vector2 = Vector2.RIGHT
var distance_traveled: float = 0.0
var is_active: bool = true
var has_hit: bool = false  # Флаг: уже попал в цель

# Ноды
@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var despawn_timer: Timer = $Timer if has_node("Timer") else null

func _ready():
	# Настраиваем таймер деспавна
	if despawn_timer:
		despawn_timer.wait_time = lifetime
		despawn_timer.timeout.connect(_on_despawn_timer_timeout)
		despawn_timer.start()
	
	# Подключаем сигналы
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	# Добавляем в группу снарядов врага
	add_to_group("enemy_projectiles")
	
	# Устанавливаем метаданные с уроном
	set_meta("damage", damage)

func setup(projectile_direction: Vector2, projectile_speed: float = speed, projectile_damage: float = damage):
	direction = projectile_direction.normalized()
	velocity = direction * projectile_speed
	damage = projectile_damage
	
	# Обновляем метаданные
	set_meta("damage", damage)
	
	# Поворачиваем спрайт
	if sprite:
		sprite.rotation = velocity.angle()
	elif animated_sprite:
		animated_sprite.rotation = velocity.angle()

func _physics_process(delta):
	if not is_active:
		return
	
	# Двигаем снаряд
	var movement = velocity * delta
	position += movement
	
	# Считаем пройденную дистанцию
	distance_traveled += movement.length()
	
	# Проверяем максимальную дистанцию
	if distance_traveled >= max_distance:
		destroy()
		return

func _on_body_entered(body):
	if not is_active or has_hit:
		return
	
	print("🎯 Снаряд столкнулся с телом: ", body.name, " | Группы: ", body.get_groups())
	
	# Проверяем, является ли тело игроком или сыром
	if body.is_in_group("players") or body.is_in_group("great_cheese"):
		# Наносим урон цели
		if body.has_method("take_damage"):
			body.take_damage(damage)
			print("✅ Снаряд нанёс урон ", body.name, " (урон: ", damage, ")")
		else:
			print("❌ У тела ", body.name, " нет метода take_damage")
		
		# Помечаем, что уже попали
		has_hit = true
		destroy()
		return
	
	# Проверяем столкновение со стенами
	if body.is_in_group("environment") or body.is_in_group("walls") or body.is_in_group("terrain"):
		print("🧱 Снаряд попал в стену")
		destroy()

func _on_area_entered(area):
	if not is_active or has_hit:
		return
	
	print("🎯 Снаряд столкнулся с областью: ", area.name, " | Группы: ", area.get_groups())
	
	# Проверяем, является ли область сыром
	if area.is_in_group("great_cheese"):
		print("🎯 Обнаружен сыр (Area2D)!")
		if area.has_method("take_damage"):
			area.take_damage(damage)
			print("✅ Снаряд нанёс урон сыру через область (урон: ", damage, ")")
		else:
			print("❌ У области сыра нет метода take_damage")
		
		# Помечаем, что уже попали
		has_hit = true
		destroy()
		return
	
	# Проверяем, является ли область HitBox игрока
	if area.is_in_group("player_hitbox") or area.is_in_group("player_attack"):
		var parent = area.get_parent()
		print("🎯 Родитель области: ", parent.name if parent else "нет")
		if parent and parent.has_method("take_damage"):
			parent.take_damage(damage)
			print("✅ Снаряд нанёс урон через область ", parent.name, " (урон: ", damage, ")")
		else:
			print("❌ У родителя области нет метода take_damage")
		
		# Помечаем, что уже попали
		has_hit = true
		destroy()
		return
	
	# Проверяем другие объекты
	if area.is_in_group("item") or area.is_in_group("collectible"):
		print("📦 Снаряд попал в предмет")
		destroy()

# Метод для получения урона извне
func get_damage() -> float:
	return damage

func destroy():
	if not is_active:
		return
	
	print("💥 Снаряд уничтожен")
	is_active = false
	
	# Немедленно отключаем коллизии
	collision_shape.set_deferred("disabled", true)
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	
	queue_free()

func _on_despawn_timer_timeout():
	if is_active:
		print("⏰ Снаряд самоуничтожился по таймеру")
		destroy()

# Методы для настройки извне
func set_damage(new_damage: float):
	damage = new_damage
	set_meta("damage", new_damage)

func set_speed(new_speed: float):
	speed = new_speed
	if velocity != Vector2.ZERO:
		velocity = velocity.normalized() * new_speed
