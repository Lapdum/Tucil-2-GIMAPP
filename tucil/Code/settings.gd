extends Control

var music_index = AudioServer.get_bus_index("Music")
var sfx_index = AudioServer.get_bus_index("SFX")


func _on_music_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(music_index,linear_to_db(value))


func _on_sfx_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(sfx_index,linear_to_db(value))
