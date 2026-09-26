class_name EnemyState
extends CharacterBody2D
## Layer 1 of 7. Every field an enemy has, setup from Content, targeting and
## small queries. Split from the original enemy.gd without logic changes.

const GRAV := 2000.0
const TUNING: EnemyTuning = preload("res://content/tuning/enemy_tuning.tres")

var room: Node
var id := ""
var def := {}
var ename := ""
var hp := 30.0
var max_hp := 30.0
var dmg := 10.0
var spd := 100.0
var r := 18.0
var ai := "walker"
var weight := 0.0
var boss := false
var elite := false
var family := ""
var dead := false
var facing := -1.0
var stun := 0.0
var knock_t := 0.0
var accented := false
var tether_t := 0.0
var stored_damage := 0.0
var hit_flash := 0.0
var hp_bar_t := 0.0
var t := 0.0
var state := ""
var st := 0.0
var telegraph := 0.0
var flying := false
var home := Vector2.ZERO
var contact_cd := 0.0
var beat_offset := 0
var swoop_target := Vector2.ZERO
var hits_taken := 0
var _was_floor := true
var _tether_tick := 0
# The newer Rests' mechanics.
var stance := true          # rim guard: turns aside off-beat hits
var stance_beats := 0
var buff_t := 0.0           # rallied by a bandleader or breathed for by a reed
var invis := false          # breathless rest: only area attacks reach it
var barrier := false        # reverb warden: throws shots back, staggers strikers
var dash_dir := Vector2.ZERO
# Detection and idle wandering (issue #2).
var aggro := false
var patrol: EnemyPatrol
var turn_cd := 0.0
# Super armor for elites and bosses (issue #3).
var stun_immune_t := 0.0


func setup(enemy_id: String, hp_scale := 1.0, dmg_scale := 1.0) -> void:
	id = enemy_id
	def = Content.ENEMIES.get(enemy_id, {})
	ename = def.get("name", enemy_id)
	max_hp = float(def.get("hp", 30)) * hp_scale
	hp = max_hp
	dmg = float(def.get("dmg", 10)) * dmg_scale
	spd = float(def.get("speed", 100.0))
	r = float(def.get("r", 18.0))
	ai = def.get("ai", "walker")
	weight = float(def.get("weight", 0.0))
	elite = def.get("elite", false)
	family = def.get("family", "")
	flying = ai in ["flyer", "shooter", "gust", "echo", "elite_piper", "elite_violist", "dasher", "phantom", "motif"]
	beat_offset = randi() % 4


func target_pos() -> Vector2:
	if room.decoy and is_instance_valid(room.decoy):
		return room.decoy.global_position
	var p = room.player
	if p and p.is_targetable() and aggro:
		return p.global_position
	return Vector2(patrol.target_x if patrol else home.x, home.y)


func has_target() -> bool:
	var p = room.player
	return (room.decoy and is_instance_valid(room.decoy)) or (p and p.is_targetable() and aggro)


## States in which an elite or boss has committed to an attack.
const COMMITTED_STATES := ["windup", "charge", "swoop", "air", "dash", "dive", "gust_windup", "pull_windup", "pull"]


## Elites and bosses can't be stunned, knocked back or interrupted while they wind up
## or carry out an attack. Hits still deal damage.
func has_super_armor() -> bool:
	return (elite or boss) and (telegraph > 0.0 or state in COMMITTED_STATES)


## Notice the player inside aggro range, lose them past leash range. Elites and
## bosses always know where the player is.
func update_aggro() -> void:
	if elite or boss:
		aggro = true
		return
	var p = room.player
	if p == null:
		aggro = false
		return
	var dist: float = global_position.distance_to(p.global_position)
	if dist <= TUNING.aggro_range:
		aggro = true
	elif dist > TUNING.leash_range:
		aggro = false


func grounded() -> bool:
	return not flying and is_on_floor()


func feet_y() -> float:
	return global_position.y + r


func _tele(beats := 1.0) -> void:
	telegraph = Beat.beat_len() * beats


func _ground_ahead() -> bool:
	var space := get_world_2d().direct_space_state
	var from := global_position + Vector2(facing * (r + 6.0), 0)
	var q := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, r + 30.0), 3)
	return not space.intersect_ray(q).is_empty()


func _fly_to(p: Vector2, d: float, s: float) -> void:
	var to := p - global_position
	var want := to.normalized() * minf(s, to.length() * 3.0)
	velocity = velocity.move_toward(want, 1400.0 * d)


func dmg_mult() -> float:
	return 1.3 if buff_t > 0.0 else 1.0


func untargetable() -> bool:
	return ai == "phantom" and invis


func reflects() -> bool:
	return ai == "warden" and barrier


func on_reflect() -> void:
	Synth.sfx_play("ping", -8.0, 4.0)


func redirects(_p: Node) -> bool:
	return ai == "binder" and state == "bind"
