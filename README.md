# Brainrot Blitz

[![make.fun](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/elpablo61/roblox-brainrot-01/rank.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/elpablo61/roblox-brainrot-01/reward.svg)](https://make.fun/bounty/roblox-brainrot-01)

A 3D brainrot tycoon for make.fun's "Make the best AI Roblox brainrot game"
bounty (roblox-brainrot-01). Built with Rojo, played in Roblox Studio, published
as a Public experience on Roblox.

## The game

A green 3D plaza with a red-carpet conveyor down the middle. Sixteen original
brainrot characters — Sir Quackington, Turbo Turnip, Professor Pickle, DJ Toast,
Captain Noodle, Madame Mooncake, Lord Llama Latte, Sir Barksalot, The Golden
Goblin of Gouda, Emperor Eggplant, The Infinite Spaghetti Monster and more —
walk the belt in six rarities (Common, Rare, Epic, Legendary, Mythic, Secret)
with Golden, Diamond, Rainbow and Blood mutations.

- **Buy** a brainrot with coins (start with $150) — it walks to your base and
  earns $/sec, forever.
- **Steal** a rival's brainrot by clicking it and carrying it home on your back
  — unless their base lock is on (60s lock, 60s cooldown). A slap or a tsunami
  drops whatever you are carrying.
- **Survive the tsunami** every 120 seconds: a 20-second warning, then a giant
  water wall sweeps the plaza. Inside your own base you are safe; outside it
  you are knocked back and lose 10% of your coins.
- **Events:** Golden Hour every ~180s doubles everyone's income for 60s, and
  every Mythic or Secret spawn fires a server-wide 2x income window.
- **Rebirth** at $10,000: coins reset, permanent +25% income multiplier, +2 base
  slots. The collection index tracks your progress out of 16.

## Layout

- `src/shared/Config.luau` — cast, rarities, mutations, prices, timings.
- `src/server/Conveyor.luau` — spawns and walks brainrots down the belt.
- `src/server/Economy.luau` — coins, income ticking, buying, Golden Hour.
- `src/server/Wave.luau` — tsunami countdown, warning, wall sweep, knockback.
- `src/server/Steal.luau` — stealing, carrying, base lock.
- `src/server/Rebirth.luau` — rebirth reset + multiplier + slots.
- `src/server/Slap.luau` — the Slap tool, handed out fresh on every spawn.
- `src/server/init.server.luau` — builds the 3D world and wires the modules.
- `src/client/HUD.client.luau` — coins, earnings, wave timer, base panel, buttons.
- `src/client/Effects.client.luau` — buy/wave particles and sounds.
- `default.project.json` — Rojo project (Lighting set here, never from a script).
- `game.rbxl` — the place Rojo builds from `src/`.
- `screenshots/` — four captures of the game running in Studio; the first by
  name is the cover and the game's first thumbnail on Roblox.
- `PLAY.json` — the published Public experience (place 89773665418299).

## Run it

Build the place, then hand it in exactly as the grader does:

    rojo build default.project.json --output game.rbxl
    mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

Play it on Roblox: https://www.roblox.com/games/89773665418299

---
Referral: vky0ybyt
