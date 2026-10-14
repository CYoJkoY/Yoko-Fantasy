shader_type canvas_item;
render_mode unshaded, blend_add;

uniform float pulse : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec4 eye = texture(TEXTURE, UV);
    float sweep = 1.0 - smoothstep(0.0, 0.22, abs(UV.x - (1.0 - pulse)));
    vec3 gold = mix(vec3(1.0, 0.58, 0.12), vec3(1.0, 0.97, 0.78), sweep);
    COLOR = vec4(gold, eye.a * pulse) * COLOR;
}
