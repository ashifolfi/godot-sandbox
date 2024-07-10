shader_type spatial;
render_mode unshaded;

uniform sampler2D sky_texture : source_color;

void fragment() {
	ALBEDO = texture(sky_texture, SCREEN_UV).rgb;
}