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
