shader_type canvas_item;
render_mode unshaded;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    float filament = pow(max(0.0, 1.0 - abs(UV.y - 0.5) * 2.0), 3.0);
    float pulse = 0.7 + 0.3 * sin(UV.x * 34.0 - TIME * 13.0);
    vec3 violet = mix(vec3(0.32, 0.12, 0.49), vec3(0.82, 0.49, 1.0), filament);
    violet = mix(violet, vec3(1.0, 0.82, 1.0), filament * pulse * 0.65);
    COLOR = vec4(violet, tex.a) * COLOR;
}
