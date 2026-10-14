shader_type canvas_item;
render_mode unshaded;

uniform vec4 accent : hint_color = vec4(1.0);
uniform float age = 1.0;

void fragment() {
    float envelope = exp(-age * 9.0);
    vec2 uv = UV;
    uv.y += sin(UV.x * 42.0 - age * 65.0) * 0.006 * envelope;
    float alpha = texture(TEXTURE, uv).a;
    float glint = pow(max(0.0, sin(UV.x * 16.0 - age * 22.0)), 4.0);
    COLOR = vec4(mix(accent.rgb, vec3(1.0, 0.95, 0.75), glint), alpha * envelope * 0.9) * COLOR;
}
