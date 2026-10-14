shader_type canvas_item;
render_mode unshaded, blend_add;

uniform vec4 accent : hint_color = vec4(0.59, 0.30, 1.0, 1.0);
uniform float age = 0.0;
uniform float flight = 0.0;
uniform float phase = 0.0;
uniform float ignited_at = -1.0;
uniform float note_lifetime;
uniform float fade_duration;
uniform float core_padding = 1.0;

varying float ignition;
varying float note_opacity;

void vertex() {
    ignition = ignited_at >= 0.0 ? exp(-(age - ignited_at) * 25.0) : exp(-age * 14.0);
    if (flight < 0.5) {
        VERTEX *= 0.63 + sin(age * 5.2 + phase) * 0.035;
        note_opacity = clamp((note_lifetime - age) / fade_duration, 0.0, 1.0);
    } else {
        VERTEX *= (0.60 - ignition * 0.13) * core_padding;
        note_opacity = 1.0;
    }
}

void fragment() {
    float visual_age = age + phase;
    vec2 p = (UV - 0.5) * 2.0;
    float pulse = 0.94 + 0.06 * sin(visual_age * 7.0);
    float edge = 1.0 - smoothstep(0.80, 0.99, max(abs(p.x), abs(p.y)));
    vec3 energy;
    if (flight < 0.5) {
        float r = length(p);
        float angle = atan(p.y, p.x);
        float swirl = angle * 3.0 + r * 13.0 - visual_age * 4.5;
        float shell = exp(-pow((r - 0.48 - sin(swirl) * 0.075) * 12.0, 2.0));
        float veil = exp(-r * r * 5.8) * (0.14 + 0.07 * sin(swirl + r * 14.0));
        float ember = exp(-pow((r - 0.34 - sin(angle * 2.0 - visual_age * 3.0) * 0.05) * 25.0, 2.0));
        float broken = smoothstep(-0.65, 0.85, sin(angle * 2.0 + visual_age * 2.4));
        energy = accent.rgb * (shell * broken * 0.55 + veil * 0.65);
        energy += vec3(0.36, 0.72, 1.0) * ember * (1.0 - broken) * 0.38;
        energy += accent.rgb * exp(-r * r * 16.0) * 0.12;
        energy += vec3(0.88, 0.78, 1.0) * exp(-r * r * 12.0) * ignition * 0.8;
        energy *= pulse;
    } else {
        p *= core_padding;
        vec2 nucleus = p * vec2(2.25, 2.65);
        float core = exp(-dot(nucleus, nucleus) * 2.4);
        float corona = exp(-dot(nucleus, nucleus) * 0.46);
        float curl = exp(-pow((length(nucleus) - 0.83 - sin(atan(nucleus.y, nucleus.x) * 3.0 - visual_age * 12.0) * 0.16) * 5.0, 2.0));
        energy = accent.rgb * corona * 0.38;
        energy += vec3(0.34, 0.83, 1.0) * curl * 0.22;
        energy += vec3(1.0, 0.95, 1.0) * core * 1.25;
        energy *= pulse;
        energy += vec3(0.88, 0.78, 1.0) * corona * ignition * 0.8;
        edge = 1.0 - smoothstep(2.15, 3.50, length(nucleus));
    }
    COLOR = vec4(energy * edge, edge * note_opacity) * COLOR;
}
