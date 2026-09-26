class_name ComboFinishers
## What each rhythm combo does when it completes (issue #11). Every finisher counts
## as on the beat; a perfect combo multiplies its damage.

const TUNING: TimingTuning = preload("res://content/tuning/timing_tuning.tres")


static func execute(p: Player, pattern: ComboPattern, perfect: bool) -> void:
	var dmg := pattern.damage * (TUNING.combo_perfect_multiplier if perfect else 1.0)
	var grade := BeatGrader.Grade.PERFECT if perfect else BeatGrader.Grade.GREAT
	var info := {"kind": "melee", "on_beat": true, "grade": grade, "combo": true}
	var room: Node = p.room
	room.float_text(p.global_position + Vector2(0, -p.size * 5.0), pattern.pattern_name + (" · perfect" if perfect else ""), Pal.GOLD, 22 if perfect else 18)
	Synth.sfx_play("chime", -8.0 if perfect else -12.0)
	room.shake(6.0 if perfect else 3.0)
	match pattern.finisher:
		&"common_time":
			_ring(p, p.global_position + Vector2(p.facing * 40.0, 0), 150.0, dmg, info, 0.0)
			Powers.fire_wave(p, dmg * 0.5, 1.2, true, true)
		&"syncopated_run":
			p._start_dash(true, 300.0, dmg)
		&"cut_time":
			_ring(p, p.global_position, 160.0, dmg, info, 0.0)
			p._later(Beat.beat_len() / Beat.tempo_scale, func(): _ring(p, p.global_position, 160.0, dmg * 0.6, info, 0.0))
		&"dotted_rise":
			var rect := Rect2(p.global_position + Vector2(0.0 if p.facing > 0.0 else -150.0, -110.0), Vector2(150.0, 140.0))
			for e in room.alive_enemies():
				if rect.grow(e.r).has_point(e.global_position):
					var i := info.duplicate()
					i["knock"] = Vector2(p.facing * 200.0, -900.0)
					p.deal(e, dmg, i)
			p.launch(Vector2(0.0, -520.0))
		&"semibreve":
			Powers.spawn_shockwaves(p, dmg, true)
			_ring(p, p.global_position, 180.0, dmg * 0.5, info, 2.0)
		&"stomp_time":
			_ring(p, p.global_position, 130.0, dmg, info, 1.2)
		&"eighth_run":
			p.drumroll_n = 6
			p.drumroll_t = 0.0
			p.drumroll_dmg = dmg
		&"swing_cut":
			var e = room.nearest_enemy(p.global_position, 520.0)
			if e == null:
				p._start_dash(true, 260.0, dmg)
				return
			var side: float = signf(e.global_position.x - p.global_position.x)
			if side == 0.0:
				side = 1.0
			room.add_line_fx(p.global_position, e.global_position, Pal.GOLD)
			p.global_position = e.global_position + Vector2(side * (e.r + 26.0), 0)
			p.facing = -side
			p.iframes = maxf(p.iframes, 0.25)
			var i2 := info.duplicate()
			i2["knock"] = Vector2(-side * 220.0, -220.0)
			p.deal(e, dmg, i2)
		_:
			push_error("ComboFinishers: unknown finisher %s" % pattern.finisher)


static func _ring(p: Player, at: Vector2, radius: float, dmg: float, info: Dictionary, stun: float) -> void:
	var r := FX.Ring.new()
	r.radius = radius * (1.0 + Game.flag("big_waves"))
	r.dmg = dmg
	r.info = info.merged({"aoe": true})
	r.color = Pal.GOLD
	r.stun = stun
	r.position = at
	p.room.add_fx(r)
