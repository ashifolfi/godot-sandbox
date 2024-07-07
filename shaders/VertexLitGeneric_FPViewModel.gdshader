shader_type spatial;
#include "VertexLitGeneric_Shared.gdshaderinc"

uniform float viewmodel_fov = 54.0f;

void vertex() {
	float onetanfov = 1.0f / tan(0.5f * (viewmodel_fov * PI / 180.0f));
	float aspect = VIEWPORT_SIZE.x / VIEWPORT_SIZE.y;
	// modify projection matrix
	PROJECTION_MATRIX[1][1] = -onetanfov;
	PROJECTION_MATRIX[0][0] = onetanfov / aspect;

	// draws the viewmodel over everything (disable if you want dof near on viewmodel)
	POSITION = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX.xyz, 1.0);
	POSITION.z = mix(POSITION.z, 0, 0.99);
}

void fragment() {
	vec4 btcol = texture(basetexture, UV);
	// gamma corrected color2
	vec3 gcc2 = pow(color2.rgb, vec3(2.200));
	vec3 color = clamp(btcol.rgb, vec3(0.0), vec3(1.0)) * clamp(gcc2, vec3(0.0), vec3(1.0));
	
	if (translucent) {
		ALPHA = btcol.a;
	}
	
	ALBEDO = color;
	if (bumpmap_enabled) {
		NORMAL_MAP = texture(bumpmap, UV).rgb;
	}
}
