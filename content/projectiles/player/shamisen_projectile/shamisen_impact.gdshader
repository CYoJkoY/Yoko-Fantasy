shader_type canvas_item;
render_mode unshaded, blend_add;

uniform float progress = 0.0;
uniform float phase = 0.0;
uniform float strength = 1.0;

void fragment() {
    vec2 p = (UV - 0.5) * 2.0;
    float r = length(p);
    float angle = atan(p.y, p.x);
    float fade = pow(1.0 - progress, 2.0);
    float front = 0.12 + 0.72 * (1.0 - pow(1.0 - progress, 3.0));
    float ripple = sin(angle * 5.0 + phase + progress * 7.0) * 0.018;
    float ring = exp(-pow((r - front - ripple) * 44.0, 2.0));
    float echo = exp(-pow((r - front * 0.72) * 60.0, 2.0));
    float fracture = pow(max(0.0, cos(angle * 3.0 + phase)), 12.0);
    float rays = fracture * exp(-r * r * 7.0) * pow(1.0 - progress, 4.0);
    float flash = exp(-r * r * 36.0) * max(0.0, 1.0 - progress * 4.3);
    float flare = exp(-p.y * p.y * 520.0 - p.x * p.x * 6.0) * max(0.0, 1.0 - progress * 3.3);
    float fragments = pow(max(0.0, cos(angle * 7.0 + phase + progress * 2.5)), 42.0);
    fragments *= exp(-pow((r - front * 0.88) * 17.0, 2.0));
    float broken = 0.35 + 0.65 * pow(sin(angle * 2.0 + phase), 2.0);
    vec3 energy = vec3(0.51, 0.20, 1.0) * (ring * broken * 0.55 + rays * 0.8) * fade;
    energy += vec3(0.25, 0.77, 1.0) * echo * fade * 0.25;
    energy += vec3(1.0, 0.90, 1.0) * (flash * 1.5 + flare * 0.8);
    energy += vec3(0.72, 0.82, 1.0) * fragments * fade * 0.75;
    COLOR = vec4(energy * strength, 1.0 - smoothstep(0.91, 1.0, r)) * COLOR;
}
