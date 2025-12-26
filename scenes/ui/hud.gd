extends Control

@onready var health_bar: TextureProgressBar = $HealthBar
@onready var currency_label: Label = $CurrencyLabel
@onready var cheese_container: HBoxContainer = $CheeseContainer

var cheese_cells: Array = []
var player_cheese_count: int = 3  

func _ready():
	var player = get_tree().get_first_node_in_group("players")
	if player:
		player.health_changed.connect(_on_player_health_changed)
		player.currency_changed.connect(_on_player_currency_changed)
		player.cheese_changed.connect(_on_player_cheese_changed)
		
		if "cheese_bites" in player:
			player_cheese_count = player.cheese_bites.size()
			print("HUD: У игрока ", player_cheese_count, " слотов для сыра")
		
		health_bar.max_value = player.max_health
		health_bar.value = player.current_health
		currency_label.text = str(player.currency)
		
		_init_cheese_cells(player_cheese_count)

func _init_cheese_cells(cheese_count: int):
	print("HUD: Создаю ", cheese_count, " сыров")
	
	# Очищаем контейнер
	for child in cheese_container.get_children():
		child.queue_free()
	
	cheese_cells.clear()
	
	var cheese_scene = preload("res://scenes/ui/cheese_cell.tscn")
	
	for i in range(cheese_count):
		var cheese = cheese_scene.instantiate()
		cheese_container.add_child(cheese)
		cheese_cells.append(cheese)
		
		cheese.set_state(3)

func _on_player_cheese_changed(cheese_states: Array):
	print("HUD: Получены состояния сыров: ", cheese_states)
	
	if cheese_states.size() != cheese_cells.size():
		print("HUD: Количество сыров изменилось! Было: ", cheese_cells.size(), ", Стало: ", cheese_states.size())
		_init_cheese_cells(cheese_states.size())
	
	for i in range(min(cheese_cells.size(), cheese_states.size())):
		cheese_cells[i].set_state(cheese_states[i])

func _on_player_health_changed(current_health, max_health):
	health_bar.max_value = max_health
	health_bar.value = current_health

func _on_player_currency_changed(new_amount):
	currency_label.text = str(new_amount)
