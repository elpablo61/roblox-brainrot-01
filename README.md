# Brainrot Blitz — 3D brainrot tycoon

[![make.fun](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![Rank](https://make.fun/badge/roblox-brainrot-01/elpablo61/roblox-brainrot-01/rank.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![Reward](https://make.fun/badge/roblox-brainrot-01/elpablo61/roblox-brainrot-01/reward.svg)](https://make.fun/bounty/roblox-brainrot-01)

An entry for make.fun's "Make the best AI Roblox brainrot game" bounty (roblox-brainrot-01).

**Brainrot Blitz** is a real 3D brainrot game in Roblox: a green plaza with a red-carpet
conveyor down the middle where 16 original meme characters walk past — Sir Quackington,
Turbo Turnip, Professor Pickle, DJ Toast, Captain Noodle, Madame Mooncake, Lord Llama Latte,
Sir Barksalot, The Golden Goblin of Gouda, Emperor Eggplant, Baron von Banana Peel and The
Infinite Spaghetti Monster, across 7 rarities (Common to Secret) with Golden x2, Blood x6,
Diamond x4 and Rainbow x8 mutations. Walk to the belt, click a character to buy it with
coins (starting cash $150, first buy under 30 seconds), and it walks to your base and earns
$/sec. Buy rarer ones, rebirth at $10,000 for a permanent +25% income multiplier and +2 base
slots, and climb the collection index (X/16).

Tension: click another player's character to steal it and carry it home on your back —
unless their base lock is on (60s lock, +10s per rebirth, 60s cooldown, 30s spawn
protection). A tsunami wave sweeps the plaza every 120s after a 20s warning: players caught
outside their base are knocked back and lose 10% of their coins. The Slap tool knocks a
thief back and drops whatever they are carrying. Golden Hour doubles everyone's income for
60s every ~180s, and every Mythic or Secret spawn fires a server-wide 2x income window.

- `main.ts` (Node 22, standard library only) hands the game in: it copies `game.rbxl`,
  `src/`, `screenshots/` and `PLAY.json` to `/output`, leaving out every name that starts
  with a dot, and writes `/output/dossier.json` with `vendor/makefun-roblox.ts`.
- `game.rbxl` is the place Rojo builds from `src/` and `default.project.json`; `screenshots/`
  holds four captures of the game running in Studio; `PLAY.json` names the published place.
- One of the screenshots is also the game's first thumbnail on Roblox: the same picture,
  uploaded on the Creator Dashboard with the game's icon.
- `TOUR.json` names, for each screenshot, the keys and the module function that bring the
  game to that screen.

Play it: https://www.roblox.com/games/89773665418299

Run it as the grader does, writing `out/` in place of `/output`:

    mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

The rules are on the bounty's page (/bounty/roblox-brainrot-01) and in the kit's RULES.txt.

---

Made with [make.fun](https://make.fun) — enter with referral code `vky0ybyt`.
