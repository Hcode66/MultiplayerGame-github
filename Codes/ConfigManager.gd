extends Node

var config_data: Dictionary


class Version:
	var major: int
	var minor: int
	var subMinor: int


	func _init(_major: int = 0, _minor: int = 0, _subminor: int = 0) -> void:
		major = _major
		minor = _minor
		subMinor = minor


	func is_equal(a: Version, b: Version = self) -> bool:
		return a.major == b.major and a.minor == b.minor and a.subMinor == b.subMinor


	func isNull() -> bool:
		return major == 0 and minor == 0 and subMinor == 0


	func get_as_text() -> String:
		if isNull():
			return "Version NOT loaded"
		return "{0}.{1}.{2}".format([major, minor, subMinor])


	func parse(text: String):
		var numbers = text.split(".")
		major = int(numbers[0])
		minor = int(numbers[1])
		subMinor = int(numbers[2])


var version: String = ProjectSettings.get_setting("application/config/version")

var data_set: Dictionary = {
	"data": {
		"name": "Human",
	},
}


func load_config(config_path = "user://config.json"):
	var file = FileAccess.open(config_path, FileAccess.READ)
	if file == null:
		print_rich("[color=red]ERROR: NO Config File [/color]")
		print_rich("[color=#bf9000][b]Creating Config File[/b][/color]")
		util.info("[color=#bf9000][b]Creating Config File[/b][/color]", 3.5, Vector2i(-1, -1))
		save_file("user://config.json", str(data_set))
		#OS.alert(config_path)
		load_config()
		return

	var txt: String = file.get_as_text()
	config_data = JSON.parse_string(txt)

	if config_data == null:
		print_rich("[color=red]ERROR: Cant load JSON file [/color]")


func load_data():
	pass
	#version.parse(cnf.get_value("init", "version"))


func _init() -> void:
	load_config()


func _ready() -> void:
	print(version)


func get_data(key: String, section: String = "data"):
	if config_data.has(section):
		if config_data[section].has(key):
			return config_data[section][key]
	else:
		return null


func set_data(key: String, value, section: String = "data") -> void:
	if !config_data.has(section):
		config_data[section] = { }
	config_data[section][key] = value
	save_file("user://config.json", str(config_data))


func save_file(file_name: String, data: String):
	var file = FileAccess.open(file_name, FileAccess.WRITE)
	if file != null:
		file.store_string(data)
		file.close()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_file("user://config.json", str(config_data))
