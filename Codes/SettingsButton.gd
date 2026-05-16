extends Button

@onready var anim: AnimationPlayer = $"../../AnimationPlayer"

var dir = true

func _on_pressed() -> void:
	
	if dir:
		anim.play("Settings")
	else:
		anim.play_backwards("Settings")
	dir = !dir

func _process(delta: float) -> void:
	pass
