shader_type canvas_item;
render_mode unshaded, blend_add;

void fragment() {
    float along = clamp(UV.x, 0.0, 1.0);
    float envelope = smoothstep(0.0, 0.045, along) * pow(1.0 - along, 0.8);
    float sway = sin(along * 11.0 - TIME * 5.0) * 0.09 * along;
    float center = UV.y - 0.5 - sway;
    float core = exp(-center * center * 90.0);
    float haze = exp(-center * center * 18.0) * 0.4;
    float wisp_offset = center + sin(along * 16.0 + TIME * 3.0) * 0.18;
    float wisp = exp(-wisp_offset * wisp_offset * 250.0) * along * 0.35;
    float edge = 1.0 - smoothstep(0.28, 0.49, abs(UV.y - 0.5));
    float alpha = min(1.0, core * 0.85 + haze + wisp) * envelope * edge;
    vec3 violet = mix(vec3(0.52, 0.22, 0.88), vec3(1.0, 0.86, 1.0), core);
    COLOR = vec4(violet, alpha) * COLOR;
}
