extends Area2D

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hint_label: Label = get_node_or_null("Label")

var player_in_range: bool = false
var can_interact: bool = true
var original_scale: Vector2 = Vector2.ONE
var tutorial_quest_completed: bool = false
var all_prerequisite_quests_done: bool = false  # Флаг проверки всех обязательных квестов

func _ready():
	original_scale = sprite.scale
	print("🔥 Оригинальный размер костра:", original_scale)
	
	anim_player.play("Idle")
	
	if hint_label:
		hint_label.visible = false
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	print("🔥 Костер-арена готов. Нажми E для входа на арену")

func _on_body_entered(body):
	if body.is_in_group("players"):
		player_in_range = true
		
		# Проверяем выполнены ли все предыдущие квесты
		_check_prerequisite_quests()
		
		if hint_label:
			if all_prerequisite_quests_done:
				hint_label.text = "Нажми E для входа на арену"
				hint_label.modulate = Color(1, 1, 1)  # Нормальный цвет
			else:
				hint_label.text = "❌ Сначала выполните все квесты"
				hint_label.modulate = Color(1, 0.3, 0.3)  # Красный цвет
			hint_label.visible = true
		
		# Меняем визуал в зависимости от доступности
		if sprite:
			if all_prerequisite_quests_done:
				sprite.modulate = Color(1.2, 1.2, 1.0)  # Яркий
			else:
				sprite.modulate = Color(0.7, 0.7, 0.7)  # Тусклый
		
		if anim_player:
			if all_prerequisite_quests_done:
				anim_player.speed_scale = 1.5  # Быстрая анимация
			else:
				anim_player.speed_scale = 0.5  # Медленная анимация

func _on_body_exited(body):
	if body.is_in_group("players"):
		player_in_range = false
		
		if hint_label:
			hint_label.visible = false
		
		# Возвращаем обычный цвет и скорость анимации
		if sprite:
			sprite.modulate = Color(1, 1, 1)
		
		if anim_player:
			anim_player.speed_scale = 1.0

func _input(event):
	if event.is_action_pressed("interact") and player_in_range and can_interact:
		# Проверяем перед входом на арену
		if not all_prerequisite_quests_done:
			print("❌ Нельзя войти на арену: не все квесты выполнены")
			show_notification("❌ Сначала выполните все квесты обучения!", Color(1, 0.3, 0.3))
			return
		enter_arena()

func _check_prerequisite_quests():
	"""Проверяем, выполнены ли все квесты кроме арены"""
	var tutorial_quests = get_tree().get_first_node_in_group("tutorial_quests")
	if not tutorial_quests:
		tutorial_quests = get_tree().current_scene.get_node_or_null("TutorialQuests")
	
	if tutorial_quests and tutorial_quests.has_method("is_tutorial_active"):
		if tutorial_quests.is_tutorial_active():
			# Получаем список всех квестов кроме арены, теперь включая ability
			var required_quests = ["move", "attack", "ability", "talk_salli", "talk_trader"]
			var completed_count = 0
			
			for quest_id in required_quests:
				if tutorial_quests.has_method("is_quest_completed"):
					if tutorial_quests.is_quest_completed(quest_id):
						completed_count += 1
						print("✅ Квест выполнен:", quest_id)
					else:
						print("❌ Квест не выполнен:", quest_id)
				else:
					print("⚠️ TutorialQuests не имеет метода is_quest_completed")
			
			# Проверяем, все ли выполнены
			if completed_count >= required_quests.size():
				all_prerequisite_quests_done = true
				print("✅ Все обязательные квесты выполнены! Можно войти на арену")
			else:
				all_prerequisite_quests_done = false
				print("⚠️ Выполнено", completed_count, "из", required_quests.size(), "квестов")
		else:
			print("⚠️ Обучение не активнo, пропускаем проверку")
			all_prerequisite_quests_done = true  # Если обучение не активно, разрешаем вход
	else:
		print("⚠️ TutorialQuests не найден, пропускаем проверку")
		all_prerequisite_quests_done = true  # Если нет TutorialQuests, разрешаем вход

func enter_arena():
	if not player_in_range or not can_interact or not all_prerequisite_quests_done:
		return
	
	print("🔥 Активация арены через костёр")
	can_interact = false
	
	# ✅ ЗАВЕРШАЕМ КВЕСТ ОБУЧЕНИЯ (только один раз)
	if not tutorial_quest_completed:
		complete_tutorial_quest()
	
	# 1. Яркий эффект активации
	if sprite:
		sprite.modulate = Color(1.5, 0.8, 0.4)
	
	# 2. Быстрая анимация
	if anim_player:
		anim_player.speed_scale = 2.0
	
	# 3. Обновляем подсказку
	if hint_label:
		hint_label.text = "Переходим на арену.."
	
	# 4. Восстанавливаем игрока
	var player = get_tree().get_first_node_in_group("players")
	if player:
		if player.has_method("restore_all_cheese_to_full"):
			player.restore_all_cheese_to_full()
			print("🧀 Сыр восстановлен до полного")
		
		if player.has_method("heal_to_full"):
			player.heal_to_full()
			print("❤️ Здоровье восстановлено до максимума")
		
		if player.has_method("save_without_restore"):
			player.save_without_restore()
			print("💾 Игра сохранена перед ареной")
	
	# 5. Показываем сообщение о завершении квеста (если было)
	if tutorial_quest_completed:
		show_quest_complete_message()
	
	# 6. Ждем немного для эффекта
	await get_tree().create_timer(1.0).timeout
	
	# 7. Переход на арену
	print("🚀 Переход на арену...")
	TransitionManager.change_scene_with_fade("res://scenes/arena_scene.tscn", 0.5, 0.3)
	
	# 8. Возвращаем возможность взаимодействия
	can_interact = true

func complete_tutorial_quest():
	"""Завершаем квест обучения 'найди костёр'"""
	var tutorial_quests = get_tree().get_first_node_in_group("tutorial_quests")
	if not tutorial_quests:
		tutorial_quests = get_tree().current_scene.get_node_or_null("TutorialQuests")
	
	if tutorial_quests and tutorial_quests.has_method("is_tutorial_active"):
		if tutorial_quests.is_tutorial_active():
			print("🔥 Завершаем квест обучения: найди костёр и начни арену")
			if tutorial_quests.has_method("complete_object_quest"):
				if tutorial_quests.complete_object_quest("campfire"):
					print("✅ Квест 'арена' успешно завершен")
					tutorial_quest_completed = true
					
					# СОХРАНЯЕМ ИГРУ ПОСЛЕ ВЫПОЛНЕНИЯ КВЕСТА
					var save_sys = get_node_or_null("/root/save_system")
					if save_sys:
						# Сохраняем прогресс обучения
						if tutorial_quests.has_method("_save_tutorial_progress"):
							tutorial_quests._save_tutorial_progress()
						# Сохраняем игру
						var player = get_tree().get_first_node_in_group("players")
						if player:
							save_sys.save_game(player)
				else:
					print("⚠️ Квест 'арена' не был найден или уже выполнен")
			else:
				print("⚠️ TutorialQuests не имеет метода complete_object_quest")
		else:
			print("⚠️ Обучение не активно, квест не завершаем")
	else:
		print("⚠️ TutorialQuests не найден")

func show_notification(text: String, color: Color = Color.WHITE):
	"""Показывает уведомление рядом с костром"""
	var notification = Label.new()
	notification.text = text
	notification.position = global_position + Vector2(-100, -100)
	get_parent().add_child(notification)
	
	notification.add_theme_color_override("font_color", color)
	notification.add_theme_font_size_override("font_size", 20)
	notification.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var tween = create_tween()
	tween.tween_property(notification, "position:y", notification.position.y - 50, 1.0)
	tween.parallel().tween_property(notification, "modulate:a", 0, 1.5)
	
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(notification):
		notification.queue_free()

func show_quest_complete_message():
	"""Показываем сообщение о завершении квеста"""
	var message = Label.new()
	message.text = "✅ Квест 'Найди костёр' выполнен!"
	message.position = global_position + Vector2(-100, -150)
	get_parent().add_child(message)
	
	message.add_theme_font_size_override("font_size", 20)
	message.add_theme_color_override("font_color", Color(0.3, 1, 0.3))
	
	var tween = create_tween()
	tween.tween_property(message, "position:y", message.position.y - 50, 1.0)
	tween.parallel().tween_property(message, "modulate:a", 0, 1.5)
	
	await get_tree().create_timer(2.0).timeout
	message.queue_free()

# ВАЖНО: фиксируем scale каждый кадр на оригинальном значении
func _process(delta):
	sprite.scale = original_scale
	
