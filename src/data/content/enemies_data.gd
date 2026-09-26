class_name EnemiesData
## Enemies (the Rests), elites and bosses.
## Split from the original content.gd without changing any values.

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
	"timpani": {"name": "The Hollow Timpani", "title": "keeper of Percussion", "hp": 1000, "script": "res://src/actors/enemies/bosses/timpani.gd", "family": "percussion"},
	"flute": {"name": "The Breathless Flute", "title": "keeper of Wind", "hp": 950, "script": "res://src/actors/enemies/bosses/flute.gd", "family": "wind"},
	"harp": {"name": "The Unstrung Harp", "title": "keeper of Strings", "hp": 1100, "script": "res://src/actors/enemies/bosses/harp.gd", "family": "string"},
	"conductor": {"name": "The Conductor", "title": "who never noticed the notes were alive", "hp": 2100, "script": "res://src/actors/enemies/bosses/conductor.gd", "family": "podium"},
	"grand_staff": {"name": "The Score", "title": "the sheet itself, awake", "hp": 3000, "script": "res://src/actors/enemies/bosses/grand_staff.gd", "family": "grand"},
}
