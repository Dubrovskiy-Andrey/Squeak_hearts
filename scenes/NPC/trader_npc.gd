extends Area2D

# ---------------------- Параметры NPC ----------------------
var can_interact = false
@export var trade_window_scene: PackedScene
var trade_window = null
var dialog_active = false
var has_traded = false
var current_dialog = null  # Храним ссылку на текущий диалог

# ---------------------- Ready ----------------------
func _ready():
	print("🛒 NPC Торговец загружен")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# Подписка на сигналы Dialogic
	# В Dialogic 2.x это глобальный сигнал
	Dialogic.signal_event.connect(_on_dialogic_signal)

	if $Label:
		$Label.visible = false

# ---------------------- Physics Process ----------------------
func _physics_process(_delta):
	if $AnimatedSprite2D:
		$AnimatedSprite2D.play()
	
	# МОЖНО нажимать E если:
	# 1. Игрок в зоне
	# 2. Нажата E
	# 3. Нет активного диалога
	# 4. Нет открытого окна торговли
	if can_interact and Input.is_action_just_pressed("interact") and not dialog_active and trade_window == null:
		print("🎮 Кнопка E нажата — старт диалога")
		start_dialog()

# ---------------------- Взаимодействие ----------------------
func _on_body_entered(body):
	if body.is_in_group("players"):
		print("✅ Игрок вошел в зону")
		if $Label:
			$Label.visible = true
		can_interact = true

func _on_body_exited(body):
	if body.is_in_group("players"):
		print("✅ Игрок вышел из зоны")
		if $Label:
			$Label.visible = false
		can_interact = false

# ---------------------- Диалог ----------------------
func start_dialog():
	dialog_active = true
	
	var player = get_tree().get_first_node_in_group("players")
	if player and player.has_method("set_can_move"):
		player.set_can_move(false)
		print("🔒 Движение заблокировано на диалог")
	
	print("💬 Запускаем диалог trader_greeting_timeline...")
	
	# Dialogic.start() ВОЗВРАЩАЕТ уже готовую ноду, которую НЕ НАДО добавлять вручную
	# Dialogic сам управляет добавлением на сцену
	current_dialog = Dialogic.start("trader_greeting_timeline")
	
	# Подписываемся на сигналы диалога
	if current_dialog:
		if current_dialog.has_signal("timeline_end"):
			current_dialog.timeline_end.connect(_on_dialog_ended)
			print("📡 Подписались на timeline_end")
		elif current_dialog.has_signal("finished"):
			current_dialog.finished.connect(_on_dialog_ended)
			print("📡 Подписались на finished")
		
		if current_dialog.has_signal("tree_exited"):
			current_dialog.tree_exited.connect(_on_dialog_tree_exited)
			print("📡 Подписались на tree_exited")
	
	print("✅ Диалог запущен")

# ---------------------- Сигналы Dialogic ----------------------
func _on_dialogic_signal(signal_name: String):
	print("💬 Получен сигнал Dialogic (signal_event):", signal_name)

	match signal_name:
		"open_trade":
			print("🎮 Сигнал open_trade - открываем окно торговли")
			# Закрываем диалог перед открытием окна
			_close_current_dialog()
			open_trade_window()
		"close_trade", "no_trade":
			print("💬 Сигнал close_trade - игрок отказался от торговли")
			_close_current_dialog()
			_end_interaction()

# Сигнал когда диалог завершается
func _on_dialog_ended():
	print("💬 Диалог завершился (timeline_end/finished)")
	# Если диалог завершился без выбора
	if dialog_active:
		print("💬 Диалог завершился без выбора")
		_close_current_dialog()
		_end_interaction()

# Сигнал когда диалог удаляется со сцены
func _on_dialog_tree_exited():
	print("💬 Диалог удален со сцены (tree_exited)")
	# Сбрасываем ссылку
	current_dialog = null

# Функция для закрытия текущего диалога
func _close_current_dialog():
	if current_dialog and is_instance_valid(current_dialog):
		print("🗑️ Закрываем текущий диалог")
		current_dialog.queue_free()
		current_dialog = null

# ---------------------- Окно торговли ----------------------
func open_trade_window():
	if not trade_window_scene:
		print("❌ Нет сцены окна торговли!")
		_end_interaction()
		return
	
	if trade_window != null and is_instance_valid(trade_window):
		print("⚠️ Окно уже открыто!")
		return
	
	print("🔄 Создаем окно торговли...")
	trade_window = trade_window_scene.instantiate()
	get_tree().current_scene.add_child(trade_window)

	# Настройка данных игрока
	var player = get_tree().get_first_node_in_group("players")
	if player and trade_window.has_method("setup"):
		var player_data = {
			"currency": player.currency,
			"crystals": PlayerInventory.get_crystal_count() if PlayerInventory else 0,
			"player_node": player
		}
		print("📊 Передаем данные игрока:", player_data)
		trade_window.setup(player_data)

	# Подписка на закрытие окна
	if trade_window.has_signal("window_closed"):
		trade_window.connect("window_closed", Callable(self, "_on_trade_window_closed"))
	
	has_traded = true
	print("✅ Окно торговли открыто")

# ---------------------- Закрытие торговли ----------------------
func _on_trade_window_closed():
	print("🛒 Окно торговли закрыто по сигналу")
	trade_window = null
	_end_interaction()

# ---------------------- Завершение взаимодействия ----------------------
func _end_interaction():
	print("🔚 Завершаем взаимодействие с NPC")
	
	dialog_active = false
	_close_current_dialog()
	
	var player = get_tree().get_first_node_in_group("players")
	if player and player.has_method("set_can_move"):
		player.set_can_move(true)
		print("🔓 Движение разблокировано")
	
	# Разрешаем повторную торговлю
	has_traded = false
	
	# Сохраняем игру при выходе из торговли
	if save_system and player:
		save_system.save_game(player)
		print("💾 Игра сохранена при выходе из торговли")
	
	if can_interact and $Label:
		$Label.visible = true
