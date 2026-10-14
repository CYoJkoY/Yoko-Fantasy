shader_type canvas_item;
render_mode unshaded, blend_add;

uniform float age = 0.0;
uniform float cursed : hint_range(0.0, 1.0) = 0.0;
uniform float energy = 0.0;

void fragment() {
    vec4 tint = COLOR;
    float mask = texture(TEXTURE, UV).a;
    float wave = pow(0.5 + 0.5 * sin(UV.x * 11.0 - UV.y * 7.0 + age * 4.6), 4.0);
    float pulse = 0.09 + wave * 0.43 + energy * (0.18 + wave * 0.42);
    vec3 blood = mix(vec3(0.78, 0.015, 0.045), vec3(1.0, 0.28, 0.25), wave * energy);
    blood = mix(blood, vec3(blood.r * 0.76 + blood.b * 0.24, blood.g * 0.75, blood.r), cursed);
    COLOR = vec4(blood * tint.rgb, mask * tint.a * pulse);
}
