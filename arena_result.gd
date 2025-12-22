extends Node2D

@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var time_label: Label = $Panel/VBoxContainer/StatsContainer/TimeLabel
@onready var waves_label: Label = $Panel/VBoxContainer/StatsContainer/WavesLabel
@onready var reward_label: Label = $Panel/VBoxContainer/StatsContainer/RewardLabel
@onready var continue_button: Button = $Panel/VBoxContainer/Buttons/ContinueButton
@onready var retry_button: Button = $Panel/VBoxContainer/Buttons/RetryButton

var survival_time: float = 0.0
var waves_completed: int = 0
var is_victory: bool = false

func _ready():
	print("🎯 ArenaResult (Node2D): Загружен и готов!")
	
	# Сразу показываем
	self.visible = true
	self.z_index = 1000
	
	# Подключаем кнопки
	continue_button.pressed.connect(_on_continue_pressed)
	retry_button.pressed.connect(_on_retry_pressed)
	
	print("🎯 ArenaResult: Кнопки подключены")

func position_at_camera(camera_position: Vector2):
	"""Позиционирование окна как у окна торговли"""
	print("🎯 Позиционирую окно результатов...")
	
	# Размер окна (оригинальный)
	var original_window_size = Vector2(650, 450)
	
	# Масштаб
	var scale_ratio = 0.53
	self.scale = Vector2(scale_ratio, scale_ratio)
	
	# Размер после масштабирования
	var scaled_window_size = original_window_size * scale_ratio
	
	# Позиционируем по центру камеры
	self.global_position = camera_position - (scaled_window_size / 2) - Vector2(0, 180)
	
	print("🎯 Окно позиционировано!")
	print("  Позиция:", self.global_position)

func display_results(time: float, waves: int, victory: bool = false, camera_position: Vector2 = Vector2.ZERO):
	print("🎯 ArenaResult.display_results ВЫЗВАН!")
	print("🎯 Данные: время=", time, " волны=", waves, " победа=", victory)
	
	survival_time = time
	waves_completed = waves
	is_victory = victory
	
	# Если передана позиция камеры - позиционируем
	if camera_position != Vector2.ZERO:
		position_at_camera(camera_position)
	
	# Обновляем UI
	_update_ui()
	
	# Даем награду
	_give_rewards()
	
	# Гарантируем что окно видно
	self.visible = true
	self.modulate = Color(1, 1, 1, 1)
	
	# Фокус на кнопке
	continue_button.grab_focus()
	
	print("🎯 Окно результатов ПОКАЗАНО!")

func _update_ui():
	# Время
	var minutes = int(survival_time) / 60
	var seconds = int(survival_time) % 60
	time_label.text = "Время: %02d:%02d" % [minutes, seconds]
	
	# Волны
	waves_label.text = "Волн: " + str(waves_completed)
	
	# Награда
	var reward = waves_completed * 50
	if is_victory:
		reward += 200
		title_label.text = "ПОБЕДА!"
		title_label.modulate = Color.GREEN
		retry_button.visible = false
		reward_label.text = "Награда: " + str(reward) + " Trash + Кристалл!"
	else:
		title_label.text = "ПОРАЖЕНИЕ"
		title_label.modulate = Color.RED
		retry_button.visible = true
		reward_label.text = "Награда: " + str(reward) + " Trash"
	
	print("🎯 UI обновлен")

func _give_rewards():
	# Даем награду игроку
	var player = get_tree().get_first_node_in_group("players")
	if player:
		var reward = waves_completed * 50
		if is_victory:
			reward += 200
		
		print("🎯 Даю награду игроку:", reward, " Trash")
		player.currency += reward
		if player.has_signal("currency_changed"):
			player.emit_signal("currency_changed", player.currency)
		
		if is_victory:
			var PlayerInventory = get_node_or_null("/root/PlayerInventory")
			if PlayerInventory:
				PlayerInventory.add_item("Crystal", 1)
				print("🎯 Кристалл добавлен")
	else:
		print("🎯 Игрок не найден для выдачи награды")

func _on_continue_pressed():
	print("🎯 Нажата 'Продолжить' - в лагерь")
	
	# ВОССТАНАВЛИВАЕМ ЗДОРОВЬЕ ИГРОКА
	_restore_player_health()
	
	get_tree().change_scene_to_file("res://scenes/world/labaratory/lab_scene.tscn")

func _on_retry_pressed():
	print("🎯 Нажата 'Повторить' - перезапуск арены")
	
	# ВОССТАНАВЛИВАЕМ ЗДОРОВЬЕ ИГРОКА
	_restore_player_health()
	
	get_tree().reload_current_scene()

func _restore_player_health():
	"""Восстанавливает здоровье игрока до максимального"""
	var player = get_tree().get_first_node_in_group("players")
	if player:
		# Восстанавливаем здоровье
		if player.has_method("heal_to_full"):
			player.heal_to_full()
			print("❤️ Здоровье игрока восстановлено до максимума!")
		
		# ВОССТАНАВЛИВАЕМ СЫР!
		if player.has_method("restore_all_cheese_to_full"):
			player.restore_all_cheese_to_full()
			print("🧀 Сыр игрока восстановлен до полного!")
