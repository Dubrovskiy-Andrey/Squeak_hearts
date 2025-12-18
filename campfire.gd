extends Area2D

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hint_label: Label = get_node_or_null("Label")

var player_in_range: bool = false
var can_interact: bool = true

@export var campfire_id: String = "campfire_1"

func _ready():
	anim_player.play("Idle")
	
	if hint_label:
		hint_label.visible = false
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("players"):
		player_in_range = true
		
		if hint_label:
			hint_label.text = "Нажми E для сохранения и восстановления"
			hint_label.visible = true

func _on_body_exited(body):
	if body.is_in_group("players"):
		player_in_range = false
		
		if hint_label:
			hint_label.visible = false

func _input(event):
	if (event.is_action_pressed("interact") and 
		player_in_range and 
		can_interact and
		not event.is_echo()):
		
		interact_with_campfire()

func interact_with_campfire():
	if not player_in_range or not can_interact:
		return
	
	print("🔥 Взаимодействие с костром")
	can_interact = false
	
	show_interaction_effect()
	heal_player()
	restore_player_cheese()
	save_and_restore_at_campfire()
	
	await get_tree().create_timer(0.5).timeout
	
	print("🔄 ПЕРЕЗАГРУЗКА локации...")
	
	# Перезагружаем сцену
	get_tree().reload_current_scene()

func heal_player():
	var players = get_tree().get_nodes_in_group("players")
	if players.size() > 0:
		var player = players[0]
		if player.has_method("heal"):
			player.heal(player.max_health)
			print("❤️ Игрок исцелён у костра")

func restore_player_cheese():
	var players = get_tree().get_nodes_in_group("players")
	if players.size() > 0:
		var player = players[0]
		if player.has_method("restore_all_cheese"):
			player.restore_all_cheese()
			print("🧀 Сыр игрока восстановлен у костра")

func save_and_restore_at_campfire():
	print("💾 Сохранение и восстановление у костра...")
	
	var players = get_tree().get_nodes_in_group("players")
	if players.size() > 0:
		var player = players[0]
		
		if save_system:
			# 1. Сначала сохраняем игру как костёрное сохранение
			save_system.campfire_save(player, campfire_id)
			print("✅ Игра сохранена как костёрное сохранение")
			
			# 2. ОЧЕНЬ ВАЖНО: Очищаем убитых врагов и собранные предметы
			print("🧹 Очищаем списки убитых врагов и предметов для респавна...")
			if save_system.save_data.has("enemies_killed"):
				save_system.save_data["enemies_killed"].clear()
			if save_system.save_data.has("items_collected"):
				save_system.save_data["items_collected"].clear()
			
			# 3. Сохраняем очищенное состояние в файл
			save_system.save_game(player)
			print("💾 Очищенное состояние сохранено в файл")
		else:
			print("❌ Ошибка: SaveSystem не найден!")

func show_interaction_effect():
	print("🔥 Костёр использован")
	
	if sprite:
		var original_modulate = sprite.modulate
		sprite.modulate = Color(1.2, 1.2, 1.0, 1.0)
		
		await get_tree().create_timer(0.3).timeout
		sprite.modulate = original_modulate
