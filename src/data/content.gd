class_name Content
## Every piece of game data in one place. Logic lives elsewhere and looks things up by id.
##
## Stat mods are additive: {"dmg": 0.12} is +12% damage, {"max_hp": 20} is +20 HP.
## Flags are named hooks the player and room code check for, each with a number.

const TITLE := "The Discordant"

# --- the notes you can be ---------------------------------------------------------------------

const CHARACTERS := {
	"quarter": {
		"name": "Quarter Note", "role": "all-rounder", "glyph": "♩",
		"hp": 100, "speed": 270.0, "jumps": 2, "dmg": 1.0, "dr": 0.0,
		"power": "soundwave",
		"innate": "Common Time: your beat window is 30% wider.",
		"desc": "One beat. The main character. A little better than average at everything.",
		"unlock": "",
	},
	"whole": {
		"name": "Mundo", "role": "Whole Note · tank", "glyph": "𝅝",
		"hp": 170, "speed": 215.0, "jumps": 1, "dmg": 1.1, "dr": 0.2,
		"power": "shockwave",
		"innate": "Held: 20% less damage, no knockback, air attacks pound the ground. Percussion runes add +8% damage each.",
		"desc": "Four beats long and very hard to knock over. Doesn't have a stem because it doesn't need one.",
		"unlock": "Defeat the keeper of Percussion.",
	},
	"half": {
		"name": "Half Note", "role": "balanced", "glyph": "𝅗𝅥",
		"hp": 120, "speed": 250.0, "jumps": 2, "dmg": 1.0, "dr": 0.05,
		"power": "reverb_shield",
		"innate": "Sustain: every melee hit rings again half a beat later for 45%.",
		"desc": "Average stats all around. Good for trying out all three pillars.",
		"unlock": "Defeat the keeper of Strings.",
	},
	"eighth": {
		"name": "Eighth Note", "role": "glass cannon", "glyph": "♪",
		"hp": 65, "speed": 330.0, "jumps": 3, "dmg": 1.2, "dr": 0.0,
		"power": "gale_dash",
		"innate": "Flag: three jumps, a dash that cuts, and damage that scales with speed.",
		"desc": "Half a beat long and always in a hurry. Hits hard, dies fast.",
		"unlock": "Defeat the keeper of Wind.",
	},
}

const CHARACTER_ORDER := ["quarter", "half", "whole", "eighth"]

# --- active powers --------------------------------------------------------------------------------

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

# --- runes -----------------------------------------------------------------------------------------
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

# --- relics ----------------------------------------------------------------------------------------

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

# --- enemies: the Rests, soldiers of the Tacet ---------------------------------------------------

const ENEMIES := {
	"quarter_rest": {"name": "Quarter Rest", "hp": 30, "dmg": 10, "speed": 115.0, "ai": "walker", "r": 18.0, "sharps": 2, "weight": 0.0},
	"whole_rest": {"name": "Whole Rest", "hp": 46, "dmg": 16, "speed": 60.0, "ai": "dropper", "r": 22.0, "sharps": 3, "weight": 0.6},
	"snare_rest": {"name": "Snare Rest", "hp": 34, "dmg": 12, "speed": 170.0, "ai": "jumper", "r": 18.0, "sharps": 3, "weight": 0.2},
	"half_rest": {"name": "Half Rest", "hp": 52, "dmg": 14, "speed": 420.0, "ai": "charger", "r": 22.0, "sharps": 3, "weight": 0.5},
	"eighth_rest": {"name": "Eighth Rest", "hp": 24, "dmg": 10, "speed": 150.0, "ai": "flyer", "r": 16.0, "sharps": 2, "weight": 0.0},
	"sixteenth_rest": {"name": "Sixteenth Rest", "hp": 22, "dmg": 9, "speed": 110.0, "ai": "shooter", "r": 16.0, "sharps": 3, "weight": 0.0},
	"gust_rest": {"name": "Gust Rest", "hp": 38, "dmg": 8, "speed": 90.0, "ai": "gust", "r": 20.0, "sharps": 3, "weight": 0.3},
	"tether_rest": {"name": "Tether Rest", "hp": 42, "dmg": 4, "speed": 85.0, "ai": "tether", "r": 18.0, "sharps": 3, "weight": 0.3},
	"echo_rest": {"name": "Echo Rest", "hp": 32, "dmg": 11, "speed": 70.0, "ai": "echo", "r": 18.0, "sharps": 3, "weight": 0.1},

	"rim_guard": {"name": "Rimshot Guard", "hp": 48, "dmg": 12, "speed": 80.0, "ai": "guard", "r": 20.0, "sharps": 4, "weight": 0.7,
		"tip": "Its stance turns aside anything off the beat. Strike it ON the beat to shatter it."},
	"bandleader": {"name": "Bandleader Rest", "hp": 40, "dmg": 8, "speed": 90.0, "ai": "buffer", "r": 18.0, "sharps": 4, "weight": 0.2, "buffs": true,
		"tip": "Rallies the rests around it: faster, harder. Kill it first."},
	"dasher": {"name": "Staccato Rest", "hp": 28, "dmg": 13, "speed": 120.0, "ai": "dasher", "r": 16.0, "sharps": 3, "weight": 0.0,
		"tip": "Winds up, then bursts across the page. Interrupt it or get out of the line."},
	"phantom": {"name": "Breathless Rest", "hp": 30, "dmg": 10, "speed": 110.0, "ai": "phantom", "r": 16.0, "sharps": 4, "weight": 0.0,
		"tip": "Fades out of sight. Only area attacks can hit it, or stun it to make it show up."},
	"breath_well": {"name": "Breath Reed", "hp": 70, "dmg": 0, "speed": 0.0, "ai": "well", "r": 22.0, "sharps": 5, "weight": 1.0,
		"tip": "Breathes for every wind rest on the page. Break it and they all choke."},
	"motif_rest": {"name": "Motif Rest", "hp": 30, "dmg": 8, "speed": 100.0, "ai": "motif", "r": 16.0, "sharps": 4, "weight": 0.0,
		"tip": "Its waves mark you. Three marks and it goes off on you."},
	"binder_rest": {"name": "Unison Rest", "hp": 44, "dmg": 6, "speed": 80.0, "ai": "binder", "r": 18.0, "sharps": 4, "weight": 0.3,
		"tip": "Binds itself to you. While bound, every hit you land on it lands on you instead. Wait it out."},
	"warden_rest": {"name": "Reverb Warden", "hp": 50, "dmg": 10, "speed": 60.0, "ai": "warden", "r": 20.0, "sharps": 4, "weight": 0.6,
		"tip": "A pulsing barrier throws shots back and staggers whoever strikes it. Hit it between pulses."},

	"timpanist": {"name": "Fallen Timpanist", "hp": 300, "dmg": 18, "speed": 180.0, "ai": "elite_timpanist", "r": 34.0, "sharps": 25, "weight": 0.85, "drop": "timpanist_mallet", "family": "percussion", "elite": true},
	"cymbalist": {"name": "Fallen Cymbalist", "hp": 270, "dmg": 16, "speed": 480.0, "ai": "elite_cymbalist", "r": 32.0, "sharps": 25, "weight": 0.8, "drop": "cymbal_shard", "family": "percussion", "elite": true},
	"piper": {"name": "Fallen Piper", "hp": 240, "dmg": 14, "speed": 190.0, "ai": "elite_piper", "r": 28.0, "sharps": 25, "weight": 0.6, "drop": "piper_reed", "family": "wind", "elite": true},
	"hornist": {"name": "Fallen Hornist", "hp": 280, "dmg": 16, "speed": 140.0, "ai": "elite_hornist", "r": 32.0, "sharps": 25, "weight": 0.8, "drop": "horn_bell", "family": "wind", "elite": true},
	"violist": {"name": "Fallen Violist", "hp": 260, "dmg": 13, "speed": 110.0, "ai": "elite_violist", "r": 30.0, "sharps": 25, "weight": 0.7, "drop": "violist_bow", "family": "string", "elite": true},
	"cellist": {"name": "Fallen Cellist", "hp": 360, "dmg": 18, "speed": 95.0, "ai": "elite_cellist", "r": 36.0, "sharps": 25, "weight": 0.9, "drop": "cello_endpin", "family": "string", "elite": true},

	"dummy": {"name": "Practice Stand", "hp": 999999, "dmg": 0, "speed": 0.0, "ai": "dummy", "r": 22.0, "sharps": 0, "weight": 1.0},
}

const BOSSES := {
	"timpani": {"name": "The Hollow Timpani", "title": "keeper of Percussion", "hp": 1000, "script": "res://src/actors/bosses/timpani.gd", "family": "percussion"},
	"flute": {"name": "The Breathless Flute", "title": "keeper of Wind", "hp": 950, "script": "res://src/actors/bosses/flute.gd", "family": "wind"},
	"harp": {"name": "The Unstrung Harp", "title": "keeper of Strings", "hp": 1100, "script": "res://src/actors/bosses/harp.gd", "family": "string"},
	"conductor": {"name": "The Conductor", "title": "who never noticed the notes were alive", "hp": 2100, "script": "res://src/actors/bosses/conductor.gd", "family": "podium"},
	"grand_staff": {"name": "The Score", "title": "the sheet itself, awake", "hp": 3000, "script": "res://src/actors/bosses/grand_staff.gd", "family": "grand"},
}

# --- pages: the climb --------------------------------------------------------------------------------

const PAGES := {
	"ledger": {
		"name": "The Margin", "subtitle": "outside the staff, where erased notes end up", "family": "ledger",
		"song": {"seed": "ledger", "bpm": 92.0, "root": 60, "scale": [0, 2, 4, 5, 7, 9, 11], "prog": [0, 4, 5, 3],
			"lead": "keys", "density": 0.32, "bass": "x.......x.......", "lead_db": -7.0,
			"drums": {"kick": "x.......x.......", "hat": "....x.......x..."}},
	},
	"percussion": {
		"name": "Page I: Percussion", "subtitle": "the Strikers, deep in the caverns", "family": "percussion", "numeral": "I",
		"enemies": ["quarter_rest", "snare_rest", "whole_rest", "half_rest", "rim_guard", "bandleader"],
		"elites": ["timpanist", "cymbalist"], "boss": "timpani", "teacher": "old_snare",
		"song": {"seed": "percussion", "bpm": 108.0, "root": 57, "scale": [0, 2, 3, 5, 7, 8, 10], "prog": [0, 5, 3, 6],
			"lead": "marimba", "density": 0.5, "bass": "x..x..x.x..x..x.", "drum_db": -3.0,
			"drums": {"kick": "x..x..x.x..x..x.", "snare": "....x.......x...", "hat": "x-x-x-x-x-x-x-x-", "tom": "..............xx"}},
	},
	"wind": {
		"name": "Page II: Wind", "subtitle": "the Breathers, up in the open sky", "family": "wind", "numeral": "II",
		"enemies": ["eighth_rest", "sixteenth_rest", "gust_rest", "dasher", "phantom", "breath_well"],
		"elites": ["piper", "hornist"], "boss": "flute", "teacher": "zephyrine",
		"song": {"seed": "wind", "bpm": 124.0, "root": 62, "scale": [0, 2, 3, 5, 7, 9, 10], "prog": [0, 3, 6, 4],
			"lead": "flute", "density": 0.42, "bass": "x.....x.x.......", "arp": true, "arp_inst": "pluck",
			"drums": {"kick": "x.......x.......", "hat": "..x...x...x...x.", "clap": "....x.......x..."}},
	},
	"string": {
		"name": "Page III: Strings", "subtitle": "the Resonants, in the humming forest", "family": "string", "numeral": "III",
		"enemies": ["tether_rest", "echo_rest", "motif_rest", "binder_rest", "warden_rest", "sixteenth_rest"],
		"elites": ["violist", "cellist"], "boss": "harp", "teacher": "luthier",
		"song": {"seed": "strings", "bpm": 96.0, "root": 55, "scale": [0, 2, 3, 5, 7, 8, 11], "prog": [0, 5, 3, 4],
			"lead": "pluck", "density": 0.55, "bass": "x...x...x...x...", "pad": true, "lead_db": -5.0,
			"drums": {"kick": "x.......x.......", "hat": "....-.......-..."}},
	},
	"podium": {
		"name": "The Grand Score", "subtitle": "the top of the world", "family": "podium", "numeral": "IV",
		"boss": "conductor",
		"song": {"seed": "podium", "bpm": 116.0, "root": 53, "scale": [0, 2, 3, 5, 7, 8, 10], "prog": [0, 5, 6, 4],
			"lead": "organ", "density": 0.5, "bass": "x..x....x..x....", "pad": true, "arp": true, "arp_inst": "marimba",
			"drums": {"kick": "x...x...x...x...", "snare": "....x.......x...", "hat": "x-x-x-x-x-x-x-x-", "crash": "x..............."}},
	},
	"grand": {
		"name": "The Score, Itself", "subtitle": "the page under all the pages", "family": "grand", "numeral": "∞",
		"boss": "grand_staff",
		"song": {"seed": "grand", "bpm": 132.0, "root": 60, "scale": [0, 1, 3, 5, 7, 8, 10], "prog": [0, 1, 0, 6],
			"lead": "organ", "density": 0.6, "bass": "x.x.x.x.x.x.x.x.", "pad": true, "arp": true, "arp_inst": "flute",
			"drums": {"kick": "x..x..x.x..x..x.", "snare": "....x.......x...", "hat": "xxxxxxxxxxxxxxxx", "tom": "............xxxx"}},
	},
}

const CLIMB := ["percussion", "wind", "string", "podium"]

# The Scribble hides one clef on each pillar page.
const CLEFS := {"percussion": "Bass Clef", "wind": "Treble Clef", "string": "Alto Clef"}

const TEACHERS := {
	"old_snare": {"name": "Old Snare", "family": "percussion",
		"lines": ["Hup! A quarter note down in the caverns? You fell a long way.",
			"We Strikers are the oldest pillar. Before melody, before harmony, there was the downbeat.",
			"The Rest got into the drums. Everything sounds muffled now.",
			"I'll teach you something. First, hit my practice stand ON the beat. Four times in a row."],
		"done": "Hah! Now that's a pulse. Pick one.",
		"after": "Keep it on the downbeat, kid."},
	"zephyrine": {"name": "Zephyrine, a retired piccolo", "family": "wind",
		"lines": ["Oh! Careful, dear. The wind up here likes to carry off the little ones.",
			"You haven't been down in the Margin with the rests, have you? Nasty, quiet things.",
			"We Breathers know what silence is. It's where you stop breathing. We don't let it in.",
			"Well, you seem fine. Four hits on the beat, in a row, and I'll show you how to breathe."],
		"done": "Lovely. Now pick one, and don't stop breathing.",
		"after": "Mind the gaps, dear. That's where they wait."},
	"luthier": {"name": "The Luthier", "family": "string",
		"lines": ["Hm. You're out of tune. Everyone is, since the silence spread.",
			"The Winds call the rests a plague. We remember it differently. We used to play together.",
			"A rest in the right place is what makes a chord ring out. Strings and rests made good music once.",
			"Something changed, and I don't think it was them. Four clean hits on the beat, then we'll talk."],
		"done": "There. Now you're in tune. Choose one.",
		"after": "Listen to what's left after the note ends."},
	"scribble": {"name": "The Scribble", "family": "margin",
		"lines": ["psst. down here. in the margin.",
			"nobody reads the margins. so that's where all the good stuff is.",
			"these aren't pillar powers. they're rest powers. they don't follow the rules.",
			"take one. and take this clef too. find all three and the Conductor won't be the last fight."],
		"done": ""},
	"pause": {"name": "Pause, a half rest", "family": "ledger", "lines": [], "done": ""},
	"bflat": {"name": "B♭, a flat who deals in sharps", "family": "ledger", "lines": [], "done": ""},
}

## Pause, a half rest who lives in the Margin, explains why rests are feared.
const MARGIN_INTRO := [
	"Oh. Another one fell. Don't worry, landing's soft down here. It's mostly eraser crumbs.",
	"I'm Pause. A half rest. Yes, a rest. You can stop backing away.",
	"Up on the staff they say rests are the corruption. That every silence is the Rest spreading. So they erased a lot of us.",
	"Something really is eating the music. You'll hear it, everything goes muffled and grey. It looks like us. I don't think it is us.",
	"The Winds hate us the most. The Strings used to play with us. Percussion just wants everyone on the downbeat.",
	"If you're climbing back up, read the margins. Nobody ever does.",
]

const PROLOGUE := [
	"There is a Score.",
	"The Grand Score holds every song there is. Every note lives on it, sheet after sheet.",
	"Every note has a bar, a beat, and a purpose.",
	"The Conductor writes it all. The Conductor has never noticed that the notes are alive.",
	"You were a quarter note. One beat.",
	"Then you were struck out and thrown off the staff, down into the Margin, where erased notes end up.",
	"Up above, the music is going quiet. The Rest is spreading through the pages.",
	"The only way back is up.",
]

const ENDINGS := {
	"fell": [
		"The note goes silent and drifts back down to the Margin.",
		"Notes don't really get erased. They get rewritten. Try again.",
	],
	"prima": [
		"The baton comes down. For the first time, the Conductor looks at you.",
		"Colour comes back to the pages. The Rest pulls back into the margins.",
		"You take your place on the staff again.",
		"The margins are still whispering, though. There might be more to find.",
	],
	"coda": [
		"The Score goes still.",
		"Under it there was no silence. Just empty space for notes nobody had written yet.",
		"The rests were never the problem. They were the room the music needed to change.",
		"You aren't just one beat anymore. You get to write the next bar.",
	],
}


static func character(id: String) -> Dictionary:
	return CHARACTERS.get(id, CHARACTERS["quarter"])


static func item(id: String) -> Dictionary:
	if RELICS.has(id):
		return RELICS[id]
	if RUNES.has(id):
		return RUNES[id]
	if POWERS.has(id):
		return POWERS[id]
	return {"name": id, "desc": ""}


static func item_family(id: String) -> String:
	var d := item(id)
	if d.has("family"):
		return d.family
	if RUNES.has(id):
		return "margin" if RUNES[id].kind == "margin" else "ledger"
	return "ledger"
