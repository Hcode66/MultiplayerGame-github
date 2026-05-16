extends NinePatchRect

@onready var upgMenu = $"../UpgradeMenu"


func _ready() -> void:
	if !is_multiplayer_authority():
		queue_free()
	visible = false


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		logic()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		logic()


func logic():
	visible = !visible
	if visible and upgMenu.enabled:
		upgMenu.enabled = false


func _on_exit_pressed() -> void:
	multiplayer.multiplayer_peer.close()
	get_tree().reload_current_scene()
	pass # Replace with function body.


func _on_countinue_pressed() -> void:
	visible = false
	pass # Replace with function body.
