class_name BeatGrader
## Grades how close a press landed to the beat, and what that grade is worth
## (issue #12). No state: the player keeps its own mash stacks.

enum Grade { NONE, MISS, GOOD, GREAT, PERFECT }

const TUNING: TimingTuning = preload("res://content/tuning/timing_tuning.tres")
const LABELS := {Grade.PERFECT: "perfect!", Grade.GREAT: "great", Grade.GOOD: "good", Grade.MISS: ""}


## `offset` is signed seconds from the nearest beat; `beat_window` is the player's.
static func grade(offset: float, beat_window: float) -> Grade:
	var d := absf(offset)
	if d <= TUNING.perfect_window:
		return Grade.PERFECT
	if d <= beat_window:
		return Grade.GREAT
	if d <= beat_window * TUNING.good_window_scale:
		return Grade.GOOD
	return Grade.MISS


## "On the beat" for runes and relics means great or better.
static func is_on_beat(g: Grade) -> bool:
	return g >= Grade.GREAT


static func damage_multiplier(g: Grade, beat_bonus: float, mash_stacks: int) -> float:
	match g:
		Grade.PERFECT:
			return TUNING.perfect_multiplier + beat_bonus
		Grade.GREAT:
			return TUNING.great_multiplier + beat_bonus
		Grade.GOOD:
			return TUNING.good_multiplier
		Grade.MISS:
			return TUNING.miss_multiplier * (1.0 - TUNING.mash_penalty_step * mini(mash_stacks, TUNING.mash_penalty_max_stacks))
	return 1.0


static func label(g: Grade) -> String:
	return LABELS.get(g, "")


static func color(g: Grade) -> Color:
	match g:
		Grade.PERFECT: return Pal.GOLD
		Grade.GREAT: return Pal.GOLD.lerp(Pal.INK, 0.25)
		Grade.GOOD: return Pal.INK_SOFT
	return Pal.INK_FAINT
