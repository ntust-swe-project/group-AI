extends GutHookScript

# GUT skips a test script that fails to parse: it logs "Ignoring script <path>
# because it does not extend GutTest" and still exits 0. Fail the run when a
# script GUT tried to collect this run was dropped because it does not load.
# Scripts that load fine but are not GutTest (helpers) and scripts excluded by
# -gselect/-gdir/-gprefix were never tried or load fine, so they do not fail.

const IGNORED_PREFIX := "Ignoring script "
const IGNORED_SUFFIX := " because it does not extend GutTest"


func run():
	if gut.log_level < 1:
		# GUT stops recording warnings at log level 0, so this check is blind.
		gut.logger.error("Parse-error check NOT RUN: needs log level >= 1 (-glog=0 was used).")
	else:
		var broken := _scripts_that_failed_to_load()
		if not broken.is_empty():
			for path in broken:
				gut.logger.error("Test script was not run, it does not load (parse error?): " + path)
			set_exit_code(1)
			return

	if gut.get_test_count() == 0:
		gut.logger.error("No tests ran.")
		set_exit_code(1)


func _scripts_that_failed_to_load() -> Array[String]:
	var broken: Array[String] = []
	for entry in gut.logger.get_warnings():
		var text := str(entry)
		var start := text.find(IGNORED_PREFIX)
		var end := text.find(IGNORED_SUFFIX)
		if start == -1 or end == -1:
			continue
		var path := text.substr(start + IGNORED_PREFIX.length(), end - start - IGNORED_PREFIX.length())
		var script = load(path)
		if script == null or not script.can_instantiate():
			broken.append(path)
	return broken
