extends TextureRect

@onready var port: LineEdit = $Port
@onready var ip: LineEdit = $IP
@export var playerScene: PackedScene = preload("res://Scenes/Player.tscn")
@onready var name_input: LineEdit = $Name
@onready var connection_timer: Timer = $ConnectionTimer
@onready var light: Light2D = $"../Light"
@export var debug_label: Label 
@export var canvasModulate: CanvasModulate

@export var localWorld: Node2D
var timeout: bool = false

func start_game():
	get_parent().visible = false
	canvasModulate.visible = true
	

func check_name_validity() -> bool:
	var n: String = name_input.text.replace(" ","")
	n = util.remove_non_ascii_printable(n)
	print(n)
	return n != "" and n.length() > 3

func _ready() -> void:

	$AnimationPlayer.play("Intro")
	var n = ConfigManager.get_data("name")
	name_input.text = n if n != null else "Human"
	gonet.stored_data["name"] = name_input.text
	get_parent().visible = true
	ip.text = gonet.get_local_ip()
	$Version.text = ConfigManager.version


func _on_host_pressed() -> void:
	if !check_name_validity():
		util.kill_info()
		util.info("Write a name ([color=yellow] minimum 4 characters)")
		return
	var err = gonet.start_server(port.text.to_int())
	if err != OK:
		close()
		var txt = "[color=red] Server ERROR => err code:{0} => {1}".format([err, error_string(err)])
		util.info(txt, 7)
		return
	multiplayer.peer_connected.connect(add_player)
	
	add_player()
	start_game()
	

func _on_join_pressed() -> void:
	if !check_name_validity():
		util.kill_info()
		util.info("Write a name ([color=yellow] minimum 4 characters)")
		return
	gonet.start_client(ip.text, port.text.to_int())
	multiplayer.connection_failed.connect(connection_failed)
	multiplayer.connected_to_server.connect(connected_to_server)
	timeout = false
	
	util.info("CONNECTING",.9)
	connection_timer.start()
	
	start_game()



func add_player(id = 1):
	
	var player: Player = playerScene.instantiate()
	player.name = str(id)
	get_node("../../World").call_deferred("add_child", player)
	gonet.updatePlayers()

	


func _on_name_text_changed(new_text: String) -> void:
	gonet.stored_data["name"] = new_text
	ConfigManager.set_data("name",new_text)
	pass # Replace with function body.


func lerp_light(to: Vector2, t: float = 10):
	#light.global_position = light.global_position.lerp(to, get_process_delta_time() * t)
	light.global_position = snapped(to,Vector2.ONE*t)

func _process(_delta: float) -> void:
	## TODO: CHANGE LIGHT WITH BASIC SPRITE FOR FPS 
	lerp_light(get_global_mouse_position(),10)
	## DEBUG !!!, DELETE ME !!!
	debug_label.text = str("FPS:",Engine.get_frames_per_second(), " / AVG:")


func _on_exit_pressed() -> void:
	get_tree().quit()
	pass # Replace with function body.

func connection_failed():
	get_parent().visible = true
	if !timeout:
		util.info("[color=red] ERROR: Connection Failed [/color]")
	close()
	localWorld.started = false
	

func connected_to_server():
	connection_timer.stop()

	


func _on_connection_timer_timeout() -> void:
	print("timeout")
	util.info("[color=yellow]Connection Timeout[/color]",3.5,Vector2i(-1,-1))
	close()
	timeout = true
	pass # Replace with function body.


func close():
	multiplayer.multiplayer_peer.close()
	get_parent().visible = true
	canvasModulate.visible = false
