extends HitBox

@export var canTakeDamage: bool = true

var isTakingDamage: bool = false
var maxHp: float = 120.
var regenCounter: float = 0
var damagedByPlayer: bool = false
var enemy_player_id: int = -1

@onready var player: Player = $".."
@onready var spr: AnimatedSprite2D = $"../Spr"
@onready var bar: ProgressBar = $"../Status/HpBar"


func _ready() -> void:
	if !is_multiplayer_authority():
		return
	gonet.set_spawnpoint(Vector2.ZERO)
	maxHp = hp
	gonet.stored_data["score"] = 0


func _process(delta: float) -> void:
	if !canTakeDamage:
		spr.modulate.a = sin(Time.get_ticks_msec() * .2) * 2.
	else:
		spr.modulate.a = 1.
	if is_multiplayer_authority():
		#upd.rpc(hp,maxHp)
		if regenCounter >= gonet.get_upg("regenSpeed") and maxHp >= hp:
			regenHp.rpc(gonet.get_upg("regenAmmount"))

			upd.rpc(hp, maxHp)

			regenCounter = 0
		regenCounter += delta

		if hp <= 0 or Input.is_action_just_pressed("Respawn"):
			Kill.rpc(enemy_player_id if damagedByPlayer else -1)
		#if multiplayer.is_server(): AudioServer.set_bus_volume_linear(0,-10)


@rpc("any_peer", "call_local", "reliable")
func TakeDamage(damage: float, dmg_by_player: bool = false, p_id: int = -1):
	if !canTakeDamage:
		return
	hp -= damage
	enemy_player_id = p_id
	damagedByPlayer = dmg_by_player
	player.set_vel.rpc(player.velocity * Vector2(0, 1))
	util.Shake(15)
	isTakingDamage = true
	AudioManager.play_sound.rpc(AudioManager.SOUND_IDS.DAMAGE, global_position, 1.5, Vector2(.85, 1.2))
	await player.spr.animation_finished
	isTakingDamage = false


@rpc("any_peer", "call_local", "reliable")
func Kill(enemy_id: int = -1, reset_hp: bool = true):
	AudioManager.play_sound.rpc(AudioManager.SOUND_IDS.DAMAGE, global_position, 1.5, Vector2(.85, 1.2))

	if enemy_id != -1:
		update_score.rpc_id(enemy_id, 1)

	get_parent().global_position = gonet.get_spawnpoint()
	if reset_hp:
		hp = maxHp
		bar.value = hp

	canTakeDamage = false
	await get_tree().create_timer(2.5).timeout
	canTakeDamage = true


@rpc("call_local", "reliable")
func regenHp(ammount):
	hp += ammount
	hp = clampf(hp, 0, maxHp)


func on_hp_change():
	if !is_inside_tree():
		return
	upd.rpc(hp, maxHp)


@rpc("any_peer", "call_local", "reliable")
func upd(new_val: float, new_max_val: float):
	bar.value = new_val
	bar.max_value = new_max_val



@rpc("any_peer", "reliable")
func update_score(amount: int):
	gonet.stored_data["score"] += amount
	print("Peer ", multiplayer.get_unique_id(), " new score: ", gonet.stored_data["score"])
	gonet.on_score_change.emit(multiplayer.get_unique_id(), gonet.stored_data["score"])


func _on_area_entered(area: Area2D) -> void:
	if !is_multiplayer_authority():
		return
	if area is JumpArea:
		player.velocity.y = -area.force
		AudioManager.play_sound.rpc(AudioManager.SOUND_IDS.JUMP_AREA, global_position)
	if area is DamageArea:
		if area.kill:
			Kill.rpc(-1, false)
			update_score(-1)
		else:
			TakeDamage.rpc(area.damage)
	pass # Replace with function body.
