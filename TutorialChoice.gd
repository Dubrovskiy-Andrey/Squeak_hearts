extends Control
class_name TutorialChoice

@onready var panel: Panel
@onready var yes_button: Button
@onready var no_button: Button

signal tutorial_selected(choice: bool)

func _ready():
	print("🎮 TutorialChoice._ready() начат")
	
	# Создаем UI полностью через код
	_create_ui()
	
	# Запускаем анимацию появления
	await get_tree().create_timer(0.1).timeout
	_init_animation()

func _create_ui():
	print("🛠️ Создание UI через код...")
	
	# Устанавливаем позицию со сдвигом 100px вправо, 50px вниз
	var screen_size = get_viewport().size
	self.position = Vector2(
		(screen_size.x - 600) / 2 - 280,  # +100px вправо от центра
		(screen_size.y - 400) / 2 - 150     # +50px вниз от центра
	)
	
	# Устанавливаем размер
	self.size = Vector2(600, 400)
	
	# Создаем стиль для панели
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.08, 0.12, 0.95)
	panel_style.border_color = Color(1, 0.8, 0.2, 0.8)
	panel_style.border_width_left = 3
	panel_style.border_width_top = 3
	panel_style.border_width_right = 3
	panel_style.border_width_bottom = 3
	panel_style.corner_radius_top_left = 15
	panel_style.corner_radius_top_right = 15
	panel_style.corner_radius_bottom_right = 15
	panel_style.corner_radius_bottom_left = 15
	panel_style.shadow_color = Color(0, 0, 0, 0.5)
	panel_style.shadow_size = 10
	
	# Создаем панель
	panel = Panel.new()
	panel.name = "Panel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.size = Vector2(550, 350)
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)
	print("✅ Панель создана")
	
	# Создаем главный контейнер
	var main_vbox = VBoxContainer.new()
	main_vbox.name = "MainVBox"
	main_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_KEEP_SIZE, 40)
	main_vbox.add_theme_constant_override("separation", 25)
	panel.add_child(main_vbox)
	
	# Заголовок
	var title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = "ПРОЙТИ ОБУЧЕНИЕ?"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 36)
	title_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	main_vbox.add_child(title_label)
	print("✅ Заголовок создан")
	
	# Описание
	var description_label = Label.new()
	description_label.name = "DescriptionLabel"
	description_label.text = "Рекомендуется для новых игроков\nВы узнаете основы управления и механики игры"
	description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description_label.add_theme_font_size_override("font_size", 22)
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.custom_minimum_size = Vector2(0, 80)
	main_vbox.add_child(description_label)
	print("✅ Описание создано")
	
	# Создаем стиль для кнопок
	var button_style_normal = StyleBoxFlat.new()
	button_style_normal.bg_color = Color(0.15, 0.15, 0.2, 0.9)
	button_style_normal.border_color = Color(0.3, 0.3, 0.4)
	button_style_normal.border_width_left = 2
	button_style_normal.border_width_top = 2
	button_style_normal.border_width_right = 2
	button_style_normal.border_width_bottom = 2
	button_style_normal.corner_radius_top_left = 8
	button_style_normal.corner_radius_top_right = 8
	button_style_normal.corner_radius_bottom_right = 8
	button_style_normal.corner_radius_bottom_left = 8
	
	var button_style_hover = button_style_normal.duplicate()
	button_style_hover.bg_color = Color(0.2, 0.2, 0.25, 0.95)
	button_style_hover.border_color = Color(0.4, 0.4, 0.5)
	
	var button_style_pressed = button_style_normal.duplicate()
	button_style_pressed.bg_color = Color(0.1, 0.1, 0.15, 0.9)
	button_style_pressed.border_color = Color(0.5, 0.4, 0.1)
	
	# Контейнер для кнопок
	var buttons_hbox = HBoxContainer.new()
	buttons_hbox.name = "ButtonsHBox"
	buttons_hbox.add_theme_constant_override("separation", 40)
	buttons_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_child(buttons_hbox)
	
	# Кнопка ДА
	yes_button = Button.new()
	yes_button.name = "YesButton"
	yes_button.text = "ДА, ОБУЧИТЬСЯ"
	yes_button.custom_minimum_size = Vector2(200, 60)
	yes_button.add_theme_font_size_override("font_size", 20)
	yes_button.add_theme_color_override("font_color", Color.WHITE)
	yes_button.add_theme_color_override("font_hover_color", Color(1, 0.9, 0.3))
	yes_button.add_theme_color_override("font_pressed_color", Color(1, 0.7, 0.1))
	yes_button.add_theme_stylebox_override("normal", button_style_normal)
	yes_button.add_theme_stylebox_override("hover", button_style_hover)
	yes_button.add_theme_stylebox_override("pressed", button_style_pressed)
	yes_button.pressed.connect(_on_yes_pressed)
	buttons_hbox.add_child(yes_button)
	print("✅ Кнопка ДА создана")
	
	# Кнопка НЕТ
	no_button = Button.new()
	no_button.name = "NoButton"
	no_button.text = "НЕТ, Я ПРОФИ"
	no_button.custom_minimum_size = Vector2(200, 60)
	no_button.add_theme_font_size_override("font_size", 20)
	no_button.add_theme_color_override("font_color", Color.WHITE)
	no_button.add_theme_color_override("font_hover_color", Color(1, 0.9, 0.3))
	no_button.add_theme_color_override("font_pressed_color", Color(1, 0.7, 0.1))
	no_button.add_theme_stylebox_override("normal", button_style_normal)
	no_button.add_theme_stylebox_override("hover", button_style_hover)
	no_button.add_theme_stylebox_override("pressed", button_style_pressed)
	no_button.pressed.connect(_on_no_pressed)
	buttons_hbox.add_child(no_button)
	print("✅ Кнопка НЕТ создана")
	
	# Подпись внизу
	var hint_label = Label.new()
	hint_label.name = "HintLabel"
	hint_label.text = "(Вы всегда можете пройти обучение позже в меню)"
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 16)
	hint_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	main_vbox.add_child(hint_label)
	print("✅ Подсказка создана")
	
	print("✅ Весь UI создан успешно!")

func _init_animation():
	print("🎬 Запуск анимации появления")
	
	# Начальные значения
	self.modulate.a = 0
	self.scale = Vector2(0.8, 0.8)
	
	# Анимация появления
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.5)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.4)
	
	print("✅ Анимация запущена")

func _on_yes_pressed():
	print("🎓 Игрок выбрал обучение")
	_close_with_choice(true)

func _on_no_pressed():
	print("⚡ Игрок пропускает обучение")
	_close_with_choice(false)

func _close_with_choice(choice: bool):
	print("🔄 Закрытие окна выбора")
	
	# Отключаем кнопки
	yes_button.disabled = true
	no_button.disabled = true
	
	# Анимация закрытия
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(0.8, 0.8), 0.3)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	
	await tween.finished
	
	print("📤 Отправка сигнала tutorial_selected с выбором:", choice)
	tutorial_selected.emit(choice)
	queue_free()
