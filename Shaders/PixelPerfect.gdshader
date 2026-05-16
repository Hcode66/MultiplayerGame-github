shader_type canvas_item;

void light() {
	LIGHT.rgb = LIGHT_DIRECTION;
	LIGHT.a = COLOR.a;
}