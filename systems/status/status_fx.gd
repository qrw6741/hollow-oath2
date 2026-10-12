class_name StatusFx
extends RefCounted
## Status effects: bleed, poison, burning and frost. Hits carry a *buildup* amount; when an
## actor's buildup for a kind reaches 100 the effect triggers (see StatusComponent). Armour
## and enemies resist kinds by a fraction (0.3 = 30% less buildup, 1.0 = immune, negative =
## weak). Bosses are immune by design: they never get a StatusComponent.

const BLEED := &"bleed"
const POISON := &"poison"
const BURN := &"burn"
const FROST := &"frost"
const KINDS: Array[StringName] = [BLEED, POISON, BURN, FROST]

const NAMES := {BLEED: "Bleed", POISON: "Poison", BURN: "Burning", FROST: "Frost"}
const COLORS := {
	BLEED: Color("c0222e"), POISON: Color("7bb04a"), BURN: Color("f08a2a"), FROST: Color("8ed0ee"),
}
const BLURBS := {
	BLEED: "Bursts for a share of health once the wound opens.",
	POISON: "Slow damage over ten seconds.",
	BURN: "Fierce damage over six seconds.",
	FROST: "Slows movement for five seconds.",
}
## Share of max health lost: bleed once; poison and burn per second while active.
const BLEED_BURST := 0.16
const POISON_PER_SEC := 0.02
const BURN_PER_SEC := 0.04
const FROST_SLOW := 0.62
const DURATIONS := {BLEED: 2.0, POISON: 10.0, BURN: 6.0, FROST: 5.0}
const THRESHOLD := 100.0
const MIN_RESIST := -0.5
const MAX_RESIST := 1.0


static func is_kind(k: StringName) -> bool:
	return KINDS.has(k)


static func name_of(k: StringName) -> String:
	return String(NAMES.get(k, String(k)))


## "Bleed 40%, Frost 20%" for UI; empty if none.
static func resist_text(r: Dictionary) -> String:
	var parts := PackedStringArray()
	for k in KINDS:
		var v := float(r.get(String(k), r.get(k, 0.0)))
		if absf(v) > 0.001:
			parts.append("%s %s%d%%" % [name_of(k), "" if v >= 0.0 else "-", roundi(absf(v) * 100.0)] if v < 1.0 else "%s immune" % name_of(k))
	return ", ".join(parts)


## Total of a resist dictionary lookup (string or StringName keys).
static func lookup(r: Dictionary, k: StringName) -> float:
	return clampf(float(r.get(String(k), r.get(k, 0.0))), MIN_RESIST, MAX_RESIST)
