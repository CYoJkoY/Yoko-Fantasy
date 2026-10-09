shader_type canvas_item;
render_mode blend_add, unshaded;

uniform float progress = 0.0;

void fragment() {
    vec4 tint = COLOR;
    vec4 art = texture(TEXTURE, UV);
    vec2 arc_uv = (UV - vec2(0.5)) / vec2(0.3515625, 0.2);
    float along = (atan(arc_uv.y, arc_uv.x) + 1.570796) / 3.141593;
    float front = progress * 1.10;
    float reveal = 1.0 - smoothstep(front - 0.025, front + 0.045, along);
    float tail = smoothstep(front - 0.42, front - 0.05, along);
    float edge = exp(-pow((along - front + 0.025) / 0.055, 2.0));
    COLOR = vec4(mix(art.rgb, vec3(1.0, 0.99, 0.90), edge * 0.7), art.a * reveal * tail) * tint;
}
