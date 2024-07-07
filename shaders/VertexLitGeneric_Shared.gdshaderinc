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

render_mode depth_draw_always, cull_back, ambient_light_disabled;

uniform sampler2D basetexture;
uniform sampler2D bumpmap;
uniform vec3 color2 : source_color = vec3(1.0);
uniform bool translucent = false;
uniform bool halflambert = false;
// phong 
uniform bool phong = false;
uniform float phongexponent; // ONLY SUPPLY INT VALUES PLEASE
uniform float phongboost;
uniform vec3 phongtint : source_color = vec3(1.0);
uniform vec3 phongfresnelranges = vec3(0.0, 0.5, 1.0);
// self illumination
uniform bool selfillum = false;
uniform vec3 selfillumtint : source_color = vec3(1.0);

// https://github.com/mapbase-source/source-sdk-2013/blob/471a840ed98c7206237cb579671a6d6fda9fd4f9/sp/src/materialsystem/stdshaders/common_vertexlitgeneric_dx9.h#L96
float f_halflambert(vec3 N, vec3 L) {
	// scale dot product from lambert by 1/2, add 1/2, and square result
	vec3 nrmN = normalize(N);
	vec3 nrmL = normalize(L);
	float result = clamp(dot(nrmN, nrmL) * 0.5 + 0.5, 0.0, 1.0);
	
	return result * result;
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

void light() {
	vec3 lambert;
	
	// Since Source 2007, half-lambertian lighting is forcibly enabled on VertexLitGeneric regardless of $halflambert setting when $phong is enabled
	if (halflambert || phong) {
		lambert = ATTENUATION * LIGHT_COLOR * f_halflambert(NORMAL, LIGHT);
	} else {
		lambert = ATTENUATION * LIGHT_COLOR * f_lambert(NORMAL, LIGHT);
	}
	
	if (phong)
	{
		float phongmask = texture(bumpmap, UV).a;
		vec3 phongcolor = phongtint * phongmask;
		
		vec3 viewDir = normalize(VIEW - FRAGCOORD.xyz);
		// https://github.com/mapbase-source/source-sdk-2013/blob/471a840ed98c7206237cb579671a6d6fda9fd4f9/sp/src/materialsystem/stdshaders/common_vertexlitgeneric_dx9.h#L178
		vec3 reflectDir = 2.0 * NORMAL * dot(NORMAL, viewDir) - viewDir;
		float LdotR = clamp(dot(reflectDir, LIGHT), 0.0, 1.0);
		vec3 specularLighting = vec3(pow(LdotR, phongexponent));
		
		specularLighting *= clamp(dot(NORMAL, LIGHT), 0.0, 1.0);
		specularLighting *= (phongcolor * LIGHT_COLOR) * phongboost;

		SPECULAR_LIGHT += specularLighting * fresnel(NORMAL, viewDir, phongfresnelranges);
	}

	vec3 diffuseComponent = ALBEDO * lambert;

	if (selfillum) {
		// use alpha of base texture
		float selfIllumMask = texture(basetexture, UV).a;
		diffuseComponent = mix(diffuseComponent, selfillumtint * ALBEDO, selfIllumMask);
	}

	DIFFUSE_LIGHT += diffuseComponent;
}