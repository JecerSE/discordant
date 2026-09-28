#!/usr/bin/env bash
# tools/compare_rng_streams.sh
# Drives tools/test_rng_streams.gd through four full playthroughs (one process each, so no
# state leaks between them) and diffs the fingerprints. Exit 0 = all three checks pass.
set -euo pipefail
cd "$(dirname "$0")/.."

OUT=$(mktemp -d)
trap 'rm -rf "$OUT"' EXIT

run() { godot --headless --fixed-fps 60 --path . --script tools/test_rng_streams.gd -- "$1" "$OUT/$2" > "$OUT/$2.log" 2>&1; }

run plain a.json
run plain b.json
run cosmetic c.json
run reload d.json

fail=0
compare() {
	if diff -q "$OUT/$1" "$OUT/$2" > /dev/null; then
		echo "ok: $3"
	else
		echo "FAILED: $3"
		diff "$OUT/$1" "$OUT/$2" || true
		fail=1
	fi
}

compare a.json b.json "same seed reproduces identical damage, spawns and item offers"
compare a.json c.json "perturbing only the cosmetic stream changes no simulation state"
compare a.json d.json "a save/load round trip mid-run changes nothing after it"
exit $fail
