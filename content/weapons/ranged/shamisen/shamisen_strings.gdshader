shader_type canvas_item;
render_mode unshaded;

uniform float age = 1.0;
uniform float strength = 1.0;

void fragment() {
    float string_index = clamp(floor((UV.y - 0.39) / 0.057), 0.0, 2.0);
    float elapsed = age - string_index * 0.028;
    float pulse = step(0.0, elapsed) * exp(-max(elapsed, 0.0) * 16.0) * strength;
    vec2 uv = UV;
    float span = sin(clamp((UV.x - 0.08) / 0.79, 0.0, 1.0) * 3.141593);
    uv.y += sin(UV.x * 36.0 - age * 170.0) * TEXTURE_PIXEL_SIZE.y * 2.8 * span * pulse;
    vec4 strings = texture(TEXTURE, uv);
    vec2 glow_step = TEXTURE_PIXEL_SIZE * 1.6;
    float glow = texture(TEXTURE, uv + vec2(0.0, glow_step.y)).a;
    glow += texture(TEXTURE, uv - vec2(0.0, glow_step.y)).a;
    glow += texture(TEXTURE, uv + vec2(glow_step.x, 0.0)).a;
    glow += texture(TEXTURE, uv - vec2(glow_step.x, 0.0)).a;
    glow = clamp(glow * 0.32, 0.0, 1.0) * pulse;
    float glint = pow(max(0.0, cos(UV.x * 16.0 - age * 45.0)), 8.0) * pulse;
    vec3 ink = mix(strings.rgb, vec3(0.96, 0.87, 1.0), clamp(pulse * 0.85 + glint, 0.0, 1.0));
    ink += vec3(0.58, 0.25, 0.96) * glow;
    COLOR = vec4(ink, max(strings.a, glow * 0.72)) * COLOR;
}
