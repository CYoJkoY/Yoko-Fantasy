shader_type canvas_item;
render_mode blend_add;

uniform float phase = 0.0;
uniform vec4 tint : hint_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec2 shape_uv = UV;
	float loose_tail = 1.0 - smoothstep(0.48, 0.94, shape_uv.x);
	float wave_a = sin(TIME * 14.0 + phase + shape_uv.x * 16.0);
	float wave_b = sin(TIME * 19.0 + phase * 0.73 + shape_uv.x * 27.0);
	float vertical_drift = (wave_a * 0.014 + wave_b * 0.006) * loose_tail;
	vec2 source_uv = vec2(1.0 - shape_uv.x, clamp(shape_uv.y + vertical_drift, 0.0, 1.0));

	vec4 stream = texture(TEXTURE, source_uv);
	vec2 echo_uv = vec2(
		clamp(source_uv.x + wave_b * 0.010 * loose_tail, 0.0, 1.0),
		clamp(source_uv.y + wave_a * 0.022 * loose_tail, 0.0, 1.0)
	);
	vec4 echo = texture(TEXTURE, echo_uv);
	stream = mix(stream, max(stream, echo), 0.26);

	float tail_fade = smoothstep(0.0, 0.20, shape_uv.x);
	float top_edge = smoothstep(0.02, 0.16, shape_uv.y);
	float bottom_edge = 1.0 - smoothstep(0.84, 0.98, shape_uv.y);
	float breath = 0.90 + 0.10 * sin(TIME * 8.0 + phase + shape_uv.x * 9.0);
	float alpha = stream.a * tail_fade * top_edge * bottom_edge * breath;
	vec3 color = stream.rgb * tint.rgb * (0.92 + 0.12 * wave_a * loose_tail);
	COLOR = vec4(color, alpha * tint.a) * COLOR;
}
