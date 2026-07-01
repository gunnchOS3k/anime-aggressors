extends RefCounted
class_name SmokeAssert

static var failures: PackedStringArray = []

static func reset() -> void:
	failures.clear()

static func ok(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error("SMOKE FAIL: %s" % message)

static func passed() -> bool:
	return failures.is_empty()

static func summary() -> String:
	if failures.is_empty():
		return "OK"
	return "\n".join(failures)
