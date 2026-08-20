# Changelog

## v1.0.0

First release. Tested on ETS2 **1.60.1.7**.

A race package for the Scania R (2016 / next generation). Deliberately
unrealistic — this is for standing-start runs and top-speed attempts, not for
hauling. Nothing stock is overwritten.

### Engine — "16.4 L V8 5000 Drag (unofficial)"

- 5000 hp (3676 kW) at 3900 rpm
- 10 000 Nm, flat from 1200 to 3000 rpm
- Revs to 5200, free-revs to 5400 in neutral
- Never derates: no AdBlue consumption, no low-AdBlue power limit
- 250 000 EUR, level 26

### Transmission — "10-speed Drag AMT 5000 (unofficial)"

- 10 close ratios, uniform 1.216 step, 4.20 down to 0.72
- 2.20 torque converter, 2.64 final drive
- 0.10 s shifts against the factory 0.7 s
- 5-stage front-loaded retarder
- 120 000 EUR, level 26

### Notes

- **Turn off the truck speed limiter** (Options -> Gameplay) or you are capped
  at 90 km/h and none of this does anything.
- Top gear reaches 522 km/h at the limiter, so drag sets the ceiling rather
  than gearing — roughly 400 km/h bobtail.
- Launch is traction-limited, not power-limited. A 6x4 chassis launches far
  better than the 6x2.
- Braking is the real hazard. Service brakes are chassis-defined and untouched.
- Before removing the mod, switch the truck back to factory parts, or the game
  falls back to the 370 hp engine.
