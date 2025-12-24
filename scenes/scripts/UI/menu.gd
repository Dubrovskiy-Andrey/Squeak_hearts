extends Control

# Ноды UI
@onready var new_game_button: Button = $VBoxContainer/NewGameButton
@onready var continue_button: Button = $VBoxContainer/ContinueGameButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var confirm_popup: ConfirmationDialog = $ConfirmPopup
@onready var dark_overlay: ColorRect
@onready var background_texture: TextureRect = $BackgroundTexture

# Сложность
@onready var difficulty_container: HBoxContainer = $VBoxContainer/DifficultyContainer
@onready var kitten_button: Button = $VBoxContainer/DifficultyContainer/KittenButton
@onready var cat_button: Button = $VBoxContainer/DifficultyContainer/CatButton
@onready var scary_button: Button = $VBoxContainer/DifficultyContainer/ScaryButton

# Title
@onready var title_label: Label = $VBoxContainer/TitleLabel

# Настройки
var settings_popup: Window
var brightness_slider: HSlider
var volume_slider: HSlider
var brightness_percent_label: Label
var volume_percent_label: Label

var current_brightness: float = 1.0
var current_volume: float = 0.8
var new_game_dialog: ConfirmationDialog = null

@onready var save_system: Node = get_node("/root/save_system")
@onready var game_manager: Node = get_node("/root/game_manager")

# Словарь для кнопок сложности
var difficulty_buttons: Dictionary = {}

# Стили
var button_style_normal: StyleBoxFlat
var button_style_hover: StyleBoxFlat
var button_style_pressed: StyleBoxFlat

# Стили для попапов
var popup_background: StyleBoxFlat
var popup_button_style_normal: StyleBoxFlat
var popup_button_style_hover: StyleBoxFlat
var popup_button_style_pressed: StyleBoxFlat

func _ready():
	print("ИНИЦИАЛИЗАЦИЯ МЕНЮ")
	
	# Создаем красивую графику
	_create_dark_overlay()
	_setup_background()
	_create_button_styles()
	_create_popup_styles()
	_apply_styles()
	
	# Инициализация
	_load_settings()
	_check_save_file()
	_setup_confirm_popup()
	_init_settings_popup()
	_apply_brightness(current_brightness)
	_apply_volume(current_volume)
	_init_difficulty_buttons()
	
	print("Меню готово")

func _setup_background():
	if background_texture:
		background_texture.texture = preload("res://assets/generated_image.jpg") if ResourceLoader.exists("res://assets/generated_image.jpg") else null
		background_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		background_texture.stretch_mode = TextureRect.STRETCH_SCALE

func _create_dark_overlay():
	dark_overlay = get_node_or_null("DarkOverlay")
	if not dark_overlay:
		dark_overlay = ColorRect.new()
		dark_overlay.name = "DarkOverlay"
		dark_overlay.color = Color(0, 0, 0, 0.6)  # Темный полупрозрачный
		dark_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(dark_overlay)
		move_child(dark_overlay, get_child_count() - 1)

func _create_button_styles():
	# Стиль для обычной кнопки
	button_style_normal = StyleBoxFlat.new()
	button_style_normal.bg_color = Color(0.15, 0.15, 0.2, 0.9)
	button_style_normal.border_color = Color(1, 0.8, 0.2, 0.8)
	button_style_normal.border_width_left = 2
	button_style_normal.border_width_top = 2
	button_style_normal.border_width_right = 2
	button_style_normal.border_width_bottom = 2
	button_style_normal.corner_radius_top_left = 10
	button_style_normal.corner_radius_top_right = 10
	button_style_normal.corner_radius_bottom_right = 10
	button_style_normal.corner_radius_bottom_left = 10
	button_style_normal.shadow_color = Color(0, 0, 0, 0.5)
	button_style_normal.shadow_size = 5
	button_style_normal.shadow_offset = Vector2(2, 2)
	
	# Стиль для кнопки при наведении
	button_style_hover = button_style_normal.duplicate()
	button_style_hover.bg_color = Color(0.2, 0.2, 0.25, 0.95)
	button_style_hover.border_color = Color(1, 0.9, 0.3, 1.0)
	button_style_hover.shadow_size = 8
	button_style_hover.shadow_color = Color(1, 0.8, 0.2, 0.3)
	
	# Стиль для нажатой кнопки
	button_style_pressed = button_style_normal.duplicate()
	button_style_pressed.bg_color = Color(0.1, 0.1, 0.15, 1.0)
	button_style_pressed.border_color = Color(1, 0.7, 0.1, 1.0)
	button_style_pressed.shadow_size = 2
	button_style_pressed.shadow_offset = Vector2(1, 1)

func _create_popup_styles():
	# Стиль фона для всех попапов
	popup_background = StyleBoxFlat.new()
	popup_background.bg_color = Color(0.08, 0.08, 0.12, 0.98)
	popup_background.border_color = Color(1, 0.8, 0.2, 0.9)
	popup_background.border_width_left = 3
	popup_background.border_width_top = 3
	popup_background.border_width_right = 3
	popup_background.border_width_bottom = 3
	popup_background.corner_radius_top_left = 12
	popup_background.corner_radius_top_right = 12
	popup_background.corner_radius_bottom_right = 12
	popup_background.corner_radius_bottom_left = 12
	popup_background.shadow_color = Color(0, 0, 0, 0.6)
	popup_background.shadow_size = 15
	popup_background.shadow_offset = Vector2(3, 3)
	
	# Стиль кнопок для попапов
	popup_button_style_normal = StyleBoxFlat.new()
	popup_button_style_normal.bg_color = Color(0.15, 0.15, 0.2, 0.9)
	popup_button_style_normal.border_color = Color(1, 0.8, 0.2, 0.8)
	popup_button_style_normal.border_width_left = 2
	popup_button_style_normal.border_width_top = 2
	popup_button_style_normal.border_width_right = 2
	popup_button_style_normal.border_width_bottom = 2
	popup_button_style_normal.corner_radius_top_left = 8
	popup_button_style_normal.corner_radius_top_right = 8
	popup_button_style_normal.corner_radius_bottom_right = 8
	popup_button_style_normal.corner_radius_bottom_left = 8
	
	popup_button_style_hover = popup_button_style_normal.duplicate()
	popup_button_style_hover.bg_color = Color(0.2, 0.2, 0.25, 0.95)
	popup_button_style_hover.border_color = Color(1, 0.9, 0.3, 1.0)
	
	popup_button_style_pressed = popup_button_style_normal.duplicate()
	popup_button_style_pressed.bg_color = Color(0.1, 0.1, 0.15, 1.0)
	popup_button_style_pressed.border_color = Color(1, 0.7, 0.1, 1.0)

func _apply_styles():
	# Применяем стили к кнопкам
	var buttons = [new_game_button, continue_button, settings_button, quit_button]
	
	for button in buttons:
		if button:
			button.add_theme_font_size_override("font_size", 24)
			button.add_theme_color_override("font_color", Color.WHITE)
			button.add_theme_color_override("font_hover_color", Color(1, 0.9, 0.3))
			button.add_theme_color_override("font_pressed_color", Color(1, 0.8, 0.2))
			button.add_theme_constant_override("outline_size", 2)
			button.add_theme_color_override("font_outline_color", Color.BLACK)
			button.custom_minimum_size = Vector2(300, 50)
			
			button.add_theme_stylebox_override("normal", button_style_normal)
			button.add_theme_stylebox_override("hover", button_style_hover)
			button.add_theme_stylebox_override("pressed", button_style_pressed)
			button.add_theme_stylebox_override("disabled", button_style_normal.duplicate())
	
	# Стиль заголовка
	if title_label:
		title_label.add_theme_font_size_override("font_size", 64)
		title_label.add_theme_color_override("font_color", Color(1, 0.9, 0.2))
		title_label.add_theme_constant_override("outline_size", 8)
		title_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
		title_label.text = "Squeak hearts"
	
	# Стиль для кнопок сложности
	_apply_difficulty_styles()

func _apply_difficulty_styles():
	if kitten_button and cat_button and scary_button:
		var diff_buttons = [kitten_button, cat_button, scary_button]
		
		for button in diff_buttons:
			button.add_theme_font_size_override("font_size", 20)
			button.custom_minimum_size = Vector2(100, 40)
			button.add_theme_constant_override("outline_size", 2)
			button.add_theme_color_override("font_outline_color", Color.BLACK)
			
			var diff_style_normal = StyleBoxFlat.new()
			diff_style_normal.bg_color = Color(0.2, 0.2, 0.25, 0.8)
			diff_style_normal.border_color = Color(0.5, 0.5, 0.5, 0.5)
			diff_style_normal.border_width_left = 1
			diff_style_normal.border_width_top = 1
			diff_style_normal.border_width_right = 1
			diff_style_normal.border_width_bottom = 1
			diff_style_normal.corner_radius_top_left = 8
			diff_style_normal.corner_radius_top_right = 8
			diff_style_normal.corner_radius_bottom_right = 8
			diff_style_normal.corner_radius_bottom_left = 8
			
			var diff_style_hover = diff_style_normal.duplicate()
			diff_style_hover.bg_color = Color(0.25, 0.25, 0.3, 0.9)
			diff_style_hover.border_color = Color(0.7, 0.7, 0.7, 0.7)
			
			var diff_style_pressed = diff_style_normal.duplicate()
			diff_style_pressed.bg_color = Color(0.15, 0.15, 0.2, 1.0)
			diff_style_pressed.border_color = Color(0.9, 0.9, 0.9, 1.0)
			
			button.add_theme_stylebox_override("normal", diff_style_normal)
			button.add_theme_stylebox_override("hover", diff_style_hover)
			button.add_theme_stylebox_override("pressed", diff_style_pressed)

func _apply_popup_styles(dialog: Window):
	# Применяем стиль фона ко всему окну
	dialog.add_theme_stylebox_override("panel", popup_background)

func _apply_full_popup_style_to_dialog(dialog: ConfirmationDialog):
	# Создаем полный стиль для ConfirmationDialog
	var panel_style = popup_background.duplicate()
	
	# Переопределяем ВСЕ стили диалога
	dialog.add_theme_stylebox_override("panel", panel_style)
	
	# Стилизуем заголовок
	dialog.add_theme_font_size_override("title_font_size", 24)
	dialog.add_theme_color_override("title_color", Color(1, 0.9, 0.3))
	
	# Стилизуем основной текст
	dialog.add_theme_font_size_override("font_size", 18)
	dialog.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	
	# Убираем стандартные отступы и улучшаем компоновку
	dialog.add_theme_constant_override("content_margin_top", 30)
	dialog.add_theme_constant_override("content_margin_bottom", 30)
	dialog.add_theme_constant_override("content_margin_left", 30)
	dialog.add_theme_constant_override("content_margin_right", 30)
	
	# Уменьшаем отступ между текстом и кнопками
	dialog.add_theme_constant_override("buttons_separation", 20)
	
	# Убираем лишние отступы для кнопок
	dialog.add_theme_constant_override("button_margin_top", 20)
	dialog.add_theme_constant_override("button_margin_bottom", 20)
	dialog.add_theme_constant_override("button_margin_left", 20)
	dialog.add_theme_constant_override("button_margin_right", 20)
	
func _apply_button_styles_to_popup(dialog: ConfirmationDialog):
	# Получаем кнопки
	var ok_button = dialog.get_ok_button()
	var cancel_button = dialog.get_cancel_button()
	
	# Настраиваем размер кнопок и их контейнер
	if ok_button and cancel_button:
		# Устанавливаем минимальный размер кнопок
		ok_button.custom_minimum_size = Vector2(140, 40)
		cancel_button.custom_minimum_size = Vector2(140, 40)
		
		# Применяем стили к кнопкам
		ok_button.add_theme_font_size_override("font_size", 18)
		ok_button.add_theme_color_override("font_color", Color.WHITE)
		ok_button.add_theme_color_override("font_hover_color", Color(1, 1, 0.5))
		ok_button.add_theme_color_override("font_pressed_color", Color(1, 0.8, 0.2))
		ok_button.add_theme_constant_override("outline_size", 2)
		ok_button.add_theme_color_override("font_outline_color", Color.BLACK)
		
		ok_button.add_theme_stylebox_override("normal", popup_button_style_normal)
		ok_button.add_theme_stylebox_override("hover", popup_button_style_hover)
		ok_button.add_theme_stylebox_override("pressed", popup_button_style_pressed)
		
		cancel_button.add_theme_font_size_override("font_size", 18)
		cancel_button.add_theme_color_override("font_color", Color.WHITE)
		cancel_button.add_theme_color_override("font_hover_color", Color(1, 1, 0.5))
		cancel_button.add_theme_color_override("font_pressed_color", Color(1, 0.8, 0.2))
		cancel_button.add_theme_constant_override("outline_size", 2)
		cancel_button.add_theme_color_override("font_outline_color", Color.BLACK)
		
		cancel_button.add_theme_stylebox_override("normal", popup_button_style_normal)
		cancel_button.add_theme_stylebox_override("hover", popup_button_style_hover)
		cancel_button.add_theme_stylebox_override("pressed", popup_button_style_pressed)
	
	# Находим контейнер кнопок и настраиваем его
	await get_tree().process_frame  # Ждем создания кнопок
	
	# Ищем HBoxContainer с кнопками
	for child in dialog.get_children():
		if child is HBoxContainer:
			# Уменьшаем отступы контейнера кнопок
			child.add_theme_constant_override("separation", 30)  # Расстояние между кнопками
			child.add_theme_constant_override("margin_top", 10)
			child.add_theme_constant_override("margin_bottom", 10)
			break

func _animate_popup_appearance(dialog: ConfirmationDialog):
	# Ждем пока диалог полностью создастся
	await get_tree().process_frame
	
	# Проверяем что диалог все еще существует
	if not is_instance_valid(dialog):
		return
	
	# Пытаемся найти дочернюю панель
	var children = dialog.get_children()
	if children.size() == 0:
		# Нет дочерних элементов - просто показываем
		return
	
	# Анимируем весь диалог через fade-in (самый простой способ)
	dialog.modulate.a = 0
	
	var tween = create_tween()
	tween.tween_property(dialog, "modulate:a", 1.0, 0.3)

func _init_difficulty_buttons():
	# Инициализируем словарь кнопок сложности
	difficulty_buttons = {
		"kitten": kitten_button,
		"cat": cat_button,
		"scary": scary_button
	}
	
	# Подключаем сигналы
	if kitten_button:
		kitten_button.pressed.connect(_on_difficulty_button_pressed.bind("kitten"))
	if cat_button:
		cat_button.pressed.connect(_on_difficulty_button_pressed.bind("cat"))
	if scary_button:
		scary_button.pressed.connect(_on_difficulty_button_pressed.bind("scary"))
	
	# Устанавливаем визуальное состояние по умолчанию
	_update_difficulty_visuals()

func _update_difficulty_visuals():
	# Обновляем внешний вид кнопок в зависимости от выбранной сложности
	if not game_manager:
		print("⚠️ GameManager не найден!")
		return
	
	var current_diff = game_manager.current_difficulty
	
	for diff_name in difficulty_buttons:
		var button = difficulty_buttons[diff_name]
		if button:
			# Определяем, активна ли эта кнопка
			var is_active = false
			var active_color = Color(1, 0.8, 0.2)
			var inactive_color = Color(0.8, 0.8, 0.8)
			
			match diff_name:
				"kitten": 
					is_active = (current_diff == game_manager.Difficulty.KITTEN)
					active_color = Color(0.3, 0.8, 0.3)  # Зеленый для китенка
				"cat": 
					is_active = (current_diff == game_manager.Difficulty.CAT)
					active_color = Color(1, 0.6, 0.1)  # Оранжевый для кота
				"scary": 
					is_active = (current_diff == game_manager.Difficulty.SCARY)
					active_color = Color(1, 0.3, 0.3)  # Красный для страха
			
			# Обновляем визуал
			if is_active:
				button.modulate = Color(1, 1, 1, 1.0)
				button.add_theme_color_override("font_color", active_color)
				
				# Делаем рамку активной
				var style = button.get_theme_stylebox("normal").duplicate()
				style.border_color = active_color
				style.border_width_left = 3
				style.border_width_top = 3
				style.border_width_right = 3
				style.border_width_bottom = 3
				button.add_theme_stylebox_override("normal", style)
				
				print("Кнопка", diff_name, "активна")
			else:
				button.modulate = Color(1, 1, 1, 0.7)
				button.add_theme_color_override("font_color", inactive_color)
				print("Кнопка", diff_name, "неактивна")

func _on_difficulty_button_pressed(diff_name: String):
	if not game_manager:
		print("❌ GameManager не найден!")
		return
	
	print("🎮 Выбрана сложность:", diff_name)
	
	# Устанавливаем сложность
	match diff_name:
		"kitten":
			game_manager.set_difficulty(game_manager.Difficulty.KITTEN)
		"cat":
			game_manager.set_difficulty(game_manager.Difficulty.CAT)
		"scary":
			game_manager.set_difficulty(game_manager.Difficulty.SCARY)
	
	# Обновляем визуал кнопок
	_update_difficulty_visuals()
	
	# Сохраняем настройки сложности
	_save_settings()

func _apply_brightness(brightness_percent: float):
	var brightness = clamp(brightness_percent, 0.5, 1.5)
	var alpha: float
	if brightness <= 1.0:
		alpha = (1.0 - brightness) * 0.5
		dark_overlay.color = Color(0, 0, 0, alpha)
	else:
		alpha = -(brightness - 1.0) * 0.3
		dark_overlay.color = Color(1, 1, 1, abs(alpha))

func _apply_volume(volume_percent: float):
	var volume = clamp(volume_percent, 0.0, 1.0)
	AudioServer.set_bus_volume_db(0, linear_to_db(volume))
	AudioServer.set_bus_mute(0, volume == 0)

func _load_settings():
	var config = ConfigFile.new()
	if config.load("user://game_settings.cfg") == OK:
		current_brightness = config.get_value("Settings", "brightness", 1.0)
		current_volume = config.get_value("Settings", "volume", 0.8)
		
		# Загружаем сложность
		var saved_difficulty = config.get_value("Settings", "difficulty", "kitten")
		if game_manager:
			match saved_difficulty:
				"kitten": game_manager.set_difficulty(game_manager.Difficulty.KITTEN)
				"cat": game_manager.set_difficulty(game_manager.Difficulty.CAT)
				"scary": game_manager.set_difficulty(game_manager.Difficulty.SCARY)
		
		print("Загружены настройки. Сложность:", saved_difficulty)
	else:
		_save_settings()

func _save_settings():
	var config = ConfigFile.new()
	config.set_value("Settings", "brightness", current_brightness)
	config.set_value("Settings", "volume", current_volume)
	
	# Сохраняем сложность
	if game_manager:
		var diff_to_save = "kitten"
		match game_manager.current_difficulty:
			game_manager.Difficulty.KITTEN: diff_to_save = "kitten"
			game_manager.Difficulty.CAT: diff_to_save = "cat"
			game_manager.Difficulty.SCARY: diff_to_save = "scary"
		config.set_value("Settings", "difficulty", diff_to_save)
		print("Сложность сохранена:", diff_to_save)
	
	config.save("user://game_settings.cfg")

func _check_save_file():
	if save_system:
		continue_button.disabled = not save_system.has_save()

func _on_new_game_button_pressed():
	# Закрываем диалоги если открыты
	if new_game_dialog != null and is_instance_valid(new_game_dialog):
		new_game_dialog.queue_free()
		new_game_dialog = null
	
	if save_system and save_system.has_save():
		# Создаем красивое окно подтверждения
		_show_new_game_confirmation()
	else:
		# Нет сохранения - сразу показываем выбор обучения
		print("🎮 Начинаем новую игру без сохранения")
		
		# Сбрасываем инвентарь если существует
		if PlayerInventory:
			PlayerInventory.reset_for_new_game()
		
		# Убеждаемся, что сложность установлена
		if game_manager:
			game_manager.set_difficulty(game_manager.Difficulty.KITTEN)
			_update_difficulty_visuals()
		
		# Сохраняем настройки
		_save_settings()
		
		# Показываем окно выбора обучения
		_show_tutorial_choice()

func _show_new_game_confirmation():
	new_game_dialog = ConfirmationDialog.new()
	new_game_dialog.title = "📁 НОВАЯ ИГРА"
	new_game_dialog.dialog_text = "Текущее сохранение будет удалено.\n\nВы уверены что хотите начать новую игру?"
	new_game_dialog.get_ok_button().text = "ДА, НАЧАТЬ"
	new_game_dialog.get_cancel_button().text = "ОТМЕНА"
	
	# Ждем пока диалог создастся
	await get_tree().process_frame
	
	# Находим все Label в диалоге и меняем им шрифт
	for child in new_game_dialog.find_children("*", "Label", true):
		if child.text == new_game_dialog.dialog_text:
			# Это основной текст диалога
			child.add_theme_font_size_override("font_size", 56)
			child.add_theme_color_override("font_color", Color(1, 1, 1))
		elif child.text == new_game_dialog.title:
			# Это заголовок
			child.add_theme_font_size_override("font_size", 28)
			child.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
	
	# Применяем остальные стили
	_apply_full_popup_style_to_dialog(new_game_dialog)
	_apply_button_styles_to_popup(new_game_dialog)
	
	# ... остальной код
	
	# Убираем стандартную тему
	new_game_dialog.theme = Theme.new()
	
	
	# Подключаем сигналы
	new_game_dialog.confirmed.connect(func():
		print("🧹 Очищаем сохранение для новой игры")
		# Удаляем сохранение
		save_system.clear_save()
		
		# Сбрасываем инвентарь если существует
		if PlayerInventory:
			PlayerInventory.reset_for_new_game()
		
		# Сбрасываем сложность на стандартную
		if game_manager:
			game_manager.set_difficulty(game_manager.Difficulty.KITTEN)
			_update_difficulty_visuals()
		
		# Сохраняем настройки
		_save_settings()
		
		# Показываем окно выбора обучения
		_show_tutorial_choice()
	)
	
	# Показываем окно
	add_child(new_game_dialog)
	
	# Устанавливаем размер ПЕРЕД показом
	new_game_dialog.size = Vector2(500, 250)
	
	# Ждем кадр для применения размера
	await get_tree().process_frame
	
	# Центрируем диалог (ИСПРАВЛЕННАЯ ЧАСТЬ)
	var screen_size: Vector2i = get_viewport().get_visible_rect().size
	var screen_vec2: Vector2 = Vector2(screen_size)
	var dialog_size: Vector2 = new_game_dialog.size
	new_game_dialog.position = (screen_vec2 - dialog_size) / 2
	
	# Показываем
	new_game_dialog.popup()

func _on_continue_game_button_pressed():
	if save_system and save_system.has_save():
		print("📂 Меню: Загружаем сохранение перед переходом в сцену")
		# Загружаем сохранение
		save_system.load_game()
		
		# Получаем данные обучения
		var tutorial_data = save_system.get_tutorial_data()
		print("📂 Загруженные данные обучения:", tutorial_data)
		
		# Получаем путь к сохраненной сцене
		var scene = save_system.get_saved_scene_path()
		if scene != "" and ResourceLoader.exists(scene):
			# Переходим в сохраненную сцену
			print("Переход в сохраненную сцену:", scene)
			TransitionManager.change_scene_with_fade(scene)
		else:
			# Если сцена не найдена, переходим в стандартную
			print("Сохраненная сцена не найдена, переход в лабораторию")
			TransitionManager.change_scene_with_fade("res://scenes/world/labaratory/lab_scene.tscn")
	else:
		# Если сохранения нет, начинаем новую игру с выбором обучения
		print("⚠️ Сохранение не найдено, начинаем новую игру")
		
		# Сбрасываем инвентарь если существует
		if PlayerInventory:
			PlayerInventory.reset_for_new_game()
		
		# Устанавливаем сложность по умолчанию
		if game_manager:
			game_manager.set_difficulty(game_manager.Difficulty.KITTEN)
			_update_difficulty_visuals()
		
		# Сохраняем настройки
		_save_settings()
		
		# Показываем окно выбора обучения
		_show_tutorial_choice()

func _on_settings_button_pressed():
	if settings_popup:
		brightness_slider.value = current_brightness * 100
		volume_slider.value = current_volume * 100
		brightness_percent_label.text = str(int(current_brightness * 100)) + "%"
		volume_percent_label.text = str(int(current_volume * 100)) + "%"
		settings_popup.visible = true
		settings_popup.grab_focus()

func _on_quit_button_pressed():
	confirm_popup.popup_centered(Vector2(400, 200))

func close_all_dialogs():
	if new_game_dialog != null and is_instance_valid(new_game_dialog):
		new_game_dialog.queue_free()
		new_game_dialog = null
	if settings_popup:
		settings_popup.visible = false
	confirm_popup.hide()

func _setup_confirm_popup():
	if confirm_popup:
		confirm_popup.title = "🚪 ВЫХОД ИЗ ИГРЫ"
		confirm_popup.dialog_text = "Вы уверены, что хотите выйти из игры?"
		confirm_popup.get_ok_button().text = "ВЫЙТИ"
		confirm_popup.get_cancel_button().text = "ОСТАТЬСЯ"
		
		# Применяем ПОЛНЫЕ стили
		_apply_full_popup_style_to_dialog(confirm_popup)
		_apply_button_styles_to_popup(confirm_popup)
		
		# Убираем стандартную тему
		confirm_popup.theme = Theme.new()
		
		confirm_popup.confirmed.connect(func():
			_save_settings()
			await get_tree().create_timer(0.3).timeout
			TransitionManager.fade_out(0.5)
			await get_tree().create_timer(0.5).timeout
			get_tree().quit()
		)
		confirm_popup.canceled.connect(func(): 
			print("Игрок остался в меню")
		)
		confirm_popup.hide()

func _init_settings_popup():
	settings_popup = Window.new()
	settings_popup.name = "SettingsPopup"
	settings_popup.title = "⚙️ НАСТРОЙКИ"
	settings_popup.size = Vector2(500, 400)
	settings_popup.unresizable = true
	settings_popup.visible = false
	settings_popup.close_requested.connect(_on_close_settings)
	
	# Применяем стиль фона
	_apply_popup_styles(settings_popup)

	var main_container = VBoxContainer.new()
	main_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_KEEP_SIZE, 30)
	main_container.add_theme_constant_override("separation", 30)

	# Яркость
	var brightness_container = VBoxContainer.new()
	brightness_container.add_theme_constant_override("separation", 10)
	
	var brightness_title = Label.new()
	brightness_title.text = "💡 ЯРКОСТЬ ЭКРАНА"
	brightness_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	brightness_title.add_theme_font_size_override("font_size", 20)
	brightness_title.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
	brightness_container.add_child(brightness_title)

	var brightness_hbox = HBoxContainer.new()
	brightness_hbox.add_theme_constant_override("separation", 15)
	
	var dark_label = Label.new()
	dark_label.text = "🌙 ТЕМНО"
	dark_label.add_theme_font_size_override("font_size", 16)
	brightness_hbox.add_child(dark_label)

	brightness_slider = HSlider.new()
	brightness_slider.min_value = 50
	brightness_slider.max_value = 150
	brightness_slider.value = current_brightness * 100
	brightness_slider.custom_minimum_size = Vector2(250, 30)
	brightness_slider.value_changed.connect(_on_brightness_changed)
	brightness_hbox.add_child(brightness_slider)

	var bright_label = Label.new()
	bright_label.text = "☀️ ЯРКО"
	bright_label.add_theme_font_size_override("font_size", 16)
	brightness_hbox.add_child(bright_label)
	brightness_container.add_child(brightness_hbox)

	brightness_percent_label = Label.new()
	brightness_percent_label.text = str(int(current_brightness * 100)) + "%"
	brightness_percent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	brightness_percent_label.add_theme_font_size_override("font_size", 18)
	brightness_percent_label.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
	brightness_container.add_child(brightness_percent_label)
	main_container.add_child(brightness_container)

	# Громкость
	var volume_container = VBoxContainer.new()
	volume_container.add_theme_constant_override("separation", 10)
	
	var volume_title = Label.new()
	volume_title.text = "🔊 ГРОМКОСТЬ ЗВУКА"
	volume_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	volume_title.add_theme_font_size_override("font_size", 20)
	volume_title.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
	volume_container.add_child(volume_title)

	var volume_hbox = HBoxContainer.new()
	volume_hbox.add_theme_constant_override("separation", 15)
	
	var quiet_label = Label.new()
	quiet_label.text = "🔇 ТИХО"
	quiet_label.add_theme_font_size_override("font_size", 16)
	volume_hbox.add_child(quiet_label)

	volume_slider = HSlider.new()
	volume_slider.min_value = 0
	volume_slider.max_value = 100
	volume_slider.value = current_volume * 100
	volume_slider.custom_minimum_size = Vector2(250, 30)
	volume_slider.value_changed.connect(_on_volume_changed)
	volume_hbox.add_child(volume_slider)

	var loud_label = Label.new()
	loud_label.text = "🔊 ГРОМКО"
	loud_label.add_theme_font_size_override("font_size", 16)
	volume_hbox.add_child(loud_label)
	volume_container.add_child(volume_hbox)

	volume_percent_label = Label.new()
	volume_percent_label.text = str(int(current_volume * 100)) + "%"
	volume_percent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	volume_percent_label.add_theme_font_size_override("font_size", 18)
	volume_percent_label.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
	volume_container.add_child(volume_percent_label)
	main_container.add_child(volume_container)

	# Кнопки
	var buttons_hbox = HBoxContainer.new()
	buttons_hbox.add_theme_constant_override("separation", 20)
	buttons_hbox.add_spacer(false)
	
	var apply_button = Button.new()
	apply_button.text = "✅ ПРИМЕНИТЬ"
	apply_button.custom_minimum_size = Vector2(150, 40)
	apply_button.add_theme_font_size_override("font_size", 18)
	apply_button.pressed.connect(_on_apply_settings)
	
	# Стилизуем кнопки настроек
	apply_button.add_theme_stylebox_override("normal", popup_button_style_normal)
	apply_button.add_theme_stylebox_override("hover", popup_button_style_hover)
	apply_button.add_theme_stylebox_override("pressed", popup_button_style_pressed)
	apply_button.add_theme_color_override("font_color", Color.WHITE)
	apply_button.add_theme_color_override("font_hover_color", Color(1, 0.9, 0.3))
	
	buttons_hbox.add_child(apply_button)

	var close_button = Button.new()
	close_button.text = "❌ ЗАКРЫТЬ"
	close_button.custom_minimum_size = Vector2(150, 40)
	close_button.add_theme_font_size_override("font_size", 18)
	close_button.pressed.connect(_on_close_settings)
	
	close_button.add_theme_stylebox_override("normal", popup_button_style_normal)
	close_button.add_theme_stylebox_override("hover", popup_button_style_hover)
	close_button.add_theme_stylebox_override("pressed", popup_button_style_pressed)
	close_button.add_theme_color_override("font_color", Color.WHITE)
	close_button.add_theme_color_override("font_hover_color", Color(1, 0.9, 0.3))
	
	buttons_hbox.add_child(close_button)
	buttons_hbox.add_spacer(false)

	main_container.add_child(buttons_hbox)
	settings_popup.add_child(main_container)
	add_child(settings_popup)
	_center_window(settings_popup)
	
	# Анимация для настроек
	


func _center_window(window: Window):
	var screen_size = DisplayServer.window_get_size()
	window.position = (screen_size - window.size) / 2

func _on_brightness_changed(value: float):
	current_brightness = value / 100.0
	brightness_percent_label.text = str(int(value)) + "%"
	_apply_brightness(current_brightness)

func _on_volume_changed(value: float):
	current_volume = value / 100.0
	volume_percent_label.text = str(int(value)) + "%"
	_apply_volume(current_volume)

func _on_apply_settings():
	_save_settings()
	settings_popup.visible = false

func _on_close_settings():
	settings_popup.visible = false

func _show_tutorial_choice():
	print("🔄 Показываем выбор обучения")
	
	# Проверяем, проходил ли игрок обучение
	var save_sys = get_node_or_null("/root/save_system")
	var skip_tutorial_choice = false
	
	if save_sys:
		var player_data = save_sys.get_player_data()
		if player_data.get("tutorial_completed", false):
			print("📚 Обучение уже пройдено, пропускаем выбор")
			skip_tutorial_choice = true
	
	if skip_tutorial_choice:
		# Обучение уже пройдено - сразу загружаем игру
		print("Переход в лабораторию (обучение пройдено)")
		TransitionManager.change_scene_with_fade("res://scenes/world/labaratory/lab_scene.tscn")
	else:
		# Загружаем сцену выбора обучения
		var choice_scene = preload("res://scenes/ui/TutorialChoice.tscn")
		if choice_scene:
			print("Создаем окно выбора обучения")
			
			var choice = choice_scene.instantiate()
			
			if choice:
				print("✅ Объект TutorialChoice создан")
				
				# ⚠️ ИСПРАВЛЯЕМ ЗДЕСЬ: сдвигаем позицию
				var screen_size = get_viewport().size
				choice.position = Vector2(
					(screen_size.x - choice.size.x) / 2 + 100,  # Центр + 100px вправо
					(screen_size.y - choice.size.y) / 2 + 50    # Центр + 50px вниз
				)
				choice.size = Vector2(600, 400)
				
				# Подключаем сигнал ВАЖНО: без CONNECT_ONE_SHOT
				choice.tutorial_selected.connect(_on_tutorial_choice_selected)
				
				# Добавляем как дочерний элемент
				add_child(choice)
				
				print("✅ TutorialChoice добавлен в сцену")
				print("📊 Состояние TutorialChoice:")
				print("  - Видимый:", choice.visible)
				print("  - Позиция:", choice.position)
				print("  - Размер:", choice.size)
				
				# Ждем завершения выбора
				await choice.tutorial_selected
				print("✅ Выбор обучения сделан")
				
			else:
				print("❌ Не удалось создать TutorialChoice")
				TransitionManager.change_scene_with_fade("res://scenes/world/labaratory/lab_scene.tscn")
		else:
			print("❌ Сцена tutorial_choice.tscn не найдена!")
			TransitionManager.change_scene_with_fade("res://scenes/world/labaratory/lab_scene.tscn")

func _on_tutorial_choice_selected(show_tutorial: bool):
	print("🎮 Игрок выбрал:", "ОБУЧЕНИЕ" if show_tutorial else "ПРОПУСТИТЬ")
	
	var save_sys = get_node_or_null("/root/save_system")
	
	# Ждем немного перед переходом
	await get_tree().create_timer(0.5).timeout
	
	if show_tutorial:
		# Сохраняем флаг "нужно пройти обучение"
		if save_sys:
			var player_data = save_sys.get_player_data()
			player_data["need_tutorial"] = true
			player_data["tutorial_skipped"] = false
			save_sys.save_data["player_data"] = player_data
			print("Установлен флаг need_tutorial = true")
		
		# Загружаем сцену с обучением
		print("Переход в лабораторию с обучением")
		TransitionManager.change_scene_with_fade("res://scenes/world/labaratory/lab_scene.tscn")
	else:
		# Сохраняем флаг "обучение пропущено"
		if save_sys:
			var player_data = save_sys.get_player_data()
			player_data["tutorial_skipped"] = true
			player_data["need_tutorial"] = false
			player_data["tutorial_completed"] = true
			save_sys.save_data["player_data"] = player_data
			print("Установлен флаг tutorial_skipped = true")
		
		# Загружаем сцену без обучения
		print("Переход в лабораторию без обучения")
		TransitionManager.change_scene_with_fade("res://scenes/world/labaratory/lab_scene.tscn")
