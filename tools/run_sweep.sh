#!/usr/bin/env bash
# tools/run_sweep.sh CONFIG.json [SHARDS] [OUT_DIR]
# Runs tools/sweep.gd as SHARDS parallel processes, each with its own HOME and
# XDG_DATA_HOME (so their user:// test saves never collide: XDG_DATA_HOME wins over HOME
# when it is set), its own absolute output file and its own log.
#
#   SHARDS   default: min(nproc, free RAM x 70% / SWEEP_PEAK_MB); SWEEP_PEAK_MB default 180,
#            the measured peak RSS of one sweep process over a full run (183320 KB).
#   OUT_DIR  default: results/<config id>/  ->  shard<i>.jsonl, shard<i>.log, home/<i>/
#
# Each shard restarts sweep.gd for every run, so each row comes from a fresh process and
# does not depend on the shard count or on what ran before it.
# Re-runnable: sweep.gd skips rows already written, so running the same command again
# resumes. The shard count is recorded in OUT_DIR/shards and must match on a resume (a
# different count would split run indexes differently). Ctrl-C stops every shard; a row cut
# off mid-write is trimmed before the next resume.
set -euo pipefail
cd "$(dirname "$0")/.."

if [ $# -lt 1 ]; then
	echo "usage: tools/run_sweep.sh CONFIG.json [SHARDS] [OUT_DIR]" >&2
	exit 2
fi
CONFIG=$(realpath "$1")
ID=$(sed -n 's/.*"id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$CONFIG" | head -1)
ID=${ID:-sweep}
OUT_DIR=$(realpath -m "${3:-results/$ID}")

PEAK_MB=${SWEEP_PEAK_MB:-180}
AVAIL_MB=$(awk '/MemAvailable/ {print int($2 / 1024)}' /proc/meminfo)
MEM_SHARDS=$(( AVAIL_MB * 70 / 100 / PEAK_MB ))
CPU_SHARDS=$(nproc)
DEFAULT=$(( MEM_SHARDS < CPU_SHARDS ? MEM_SHARDS : CPU_SHARDS ))
(( DEFAULT < 1 )) && DEFAULT=1
N=${2:-$DEFAULT}

mkdir -p "$OUT_DIR"
if [ -f "$OUT_DIR/shards" ] && [ "$(cat "$OUT_DIR/shards")" != "$N" ]; then
	echo "OUT_DIR was started with $(cat "$OUT_DIR/shards") shards; resume with the same count" >&2
	exit 2
fi
echo "$N" > "$OUT_DIR/shards"
echo "[run_sweep] $ID: $N shard(s) (cpu $CPU_SHARDS, memory $MEM_SHARDS at ${PEAK_MB} MB each, ${AVAIL_MB} MB free) -> $OUT_DIR"

# One import before any shard starts: parallel imports race on the shared .godot/ cache.
godot --headless --path . --import > "$OUT_DIR/import.log" 2>&1

pids=()
stop() {
	echo "[run_sweep] stopping ${#pids[@]} shard(s)" >&2
	kill "${pids[@]}" 2>/dev/null || true
	pkill -TERM -f "tools/sweep.gd -- $CONFIG" 2>/dev/null || true
	wait || true
	exit 130
}
trap stop INT TERM

for i in $(seq 1 "$N"); do
	out="$OUT_DIR/shard$i.jsonl"
	# A row cut off by an earlier stop has no newline; drop it so the resume starts clean.
	if [ -s "$out" ] && [ -n "$(tail -c1 "$out")" ]; then
		sed -i '$d' "$out"
	fi
	home="$OUT_DIR/home/$i"
	mkdir -p "$home"
	# One run per process (see tools/sweep.gd): restart until the shard reports it is done.
	(
		while :; do
			rc=0
			HOME="$home" XDG_DATA_HOME="$home/.local/share" \
				godot --headless --fixed-fps 60 --path . --script tools/sweep.gd -- \
				"$CONFIG" "$out" --shard "$i/$N" --max-runs 1 >> "$OUT_DIR/shard$i.log" 2>&1 || rc=$?
			[ "$rc" = 75 ] || exit "$rc"
		done
	) &
	pids+=($!)
done

fail=0
for i in "${!pids[@]}"; do
	if ! wait "${pids[$i]}"; then
		echo "[run_sweep] shard $((i + 1)) failed, see $OUT_DIR/shard$((i + 1)).log" >&2
		fail=1
	fi
done
rows=$(cat "$OUT_DIR"/shard*.jsonl 2>/dev/null | grep -c . || true)
echo "[run_sweep] done: $rows row(s) in $OUT_DIR"
exit $fail
