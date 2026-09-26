class_name IntroData
## The prologue cutscene, shot by shot. Each shot has a length (s), a caption typed into
## the bottom letterbox, the scenery behind it ("" for none), the song and how muffled
## it is, and cues: sounds, shakes and flashes at set times (s into the shot).
## How each kind is drawn: IntroShots.

const SHOTS := [
	{"kind": "score", "time": 5.0, "area": "grand", "song": "podium", "hush": [0.0, 0.0],
		"caption": "There is a Score. Every song there is, written on one great page.",
		"cues": []},
	{"kind": "conductor", "time": 5.4, "area": "grand", "song": "podium", "hush": [0.0, 0.0],
		"caption": "The Conductor writes all of it. The Conductor has never noticed that the notes are alive.",
		"cues": [{"t": 1.0, "sfx": "ping"}, {"t": 1.6, "sfx": "ping"}, {"t": 2.2, "sfx": "ping"}, {"t": 2.8, "sfx": "ping"}]},
	{"kind": "quarter", "time": 4.4, "area": "grand", "song": "podium", "hush": [0.0, 0.0],
		"caption": "You were a quarter note. One beat. You liked it there.",
		"cues": []},
	{"kind": "struck", "time": 2.8, "area": "grand", "song": "podium", "hush": [0.0, 0.9],
		"caption": "Then you were struck out.",
		"cues": [{"t": 0.9, "sfx": "zap"}, {"t": 1.05, "sfx": "crash", "shake": 1.0, "flash": true}]},
	{"kind": "fall", "time": 2.8, "area": "", "song": "podium", "hush": [0.9, 1.0],
		"caption": "Off the staff, and down,",
		"cues": [{"t": 0.05, "sfx": "whoosh"}, {"t": 1.4, "sfx": "whoosh"}]},
	{"kind": "margin", "time": 3.8, "area": "ledger", "song": "ledger", "hush": [0.6, 0.3],
		"caption": "into the Margin, where erased notes end up.",
		"cues": [{"t": 0.55, "sfx": "tom", "shake": 0.6}]},
	{"kind": "rest", "time": 5.2, "area": "ledger", "song": "ledger", "hush": [0.3, 1.0],
		"caption": "Up above, the music is going quiet. The Rest is spreading through the pages.",
		"cues": [{"t": 0.8, "sfx": "boom"}, {"t": 2.2, "sfx": "boom"}]},
	{"kind": "title", "time": 3.6, "area": "grand", "song": "ledger", "hush": [1.0, 0.0],
		"caption": "The only way back is up.",
		"cues": []},
]

## When the logo slams down in the last shot (s), before snapping to the next beat.
const SLAM_AT := 1.3
