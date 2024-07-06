/*
	Incomplete VertexLitGeneric shader for Godot 4.x
	
	Implementation based on these resources:
	- https://developer.valvesoftware.com/wiki/Phong_materials
	- https://cdn.akamai.steamstatic.com/apps/valve/2006/SIGGRAPH06_Course_ShadingInValvesSourceEngine.pdf
	- https://learnopengl.com/Lighting/Basic-Lighting
	- https://developer.valvesoftware.com/w/images/9/90/Shadetree.jpg
	- https://developer.valvesoftware.com/wiki/VertexLitGeneric
	- https://github.com/craftablescience/ChiraEngine/blob/main/resources/engine/shaders/phonglit.fsh
	- https://github.com/syborg64/BlenderVertexLitGeneric
	- Visual observation in HL2 EP2
*/
shader_type spatial;

uniform sampler2D basetexture;
uniform sampler2D bumpmap;
uniform vec3 color2 : source_color = vec3(1.0);
// phong variables
uniform float phongexponent; // ONLY SUPPLY INT VALUES PLEASE
uniform float phongboost;
uniform vec3 phongtint : source_color = vec3(1.0);
uniform vec3 phongfresnelranges = vec3(0.0, 0.5, 1.0);
// flags
uniform bool halflambert = false;
uniform bool phong = false;

float f_halflambert(vec3 N, vec3 L) {
	// scale dot product from lambert by 1/2, add 1/2, and square result
	vec3 nrmN = normalize(N);
	vec3 nrmL = normalize(L);
	float result = (dot(nrmN, nrmL) / 2.0) + 0.5;
	
	return pow(result, 2.0);
}

float f_lambert(vec3 N, vec3 L) {
	vec3 nrmN = normalize(N);
	vec3 nrmL = normalize(L);
	float result = dot(nrmN, nrmL);
	
	return max(result, 0.0);
}

// https://developer.valvesoftware.com/wiki/Phong_materials
float fresnel2(vec3 norm, vec3 eyedir) {
	float fresnel = 1.0 - clamp(dot(norm, eyedir), 0.0, 1.0);
	return fresnel * fresnel;
}

float fresnel(vec3 norm, vec3 eyedir, vec3 ranges) {
	float result, f = fresnel2(norm, eyedir);
	
	if (f > 0.5) {
		result = mix(ranges.y, ranges.z, (2.0 * f) - 1.0);
	} else {
		result = mix(ranges.x, ranges.y, 2.0 * f);
	}
	
	return result;
}

void fragment() {
	vec4 btcol = texture(basetexture, UV);
	// gamma corrected color2
	vec3 gcc2 = pow(color2.rgb, vec3(2.200));
	vec3 color = clamp(btcol.rgb, vec3(0.0), vec3(1.0)) * clamp(gcc2, vec3(0.0), vec3(1.0));
	
	ALBEDO = color;
	NORMAL_MAP = texture(bumpmap, UV).rgb;
}

void light() {
	vec3 lambert;
	
	if (halflambert) {
		lambert = ATTENUATION * LIGHT_COLOR * f_halflambert(NORMAL, LIGHT);
	} else {
		lambert = ATTENUATION * LIGHT_COLOR * f_lambert(NORMAL, LIGHT);
	}
	
	vec3 specular;
	if (phong)
	{
		float phongmask = texture(bumpmap, UV).a;
		float pbf = phongboost * phongmask;
		
		vec3 phongcolor = phongtint * clamp((pbf / phongexponent) * 3.540, 0.0, 1.0);
		float magicRoughness = ((phongexponent + 16.32) / 8.415) + 0.085;
		
		vec3 viewDir = normalize(VIEW - FRAGCOORD.xyz);
		vec3 reflectDir = reflect(-LIGHT, NORMAL);
		
		float spec = pow(max(dot(viewDir, reflectDir), 0.0), phongexponent);
		
		vec3 specular = (SPECULAR_AMOUNT * spec * (LIGHT_COLOR * phongcolor));
		SPECULAR_LIGHT += specular * fresnel(NORMAL, viewDir, phongfresnelranges);
	}

	DIFFUSE_LIGHT += ALBEDO * lambert;
}
