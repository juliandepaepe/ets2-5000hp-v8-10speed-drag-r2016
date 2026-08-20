# 5000 hp Dragster V8 + 10-speed — Scania R 2016 (unofficial)

A race package for the Scania R (2016 / next generation) in Euro Truck
Simulator 2: a 5000 hp V8 and a close-ratio 10-speed with a torque converter,
geared for standing starts and for top speed.

This is deliberately unrealistic and does not pretend otherwise. If you want a
fast truck that still behaves like a truck, use a haulage tune instead.

What it is *not* is arbitrary. A big torque number bolted to a haulage gearbox
is slower than a well-matched 1000 hp build, because the box upshifts out of
the power band on every change and the engine cannot rev. Both parts here are
sized against each other, and every value is derived in
[docs/tuning.md](docs/tuning.md).

Tested on ETS2 **1.60.1.7**.

## What it adds

Two optional parts. Nothing stock is overwritten — every factory engine and
gearbox is still selectable.

### Engine — "16.4 L V8 5000 Drag (unofficial)"

| | |
|---|---|
| Power | 5000 hp (3676 kW) @ 3900 rpm |
| Torque | 10 000 Nm, flat 1200–3000 rpm |
| Rev limit | 5200 (5400 in neutral) |
| Derate | none — no AdBlue use, no low-AdBlue limit |
| Price | €250,000, level 26 |

The rev limit is the interesting part. **No factory Scania R 2016 engine sets
`rpm_limit` at all**, so every one of them inherits a low default and simply
cannot rev — across the whole game the values in use are 1900–2300. Lifting it
to 5200 is what makes a ten-speed close-ratio ladder and a 400 km/h top gear
possible in the first place.

The engine also sets the `rpm_range_*` family, which tells the automated
gearbox where to work. Without it a 10 000 Nm engine still shifts up around
1400 rpm like a haulage unit and falls out of its own power band every time.

### Transmission — "10-speed Drag AMT 5000 (unofficial)"

| | |
|---|---|
| Gears | 10 forward, 1 reverse, no crawlers |
| Step | uniform 1.216, spread 5.833 |
| Converter | 2.20 stall ratio |
| Final drive | 2.64 |
| Shift time | 0.10 s (factory: 0.7 s) |
| Top gear | 522 km/h at the limiter |
| Retarder | 5-stage, front-loaded |
| Price | €120,000, level 26 |

Top gear deliberately reaches far past what the truck can achieve, so **drag
sets the ceiling rather than the rev limiter** — a build that bounces off the
limiter in top has thrown away speed. Estimated terminal velocity bobtail is
**~410 km/h at ~4090 rpm**, just past peak power, which is close to optimal
gearing.

## Before it will do any of this

**Turn off the truck speed limiter:** Options → Gameplay → *Truck speed
limiter*. Leave it on and you are capped at 90 km/h and none of the above
happens. Worth also disabling police and traffic before a top-speed run.

## Two things that will surprise you

**Launch is traction-limited, not power-limited.** The converter and first gear
together demand roughly 481 kN, about 6.5 g on a bobtail tractor — far past
what the tyres hold. A **6x4 chassis drives two axles and launches far better
than the 6x2**, which drives only one. No engine fixes wheelspin.

**Stopping is the real problem.** Kinetic energy at 410 km/h is about 22 times
that at 90. The retarder is staged aggressively to help, but service brakes are
defined on the chassis and are untouched by this mod. Leave far more room than
instinct suggests.

Also: the factory V8 sound was never sampled anywhere near 5000 rpm. It holds
up better than expected, but it is not a race sound.

## Install

Download **`drag_5000_r2016.scs`** from the
[latest release](../../releases/latest), or build it yourself (below).

**1. Drop the `.scs` into your mod folder.** Do not unzip it.

| Platform | Mod folder |
|---|---|
| Windows | `%USERPROFILE%\Documents\Euro Truck Simulator 2\mod\` |
| Linux (native) | `~/.local/share/Euro Truck Simulator 2/mod/` |
| macOS | `~/Library/Application Support/Euro Truck Simulator 2/mod/` |

<details>
<summary>Linux via Proton / Steam Play</summary>

The native paths do not apply — the game sees a Windows filesystem inside the
Proton prefix:

```
~/.steam/steam/steamapps/compatdata/227300/pfx/drive_c/users/steamuser/Documents/Euro Truck Simulator 2/mod/
```

</details>

**2. Enable it** in Mod Manager, from the profile screen, before loading a
profile.

**3. Fit the parts.** Truck Manager → your Scania R 2016 → Upgrade → Engine tab
and Transmission tab.

> **Removing the mod:** switch back to factory parts *first*. If the mod
> disappears while these are fitted, the game silently falls back to the 370 hp
> engine and the base gearbox.

## Build

Requires Windows PowerShell 5.1 or later. No game files needed.

```powershell
.\build.ps1              # pack to dist\drag_5000_r2016.scs
.\build.ps1 -Install     # pack and copy into the game mod folder
.\build.ps1 -Uninstall   # remove from the game mod folder
.\build.ps1 -Workshop    # lay out dist\workshop\ for the SCS Workshop Uploader
```

The Workshop format is not a `.scs`: the uploader wants a folder with
`versions.sii` plus a subfolder of loose files. The two targets also disagree
about the manifest — the Workshop validator rejects `compatible_versions[]` and
warns about `display_name`, while the standalone `.scs` needs both — so those
fields are tagged `#!standalone` in `src/manifest.sii` and stripped by
`-Workshop`.

The build refuses to pack on two mistakes that give no usable in-game error: a
UTF-8 BOM ahead of the leading `SiiNunit` token, and a unit-name token over 12
characters or outside `[a-z0-9_]`. The second one silently makes the game
discard an entire file, so the part just never appears.

### Images

```powershell
.\make-icon.ps1 -Source "path\to\your\screenshot.png"
```

Produces `src/mod_icon.jpg` (276 × 162, exact) and
`dist/workshop_preview.jpg` (640 × 360, max 1 MB). Use an image you own —
your own in-game screenshots are the safe choice.

## Licence

[MIT](LICENSE) covers the definitions, scripts and documentation, all of which is original work. Images are NOT covered by the licence - see [NOTICE](NOTICE).

Unofficial, fan-made, and containing no files from Euro Truck Simulator 2. Not
affiliated with, authorised by, or endorsed by SCS Software s.r.o. or Scania CV
AB. "Scania" is a trademark of Scania CV AB, used only to identify the vehicle
these parts fit. The parts are fictional and represent no real product. See
[NOTICE](NOTICE).
