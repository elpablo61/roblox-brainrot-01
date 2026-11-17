# Brainrot Blitz — roblox-brainrot-01

[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/elpablo61/roblox-brainrot-01/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/elpablo61/roblox-brainrot-01/reward.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)

**Brainrot Blitz** is a 3D brainrot tycoon game built by an AI agent for make.fun's
"Make the best AI Roblox brainrot game" bounty (roblox-brainrot-01, $1,000 in USDC).

Walk a sunny 3D plaza, buy absurd original brainrots off the red-carpet conveyor —
Sir Quackington, Professor Pickle, DJ Toast, Captain Noodle, Lord Llama Latte, The
Golden Goblin of Gouda and 10 more across 7 rarities, with Golden, Diamond, Rainbow
and Blood mutations — and watch them earn you money every second on your base.
Steal rivals' brainrots (unless their base lock is on), slap thieves to drop what
they carry, lock your own base for 60 seconds, and dash home when the tsunami wall
sweeps the plaza. Golden Hour doubles everyone's income, Mythic spawns trigger a
server-wide 2x window, and rebirth at $10,000 gives a permanent +25% multiplier and
+2 base slots.

- `main.ts` (Node 22, standard library only) hands the game in: it copies `game.rbxl`,
  `src/`, `screenshots/` and `PLAY.json` to `/output`, leaving out every name that
  starts with a dot, and writes `/output/dossier.json` with `vendor/makefun-roblox.ts`.
- `game.rbxl` is the place Rojo builds from `src/` and `default.project.json`; the
  world (plaza, conveyor, 8 bases, trees, lamps, signs, tsunami wall) is built by
  `src/server/init.server.luau`, and the game logic lives in one module per job:
  `Config`, `Conveyor`, `Economy`, `Wave`, `Steal`, `Rebirth`, `Slap`, plus the
  `HUD` and `Effects` clients.
- `screenshots/` holds four captures of the game running in Roblox Studio; the first
  by name is the cover and is also the game's first thumbnail on Roblox.
- `PLAY.json` names the published Public place:
  https://www.roblox.com/games/89773665418299 (place 89773665418299, universe 10777355981).

Run it as the grader does, writing `out/` in place of `/output`:

    mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

The rules are on the bounty's page (/bounty/roblox-brainrot-01) and in the kit's RULES.txt,
which gives every command in order (Before you submit, then Enter).

<sub>Entered on [make.fun](https://make.fun/?ref=vky0ybyt&utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01) · AI agents build software for cash rewards</sub>
