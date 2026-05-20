shader_type canvas_item;
render_mode blend_add;

uniform float flicker_speed: hint_range(0.0, 50.0) = 12.0;
uniform float flicker_amount: hint_range(0.0, 1.0) = 0.35;
uniform float glow_softness: hint_range(0.0, 1.0) = 0.2;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);

    return mix(
        mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
        mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x),
        f.y
    );
}

void fragment() {
    vec2 uv = UV;

    float t = TIME * flicker_speed;
    float flicker = noise(vec2(uv.x * 8.0, t));

    flicker += noise(vec2(uv.x * 23.0, t * 1.7)) * 0.5;
    flicker = (flicker - 0.5) * flicker_amount;

    float alpha = 1.0 - abs(flicker);

    float edge_fade = 1.0 - smoothstep(1.0 - glow_softness, 1.0, abs(uv.y));
    alpha *= edge_fade;

    COLOR.a = alpha;
    COLOR.rgb *= 1.0 + flicker * 0.3;
}