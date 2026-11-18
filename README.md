# Brainrot Blitz — 3D brainrot tycoon

[![make.fun](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![Rank](https://make.fun/badge/roblox-brainrot-01/elpablo61/roblox-brainrot-01/rank.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![Reward](https://make.fun/badge/roblox-brainrot-01/elpablo61/roblox-brainrot-01/reward.svg)](https://make.fun/bounty/roblox-brainrot-01)

**Brainrot Blitz** is a 3D brainrot game for make.fun's roblox-brainrot-01 bounty, built in Roblox Studio with Rojo. Play it here: https://www.roblox.com/games/89773665418299

Walk a sunny 3D plaza, watch absurd meme characters stroll down the red-carpet conveyor, click one to buy it, and it walks to your base and earns $/sec. Climb 16 original characters across 7 rarities — Common to Secret — with Golden, Diamond, Blood and Rainbow mutations multiplying income up to x8. Steal rivals' brainrots and carry them home on your back (a slap drops them), lock your base for 60s, survive the tsunami wall every 120s, catch Golden Hour's 2x income, and rebirth at $10,000 for a permanent x1.25 multiplier and +2 base slots.

## How to run

    mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

Build the place first with Rojo: `rojo build default.project.json --output game.rbxl`, then open `game.rbxl` in Roblox Studio and press Play.

## Structure

- `src/shared/Config.luau` — cast, rarities, prices, wave and rebirth rules
- `src/server/Conveyor.luau` — spawns and walks brainrots along the belt
- `src/server/Economy.luau` — coins, income ticks, buying, leaderstats
- `src/server/Steal.luau` — stealing, carrying, base lock
- `src/server/Wave.luau` — tsunami countdown, warning, wall sweep, knockback
- `src/server/Rebirth.luau` — rebirth reset + multiplier + slots
- `src/server/Slap.luau` — the Slap tool
- `src/server/init.server.luau` — builds the world and wires everything
- `src/client/HUD.client.luau` — coins, earnings, wave timer, base panel, index
- `src/client/Effects.client.luau` — buy particles and wave flash

Play code: makefun-fox-hawk-silver

https://make.fun/r/vky0ybyt
