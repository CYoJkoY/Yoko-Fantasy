shader_type canvas_item;
render_mode unshaded;

uniform vec4 accent : hint_color = vec4(0.68, 0.39, 1.0, 1.0);
uniform float age = 0.0;
uniform float phase = 0.0;
uniform float ignited_at = -1.0;
uniform float note_lifetime;
uniform float fade_duration;

varying float ignition;
varying float note_opacity;

void vertex() {
    float scale = 0.64 + sin(age * 5.2 + phase) * 0.018;
    float angle = sin(age * 2.4 + phase) * 0.12;
    float c = cos(angle);
    float s = sin(angle);
    VERTEX = vec2(c * VERTEX.x - s * VERTEX.y, s * VERTEX.x + c * VERTEX.y) * scale;
    VERTEX.y += sin(age * 3.5 + phase) * 2.2;
    ignition = ignited_at >= 0.0 ? exp(-(age - ignited_at) * 25.0) : exp(-age * 14.0);
    note_opacity = clamp((note_lifetime - age) / fade_duration, 0.0, 1.0);
}

void fragment() {
    float visual_age = age + phase;
    vec2 uv = UV;
    uv.x += sin(uv.y * 13.0 - visual_age * 4.0) * 0.004;
    vec4 ink = texture(TEXTURE, uv);
    vec2 step = TEXTURE_PIXEL_SIZE * 1.5;
    float inner = texture(TEXTURE, uv + vec2(step.x, 0.0)).a;
    inner *= texture(TEXTURE, uv - vec2(step.x, 0.0)).a;
    inner *= texture(TEXTURE, uv + vec2(0.0, step.y)).a;
    inner *= texture(TEXTURE, uv - vec2(0.0, step.y)).a;
    float rim = (1.0 - inner) * ink.a;
    float sheen = pow(max(0.0, 1.0 - abs(uv.y + uv.x * 0.28 - mod(visual_age * 0.65, 1.7))), 18.0);
    vec3 color = mix(accent.rgb * 0.74, vec3(0.92, 0.91, 1.0), ink.r * 0.80);
    color = mix(color, vec3(0.55, 0.83, 1.0), rim * 0.37);
    color += vec3(0.25, 0.20, 0.32) * (sheen + ignition);
    COLOR = vec4(color, ink.a * 0.96 * note_opacity) * COLOR;
}
