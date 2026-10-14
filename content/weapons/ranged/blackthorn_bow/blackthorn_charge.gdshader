shader_type canvas_item;
render_mode unshaded, blend_add;

uniform float charge : hint_range(0.0, 1.0) = 0.0;
uniform float release_flash : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    float wave = pow(0.5 + 0.5 * sin(UV.y * 19.0 - TIME * 3.3), 3.0);
    float energy = charge * (0.16 + wave * 0.34) + release_flash * 0.9;
    COLOR = vec4(mix(tex.rgb, vec3(1.0, 0.8, 1.0), release_flash), tex.a * energy) * COLOR;
}
