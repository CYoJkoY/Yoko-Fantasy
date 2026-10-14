shader_type canvas_item;
render_mode unshaded;

varying float text_y;

void vertex() {
    text_y = VERTEX.y;
}

void fragment() {
    vec4 glyph = texture(TEXTURE, UV) * COLOR;
    vec3 purple = vec3(0.188235, 0.078431, 0.250980);
    vec3 dark_green = vec3(0.08, 0.32, 0.22);
    glyph.rgb *= mix(dark_green, purple, smoothstep(12.0, 42.0, text_y));
    COLOR = glyph;
}
