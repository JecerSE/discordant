class_name PowersData
## Active powers: Percussion, Wind, String and Rest.
## Split from the original content.gd without changing any values.

const POWERS := {
	# Percussion — the beat, the ground, the weight.
	"shockwave": {"name": "Shockwave", "family": "percussion", "cd": 5.0, "dmg": 26,
		"desc": "Slam the ground; a wave runs both ways along it. In the air, dive first."},
	"parry": {"name": "Rimshot Parry", "family": "percussion", "cd": 2.2, "dmg": 20,
		"desc": "A brief guard. Blocked hits are negated, shots are reflected, and your next strike lands on the beat."},
	"drumroll": {"name": "Drumroll", "family": "percussion", "cd": 6.0, "dmg": 9,
		"desc": "Six rapid strikes in front of you, each one counted on the beat."},
	"earthbend": {"name": "Timpani Pillar", "family": "percussion", "cd": 7.0, "dmg": 22,
		"desc": "Raise a pillar of stone ahead. It launches whatever stands there and stays as a wall for a while."},
	# Wind — breath and speed.
	"gale_dash": {"name": "Gale Dash", "family": "wind", "cd": 3.0, "dmg": 18,
		"desc": "A long dash that cuts through enemies. A kill refunds the cooldown."},
	"updraft": {"name": "Updraft", "family": "wind", "cd": 6.0, "dmg": 10,
		"desc": "Fly up and hover for a moment. Hits enemies below you."},
	"breath_charge": {"name": "Breath Charge", "family": "wind", "cd": 4.0, "dmg": 34,
		"desc": "Hold to charge, release to blow a gust. A full charge knocks enemies flying."},
	"fade": {"name": "Fade", "family": "wind", "cd": 11.0, "dmg": 0,
		"desc": "Turn invisible for 3 seconds. Your first hit out of it deals double."},
	"tempest": {"name": "Tempest", "family": "wind", "cd": 18.0, "dmg": 8,
		"desc": "Summon a tornado that drags enemies in and lifts them, grinding them for 4 seconds."},
	# String — echo, pull, harmony.
	"soundwave": {"name": "Soundwave", "family": "string", "cd": 1.1, "dmg": 16,
		"desc": "Fire a wave of sound that passes through its target."},
	"echo": {"name": "Echo", "family": "string", "cd": 9.0, "dmg": 0,
		"desc": "For 4 seconds, all damage you deal repeats one beat later."},
	"soul_pull": {"name": "Soul Pull", "family": "string", "cd": 4.0, "dmg": 12,
		"desc": "Hook the nearest enemy you face and reel it in, stunned."},
	"tether": {"name": "Tether", "family": "string", "cd": 9.0, "dmg": 0,
		"desc": "Link up to four nearby enemies: damage to one is shared, 60%, with the rest."},
	"reverb_shield": {"name": "Reverb Shield", "family": "string", "cd": 8.0, "dmg": 0,
		"desc": "A shield that absorbs 35 damage for 3 seconds, then releases what it caught as a ring."},
	# The margin — taught in secret by the Scribble. Strange and strong.
	"fermata": {"name": "Fermata", "family": "margin", "cd": 20.0, "dmg": 0,
		"desc": "Everything but you stops for 3 seconds. Damage you deal is saved up and lands all at once, x1.5, when time starts again."},
	"caesura": {"name": "Caesura", "family": "margin", "cd": 12.0, "dmg": 30,
		"desc": "Untouchable for 2 seconds but unable to strike. When it ends, everything near you is silenced."},
	"da_capo": {"name": "Da Capo", "family": "margin", "cd": 15.0, "dmg": 0,
		"desc": "Go back to where you were, and the health you had, 3 seconds ago."},
	"grace_note": {"name": "Grace Note", "family": "margin", "cd": 2.5, "dmg": 20,
		"desc": "Teleport behind the nearest enemy and hit it."},
	"accelerando": {"name": "Accelerando", "family": "margin", "cd": 16.0, "dmg": 0,
		"desc": "The whole page plays at double tempo for 5 seconds. Enemies too."},
	"ghost_note": {"name": "Ghost Note", "family": "margin", "cd": 10.0, "dmg": 40,
		"desc": "Leave a decoy of yourself. Enemies go after it. It explodes after 3 seconds."},
}
