#!/usr/bin/env bash
# tools/test_sweep.sh
# Checks the sweep harness (tools/sweep.gd) stays deterministic. Exit 0 = all pass.
#   1. each item policy (first_card, random) gives identical rows when run twice
#   2. paired seeds: a forced-item variant replays the control's seed and character
#   3. a sweep killed after its first row and resumed matches an uninterrupted one (this
#      also shows a row doesn't depend on what ran before it: see --max-runs in sweep.gd)
# Rows are compared without wall_seconds (real time). Every process gets its own HOME and
# XDG_DATA_HOME so the test saves never collide. Takes a few minutes (full climbs).
set -euo pipefail
cd "$(dirname "$0")/.."

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
godot --headless --path . --import > "$WORK/import.log" 2>&1

cfg() {  # cfg NAME POLICY
	cat > "$WORK/$1.json" <<EOF
{"id": "$1", "runs": 2, "characters": ["quarter", "eighth"], "base_seed": 600000, "clefs": false,
 "item_policy": "$2", "paired_seeds": true,
 "variants": [{"label": "control", "runs": 1}, {"label": "rosin", "runs": 1, "force_items": ["rosin"]}]}
EOF
}

sweep() {  # sweep CONFIG OUT: one run per process, until done (as tools/run_sweep.sh does)
	local home="$WORK/home_$(basename "$2")" rc
	mkdir -p "$home"
	while :; do
		rc=0
		HOME="$home" XDG_DATA_HOME="$home/.local/share" godot --headless --fixed-fps 60 --path . \
			--script tools/sweep.gd -- "$1" "$2" --max-runs 1 >> "$2.log" 2>&1 || rc=$?
		[ "$rc" = 75 ] || return "$rc"
	done
}

strip() { sed 's/"wall_seconds":[-0-9.e+]*,\{0,1\}//' "$1"; }

fail=0
check() {
	if [ "$1" = ok ]; then echo "ok: $2"; else echo "FAIL: $2"; fail=1; fi
}

for policy in first_card random; do
	cfg "$policy" "$policy"
	sweep "$WORK/$policy.json" "$WORK/$policy.a.jsonl"
	sweep "$WORK/$policy.json" "$WORK/$policy.b.jsonl"
	rows=$(grep -c . "$WORK/$policy.a.jsonl" || true)
	if [ "$rows" = 2 ] && diff -q <(strip "$WORK/$policy.a.jsonl") <(strip "$WORK/$policy.b.jsonl") > /dev/null; then
		check ok "$policy policy: two runs of the sweep give identical rows"
	else
		check fail "$policy policy: rows differ between two runs ($rows rows)"
	fi
done

seeds=$(grep -o '"run_seed":[0-9]*' "$WORK/first_card.a.jsonl" | sort -u | wc -l)
chars=$(grep -o '"character":"[a-z]*"' "$WORK/first_card.a.jsonl" | sort -u | wc -l)
if [ "$seeds" = 1 ] && [ "$chars" = 1 ] && grep -q '"forced_items":\["rosin"\]' "$WORK/first_card.a.jsonl"; then
	check ok "paired seeds: the rosin variant replays the control's seed and character"
else
	check fail "paired seeds: $seeds seed(s), $chars character(s) across the pair"
fi

# Kill after the first row lands, then resume.
out="$WORK/resume.jsonl"
home="$WORK/home_resume"
mkdir -p "$home"
HOME="$home" XDG_DATA_HOME="$home/.local/share" godot --headless --fixed-fps 60 --path . \
	--script tools/sweep.gd -- "$WORK/first_card.json" "$out" --max-runs 0 > "$out.log" 2>&1 &
pid=$!
until [ -s "$out" ] && [ "$(grep -c . "$out")" -ge 1 ]; do
	kill -0 "$pid" 2>/dev/null || break
	sleep 1
done
kill "$pid" 2>/dev/null || true
wait "$pid" 2>/dev/null || true
if [ -s "$out" ] && [ -n "$(tail -c1 "$out")" ]; then sed -i '$d' "$out"; fi
sweep "$WORK/first_card.json" "$out"
if diff -q <(strip "$out" | sort) <(strip "$WORK/first_card.a.jsonl" | sort) > /dev/null; then
	check ok "a sweep killed after its first row and resumed matches an uninterrupted one"
else
	check fail "the resumed sweep differs from an uninterrupted one"
fi
exit $fail
