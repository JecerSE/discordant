class_name RunesData
## Runes, family set bonuses and dissonance combos.
## Split from the original content.gd without changing any values.

# swap: equip in your three rune slots, change them outside combat.
# family: swap runes that belong to a pillar; two or three of a family awaken a set bonus.
# permanent: bound to you for the run the moment you take one. Strong, and never removed.
# margin: red-pencil runes. Permanent, powerful, and each one breaks a rule of the game.
const RUNES := {
	"metronome": {"name": "Metronome Rune", "kind": "swap", "desc": "Beat window +40 ms.", "mods": {"beat_window": 0.04}},
	"forte": {"name": "Forte", "kind": "swap", "desc": "+15% damage.", "mods": {"dmg": 0.15}},
	"leggiero": {"name": "Leggiero", "kind": "swap", "desc": "+14% move speed.", "mods": {"speed": 0.14}},
	"staccato": {"name": "Staccato", "kind": "swap", "desc": "+20% attack speed.", "mods": {"atk_speed": 0.2}},
	"legato": {"name": "Legato", "kind": "swap", "desc": "Power cooldowns 18% shorter.", "mods": {"cdr": 0.18}},
	"crescendo": {"name": "Crescendo", "kind": "swap", "desc": "Each consecutive on-beat hit deals 6% more (up to 60%). An off-beat hit resets it.", "flags": {"crescendo": 0.06}},
	"accent": {"name": "Accent", "kind": "swap", "desc": "Your first hit on each enemy deals +60%.", "flags": {"accent": 0.6}},
	"dynamics": {"name": "Dynamics", "kind": "swap", "desc": "Powers deal +25% damage.", "mods": {"power_dmg": 0.25}},

	"bass_drum": {"name": "Bass Drum", "kind": "family", "family": "percussion", "desc": "+25 max HP.", "mods": {"max_hp": 25}},
	"cymbal": {"name": "Cymbal", "kind": "family", "family": "percussion", "desc": "On-beat melee hits crash in a small ring.", "flags": {"cymbal_crash": 0.35}},
	"snare": {"name": "Snare Drum", "kind": "family", "family": "percussion", "desc": "Parry window +60% and take 6% less damage.", "mods": {"dr": 0.06}, "flags": {"parry_window": 0.6}},
	"piccolo": {"name": "Piccolo", "kind": "family", "family": "wind", "desc": "+1 jump.", "mods": {"jumps": 1}},
	"reed": {"name": "Oboe", "kind": "family", "family": "wind", "desc": "Dash cooldown 35% shorter.", "mods": {"dash_cdr": 0.35}},
	"horn": {"name": "Trumpet", "kind": "family", "family": "wind", "desc": "+15% move speed.", "mods": {"speed": 0.15}},
	"flute_rune": {"name": "Flute", "kind": "family", "family": "wind", "desc": "Wind powers deal +20% and your dash cuts for 6.", "mods": {"power_dmg": 0.1}, "flags": {"piper_dash": 6}},
	"bow": {"name": "Violin", "kind": "family", "family": "string", "desc": "Projectiles deal +30%.", "mods": {"proj_dmg": 0.3}},
	"pizzicato": {"name": "Guitar", "kind": "family", "family": "string", "desc": "Melee hits have a 25% chance to fire a small soundwave.", "flags": {"pizzicato": 0.25}},
	"harmonic": {"name": "Harp", "kind": "family", "family": "string", "desc": "Shields absorb 50% more and power cooldowns are 8% shorter.", "mods": {"cdr": 0.08}, "flags": {"shield_bonus": 0.5}},

	"timpani_rune": {"name": "Timpani", "kind": "family", "family": "percussion", "desc": "Shockwaves and rings you make are 30% larger and deal +15%.", "flags": {"big_waves": 0.3}, "mods": {"power_dmg": 0.05}},
	"piano": {"name": "Piano", "kind": "family", "families": ["percussion", "string"], "family": "percussion", "desc": "Counts toward BOTH the Percussion and String sets, and never causes dissonance.", "mods": {"dmg": 0.05}},
	"theremin": {"name": "Theremin", "kind": "swap", "rare": true, "desc": "Every beat, enemies within reach of you take 7 damage.", "flags": {"theremin": 7}},
	"hurdy_gurdy": {"name": "Hurdy-Gurdy", "kind": "swap", "rare": true, "desc": "Every other beat, a soundwave cranks out behind you.", "flags": {"drone_wave": 10}},

	"whole_rest_rune": {"name": "Whole Rest", "kind": "pause", "desc": "Parry window +80%. A successful parry heals 4.", "flags": {"parry_window": 0.8, "parry_heal": 4}},
	"half_rest_rune": {"name": "Half Rest", "kind": "pause", "desc": "Dash cooldown 30% shorter.", "mods": {"dash_cdr": 0.3}},
	"quarter_rest_rune": {"name": "Quarter Rest", "kind": "pause", "desc": "Beat window +35 ms.", "mods": {"beat_window": 0.035}},
	"eighth_rest_rune": {"name": "Eighth Rest", "kind": "pause", "desc": "After being hit you stay untouchable 60% longer.", "flags": {"iframe_bonus": 0.6}},
	"fermata_rune": {"name": "Fermata", "kind": "pause", "desc": "Each on-beat strike shaves 0.2 s off every power cooldown.", "flags": {"beat_cdr": 0.2}},

	"key_signature": {"name": "Key Signature", "kind": "permanent", "desc": "+20 max HP and +10% damage.", "mods": {"max_hp": 20, "dmg": 0.1}},
	"common_time": {"name": "4/4", "kind": "permanent", "desc": "On-beat hits deal an extra +35%.", "mods": {"beat_bonus": 0.35}},
	"coda": {"name": "Coda", "kind": "permanent", "desc": "Once per run, a killing blow leaves you at 1 HP instead.", "flags": {"coda": 1}},
	"double_bar": {"name": "Double Bar", "kind": "permanent", "desc": "Opens a third power slot.", "flags": {"third_slot": 1}},
	"repeat_sign": {"name": "Repeat Sign", "kind": "permanent", "desc": "Heal 10 HP whenever you clear a room.", "flags": {"clear_heal": 10}},
	"segno": {"name": "Segno", "kind": "permanent", "desc": "+1 rune slot.", "flags": {"rune_slot": 1}},
	"diminution": {"name": "Diminution", "kind": "permanent", "desc": "You shrink, move 18% faster, and deal up to +50% to anything bigger than you.", "mods": {"speed": 0.18}, "flags": {"diminution": 0.5}},
	"augmentation": {"name": "Augmentation", "kind": "permanent", "desc": "You grow, gain 40 max HP and +15% damage, and move 10% slower.", "mods": {"max_hp": 40, "dmg": 0.15, "speed": -0.1}, "flags": {"augmentation": 1}},
	"dotted": {"name": "Dotted Rhythm", "kind": "permanent", "desc": "+25 max HP, and shields, fades, echoes and updrafts last 50% longer.", "mods": {"max_hp": 25}, "flags": {"dotted": 0.5}},

	"tritone": {"name": "Tritone", "kind": "margin", "desc": "+60% damage dealt, +40% damage taken.", "mods": {"dmg": 0.6, "dmg_taken": 0.4}},
	"glass_harmonica": {"name": "Glass Harmonica", "kind": "margin", "desc": "Deal double damage. Every hit you take costs at least a quarter of your max HP.", "mods": {"dmg": 1.0}, "flags": {"glass": 0.25}},
	"out_of_tune": {"name": "Out of Tune", "kind": "margin", "desc": "Every hit deals anywhere from 0.2x to 3x. Good luck.", "flags": {"out_of_tune": 1}},
	"four_thirty_three": {"name": "4'33\"", "kind": "margin", "desc": "Standing perfectly still makes you untargetable and slowly heals you. The music stops while you do it.", "flags": {"four_thirty_three": 1}},
	"syncopation": {"name": "Syncopation", "kind": "margin", "desc": "The beat is now between the beats. Hits there deal an extra +50%.", "mods": {"beat_bonus": 0.5}, "flags": {"syncopation": 1}},
	"kazoo": {"name": "Kazoo", "kind": "margin", "desc": "All melody is now kazoo. 6% chance to instantly kill a non-boss enemy on hit.", "flags": {"kazoo": 0.06}},
}

const FAMILY_SETS := {
	"percussion": {
		2: {"desc": "+25% damage to stunned or airborne enemies.", "flags": {"stunned_bonus": 0.25}},
		3: {"desc": "Landing from a height sends out a shockwave.", "flags": {"land_shock": 1}},
	},
	"wind": {
		2: {"desc": "Dashing leaves a cutting slipstream behind you.", "flags": {"dash_trail": 1}},
		3: {"desc": "Damage scales with speed: +1% per 5 speed above 250.", "flags": {"horn_scaling": 1}},
	},
	"string": {
		2: {"desc": "Projectiles pierce one more enemy and deal +15%.", "mods": {"pierce": 1, "proj_dmg": 0.15}},
		3: {"desc": "Every bar, a soundwave fires itself at the nearest enemy.", "flags": {"auto_wave": 1}},
	},
}

## Mixing rival pillars' family runes. Each pair is slightly out of tune (a smaller beat
## window) but something new happens.
const DISSONANCE := {
	"thunderclap": {"name": "Thunderclap", "pair": ["percussion", "wind"], "desc": "Every dash ends in a pair of small shockwaves.", "mods": {"beat_window": -0.01}, "flags": {"thunderclap": 1}},
	"aeolian": {"name": "Aeolian Harp", "pair": ["wind", "string"], "desc": "Soundwaves fly 40% faster and shove what they hit.", "mods": {"beat_window": -0.01}, "flags": {"aeolian": 1}},
	"prepared_piano": {"name": "Prepared Piano", "pair": ["string", "percussion"], "desc": "Every shockwave you make also fires a soundwave along it.", "mods": {"beat_window": -0.01}, "flags": {"prepared_piano": 1}},
	"cacophony": {"name": "Cacophony", "pair": ["percussion", "wind", "string"], "desc": "All three at once: +20% damage, but the beat window shrinks by another 20 ms.", "mods": {"dmg": 0.2, "beat_window": -0.02}},
}
