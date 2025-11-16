extends CanvasLayer
func _input(_event):
	if _event.is_action_pressed("inventory"):
		$Inventory.visible = !$Inventory.visible
		$Inventory. initialize_inventory()
