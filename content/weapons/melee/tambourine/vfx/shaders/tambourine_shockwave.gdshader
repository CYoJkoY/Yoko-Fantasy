shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 tint_color : hint_color = vec4(1.0, 0.77, 0.24, 1.0);
uniform float arc_phase = 0.0;
uniform float width_ratio : hint_range(0.1, 1.0) = 1.0;

void fragment() {
	vec2 offset = UV - vec2(0.5);
	float radius = max(length(offset), 0.0001);
	float angle = atan(offset.y, offset.x);
	float width = width_ratio * mix(1.0, 0.22, smoothstep(0.06, 0.95, progress));
	float sample_radius = max(0.0, 106.0 / 256.0 + (radius - 106.0 / 256.0) / width);
	vec2 sample_uv = vec2(0.5) + offset / radius * sample_radius;
	vec4 tex = texture(TEXTURE, sample_uv);
	float arcs = 0.54 + 0.26 * sin(angle * 3.0 + arc_phase)
		+ 0.15 * sin(angle * 7.0 - arc_phase * 0.7)
		+ 0.05 * sin(angle * 13.0 + arc_phase);
	float erosion = smoothstep(0.16, 0.94, progress);
	float arc_mask = smoothstep(erosion - 0.16, erosion + 0.08, arcs);
	float edge = smoothstep(0.0, 0.12, tex.a);
	vec3 color = mix(tex.rgb, tint_color.rgb, 0.2);
	color = mix(color, vec3(1.0, 0.97, 0.82), (1.0 - smoothstep(0.0, 0.28, progress)) * 0.5);
	COLOR *= vec4(color, tex.a * tint_color.a * arc_mask * edge);
}
