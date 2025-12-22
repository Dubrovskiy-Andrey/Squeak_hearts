extends Node

class_name WaveManager

# Сигналы
signal wave_started(wave_num, wave_data)
signal wave_completed(wave_num)
signal enemy_spawned(enemy)
signal all_enemies_defeated()
signal total_waves_updated(total)
signal boss_spawned(boss_enemy)

# Экспортные переменные
@export var spawn_points: Array[NodePath] = []
@export var enemy_scenes: Dictionary = {
	"BasicCat": preload("res://scenes/NPC/enemy.tscn"),
	"ArcherCat": preload("res://scenes/NPC/enemy_ranged.tscn"),
	"BossCat": preload("res://scenes/NPC/boss_enemy.tscn")  # Добавили босса
}
@export var wave_delay_between: float = 5.0  # Задержка между волнами

# Конфигурация волн для разных сложностей
var wave_configs = {
	"kitten": [  # 8 волн для "Котёнка"
		{"delay": 3.0, "enemies": [{"type": "BasicCat", "count": 3}], "name": "Волна 1", "reward": {"trash": 100}},
		{"delay": 2.5, "enemies": [{"type": "BasicCat", "count": 4}, {"type": "ArcherCat", "count": 1}], "name": "Волна 2", "reward": {"trash": 120}},
		{"delay": 2.0, "enemies": [{"type": "BasicCat", "count": 3}, {"type": "ArcherCat", "count": 2}], "name": "Волна 3", "reward": {"trash": 140}},
		{"delay": 1.8, "enemies": [{"type": "BasicCat", "count": 5}, {"type": "ArcherCat", "count": 2}], "name": "Волна 4", "reward": {"trash": 160}},
		{"delay": 1.6, "enemies": [{"type": "BasicCat", "count": 4}, {"type": "ArcherCat", "count": 3}], "name": "Волна 5", "reward": {"trash": 180}},
		{"delay": 1.4, "enemies": [{"type": "BasicCat", "count": 6}, {"type": "ArcherCat", "count": 3}], "name": "Волна 6", "reward": {"trash": 200}},
		{"delay": 1.2, "enemies": [{"type": "BasicCat", "count": 5}, {"type": "ArcherCat", "count": 4}], "name": "Волна 7", "reward": {"trash": 220}},
		{"delay": 1.0, "enemies": [{"type": "BossCat", "count": 1}], "name": "ФИНАЛЬНЫЙ БОСС", "reward": {"trash": 500, "crystals": 3}}
	],
	"cat": [  # 10 волн для "Кота"
		{"delay": 2.8, "enemies": [{"type": "BasicCat", "count": 3}, {"type": "ArcherCat", "count": 1}], "name": "Волна 1", "reward": {"trash": 110}},
		{"delay": 2.3, "enemies": [{"type": "BasicCat", "count": 4}, {"type": "ArcherCat", "count": 1}], "name": "Волна 2", "reward": {"trash": 130}},
		{"delay": 1.8, "enemies": [{"type": "BasicCat", "count": 5}, {"type": "ArcherCat", "count": 2}], "name": "Волна 3", "reward": {"trash": 150}},
		{"delay": 1.6, "enemies": [{"type": "BasicCat", "count": 4}, {"type": "ArcherCat", "count": 3}], "name": "Волна 4", "reward": {"trash": 170}},
		{"delay": 1.4, "enemies": [{"type": "BasicCat", "count": 6}, {"type": "ArcherCat", "count": 3}], "name": "Волна 5", "reward": {"trash": 190}},
		{"delay": 1.2, "enemies": [{"type": "BasicCat", "count": 5}, {"type": "ArcherCat", "count": 4}], "name": "Волна 6", "reward": {"trash": 210}},
		{"delay": 1.0, "enemies": [{"type": "BasicCat", "count": 7}, {"type": "ArcherCat", "count": 4}], "name": "Волна 7", "reward": {"trash": 230}},
		{"delay": 0.9, "enemies": [{"type": "BasicCat", "count": 6}, {"type": "ArcherCat", "count": 5}], "name": "Волна 8", "reward": {"trash": 250}},
		{"delay": 0.8, "enemies": [{"type": "BasicCat", "count": 8}, {"type": "ArcherCat", "count": 5}], "name": "Волна 9", "reward": {"trash": 270}},
		{"delay": 0.7, "enemies": [{"type": "BossCat", "count": 1}], "name": "ФИНАЛЬНЫЙ БОСС", "reward": {"trash": 600, "crystals": 5}}
	],
	"scary": [  # 12 волн для "Страшного"
		{"delay": 2.5, "enemies": [{"type": "BasicCat", "count": 4}, {"type": "ArcherCat", "count": 1}], "name": "Волна 1", "reward": {"trash": 120}},
		{"delay": 2.0, "enemies": [{"type": "BasicCat", "count": 5}, {"type": "ArcherCat", "count": 1}], "name": "Волна 2", "reward": {"trash": 140}},
		{"delay": 1.7, "enemies": [{"type": "BasicCat", "count": 6}, {"type": "ArcherCat", "count": 2}], "name": "Волна 3", "reward": {"trash": 160}},
		{"delay": 1.5, "enemies": [{"type": "BasicCat", "count": 5}, {"type": "ArcherCat", "count": 3}], "name": "Волна 4", "reward": {"trash": 180}},
		{"delay": 1.3, "enemies": [{"type": "BasicCat", "count": 7}, {"type": "ArcherCat", "count": 3}], "name": "Волна 5", "reward": {"trash": 200}},
		{"delay": 1.1, "enemies": [{"type": "BasicCat", "count": 6}, {"type": "ArcherCat", "count": 4}], "name": "Волна 6", "reward": {"trash": 220}},
		{"delay": 1.0, "enemies": [{"type": "BasicCat", "count": 8}, {"type": "ArcherCat", "count": 4}], "name": "Волна 7", "reward": {"trash": 240}},
		{"delay": 0.9, "enemies": [{"type": "BasicCat", "count": 7}, {"type": "ArcherCat", "count": 5}], "name": "Волна 8", "reward": {"trash": 260}},
		{"delay": 0.8, "enemies": [{"type": "BasicCat", "count": 9}, {"type": "ArcherCat", "count": 5}], "name": "Волна 9", "reward": {"trash": 280}},
		{"delay": 0.7, "enemies": [{"type": "BasicCat", "count": 8}, {"type": "ArcherCat", "count": 6}], "name": "Волна 10", "reward": {"trash": 300}},
		{"delay": 0.6, "enemies": [{"type": "BasicCat", "count": 10}, {"type": "ArcherCat", "count": 6}], "name": "Волна 11", "reward": {"trash": 320}},
		{"delay": 0.5, "enemies": [{"type": "BossCat", "count": 1}], "name": "ФИНАЛЬНЫЙ БОСС", "reward": {"trash": 700, "crystals": 8}}
	]
}

# Состояние
var current_wave: int = -1
var is_wave_active: bool = false
var enemies_to_spawn: Array = []
var enemies_alive: int = 0
var spawn_timer: Timer
var actual_spawn_points: Array[Node2D] = []
var stop_all_waves_flag: bool = false  # Флаг для полной остановки
var current_difficulty: String = "cat"  # По умолчанию нормальная сложность
var max_waves_for_current_difficulty: int = 10  # По умолчанию
var wave_hp_bonus_multiplier: float = 1.0  # Множитель HP за чётные волны

@onready var game_manager = get_node("/root/game_manager") if has_node("/root/game_manager") else null

func _ready():
	# Инициализируем точки спавна
	for point_path in spawn_points:
		if has_node(point_path):
			var point = get_node(point_path)
			if point:
				actual_spawn_points.append(point)
	
	print("✅ WaveManager готов. Точек спавна:", actual_spawn_points.size())
	
	# Получаем текущую сложность
	if game_manager:
		current_difficulty = _get_difficulty_string()
		max_waves_for_current_difficulty = game_manager.get_difficulty_multiplier("max_waves")
		print("🎮 Текущая сложность:", current_difficulty, ", волн:", max_waves_for_current_difficulty)
	
	# Создаем таймер спавна
	spawn_timer = Timer.new()
	add_child(spawn_timer)
	spawn_timer.one_shot = false

func _get_difficulty_string() -> String:
	if not game_manager:
		return "cat"
	
	var diff_index = game_manager.get_difficulty_index()
	match diff_index:
		0: return "kitten"
		1: return "cat"
		2: return "scary"
		_: return "cat"

func start_waves():
	print("🚀 Начинаем волны на сложности:", current_difficulty)
	current_wave = 0
	wave_hp_bonus_multiplier = 1.0  # Сбрасываем бонус HP
	stop_all_waves_flag = false  # Сбрасываем флаг остановки
	start_next_wave()

func start_next_wave():
	# Проверяем не остановлены ли волны
	if stop_all_waves_flag:
		print("⏹️ Волны остановлены, не начинаем новую")
		return
	
	# Проверяем не закончились ли волны
	if current_wave >= get_wave_config_for_difficulty().size():
		print("🎉 Все волны пройдены!")
		all_enemies_defeated.emit()
		return
	
	# Получаем конфиг текущей волны
	var wave_config = get_wave_config_for_difficulty()[current_wave]
	
	# Обновляем множитель HP каждую вторую волну (+15%)
	if current_wave >= 1 and (current_wave + 1) % 2 == 0:
		wave_hp_bonus_multiplier += 0.15
		print("📈 Волна", current_wave + 1, ": +15% HP врагов (теперь ×", wave_hp_bonus_multiplier, ")")
	
	# Подготавливаем список врагов
	enemies_to_spawn.clear()
	for enemy_data in wave_config["enemies"]:
		for i in range(enemy_data["count"]):
			enemies_to_spawn.append(enemy_data["type"])
	
	enemies_alive = enemies_to_spawn.size()
	is_wave_active = true
	
	print("🌊 Волна", current_wave + 1, "началась! Врагов:", enemies_alive)
	print("📝 Конфиг волны:", wave_config["name"])
	print("⚙️ Задержка спавна:", wave_config.get("delay", 2.0), "сек")
	
	# Запускаем таймер спавна
	spawn_timer.wait_time = wave_config.get("delay", 2.0)
	spawn_timer.timeout.connect(_spawn_next_enemy)
	spawn_timer.start()
	
	# Сигнал о начале волны
	wave_started.emit(current_wave + 1, wave_config)
	
	# Обновляем UI
	total_waves_updated.emit(get_wave_config_for_difficulty().size())

func _spawn_next_enemy():
	# Проверяем не остановлены ли волны
	if stop_all_waves_flag:
		print("⏹️ Волны остановлены, прекращаем спавн")
		spawn_timer.stop()
		return
	
	if enemies_to_spawn.is_empty():
		spawn_timer.stop()
		spawn_timer.timeout.disconnect(_spawn_next_enemy)
		print("✅ Все враги заспавнены для волны", current_wave + 1)
		return
	
	if actual_spawn_points.is_empty():
		print("❌ Нет точек спавна!")
		return
	
	# Берем тип врага
	var enemy_type = enemies_to_spawn.pop_front()
	
	# Проверяем наличие сцены врага
	if not enemy_scenes.has(enemy_type):
		print("❌ Неизвестный тип врага:", enemy_type)
		return
	
	var enemy_scene = enemy_scenes[enemy_type]
	if not enemy_scene:
		print("❌ Сцена врага не загружена:", enemy_type)
		return
	
	# Выбираем случайную точку спавна
	var spawn_point = actual_spawn_points[randi() % actual_spawn_points.size()]
	
	# Создаем врага
	var enemy = enemy_scene.instantiate()
	get_parent().add_child(enemy)
	enemy.global_position = spawn_point.global_position
	
	# Применяем модификаторы сложности и бонусы волн
	_apply_all_bonuses_to_enemy(enemy)
	
	# Для босса отправляем специальный сигнал
	if enemy_type == "BossCat":
		boss_spawned.emit(enemy)
		print("👑 ФИНАЛЬНЫЙ БОСС ПОЯВИЛСЯ!")
	
	# Подписываемся на смерть врага
	enemy.tree_exited.connect(_on_enemy_died)
	
	print("🐱 Спавн врага", enemy_type, "в позиции", spawn_point.global_position)
	enemy_spawned.emit(enemy)

func _apply_all_bonuses_to_enemy(enemy: Node):
	if not game_manager:
		print("⚠️ GameManager не найден, сложность не применена")
		return
	
	# Получаем базовые множители сложности
	var hp_mult = 1.0
	var damage_mult = 1.0
	
	if game_manager.has_method("get_difficulty_multiplier"):
		hp_mult = game_manager.get_difficulty_multiplier("enemy_hp_multiplier")
		damage_mult = game_manager.get_difficulty_multiplier("enemy_damage_multiplier")
	else:
		print("⚠️ GameManager не имеет метода get_difficulty_multiplier")
		return
	
	# Применяем бонус чётных волн
	hp_mult *= wave_hp_bonus_multiplier
	
	print("🎮 Применяем бонусы: Сложность HP x", hp_mult, ", Урон x", damage_mult, ", Волна HP x", wave_hp_bonus_multiplier)
	
	# Применяем к врагу
	if enemy.has_method("scale_stats"):
		enemy.scale_stats(hp_mult, damage_mult)
	
	# Добавляем метод для применения бонуса волны (если у врага есть такой метод)
	if enemy.has_method("apply_wave_bonus"):
		enemy.apply_wave_bonus(current_wave + 1)

func _on_enemy_died():
	enemies_alive -= 1
	print("☠️ Враг убит. Осталось:", enemies_alive)
	
	if enemies_alive <= 0 and is_wave_active and not stop_all_waves_flag:
		_wave_completed()

func _wave_completed():
	# Проверяем не остановлены ли волны
	if stop_all_waves_flag:
		print("⏹️ Волны остановлены, пропускаем завершение волны")
		return
	
	is_wave_active = false
	
	# Останавливаем таймер если он запущен
	if spawn_timer and spawn_timer.timeout.is_connected(_spawn_next_enemy):
		spawn_timer.stop()
		spawn_timer.timeout.disconnect(_spawn_next_enemy)
	
	print("✅ Волна", current_wave + 1, "завершена!")
	
	# Даем награду за волну
	if is_inside_tree() and not stop_all_waves_flag:
		_give_wave_reward()
	else:
		print("⚠️ Волны остановлены или WaveManager не в дереве сцены, пропускаем награду")
	
	# Сигнал о завершении волны
	if not stop_all_waves_flag:
		wave_completed.emit(current_wave + 1)
	
	# Ждем перед следующей волной ТОЛЬКО ЕСЛИ волны не остановлены
	if is_inside_tree() and not stop_all_waves_flag:
		print("⏳ Ожидание", wave_delay_between, "сек перед следующей волной...")
		await get_tree().create_timer(wave_delay_between).timeout
		
		# Начинаем следующую волну
		current_wave += 1
		print("➡️ Переход к волне", current_wave + 1)
		start_next_wave()
	else:
		print("⚠️ Волны остановлены или WaveManager удален, не начинаем следующую волну")

func _give_wave_reward():
	# ПРОВЕРКА: Волны остановлены?
	if stop_all_waves_flag:
		print("⚠️ Волны остановлены, награда не выдана")
		return
	
	# ПРОВЕРКА: Мы все еще в дереве сцены?
	if not is_inside_tree():
		print("⚠️ WaveManager не в дереве сцены, пропускаем награду")
		return
	
	# ПРОВЕРКА: Есть ли конфиг для текущей волны?
	if current_wave >= get_wave_config_for_difficulty().size():
		return
	
	var wave_config = get_wave_config_for_difficulty()[current_wave]
	var reward = wave_config.get("reward", {"trash": 100})
	
	# Применяем множитель сложности
	var reward_mult = 1.0
	if game_manager and game_manager.has_method("get_difficulty_multiplier"):
		reward_mult = game_manager.get_difficulty_multiplier("reward_multiplier")
	
	var trash_reward = int(reward.get("trash", 100) * reward_mult)
	var crystal_reward = reward.get("crystals", 0)
	
	# ИЩЕМ ИГРОКА
	var player = get_tree().get_first_node_in_group("players")
	
	# ДАЕМ НАГРАДУ ТОЛЬКО ЕСЛИ ИГРОК СУЩЕСТВУЕТ
	if player and is_instance_valid(player):
		# Даем валюту
		player.currency += trash_reward
		if player.has_signal("currency_changed"):
			player.emit_signal("currency_changed", player.currency)
		
		# Даем кристаллы (если есть в награде)
		if crystal_reward > 0 and PlayerInventory:
			PlayerInventory.add_crystal(crystal_reward)
			print("💎 Награда за волну", current_wave + 1, ":", crystal_reward, " Crystals")
		
		print("💰 Награда за волну", current_wave + 1, ":", trash_reward, " Trash")
		
		# Сохраняем прогресс
		if save_system and is_instance_valid(save_system):
			save_system.save_game(player)
	else:
		print("⚠️ Игрок не найден, награда не выдана")

func get_wave_config_for_difficulty():
	return wave_configs.get(current_difficulty, wave_configs["cat"])

func stop_waves():
	print("⏹️ WaveManager.stop_waves() вызван - ПОЛНАЯ ОСТАНОВКА")
	stop_all_waves_flag = true  # Устанавливаем флаг остановки
	is_wave_active = false
	
	# Останавливаем таймер
	if spawn_timer:
		spawn_timer.stop()
		print("⏹️ Таймер спавна остановлен")
	
	# Отключаем все подключенные сигналы
	if spawn_timer and spawn_timer.timeout.is_connected(_spawn_next_enemy):
		spawn_timer.timeout.disconnect(_spawn_next_enemy)
		print("⏹️ Сигнал таймера отключен")
	
	# Очищаем список врагов для спавна
	enemies_to_spawn.clear()
	print("⏹️ Список врагов для спавна очищен")
	
	print("⏹️ Волны полностью остановлены")

func get_current_wave() -> int:
	return current_wave + 1 if current_wave >= 0 else 0

func get_total_waves() -> int:
	return get_wave_config_for_difficulty().size()

func get_enemies_alive() -> int:
	return enemies_alive

func is_wave_in_progress() -> bool:
	return is_wave_active and not stop_all_waves_flag

func is_final_wave() -> bool:
	return current_wave == get_wave_config_for_difficulty().size() - 1

# Новый метод для очистки всех врагов
func clear_all_enemies():
	print("🧹 Очищаю всех врагов...")
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	print("🧹 Очищено врагов:", enemies.size())
