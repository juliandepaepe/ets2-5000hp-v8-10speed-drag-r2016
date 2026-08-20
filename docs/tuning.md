# Tuning derivation

Every number in `src/def/` is computed here. Nothing is transcribed from an
existing definition file.

The haulage package this project is derived from had to respect real-world
plausibility. This one does not — but "unrealistic" is not the same as
"arbitrary", and the two parts still have to agree with each other or the
truck is slower than a well-matched 1000 hp build.

## Reference geometry

315/70 R22.5 rear tyres:

```
diameter      = 2 * (315 mm * 0.70) + 22.5 in * 25.4 = 1012.5 mm
circumference = pi * 1.0125 = 3.1809 m
rolling radius= 0.50625 m

rpm = km/h * 5.2397 * (final_drive * gear)
```

## Engine

### Target

5000 PS (3677.5 kW), with the torque plateau starting low enough to launch and
a rev ceiling high enough that a close-ratio box is usable.

### Sizing

The game derives power from the torque curve; `info[]` is display text only.

```
P = torque * max(curve_factor * rpm) * 2*pi/60          2*pi/60 = 0.104720
```

Peak torque is set at **10 000 Nm** and the power peak placed at 3900 rpm:

```
max(f * rpm) = 0.90 * 3900 = 3510
P = 10000 * 3510 * 0.104720 = 3 675 672 W = 3675.7 kW = 4998 PS
```

| rpm | factor | f x rpm | note |
|-----|--------|---------|------|
| 0 | 0.00 | 0 | |
| 500 | 0.35 | 175 | |
| 1200 | 1.00 | 1200 | plateau starts |
| 3000 | 1.00 | 3000 | plateau ends — 1800 rpm wide |
| 3400 | 0.96 | 3264 | |
| **3900** | **0.90** | **3510** | power peak |
| 4300 | 0.78 | 3354 | |
| 4800 | 0.55 | 2640 | |
| 5200 | 0.25 | 1300 | limiter |
| 5400 | 0.00 | 0 | |

The plateau is 1800 rpm wide on purpose. Area under the curve is what wins a
standing start, not the peak.

### The two fields that actually matter

**`rpm_limit`.** No factory Scania R 2016 engine sets this field — every one of
them inherits the low default, so no amount of torque makes them rev. Across
the whole game the values in use are 1900–2300. Setting **5200** is what makes
a ten-speed close-ratio ladder and a 400 km/h top gear possible at all.

**`rpm_range_*`.** These tell the automated gearbox where to operate. A 10 000
Nm engine with a haulage shift map still upshifts around 1400 rpm and drops out
of its own power band on every change.

```
rpm_range_power:        (3000, 4300)   band the box targets
rpm_range_low_gear:     (2600, 4700)   allowed window, low gears
rpm_range_high_gear:    (3000, 4600)   allowed window, high gears
rpm_range_engine_brake: (3600, 5200)
```

`adblue_consumption: 0.0` with `no_adblue_power_limit: 1.0` means it never
consumes and never derates — a run cannot be spoiled halfway by a fluid level.

## Transmission

### Targets

| | Target |
|---|---|
| T1 | Top gear geared for ~400 km/h at peak power, so drag limits top speed, not the rev limiter |
| T2 | Close ratios: every upshift lands back inside the 3000–4300 power band |
| T3 | Standing start limited by traction, not by torque |

### T1 — final drive and top gear

```
2.64 final drive * 0.72 top gear = 1.9008

3900 rpm (peak power) -> 392 km/h
5200 rpm (limiter)    -> 522 km/h
```

Gearing the limiter well past the achievable speed is deliberate. A build that
bounces off the limiter in top has thrown away speed it could have had.

Estimated drag-limited terminal velocity, bobtail (no trailer), taking
Cd·A ≈ 4.0 m², Crr 0.006, m 7500 kg:

```
P = 0.5 * rho * CdA * v^3 + Crr * m * g * v
3 675 672 W  ->  v ~= 113.9 m/s = 410 km/h,  ~4090 rpm in top
```

which lands just past the 3900 rpm power peak. That is close to optimal
gearing. Treat 410 as an estimate: Cd·A is a guess and the game's own
aerodynamic model may not match it.

### T2 — the ladder

Single geometric progression, 4.20 to 0.72 across 10 gears:

```
r = (4.20 / 0.72) ^ (1/9) = 1.21647     spread 5.833
```

An upshift divides rpm by 1.216. From the 4300 rpm top of the band that lands
at 3536 — still inside it. That is the whole point of close ratios.

| Gear | Ratio | Overall | km/h @ 3900 | km/h @ 5200 | Step |
|-----:|------:|--------:|------------:|------------:|-----:|
| 1 | 4.20 | 11.09 | 67 | 90 | – |
| 2 | 3.45 | 9.11 | 82 | 109 | 1.217 |
| 3 | 2.84 | 7.50 | 99 | 132 | 1.215 |
| 4 | 2.33 | 6.15 | 121 | 161 | 1.219 |
| 5 | 1.92 | 5.07 | 147 | 196 | 1.214 |
| 6 | 1.58 | 4.17 | 178 | 238 | 1.215 |
| 7 | 1.30 | 3.43 | 217 | 289 | 1.215 |
| 8 | 1.07 | 2.82 | 264 | 351 | 1.215 |
| 9 | 0.88 | 2.32 | 320 | 427 | 1.216 |
| 10 | 0.72 | 1.90 | 392 | **522** | 1.222 |

`shift_time: 0.10` against the factory 0.7 s. Over nine upshifts that is
5.4 seconds of a standing-start run not spent coasting.

### T3 — launch

`stall_torque_ratio: 2.20` adds torque-converter multiplication at stall and
removes the dead spot a dry clutch has off the line.

```
F = 10000 Nm * 2.20 * 4.20 * 2.64 / 0.50625 m = 481 kN
```

On a ~7.5 t bobtail tractor that is roughly 6.5 g of demand — far past what
the tyres will hold. That is intended: the launch is traction-limited, so it
is chassis and throttle control that decide the run, not the engine.

Practical consequence: a **6x4 chassis drives two axles and launches far
better than the 6x2**, which drives only one. The engine cannot fix wheelspin.

### Retarder

Stopping is the genuine hazard this package creates. Kinetic energy at 410 km/h
is about 22 times that at 90 km/h. Staging is front-loaded rather than linear
so position 1 already does real work:

```
0.30, 0.55, 0.75, 0.90, 1.00 (+ engine brake)
```

Service brakes are defined on the chassis, not here, and are untouched. Leave
far more room than instinct suggests.

## Reproducing this

```powershell
$diff = 2.64; $gTop = 0.72; $g1 = 4.20; $n = 10
$r = [math]::Pow($g1/$gTop, 1.0/($n-1))
0..($n-1) | ForEach-Object {
    $g = [math]::Round($gTop * [math]::Pow($r, $n-1-$_), 2)
    "{0,2}  {1,6:N2}  {2,6:N0} km/h @ 3900" -f ($_+1), $g, (3900/(5.2397*$diff*$g))
}
```
