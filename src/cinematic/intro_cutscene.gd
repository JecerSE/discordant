class_name IntroCutscene
extends Control
## The prologue: plays IntroData.SHOTS in order with letterbox bars, typed captions,
## timed sounds, shakes and flashes, and ends by slamming the logo down on a beat and
## handing over to the title screen. Space jumps to the next shot, Esc skips it all.

const TUNING: CinematicTuning = preload("res://content/tuning/cinematic_tuning.tres")
const CAPTION_DELAY := 0.3
const CAPTION_COLOR := Color(0.95, 0.92, 0.85)
const HINT_COLOR := Color(0.7, 0.68, 0.75)

var _shot_i := -1
var _shot: Dictionary = {}
var _t := 0.0
var _total_t := 0.0
var _cue_i := 0
var _shake := 0.0
var _flash := 0.0
var _bars := 0.0
var _slam_at := 0.0
var _slammed := false
var _leaving := false
var _grace := 0.3
var _area := ""
var _backdrop: EnvironmentBackdrop


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_next_shot()


func _process(delta: float) -> void:
	if _leaving:
		return
	_t += delta
	_total_t += delta
	_grace = maxf(0.0, _grace - delta)
	_shake = move_toward(_shake, 0.0, TUNING.shake_decay * delta)
	_flash = maxf(0.0, _flash - delta)
	_run_cues()
	_follow_hush()
	if _shot.kind == "title" and not _slammed and _t >= _slam_at:
		_slam()
	var open_up: bool = _shot.kind == "title" and _slammed and _t > _slam_at + 0.4
	_bars = move_toward(_bars, 0.0 if open_up else 1.0, delta / TUNING.letterbox_slide)
	position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake
	if _grace <= 0.0:
		if Input.is_action_just_pressed("pause") or Input.is_action_just_pressed("ui_cancel"):
			_finish()
			return
		if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("attack"):
			_t = _shot.time
	if _t >= _shot.time:
		_next_shot()
	queue_redraw()


func _next_shot() -> void:
	_shot_i += 1
	if _shot_i >= IntroData.SHOTS.size():
		_finish()
		return
	_shot = IntroData.SHOTS[_shot_i]
	_t = 0.0
	_cue_i = 0
	_set_area(_shot.area)
	var song: Dictionary = Content.PAGES[_shot.song].song
	if _shot_i == 0:
		Synth.start_song(song)
	elif Synth.song.get("seed", "") != song.seed:
		Synth.transition_to(song)
	if _shot.kind == "title":
		# Land on a beat, so the crash is in time with the music.
		_slam_at = IntroData.SLAM_AT + Beat.time_to_next_beat()
		_slammed = false


func _set_area(area: String) -> void:
	if area == _area:
		return
	_area = area
	if _backdrop:
		_backdrop.queue_free()
		_backdrop = null
	if area == "":
		return
	_backdrop = EnvironmentBackdrop.new()
	_backdrop.setup_area(area, TUNING.title_drift)
	add_child(_backdrop)
	move_child(_backdrop, 0)


func _run_cues() -> void:
	var cues: Array = _shot.cues
	while _cue_i < cues.size() and _t >= cues[_cue_i].t:
		_cue(cues[_cue_i])
		_cue_i += 1


func _cue(c: Dictionary) -> void:
	if c.has("sfx"):
		Synth.sfx_play(c.sfx, -4.0)
	if c.has("shake"):
		_shake = TUNING.shake_strength * float(c.shake)
	if c.get("flash", false):
		_flash = TUNING.flash_time


func _slam() -> void:
	_slammed = true
	_cue({"sfx": "crash", "shake": 1.0, "flash": true})
	Synth.sfx_play("boom", -6.0)


## The music muffles and clears as the shot's hush range says; the scenery follows.
func _follow_hush() -> void:
	var h: Array = _shot.hush
	var f := clampf(_t / float(_shot.time), 0.0, 1.0)
	if _shot.kind == "title":
		f = 1.0 if _slammed else 0.0
	var hush := lerpf(h[0], h[1], f)
	Synth.hush = hush
	if _backdrop:
		_backdrop.hush = hush


func _finish() -> void:
	if _leaving:
		return
	_leaving = true
	Game.meta.seen_prologue = true
	Game.save()
	Synth.hush = 0.0
	Game.goto("title", {"from_intro": true})


func _draw() -> void:
	if _shot.is_empty():
		return
	var sz := size
	IntroShots.draw(self, _shot.kind, _t, _shot.time, {"slam_at": _slam_at})
	if _flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, sz), Color(1, 1, 1, _flash / TUNING.flash_time * 0.8))
	_draw_letterbox(sz)


func _draw_letterbox(sz: Vector2) -> void:
	var bar := TUNING.letterbox_height * ease(_bars, -2.0)
	if bar <= 0.5:
		return
	draw_rect(Rect2(-20, -20, sz.x + 40, bar + 20), Color.BLACK)
	draw_rect(Rect2(-20, sz.y - bar, sz.x + 40, bar + 20), Color.BLACK)
	var text: String = _shot.caption
	var shown := int(maxf(0.0, _t - CAPTION_DELAY) * TUNING.type_speed)
	if shown > 0 and _bars > 0.9:
		UI.text(self, Vector2(sz.x * 0.5, sz.y - bar * 0.5 + 8.0), text.substr(0, shown), TUNING.caption_size, CAPTION_COLOR, HORIZONTAL_ALIGNMENT_CENTER)
	var hint_a := clampf(1.0 - (_total_t - TUNING.skip_hint_time), 0.0, 1.0)
	if hint_a > 0.0:
		UI.text(self, Vector2(sz.x - 24, bar * 0.5 + 6.0), "Space: next   Esc: skip", 14, Color(HINT_COLOR, hint_a), HORIZONTAL_ALIGNMENT_RIGHT)
