shader_type canvas_item;

uniform float intensity : hint_range(0.0, 3.0) = 1.5;
uniform float speed : hint_range(0.0, 10.0) = 5.0;
uniform float scale : hint_range(0.1, 10.0) = 5.0;
uniform float detail : hint_range(0.1, 5.0) = 2.0;
uniform vec4 flame_color : hint_color = vec4(1.0, 0.6, 0.2, 1.0);
uniform vec4 core_color : hint_color = vec4(1.0, 1.0, 0.2, 1.0);
uniform float flicker_speed : hint_range(0.0, 10.0) = 5.0;
uniform float bottom_offset : hint_range(0.0, 1.0) = 0.0;

float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);
    
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    
    vec2 u = f * f * (3.0 - 2.0 * f);
    
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 st) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    
    for (int i = 0; i < 4; i++) {
        value += amplitude * noise(st * frequency);
        st *= 2.0;
        amplitude *= 0.5;
    }
    
    return value;
}

void fragment() {
    vec2 uv = UV;
    float time = TIME * speed;
    float flame_noise = fbm(uv * scale + vec2(time * 0.5, time));
    float flame_detail = fbm(uv * scale * detail + vec2(time * 0.3, time * 1.2));
    float flame_pattern = mix(flame_noise, flame_detail, 0.4);
    float vertical_gradient = 1.0 - uv.y;
    
    vertical_gradient = pow(vertical_gradient, 1.5);
    vertical_gradient = max(0.0, vertical_gradient - bottom_offset);
    
    vec2 distortion = vec2(
        sin(uv.y * 8.0 + time * 2.0) * 0.05 * intensity * vertical_gradient,
        cos(uv.x * 6.0 + time * 1.5) * 0.03 * intensity * vertical_gradient
    );
    
    uv += distortion;

    vec4 tex_color = texture(TEXTURE, uv);
    
    float flame_mask = flame_pattern * vertical_gradient;
    
    float flicker = 0.8 + 0.2 * sin(TIME * flicker_speed);
    flame_mask *= flicker;
    
    vec4 fire_color = mix(flame_color, core_color, flame_mask * 1.5);
    
    float fire_alpha = flame_mask * tex_color.a;
    
    COLOR = mix(tex_color, fire_color, fire_alpha);
    COLOR.a = max(tex_color.a, fire_alpha);
}