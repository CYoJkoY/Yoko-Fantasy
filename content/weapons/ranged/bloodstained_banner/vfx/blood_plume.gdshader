shader_type canvas_item;
render_mode unshaded, blend_add;

uniform float rise : hint_range(0.0, 1.0) = 0.0;
uniform float age = 0.0;
uniform float cursed : hint_range(0.0, 1.0) = 0.0;
uniform float strength : hint_range(0.0, 1.0) = 1.0;
uniform float accent : hint_range(0.0, 1.0) = 0.0;
uniform float foot_uv : hint_range(0.5, 1.0) = 1.0;

void fragment() {
    vec4 tint = COLOR;
    float height = max(0.0, 1.0 - UV.y / foot_uv);
    float sway = (sin(height * 13.0 - age * 18.0) * 0.024 + sin(height * 27.0 - age * 11.0) * 0.010) * height;
    vec2 uv = vec2(UV.x + sway, UV.y);
    float mask = texture(TEXTURE, uv).a;
    float tip = 1.0 - smoothstep(rise - 0.15, rise + 0.03, height);
    float flow = 0.78 + 0.22 * sin(height * 32.0 - age * 40.0 + UV.x * 13.0);
    float vein = pow(0.5 + 0.5 * sin(UV.x * 51.0 + height * 13.0 - age * 15.0), 5.0);
    float core = pow(mask, 2.5);
    vec3 blood = mix(vec3(0.48, 0.015, 0.72), vec3(1.0, 0.025, 0.075), smoothstep(0.03, 0.38, mask));
    blood = mix(blood, vec3(1.0, 0.55, 0.46), core * (0.52 + vein * 0.38));
    blood = mix(blood, mix(vec3(0.52, 0.035, 0.82), vec3(1.0, 0.10, 0.30), mask), accent);
    blood = mix(blood, vec3(blood.r * 0.76 + blood.b * 0.24, blood.g * 0.75, blood.r), cursed);
    COLOR = vec4(blood * tint.rgb, mask * tip * flow * strength * tint.a);
}
