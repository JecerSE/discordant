class_name VoidLook
extends Resource
## The Void: not a place, what the hush becomes as it wins. A continuous function of the
## existing graduated hush (Synth.hush, 0 when a room is free, up to 1 when the Rest holds it):
## as it rises, the season drains toward grey, its particles thin out and the parallax planes
## fade into one flat tone. No state of its own. Switched off by removing "void_look" from
## render_flags.tres.

const FLAG := "void_look"
const PATH := "res://content/art/void_look.tres"

## Set by tests and captures to pin the hush the Void reads (-1 = read the real one).
static var forced_hush := -1.0
static var _look: VoidLook

## Hush where the Void begins, and where it is complete.
@export var start_hush := 0.2
@export var full_hush := 1.0
## At full Void: how far colours drain toward their own grey (0..1), the share of particles
## still drifting, and the one faint alpha every plane fades to.
@export var desaturate := 0.85
@export var particle_keep := 0.2
@export var flat_alpha := 0.03


static func look() -> VoidLook:
	if _look == null:
		_look = load(PATH)
	return _look


## How far the Void has come (0..1) at hush `hush`.
static func amount(hush: float) -> float:
	if not RenderAdapter.is_on(FLAG):
		return 0.0
	var l := look()
	var h := forced_hush if forced_hush >= 0.0 else hush
	return clampf(inverse_lerp(l.start_hush, l.full_hush, h), 0.0, 1.0)


## `c` drained toward its own grey by `amt` (0..1), alpha kept.
static func drain(c: Color, amt: float) -> Color:
	var g := c.get_luminance()
	return Color(lerpf(c.r, g, amt), lerpf(c.g, g, amt), lerpf(c.b, g, amt), c.a)
