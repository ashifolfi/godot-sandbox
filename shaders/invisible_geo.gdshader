shader_type spatial;
render_mode unshaded;

uniform vec3 geo_color : source_color = vec3(0.0, 0.0, 0.0);
const float edge_thickness = 1.0;
varying vec3 barys;

void vertex() {
	int index = VERTEX_ID % 3;
	switch (index) {
		case 0:
			barys = vec3(1.0, 0.0, 0.0);
			break;
		case 1:
			barys = vec3(0.0, 1.0, 0.0);
			break;
		case 2:
			barys = vec3(0.0, 0.0, 1.0);
			break;
	}
}

void fragment() {
	vec3 deltas = fwidth(barys);
	vec3 barys_s = smoothstep(deltas * edge_thickness - 0.01, deltas * edge_thickness + 0.01, barys);
	float wires = min(barys_s.x, min(barys_s.y, barys_s.z));
	
	vec3 wire_color = vec3(
		1.0 - geo_color.r,
		1.0 - geo_color.g,
		1.0 - geo_color.b
	);
	
	ALBEDO = mix(wire_color, geo_color, wires);
}
