# tools/sweep_picker.gd
extends RefCounted
## Chooses a card on the reward screens (chests, teachers, fermatas, keeper gifts) for the
## sweep bot, and records every pick. "first_card" always takes card 0, which is what pressing
## accept did before. "random" draws from its own RandomNumberGenerator, seeded from the run
## seed: it never touches a game stream, so the game's own randomness is unaffected.

var policy := "first_card"
var picks: Array = []
var _rng := RandomNumberGenerator.new()
var _decided := {}


func _init(item_policy: String, run_seed: int) -> void:
	policy = item_policy
	_rng.seed = hash([run_seed, "sweep_bot_picks"])


## Called every frame an overlay is open. Sets the selection on a choice screen (deciding
## once per screen) so the bot's accept press takes it. Other overlays keep their default.
func steer(overlay: Node, bar: int, room_type: String) -> void:
	if not overlay.get_script().resource_path.ends_with("choice.gd"):
		return
	var ids: Array = overlay.ids
	if ids.is_empty():
		return
	var key := overlay.get_instance_id()
	if not _decided.has(key):
		var i := 0 if policy == "first_card" else _rng.randi_range(0, ids.size() - 1)
		_decided[key] = i
		picks.append({"bar": bar, "room": room_type, "title": overlay.title, "offered": ids.duplicate(), "picked": ids[i]})
	overlay.sel = _decided[key]
