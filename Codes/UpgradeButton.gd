class_name UpgradeButton
extends Button

enum OPS {
	ADD = 0,
	MULTIPLY = 1,
	SUBTRACT = 2,
	DIVIDE = 3,
}

@export var dataName: String = "<>"
@export_multiline var upgradesJson: String
@export var op: OPS
@export var prg_bar: TextureProgressBar
@export var defaultVal: float = 1.

var upgCount: int = 0:
	set(v):
		upgCount = v
		prg_bar.value = v
		var upgrades: Dictionary = JSON.parse_string(upgradesJson)
		if upgrades["data"].size() <= upgCount:
			return

		var prc: float = upgrades["data"][upgCount][0]
		var val: float = upgrades["data"][upgCount][1]

		tooltip_text = "{0} : Required MANA:{1} | It will {2} {3}".format([text, prc, OPS.keys()[op], val])
var data: float = 0.

@onready var audio: AudioStreamPlayer = %UpgAudio


func _ready() -> void:
	if !is_multiplayer_authority():
		queue_free()
	gonet.stored_data[dataName] = defaultVal
	gonet.check_data("upg_count", 0)
	pressed.connect(use)
	upgCount = 0
	mouse_entered.connect(
		func():
			util.info(tooltip_text, 30)
	)
	mouse_exited.connect(
		func():
			util.kill_info()
	)


func update(val):
	match op:
		0:
			gonet.stored_data[dataName] += val
		1:
			gonet.stored_data[dataName] *= val
		2:
			gonet.stored_data[dataName] -= val
		3:
			gonet.stored_data[dataName] /= val
	gonet.stored_data["upg_count"] += 1


func use():
	var upgrades: Dictionary = JSON.parse_string(upgradesJson)
	if upgrades["data"].size() <= upgCount:
		return
	prg_bar.max_value = upgrades["data"].size()
	var prc: float = upgrades["data"][upgCount][0]
	var val: float = upgrades["data"][upgCount][1]
	print(prc, " | ", val, " | ", get_mana(), " | ", upgCount)
	if get_mana() >= prc:
		update(val)
		decrease_mana(prc)
		audio.play()
		upgCount += 1
	pass


func get_mana() -> float:
	return gonet.stored_data["mana"]


func decrease_mana(val: float) -> void:
	gonet.stored_data["mana"] -= val
	gonet.mana_changed.emit()
