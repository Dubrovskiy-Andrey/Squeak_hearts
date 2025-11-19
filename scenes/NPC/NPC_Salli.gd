extends Area2D

var can_interact = false
const DIALOG = preload("res://scenes/ui/dialog.tscn")

func _ready():
	print("NPC готов к работе")

func _physics_process(_delta):
	$AnimatedSprite2D.play()
	
	if can_interact and Input.is_action_just_pressed("dialog"):
		start_dialog()

func _on_body_entered(body):
	if body.name == "player":
		$Label.visible = true
		can_interact = true

func _on_body_exited(body):
	if body.name == "player":
		$Label.visible = false
		can_interact = false

func start_dialog():
	$Label.visible = false
	var dialog = DIALOG.instantiate()

	get_tree().current_scene.get_node("UserInterface").add_child(dialog)
	get_tree().call_group("players", "disable_movement")

	can_interact = false
