extends Control

var dialog = [
	'Привет, я мышка Салли',
	'Я инженерка, так что если нужна будет помощь — обращайся'
]

var dialog_index = 0
var finished = false
var tween: Tween

# 💬 Координаты окна диалога (сам выбираешь)
var screen_position: Vector2 = Vector2(900, 300)  

func _ready():
	custom_minimum_size = Vector2(300, 80)
	size = Vector2(600, 190)

	# ставим по указанным координатам
	position = screen_position

	load_dialog()

func _input(event):
	if event.is_action_pressed("dialog") and finished:
		load_dialog()

func load_dialog():
	if dialog_index < dialog.size():
		finished = false
		$RichTextLabel.bbcode_text = dialog[dialog_index]
		$RichTextLabel.visible_ratio = 0
		
		if tween:
			tween.kill()

		tween = create_tween()
		tween.tween_property($RichTextLabel, "visible_ratio", 1.0, 1.0)
		tween.finished.connect(_on_tween_finished)

	else:
		queue_free()
		get_tree().call_group("players", "enable_movement")

	dialog_index += 1

func _on_tween_finished():
	finished = true
