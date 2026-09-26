class_name TitleArt
## The pieces the title screen and the intro's last shot share, so the cutscene can hand
## over to the menu without a jump: the pixel logo, its subtitle and the falling note.

const TUNING: CinematicTuning = preload("res://content/tuning/cinematic_tuning.tres")
const LOGO: Texture2D = preload("res://assets/ui/logo.png")
const SUBTITLE := "a quarter note fell off the Grand Score"
const SUBTITLE_GAP := 34.0
const SUBTITLE_COLOR := Color(0.95, 0.92, 0.85)


## The logo centred on TUNING.logo_center, grown by mul (1 = resting size).
static func logo(ci: CanvasItem, mul := 1.0, alpha := 1.0) -> void:
	var size := LOGO.get_size() * TUNING.logo_scale * mul
	var r := Rect2(TUNING.logo_center - size * 0.5, size)
	ci.draw_texture_rect(LOGO, r, false, Color(1, 1, 1, alpha))


static func subtitle(ci: CanvasItem, alpha := 1.0) -> void:
	var y := TUNING.logo_center.y + LOGO.get_size().y * TUNING.logo_scale * 0.5 + SUBTITLE_GAP
	UI.text(ci, Vector2(TUNING.logo_center.x, y), SUBTITLE, 22, Color(SUBTITLE_COLOR, alpha), HORIZONTAL_ALIGNMENT_CENTER)


## Our quarter note tumbling down the right side of the screen, forever.
static func falling_note(ci: CanvasItem, t: float, screen: Vector2) -> void:
	var fall := fmod(t / TUNING.title_fall_time, 1.0)
	var x := screen.x * 0.8 + sin(t * 1.3) * 30.0
	var y := lerpf(-80.0, screen.y + 80.0, fall)
	ArtLibrary.draw_anim(ci, "note_quarter", &"fall", t, Vector2(x, y), 5.0, sin(t * 2.0) * 0.6)
