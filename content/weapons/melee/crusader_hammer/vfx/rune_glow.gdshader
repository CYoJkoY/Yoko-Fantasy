shader_type canvas_item;
render_mode blend_add, unshaded;

uniform float opacity = 0.3;
uniform float charge = 0.0;
uniform float phase = 0.0;

void fragment() {
	vec4 tint = COLOR;
	vec4 art = texture(TEXTURE, UV);
	vec2 step_uv = TEXTURE_PIXEL_SIZE * 1.5;
	float halo = texture(TEXTURE, UV + vec2(step_uv.x, 0.0)).a;
	halo += texture(TEXTURE, UV - vec2(step_uv.x, 0.0)).a;
	halo += texture(TEXTURE, UV + vec2(0.0, step_uv.y)).a;
	halo += texture(TEXTURE, UV - vec2(0.0, step_uv.y)).a;
	float glint = pow(max(0.0, cos(UV.y * 8.0 - phase * 2.4)), 12.0) * 0.18;
	float energy = clamp(opacity + charge * 0.8, 0.0, 1.0);
	vec3 gold = mix(art.rgb, vec3(1.0, 0.95, 0.74), charge * 0.7);
	COLOR = vec4(gold * (1.0 + glint + charge * 0.35), (art.a + halo * 0.09) * energy) * tint;
}
