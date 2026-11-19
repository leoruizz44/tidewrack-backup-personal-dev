extends Node
## Journal — discovered-logs system (Public Demo scaffold).
##
## Autoloaded as `Journal`. As the player examines objects, the dialogue
## "set_flag" hooks will record discovered entries here; the journal screen
## renders them. Storage only, no UI yet. GameState saves entries() alongside
## the story flags and calls restore() on load.

signal entry_added(id: String)

var _entries: Array[String] = []


func discover(id: String) -> void:
	if id in _entries:
		return
	_entries.append(id)
	entry_added.emit(id)


func entries() -> Array[String]:
	return _entries.duplicate()


func has(id: String) -> bool:
	return id in _entries


## Empties the journal (new game).
func reset() -> void:
	_entries.clear()


## Replaces the journal with ids read from a save. Anything that is not a
## list gives an empty journal; non-string, empty and duplicate items are
## skipped. Does not emit entry_added.
func restore(saved: Variant) -> void:
	_entries.clear()
	if typeof(saved) != TYPE_ARRAY:
		return
	var items: Array = saved
	for item in items:
		if typeof(item) == TYPE_STRING and item != "" and not (item in _entries):
			_entries.append(item)
# TODO(demo): add the reader UI.
