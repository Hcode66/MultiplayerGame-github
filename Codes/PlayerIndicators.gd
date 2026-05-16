extends Node2D

const texture = preload("res://Sprites/Other/hitparticle.png")

var timer: float = 0
var mat: CanvasItemMaterial = CanvasItemMaterial.new()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if !is_multiplayer_authority():
		queue_free()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	timer += delta
	if timer > 1.:
		timer = 0
		update()
	pass


func setSprPos(spr: Sprite2D, pos: Vector2):
	spr.visible = global_position.distance_to(pos) > 100

	var relativePos: Vector2 = global_position.direction_to(pos) * 50
	spr.position = relativePos


func update():
	var players: Array[Node] = get_tree().get_nodes_in_group("Player")

	for player: Player in players:
		if player == gonet.get_player(gonet.get_multiplayer_authority()):
			continue

		var pID: String = player.name

		if !has_node(pID):
			var spr = Sprite2D.new()
			spr.texture = texture
			spr.global_position = global_position
			add_child(spr)
			spr.name = pID
			setSprPos(spr, player.global_position)
			spr.material = mat
		else:
			setSprPos(get_node(pID), player.global_position)
