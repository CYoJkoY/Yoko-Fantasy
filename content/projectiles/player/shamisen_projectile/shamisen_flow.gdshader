shader_type canvas_item;
render_mode unshaded, blend_add;

uniform vec4 accent : hint_color = vec4(0.59, 0.30, 1.0, 1.0);
uniform float age = 0.0;
uniform float echo_started_at = -1.0;
uniform float echo_duration;

varying float opacity;

void vertex() {
    float remaining = echo_started_at >= 0.0 ? max(0.0, 1.0 - (age - echo_started_at) / echo_duration) : 1.0;
    opacity = remaining * remaining;
}

void fragment() {
    float u = clamp(UV.x, 0.0, 1.0);
    float y = UV.y * 2.0 - 1.0;
    float spine = sin(u * 11.0 - age * 21.0) * (1.0 - u) * 0.08;
    float width = 0.14 + pow(u, 0.75) * 0.27;
    float fluid = exp(-pow((y - spine) / width, 2.0));
    float filament_width = 0.05 + u * 0.025;
    float violet = exp(-pow((y - spine - sin(u * 12.0 - age * 18.0) * width * 0.50) / filament_width, 2.0));
    float blue = exp(-pow((y - spine + sin(u * 8.0 + age * 15.0) * width * 0.60) / filament_width, 2.0));
    float glow = exp(-pow((y - spine) / (width * 1.8), 2.0));
    float taper = smoothstep(0.0, 0.18, u) * (1.0 - smoothstep(0.84, 1.0, u));
    vec3 light = accent.rgb * (fluid * 0.68 + violet * 0.42 + glow * 0.08);
    light += vec3(0.34, 0.83, 1.0) * blue * 0.52;
    light += vec3(1.0, 0.95, 1.0) * (fluid * 0.30 * u * u + violet * 0.10);
    float edge = 1.0 - smoothstep(0.72, 0.99, abs(y));
    COLOR = vec4(light * taper * edge, edge * opacity) * COLOR;
}
