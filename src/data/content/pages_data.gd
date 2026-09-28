class_name PagesData
## Pages (areas), their songs, the climb order and the clefs.
## Split from the original content.gd without changing any values.

const PAGES := {
	ContentIds.PageIds.LEDGER: {
		"name": "The Margin", "subtitle": "outside the staff, where erased notes end up", "family": "ledger",
		"song": {"seed": "ledger", "bpm": 92.0, "root": 60, "scale": [0, 2, 4, 5, 7, 9, 11], "prog": [0, 4, 5, 3],
			"lead": "keys", "density": 0.32, "bass": "x.......x.......", "lead_db": -7.0,
			"drums": {"kick": "x.......x.......", "hat": "....x.......x..."}},
	},
	ContentIds.PageIds.PERCUSSION: {
		"name": "Bar I: Percussion", "subtitle": "the Strikers, deep in the caverns", "family": "percussion", "numeral": "I",
		"enemies": [ContentIds.EnemyIds.QUARTER_REST, ContentIds.EnemyIds.SNARE_REST, ContentIds.EnemyIds.WHOLE_REST, ContentIds.EnemyIds.HALF_REST, ContentIds.EnemyIds.RIM_GUARD, ContentIds.EnemyIds.BANDLEADER],
		"elites": [ContentIds.EnemyIds.TIMPANIST, ContentIds.EnemyIds.CYMBALIST], "boss": "timpani", "teacher": "old_snare",
		"song": {"seed": "percussion", "bpm": 108.0, "root": 57, "scale": [0, 2, 3, 5, 7, 8, 10], "prog": [0, 5, 3, 6],
			"lead": "marimba", "density": 0.5, "bass": "x..x..x.x..x..x.", "drum_db": -3.0,
			"drums": {"kick": "x..x..x.x..x..x.", "snare": "....x.......x...", "hat": "x-x-x-x-x-x-x-x-", "tom": "..............xx"}},
	},
	ContentIds.PageIds.WIND: {
		"name": "Bar II: Wind", "subtitle": "the Breathers, up in the open sky", "family": "wind", "numeral": "II",
		"enemies": [ContentIds.EnemyIds.EIGHTH_REST, ContentIds.EnemyIds.SIXTEENTH_REST, ContentIds.EnemyIds.GUST_REST, ContentIds.EnemyIds.DASHER, ContentIds.EnemyIds.PHANTOM, ContentIds.EnemyIds.BREATH_WELL],
		"elites": [ContentIds.EnemyIds.PIPER, ContentIds.EnemyIds.HORNIST], "boss": "flute", "teacher": "zephyrine",
		"song": {"seed": "wind", "bpm": 124.0, "root": 62, "scale": [0, 2, 3, 5, 7, 9, 10], "prog": [0, 3, 6, 4],
			"lead": "flute", "density": 0.42, "bass": "x.....x.x.......", "arp": true, "arp_inst": "pluck",
			"drums": {"kick": "x.......x.......", "hat": "..x...x...x...x.", "clap": "....x.......x..."}},
	},
	ContentIds.PageIds.STRING: {
		"name": "Bar III: Strings", "subtitle": "the Resonants, in the humming forest", "family": "string", "numeral": "III",
		"enemies": [ContentIds.EnemyIds.TETHER_REST, ContentIds.EnemyIds.ECHO_REST, ContentIds.EnemyIds.MOTIF_REST, ContentIds.EnemyIds.BINDER_REST, ContentIds.EnemyIds.WARDEN_REST, ContentIds.EnemyIds.SIXTEENTH_REST],
		"elites": [ContentIds.EnemyIds.VIOLIST, ContentIds.EnemyIds.CELLIST], "boss": "harp", "teacher": "luthier",
		"song": {"seed": "strings", "bpm": 96.0, "root": 55, "scale": [0, 2, 3, 5, 7, 8, 11], "prog": [0, 5, 3, 4],
			"lead": "pluck", "density": 0.55, "bass": "x...x...x...x...", "pad": true, "lead_db": -5.0,
			"drums": {"kick": "x.......x.......", "hat": "....-.......-..."}},
	},
	ContentIds.PageIds.PODIUM: {
		"name": "The Grand Score", "subtitle": "the top of the world", "family": "podium", "numeral": "IV",
		"boss": "conductor",
		"song": {"seed": "podium", "bpm": 116.0, "root": 53, "scale": [0, 2, 3, 5, 7, 8, 10], "prog": [0, 5, 6, 4],
			"lead": "organ", "density": 0.5, "bass": "x..x....x..x....", "pad": true, "arp": true, "arp_inst": "marimba",
			"drums": {"kick": "x...x...x...x...", "snare": "....x.......x...", "hat": "x-x-x-x-x-x-x-x-", "crash": "x..............."}},
	},
	ContentIds.PageIds.GRAND: {
		"name": "The Score, Itself", "subtitle": "the page under all the pages", "family": "grand", "numeral": "∞",
		"boss": "grand_staff",
		"song": {"seed": "grand", "bpm": 132.0, "root": 60, "scale": [0, 1, 3, 5, 7, 8, 10], "prog": [0, 1, 0, 6],
			"lead": "organ", "density": 0.6, "bass": "x.x.x.x.x.x.x.x.", "pad": true, "arp": true, "arp_inst": "flute",
			"drums": {"kick": "x..x..x.x..x..x.", "snare": "....x.......x...", "hat": "xxxxxxxxxxxxxxxx", "tom": "............xxxx"}},
	},
}

const CLIMB := [ContentIds.PageIds.PERCUSSION, ContentIds.PageIds.WIND, ContentIds.PageIds.STRING, ContentIds.PageIds.PODIUM]

# The Scribble hides one clef on each pillar page.
const CLEFS := {ContentIds.PageIds.PERCUSSION: "Bass Clef", ContentIds.PageIds.WIND: "Treble Clef", ContentIds.PageIds.STRING: "Alto Clef"}
