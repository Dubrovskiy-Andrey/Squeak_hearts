extends CanvasLayer
class_name TutorialQuests

var quests_panel: Panel
var quests_container: VBoxContainer
var anim_player: AnimationPlayer
var timer: Timer
var started_from_manager = false

# Массив квестов с поддержкой сохранения прогресса
var tutorial_quests = [
	{
		"id": "move",
		"text": "Подвигайся: [A][D] и [ПРОБЕЛ] для прыжка",
		"required_inputs": ["ui_left", "ui_right", "ui_up"],
		"completed_inputs": {},
		"done": false,
		"type": "input"
	},
	{
		"id": "attack",
		"text": "Атакуй воздух: [ЛКМ] или [ПРОБЕЛ]",
		"required_count": 3,
		"current_count": 0,
		"done": false,
		"type": "counter"
	},
	{
		"id": "ability",
		"text": "Используй способность: [F]-ярость, [G]-скорость или [H]-лечение",
		"required_keys": ["damage_buff", "speed_buff", "heal_buff"],
		"done": false,
		"type": "input"
	},
	{
		"id": "talk_salli",
		"text": "Поговори с Salli (подойди и нажми E)",
		"npc_name": "salli",
		"done": false,
		"type": "npc"
	},
	{
		"id": "talk_trader",
		"text": "Поговори с Торговцем",
		"npc_name": "trader",
		"done": false,
		"type": "npc"
	},
	{
		"id": "arena",
		"text": "Найди костёр и начни арену",
		"target_object": "campfire",
		"done": false,
		"type": "object"
	}
]

var quest_items = {}
var player = null
var is_active = false
var lore_shown = false
var lore_panel = null
var ui_created = false

func _ready():
	layer = 50
	
	# Ждем загрузки save_system
	await get_tree().process_frame
	
	var save_sys = get_node_or_null("/root/save_system")
	if save_sys:
		# ЗАГРУЖАЕМ ПРОГРЕСС ИЗ СОХРАНЕНИЯ
		_load_tutorial_progress()
		
		var tutorial_data = save_sys.get_tutorial_data()
		var need_tutorial = tutorial_data.get("need_tutorial", true)
		var tutorial_skipped = tutorial_data.get("tutorial_skipped", false)
		var tutorial_completed = tutorial_data.get("tutorial_completed", false)
		
		print("📊 TutorialQuests: проверка состояния обучения")
		print("  - need_tutorial:", need_tutorial)
		print("  - tutorial_skipped:", tutorial_skipped)
		print("  - tutorial_completed:", tutorial_completed)
		print("  - lore_shown:", lore_shown)
		print("  - is_active:", is_active)
		
		# Проверяем, нужно ли загружать обучение
		if need_tutorial and not tutorial_skipped and not tutorial_completed:
			print("🎮 TutorialQuests: обучение требуется")
			
			# Ждем немного, чтобы все загрузилось
			await get_tree().create_timer(0.5).timeout
			
			# Проверяем, был ли уже показан лор
			if lore_shown:
				# Лор уже показан - создаем UI и восстанавливаем
				print("📖 Лор уже показан, создаем UI квестов")
				_create_ui()
				ui_created = true
				restore_from_save()
			else:
				# Обучение еще не начиналось
				print("🎮 TutorialQuests: запускаем обучение с нуля")
				start_tutorial()
		elif tutorial_completed:
			# Обучение уже завершено - СКРЫВАЕМ, но не удаляем!
			print("✅ Обучение уже пройдено, скрываем систему")
			visible = false  # Просто скрываем
			set_process(false)  # Отключаем обработку
			# НЕ queue_free() - оставляем в сцене!
		else:
			print("🚀 TutorialQuests: обучение не требуется, скрываем")
			visible = false
			set_process(false)
	else:
		print("⚠️ TutorialQuests: save_system не найден, скрываем")
		visible = false
		set_process(false)
	
	print("✅ TutorialQuests инициализирован")

func restore_from_save():
	"""Восстанавливает UI после загрузки сохранения"""
	print("🔄 TutorialQuests: восстановление из сохранения")
	
	# Восстанавливаем игрока
	player = get_tree().get_first_node_in_group("players")
	if not player:
		print("❌ Игрок не найден при восстановлении, пробуем через 1 секунду...")
		await get_tree().create_timer(1.0).timeout
		player = get_tree().get_first_node_in_group("players")
		if not player:
			print("❌ Игрок все еще не найден")
			return
	
	print("✅ Игрок найден при восстановлении:", player.name)
	
	# Создаем UI квестов
	_create_quest_ui()
	
	# Показываем панель квестов
	_show_quests_panel_silent()
	
	# Включаем обработку
	set_process(true)
	
	print("✅ UI квестов восстановлен")

func _create_ui():
	print("🛠️ Создание UI квестов через код...")
	_create_quests_panel()
	print("✅ Весь UI создан успешно!")
	ui_created = true

func _create_quests_panel():
	quests_panel = Panel.new()
	quests_panel.name = "QuestsPanel"
	quests_panel.visible = false
	
	quests_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	quests_panel.offset_left = -400
	quests_panel.offset_top = 20
	quests_panel.offset_right = -20
	quests_panel.offset_bottom = 370
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.05, 0.08, 0.85)
	panel_style.border_color = Color(1, 0.8, 0.2, 0.9)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.shadow_color = Color(0, 0, 0, 0.6)
	panel_style.shadow_size = 12
	panel_style.shadow_offset = Vector2(2, 2)
	quests_panel.add_theme_stylebox_override("panel", panel_style)
	
	add_child(quests_panel)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.name = "VBoxContainer"
	main_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_KEEP_SIZE, 12)
	main_vbox.add_theme_constant_override("separation", 12)
	quests_panel.add_child(main_vbox)
	
	var title_hbox = HBoxContainer.new()
	title_hbox.add_theme_constant_override("separation", 10)
	main_vbox.add_child(title_hbox)
	
	var icon = Label.new()
	icon.text = "🎯"
	icon.add_theme_font_size_override("font_size", 20)
	title_hbox.add_child(icon)
	
	var title = Label.new()
	title.name = "TitleLabel"
	title.text = "ЦЕЛИ ОБУЧЕНИЯ"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	title_hbox.add_child(title)
	
	var separator = HSeparator.new()
	separator.add_theme_constant_override("separation", 8)
	main_vbox.add_child(separator)
	
	var scroll_container = ScrollContainer.new()
	scroll_container.custom_minimum_size = Vector2(0, 250)
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(scroll_container)
	
	quests_container = VBoxContainer.new()
	quests_container.name = "QuestItems"
	quests_container.add_theme_constant_override("separation", 10)
	quests_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.add_child(quests_container)
	
	print("✅ Панель квестов создана (справа сверху)")

func start_tutorial():
	if is_active:
		print("⚠️ Обучение уже активно")
		return
	
	print("🎮 Начинаем квестовое обучение, is_active =", is_active)
	is_active = true
	
	player = get_tree().get_first_node_in_group("players")
	if not player:
		print("❌ Игрок не найден, пробуем через 1 секунду...")
		await get_tree().create_timer(1.0).timeout
		player = get_tree().get_first_node_in_group("players")
		if not player:
			print("❌ Игрок все еще не найден, отменяем обучение")
			is_active = false
			return
	
	print("✅ Игрок найден:", player.name)
	
	# Создаем UI
	if not ui_created:
		_create_ui()
	
	if player.has_method("set_can_move"):
		player.set_can_move(false)
	
	show_lore()

func show_lore():
	print("📖 Показываем лор игры...")
	
	# Проверяем, не был ли лор уже показан
	if lore_shown:
		print("📖 Лор уже был показан ранее, пропускаем")
		_on_lore_continue_pressed()
		return
	
	lore_panel = Panel.new()
	lore_panel.name = "LorePanel"
	lore_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var lore_panel_style = StyleBoxFlat.new()
	lore_panel_style.bg_color = Color(0, 0, 0, 0.97)
	lore_panel.add_theme_stylebox_override("panel", lore_panel_style)
	
	add_child(lore_panel)
	
	var rich_label = RichTextLabel.new()
	rich_label.bbcode_enabled = true
	
	var lore_text = """[center][color=white][font_size=32]ДОБРО ПОЖАЛОВАТЬ В ЛАБОРАТОРИЮ![/font_size]

[font_size=26]Ты — экспериментальный образец мыши-солдата.
Твоя миссия — защищать СЫРНЫЙ МОНОЛИТ от врагов.

В этой лаборатории ты можешь:
• [color=yellow]Прокачиваться[/color] у Salli
• [color=yellow]Покупать снаряжение[/color] у Торговца  
• [color=yellow]Тренироваться[/color] на Арене

Твои способности:
• [color=red][F] - Ярость: увеличивает урон[/color]
• [color=cyan][G] - Ускорение: увеличивает скорость[/color]
• [color=green][H] - Лечение: восстанавливает здоровье[/color]

Но будь осторожен — враги уже на подходе...[/font_size][/color][/center]"""
	
	rich_label.text = lore_text
	rich_label.fit_content = true
	rich_label.scroll_active = false
	
	var main_container = VBoxContainer.new()
	var screen_size = get_viewport().size
	main_container.position = Vector2(
		screen_size.x / 2 - 350,
		screen_size.y / 2 - 250
	)
	main_container.size = Vector2(800, 600)
	main_container.add_theme_constant_override("separation", 40)
	lore_panel.add_child(main_container)
	
	main_container.add_child(rich_label)
	
	var continue_button = Button.new()
	continue_button.text = "ПОНЯЛ, ПОЕХАЛИ!"
	continue_button.custom_minimum_size = Vector2(250, 60)
	continue_button.add_theme_font_size_override("font_size", 22)
	continue_button.add_theme_color_override("font_color", Color.WHITE)
	continue_button.add_theme_color_override("font_hover_color", Color(1, 1, 0.8))
	continue_button.add_theme_color_override("font_pressed_color", Color(1, 0.8, 0.6))
	
	var button_container = HBoxContainer.new()
	button_container.add_theme_constant_override("separation", 0)
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color(0.25, 0.25, 0.4)
	button_style.border_color = Color(1, 0.9, 0.3)
	button_style.border_width_left = 3
	button_style.border_width_top = 3
	button_style.border_width_right = 3
	button_style.border_width_bottom = 3
	button_style.corner_radius_top_left = 12
	button_style.corner_radius_top_right = 12
	button_style.corner_radius_bottom_right = 12
	button_style.corner_radius_bottom_left = 12
	
	var button_hover = button_style.duplicate()
	button_hover.bg_color = Color(0.35, 0.35, 0.5)
	button_hover.border_color = Color(1, 1, 0.5)
	
	var button_pressed = button_style.duplicate()
	button_pressed.bg_color = Color(0.15, 0.15, 0.3)
	button_pressed.border_color = Color(1, 0.8, 0.2)
	
	continue_button.add_theme_stylebox_override("normal", button_style)
	continue_button.add_theme_stylebox_override("hover", button_hover)
	continue_button.add_theme_stylebox_override("pressed", button_pressed)
	continue_button.pressed.connect(_on_lore_continue_pressed)
	
	button_container.add_child(continue_button)
	main_container.add_child(button_container)
	
	rich_label.modulate.a = 0
	continue_button.modulate.a = 0
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(rich_label, "modulate:a", 1.0, 1.5)
	tween.tween_property(continue_button, "modulate:a", 1.0, 1.5).set_delay(0.5)
	
	print("✅ Лор показан (текст сдвинут влево и выше через position)")

func _on_lore_continue_pressed():
	print("📖 Лор прочитан")
	lore_shown = true
	
	# Сохраняем, что лор был показан
	_save_tutorial_progress()
	
	if lore_panel:
		var tween = create_tween()
		tween.tween_property(lore_panel, "modulate:a", 0.0, 0.5)
		await tween.finished
		lore_panel.queue_free()
		lore_panel = null
	
	_create_quest_ui()
	_show_quests_panel()
	
	if player and player.has_method("set_can_move"):
		player.set_can_move(true)

func _create_quest_ui():
	for child in quests_container.get_children():
		child.queue_free()
	
	quest_items.clear()
	
	for quest in tutorial_quests:
		var quest_item = _create_quest_item(quest)
		quests_container.add_child(quest_item)
		quest_items[quest["id"]] = quest_item
	
	print("✅ UI целей создан")

func _create_quest_item(quest):
	var hbox = HBoxContainer.new()
	hbox.name = "Quest_" + quest["id"]
	hbox.add_theme_constant_override("separation", 12)
	hbox.custom_minimum_size = Vector2(0, 40)
	
	var checkbox = Label.new()
	checkbox.name = "Checkbox"
	if quest["done"]:
		checkbox.text = "✅"
		checkbox.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
	else:
		checkbox.text = "⬜"
	checkbox.add_theme_font_size_override("font_size", 20)
	checkbox.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	checkbox.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	checkbox.custom_minimum_size = Vector2(30, 30)
	hbox.add_child(checkbox)
	
	var label = Label.new()
	label.name = "Text"
	
	# Формируем текст с учетом прогресса
	var display_text = quest["text"]
	if quest["id"] == "attack" and quest["current_count"] > 0:
		display_text = quest["text"] + " (" + str(quest["current_count"]) + "/" + str(quest["required_count"]) + ")"
	
	label.text = display_text
	
	if quest["done"]:
		label.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7))
	else:
		label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	
	label.add_theme_font_size_override("font_size", 16)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(label)
	
	return hbox

func _show_quests_panel():
	quests_panel.visible = true
	quests_panel.modulate.a = 0
	quests_panel.position.x = get_viewport().size.x + 20
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(quests_panel, "position:x",
		get_viewport().size.x - quests_panel.size.x - 20,
		0.6
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(quests_panel, "modulate:a", 1.0, 0.4)
	
	await tween.finished
	_play_panel_attention_animation()
	
	print("🎯 Цели обучения показаны (справа сверху)")

func _show_quests_panel_silent():
	"""Показывает панель квестов без анимации (для восстановления)"""
	quests_panel.visible = true
	quests_panel.modulate.a = 1.0
	quests_panel.position.x = get_viewport().size.x - quests_panel.size.x - 20
	print("🎯 Цели обучения восстановлены (без анимации)")

func _play_panel_attention_animation():
	var tween = create_tween()
	tween.set_loops(2)
	tween.tween_property(quests_panel, "scale", Vector2(1.02, 1.02), 0.1)
	tween.tween_property(quests_panel, "scale", Vector2(1.0, 1.0), 0.1)

func _process(delta):
	if not is_active or not player or not lore_shown:
		return
	
	_check_quest_progress()

func _check_quest_progress():
	for quest in tutorial_quests:
		if quest["done"]:
			continue
		
		match quest["id"]:
			"move":
				_check_movement_quest(quest)
			"attack":
				_check_attack_quest(quest)
			"ability":
				_check_ability_quest(quest)

func _check_movement_quest(quest):
	for input_action in quest.get("required_inputs", []):
		if Input.is_action_just_pressed(input_action):
			quest["completed_inputs"][input_action] = true
			# Сохраняем прогресс после каждого действия
			_save_tutorial_progress()
	
	if quest["completed_inputs"].size() >= quest["required_inputs"].size():
		_complete_quest(quest["id"])

func _check_attack_quest(quest):
	if Input.is_action_just_pressed("attack"):
		quest["current_count"] += 1
		
		var quest_item = quest_items.get(quest["id"])
		if quest_item:
			var label = quest_item.get_node("Text")
			if label:
				label.text = quest["text"] + " (" + str(quest["current_count"]) + "/" + str(quest["required_count"]) + ")"
		
		# Сохраняем прогресс после каждой атаки
		_save_tutorial_progress()
		
		if quest["current_count"] >= quest["required_count"]:
			_complete_quest(quest["id"])

func _check_ability_quest(quest):
	# Проверяем нажатие любой из способностей: F (damage_buff), G (speed_buff), H (heal_buff)
	for action in quest.get("required_keys", []):
		if Input.is_action_just_pressed(action):
			print("🎮 Использована способность: ", action)
			_complete_quest(quest["id"])
			return

func _complete_quest(quest_id):
	print("🎯 _complete_quest вызван для: ", quest_id)
	
	var quest_index = -1
	for i in range(tutorial_quests.size()):
		if tutorial_quests[i]["id"] == quest_id:
			quest_index = i
			break
	
	if quest_index == -1:
		print("❌ Квест не найден в массиве: ", quest_id)
		return
	
	var quest = tutorial_quests[quest_index]
	
	if quest["done"]:
		print("⚠️ Квест уже выполнен: ", quest_id)
		return
	
	print("✅ Отмечаем квест как выполненный: ", quest_id)
	quest["done"] = true
	
	# СОХРАНЯЕМ ПРОГРЕСС ПРИ ЗАВЕРШЕНИИ КВЕСТА
	_save_tutorial_progress()
	
	var quest_item = quest_items.get(quest_id)
	if quest_item:
		print("🔄 Найден UI элемент, обновляем...")
		var checkbox = quest_item.get_node("Checkbox")
		if checkbox:
			checkbox.text = "✅"
			checkbox.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
			print("✅ Чекбокс обновлен")
		
		var label = quest_item.get_node("Text")
		if label:
			label.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7))
			print("✅ Текст обновлен")
	else:
		print("❌ UI элемент не найден! quest_items keys: ", quest_items.keys())
	
	print("✅ Цель выполнена: ", quest_id)
	_check_all_quests_completed()

func _check_all_quests_completed():
	var all_done = true
	for quest in tutorial_quests:
		if not quest["done"]:
			all_done = false
			break
	
	if all_done:
		print("🎉 Все цели обучения выполнены!")
		_finish_tutorial()

func _finish_tutorial():
	print("🏁 Обучение завершено")
	is_active = false
	
	_give_tutorial_reward()
	
	var tween = create_tween()
	tween.tween_property(quests_panel, "position:x", -420, 0.5)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(quests_panel, "modulate:a", 0.0, 0.3)
	
	await tween.finished
	quests_panel.visible = false
	
	var save_sys = get_node_or_null("/root/save_system")
	if save_sys:
		save_sys.set_tutorial_completed(true)
		save_sys.set_need_tutorial(false)
		# Также сохраняем окончательный прогресс
		_save_tutorial_progress()
		print("💾 Прогресс обучения сохранен (завершено)")
	
	await get_tree().create_timer(1.0).timeout
	queue_free()

func _give_tutorial_reward():
	if player:
		# 1. Валюта
		if player.has_method("add_currency"):
			player.add_currency(200)
			print("💰 Награда: +200 валюты (через add_currency)")
		else:
			# Альтернативные способы проверки наличия свойства
			if "currency" in player:
				player.currency += 200
				print("💰 Награда: +200 валюты (через свойство currency)")
			elif "coins" in player:
				player.coins += 200
				print("💰 Награда: +200 монет (через свойство coins)")
			else:
				print("⚠️ Не найдено свойство для валюты у игрока")
			
			# Проверяем наличие сигнала
			if player.has_signal("currency_changed"):
				player.emit_signal("currency_changed", player.currency if "currency" in player else 0)
			elif player.has_signal("coins_changed"):
				player.emit_signal("coins_changed", player.coins if "coins" in player else 0)
		
		# 2. Сообщение
		_show_reward_message("🎉 ОБУЧЕНИЕ ПРОЙДЕНО!\n+200 валюты")
		
		# 3. Сохраняем игру
		var save_sys = get_node_or_null("/root/save_system")
		if save_sys:
			save_sys.save_game(player)
			print("💾 Игра сохранена после награды")
		
		print("✅ Награда выдана")

func _show_reward_message(text):
	print("🎉 Показываем сообщение о награде:", text)
	
	# Получаем камеру или позицию игрока для ориентира
	var reference_position = Vector2.ZERO
	var camera = null
	
	if player:
		# Ищем камеру
		for child in player.get_children():
			if child is Camera2D:
				camera = child
				break
		
		if camera:
			reference_position = camera.global_position
			print("🎥 Используем позицию камеры:", reference_position)
		else:
			reference_position = player.global_position
			print("🎮 Используем позицию игрока:", reference_position)
	else:
		# Центр экрана
		var viewport = get_viewport().get_visible_rect().size
		reference_position = viewport / 2
		print("📺 Используем центр экрана:", reference_position)
	
	# Создаем сообщение
	var message = Label.new()
	message.text = text
	
	# Позиционируем ЛЕВЕЕ центра (смещаем по X влево)
	# -370 по X = левее на 370 пикселей
	# -200 по Y = выше на 200 пикселей
	message.position = reference_position + Vector2(-420, -400)
	
	# Добавляем к корневой сцене
	get_tree().current_scene.add_child(message)
	
	# Стиль как в арене
	message.add_theme_font_size_override("font_size", 42)
	message.add_theme_color_override("font_color", Color(1, 0.9, 0.2))  # Золотой цвет
	message.add_theme_constant_override("outline_size", 6)
	message.add_theme_color_override("font_outline_color", Color.BLACK)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Добавляем фон для лучшей читаемости
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0, 0, 0, 0.7)
	bg_style.border_color = Color(1, 0.8, 0.2)
	bg_style.border_width_left = 2
	bg_style.border_width_top = 2
	bg_style.border_width_right = 2
	bg_style.border_width_bottom = 2
	bg_style.corner_radius_top_left = 8
	bg_style.corner_radius_top_right = 8
	bg_style.corner_radius_bottom_right = 8
	bg_style.corner_radius_bottom_left = 8
	message.add_theme_stylebox_override("normal", bg_style)
	
	# Настройки отступов
	message.size = Vector2(400, 80)  # Фиксированный размер
	
	# Анимация - только поднятие вверх и исчезновение
	message.modulate.a = 1.0  # Сразу видимое
	message.scale = Vector2(1.0, 1.0)  # Нормальный размер
	
	var tween = create_tween()
	
	# 1. Подъем вверх на 80 пикселей за 1.2 секунды
	tween.tween_property(message, "position:y", message.position.y - 80, 1.2)
	
	# 2. Исчезновение через 0.5 секунды
	tween.parallel().tween_property(message, "modulate:a", 0.0, 1.0).set_delay(0.5)
	
	# Удаление через время
	await get_tree().create_timer(2.5).timeout
	if is_instance_valid(message):
		message.queue_free()
	print("✅ Сообщение о награде скрыто")

func complete_npc_quest(npc_name: String) -> bool:
	print("🎯 complete_npc_quest для NPC: ", npc_name)
	
	# Просто ищем квест с таким именем NPC
	for quest in tutorial_quests:
		if "npc_name" in quest and quest["npc_name"] == npc_name:
			if not quest["done"]:
				print("✅ Найден квест для ", npc_name, ": ", quest["id"])
				_complete_quest(quest["id"])
				return true
			else:
				print("⚠️ Квест для ", npc_name, " уже выполнен")
	
	print("❌ Не найден квест для NPC: ", npc_name)
	return false

func complete_object_quest(object_name: String) -> bool:
	for quest in tutorial_quests:
		if quest.has("target_object") and quest["target_object"] == object_name and not quest["done"]:
			print("✅ Объектный квест выполнен:", object_name)
			_complete_quest(quest["id"])
			return true
	return false

func get_player():
	return player

func is_tutorial_active() -> bool:
	return is_active

func get_active_quests() -> Array:
	var active = []
	for quest in tutorial_quests:
		if not quest["done"]:
			active.append(quest)
	return active

func is_quest_completed(quest_id: String) -> bool:
	for quest in tutorial_quests:
		if quest["id"] == quest_id:
			return quest["done"]
	return false

func debug_complete_all_quests():
	print("🔧 Отладка: завершение всех квестов")
	for quest in tutorial_quests:
		if not quest["done"]:
			quest["done"] = true
			_complete_quest(quest["id"])

# ==================== МЕТОДЫ ДЛЯ СОХРАНЕНИЯ ПРОГРЕССА ====================

func _save_tutorial_progress():
	"""Сохраняет прогресс обучения в save_system"""
	var save_sys = get_node_or_null("/root/save_system")
	if not save_sys:
		print("❌ save_system не найден для сохранения прогресса")
		return
	
	# Собираем состояние квестов
	var quests_completed = {}
	var quests_progress = {}
	
	for quest in tutorial_quests:
		quests_completed[quest["id"]] = quest["done"]
		
		# Сохраняем прогресс для квестов со счетчиками
		if quest.has("current_count"):
			quests_progress[quest["id"]] = {
				"current_count": quest["current_count"]
			}
		# Сохраняем введенные клавиши для движения
		elif quest.has("completed_inputs"):
			quests_progress[quest["id"]] = {
				"completed_inputs": quest["completed_inputs"]
			}
	
	var tutorial_state = {
		"tutorial_completed": false,  # Будет true только когда все квесты завершены
		"need_tutorial": true,
		"tutorial_skipped": false,
		"quests_completed": quests_completed,
		"quests_progress": quests_progress,
		"is_active": is_active,
		"lore_shown": lore_shown
	}
	
	save_sys.save_data["tutorial_data"] = tutorial_state
	print("💾 Прогресс обучения сохранен")

func _load_tutorial_progress():
	"""Загружает прогресс обучения из save_system"""
	var save_sys = get_node_or_null("/root/save_system")
	if not save_sys:
		print("❌ save_system не найден для загрузки прогресса")
		return
	
	var tutorial_data = save_sys.get_tutorial_data()
	print("📂 Загружаем данные обучения:", tutorial_data)
	
	# Восстанавливаем глобальные флаги
	lore_shown = tutorial_data.get("lore_shown", false)
	is_active = tutorial_data.get("is_active", false)
	
	# Восстанавливаем состояние квестов
	var quests_completed = tutorial_data.get("quests_completed", {})
	var quests_progress = tutorial_data.get("quests_progress", {})
	
	for i in range(tutorial_quests.size()):
		var quest = tutorial_quests[i]
		var quest_id = quest["id"]
		
		# Восстанавливаем статус выполнения
		if quest_id in quests_completed:
			tutorial_quests[i]["done"] = quests_completed[quest_id]
		
		# Восстанавливаем прогресс
		if quest_id in quests_progress:
			var progress = quests_progress[quest_id]
			
			if tutorial_quests[i].has("current_count") and "current_count" in progress:
				tutorial_quests[i]["current_count"] = progress["current_count"]
			
			if tutorial_quests[i].has("completed_inputs") and "completed_inputs" in progress:
				tutorial_quests[i]["completed_inputs"] = progress["completed_inputs"].duplicate()
	
	print("✅ Прогресс обучения загружен")
	print("📊 Состояние после загрузки:")
	for quest in tutorial_quests:
		print("  -", quest["id"], ":", quest["done"], 
			" (прогресс:", quest.get("current_count", 0), 
			" вводы:", quest.get("completed_inputs", {}).size(), ")")

func get_tutorial_state() -> Dictionary:
	"""Возвращает текущее состояние обучения для сохранения"""
	var quests_completed = {}
	var quests_progress = {}
	
	for quest in tutorial_quests:
		quests_completed[quest["id"]] = quest["done"]
		
		if quest.has("current_count"):
			quests_progress[quest["id"]] = {
				"current_count": quest["current_count"]
			}
		elif quest.has("completed_inputs"):
			quests_progress[quest["id"]] = {
				"completed_inputs": quest["completed_inputs"].duplicate()
			}
	
	return {
		"tutorial_completed": false,
		"need_tutorial": true,
		"tutorial_skipped": false,
		"quests_completed": quests_completed,
		"quests_progress": quests_progress,
		"is_active": is_active,
		"lore_shown": lore_shown
	}
