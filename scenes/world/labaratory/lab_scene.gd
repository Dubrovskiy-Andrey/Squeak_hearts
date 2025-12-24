extends Node2D

func _ready():
	print("🔬 Лабораторная сцена загружена")
	
	# ТОЛЬКО логируем состояние, НЕ создаем TutorialQuests здесь
	var save_sys = get_node_or_null("/root/save_system")
	
	if save_sys:
		var tutorial_data = save_sys.get_tutorial_data()
		var need_tutorial = tutorial_data.get("need_tutorial", true)
		var tutorial_skipped = tutorial_data.get("tutorial_skipped", false)
		var tutorial_completed = tutorial_data.get("tutorial_completed", false)
		
		print("🔬 Состояние обучения в лаборатории:")
		print("  - need_tutorial:", need_tutorial)
		print("  - tutorial_skipped:", tutorial_skipped)
		print("  - tutorial_completed:", tutorial_completed)
		
		if need_tutorial and not tutorial_skipped and not tutorial_completed:
			print("🎮 Обучение активно в этой сессии")
			# TutorialQuests должен быть уже создан как часть сцены
			
			# Проверяем, существует ли TutorialQuests
			var tutorial_node = get_tree().get_first_node_in_group("tutorial_quests")
			if tutorial_node:
				print("✅ TutorialQuests найден в сцене")
			else:
				print("⚠️ TutorialQuests НЕ найден в сцене!")
				# Это ОШИБКА - TutorialQuests должен быть частью префаба лаборатории
		elif tutorial_completed:
			print("✅ Обучение уже пройдено")
		else:
			print("🚀 Обучение не требуется или пропущено")
	else:
		print("⚠️ save_system не найден")
	
	# Всегда даем игроку возможность двигаться
	var player = get_tree().get_first_node_in_group("players")
	if player and player.has_method("set_can_move"):
		player.set_can_move(true)
		print("🎮 Движение игрока разрешено")
