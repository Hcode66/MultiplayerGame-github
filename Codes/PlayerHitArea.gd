extends Area2D

@export var nextAttackTime: float = .41
@export var attackDelay: float = .2:
	set(v):
		attackDelay = v
		var b = (v / 0.8) + 0.55 ## ratio with attack delay | default is 0.8
		$"../Status/SuperProgressBar".max_value = b
		$SuperTimer.wait_time = b
@export var spr: AnimatedSprite2D
@export var player: Player
@export var knockBack: float = 50.
@export var hitParticleScene: PackedScene
@export var hitBox: HitBox
@export var superProgressBar: TextureProgressBar
@export var superTimer: Timer
@export var superParticle: GPUParticles2D

var damage: float:
	get():
		return gonet.get_upg("attackDamage")
var nextAttackCounter: float = 0.
var hitboxes: Array[HitBox] = []
var attackDelayCounter: float = 0.
var isAttacking: bool = false
var mana: float = 0:
	set(v):
		mana = v
		upd_mana_bar()
		#gonet.stored_data["mana"] = v
var canUseSuper: bool = false
var isUsingSuper: bool = false
var damaged: Array[HitBox] = []
var is_particle_fliped: bool = false
var isSuperParticleStarted: bool = false

@onready var coll: CollisionShape2D = $Coll
@onready var upgMenu = $"../GUI/UpgradeMenu"
@onready var dash_particle: GPUParticles2D = $"../Particles/DashParticle"


func _ready() -> void:
	if !is_multiplayer_authority():
		return

	gonet.stored_data["mana"] = 0


func _process(delta: float) -> void:
	if !is_multiplayer_authority():
		return
	if !isSuperParticleStarted and canUseSuper:
		superParticle.restart()
		isSuperParticleStarted = true
		#superParticle.

	coll.position.x = abs(coll.position.x) * player.dir
	superProgressBar.visible = true
	if !upgMenu.enabled:
		Attack(delta)
		SuperAttack()


func Attack(delta: float):
	attackDelay = gonet.get_upg("attackSpeed")

	if Input.is_action_just_pressed("left_mouse") and attackDelayCounter > attackDelay and !isUsingSuper:
		isAttacking = true
		util.Shake(5.)
		if nextAttackCounter < nextAttackTime:
			spr.play("attack2")
			nextAttackCounter = nextAttackTime
		else:
			spr.play("attack1")
			nextAttackCounter = 0
		attackDelayCounter = 0
		AudioManager.play_sound(
			[AudioManager.SOUND_IDS.SLASH1, AudioManager.SOUND_IDS.SLASH2].pick_random(),
			global_position,
			1.5,
			Vector2(1., 1.2),
		)

		giveDamage()
	#if nextAttackCounter > 0

	nextAttackCounter += delta
	attackDelayCounter += delta
	if attackDelayCounter >= attackDelay:
		isAttacking = false


func giveDamage():
	for i: HitBox in hitboxes:
		Hit(i)

func calc_mana() -> float: return snappedf(10/(gonet.get_data("upg_count") + 0.5),0.25)

func Hit(target: HitBox, dmg = damage):
	target.TakeDamage.rpc(dmg, true, multiplayer.get_unique_id())
	if target.canTakeDamage:
		util.Shake(15)
		add_mana(calc_mana())
	spawn_hit_particle.rpc(target.global_position)
	if target.get_parent() is Player:
		var target_player: Player = target.get_parent()
		target_player.set_vel.rpc(Vector2(knockBack * player.dir, target_player.velocity.y))


@rpc("authority", "call_local", "unreliable")
func spawn_hit_particle(pos: Vector2):
	var p: GPUParticles2D = hitParticleScene.instantiate()
	gonet.get_world().call_deferred("add_child", p, true)
	p.global_position = pos
	p.emitting = true
	await get_tree().create_timer(.2).timeout
	p.queue_free()


func SuperAttack():
	superProgressBar.value = superTimer.wait_time - superTimer.time_left

	if canUseSuper:
		superProgressBar.modulate.a = lerpf(superProgressBar.modulate.a, .0, get_process_delta_time() * 10)
	else:
		superProgressBar.modulate.a = lerpf(superProgressBar.modulate.a, 1., get_process_delta_time() * 10)

	if isUsingSuper:
		#dash_particle.emitting = true

		for i in hitboxes:
			if !damaged.has(i):
				Hit(i, damage * 2)
				damaged.append(i)
	else:
		#trail.enabled = false
		dash_particle.emitting = false

	if Input.is_action_just_pressed("right_mouse") and canUseSuper:
		flip_dash_particle.rpc(player.dir)
		dash_particle.restart()
		AudioManager.play_sound(AudioManager.SOUND_IDS.DASH, global_position, 1.6, Vector2(1, 1.5))
		superTimer.start()
		canUseSuper = false
		isUsingSuper = true
		player.velocity.x = 2100 * player.dir
		setHitBox.rpc(false)
		await get_tree().create_timer(.1).timeout
		isUsingSuper = false
		setHitBox.rpc(true)
		damaged = []


@rpc("any_peer", "call_local", "reliable")
func setHitBox(value: bool) -> void:
	if value:
		hitBox.monitorable = true
		hitBox.monitoring = true
	else:
		hitBox.monitorable = false
		hitBox.monitoring = false


func add_mana(val: float):
	gonet.stored_data["mana"] += val
	mana = gonet.stored_data["mana"]
	gonet.mana_changed.emit()


func upd_mana_bar():
	$"../GUI/UpgradeMenu/ManaBar".value = mana
	$"../GUI/UpgradeMenu/ManaBar/Text".text = str("MANA:", snappedf(mana, .1))


@rpc("any_peer", "call_local")
func flip_dash_particle(dir: float):
	dash_particle.process_material.scale_curve.curve_x.set_point_value(0, dir)


func _on_area_entered(area: Area2D) -> void:
	if area is HitBox and !hitboxes.has(area):
		if area.get_parent() == get_parent():
			return
		hitboxes.append(area)

	pass # Replace with function body.


func _on_area_exited(area: Area2D) -> void:
	if area is HitBox and hitboxes.has(area):
		hitboxes.erase(area)


func _on_super_timer_timeout() -> void:
	canUseSuper = true
	isSuperParticleStarted = false
	pass # Replace with function body.
