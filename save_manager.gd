extends Node

var path := "user://data.json"

func write_save(content: Variant) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(content))
	file.close()
	file = null

func read_save() -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)
	var content: Variant = JSON.parse_string(file.get_as_text())
	return content

func create_new_save_file() -> void:
	var file := FileAccess.open("res://default_save.json", FileAccess.READ)
	var content: Variant = JSON.parse_string(file.get_as_text())
	write_save(content)

func _ready() -> void:
	if not FileAccess.file_exists(path):
		create_new_save_file()
