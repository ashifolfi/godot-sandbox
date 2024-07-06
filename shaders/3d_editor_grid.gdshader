shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec4 grid_color_main : source_color;
uniform vec4 grid_color_sub : source_color;
uniform float grid_size = 32.0;
uniform float line_thickness = 1.0;
uniform float fade_distance = 12.0;

void fragment() {
	// Called for every pixel the material is visible on.
	vec3 worldPos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	vec4 color = vec4(0.0, 0.0, 0.0, 0.0);
	float thickness = line_thickness / 100.0;
	float grid = grid_size / 100.0;
	
	if (mod(worldPos.x, grid * 4.0) <= thickness)
	{
		color = grid_color_main;
	}
	else if (mod(worldPos.x, grid) <= thickness)
	{
		if (color != grid_color_main)
			color = grid_color_sub;
	}
	
	if (mod(worldPos.z, grid * 4.0) <= thickness)
	{
		color = grid_color_main;
	}
	else if (mod(worldPos.z, grid) <= thickness)
	{
		if (color != grid_color_main)
			color = grid_color_sub;
	}
	
	float x = abs(UV.r-.5)*2.0;
	float y = abs(UV.g-.5)*2.0;
	float q = (1.0-sqrt(x*x+y*y)/(fade_distance / 10.0))/(1.0-0.0);
	
	ALBEDO = color.xyz;
	ALPHA = color.w*q;
	if (ALPHA < 0.0)
		ALPHA = 0.0;
}
