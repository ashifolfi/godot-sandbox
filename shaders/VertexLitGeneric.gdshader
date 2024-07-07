shader_type spatial;
#include "VertexLitGeneric_Shared.gdshaderinc"

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
