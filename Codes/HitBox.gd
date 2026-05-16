extends Area2D
class_name HitBox

@export var hp: float = 25.:
	set(v):
		hp = v
		on_hp_change()
@export var tags: Array[String] = []

func on_hp_change(): pass

@rpc("any_peer", "call_local")
func TakeDamage(damage:float):
	hp -= damage
