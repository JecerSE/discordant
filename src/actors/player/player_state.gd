class_name PlayerState
extends CharacterBody2D
## Layer 1 of 6. Every field the player has, plus small read-only helpers.
## Split from the original player.gd without logic changes.

const GRAV := 2100.0
const JUMP_V := 790.0
const MAX_FALL := 980.0
const DASH_SPEED := 720.0
const DASH_TIME := 0.15
const DASH_CD := 0.75
const COYOTE := 0.1
const BUFFER := 0.13
const MOVE_TUNING: PlayerMovementTuning = preload("res://content/tuning/player_movement_tuning.tres")

var room: Node
var char_id := "quarter"
var size := 13.0
var facing := 1.0
var hp := 100.0
var max_hp := 100.0
var dead := false
var controllable := true

var jumps_left := 0
var coyote := 0.0
var jump_buf := 0.0
var atk_buf := 0.0
var dash_t := 0.0
var dash_cd := 0.0
var dash_dir := 1.0
var dash_speed := DASH_SPEED
var dash_power := false
var dash_dmg := 0.0
var dash_hit := {}
var dash_from := Vector2.ZERO
var iframes := 0.0
var hurt_flash := 0.0
var atk_cd := 0.0
var combo := 0
var combo_t := 0.0
var swing_t := 0.0
var swing_len := 0.2
var squash := 1.0
var cds: Array[float] = [0.0, 0.0, 0.0]
var push := Vector2.ZERO
var drop_t := 0.0
var blink_t := 2.0
var afterimages: Array = []

# Power state.
var parry_t := 0.0
var primed := false
var shield_hp := 0.0
var shield_t := 0.0
var shield_absorbed := 0.0
var fade_t := 0.0
var fade_bonus := false
var updraft_t := 0.0
var charging := -1
var charge := 0.0
var caesura_t := 0.0
var echo_t := 0.0
var accel_t := 0.0
var drumroll_n := 0
var drumroll_t := 0.0
var drumroll_dmg := 0.0
var diving := ""
var dive_dmg := 0.0
var history: Array = []
var _hist_t := 0.0

# Rune state.
var crescendo := 0
var mallet_count := 0
var first_attack_used := false
var still_t := 0.0
var peak_y := 0.0
var _was_floor := true
var tether_src: Node = null
var bound_by: Node = null
var marks := 0
var marks_t := 0.0
var stagger_t := 0.0
# Momentum carry and launches (issue #15).
var momentum_t := 0.0
var launch_lock := 0.0
# Timing grades and rhythm combos (issues #11, #12, #14).
var last_grade: BeatGrader.Grade = BeatGrader.Grade.NONE
var pending_grade: BeatGrader.Grade = BeatGrader.Grade.NONE
var pending_down := false
var pending_combo := {}
var mash_stacks := 0
var combo_tracker: ComboTracker
var jump_grade: BeatGrader.Grade = BeatGrader.Grade.NONE
var flow_t := 0.0
var dash_on_beat := false


func refresh_stats() -> void:
	var s := Game.stats()
	var old_max := max_hp
	max_hp = s.max_hp
	if max_hp > old_max and old_max > 0.0 and hp > 0.0:
		hp += max_hp - old_max
	hp = minf(hp, max_hp)


func stats() -> Dictionary:
	return Game.stats()


func speed() -> float:
	var s := stats()
	var sp: float = s.base_speed * (1.0 + s.speed)
	if accel_t > 0.0:
		sp *= 1.3
	if flow_t > 0.0:
		sp *= 1.0 + MOVE_TUNING.flow_speed_bonus
	return sp


func feet_y() -> float:
	return global_position.y + size
