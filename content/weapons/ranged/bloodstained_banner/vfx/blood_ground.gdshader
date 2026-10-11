shader_type canvas_item;
render_mode unshaded, blend_add;

uniform float age = 0.0;
uniform float cursed : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec4 tint = COLOR;
    vec2 p = UV - vec2(0.5);
    float radius = length(p) * 2.0;
    float angle = atan(p.y, p.x);
    float ripple = sin(radius * 24.0 - age * 17.0 + angle * 3.0);
    vec2 uv = UV + p * ripple * 0.004;
    float mask = texture(TEXTURE, uv).a;
    float birth = smoothstep(0.0, 0.04, age);
    float spread = 1.0 - smoothstep(age * 11.0, age * 11.0 + 0.26, radius);
    float grain = 0.5 + 0.25 * sin(angle * 5.0 + radius * 17.0) + 0.18 * sin(angle * 11.0 - radius * 9.0);
    float erosion = smoothstep(0.38, 0.86, age);
    float dissolve = 1.0 - smoothstep(grain - 0.14, grain + 0.22, erosion);
    float sweep = pow(0.5 + 0.5 * cos(angle * 3.0 - age * 19.0 + radius * 7.0), 7.0);
    float wave = exp(-pow((radius - age * 4.5) * 12.0, 2.0));
    vec3 blood = mix(vec3(0.86, 0.025, 0.12), vec3(1.0, 0.31, 0.34), sweep * 0.75 + wave * 0.25);
    float flow = 0.65 + sweep * 0.45 + wave * 0.30;
    blood = mix(blood, vec3(blood.r * 0.76 + blood.b * 0.24, blood.g * 0.75, blood.r), cursed);
    COLOR = vec4(blood * tint.rgb, mask * tint.a * birth * spread * dissolve * flow);
}
