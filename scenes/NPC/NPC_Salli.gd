extends Area2D

var can_interact = false


func _ready():
	print("NPC готов к работе")

func _physics_process(_delta):
	$AnimatedSprite2D.play()
	
	if can_interact and Input.is_action_just_pressed("dialog"):
		Dialogic.start("timeline1")	

func _on_body_entered(body):
	if body.name == "player":
		$Label.visible = true
		can_interact = true

func _on_body_exited(body):
	if body.name == "player":
		$Label.visible = false
		can_interact = false
