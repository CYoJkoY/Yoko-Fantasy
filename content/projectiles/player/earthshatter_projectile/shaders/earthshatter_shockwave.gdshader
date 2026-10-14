shader_type canvas_item;
render_mode unshaded;

uniform float ring_width = 0.07;
uniform float expansion_progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 wave_color : hint_color = vec4(1.0, 0.85, 0.55, 1.0);

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    float radius = length(UV - vec2(0.5));
    float ring = 1.0 - smoothstep(ring_width * 0.5, ring_width, abs(radius - 0.35));
    float alpha = max(tex.a * 0.6, ring * 0.5) * (1.0 - expansion_progress);
    vec3 col = mix(tex.rgb, wave_color.rgb, 0.4);
    COLOR = vec4(col, alpha) * COLOR;
}
