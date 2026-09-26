class_name DamageNumbers
extends RefCounted
## Turns every hit into on-screen numbers without stacking duplicates.
## Hits on one target within the merge window add into a single number per channel,
## so a swing plus its follow-ups (Sustain, Double Stop, crashes) reads as one hit.

enum Style { NORMAL, ON_BEAT, FOLLOW_UP, ECHO, SHARED, STORED }

const TUNING: FeedbackTuning = preload("res://content/tuning/feedback_tuning.tres")

## Which styles share a number. Follow-ups merge into the main hit; echoes, shared
## tether damage and Fermata-stored damage each get their own number.
const CHANNEL := {
	Style.NORMAL: 0, Style.ON_BEAT: 0, Style.FOLLOW_UP: 0,
	Style.ECHO: 1, Style.SHARED: 2, Style.STORED: 3,
}

## key "instance_id:channel" -> {"node": WeakRef, "until_ms": int}
var _open: Dictionary = {}


func show(host: Node, target: Node2D, radius: float, amount: float, style: Style) -> void:
	if amount <= 0.0 or not is_instance_valid(target):
		return
	var now := Time.get_ticks_msec()
	var key := "%d:%d" % [target.get_instance_id(), CHANNEL[style]]
	var entry: Dictionary = _open.get(key, {})
	var existing: FxDamageNumber = null
	if not entry.is_empty() and now <= int(entry.until_ms):
		existing = entry.node.get_ref() as FxDamageNumber
	if existing != null:
		var col := existing.color
		if style == Style.ON_BEAT:
			col = _color(style)
		existing.add(amount, col)
		entry.until_ms = now + TUNING.damage_merge_window_ms
		return
	var n := FxDamageNumber.new()
	n.base_size = TUNING.on_beat_font_size if style == Style.ON_BEAT else (TUNING.damage_font_size if CHANNEL[style] == 0 else TUNING.channel_font_size)
	n.pop_size = TUNING.merge_pop_size
	n.size = n.base_size
	n.position = target.global_position + Vector2(randf_range(-8.0, 8.0), -radius - 12.0 - 14.0 * CHANNEL[style])
	n.add(amount, _color(style))
	host.add_fx(n)
	_open[key] = {"node": weakref(n), "until_ms": now + TUNING.damage_merge_window_ms}
	_prune(now)


func _color(style: Style) -> Color:
	match style:
		Style.ON_BEAT: return Pal.GOLD
		Style.ECHO, Style.SHARED: return Pal.STRING
		Style.STORED: return Pal.MARGIN
	return Pal.INK


func _prune(now: int) -> void:
	for k in _open.keys():
		if now > int(_open[k].until_ms) + 1000:
			_open.erase(k)
