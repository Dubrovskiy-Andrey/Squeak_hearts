extends Node2D

func _ready():
	var save_sys = get_node_or_null("/root/save_system")
	
	if save_sys:
		var tutorial_data = save_sys.get_tutorial_data()
		var need_tutorial = tutorial_data.get("need_tutorial", true)
		var tutorial_skipped = tutorial_data.get("tutorial_skipped", false)
		var tutorial_completed = tutorial_data.get("tutorial_completed", false)
		
		if need_tutorial and not tutorial_skipped and not tutorial_completed:
			var tutorial_node = get_tree().get_first_node_in_group("tutorial_quests")
			if tutorial_node:
				print("✅ TutorialQuests найден в сцене")
			else:
				print("⚠️ TutorialQuests НЕ найден в сцене!")
		elif tutorial_completed:
			print("✅ Обучение уже пройдено")
		else:
			print("🚀 Обучение не требуется или пропущено")
	else:
		print("⚠️ save_system не найден")
	var player = get_tree().get_first_node_in_group("players")
	if player and player.has_method("set_can_move"):
		player.set_can_move(true)
