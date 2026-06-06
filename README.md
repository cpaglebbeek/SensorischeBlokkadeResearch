# SensorischeBlokkadeResearch

Research-output van 8 autonome Claude Code agents die parallel een broad+deep dive uitvoeren naar **differentiële hypothesen voor "hoort wel maar verwerkt niet"** bij volwassenen met intact perifeer gehoor.

## Achtergrond

Spin-off van klinisch dossier `cpaglebbeek/GezondheidJoyce/dossiers/sensorische_blokkade/` (private, git-crypt). De prompts en output zijn **publiek-bruikbaar generiek onderzoek** — geen patiëntdata. Tooling-roadmap: `cpaglebbeek/WatHoorIk` v0.1.0-Plomp (publieke web-app voor zelf-test centrale auditieve verwerking).

## Hypothesen (10)

- **H1** CAPD (Centrale Auditieve Verwerkingsstoornis)
- **H2** Auditory Verbal Agnosia / Pure Word Deafness
- **H3** Dissociatieve freeze / functional freeze
- **H4** ADHD-inattentief + Sensory Processing Disorder shutdown
- **H5** Hormonale fluctuatie
- **H6** Slaap-deficit / vermoeidheid / farmaca
- **H7** Migraine-aura / focale neurologie
- **H8** Hyperacusis / misofonie
- **H9** Anauralia (auditieve aphantasie)
- **H10** Cognitieve overload (normale variant)

## 8 agents

| ID | Type | Onderwerp |
|----|------|-----------|
| B1 | broad | NL+EN literatuurkaart H1-H10 |
| B2 | broad | Zorgpad NL: huisarts → APD-poli → psycholoog → psychiater |
| B3 | broad | Validated NL self-test instrumenten inventaris |
| B4 | broad | Bestaand tooling-landschap + USP voor WatHoorIk-Plomp |
| D1 | deep | H3 dissociatie/freeze — neurobiologie + behandelpaden + thuis-protocol |
| D2 | deep | H1 CAPD — klinische criteria volwassenen + NL audiologen |
| D3 | deep | H4 ADHD-inattentief + SPD — volwassen zorgpad + screening |
| D4 | deep | T1-T6 Web Audio API implementatie skeletten |

## Status live

Bekijk `status.json` voor real-time agent-status (start, end, exit-code per agent). Bekijk `SUMMARY.md` voor finale samenvatting wanneer alle 8 klaar zijn.

## Mappenstructuur

```
prompts/    B1.md ... D4.md           (initial commit, niet meer wijzigen)
output/     B1.md ... D4.md           (door agents geschreven + gecommit)
logs/       B1.log ... D4.log         (per-agent log)
status.json                            (live status alle 8)
SUMMARY.md                             (final, bij compleet)
wrapper.sh                             (per-agent runner met auto-commit)
run.sh                                 (start tmux-zwerm)
monitor.sh                             (polling-loop voor SUMMARY-generatie)
```

## Architectuur

- **Runner:** HorseCloud55, `/opt/research-agents/sensorische-blokkade-repo/`
- **Claude Code:** v2.1.163 (Claude Code), headless via `claude -p`
- **Tmux-session:** "research", 1 init + 1 monitor + 8 agent-windows
- **Auto-commit:** wrapper.sh doet na elke agent: `git pull --rebase --autostash` + `git add output/X.md logs/X.log status.json` + `git commit` + `git push github-research main` (flock-protected, sequentieel)
- **Final summary:** monitor.sh detecteert alle 8 done, schrijft SUMMARY.md, pusht

## Licentie

AGPL-3.0 — vrij te hergebruiken, afgeleid werk moet ook AGPL zijn.
Output is generieke wetenschappelijke synthese; bronnen zijn academisch en publiek.
