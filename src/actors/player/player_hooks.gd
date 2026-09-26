class_name PlayerHooks
extends PlayerAttacks
## Layer 4 of 6. Runes and effects that run on the clock: bar and beat hooks,
## 4'33", Da Capo history, Motif marks, stagger.

func _on_bar(_n: int) -> void:
	if dead or room == null or get_tree().paused or not room.combat_active():
		return
	if Game.flag("auto_wave") > 0.0:
		var e = room.nearest_enemy(global_position, 900.0)
		if e:
			var dir: Vector2 = (e.global_position - global_position).normalized()
			Powers.fire_wave_dir(self as Player, dir, 12.0, 0.8)


func _on_beat(n: int) -> void:
	if dead or room == null or get_tree().paused or not room.combat_active():
		return
	var th := Game.flag("theremin")
	if th > 0.0:
		for e in room.enemies_in_circle(global_position, 95.0):
			deal(e, th, {"kind": "power", "proc": false, "aoe": true})
	var dw := Game.flag("drone_wave")
	if dw > 0.0 and n % 2 == 0:
		Powers.fire_wave_dir(self as Player, Vector2(-facing, 0), dw, 0.7, false)


func _four_thirty_three(delta: float, dir: float) -> void:
	if Game.flag("four_thirty_three") <= 0.0:
		return
	var moving := absf(dir) > 0.1 or not is_on_floor() or Input.is_action_pressed("attack")
	if moving:
		if still_t > 0.6:
			Synth.hush = room.base_hush()
		still_t = 0.0
	else:
		still_t += delta
		if still_t > 0.6:
			heal(4.0 * delta, false)
			Synth.hush = 1.0


func _record_history(delta: float) -> void:
	_hist_t -= delta
	if _hist_t <= 0.0:
		_hist_t = 0.1
		history.append({"p": global_position, "hp": hp})
		if history.size() > 31:
			history.pop_front()


## A Motif Rest's mark. Three and the motif resolves on you.
func add_mark() -> void:
	marks += 1
	marks_t = 5.0
	room.float_text(global_position + Vector2(0, -52), "marked %d/3" % marks, Pal.STRING, 16)
	if marks >= 3:
		marks = 0
		iframes = 0.0
		room.announce("", "the motif resolves", Pal.STRING)
		var r := FX.Ring.new()
		r.team = "none"
		r.radius = 90.0
		r.color = Pal.STRING
		r.position = global_position
		room.add_fx(r)
		take_hit(34.0, global_position, {"unblockable": true})


func stagger(t: float) -> void:
	stagger_t = maxf(stagger_t, t)
	velocity.x = -facing * 260.0
	room.float_text(global_position + Vector2(0, -52), "staggered", Pal.HUSH, 16)
