class_name FantasyProjectileVisualUtils


static func get_opacity() -> float:
    if ProgressData == null or not is_instance_valid(ProgressData):
        return 1.0
    var settings = ProgressData.settings
    if settings == null:
        return 1.0
    if not ("projectile_opacity" in settings):
        return 1.0
    return clamp(float(settings.projectile_opacity), 0.0, 1.0)
