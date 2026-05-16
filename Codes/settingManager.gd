extends Node
@onready var settingSound: Button = $"../SettingSound"

var sound = true:
	set(v):
		sound = v
		AudioServer.set_bus_mute(0, !v if v != null else true)
		settingSound.text = "on" if v else "off"


func _on_setting_sound_pressed() -> void:
	sound = !sound
	ConfigManager.set_data("sound",sound, "setting")

func _ready() -> void:
	sound = ConfigManager.get_data("sound", "setting")
