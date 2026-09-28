class_name StoryData
## Teachers, the Margin intro, the prologue and the endings.
## Split from the original content.gd without changing any values.

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
