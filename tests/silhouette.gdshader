shader_type canvas_item;
// 찍기 씬의 실루엣 모드(계획 030 결정 270). 알파만 읽어 한 색으로 칠한다(견본 026의 silArt와 같은 갈래).
// 게임 셰이더(opponent_part.gdshader)는 고치지 않는다. TEXTURE는 fragment 안에서만 읽는다(029의 교훈).

uniform vec4 sil_color : source_color = vec4(0.0, 0.0, 1.0, 1.0);

void fragment() {
	float a = step(0.5, texture(TEXTURE, UV).a);
	COLOR = vec4(sil_color.rgb, a);
}
