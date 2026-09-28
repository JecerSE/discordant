# tools/sweep_plan.gd
extends RefCounted
## Config validation and the per-run plan for tools/sweep.gd. Pure functions of the config
## and the run index, so any row can be re-run alone. No autoloads, no game RNG.
##
## Config keys:
##   id, runs, characters, base_seed, clefs   as before
##   item_policy    "first_card" (take the first card, the old behaviour) or "random" (a bot
##                  RNG seeded from the run seed; never a game stream)
##   variants       [{"label": str, "runs": int, "force_items": [id, ...]}, ...]; their runs
##                  must add up to the config's runs
##   force_items    items granted at run start in every run (variants can add their own)
##   paired_seeds   with variants: each variant's k-th run uses the same seed and character
##                  as every other variant's k-th run, so a forced item is compared against
##                  the control on identical runs
##   note           free text, ignored

const ALLOWED := ["id", "runs", "characters", "base_seed", "clefs", "item_policy", "variants",
	"force_items", "paired_seeds", "note"]
const POLICIES := ["first_card", "random"]
const VARIANT_KEYS := ["label", "runs", "force_items"]


## Returns "" if the config can run, otherwise why not.
static func validate(cfg: Dictionary) -> String:
	for k in cfg:
		if not k in ALLOWED:
			return "unknown config key '%s'%s" % [k, " (rename planned_runs to runs once the sweep supports the config)" if k == "planned_runs" else ""]
	if int(cfg.get("runs", 0)) <= 0:
		return "runs must be a positive number"
	if not cfg.get("item_policy", "first_card") in POLICIES:
		return "item_policy must be one of %s" % str(POLICIES)
	var items: Dictionary = load("res://src/data/content/relics_data.gd").RELICS
	for id in cfg.get("force_items", []):
		if not items.has(id):
			return "force_items: '%s' is not a relic or champion item" % id
	var variants: Array = cfg.get("variants", [])
	if cfg.get("paired_seeds", false) and variants.is_empty():
		return "paired_seeds needs variants"
	if not variants.is_empty():
		var total := 0
		for v in variants:
			for k in v:
				if not k in VARIANT_KEYS:
					return "unknown variant key '%s'" % k
			if not v.has("label") or int(v.get("runs", 0)) <= 0:
				return "every variant needs a label and positive runs"
			for id in v.get("force_items", []):
				if not items.has(id):
					return "variant %s: '%s' is not a relic or champion item" % [v.label, id]
			total += int(v.runs)
		if total != int(cfg.runs):
			return "variants add up to %d runs but runs is %d" % [total, int(cfg.runs)]
	return ""


## What run `run_index` plays: character, seed, variant label, items to force.
static func plan(cfg: Dictionary, run_index: int) -> Dictionary:
	var chars: Array = cfg.get("characters", ["quarter"])
	var base := int(cfg.get("base_seed", 0))
	var label := ""
	var local := run_index
	var forced: Array = (cfg.get("force_items", []) as Array).duplicate()
	var start := 0
	for v in cfg.get("variants", []):
		if run_index < start + int(v.runs):
			label = v.label
			local = run_index - start
			forced.append_array(v.get("force_items", []))
			break
		start += int(v.runs)
	# Paired: the k-th run of every variant replays the same seed and character.
	var k := local if cfg.get("paired_seeds", false) else run_index
	return {"character": chars[k % chars.size()], "seed": base + k, "variant": label, "force_items": forced}
