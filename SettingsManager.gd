extends Node

const SETTINGS_PATH = "user://game_settings.cfg"

var settings: Dictionary = {
	"brightness": 1.0,
	"volume": 0.8
}

func _ready():
	load_settings()

func save_settings():
	var config = ConfigFile.new()
	config.set_value("Settings", "brightness", settings["brightness"])
	config.set_value("Settings", "volume", settings["volume"])
	config.save(SETTINGS_PATH)
	print("SettingsManager: Настройки сохранены")

func load_settings():
	var config = ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		settings["brightness"] = config.get_value("Settings", "brightness", 1.0)
		settings["volume"] = config.get_value("Settings", "volume", 0.8)
		print("SettingsManager: Настройки загружены")
	else:
		save_settings()

func set_brightness(value: float):
	settings["brightness"] = clamp(value, 0.5, 1.5)
	save_settings()

func set_volume(value: float):
	settings["volume"] = clamp(value, 0.0, 1.0)
	save_settings()

func get_brightness() -> float:
	return settings["brightness"]

func get_volume() -> float:
	return settings["volume"]

func apply_brightness():
	var world_env = get_tree().get_first_node_in_group("world_environment")
	if world_env and world_env.environment:
		world_env.environment.adjustment_brightness = settings["brightness"]

func apply_volume():
	AudioServer.set_bus_volume_db(0, linear_to_db(settings["volume"]))
	AudioServer.set_bus_mute(0, settings["volume"] == 0)
