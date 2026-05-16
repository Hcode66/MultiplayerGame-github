extends Area2D

@export var offset: Vector2 = Vector2.ZERO

var current: bool = false:
	set(v):
		current = v

@onready var light: PointLight2D = $Light
@onready var particles: GPUParticles2D = $Particles


func _ready() -> void:
	await multiplayer.connected_to_server
	if !is_multiplayer_authority():
		return
	gonet.spawn_point_changed.connect(changed)


func _process(delta: float) -> void:
	#if !is_multiplayer_authority(): return
	particles.emitting = !current
	if current:
		light.energy = lerpf(light.energy, 1, delta * 10)
		modulate = Color.WHITE
	else:
		light.energy = lerpf(light.energy, 0, delta * 10)
		modulate = Color.LIGHT_GRAY


func changed(pos: Vector2):
	#if !is_multiplayer_authority(): return
	if gonet.current_spawn_point != self:
		current = false


func _on_body_entered(body: Node2D) -> void:
	if body is Player and body.is_multiplayer_authority():
		gonet.set_spawnpoint(global_position + offset)
		current = true
