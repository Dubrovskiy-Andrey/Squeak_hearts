extends Node2D
func _ready():
	Dialogic.signal_event.connect(_on_dialogic_signal)
	
func _on_dialogic_signal(argument):
	if argument == "accept":
		$UserInterface/Inventory.visible = true
