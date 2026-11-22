shader_type canvas_item;
// 상대 파츠의 상태 색·흰 번쩍임·조준 테두리(결정 259). 상태 색은 칠에만 얹고 선은 그대로 둔다(바이블 5절, 결정 181·188).
// 2D가 sRGB 값으로 도는 것이 전제다(HDR 2D를 켜면 선과 칠이 다르게 갈린다. 계획 029 위험 R2).

// 문턱은 바꾸지 않는다(결정 188). 견본 026의 feColorMatrix와 같은 식이다.
const float LINE_Y = 0.22;
const float FILL_Y = 0.30;

uniform vec3 tint_color = vec3(1.0);
uniform float tint_amount = 0.0;
uniform bool outline_on = false;
// 테두리의 굵기(텍스처 화소). 파츠 단위 5 ÷ 단위/화소.
uniform vec2 outline_texels = vec2(9.0);
uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 0.4, 1.0);

// 그림 밖은 투명으로 본다.
float inside(vec2 uv) {
	return (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) ? 0.0 : 1.0;
}

void fragment() {
	vec4 src = COLOR;
	float y = dot(src.rgb, vec3(0.2126, 0.7152, 0.0722));
	float line_w = clamp((FILL_Y - y) / (FILL_Y - LINE_Y), 0.0, 1.0);
	vec3 tinted = mix(src.rgb, tint_color, tint_amount);
	vec4 result = vec4(mix(tinted, src.rgb, line_w), src.a);
	// 안쪽 테두리: 잘린 그림의 여백이 1화소라 바깥에는 그릴 자리가 없다(결정 251).
	if (outline_on && src.a >= 0.5) {
		vec2 d = TEXTURE_PIXEL_SIZE * outline_texels;
		bool edge = false;
		for (int i = 0; i < 8; i++) {
			float a = float(i) * 0.785398;
			vec2 far_uv = UV + vec2(cos(a), sin(a)) * d;
			vec2 near_uv = UV + vec2(cos(a), sin(a)) * d * 0.5;
			// 내장 TEXTURE는 사용자 함수에 넘기지 않는다(헤드리스 4.7.2의 셰이더 컴파일러가 오류를 낸다. 029 playtester).
			float far_a = texture(TEXTURE, far_uv).a * inside(far_uv);
			float near_a = texture(TEXTURE, near_uv).a * inside(near_uv);
			if (far_a < 0.5 || near_a < 0.5) {
				edge = true;
			}
		}
		if (edge) {
			result = vec4(outline_color.rgb, src.a);
		}
	}
	COLOR = result;
}
