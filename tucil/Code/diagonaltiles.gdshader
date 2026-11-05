shader_type canvas_item;

uniform float progress: hint_range(0.0,1.0);
uniform bool reverse = true;
uniform vec2 numberoftiles = vec2(15, 8.4375);
uniform vec2 pixelsPrtile = vec2(16,16);

void fragment(){
	vec2 posinsqr = UV * numberoftiles;
	vec2 pixpos = round(posinsqr*pixelsPrtile);
	vec2 frac = fract(pixpos/pixelsPrtile);
	vec2 dir = abs(frac - 0.5);
	
	if(dir.x + dir.y + UV.x + UV.y >= progress * 4.0){
		if(!reverse){
			discard;
		}
	}else if(reverse){
		discard;
	}
}
