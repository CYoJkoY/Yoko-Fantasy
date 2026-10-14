shader_type canvas_item;
render_mode unshaded, blend_add;

uniform float age = 0.0;
uniform float cursed : hint_range(0.0, 1.0) = 0.0;
uniform float energy = 0.0;

void fragment() {
    vec4 tint = COLOR;
    vec2 p = UV - vec2(0.5);
    float radius = length(p) * 2.0;
    float angle = atan(p.y, p.x);
    float ripple = sin(angle * 3.0 - age * 3.2) * 0.055 + sin(angle * 5.0 + age * 1.9) * 0.020;
    vec2 uv = UV + p * ripple;
    float mask = texture(TEXTURE, uv).a;
    float gleam = pow(0.5 + 0.5 * sin(angle * 2.0 - age * 4.0 + radius * 3.0), 3.0);
    vec3 blood = mix(vec3(0.78, 0.025, 0.17), vec3(1.0, 0.32, 0.36), gleam * (0.4 + energy * 0.5));
    blood = mix(blood, vec3(blood.r * 0.76 + blood.b * 0.24, blood.g * 0.75, blood.r), cursed);
    COLOR = vec4(blood * tint.rgb, mask * tint.a * (0.55 + gleam * 0.45));
}
