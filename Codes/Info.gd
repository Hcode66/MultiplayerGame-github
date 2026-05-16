extends RichTextLabel

class_name InfoText

var side: Vector2i = Vector2i(1, -1)
var time: float = 2.5
var counter: float = 0.


func _ready() -> void:
	if side.x > 0:
		global_position.x = get_viewport_rect().size.x
	else:
		global_position.x = -size.x
	if side.y > 0:
		global_position.y = 0
	else:
		global_position.y = get_viewport_rect().size.y - size.y


func _process(delta: float) -> void:
	var target_pos = 0
	var isFinished = counter >= time / 2
	if side.x > 0:
		if isFinished:
			target_pos = get_viewport_rect().size.x
		else:
			target_pos = get_viewport_rect().size.x - size.x

	else:
		if isFinished:
			target_pos = -size.x
		else:
			target_pos = 0
	if isFinished:
		kill()
	counter += delta
	global_position.x = lerpf(global_position.x, target_pos, delta * 8)


func kill(custom_time: float = time):
	modulate.a = lerpf(modulate.a, 0, get_process_delta_time() * 15)
	await get_tree().create_timer(custom_time / 2).timeout
	queue_free()
