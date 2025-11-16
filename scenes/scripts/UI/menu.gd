extends Node2D
@onready var animPlayer = $TextureRect/AnimationPlayer

func _ready() -> void:
	pass

func _on_new_game_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/world/labaratory/lab_scene.tscn")

func _on_continue_game_button_pressed() -> void:
	print("Продолжить игру — скоро будет доступно")


func _on_settings_button_pressed() -> void:
	print("Открыть настройки (пока не реализовано)")
