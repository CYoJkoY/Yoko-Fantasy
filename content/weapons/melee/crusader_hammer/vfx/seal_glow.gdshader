shader_type canvas_item;
render_mode blend_add, unshaded;

uniform float progress = 0.0;

void fragment() {
	vec4 tint = COLOR;
	vec4 art = texture(TEXTURE, UV);
	float radius = length((UV - vec2(0.5)) * 2.0);
	float ignition = exp(-pow((radius - progress * 3.4) / 0.13, 2.0));
	float shimmer = 0.92 + 0.08 * sin(radius * 32.0 - progress * 14.0);
	vec3 gold = mix(art.rgb, vec3(1.0, 0.98, 0.82), ignition * 0.6);
	vec2 pixel = TEXTURE_PIXEL_SIZE * 2.5;
	float halo = texture(TEXTURE, UV + vec2(pixel.x, 0.0)).a;
	halo += texture(TEXTURE, UV - vec2(pixel.x, 0.0)).a;
	halo += texture(TEXTURE, UV + vec2(0.0, pixel.y)).a;
	halo += texture(TEXTURE, UV - vec2(0.0, pixel.y)).a;
	halo *= 0.25;
	float alpha = max(art.a, halo * 0.48);
	COLOR = vec4(gold * (shimmer * 1.35 + ignition * 0.85), alpha) * tint;
}
