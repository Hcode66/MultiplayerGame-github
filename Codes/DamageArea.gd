extends Area2D

class_name DamageArea
@export var useKnockback: bool = false
@export var knocback: float = 1500.
@export var kill: bool = false
@export var damage: float = 20.
@export var damageLoopInterval: float = .1
var target: Player
var counter: float = .0
