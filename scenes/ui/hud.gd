extends Control

@onready var health_bar: TextureProgressBar = $HealthBar
@onready var currency_label: Label = $CurrencyLabel

func _ready():
	var player = get_tree().get_first_node_in_group("players")
	if player:
		player.health_changed.connect(Callable(self, "_on_player_health_changed"))
		player.currency_changed.connect(Callable(self, "_on_player_currency_changed"))
		
		health_bar.max_value = player.max_health
		health_bar.value = player.current_health
		
		# Устанавливаем валюту из игрока
		currency_label.text = str(player.currency)

func _on_player_health_changed(current_health, max_health):
	health_bar.max_value = max_health
	health_bar.value = current_health

func _on_player_currency_changed(new_amount):
	currency_label.text = str(new_amount)
