class_name PagesData
## Pages (areas), their songs, the climb order and the clefs.
## Split from the original content.gd without changing any values.

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
