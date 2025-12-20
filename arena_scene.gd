extends Node2D

@onready var wave_manager = $WaveManager
@onready var great_cheese = $GreateCheese
@onready var tilemap = $TileMap
@onready var spawn_marker = $PlayerSpawn  # Маркер спавна игрока

# UI элементы
@onready var wave_label: Label = $UI/Control/WaveLabel
@onready var enemies_label: Label = $UI/Control/EnemiesLabel
@onready var timer_label: Label = $UI/Control/TimerLabel
@onready var cheese_health_bar: TextureProgressBar = $UI/Control/CheeseHealthBar

var player: Node = null
var survival_time: float = 0.0
var is_game_active: bool = false
var is_game_over: bool = false
var survival_timer: Timer

func _ready():
	print("🏟️ Арена загружена с TileMap!")
	print("🔍 Проверяю сыр:", great_cheese)
	print("📍 Проверяю маркер спавна:", spawn_marker)
	
	# Отладочная информация о маркере
	if spawn_marker:
		print("📍 Маркер спавна найден, позиция:", spawn_marker.global_position)
	else:
		print("⚠️ Маркер спавна не найден!")
		# Создаем временный маркер в центре
		_create_fallback_spawn_marker()
	
	# Добавляем арену в группу для легкого доступа
	add_to_group("arena")
	
	# Добавляем UI в группу для скрытия
	var ui = get_node_or_null("UI")
	if ui:
		ui.add_to_group("arena_ui")
		print("✅ UI арены добавлен в группу")
	
	# Автозагрузка игрока
	_load_player()
	
	# Настройка сыра
	if great_cheese:
		print("🧀 Сыр найден на арене, подключаем сигналы...")
		
		# Подключаем сигналы
		if great_cheese.has_signal("health_changed"):
			great_cheese.health_changed.connect(_on_cheese_health_changed)
		
		if great_cheese.has_signal("destroyed"):
			great_cheese.destroyed.connect(_on_cheese_destroyed)
		else:
			print("❌ Сигнал destroyed НЕ найден у сыра!")
		
		# Установка здоровья сыра
		cheese_health_bar.max_value = great_cheese.max_health
		cheese_health_bar.value = great_cheese.current_health
	else:
		print("❌ Сыр НЕ найден на арене!")
	
	# Проверяем точки спавна врагов
	var spawn_points = _get_spawn_points()
	print("📍 Найдено точек спавна врагов:", spawn_points.size())
	
	# Ждем 0.5 секунды и начинаем игру
	await get_tree().create_timer(0.5).timeout
	start_game()

func _create_fallback_spawn_marker():
	# Создаем временный маркер в центре экрана если основной не найден
	var viewport_size = get_viewport().get_visible_rect().size
	spawn_marker = Marker2D.new()
	spawn_marker.name = "FallbackSpawnMarker"
	spawn_marker.global_position = viewport_size / 2
	add_child(spawn_marker)
	print("📍 Создан временный маркер в центре:", spawn_marker.global_position)

func _load_player():
	# Ищем игрока в сцене
	player = get_tree().get_first_node_in_group("players")
	
	if not player:
		print("❌ Игрок не найден в группе! Создаем нового...")
		var player_scene = preload("res://scenes/player/player.tscn")
		if player_scene:
			player = player_scene.instantiate()
			add_child(player)
			print("✅ Игрок создан на арене")
	else:
		print("✅ Игрок найден на арене")
	
	# Позиционируем игрока
	_position_player()

func _position_player():
	if not player:
		print("⚠️ Не могу позиционировать игрока - player отсутствует")
		return
	
	# Используем маркер спавна
	if spawn_marker:
		player.global_position = spawn_marker.global_position
		print("🎮 Игрок размещен на маркере спавна:", player.global_position)
	else:
		# Запасной вариант - центр экрана
		var viewport_center = get_viewport().get_visible_rect().size / 2
		player.global_position = viewport_center
		print("🎮 Игрок размещен в центре экрана:", player.global_position)

func _get_spawn_points() -> Array:
	var points = []
	var spawn_container = $SpawnPoints
	if spawn_container:
		for child in spawn_container.get_children():
			if child is Marker2D:
				points.append(child.global_position)
	return points

func start_game():
	print("🎮 Игра началась на арене!")
	is_game_active = true
	is_game_over = false
	
	# Создаем таймер выживания
	survival_timer = Timer.new()
	add_child(survival_timer)
	survival_timer.wait_time = 1.0
	survival_timer.timeout.connect(_update_survival_timer)
	survival_timer.start()
	
	# Запускаем волны
	if wave_manager and wave_manager.has_method("start_waves"):
		wave_manager.start_waves()
		print("🌊 Волны запущены")
	
	# Обновляем UI
	_update_ui()

func _update_survival_timer():
	if not is_game_active:
		return
	
	survival_time += 1.0
	
	# Форматируем время
	var minutes = int(survival_time) / 60
	var seconds = int(survival_time) % 60
	
	if timer_label:
		timer_label.text = "Время: %02d:%02d" % [minutes, seconds]
	
	if wave_manager:
		if wave_manager.has_method("get_enemies_alive"):
			var enemies_alive = wave_manager.get_enemies_alive()
			if enemies_label:
				enemies_label.text = "Врагов: " + str(enemies_alive)
		
		if wave_manager.has_method("get_current_wave"):
			var current_wave = wave_manager.get_current_wave()
			if wave_label:
				wave_label.text = "Волна: " + str(current_wave)

func _update_ui():
	if wave_manager:
		if wave_manager.has_method("get_current_wave"):
			var wave = wave_manager.get_current_wave()
			if wave_label:
				wave_label.text = "Волна: " + str(wave)
		
		if wave_manager.has_method("get_enemies_alive"):
			var enemies = wave_manager.get_enemies_alive()
			if enemies_label:
				enemies_label.text = "Врагов: " + str(enemies)

func _on_cheese_health_changed(current: float, max_hp: float):
	print("🧀 Здоровье сыра:", current, "/", max_hp)
	
	if cheese_health_bar:
		cheese_health_bar.max_value = max_hp
		cheese_health_bar.value = current
		
		var percent = current / max_hp
		if percent > 0.6:
			cheese_health_bar.tint_progress = Color(0.2, 1.0, 0.2)
		elif percent > 0.3:
			cheese_health_bar.tint_progress = Color(1.0, 0.8, 0.2)
		else:
			cheese_health_bar.tint_progress = Color(1.0, 0.2, 0.2)
			
			var tween = create_tween()
			tween.tween_property(cheese_health_bar, "modulate:a", 0.5, 0.3)
			tween.tween_property(cheese_health_bar, "modulate:a", 1.0, 0.3)

func _on_cheese_destroyed():
	print("💀 Сигнал: Сыр уничтожен! (получен ареной)")
	_end_game("Сыр уничтожен!")

func _end_game(reason: String):
	# Защита от повторных вызовов
	if is_game_over:
		print("⚠️ Игра уже завершена, игнорируем повторный вызов")
		return
	
	print("🛑 Начинаем завершение игры:", reason)
	is_game_active = false
	is_game_over = true
	
	# Останавливаем таймер
	if survival_timer:
		survival_timer.stop()
		print("⏹️ Таймер остановлен")
	
	# Останавливаем волны
	if wave_manager and wave_manager.has_method("stop_waves"):
		wave_manager.stop_waves()
		print("⏹️ Волны остановлены")
	
	print("🛑 Игра окончена:", reason, " Время:", survival_time, "с")
	
	# Останавливаем всех врагов
	_stop_all_enemies()
	
	# Останавливаем игрока
	if player and player.has_method("set_can_move"):
		player.set_can_move(false)
		print("⏹️ Движение игрока остановлено")
	
	# Сохраняем игру
	if player:
		print("💾 Сохраняем игру...")
		player.save_without_restore()
	
	# Показываем сообщение
	_show_game_over_message(reason)
	
	# Ждем 2 секунды и показываем результаты
	print("⏳ Ждем 2 секунды перед показом результатов...")
	await get_tree().create_timer(2.0).timeout
	
	_show_results_screen()

func _show_game_over_message(reason: String):
	var message_text = ""
	if reason == "Сыр уничтожен!":
		message_text = "🧀 СЫР УНИЧТОЖЕН! 🧀"
	else:
		message_text = "💀 ВАС УБИЛИ! 💀"
	
	var message = Label.new()
	message.text = message_text
	message.add_theme_font_size_override("font_size", 48)
	
	if reason == "Сыр уничтожен!":
		message.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	else:
		message.add_theme_color_override("font_color", Color(1, 0, 0))
	
	# Позиционируем по центру экрана
	var viewport_size = get_viewport().get_visible_rect().size
	message.position = Vector2(viewport_size.x / 2 - 150, viewport_size.y / 2 - 50)
	
	add_child(message)
	
	var tween = create_tween()
	tween.tween_property(message, "scale", Vector2(1.5, 1.5), 0.5)
	tween.tween_property(message, "scale", Vector2(1.0, 1.0), 0.5)
	tween.tween_property(message, "modulate:a", 0, 1.0)
	
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(message):
		message.queue_free()

func _stop_all_enemies():
	print("⏹️ Останавливаю всех врагов...")
	
	# 1. Останавливаем WaveManager
	if wave_manager:
		if wave_manager.has_method("stop_waves"):
			wave_manager.stop_waves()
			print("⏹️ WaveManager остановлен")
		
		# Очищаем всех врагов
		if wave_manager.has_method("clear_all_enemies"):
			wave_manager.clear_all_enemies()
	
	# 2. Останавливаем существующих врагов
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy):
			if enemy.has_method("stop_moving"):
				enemy.stop_moving()
			elif enemy.has_method("queue_free"):
				enemy.queue_free()
	
	print("⏹️ Остановлено/удалено врагов:", enemies.size())

func _show_results_screen():
	print("📊 Показываю экран результатов...")
	
	var results_scene = load("res://scenes/arena_result.tscn")
	if results_scene:
		print("✅ Сцена результатов загружена")
		
		var results = results_scene.instantiate()
		print("✅ Экземпляр создан")
		
		# Находим позицию камеры
		var camera_position = _get_camera_center_position()
		print("📊 Центр камеры для позиционирования:", camera_position)
		
		# Добавляем на сцену ПЕРЕД вызовом методов
		add_child(results)
		print("✅ Окно добавлено на сцену")
		
		# Ждем один кадр чтобы окно полностью инициализировалось
		await get_tree().process_frame
		
		# Получаем данные волны
		var wave_num = 0
		if wave_manager and wave_manager.has_method("get_current_wave"):
			wave_num = wave_manager.get_current_wave()
			print("📊 Волна для отображения:", wave_num)
		
		# Вызываем методы окна результатов
		if results.has_method("position_at_camera"):
			print("✅ Вызываю position_at_camera()")
			results.position_at_camera(camera_position)
		
		# Определяем победа или поражение
		var is_victory = false  # По умолчанию поражение (игрок умер или сыр уничтожен)
		
		# Вызываем display_results
		if results.has_method("display_results"):
			print("✅ Вызываю display_results()")
			# Ждем еще немного чтобы позиционирование завершилось
			await get_tree().create_timer(0.05).timeout
			results.display_results(survival_time, wave_num, is_victory, camera_position)
			print("✅ display_results() вызван")
		else:
			print("❌ Окно не имеет метода display_results()")
		
		# Скрываем UI арены
		var ui = get_node_or_null("UI")
		if ui:
			ui.visible = false
			print("✅ UI арены скрыт")
		
		print("✅ Всё готово, окно должно быть видно!")
	else:
		print("❌ Сцена результатов не найдена")

func _get_camera_center_position() -> Vector2:
	# Ищем камеру игрока
	if player:
		print("🎥 Ищу камеру у игрока:", player.name)
		var camera = player.get_node_or_null("Camera2D")
		if camera:
			print("🎥 Камера найдена, позиция:", camera.global_position)
			return camera.global_position
		else:
			print("🎥 Камера не найдена, использую позицию игрока:", player.global_position)
			return player.global_position
	
	# Если нет игрока, используем центр экрана
	print("🎥 Игрок не найден, использую центр по умолчанию")
	return Vector2(400, 300)

func _on_wave_started(wave_num: int):
	if wave_label:
		wave_label.text = "Волна: " + str(wave_num)
		
		var tween = create_tween()
		tween.tween_property(wave_label, "scale", Vector2(1.3, 1.3), 0.2)
		tween.tween_property(wave_label, "scale", Vector2(1.0, 1.0), 0.2)
		
	print("🌊 Началась волна", wave_num)

# ДОБАВЛЕНО: Метод для получения времени выживания
func get_survival_time() -> float:
	return survival_time

# ДОБАВЛЕНО: Метод для остановки игры при смерти игрока
func on_player_died():
	print("🏟️ Арена получила сигнал о смерти игрока")
	if not is_game_over:
		_end_game("Игрок умер")
