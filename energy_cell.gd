extends Control

@export var cheese_state: int = 3:
	set(value):
		cheese_state = clamp(value, 0, 3)
		_update_texture()

@onready var cheese_texture: TextureRect = $CheeseTexture

@export var empty_texture: Texture2D
@export var small_texture: Texture2D    # 1 кусочек
@export var medium_texture: Texture2D   # 2 кусочка
@export var full_texture: Texture2D     # 3 кусочка - ПОЛНЫЙ

func _ready():
	# Убедитесь что загружаются правильные текстуры!
	if not empty_texture:
		empty_texture = load("res://assets/HP/cheese_empty.png")
	if not small_texture:
		small_texture = load("res://assets/HP/cheese_small.png")
	if not medium_texture:
		medium_texture = load("res://assets/HP/cheese_medium.png")
	if not full_texture:
		full_texture = load("res://assets/HP/cheese_full.png")
	
	_update_texture()

func _update_texture():
	if not is_instance_valid(cheese_texture):
		return
	
	match cheese_state:
		0:  # ПУСТОЙ
			cheese_texture.texture = empty_texture
			cheese_texture.modulate = Color(1, 1, 1, 0.5)
		1:  # МАЛЕНЬКИЙ (1/3)
			cheese_texture.texture = small_texture
			cheese_texture.modulate = Color(1, 1, 1, 1)
		2:  # СРЕДНИЙ (2/3)
			cheese_texture.texture = medium_texture
			cheese_texture.modulate = Color(1, 1, 1, 1)
		3:  # ПОЛНЫЙ (3/3)
			cheese_texture.texture = full_texture
			cheese_texture.modulate = Color(1, 1, 1, 1)

func set_state(state: int):
	cheese_state = state
