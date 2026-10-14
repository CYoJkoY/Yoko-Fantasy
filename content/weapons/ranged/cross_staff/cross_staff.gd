extends "res://mods-unpacked/Yoko-Fantasy/content/weapons/ranged/shared/orbit_strike_weapon.gd"

const CAST_VFX_DURATION: float = 0.36

const TIER_COLORS = [
    {
        "halo": Color(1.0, 0.95, 0.78, 0.70),
        "corona": Color(1.0, 0.95, 0.80, 0.55),
        "flare": Color(1.0, 0.98, 0.90, 0.45),
        "strike": Color(1.0, 0.96, 0.85, 1.0)
    },
    {
        "halo": Color(0.84, 0.96, 1.0, 0.72),
        "corona": Color(0.82, 0.95, 1.0, 0.58),
        "flare": Color(0.90, 0.98, 1.0, 0.48),
        "strike": Color(0.86, 0.96, 1.0, 1.0)
    },
    {
        "halo": Color(0.95, 0.86, 1.0, 0.74),
        "corona": Color(0.92, 0.84, 1.0, 0.60),
        "flare": Color(0.96, 0.90, 1.0, 0.50),
        "strike": Color(0.95, 0.88, 1.0, 1.0)
    },
    {
        "halo": Color(1.0, 0.88, 0.70, 0.78),
        "corona": Color(1.0, 0.90, 0.72, 0.62),
        "flare": Color(1.0, 0.94, 0.80, 0.52),
        "strike": Color(1.0, 0.88, 0.72, 1.0)
    }
]

const CURSED_COLORS = {
    "halo": Color(0.72, 0.30, 1.0, 0.78),
    "corona": Color(0.66, 0.22, 1.0, 0.66),
    "flare": Color(0.90, 0.62, 1.0, 0.56),
    "strike": Color(0.80, 0.42, 1.0, 1.0)
}

onready var _staff_halo: Sprite = $Sprite/StaffEffects/StaffHalo
onready var _sun_corona: Sprite = $Sprite/StaffEffects/SunCoronaRing
onready var _cast_flare: Sprite = $Sprite/StaffEffects/CastFlare
onready var _cast_particles: CPUParticles2D = $Sprite/StaffEffects/CastParticles

var _cast_vfx_elapsed: float = 1.0


func _ready() -> void:
    var cfg: Dictionary = _get_tier_color_config()

    if is_cursed:
        var cursed_ramp: Gradient = _cast_particles.color_ramp.duplicate()
        cursed_ramp.colors = PoolColorArray([
            Color(0.94, 0.80, 1.0, 0.0), Color(0.85, 0.55, 1.0, 0.6),
            Color(0.62, 0.22, 1.0, 0.4), Color(0.40, 0.10, 0.80, 0.0)
        ])
        _cast_particles.color_ramp = cursed_ramp

    if _sun_corona != null:
        _sun_corona.visible = false
        _sun_corona.modulate.a = 0.0

    if _cast_flare != null:
        _cast_flare.visible = false
        _cast_flare.modulate.a = 0.0

    if _staff_halo != null:
        _staff_halo.visible = true
        _staff_halo.modulate = cfg.halo


func _get_tier_color_config() -> Dictionary:
    if is_cursed:
        return CURSED_COLORS
    var t: int = 0
    if "tier" in self and tier is int:
        t = tier
    elif current_stats != null and "tier" in current_stats:
        t = current_stats.tier
    t = int(clamp(t, 0, 3))
    return TIER_COLORS[t]


func _update_visual_effects(delta: float) -> void:
    var cfg: Dictionary = _get_tier_color_config()

    if is_instance_valid(_staff_halo):
        _staff_halo.rotation += delta * 0.8
        var halo_pulse: float = (cfg.halo.a * 0.90) + sin(_time * 2.4) * (cfg.halo.a * 0.22)
        _staff_halo.modulate = Color(cfg.halo.r, cfg.halo.g, cfg.halo.b, halo_pulse)
        _staff_halo.scale = Vector2.ONE * (0.48 + sin(_time * 2.0) * 0.05)

    if _cast_vfx_elapsed < CAST_VFX_DURATION:
        _cast_vfx_elapsed += delta
        var progress: float = clamp(_cast_vfx_elapsed / CAST_VFX_DURATION, 0.0, 1.0)
        var ease_out: float = sin(progress * PI * 0.5)
        var fade_alpha: float = (1.0 - progress) * (1.0 - progress)

        if is_instance_valid(_sun_corona):
            _sun_corona.scale = Vector2.ONE * lerp(0.15, 0.62, ease_out)
            _sun_corona.modulate = Color(cfg.corona.r, cfg.corona.g, cfg.corona.b, cfg.corona.a * fade_alpha)
            _sun_corona.rotation += delta * 1.2
            if progress >= 1.0:
                _sun_corona.visible = false

        if is_instance_valid(_cast_flare):
            _cast_flare.scale = Vector2.ONE * lerp(0.16, 0.35, ease_out)
            _cast_flare.modulate = Color(cfg.flare.r, cfg.flare.g, cfg.flare.b, cfg.flare.a * fade_alpha)
            _cast_flare.rotation += delta * 2.0
            if progress >= 1.0:
                _cast_flare.visible = false


func _start_cast_effects() -> void:
    _cast_vfx_elapsed = 0.0

    var cfg: Dictionary = _get_tier_color_config()

    if is_instance_valid(_sun_corona):
        _sun_corona.visible = true
        _sun_corona.scale = Vector2.ONE * 0.15
        _sun_corona.modulate = cfg.corona
        _sun_corona.rotation = randf() * TAU

    if is_instance_valid(_cast_flare):
        _cast_flare.visible = true
        _cast_flare.scale = Vector2.ONE * 0.16
        _cast_flare.modulate = cfg.flare
        _cast_flare.rotation = randf() * TAU

    if is_instance_valid(_cast_particles):
        _cast_particles.restart()
        _cast_particles.emitting = true


func _get_strike_tint() -> Color:
    return _get_tier_color_config().strike
