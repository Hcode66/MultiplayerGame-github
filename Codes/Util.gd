extends Node

#DELETE THIS
var avgFps = 0
var counter = 0
var fps = 0
var isShaking: bool = false
var shakeForce: float = 0
var shakeSpeed: float = 10.
var shakeFadeSpeed: float = 1.
var info_scene: PackedScene = preload("res://Scenes/Info.tscn")
var canvas_layer: CanvasLayer = CanvasLayer.new()


func _ready() -> void:
	add_child(canvas_layer)


func _process(delta: float) -> void:
	fps += Engine.get_frames_per_second()
	counter += 1
	avgFps = floorf(fps / counter)

	if Input.is_action_just_pressed("fullscreen"):
		if get_window().mode == Window.MODE_FULLSCREEN:
			get_window().mode = Window.MODE_WINDOWED
		elif get_window().mode == Window.MODE_WINDOWED:
			get_window().mode = Window.MODE_FULLSCREEN


func _physics_process(delta: float) -> void:
	_shakeLogic(delta)


func Shake(_shakeForce: float, _shakeSpeed: float = 1., _shakeFadeSpeed = 40., shakeTime: float = .2):
	isShaking = true
	shakeForce = _shakeForce
	shakeSpeed = _shakeSpeed
	shakeFadeSpeed = _shakeFadeSpeed
	await get_tree().create_timer(shakeTime).timeout
	isShaking = false


func info(text: String, duration: float = 3.5, side: Vector2i = Vector2i(1, -1)):
	var scn: RichTextLabel = info_scene.instantiate()
	scn.text = text
	scn.time = duration
	scn.side = side
	canvas_layer.add_child(scn)


func kill_info(indx: int = -1):
	if indx < 0:
		for i in canvas_layer.get_children():
			if i is InfoText:
				i.counter = i.time + 1.
				i.kill(1.)

		return
	canvas_layer.get_child(indx).queue_free()


func strip_bbcode(source: String) -> String:
	var regex = RegEx.new()
	regex.compile("\\[.*?\\]")
	return regex.sub(source, "", true)


func remove_non_ascii_printable(input_string: String) -> String:
	var regex = RegEx.new()

	var error = regex.compile("[^\\x20-\\x7E]")

	if error != OK:
		push_error("RegEx error")
		return input_string

	return regex.sub(input_string, "", true)


func _shakeLogic(delta: float):
	if gonet.get_player_count() == 0:
		return

	if gonet.multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		return
	if !gonet.is_multiplayer_authority():
		return
	var cam: Camera2D = get_viewport().get_camera_2d()

	if cam != null:
		if isShaking:
			var offset = Vector2(
				randf_range(-shakeForce, shakeForce),
				randf_range(-shakeForce, shakeForce),
			)
			cam.offset = cam.offset.lerp(offset, delta * shakeFadeSpeed)
			shakeForce = lerpf(shakeForce, 0, delta * shakeSpeed)
		else:
			cam.offset = cam.offset.lerp(Vector2.ZERO, delta * shakeFadeSpeed)
