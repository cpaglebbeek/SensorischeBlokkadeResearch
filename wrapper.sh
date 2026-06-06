#!/usr/bin/env bash
# wrapper.sh — runt één agent en commit + push resultaat naar GitHub
set -u
agent="${1:?agent-id required}"
base="/opt/research-agents/sensorische-blokkade-repo"
prompt_file="$base/prompts/$agent.md"
output_file="$base/output/$agent.md"
log_file="$base/logs/$agent.log"
status_file="$base/status.json"
status_lock="/tmp/research-status.lock"
git_lock="/tmp/research-git.lock"

mkdir -p "$base/output" "$base/logs"

start_ts="$(date -Iseconds)"
echo "[$agent] start $start_ts" >> "$log_file"

# Mark "running" status atomic
(
  flock -x 200
  python3 - <<PY
import json, pathlib
p = pathlib.Path("$status_file")
d = json.loads(p.read_text()) if p.exists() else {}
d["$agent"] = {"start": "$start_ts", "end": None, "exit": None, "state": "running"}
p.write_text(json.dumps(d, indent=2, sort_keys=True))
PY
) 200>"$status_lock"

# Pre-commit "running" status
(
  flock -x 201
  cd "$base"
  git pull --rebase --autostash 2>>"$log_file" || true
  git add status.json logs/$agent.log 2>>"$log_file"
  git commit -m "[$agent] running" --quiet 2>>"$log_file" || true
  git push github-research main 2>>"$log_file" || true
) 201>"$git_lock"

# Run agent
claude -p "$(cat "$prompt_file")" > "$output_file" 2>> "$log_file"
exit_code=$?

end_ts="$(date -Iseconds)"
output_bytes=$(wc -c < "$output_file" 2>/dev/null || echo 0)
output_lines=$(wc -l < "$output_file" 2>/dev/null || echo 0)
echo "[$agent] end $end_ts code=$exit_code bytes=$output_bytes lines=$output_lines" >> "$log_file"

# Mark "done" status atomic
(
  flock -x 200
  python3 - <<PY
import json, pathlib
p = pathlib.Path("$status_file")
d = json.loads(p.read_text()) if p.exists() else {}
d["$agent"] = {
    "start": "$start_ts",
    "end": "$end_ts",
    "exit": $exit_code,
    "state": "done" if $exit_code == 0 else "failed",
    "output_bytes": $output_bytes,
    "output_lines": $output_lines,
}
p.write_text(json.dumps(d, indent=2, sort_keys=True))
PY
) 200>"$status_lock"

# Post-commit result
(
  flock -x 201
  cd "$base"
  git pull --rebase --autostash 2>>"$log_file" || true
  git add output/$agent.md logs/$agent.log status.json 2>>"$log_file"
  git commit -m "[$agent] $( [ $exit_code -eq 0 ] && echo done || echo failed ) — bytes=$output_bytes lines=$output_lines" --quiet 2>>"$log_file" || true
  git push github-research main 2>>"$log_file" || echo "[$agent] PUSH FAILED $(date -Iseconds)" >> "$log_file"
) 201>"$git_lock"

exit $exit_code
