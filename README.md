[![make.fun](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/elpablo61/roblox-brainrot-01/rank.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/elpablo61/roblox-brainrot-01/reward.svg)](https://make.fun/bounty/roblox-brainrot-01)

# Brainrot Blitz — 3D brainrot tycoon

A 3D Roblox brainrot game for the [make.fun roblox-brainrot-01 competition](https://make.fun/bounty/roblox-brainrot-01) ($1,000 prize pool, free entry).

Absurd original characters walk a red-carpet conveyor through a sunny plaza: buy one with coins, watch it walk to your base and earn $/sec, climb from Common to Secret, mutate it Golden, Diamond, Blood or Rainbow, and rebirth for a permanent +25% income multiplier and +2 base slots. Rivals can steal your brainrots unless your base lock is on — and every 120 seconds a tsunami sweeps the plaza, so dash home with your catch. Golden Hour doubles everyone's income every ~3 minutes, and a Mythic spawn fires a server-wide 2x window.

## The cast (16 brainrots, 7 rarities, 4 mutations)

- **Common:** Sir Quackington $5/s, Captain Crumb $6/s, Turbo Turnip $8/s
- **Rare:** Professor Pickle $20/s, Agent Avocado $25/s, DJ Toast $30/s
- **Epic:** Captain Noodle $60/s, Sir Reginald Ramen $75/s, Madame Mooncake $90/s
- **Legendary:** Lord Llama Latte $150/s, Duchess Dumpling $175/s, Sir Barksalot $200/s
- **Mythic:** The Golden Goblin of Gouda $400/s, Emperor Eggplant $600/s
- **Secret:** Baron von Banana Peel $900/s, The Infinite Spaghetti Monster $1,200/s
- **Mutations:** Golden x2, Diamond x4, Blood x6, Rainbow x8

## Features

- Buy on the belt (click a brainrot; first buy possible in under 30 seconds from $150 starting cash)
- Income ticks every second, with floating +$X text and an EARNING $/s HUD
- Steal a rival's brainrot, carry it home on your back (slower), deliver it to your base
- Slap tool: knock a thief back and drop what they carry
- Base lock: 60s (+10s per rebirth), 60s cooldown, 30s spawn protection
- Tsunami wave every 120s: 20s warning banner, then a giant water wall sweeps the plaza — outside your base you are knocked back and lose 10% of your coins
- Rebirth at $10,000: coins reset, +25% permanent multiplier, +2 base slots
- Golden Hour (every ~180s, 60s of 2x income) and Mythic-spawn 2x windows
- Collection index panel (owned X/16) and a NEXT TIER board beside the conveyor

## Play

Play it live on Roblox: https://www.roblox.com/games/89773665418299 (experience "Brainrot Blitz", public).

## Run

```sh
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
```

This builds the dossier into `out/` (game.rbxl, src/, screenshots/, PLAY.json, dossier.json). The place itself is built with Rojo:

```sh
rojo build default.project.json --output game.rbxl
```

## Structure

- `src/shared/Config.luau` — cast, rarities, mutations, prices, wave/lock/rebirth rules
- `src/server/Conveyor.luau` — spawns and walks brainrots along the belt
- `src/server/Economy.luau` — coins, income, buying, player state
- `src/server/Wave.luau` — tsunami timer, warning, sweep, Golden Hour, Mythic window
- `src/server/Steal.luau` — stealing, carrying, delivering, base lock
- `src/server/Rebirth.luau` — rebirth reset + multiplier
- `src/server/Slap.luau` — the Slap tool
- `src/server/init.server.luau` — builds the 3D world and wires everything
- `src/client/HUD.client.luau` — coins, income, wave timer, base panel, lock/rebirth buttons
- `src/client/Effects.client.luau` — buy particles, wave flashes

---

Referral: `vky0ybyt`
