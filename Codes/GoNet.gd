extends Node

var peer: ENetMultiplayerPeer

signal peer_connected(id: int)
signal peer_disconnected(id: int)
signal spawn_point_changed(new_pos: Vector2)
signal on_score_change(id: int, score: int)
signal mana_changed()
var game_data = {
}
var stored_data = { }
var score_data = { }
var name_data = { }
var current_spawn_point: Node
var isMobile: bool = false
var players = []


func _ready() -> void:
	multiplayer.peer_connected.connect(func(id): peer_connected.emit(id))
	multiplayer.peer_disconnected.connect(func(id): peer_disconnected.emit(id))
	multiplayer.server_disconnected.connect(server_disconnected)

	peer_disconnected.connect(destroy_player)
	peer_connected.connect(player_connected)
	on_score_change.connect(_on_score_changed)
	isMobile = OS.get_name() == "Android"
	if isMobile:
		InputMap.action_erase_event("left_mouse", InputMap.action_get_events("left_mouse")[0])
		InputMap.action_erase_event("right_mouse", InputMap.action_get_events("right_mouse")[0])

	print(get_local_ip())


func start_server(port: int) -> Error:
	multiplayer.multiplayer_peer.close()
	peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(port)
	multiplayer.multiplayer_peer = peer
	get_window().title = "Server"
	return err


func start_client(ip_addres: String, port: int):
	peer = ENetMultiplayerPeer.new()
	peer.create_client(ip_addres, port)
	multiplayer.multiplayer_peer = peer

	get_window().title = "Client:{0}".format([multiplayer.get_unique_id()])


func get_world() -> Node2D:
	return get_tree().get_first_node_in_group("World")


func check_upg(what: String):
	return stored_data.has(what)


func get_upg(what: String):
	if !check_upg(what):
		return
	return stored_data[what]


@rpc("any_peer", "call_local", "reliable")
func set_spawnpoint(pos: Vector2) -> void:
	stored_data["spawn_point"] = pos
	spawn_point_changed.emit(pos)


func get_spawnpoint() -> Vector2:
	return stored_data["spawn_point"]


func _on_score_changed(id: int, score: int):
	if multiplayer.multiplayer_peer == null:
		return
	score_data[id] = score
	_upd_score_data.rpc(id, score)
	#(score_data)


@rpc("any_peer", "call_local", "reliable")
func _upd_score_data(id: int, score: int):
	score_data[id] = score
	#(score_data, "::", multiplayer.get_unique_id())


@rpc("any_peer", "call_local", "reliable")
func set_name_data(id: int, val: String):
	name_data[id] = val


func get_local_ip() -> String:
	var ip_address: String = ""
	# Get all local addresses as an array
	var addresses: PackedStringArray = IP.get_local_addresses()

	for address in addresses:
	# Check if it is an IPv4 address (contains dots)
		if "." in address:
			# Exclude loopback and link-local addresses
			if not address.begins_with("127.") and not address.begins_with("169.254."):
				# Prioritize common private network ranges
				if address.begins_with("192.168.") or address.begins_with("10.") or (address.begins_with("172.") and int(address.split(".")[1]) >= 16 and int(address.split(".")[1]) <= 31):
					ip_address = address
					break # Found a likely LAN IP, stop searching
				elif ip_address == "":
					# Store the first valid IPv4 address as a fallback
					ip_address = address

	return ip_address


func get_player(id: int) -> Player:
	#var players: Array[Node] = get_tree().get_nodes_in_group("Player")
	for i in players:
		if !is_instance_valid(i):
			continue
		if i.name == str(id):
			return i
	return null


func get_player_count() -> int:
	return get_tree().get_node_count_in_group("Player")


func updatePlayers() -> void:
	players = get_tree().get_nodes_in_group("Player")


func destroy_player(id):
	#print(get_player(id))
	if get_player(id) == null:
		return
	get_player(id).queue_free()
	score_data.erase(id)

	on_score_change.emit(id, -1)
	#print(score_data)
	#print(stored_data)


func server_disconnected():
	
	gonet.score_data.clear()
	get_tree().reload_current_scene()
	multiplayer.multiplayer_peer.close()
	updatePlayers()
	#get_tree().reload_current_scene()


func player_connected(id: int):
	#peer.put_packet(JSON.stringify(game_data).to_utf8_buffer())

	pass


@rpc("any_peer", "call_local")
func set_gamedata(data: PackedByteArray):
	game_data = JSON.parse_string(data.get_string_from_utf8())
	process_gamedata()


func process_gamedata():
	if game_data.has("player_speed"):
		get_player(multiplayer.get_unique_id()).speed = game_data["player_speed"]


func get_data(what: String):
	return stored_data[what] if stored_data.has(what) else null

## if stored.has(what) == false -> create_data != null -> stored[what] = create_data
func check_data(what: String, create_data = null) -> bool:
	if !stored_data.has(what):
		if create_data != null:
			stored_data[what] = create_data
			return true
	else:
		return true
	return false
	
