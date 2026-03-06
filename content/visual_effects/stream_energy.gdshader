shader_type canvas_item;

uniform vec4 line_color : hint_color = vec4(1.0, 0.0, 0.1, 1.0);
uniform float speed = 20.0;
uniform float pulse_speed = 10.0;
uniform float dash_count = 12.0;

void fragment() {
    float duration = TIME * speed;
    float pulse = sin(UV.x * dash_count - duration) * 0.5 + 0.5;
    float edge_fade = sin(UV.y * 3.1415927);
    float glow = 0.8 + 0.2 * sin(TIME * pulse_speed);
    
    vec4 final_color = line_color;
    final_color.a *= pulse * edge_fade * glow;
    
    COLOR = final_color;
}