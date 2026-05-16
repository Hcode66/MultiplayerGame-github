class_name JumpArea
extends Area2D

@export var force: float = 1000

@onready var spr: AnimatedSprite2D = $Spr


func _on_spr_animation_finished() -> void:
	if spr.animation == "hit":
		spr.play("idle")
	
