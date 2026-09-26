class_name RelicsData
## Relics and champion memorabilia.
## Split from the original content.gd without changing any values.

const RELICS := {
	"rosin": {"name": "Rosin", "price": 70, "desc": "+12% damage.", "mods": {"dmg": 0.12}},
	"tuning_fork": {"name": "Tuning Fork", "price": 80, "desc": "On-beat hits heal 1 HP.", "flags": {"on_beat_heal": 1}},
	"brass_metronome": {"name": "Brass Metronome", "price": 60, "desc": "Beat window +30 ms.", "mods": {"beat_window": 0.03}},
	"sheet_protector": {"name": "Sheet Protector", "price": 65, "desc": "+20 max HP.", "mods": {"max_hp": 20}},
	"ear_plugs": {"name": "Ear Plugs", "price": 75, "desc": "Take 12% less damage.", "mods": {"dr": 0.12}},
	"valve_oil": {"name": "Valve Oil", "price": 60, "desc": "+10% move speed, dash cooldown 15% shorter.", "mods": {"speed": 0.1, "dash_cdr": 0.15}},
	"capo": {"name": "Capo", "price": 75, "desc": "Power cooldowns 12% shorter.", "mods": {"cdr": 0.12}},
	"page_turner": {"name": "Page Turner", "price": 70, "desc": "+1 jump.", "mods": {"jumps": 1}},
	"practice_mute": {"name": "Practice Mute", "price": 55, "desc": "Enemy projectiles fly 25% slower.", "mods": {"enemy_proj_slow": 0.25}},
	"encore_ticket": {"name": "Encore Ticket", "price": 60, "desc": "Heal 8 HP when a room is cleared.", "flags": {"clear_heal": 8}},
	"gold_leaf": {"name": "Gold Leaf", "price": 50, "desc": "+35% sharps.", "mods": {"sharps": 0.35}},
	"espresso": {"name": "Espresso", "price": 70, "desc": "+15% attack speed. Shaky hands.", "mods": {"atk_speed": 0.15}},
	"sustain_pedal": {"name": "Sustain Pedal", "price": 80, "desc": "Powers deal +22% damage.", "mods": {"power_dmg": 0.22}},
	"tempo_marking": {"name": "Tempo Marking", "price": 55, "desc": "Your first attack in each room always lands on the beat.", "flags": {"first_attack_beat": 1}},
	"bent_paperclip": {"name": "Bent Paperclip", "price": 30, "desc": "+1 sharp per kill. Found it on the floor.", "flags": {"kill_sharps": 1}},
	"pencil_stub": {"name": "Pencil Stub", "price": 85, "desc": "Heal for 3% of the damage you deal.", "mods": {"lifesteal": 0.03}},
	"double_stop": {"name": "Double Stop", "price": 90, "desc": "Melee hits strike a second time for 30%.", "flags": {"double_stop": 0.3}},
	"rubber_mallet": {"name": "Rubber Mallet", "price": 60, "desc": "Melee knocks enemies back much farther.", "flags": {"knockback": 0.8}},

	# Champion memorabilia — only from fallen elites.
	"timpanist_mallet": {"name": "Timpanist's Mallet", "champion": true, "family": "percussion", "desc": "Every fourth melee hit releases a shockwave.", "flags": {"mallet_shock": 4}},
	"cymbal_shard": {"name": "Cymbal Shard", "champion": true, "family": "percussion", "desc": "On-beat hits crash in a ring for 45%. +10 max HP.", "mods": {"max_hp": 10}, "flags": {"cymbal_crash": 0.45}},
	"piper_reed": {"name": "Piper's Reed", "champion": true, "family": "wind", "desc": "Dashing through enemies cuts them for 20. Dash cooldown 25% shorter.", "mods": {"dash_cdr": 0.25}, "flags": {"piper_dash": 20}},
	"horn_bell": {"name": "Hornist's Bell", "champion": true, "family": "wind", "desc": "+20% move speed. Damage scales with speed.", "mods": {"speed": 0.2}, "flags": {"horn_scaling": 1}},
	"violist_bow": {"name": "Violist's Bow", "champion": true, "family": "string", "desc": "Every melee hit also fires a small soundwave.", "flags": {"pizzicato": 1.0}},
	"cello_endpin": {"name": "Cellist's Endpin", "champion": true, "family": "string", "desc": "+40 max HP. Taking a hit rings out for 15 damage around you.", "mods": {"max_hp": 40}, "flags": {"cello_reverb": 15}},
}
