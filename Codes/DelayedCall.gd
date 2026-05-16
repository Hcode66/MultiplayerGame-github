extends Node
class_name DelayedCall

@export var func_name: StringName = "queue_free"
@export var args: Array = []
@export var time: float = 1.
func _ready() -> void:
	await get_tree().create_timer(time).timeout
	get_parent().callv(func_name,args)
