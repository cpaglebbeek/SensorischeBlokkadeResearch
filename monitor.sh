#!/usr/bin/env bash
# monitor.sh — polling-loop, schrijft SUMMARY.md zodra alle 8 done
set -u
base="/opt/research-agents/sensorische-blokkade-repo"
status_file="$base/status.json"
summary_file="$base/SUMMARY.md"
git_lock="/tmp/research-git.lock"
agents=(B1 B2 B3 B4 D1 D2 D3 D4)

cd "$base"

echo "[monitor] start $(date -Iseconds)"

while true; do
  sleep 60

  if [ ! -f "$status_file" ]; then
    continue
  fi

  done_count=$(python3 - <<PY
import json, pathlib
d = json.loads(pathlib.Path("$status_file").read_text())
agents = ["B1","B2","B3","B4","D1","D2","D3","D4"]
done = sum(1 for a in agents if d.get(a, {}).get("state") in ("done", "failed"))
print(done)
PY
)

  echo "[monitor] $(date -Iseconds) — $done_count/8 done"

  if [ "$done_count" -eq 8 ]; then
    echo "[monitor] alle 8 klaar — schrijf SUMMARY"
    break
  fi
done

# Schrijf SUMMARY.md
completed_ts=$(date -Iseconds)
python3 - <<PY > "$summary_file"
import json, pathlib
d = json.loads(pathlib.Path("$status_file").read_text())
agents = ["B1","B2","B3","B4","D1","D2","D3","D4"]
agent_titles = {
    "B1": "broad — NL+EN literatuurkaart H1-H10",
    "B2": "broad — Zorgpad NL",
    "B3": "broad — Validated NL self-test instrumenten",
    "B4": "broad — Tooling-landschap + USP Plomp",
    "D1": "deep — H3 dissociatie/freeze",
    "D2": "deep — H1 CAPD volwassenen + NL",
    "D3": "deep — H4 ADHD-inattentief + SPD",
    "D4": "deep — T1-T6 Web Audio implementatie",
}
print("# SUMMARY — Zwerm voltooid")
print()
print(f"**Voltooid:** $completed_ts")
print(f"**Gestart:**  {d.get('_zwerm',{}).get('started','?')}")
print()
print("| Agent | Onderwerp | State | Bytes | Lines | Start | End | Duur |")
print("|-------|-----------|-------|------:|------:|-------|-----|-----:|")
from datetime import datetime
for a in agents:
    e = d.get(a, {})
    title = agent_titles[a]
    state = e.get("state", "?")
    by = e.get("output_bytes", 0)
    ln = e.get("output_lines", 0)
    st = e.get("start", "?")
    en = e.get("end", "?")
    try:
        ds = datetime.fromisoformat(st)
        de = datetime.fromisoformat(en)
        dur = str(de - ds).split(".")[0]
    except Exception:
        dur = "?"
    print(f"| {a} | {title} | {state} | {by:,} | {ln} | {st[11:19]} | {en[11:19]} | {dur} |")
print()
print("## Output per agent")
print()
for a in agents:
    print(f"- [{a}.md](output/{a}.md) — {agent_titles[a]}")
print()
print("## Volgende stappen (Mac-zijde)")
print()
print("1. Pull deze repo: `git -C ~/Documents/Gemini_Projects/SensorischeBlokkadeResearch pull`")
print("2. Lees outputs + integreer in `GezondheidJoyce/dossiers/sensorische_blokkade/HYPOTHESEN.md` evidence-velden + nieuwe `INTEGRATIE.md`")
print("3. Update RESUME-register na integratie")
PY

# Update _zwerm status
python3 - <<PY
import json, pathlib
p = pathlib.Path("$status_file")
d = json.loads(p.read_text())
d.setdefault("_zwerm", {})
d["_zwerm"]["completed"] = "$completed_ts"
d["_zwerm"]["agents_done"] = 8
p.write_text(json.dumps(d, indent=2, sort_keys=True))
PY

# Final commit
(
  flock -x 201
  cd "$base"
  git pull --rebase --autostash 2>/dev/null || true
  git add SUMMARY.md status.json
  git commit -m "[zwerm] COMPLEET $completed_ts — alle 8 agents klaar, SUMMARY.md geschreven" --quiet
  git push origin main 2>&1 | tail -3
) 201>"$git_lock"

echo "[monitor] SUMMARY gepusht. Klaar."
