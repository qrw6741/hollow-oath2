import os
"""Generates enemy / attack data (.tres) and enemy scenes (.tscn) for the newer enemies.
Edit the numbers here and re-run:  python3 tools/gen_enemy_data.py
(Older enemies - Penitent, Acolyte, Bell-Bearer, bosses - are hand-written .tres files.)"""
import os
R=os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
def attack(id_, name, anim, su, act, rec, dmg, kb, parry, hsize, hoff, lunge=0.0, lstart=0, lframes=0, track=True, hs=0.08, shake=3.0, amin=0, amax=40, w=1.0, nxt=None, chain=1.0, proj=0.0, pk=1.0):
    ext = '[ext_resource type="Script" path="res://systems/combat/attack_data.gd" id="1_attack"]'
    steps=2
    nl=""
    if nxt:
        ext += f'\n[ext_resource type="Resource" path="res://data/attacks/{nxt}.tres" id="2_next"]'
        steps=3
        nl='next_in_combo = ExtResource("2_next")\n'
    s=f'''[gd_resource type="Resource" script_class="AttackData" load_steps={steps} format=3]

{ext}

[resource]
script = ExtResource("1_attack")
id = &"{id_}"
display_name = "{name}"
animation = &"{anim}"
startup_frames = {su}
active_frames = {act}
recovery_frames = {rec}
chain_open_frame = -1
dodge_cancel_frame = -1
{nl}damage = {dmg:.1f}
poise_damage = 0.0
stamina_cost = 0.0
knockback = Vector2({kb[0]}, {kb[1]})
parryable = {"true" if parry else "false"}
hitbox_size = Vector2({hsize[0]}, {hsize[1]})
hitbox_offset = Vector2({hoff[0]}, {hoff[1]})
lunge_speed = {lunge:.1f}
lunge_start_frame = {lstart}
lunge_frames = {lframes}
track_during_startup = {"true" if track else "false"}
projectile_speed = {proj}
projectile_offset = Vector2(12, -20)
hit_stop = {hs}
shake = {shake}
ai_min_range = {amin}
ai_max_range = {amax}
ai_weight = {w}
ai_chain_chance = {chain}
'''
    open(f"{R}/data/attacks/{id_}.tres","w").write(s)

attack("moth_dive","Gloam Moth — Dive","dive",30,18,30,14,(90,-60),True,(22,20),(6,-8),amin=0,amax=160,hs=0.06,shake=2.0)
attack("oathguard_bash","Oathguard — Shield Bash","bash",20,5,26,18,(140,-40),True,(30,34),(18,-20),lunge=90,lstart=16,lframes=6,amin=0,amax=40)
attack("oathguard_thrust","Oathguard — Spear Thrust","thrust",28,5,30,24,(110,-20),True,(52,10),(36,-22),lunge=60,lstart=24,lframes=6,amin=30,amax=70,w=1.2)
attack("mimic_bite_2","Mimic — Second Bite","bite",12,5,30,22,(100,-60),True,(30,24),(18,-12),amin=0,amax=0,w=0.0)
attack("mimic_bite","Mimic — Bite","bite",18,5,10,22,(100,-60),True,(30,24),(18,-12),amin=0,amax=36,nxt="mimic_bite_2",chain=0.6)
attack("mimic_ambush","Mimic — Ambush","bite",12,6,34,30,(160,-120),False,(36,28),(16,-12),track=False,amin=0,amax=0,w=0.0,hs=0.1,shake=5.0)
attack("mimic_pounce","Mimic — Pounce","pounce",30,10,36,30,(150,-90),False,(30,26),(14,-12),lunge=210,lstart=28,lframes=12,amin=50,amax=120,w=0.8,hs=0.1,shake=5.0)

# Crafting materials (see systems/forge.gd): id -> (item, chance, count). Older enemies are patched in their .tres.
BONUS={'gloam_moth':('hollow_resin',0.25,1),'oathguard':('forge_scrap',0.30,1),'mimic':('forge_scrap',1.0,3),
 'carrion_crow':('hollow_resin',0.25,1),'roadside_pikeman':('forge_scrap',0.30,1),'hollow_marshal':('forge_scrap',1.0,6)}

def enemy(id_, name, lore, atks, hp, poise, patrol, chase, det, vdet, cdmin, cdmax, recover, backstep, stagger, pstag, embers, drop=None, dchance=0.0, dcount=1, leash=320):
    ext=['[ext_resource type="Script" path="res://actors/enemies/enemy_data.gd" id="1_enemy"]']
    for i,a in enumerate(atks):
        ext.append(f'[ext_resource type="Resource" path="res://data/attacks/{a}.tres" id="a{i}"]')
    if drop: ext.append(f'[ext_resource type="Resource" path="res://data/items/{drop}.tres" id="drop"]')
    bonus=BONUS.get(id_)
    if bonus: ext.append(f'[ext_resource type="Resource" path="res://data/items/{bonus[0]}.tres" id="bonus"]')
    arr=", ".join(f'ExtResource("a{i}")' for i in range(len(atks)))
    s=f'''[gd_resource type="Resource" script_class="EnemyData" load_steps={len(ext)+1} format=3]

{chr(10).join(ext)}

[resource]
script = ExtResource("1_enemy")
id = &"{id_}"
display_name = "{name}"
lore = "{lore}"
max_health = {hp:.1f}
max_poise = {poise:.1f}
poise_regen_delay_frames = 90
poise_regen_per_second = 30.0
patrol_speed = {patrol:.1f}
chase_speed = {chase:.1f}
detection_range = {det:.1f}
vertical_detection = {vdet:.1f}
leash_range = {leash:.1f}
attacks = [{arr}]
attack_cooldown_min = {cdmin}
attack_cooldown_max = {cdmax}
recover_frames = {recover}
backstep_speed = {backstep:.1f}
stagger_frames = {stagger}
parry_stagger_frames = {pstag}
ember_reward = {embers}
''' + (f'drop_item = ExtResource("drop")\ndrop_chance = {dchance}\ndrop_count = {dcount}\n' if drop else "") + (f'bonus_drop_item = ExtResource("bonus")\nbonus_drop_chance = {bonus[1]}\nbonus_drop_count = {bonus[2]}\n' if bonus else "")
    open(f"{R}/data/enemies/{id_}.tres","w").write(s)

enemy("gloam_moth","Gloam Moth","Moths that drank from the candles after the Unbinding. They still circle anything that burns.",["moth_dive"],40,20,30,85,170,150,50,110,46,0,40,110,35)
enemy("oathguard","Oathguard","Sworn shields of the Vaelmoor road. Their oath was to hold the line; no one told them the line was gone.",["oathguard_bash","oathguard_thrust"],130,90,24,52,170,60,40,80,26,50,50,110,140,"ember_shard",0.2)
enemy("mimic","Mimic","A strongbox that learned to wait. Greed is the bait it never runs out of.",["mimic_bite","mimic_pounce","mimic_ambush"],210,70,0,62,200,60,40,80,30,40,50,110,400,"ember_shard",1.0,3)

def scene(name, script, data, visual, body, bpos, hurt, hpos, gravity=None, extra=""):
    s=f'''[gd_scene load_steps=11 format=3]

[ext_resource type="Script" path="res://actors/enemies/{script}.gd" id="1_enemy"]
[ext_resource type="Resource" path="res://data/enemies/{data}.tres" id="2_data"]
[ext_resource type="Script" path="res://systems/combat/health_component.gd" id="3_health"]
[ext_resource type="Script" path="res://systems/combat/hurtbox.gd" id="4_hurtbox"]
[ext_resource type="Script" path="res://systems/combat/hitbox.gd" id="5_hitbox"]
[ext_resource type="Script" path="res://systems/combat/attack_runner.gd" id="6_runner"]
[ext_resource type="Script" path="res://actors/enemies/{visual}.gd" id="7_visual"]

[sub_resource type="RectangleShape2D" id="body_shape"]
size = Vector2({body[0]}, {body[1]})

[sub_resource type="RectangleShape2D" id="hurt_shape"]
size = Vector2({hurt[0]}, {hurt[1]})

[sub_resource type="RectangleShape2D" id="hit_shape"]
size = Vector2(30, 30)

[node name="{name}" type="CharacterBody2D"]
collision_layer = 4
collision_mask = 1
floor_snap_length = 3.0
script = ExtResource("1_enemy")
data = ExtResource("2_data")
{extra}
[node name="Body" type="CollisionShape2D" parent="."]
position = Vector2({bpos[0]}, {bpos[1]})
shape = SubResource("body_shape")

[node name="Health" type="Node" parent="."]
script = ExtResource("3_health")

[node name="Hurtbox" type="Area2D" parent="."]
collision_layer = 16
collision_mask = 0
script = ExtResource("4_hurtbox")

[node name="Shape" type="CollisionShape2D" parent="Hurtbox"]
position = Vector2({hpos[0]}, {hpos[1]})
shape = SubResource("hurt_shape")

[node name="Hitbox" type="Area2D" parent="."]
collision_layer = 0
collision_mask = 8
script = ExtResource("5_hitbox")

[node name="Shape" type="CollisionShape2D" parent="Hitbox"]
position = Vector2(18, -14)
shape = SubResource("hit_shape")

[node name="AttackRunner" type="Node" parent="." node_paths=PackedStringArray("hitbox")]
script = ExtResource("6_runner")
hitbox = NodePath("../Hitbox")

[node name="Visual" type="Node2D" parent="."]
script = ExtResource("7_visual")
'''
    open(f"{R}/actors/enemies/{data}.tscn","w").write(s)

scene("GloamMoth","flying_enemy","gloam_moth","moth_visual",(14,12),(0,-8),(20,16),(0,-8))
scene("Oathguard","shield_enemy","oathguard","oathguard_visual",(16,34),(0,-17),(18,36),(0,-18))
scene("Mimic","mimic","mimic","mimic_visual",(24,18),(0,-9),(26,20),(0,-10))

# ------------------------------------------------------------------ the Vaelmoor road
attack("crow_dive","Carrion Crow — Dive","dive",26,14,24,12,(80,-50),True,(16,14),(6,-6),amin=0,amax=150,hs=0.05,shake=1.5)
attack("pike_thrust","Roadside Pikeman — Pike Thrust","thrust",24,5,26,20,(130,-40),True,(56,10),(38,-22),lunge=40,lstart=20,lframes=5,amin=30,amax=80)
attack("pike_trip","Roadside Pikeman — Low Sweep","sweep",30,6,30,14,(90,-120),False,(60,8),(36,-6),amin=0,amax=70,w=0.7)
attack("marshal_thrust","Hollow Marshal — Lance Thrust","thrust",26,6,30,22,(150,-40),True,(70,12),(48,-26),lunge=80,lstart=22,lframes=6,amin=40,amax=110,w=1.2,hs=0.09,shake=4.0)
attack("marshal_sweep","Hollow Marshal — Lance Sweep","sweep",30,8,32,26,(180,-60),True,(84,34),(30,-22),amin=0,amax=70,hs=0.09,shake=4.0)
attack("marshal_charge","Hollow Marshal — Couched Charge","charge",34,24,36,30,(230,-100),False,(34,44),(20,-24),lunge=280,lstart=34,lframes=24,amin=100,amax=260,hs=0.1,shake=6.0)
attack("marshal_vault","Hollow Marshal — Pole Vault","leap",54,6,38,32,(190,-150),False,(110,28),(0,-12),track=False,amin=90,amax=280,w=1.2,hs=0.12,shake=8.0)
attack("marshal_banner","Hollow Marshal — Raise the Banner","banner",40,4,40,1,(0,0),False,(2,2),(0,-200),track=False,amin=120,amax=420,w=0.7,proj=1.0,hs=0.0,shake=0.0)
enemy("carrion_crow","Carrion Crow","They follow the road for what falls on it. Lately, that has been the sworn.",["crow_dive"],32,15,36,95,190,160,50,110,40,0,30,100,30,leash=360)
enemy("roadside_pikeman","Roadside Pikeman","A conscript of the road watch. The pike was issued; the courage, he was told, would follow.",["pike_thrust","pike_trip"],90,45,26,58,190,60,40,80,26,50,40,100,60,"ash_bandage",0.25)
enemy("hollow_marshal","Sir Orren, the Hollow Marshal","Marshal of the Crown's road. He swore to hold the crossroads against anything that came, and has held it against everything since.",["marshal_thrust","marshal_sweep","marshal_charge"],900,100,30,56,800,300,40,80,28,50,55,120,3200,"marshals_crest",1.0,1,leash=99999)
scene("CarrionCrow","flying_enemy","carrion_crow","crow_visual",(12,10),(0,-6),(18,14),(0,-6))
scene("RoadsidePikeman","enemy_base","roadside_pikeman","pikeman_visual",(14,32),(0,-16),(16,34),(0,-17))
print("ok")
