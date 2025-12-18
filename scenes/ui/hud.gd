extends Control

@onready var health_bar: TextureProgressBar = $HealthBar
@onready var currency_label: Label = $CurrencyLabel
@onready var cheese_container: HBoxContainer = $CheeseContainer

var max_cheese: int = 3
var cheese_cells: Array = []

func _ready():
	var player = get_tree().get_first_node_in_group("players")
	if player:
		player.health_changed.connect(_on_player_health_changed)
		player.currency_changed.connect(_on_player_currency_changed)
		player.cheese_changed.connect(_on_player_cheese_changed)
		
		health_bar.max_value = player.max_health
		health_bar.value = player.current_health
		currency_label.text = str(player.currency)
		
		# Инициализация сыра
		_init_cheese_cells()

func _init_cheese_cells():
	# Очищаем контейнер
	for child in cheese_container.get_children():
		child.queue_free()
	
	cheese_cells.clear()
	
	# Создаем сыры
	var cheese_scene = preload("res://scenes/ui/cheese_cell.tscn")
	
	for i in range(max_cheese):
		var cheese = cheese_scene.instantiate()
		cheese_container.add_child(cheese)
		cheese_cells.append(cheese)
		
		# Устанавливаем начальное состояние - ПОЛНЫЙ (состояние 3)
		cheese.set_state(3)

func _on_player_cheese_changed(cheese_states: Array):
	# cheese_states - массив состояний для каждого сыра [3, 3, 3] для начала
	print("HUD: Получены состояния сыров: ", cheese_states)
	
	# Обновляем все сыры
	for i in range(min(cheese_cells.size(), cheese_states.size())):
		cheese_cells[i].set_state(cheese_states[i])

func _on_player_health_changed(current_health, max_health):
	health_bar.max_value = max_health
	health_bar.value = current_health

func _on_player_currency_changed(new_amount):
	currency_label.text = str(new_amount)
