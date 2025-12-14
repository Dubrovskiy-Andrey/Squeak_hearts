extends Area2D

var can_interact = false
@export var upgrade_cost: int = 50
@export var health_bonus: int = 20
@export var damage_bonus: int = 5

func _ready():
	print("NPC Salli готов к работе")
	Dialogic.signal_event.connect(_on_dialogic_signal)

func _physics_process(_delta):
	$AnimatedSprite2D.play()
	if can_interact and Input.is_action_just_pressed("dialog"):
		# ОБНОВЛЯЕМ ПЕРЕМЕННУЮ DIALOGIC ПЕРЕД ДИАЛОГОМ
		update_dialogic_currency()
		Dialogic.start("salli_upgrade_timeline")

func update_dialogic_currency():
	var player = get_tree().get_first_node_in_group("players")
	if player:
		# ПРАВИЛЬНЫЙ СПОСОБ установки переменной в Dialogic 2
		Dialogic.VAR.set('player_currency', player.currency)
		print("Установлена переменная Dialogic: player_currency = ", player.currency)

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
	
	# Двойная проверка (на всякий случай)
	if player.currency >= upgrade_cost:
		player.currency -= upgrade_cost
		player.emit_signal("currency_changed", player.currency)
		
		player.max_health += health_bonus
		player.current_health += health_bonus
		player.attack_damage += damage_bonus
		
		print("Улучшение применено! Здоровье: +", health_bonus, ", Урон: +", damage_bonus)
		
		player.emit_signal("health_changed", player.current_health, player.max_health)
		
		# ОБНОВЛЯЕМ ПЕРЕМЕННУЮ ПОСЛЕ ТРАТЫ
		Dialogic.VAR.set('player_currency', player.currency)
		
		if save_system:
			save_system.save_game(player)
			print("Прогресс сохранён!")
	else:
		print("Недостаточно валюты! (второй уровень проверки)")
