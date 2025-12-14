extends Area2D

var can_interact = false
@export var base_upgrade_cost: int = 50
@export var base_crystal_cost: int = 1
@export var health_bonus: int = 20
@export var damage_bonus: int = 5
@export var npc_name: String = "salli"

var upgrade_level: int = 0

func _ready():
	print("NPC Salli готов к работе")
	Dialogic.signal_event.connect(_on_dialogic_signal)
	load_upgrade_level()

func load_upgrade_level():
	if save_system:
		upgrade_level = save_system.get_npc_upgrade_level(npc_name)
		print("Загружен уровень прокачки для", npc_name, ":", upgrade_level)

func save_upgrade_level():
	if save_system:
		# Сохраняем уровень NPC
		save_system.set_npc_upgrade_level(npc_name, upgrade_level)
		print("Уровень прокачки сохранен:", upgrade_level)
		
		# Сохраняем игру полностью
		var player = get_tree().get_first_node_in_group("players")
		if player:
			save_system.save_game(player)

func _physics_process(_delta):
	$AnimatedSprite2D.play()
	if can_interact and Input.is_action_just_pressed("dialog"):
		update_dialogic_variables()
		Dialogic.start("salli_upgrade_timeline")

func update_dialogic_variables():
	var player = get_tree().get_first_node_in_group("players")
	if player:
		Dialogic.VAR.set('player_currency', player.currency)
		
		var crystal_count = 0
		if PlayerInventory:
			crystal_count = PlayerInventory.get_crystal_count()
		Dialogic.VAR.set('player_crystals', crystal_count)
		
		var current_currency_cost = calculate_currency_cost()
		var current_crystal_cost = calculate_crystal_cost()
		
		Dialogic.VAR.set('current_upgrade_cost', current_currency_cost)
		Dialogic.VAR.set('current_crystal_cost', current_crystal_cost)
		Dialogic.VAR.set('upgrade_level', upgrade_level)
		
		print("=== ДИАЛОГ NPC ===")
		print("Уровень прокачки:", upgrade_level)
		print("Стоимость:", current_currency_cost, "валюты +", current_crystal_cost, "кристаллов")

func calculate_currency_cost() -> int:
	return base_upgrade_cost + (upgrade_level * 25)

func calculate_crystal_cost() -> int:
	return base_crystal_cost + upgrade_level

func _on_body_entered(body):
	if body.is_in_group("players"):
		$Label.visible = true
		can_interact = true

func _on_body_exited(body):
	if body.is_in_group("players"):
		$Label.visible = false
		can_interact = false

func _on_dialogic_signal(argument: String):
	print("Получен сигнал от Dialogic:", argument)
	if argument == "buy_upgrade":
		try_apply_upgrade()

func try_apply_upgrade():
	var player = get_tree().get_first_node_in_group("players")
	if not player:
		print("Ошибка: игрок не найден!")
		return
	
	var currency_cost = calculate_currency_cost()
	var crystal_cost = calculate_crystal_cost()
	
	print("=== ПРОВЕРКА РЕСУРСОВ ===")
	print("Нужно валюты:", currency_cost, " | У игрока:", player.currency)
	print("Нужно кристаллов:", crystal_cost)
	
	if player.currency < currency_cost:
		print("❌ Недостаточно валюты!")
		return
	
	var has_enough_crystals = false
	if PlayerInventory:
		var current_crystals = PlayerInventory.get_crystal_count()
		print("Кристаллов у игрока:", current_crystals)
		if current_crystals >= crystal_cost:
			has_enough_crystals = true
		else:
			print("❌ Недостаточно кристаллов!")
			return
	else:
		print("Ошибка: PlayerInventory не найден!")
		return
	
	apply_upgrade(player, currency_cost, crystal_cost)

func apply_upgrade(player, currency_cost: int, crystal_cost: int):
	player.currency -= currency_cost
	player.emit_signal("currency_changed", player.currency)
	
	if PlayerInventory:
		PlayerInventory.spend_crystals(crystal_cost)
	
	player.max_health += health_bonus
	player.current_health += health_bonus
	player.attack_damage += damage_bonus
	
	upgrade_level += 1
	
	print("✅ УЛУЧШЕНИЕ ПРИМЕНЕНО!")
	print("Новый уровень:", upgrade_level)
	print("Потрачено:", currency_cost, "валюты и", crystal_cost, "кристаллов")
	print("Новые статы: HP=", player.max_health, " DMG=", player.attack_damage)
	
	player.emit_signal("health_changed", player.current_health, player.max_health)
	
	update_dialogic_variables()
	
	# СОХРАНЯЕМ УРОВЕНЬ И ИГРУ
	save_upgrade_level()
