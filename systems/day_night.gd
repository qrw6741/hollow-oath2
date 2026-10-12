class_name DayNight
extends RefCounted
## The road's slow turn from daylight to dusk to night and back, driven by play time (so it
## survives saves without a new field). Outdoor levels with a DayNightCycle node follow it;
## spawners marked "night only" or "day only" appear and vanish with it.
##
## One cycle = CYCLE seconds:  day 0-45%, dusk 45-58%, night 58-92%, dawn 92-100%.

const CYCLE := 840.0
const START := 0.05            ## a new game begins early in the morning
const DUSK_AT := 0.45
const NIGHT_AT := 0.58
const DAWN_AT := 0.92
const NIGHT_THRESHOLD := 0.6

## Tests and tools can pin the time (0..1); -1 = follow play time.
static var forced := -1.0

enum Phase { DAY, DUSK, NIGHT, DAWN }


## Position in the cycle, 0..1.
static func time() -> float:
	if forced >= 0.0:
		return forced
	return fposmod(GameState.play_time / CYCLE + START, 1.0)


static func phase(t := -1.0) -> int:
	if t < 0.0:
		t = time()
	if t < DUSK_AT:
		return Phase.DAY
	if t < NIGHT_AT:
		return Phase.DUSK
	if t < DAWN_AT:
		return Phase.NIGHT
	return Phase.DAWN


static func phase_name(p: int) -> String:
	return ["Daylight", "Dusk", "Night", "Dawn"][p]


## 0 = full daylight, 1 = full night.
static func darkness(t := -1.0) -> float:
	if t < 0.0:
		t = time()
	if t < DUSK_AT:
		return 0.0
	if t < NIGHT_AT:
		return smoothstep(DUSK_AT, NIGHT_AT, t)
	if t < DAWN_AT:
		return 1.0
	return 1.0 - smoothstep(DAWN_AT, 1.0, t)


static func is_night() -> bool:
	return darkness() >= NIGHT_THRESHOLD


## Colour for the level's CanvasModulate.
static func tint(d := -1.0) -> Color:
	if d < 0.0:
		d = darkness()
	var day := Color(1.0, 0.98, 0.94)
	var dusk := Color(1.0, 0.7, 0.55)
	var night := Color(0.38, 0.44, 0.7)
	return day.lerp(dusk, clampf(d * 2.0, 0.0, 1.0)).lerp(night, clampf(d * 2.0 - 1.0, 0.0, 1.0))
