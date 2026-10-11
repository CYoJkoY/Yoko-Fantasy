shader_type canvas_item;
render_mode unshaded, blend_add;

uniform float age = 0.0;
uniform float cursed : hint_range(0.0, 1.0) = 0.0;
uniform float strength = 0.0;

void fragment() {
    vec4 tint = COLOR;
    float h = 1.0 - UV.y;
    float phase = h * 10.0 - age * 13.0;
    float radius = (0.37 - h * 0.23);
    float center = 0.5 + sin(phase) * radius;
    float width = 0.006 + (1.0 - h) * 0.008;
    float strand = exp(-pow((UV.x - center) / width, 2.0));
    float mist = exp(-pow((UV.x - center) / (width * 3.5), 2.0)) * 0.15;
    float tip = 1.0 - smoothstep(age * 3.0 - 0.08, age * 3.0 + 0.16, h);
    float ends = smoothstep(0.0, 0.10, h) * (1.0 - smoothstep(0.7, 0.98, h));
    float facing = 0.38 + 0.62 * (0.5 + 0.5 * cos(phase));
    vec3 blood = mix(vec3(0.65, 0.045, 0.80), vec3(1.0, 0.20, 0.30), facing);
    blood = mix(blood, vec3(blood.r * 0.76 + blood.b * 0.24, blood.g * 0.75, blood.r), cursed);
    COLOR = vec4(blood * tint.rgb, (strand + mist) * ends * tip * facing * strength * tint.a);
}
