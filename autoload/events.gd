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
signal checkpoint_rested(checkpoint_id: StringName, respawn_position: Vector2)
signal enemy_killed(enemy: Node2D)

# --- Interaction / UI ---
signal interact_prompt_shown(text: String)
signal interact_prompt_hidden
signal banner_requested(text: String)

# --- Combat feel ---
signal screen_shake_requested(strength: float, duration: float)
