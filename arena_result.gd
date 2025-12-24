extends CanvasLayer  # ИЗМЕНЕНО: Теперь CanvasLayer!

@onready var title_label: Label = $Control/Panel/VBoxContainer/TitleLabel
@onready var time_label: Label = $Control/Panel/VBoxContainer/StatsContainer/TimeLabel
@onready var waves_label: Label = $Control/Panel/VBoxContainer/StatsContainer/WavesLabel
@onready var reward_label: Label = $Control/Panel/VBoxContainer/StatsContainer/RewardLabel
@onready var continue_button: Button = $Control/Panel/VBoxContainer/Buttons/ContinueButton
@onready var retry_button: Button = $Control/Panel/VBoxContainer/Buttons/RetryButton
@onready var panel: Panel = $Control/Panel
@onready var container: Control = $Control

var survival_time: float = 0.0
var waves_completed: int = 0
var is_victory: bool = false

func _ready():
	print("🎯 ArenaResult (CanvasLayer): Готов к работе!")
	
	# Изначально скрываем
	self.visible = false
	
	# Устанавливаем высокий слой чтобы быть поверх всего
	self.layer = 100
	
	# Устанавливаем Control на весь экран
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.set_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Черный полупрозрачный фон
	var background_style = StyleBoxFlat.new()
	background_style.bg_color = Color(0, 0, 0, 0.7)
	container.add_theme_stylebox_override("panel", background_style)
	
	# Центрируем панель
	panel.set_anchors_preset(Control.PRESET_CENTER)
	
	# Подключаем кнопки
	continue_button.pressed.connect(_on_continue_pressed)
	retry_button.pressed.connect(_on_retry_pressed)
	
	# Настраиваем стиль
	_apply_styles()

func _apply_styles():
	# Стиль панели с контентом
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	panel_style.border_color = Color(1, 0.8, 0.2, 1.0)
	panel_style.border_width_left = 4
	panel_style.border_width_top = 4
	panel_style.border_width_right = 4
	panel_style.border_width_bottom = 4
	panel_style.corner_radius_top_left = 15
	panel_style.corner_radius_top_right = 15
	panel_style.corner_radius_bottom_right = 15
	panel_style.corner_radius_bottom_left = 15
	
	panel.add_theme_stylebox_override("panel", panel_style)
	
	# Стиль заголовка
	title_label.add_theme_font_size_override("font_size", 48)
	title_label.add_theme_constant_override("outline_size", 6)
	title_label.add_theme_color_override("font_outline_color", Color.BLACK)
	
	# Стиль статистики
	time_label.add_theme_font_size_override("font_size", 28)
	waves_label.add_theme_font_size_override("font_size", 28)
	reward_label.add_theme_font_size_override("font_size", 32)
	reward_label.add_theme_color_override("font_color", Color(1, 0.95, 0.3))
	
	# Стиль кнопок
	_style_button(continue_button, Color(0.2, 0.7, 0.2), "ПРОДОЛЖИТЬ")
	_style_button(retry_button, Color(0.9, 0.5, 0.1), "ПОВТОРИТЬ")

func _style_button(button: Button, base_color: Color, text: String):
	button.text = text
	button.add_theme_font_size_override("font_size", 24)
	button.custom_minimum_size = Vector2(250, 60)
	
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = base_color.darkened(0.2)
	normal_style.border_color = base_color.lightened(0.4)
	normal_style.border_width_left = 3
	normal_style.border_width_top = 3
	normal_style.border_width_right = 3
	normal_style.border_width_bottom = 3
	normal_style.corner_radius_top_left = 12
	normal_style.corner_radius_top_right = 12
	normal_style.corner_radius_bottom_right = 12
	normal_style.corner_radius_bottom_left = 12
	
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = base_color
	hover_style.border_color = base_color.lightened(0.6)
	
	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = base_color.darkened(0.3)
	pressed_style.border_color = base_color
	
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color(1, 1, 0.9))
	button.add_theme_color_override("font_pressed_color", Color(1, 0.95, 0.8))

func display_results(time: float, waves: int, victory: bool = false):
	print("🎯 ArenaResult.display_results ВЫЗВАН!")
	print("🎯 Данные: время=", time, " волны=", waves, " победа=", victory)
	
	survival_time = time
	waves_completed = waves
	is_victory = victory
	
	# Обновляем UI
	_update_ui()
	
	# Показываем СРАЗУ
	self.visible = true
	
	# Простая анимация
	_simple_show_animation()
	
	# Даем награду
	_give_rewards()
	
	print("🎯 Окно результатов показано!")

func _simple_show_animation():
	"""Простая анимация появления"""
	# Начальное состояние
	panel.scale = Vector2(0.8, 0.8)
	panel.modulate.a = 0
	
	# Анимация
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.3)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "modulate:a", 1.0, 0.3)
	
	await tween.finished
	continue_button.grab_focus()

func _update_ui():
	# Время
	var minutes = int(survival_time) / 60
	var seconds = int(survival_time) % 60
	time_label.text = "⏱️  Время: %02d:%02d" % [minutes, seconds]
	
	# Волны
	waves_label.text = "🌊  Волн: " + str(waves_completed)
	
	# Награда
	var reward = waves_completed * 50
	if is_victory:
		reward += 200
		title_label.text = "🏆 ПОБЕДА!"
		title_label.modulate = Color(0.3, 1, 0.3)
		retry_button.visible = false
		reward_label.text = "💰 Награда: " + str(reward) + " Trash + 💎 Кристалл!"
	else:
		title_label.text = "💀 ПОРАЖЕНИЕ"
		title_label.modulate = Color(1, 0.3, 0.3)
		retry_button.visible = true
		reward_label.text = "💰 Награда: " + str(reward) + " Trash"

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

func _on_continue_pressed():
	print("🎯 Нажата 'Продолжить' - в лагерь")
	
	# Анимация кнопки
	_animate_button_press(continue_button)
	
	# Простое закрытие
	self.visible = false
	
	# Восстанавливаем здоровье игрока
	_restore_player_health()
	
	# Переход с эффектом через TransitionManager
	var transition_manager = get_node_or_null("/root/TransitionManager")
	if transition_manager and transition_manager.has_method("change_scene_with_fade"):
		print("🎬 Использую TransitionManager для перехода")
		transition_manager.change_scene_with_fade("res://scenes/world/labaratory/lab_scene.tscn", 0.3, 0.3)
	else:
		print("⚠️ TransitionManager не найден, прямой переход")
		get_tree().change_scene_to_file("res://scenes/world/labaratory/lab_scene.tscn")

func _on_retry_pressed():
	print("🎯 Нажата 'Повторить' - перезапуск арены")
	
	# Анимация кнопки
	_animate_button_press(retry_button)
	
	# Простое закрытие
	self.visible = false
	
	# Восстанавливаем здоровье игрока
	_restore_player_health()
	
	# Перезапуск арены с эффектом через TransitionManager
	var transition_manager = get_node_or_null("/root/TransitionManager")
	if transition_manager and transition_manager.has_method("change_scene_with_fade"):
		print("🎬 Использую TransitionManager для перезапуска арены")
		var current_scene_path = get_tree().current_scene.scene_file_path
		transition_manager.change_scene_with_fade(current_scene_path, 0.3, 0.3)
	else:
		# Без TransitionManager
		var current_scene_path = get_tree().current_scene.scene_file_path
		var scene = load(current_scene_path)
		if scene:
			get_tree().change_scene_to_packed(scene)

func _animate_button_press(button: Button):
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(button, "scale", Vector2(0.95, 0.95), 0.1)
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1).set_delay(0.1)

func _restore_player_health():
	"""Восстанавливает здоровье игрока до максимального"""
	var player = get_tree().get_first_node_in_group("players")
	if player:
		# Восстанавливаем здоровье
		if player.has_method("heal_to_full"):
			player.heal_to_full()
			print("❤️ Здоровье игрока восстановлено до максимума!")
		
		# Восстанавливаем сыр
		if player.has_method("restore_all_cheese_to_full"):
			player.restore_all_cheese_to_full()
			print("🧀 Сыр игрока восстановлен до полного!")
