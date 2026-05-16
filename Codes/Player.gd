extends CharacterBody2D

class_name Player

@onready var cam: Camera2D = $Camera2D

@export var hitArea: Area2D
@export var hitBox: Area2D
@export var spr: AnimatedSprite2D
@export var jetpackCounter: float = 0.
@export var jetpackTime: float = 0.
@export var coyoteTime: float = .1
@export var pos: Vector2:
	set(v):
		pos = v

var speed = 500.0
const JUMP_VELOCITY = -1000.0
var coyoteCounter: float = 0.
var isUsingSuper: bool = false
#const TEST_OBJ = preload("uid://ccurewo0sry2t")
var color: Color

var dir: float = 1
var isAdmin: bool = false
@export var light: PointLight2D
@onready var runAudio: AudioStreamPlayer2D = $RunAudio
## FOR ADMIN
var isNameVisible: bool = true


func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())
	gonet.updatePlayers()


func check_name(context):
	if gonet.stored_data["name"].ends_with(context):
		gonet.stored_data["name"] = gonet.stored_data["name"].replace(context, "")
		return true
	return false


func check_namecodes():
	if check_name(".admin"):
		isAdmin = true
		util.info("[color=yellow]You Are ADMIN[/color]")

	if check_name(".hide"):
		set_player_name.rpc("", false)
		isNameVisible = false
	else:
		set_player_name.rpc(gonet.stored_data["name"])


func prepare():
	%HpBar.light_mask = 17
	%NameLabel.light_mask = 17

	gonet.set_multiplayer_authority(multiplayer.get_unique_id())
	%NameLabel.modulate = Color.YELLOW

	check_namecodes()

	gonet.set_name_data.rpc(multiplayer.get_unique_id(), gonet.stored_data["name"])
	cam.enabled = true
	color = Color8(randi_range(0, 255), randi_range(0, 255), randi_range(0, 255))


func _ready() -> void:
	if gonet.isMobile:
		get_tree().get_first_node_in_group("MobileGUI").visible = true
		light.texture = load("res://Sprites/Other/MobileLight.png")

	if is_multiplayer_authority():
		#cam.make_current()
		#### 10001000000000000000000000000000 -> 1 and 5
		prepare()
		multiplayer.peer_connected.connect(peer_connected)

	else:
		cam.enabled = false
		spr.light_mask = 1
		spr.visibility_layer = 1
		$Lights.queue_free()


func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		Movement(delta)
		Jumping(delta)
		animContol()
		move_and_slide()
		pos = position
		if Input.is_action_pressed("debug") and isAdmin:
			gonet.stored_data["mana"] = 9999
			gonet.mana_changed.emit()

		light.texture_scale = gonet.stored_data["viewDistance"]

		#if Input.is_action_just_pressed("right_mouse"):
		#spawnobj.rpc(get_global_mouse_position(),color)
	else:
		position = position.lerp(pos, delta * 40)


func Movement(delta: float) -> void:
	var direction := Input.get_axis("ui_left", "ui_right")
	if hitArea.isAttacking:
		direction = 0
	if direction < 0:
		spr.flip_h = true
		dir = -1
	elif direction > 0:
		spr.flip_h = false
		dir = 1
	if !hitArea.isUsingSuper:
		if direction:
			velocity.x = direction * speed
			runAudio.pitch_scale = randf_range(.9, 1.2)
			if is_on_floor():
				if !runAudio.playing and abs(velocity.x) > 1:
					runAudio.play()
			else:
				runAudio.stop()

		else:
			runAudio.stop()
			velocity.x = move_toward(velocity.x, 0, speed)


func Jumping(delta) -> void:
	velocity.y = clamp(velocity.y, -INF, 1000)

	if not is_on_floor():
		coyoteCounter -= delta
		if !hitArea.isUsingSuper:
			velocity += get_gravity() * delta * (3.5 if velocity.y > 1 else 2.8)
		else:
			velocity.y = 0
	else:
		#canUseJetpack = false
		coyoteCounter = coyoteTime
	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and coyoteCounter > 0:
		velocity.y = JUMP_VELOCITY
		AudioManager.play_sound.rpc(AudioManager.SOUND_IDS.JUMP, global_position, .2)

	if Input.is_action_just_released("ui_accept"):
		if velocity.y < 0:
			velocity.y = 0

	if hitArea.isAttacking:
		velocity.y = 0


func animContol():
	if hitBox.isTakingDamage:
		spr.play("take_hit")
	elif !hitArea.isAttacking:
		if is_on_floor():
			if absf(velocity.x) > 5.:
				spr.play("run")

			if absf(velocity.x) < 5.:
				spr.play("idle")

		else:
			if velocity.y > 0.:
				spr.play("fall")

			elif velocity.y < 15.:
				spr.play("jump")


@rpc("any_peer", "call_local", "unreliable")
func set_new_animation(new_anim: String):
	spr.play(new_anim)


func _on_spr_animation_changed() -> void:
	if !is_multiplayer_authority():
		return
	set_new_animation.rpc(spr.animation)
	pass # Replace with function body.


@rpc("any_peer", "call_local", "reliable")
func set_vel(new_vel):
	velocity = new_vel


func SetCollisionForPlayers(value: bool) -> void:
	for i in get_tree().get_nodes_in_group("Player"):
		if i == self:
			continue
		if !value:
			add_collision_exception_with(i)
		else:
			remove_collision_exception_with(i)


@rpc("any_peer", "call_local", "reliable")
func set_player_name(new_name: String, isVisible: bool = true):
	%NameLabel.visible = isVisible
	%NameLabel.text = new_name


func peer_connected(id: int):
	set_player_name.rpc(gonet.stored_data["name"], isNameVisible)
	#gonet.set_name_data.rpc(, gonet.stored_data["name"])
	gonet.set_name_data.rpc(multiplayer.get_unique_id(), gonet.stored_data["name"])
