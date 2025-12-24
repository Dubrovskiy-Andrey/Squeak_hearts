extends Node2D  # Или какой у вас корневой узел в lab_scene.tscn

func _ready():
	print("🔬 Лабораторная сцена загружена")
	
	# Проверяем, нужно ли запускать обучение
	var save_sys = get_node_or_null("/root/save_system")
	
	if save_sys:
		var player_data = save_sys.get_player_data()
		var need_tutorial = player_data.get("need_tutorial", false)
		var tutorial_skipped = player_data.get("tutorial_skipped", false)
		
		print("📊 Состояние обучения:")
		print("  - need_tutorial:", need_tutorial)
		print("  - tutorial_skipped:", tutorial_skipped)
		print("  - tutorial_completed:", player_data.get("tutorial_completed", false))
		
		if need_tutorial and not tutorial_skipped:
			print("🎮 Запускаем обучение...")
		else:
			print("🚀 Обучение не требуется, начинаем обычную игру")
	else:
		print("⚠️ Система сохранения не найдена")
