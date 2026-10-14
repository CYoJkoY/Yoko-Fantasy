shader_type canvas_item;
render_mode unshaded, blend_add;

uniform vec4 accent : hint_color = vec4(0.64, 0.32, 1.0, 1.0);
uniform float age = 0.0;
uniform float head = 1.0;
uniform float ended_at = -1.0;
uniform float duration;
uniform float end_fade = 0.05;

varying float pluck;
varying float opacity;

void vertex() {
    float elapsed = ended_at >= 0.0 ? max(0.0, age - ended_at) : 0.0;
    float remaining = max(0.0, 1.0 - elapsed / duration);
    opacity = remaining * remaining;
    pluck = exp(-elapsed * 9.0);
}

void fragment() {
    float u = clamp(UV.x, 0.0, 1.0);
    float y = UV.y - 0.5;
    float span = sin(u * 3.141593);
    float vibration = sin(u * 26.0 - age * 43.0) * span * 0.065 * pluck;
    float center = y - vibration;
    float core = exp(-center * center * 1800.0);
    float upper = exp(-pow((center - 0.16 - sin(u * 18.0 + age * 27.0) * span * 0.035 * pluck) * 32.0, 2.0));
    float lower = exp(-pow((center + 0.16 + sin(u * 20.0 - age * 31.0) * span * 0.035 * pluck) * 32.0, 2.0));
    float glow = exp(-center * center * 29.0);
    float pulse = exp(-pow((u - head) * 18.0, 2.0));
    float passed = 1.0 - smoothstep(head - 0.025, head + 0.025, u);
    float flowing = 0.73 + 0.27 * sin(u * 60.0 - age * 35.0);
    float envelope = 0.16 + passed * 0.74 + pulse * 1.10;
    vec3 light = accent.rgb * (glow * 0.13 + upper * 0.55) + vec3(0.28, 0.77, 1.0) * lower * 0.48;
    light += vec3(0.93, 0.82, 1.0) * core * flowing * 0.80;
    light += accent.rgb * glow * pulse * 0.32;
    float edge = 1.0 - smoothstep(0.36, 0.49, abs(y));
    edge *= smoothstep(0.0, end_fade, u) * (1.0 - smoothstep(1.0 - end_fade, 1.0, u));
    COLOR = vec4(light * envelope * edge, edge * opacity) * COLOR;
}
