extends Node
## Global signal bus. Independent systems talk through these signals so that
## no system needs a hard reference to another (HUD <-> Player, Level <-> GameState...).

# --- Player lifecycle ---
signal player_spawned(player: Node2D)
signal player_died
signal respawn_requested
signal player_respawned(player: Node2D)
signal flasks_changed(current: int, maximum: int)

# --- Session / menus ---
signal new_game_requested(slot: int, preset_id: StringName)
signal load_game_requested(slot: int)
signal quit_to_menu_requested
signal session_started
signal game_saved(slot: int)
signal save_failed(slot: int, reason: String)

# --- World ---
## A level exit (or a respawn at a candle in another level) wants a different level.
signal level_change_requested(level_path: String, entry_id: StringName, respawn: bool)
signal level_entered(level_path: String)
## The ending of the prologue: walk into the light -> white fade -> another world.
signal teleport_requested(level_path: String, entry_id: StringName)
## Readable signs / tablets.
signal message_requested(title: String, text: String)
signal message_closed
signal checkpoint_rested(checkpoint_id: StringName, respawn_position: Vector2)
signal enemy_killed(enemy: Node2D)

# --- Bosses ---
signal boss_fight_started(boss: Node)
signal boss_phase_changed(boss: Node, phase: int)
## victory = false when the player died or the fight was reset.
signal boss_fight_ended(victory: bool)
signal boss_defeated(boss_id: StringName)

# --- Economy / inventory ---
signal embers_changed(total: int)
signal embers_gained(amount: int)
signal ember_drop_changed
signal inventory_changed
signal item_picked(item_id: StringName, count: int)
signal item_used(item_id: StringName)
signal stats_changed
signal inventory_menu_requested
signal inventory_menu_closed
signal map_requested
signal map_closed

# --- Dialogue & shops ---
## [param lines]: Strings, or {"who": speaker, "text": line} to switch speaker mid-conversation.
signal dialogue_requested(speaker: String, lines: Array)
signal dialogue_closed
signal shop_requested(shop_id: StringName)
signal shop_closed

# --- Interaction / UI ---
signal interact_prompt_shown(text: String)
signal interact_prompt_hidden
signal banner_requested(text: String)

# --- Combat feel ---
signal screen_shake_requested(strength: float, duration: float)
