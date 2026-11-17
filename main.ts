// Brainrot Blitz — the hand-in program for make.fun's roblox-brainrot-01 bounty.
// The game is the Rojo project in this directory: `rojo build default.project.json
// --output game.rbxl` builds the place from src/ and default.project.json, and this
// program copies game.rbxl, src/, screenshots/ and PLAY.json from beside this file
// to /output and writes /output/dossier.json with the vendored make.fun library.
// Brainrot Blitz is a 3D brainrot tycoon: a green plaza, a red-carpet conveyor where
// 16 original brainrots walk past, 8 player bases, stealing with a base lock, a
// tsunami wall every two minutes, Golden Hour events, rebirths and a slap tool.
// The build is deterministic: no clock, no randomness in this file, so running it
// twice writes byte-identical output. The first screenshot by name is the cover and
// is also the game's first thumbnail on Roblox; every screenshot is a capture of the
// game running in Roblox Studio, 16:9 and at most 256 KiB.
//
// Every name under /output starts with a letter, a digit or _ and holds only letters,
// digits, . _ and -: the grader fails an entry whose output holds any other, so a file
// such as .gitkeep or .DS_Store copied in fails it. So src/ and screenshots/ are
// copied without any name that starts with a dot, at any depth.
//
// Outside the grader's container, MAKEFUN_OUTPUT_DIR stands in for /output:
//   mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

import { copyFileSync, cpSync, existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { basename, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildDossier } from './vendor/makefun-roblox.ts';

const here = fileURLToPath(new URL('.', import.meta.url));
const out = process.env.MAKEFUN_OUTPUT_DIR ?? '/output';

/** cpSync's filter: leave out every file and directory whose name starts with a dot (.gitkeep, .DS_Store, .git). */
const notDotted = (path: string): boolean => !basename(path).startsWith('.');

copyFileSync(join(here, 'game.rbxl'), join(out, 'game.rbxl'));
copyFileSync(join(here, 'PLAY.json'), join(out, 'PLAY.json'));
cpSync(join(here, 'src'), join(out, 'src'), { recursive: true, filter: notDotted });
mkdirSync(join(out, 'screenshots'), { recursive: true });
if (existsSync(join(here, 'screenshots'))) cpSync(join(here, 'screenshots'), join(out, 'screenshots'), { recursive: true, filter: notDotted });

// The scorer's own caps (reference/gate.json): only text_max_bytes shapes the bytes; the others refuse an entry the
// scorer would refuse (more than 4 screenshots or one over 256 KiB; a place of more than 500000 instances, whose
// scripts' sources come to over 8 MiB or whose scripts' paths come to over 1048576 characters, in all).
writeFileSync(
  join(out, 'dossier.json'),
  buildDossier(out, { text_max_bytes: 65536, screenshots: { max: 4, max_bytes: 262144 }, max_instances: 500000, scripts_max_source_bytes: 8388608, scripts_max_path_chars: 1048576 }),
);
