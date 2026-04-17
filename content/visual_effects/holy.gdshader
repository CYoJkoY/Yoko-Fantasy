shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.8;
uniform float pulse_speed : hint_range(0.0, 3.0) = 1.5;
uniform vec4 glow_color : hint_color = vec4(1.0, 0.95, 0.8, 1.0);
uniform float edge_width : hint_range(0.001, 0.1) = 0.02;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);

    if (tex_color.a < 0.01) {
        COLOR = vec4(0.0, 0.0, 0.0, 0.0);
    } else {
        float pulse = sin(TIME * pulse_speed) * 0.3 + 0.7;

        vec2 pixel_size = vec2(1.0) / vec2(textureSize(TEXTURE, 0));
        float alpha_up = texture(TEXTURE, UV + vec2(0.0, edge_width)).a;
        float alpha_down = texture(TEXTURE, UV - vec2(0.0, edge_width)).a;
        float alpha_left = texture(TEXTURE, UV - vec2(edge_width, 0.0)).a;
        float alpha_right = texture(TEXTURE, UV + vec2(edge_width, 0.0)).a;

        float edge = (abs(tex_color.a - alpha_up) +
                      abs(tex_color.a - alpha_down) +
                      abs(tex_color.a - alpha_left) +
                      abs(tex_color.a - alpha_right)) * 2.5;

        edge = clamp(edge, 0.0, 1.0);

        float gold_white = 1.0 - length(UV - 0.5) * 1.5;
        gold_white = clamp(gold_white, 0.0, 1.0);

        vec3 gold = vec3(1.0, 0.9, 0.5);
        vec3 white = vec3(1.0, 1.0, 0.95);
        vec3 effect_color = mix(gold, white, gold_white);

        float effect_strength = edge * pulse * intensity;
        vec3 final_color = mix(tex_color.rgb, effect_color, effect_strength);
        final_color += effect_color * 0.3 * pulse * intensity;

        COLOR = vec4(final_color, tex_color.a);
    }
}
