extends Resource

export(float) var target_refresh_ticks = 5.0

export(float) var guard_radius = 100.0
export(float) var guard_orbit_speed = 3.4
export(float) var guard_speed = 980.0
export(float) var return_speed = 1280.0
export(float) var return_curve_distance = 88.0

export(float) var aim_ticks = 3.0
export(float) var windup_ticks = 3.0
export(float) var slash_ticks = 6.0
export(float) var chain_ticks = 2.0
export(float) var approach_distance = 72.0
export(float) var exit_distance = 86.0
export(float) var curve_side_distance = 84.0
export(float) var aim_snap_distance = 170.0
export(float) var sweep_width = 34.0
export(int) var max_chain_hits = 3
export(float) var chain_search_radius = 220.0

export(float) var arc_radius = 64.0
export(Color) var slash_color = Color("#d7b2ff")
export(Color) var trail_color = Color("#8a70ff")
export(Color) var trail_secondary_color = Color(0.52, 0.86, 1.0, 0.18)
export(Color) var trail_core_color = Color(0.92, 0.96, 1.0, 0.42)
export(Color) var satellite_trail_color = Color(0.58, 0.34, 1.0, 0.20)
export(Color) var satellite_trail_secondary_color = Color(0.42, 0.86, 1.0, 0.14)
export(Color) var attack_fragment_color = Color(0.68, 0.38, 1.0, 0.30)
export(Color) var attack_fragment_secondary_color = Color(0.42, 0.86, 1.0, 0.22)
export(float) var slash_width = 6.0
export(float) var trail_width = 5.0
export(float) var trail_aura_width = 10.0
export(float) var trail_core_width = 2.0
export(int) var trail_max_points = 7
export(float) var trail_sample_min_distance = 10.0
export(float) var attack_fragment_lifetime = 0.18
export(float) var attack_fragment_interval_ticks = 0.50
export(float) var attack_fragment_width = 2.0
export(float) var blade_afterimage_lifetime = 0.14
export(float) var blade_afterimage_alpha = 0.32
export(float) var blade_afterimage_min_distance = 22.0
export(float) var guard_breathe_scale = 0.045
export(float) var guard_wave_height = 30.0
export(float) var guard_wave_speed = 2.0
export(float) var guard_tilt_strength = 0.22
export(float) var hit_flash_alpha = 0.42

export(float) var satellite_attack_range = 200.0
export(float) var satellite_attack_cooldown_ticks = 90.0
export(float) var satellite_attack_ticks = 8.0
export(float) var satellite_return_ticks = 10.0
export(float) var satellite_attack_distance = 34.0
export(float) var satellite_hitbox_length = 82.0
export(float) var satellite_hitbox_width = 20.0
export(float) var satellite_knockback = 5.0
export(float) var satellite_guard_orbit_width = 2.5
export(float) var satellite_guard_orbit_core_width = 0.8
export(float) var satellite_guard_orbit_segment_width = 6.6

export(float) var target_angle_weight = 0.10
export(float) var target_origin_weight = 0.60
export(float) var target_player_weight = 0.18
export(float) var target_follow_through_weight = 0.08

# Set an active limit only for explicit balance overrides; zero uses all ready blades.
export(int) var max_active_main_attacks = 0
export(int) var max_active_satellite_attacks = 0
export(int) var max_attack_dispatches_per_tick = 2

# Visual budgets never change combat concurrency or hitbox processing.
export(int) var full_visual_count = 4
export(int) var reduced_visual_count = 8
export(int) var minimal_visual_count = 16
export(int) var crowded_reduced_visual_slots = 3
export(int) var crowded_minimal_visual_slots = 3
export(int) var satellite_idle_visible_count = 8
