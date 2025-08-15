class_name Helpers

# Store where the last thing was saved/loaded from
static func add_storage_directory(storage_name: String, path: String) -> void:
	var storage_directories = {}
	var file = FileAccess.open(Constants.storage_directories_file, FileAccess.READ)
	if file:
		var json = JSON.new()
		var result = json.parse(file.get_as_text())
		if result == OK:
			var data = json.data
			storage_directories = data if data is Dictionary else {}
		file.close()
	storage_directories[storage_name] = path
	file = FileAccess.open(Constants.storage_directories_file, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(storage_directories))
		file.close()


static func get_storage_directory(storage_name: String) -> String:
	var storage_directories = {}
	var file = FileAccess.open(Constants.storage_directories_file, FileAccess.READ)
	if file:
		var json = JSON.new()
		var result = json.parse(file.get_as_text())
		if result == OK:
			var data = json.data
			storage_directories = data if data is Dictionary else {}
		file.close()
	return storage_directories.get(storage_name, "")
