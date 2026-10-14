shader_type canvas_item;
render_mode unshaded;

uniform vec4 accent : hint_color = vec4(0.46, 0.86, 1.0, 1.0);
uniform float age = 0.0;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    float sheen = pow(max(0.0, 1.0 - abs(UV.y + UV.x * 0.32 - mod(age * 0.6, 1.8))), 12.0);
    vec3 ink = mix(tex.rgb, mix(accent.rgb, vec3(1.0), 0.8), sheen * 0.22);
    COLOR = vec4(ink, tex.a) * COLOR;
}
