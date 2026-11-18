# Noodle Brainrot Heist — roblox-brainrot-01

An original Steal-a-Brainrot-style 3D game for make.fun's roblox-brainrot-01 bounty
($1,000 prize pool, top 50 split, $150 first place). All characters, names and
gags are original inventions — no borrowed brainrot names, images or audio.

## How it plays

- **The belt:** the Noodle-O-Matic spits out a fresh brainrot every 6 seconds.
  It strolls east along the central conveyor with a floating price tag.
- **Buy & carry:** walk up to one on the belt and press **E** to buy it, then
  carry it home on your head and press **E** again inside your own base to
  place it. Every brainrot in your base pays you every second.
- **Steal:** walk into a rival's unlocked base and press **E** next to their
  brainrot to steal it — then run it home before they notice.
- **Lock:** press **Q** (or the Lock button) to shut your base door for 45 s.
  60 s cooldown after it opens.
- **Rebirth:** press **R** twice (or the Rebirth button) once you can afford
  it: cash and base wipe, income multiplier grows +0.5x forever.
- **Map events:** every 90 s a Noodle Tsunami or Giggle Storm sweeps the map.
  Caught outside your base you walk slow, and a carried brainrot can be
  knocked out of your hands.

## The roster — 12 original brainrots, 6 rarities, 3 mutations

| Rarity | Brainrot | $/s | Cost |
|---|---|---|---|
| Common | Captain Sofa Spud | 1 | $25 |
| Common | Sir Wobbly Teacup | 2 | $50 |
| Rare | DJ Sour Pickle | 5 | $150 |
| Rare | Madam Moon Pie | 8 | $250 |
| Epic | Jazz Macaroni Fish | 15 | $500 |
| Epic | Grandma's Flying Slipper | 20 | $750 |
| Legendary | Professor Noodle Wizard | 40 | $1,500 |
| Legendary | Turbo Toilet Racer | 60 | $2,500 |
| Mythic | The Infinite Dumpling | 120 | $6,000 |
| Mythic | Chairman Croissant | 180 | $9,000 |
| Secret | Sir Bananaphone the Third | 500 | $25,000 |
| Secret | The Forbidden Left Sock | 800 | $40,000 |

Mutations roll on spawn: **Golden x2** (8%), **Rainbow x5** (3%),
**Glitch x10** (1%). Every model is built from plain Roblox Parts — no meshes,
no downloaded assets.

## Layout

- `default.project.json` — the 3D world: conveyor belt, Noodle-O-Matic,
  8 walled bases (6 slots each), spawn pad, trees, 4 original meme statues
  (noodle bowl, pickle, sofa potato, moon pie), lamps, sky + lighting.
- `src/server/` — Config (roster/prices), Economy (cash/income/rebirth),
  Bases (plots/slots/locks), Spawner (belt + Part-built models),
  Carry (buy/place/steal), Events (90 s map waves), init.server (bootstrap).
- `src/client/Game.client.luau` — HUD (cash, income, base roster, event
  countdown, prompt, leaderboard, notifications) + E/Q/R via
  ContextActionService.
- `main.ts` — hands the game in: copies game.rbxl, src/, screenshots/ and
  PLAY.json to /output and writes dossier.json (vendor kit unchanged).
- `TOUR.json` — the 4 planned screenshot steps (see below).
- `PLAY.json` — placeholder until the place is published (fill in the real
  place_id / universe_id / url on 2026-11-20).

## Build & hand in

    ~/workspace/bin/rojo build default.project.json --output game.rbxl
    mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

## Screenshots (to be shot in Roblox Studio on the user's PC, 2026-11-20)

Screenshots are intentionally empty in this repo until then:

1. `1-cover.png` — cover / first Roblox thumbnail: base panorama with
   brainrots and the cash counter ticking.
2. `2-buy.png` — the moment of buying a brainrot off the belt.
3. `3-steal.png` — stealing / locked-door standoff at a rival base.
4. `4-event.png` — a map event sweeping the map mid-carry.
