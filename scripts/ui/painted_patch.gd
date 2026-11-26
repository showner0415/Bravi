extends RefCounted
## 그린 질감(계획 033b, 결정 489)의 그리는 길. StyleBox의 그림 칸이 차 있을 때만 부른다.


# 원본 화소 `density` = 화면 1. 변환으로 줄여 그린다: 버튼은 스타일 다음에 같은 항목에 글을 그리므로 끝에 꼭 되돌린다(R6).
static func draw_nine_patch(canvas_item: RID, rect: Rect2, texture: Texture2D, margins: Vector4, density: float,
		axis_x: int, axis_y: int, modulate: Color, draw_center: bool = true) -> void:
	RenderingServer.canvas_item_add_set_transform(canvas_item,
		Transform2D(0.0, Vector2.ONE / density, 0.0, rect.position))
	RenderingServer.canvas_item_add_nine_patch(canvas_item, Rect2(Vector2.ZERO, rect.size * density),
		Rect2(Vector2.ZERO, texture.get_size()), texture.get_rid(),
		Vector2(margins.x, margins.y), Vector2(margins.z, margins.w),
		axis_x, axis_y, draw_center, modulate)
	RenderingServer.canvas_item_add_set_transform(canvas_item, Transform2D.IDENTITY)


# 타일 없이 그림의 한 곳을 잘라 깐다. 자리는 rect 크기로 정해(같은 크기는 같은 곳) 넘치면 그림 안으로 당긴다(결정 489).
static func draw_paper(canvas_item: RID, rect: Rect2, texture: Texture2D, density: float, modulate: Color) -> void:
	var tex_size := texture.get_size()
	var want := rect.size * density
	var region_size := Vector2(minf(want.x, tex_size.x), minf(want.y, tex_size.y))
	var slack := tex_size - region_size
	var seed_x := fposmod(rect.size.x * 0.6180339 + rect.size.y * 0.3247179, 1.0)
	var seed_y := fposmod(rect.size.x * 0.7548776 + rect.size.y * 0.5698402, 1.0)
	var origin := Vector2(slack.x * seed_x, slack.y * seed_y)
	RenderingServer.canvas_item_add_texture_rect_region(canvas_item, rect, texture.get_rid(),
		Rect2(origin, region_size), modulate)
