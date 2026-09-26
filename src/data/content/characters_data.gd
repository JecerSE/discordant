class_name CharactersData
## The four playable notes.
## Split from the original content.gd without changing any values.

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
