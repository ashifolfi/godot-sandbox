shader_type canvas_item;

uniform bool horizontal = false;
uniform bool flip = false;
uniform float progress : hint_range(0.0, 1.0, 0.1) = 1.0;

void fragment() {
	// Called for every pixel the material is visible on.
	if (horizontal) {
		if (flip) {
			if (UV.x < 1.0 - progress) {
				COLOR.a = 0.0;
			}
		} else {
			if (UV.x > progress) {
				COLOR.a = 0.0;
			}
		}
	} else {
		if (flip) {
			if (UV.y < 1.0 - progress) {
				COLOR.a = 0.0;
			}
		} else {
			if (UV.y > progress) {
				COLOR.a = 0.0;
			}
		}
	}
}
