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


# draw_paper와 같은 그림 자리를 바깥 꼴(rect 안의 좌표) 안에만 깐다(결정 498). 자리 셈은 draw_paper와 한 벌이다.
static func draw_paper_clipped(canvas_item: RID, rect: Rect2, texture: Texture2D, density: float, modulate: Color,
		outline: PackedVector2Array) -> void:
	var tex_size := texture.get_size()
	var want := rect.size * density
	var region_size := Vector2(minf(want.x, tex_size.x), minf(want.y, tex_size.y))
	var slack := tex_size - region_size
	var seed_x := fposmod(rect.size.x * 0.6180339 + rect.size.y * 0.3247179, 1.0)
	var seed_y := fposmod(rect.size.x * 0.7548776 + rect.size.y * 0.5698402, 1.0)
	var origin := Vector2(slack.x * seed_x, slack.y * seed_y)
	_fill_mapped(canvas_item, outline, rect.position, texture, modulate, origin, region_size, Vector2.ZERO, rect.size)


# 9조각을 손으로 나눠(가운데 없음) 조각마다 바깥 꼴과 겹친 몫만 깐다(결정 498). TILE_FIT은 같은 크기로 나눈 타일마다 조각 전체를 깐다.
static func draw_nine_patch_clipped(canvas_item: RID, rect: Rect2, texture: Texture2D, margins: Vector4, density: float,
		axis_x: int, axis_y: int, modulate: Color, outline: PackedVector2Array) -> void:
	var tex := texture.get_size()
	var xd := [0.0, margins.x / density, rect.size.x - margins.z / density, rect.size.x]
	var yd := [0.0, margins.y / density, rect.size.y - margins.w / density, rect.size.y]
	var xs := [0.0, margins.x, tex.x - margins.z, tex.x]
	var ys := [0.0, margins.y, tex.y - margins.w, tex.y]
	for row in 3:
		for col in 3:
			if row == 1 and col == 1:
				continue
			var dst := Rect2(xd[col], yd[row], xd[col + 1] - xd[col], yd[row + 1] - yd[row])
			var src := Rect2(xs[col], ys[row], xs[col + 1] - xs[col], ys[row + 1] - ys[row])
			if dst.size.x <= 0.0 or dst.size.y <= 0.0 or src.size.x <= 0.0 or src.size.y <= 0.0:
				continue
			var nx := _tile_count(dst.size.x, src.size.x / density, axis_x) if col == 1 else 1
			var ny := _tile_count(dst.size.y, src.size.y / density, axis_y) if row == 1 else 1
			var tile := Vector2(dst.size.x / nx, dst.size.y / ny)
			for iy in ny:
				for ix in nx:
					var at := dst.position + Vector2(ix * tile.x, iy * tile.y)
					var quad := PackedVector2Array([at, at + Vector2(tile.x, 0), at + tile, at + Vector2(0, tile.y)])
					for part in Geometry2D.intersect_polygons(quad, outline):
						_fill_mapped(canvas_item, part, rect.position, texture, modulate, src.position, src.size, at, tile)


# 잘린 자리의 바랜 선(결정 498). points는 판 안의 좌표.
static func draw_edge_line(canvas_item: RID, offset: Vector2, points: PackedVector2Array, color: Color, width: float) -> void:
	if points.size() < 2:
		return
	var world := PackedVector2Array()
	for p in points:
		world.append(p + offset)
	RenderingServer.canvas_item_add_polyline(canvas_item, world, PackedColorArray([color]), width, true)


static func _tile_count(dst_len: float, src_screen_len: float, mode: int) -> int:
	if mode == RenderingServer.NINE_PATCH_TILE_FIT:
		return maxi(1, roundi(dst_len / src_screen_len))
	return 1


# 다각형(dst 상자 안의 좌표)을 삼각형으로 나눠 선형 UV로 깐다: dst 상자가 src 상자의 그림에 대응한다.
static func _fill_mapped(canvas_item: RID, poly: PackedVector2Array, offset: Vector2, texture: Texture2D, modulate: Color,
		src_pos: Vector2, src_size: Vector2, dst_pos: Vector2, dst_size: Vector2) -> void:
	var indices := Geometry2D.triangulate_polygon(poly)
	if indices.is_empty():
		return
	var tex_size := texture.get_size()
	var points := PackedVector2Array()
	var uvs := PackedVector2Array()
	var colors := PackedColorArray()
	for p in poly:
		points.append(p + offset)
		uvs.append((src_pos + (p - dst_pos) * src_size / dst_size) / tex_size)
		colors.append(modulate)
	RenderingServer.canvas_item_add_triangle_array(canvas_item, indices, points, colors, uvs,
		PackedInt32Array(), PackedFloat32Array(), texture.get_rid())
