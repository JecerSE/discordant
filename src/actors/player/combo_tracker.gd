class_name ComboTracker
extends RefCounted
## Remembers recent attack presses (in beats) and reports when the latest ones form
## one of the character's rhythm patterns (issue #11).

const TUNING: TimingTuning = preload("res://content/tuning/timing_tuning.tres")

var combos: ComboSet
## Each press: {"beat": float, "grade": BeatGrader.Grade}
var _presses: Array[Dictionary] = []


func _init(set: ComboSet) -> void:
	assert(set != null, "ComboTracker needs a ComboSet")
	combos = set


## Records a press. Returns {"pattern": ComboPattern, "perfect": bool} when a pattern
## completes, or an empty Dictionary.
func press(beat_pos: float, g: BeatGrader.Grade) -> Dictionary:
	_presses.append({"beat": beat_pos, "grade": g})
	while not _presses.is_empty() and beat_pos - float(_presses[0].beat) > TUNING.combo_memory_beats:
		_presses.pop_front()
	# Longer patterns first, so a long run isn't cut short by a shorter one inside it.
	var ordered: Array[ComboPattern] = combos.patterns.duplicate()
	ordered.sort_custom(func(a: ComboPattern, b: ComboPattern) -> bool: return a.intervals.size() > b.intervals.size())
	for pattern in ordered:
		var result := _match(pattern)
		if not result.is_empty():
			_presses.clear()
			return result
	return {}


func reset() -> void:
	_presses.clear()


func _match(pattern: ComboPattern) -> Dictionary:
	var n := pattern.intervals.size()
	if _presses.size() < n + 1:
		return {}
	var start := _presses.size() - (n + 1)
	var perfect := true
	for i in n + 1:
		var g: BeatGrader.Grade = _presses[start + i].grade
		if g < BeatGrader.Grade.GOOD:
			return {}
		if g < BeatGrader.Grade.GREAT:
			perfect = false
	for i in n:
		var gap: float = _presses[start + i + 1].beat - _presses[start + i].beat
		if absf(gap - pattern.intervals[i]) > TUNING.combo_interval_tolerance:
			return {}
	return {"pattern": pattern, "perfect": perfect}
