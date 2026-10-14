shader_type canvas_item;
render_mode unshaded;

uniform float crack_progress : hint_range(0.0, 1.0) = 1.0;
uniform float glow_intensity : hint_range(0.0, 2.0) = 1.0;
uniform vec4 glow_color : hint_color = vec4(1.0, 0.65, 0.22, 1.0);
uniform float dissolve_amount : hint_range(0.0, 1.0) = 0.0;
uniform float pulse_time = 0.0;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    if (tex.a <= 0.001) {
        discard;
    }

    vec2 center_uv = UV - vec2(0.5);
    float dist = length(center_uv) * 2.0;

    float angle = atan(center_uv.y, center_uv.x);
    float edge_var = 0.12 * sin(angle * 6.0) + 0.08 * cos(angle * 13.0);
    float reveal_threshold = clamp(crack_progress * 1.25 + edge_var, 0.0, 1.25);

    if (dist > reveal_threshold) {
        discard;
    }

    float pulse = 0.75 + 0.25 * sin(pulse_time * 6.0 + dist * 5.0);
    float inner_glow_mask = clamp((1.0 - dist) * 1.2, 0.0, 1.0);
    
    vec3 rock_color = tex.rgb;
    vec3 energized = mix(rock_color, glow_color.rgb * 1.3, inner_glow_mask * glow_intensity * pulse);
    
    float alpha = tex.a * (1.0 - dissolve_amount);
    
    COLOR = vec4(energized, alpha) * COLOR;
}
