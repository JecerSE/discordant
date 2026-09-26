# tools/test_combat.gd
extends SceneTree
## godot --headless --path . --script tools/test_combat.gd
## Checks timing grades (#12) and rhythm combo matching (#11). Exit 0 = pass.

var _failures := 0


func _initialize() -> void:
	var window := 0.085
	_expect(BeatGrader.grade(0.0, window) == BeatGrader.Grade.PERFECT, "0 ms is perfect")
	_expect(BeatGrader.grade(0.06, window) == BeatGrader.Grade.GREAT, "60 ms is great")
	_expect(BeatGrader.grade(-0.12, window) == BeatGrader.Grade.GOOD, "-120 ms is good")
	_expect(BeatGrader.grade(0.2, window) == BeatGrader.Grade.MISS, "200 ms is a miss")
	var perfect := BeatGrader.damage_multiplier(BeatGrader.Grade.PERFECT, 0.0, 0)
	var miss := BeatGrader.damage_multiplier(BeatGrader.Grade.MISS, 0.0, 0)
	var mashed := BeatGrader.damage_multiplier(BeatGrader.Grade.MISS, 0.0, 6)
	_expect(perfect > BeatGrader.damage_multiplier(BeatGrader.Grade.GREAT, 0.0, 0), "perfect beats great")
	_expect(miss < 1.0 and mashed < miss, "misses cost damage, mashing costs more")

	var quarter: ComboSet = load("res://content/combat/quarter_combos.tres")
	var t := ComboTracker.new(quarter)
	var G := BeatGrader.Grade
	_expect(t.press(0.0, G.GREAT).is_empty(), "one press is no combo")
	t.press(1.0, G.GREAT)
	t.press(2.02, G.GREAT)
	var r := t.press(3.0, G.PERFECT)
	_expect(not r.is_empty() and r.pattern.pattern_name == "Common Time" and r.perfect, "four quarters = perfect Common Time")

	t.reset()
	t.press(10.0, G.GREAT)
	t.press(10.5, G.GOOD)
	r = t.press(11.0, G.GREAT)
	_expect(not r.is_empty() and r.pattern.pattern_name == "Syncopated Run" and not r.perfect, "eighth-eighth-quarter = Syncopated Run (a good is not perfect)")

	t.reset()
	t.press(20.0, G.GREAT)
	t.press(21.0, G.MISS)
	t.press(22.0, G.GREAT)
	r = t.press(23.0, G.GREAT)
	_expect(r.is_empty(), "a missed press breaks the combo")

	var whole: ComboSet = load("res://content/combat/whole_combos.tres")
	var w := ComboTracker.new(whole)
	w.press(0.0, G.GREAT)
	r = w.press(4.0, G.GREAT)
	_expect(not r.is_empty() and r.pattern.pattern_name == "Semibreve", "two strikes a bar apart = Semibreve")

	var eighth: ComboSet = load("res://content/combat/eighth_combos.tres")
	var e := ComboTracker.new(eighth)
	for i in 4:
		e.press(i * 0.5, G.GREAT)
	r = e.press(2.0, G.GREAT)
	_expect(not r.is_empty() and r.pattern.pattern_name == "Eighth Run", "five eighths = Eighth Run")

	if _failures == 0:
		print("test_combat: ok")
	quit(1 if _failures > 0 else 0)


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_failures += 1
		push_error("FAILED: " + what)
