extends VBoxContainer

const SCORE_LABEL = preload("res://Scenes/ScoreLabel.tscn")

var labels = { }
var open = false
var counter: float = 0


func _ready() -> void:
	if !is_multiplayer_authority():
		queue_free()
	#gonet.on_score_change.connect(_on_score_change)
	multiplayer.peer_connected.connect(send_to_all)

	scale = Vector2.ONE * 0.00001 ## Vector2.ZERO -> affine_invert: Condition "det == 0" is true
	multiplayer.peer_disconnected.connect(remove_score_label)
	#multiplayer.connected_to_server.connect(func(): add_label(1))


func _process(delta: float) -> void:
	counter += delta

	if counter > .5:
		update_scores()
		counter = 0

	if Input.is_action_just_pressed("Score"):
		open = !open
	if open:
		scale = lerp(scale, Vector2.ONE, delta * 10)
	else:
		scale = lerp(scale, Vector2.ZERO, delta * 10)


func update_scores():
	add_label(multiplayer.get_unique_id())
	for i in multiplayer.get_peers():
		add_label(i)


func add_label(id: int):
	if !labels.has(id):
		var l: RichTextLabel = SCORE_LABEL.instantiate()
		add_child(l)
		l.text = get_player_name(id) + " : " + str(get_score(id))
		labels[id] = l
	elif gonet.score_data.has(id):
		labels[id].text = get_player_name(id) + " : " + str(get_score(id))


func remove_score_label(id: int):
	if !labels.has(id):
		return
	labels[id].queue_free()


func send_to_all(_id):
	#for i in gonet.score_data:
	var myId = multiplayer.get_unique_id()
	if gonet.score_data.has(myId):
		gonet._upd_score_data.rpc(myId, gonet.score_data[myId])


@rpc("any_peer", "call_local", "reliable")
func send_score(id: int, score: int):
	gonet.score_data[id] = score


func get_player_name(id: int):
	return gonet.name_data[id] if gonet.name_data.has(id) else "<loading>"


func get_score(id: int):
	return gonet.score_data[id] if gonet.score_data.has(id) else 0
