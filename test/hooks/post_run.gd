extends GutHookScript

# GUT exits 0 when a test script fails to parse: it skips the file with a
# warning and only counts failed asserts. Fail the run instead when any
# test_*.gd under res://test/ was not collected, or when nothing ran.

const TEST_DIR := "res://test/"


func run():
	var collected := {}
	for script in gut.get_test_collector().scripts:
		collected[script.path] = true

	var skipped: Array[String] = []
	for path in _find_test_files(TEST_DIR):
		if not collected.has(path):
			skipped.append(path)

	if not skipped.is_empty():
		for path in skipped:
			gut.logger.error("Test script was not run (parse error?): " + path)
		set_exit_code(1)
	elif gut.get_test_count() == 0:
		gut.logger.error("No tests ran.")
		set_exit_code(1)


func _find_test_files(dir_path: String) -> Array[String]:
	var found: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return found
	for file in dir.get_files():
		if file.begins_with("test_") and file.ends_with(".gd"):
			found.append(dir_path.path_join(file))
	for sub in dir.get_directories():
		found.append_array(_find_test_files(dir_path.path_join(sub)))
	return found
