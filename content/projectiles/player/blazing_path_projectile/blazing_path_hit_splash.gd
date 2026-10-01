extends Node2D

const FLAME_SHADER_CODE: String = """
shader_type canvas_item;
render_mode blend_add;

uniform vec4 tint_color : hint_color = vec4(1.0, 0.18, 0.06, 1.0);
uniform vec4 core_color : hint_color = vec4(1.0, 0.65, 0.45, 1.0);

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    float lum = max(tex.r, max(tex.g, tex.b));
    float core = clamp((tex.r + tex.g + tex.b - 1.2) / 1.8, 0.0, 1.0);
    vec3 recolored = mix(tint_color.rgb * lum, core_color.rgb, core * core);
    COLOR = vec4(recolored * COLOR.rgb, tex.a * COLOR.a);
}
"""

const TIER_SPLASH_CONFIGS: Array = [
    {
        "tint": Color(1.0, 0.14, 0.05, 1.0),
        "core": Color(1.0, 0.62, 0.42, 1.0),
        "particle_colors": [
            Color(1.0, 0.75, 0.55, 1.0),
            Color(1.0, 0.22, 0.08, 0.8),
            Color(0.8, 0.05, 0.02, 0.0),
        ],
    },
    {
        "tint": Color(1.0, 0.84, 0.08, 1.0),
        "core": Color(1.0, 0.98, 0.72, 1.0),
        "particle_colors": [
            Color(1.0, 1.0, 0.85, 1.0),
            Color(1.0, 0.85, 0.15, 0.8),
            Color(0.85, 0.55, 0.02, 0.0),
        ],
    },
    {
        "tint": Color(0.94, 0.97, 1.0, 1.0),
        "core": Color(1.0, 1.0, 1.0, 1.0),
        "particle_colors": [
            Color(1.0, 1.0, 1.0, 1.0),
            Color(0.92, 0.96, 1.0, 0.8),
            Color(0.75, 0.82, 0.95, 0.0),
        ],
    },
    {
        "tint": Color(0.12, 0.52, 1.0, 1.0),
        "core": Color(0.72, 0.95, 1.0, 1.0),
        "particle_colors": [
            Color(0.82, 0.96, 1.0, 1.0),
            Color(0.20, 0.65, 1.0, 0.8),
            Color(0.05, 0.25, 0.88, 0.0),
        ],
    },
]

var _lifetime: float = 0.25
var _elapsed: float = 0.0
var _main: Node = null
var _pool_id: int = 0
var _opacity: float = 1.0
var _shader_mat: ShaderMaterial = null

onready var _sprite: Sprite = $Sprite
onready var _particles: CPUParticles2D = $CPUParticles2D

func _ready() -> void:
    var shader := Shader.new()
    shader.code = FLAME_SHADER_CODE
    _shader_mat = ShaderMaterial.new()
    _shader_mat.shader = shader
    _sprite.material = _shader_mat
    if _particles.color_ramp != null:
        _particles.color_ramp = _particles.color_ramp.duplicate()

func play(at_position: Vector2, main: Node, pool_id: int, tier_idx: int = 0) -> void:
    _main = main
    _pool_id = pool_id
    _opacity = FantasyProjectileVisualUtils.get_opacity()
    _elapsed = 0.0
    global_position = at_position
    visible = true

    var clamped_tier: int = int(clamp(tier_idx, 0, TIER_SPLASH_CONFIGS.size() - 1))
    var cfg: Dictionary = TIER_SPLASH_CONFIGS[clamped_tier]
    if _shader_mat != null:
        _shader_mat.set_shader_param("tint_color", cfg["tint"])
        _shader_mat.set_shader_param("core_color", cfg["core"])
    if _particles.color_ramp != null:
        var p_colors: Array = cfg["particle_colors"]
        for i in range(min(_particles.color_ramp.get_point_count(), p_colors.size())):
            _particles.color_ramp.set_color(i, p_colors[i])

    _sprite.rotation = 0.0
    _sprite.scale = Vector2.ONE * 0.8
    _sprite.modulate = Color(1.0, 1.0, 1.0, _opacity)
    _particles.modulate = Color(1.0, 1.0, 1.0, _opacity)
    _particles.emitting = true
    _particles.restart()

func _process(delta: float) -> void:
    _elapsed += delta
    var progress = clamp(_elapsed / _lifetime, 0.0, 1.0)

    _sprite.scale = Vector2.ONE * (0.8 + 1.2 * progress)
    _sprite.modulate.a = (1.0 - progress) * _opacity
    _sprite.rotation += 8.0 * delta

    if _elapsed >= _lifetime:
        visible = false
        _particles.emitting = false
        _main.add_node_to_pool(self, _pool_id)
