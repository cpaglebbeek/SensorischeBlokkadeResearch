#!/usr/bin/env bash
# run.sh — start zwerm in tmux-session "research"
set -eu
base="/opt/research-agents/sensorische-blokkade-repo"
session="research"
agents=(B1 B2 B3 B4 D1 D2 D3 D4)

cd "$base"
mkdir -p output logs
chmod +x wrapper.sh monitor.sh

# Pre-flight: claude logged in?
if ! claude -p "ping" >/dev/null 2>&1; then
  echo "FATAL: claude CLI niet ingelogd. Doe eerst: claude, /login, exit. Abort."
  exit 2
fi

if tmux has-session -t "$session" 2>/dev/null; then
  echo "Tmux-session '$session' draait al — abort. Kill eerst: tmux kill-session -t $session"
  exit 1
fi

# Init status.json + initial commit "zwerm started"
date_iso=$(date -Iseconds)
python3 - <<PY
import json, pathlib
pathlib.Path("$base/status.json").write_text(json.dumps({
    "_zwerm": {"started": "$date_iso", "completed": None, "agents_total": 8, "agents_done": 0}
}, indent=2, sort_keys=True))
PY

git pull --rebase --autostash 2>/dev/null || true
git add status.json
git commit -m "[zwerm] gestart $date_iso — 8 agents (B1-D4)" --quiet
git push origin main 2>&1 | tail -3

# Start tmux
tmux new-session -d -s "$session" -n init "echo 'zwerm start: $date_iso'; sleep 2"
tmux new-window -t "$session" -n monitor "bash $base/monitor.sh"

for a in "${agents[@]}"; do
  tmux new-window -t "$session" -n "$a" "bash $base/wrapper.sh $a; sleep 30"
done

tmux list-windows -t "$session"
echo "Zwerm gestart. Inspecteer: tmux attach -t $session  (Ctrl-b + n)"
echo "GitHub live: https://github.com/cpaglebbeek/SensorischeBlokkadeResearch"
echo "Status: cat $base/status.json"
