class_name WeaponData
extends Resource
## A weapon is a bundle of attack definitions. New weapon classes are added by
## creating a WeaponData .tres plus AttackData .tres files — no code changes.

@export var id: StringName = &""
@export var display_name := ""
@export_multiline var description := ""
@export var light_combo_start: AttackData
@export var heavy: AttackData
@export var aerial: AttackData
## Played when attacking an enemy that has been parried (riposte / execution).
@export var riposte: AttackData
## Multiplier on the riposte's damage for this weapon class.
@export var riposte_multiplier := 1.0
## How the weapon is drawn on the character (PresetData.WeaponLook).
@export var look := PresetData.WeaponLook.SWORD
## Held in two hands (cosmetic; shown on the equipment screen).
@export var two_handed := false
## Status buildup every hit with this weapon adds (StatusFx.KINDS; empty = none).
## Flat damage multiplier of this weapon (unique weapons hit harder than forged ones).
@export var damage_mult := 1.0

@export_group("Jutsu")
## This weapon's own technique (see Jutsu); used on the Art button in place of the equipped Art.
@export var jutsu: StringName = &""
@export var jutsu_cost := 40.0
@export_group("Skill and guard")
## The special move on the Skill button; costs [member skill_cost] focus.
@export var skill: AttackData
@export var skill_cost := 30.0
## Frames added to the parry window (negative = tighter) and to the whole parry motion.
@export var parry_window_bonus := 0
@export var parry_recovery_bonus := 0
## Above 0: holding Parry after the window keeps a guard up that cuts frontal damage by this
## fraction (0.75 = takes a quarter), draining stamina per blocked hit.
@export_range(0.0, 0.95) var block_reduction := 0.0
@export_group("Status")
@export var status: StringName = &""
@export var status_amount := 0.0
