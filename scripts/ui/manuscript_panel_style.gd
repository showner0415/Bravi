@tool
extends StyleBox
## 필사본 패널(결정 312 나): 칠 → 결 → 바깥 테두리 → 안쪽 가는 선 → 네 모서리 마름모. 값이 0인 몫은 그리지 않는다(벽은 칠과 결만).

const PaperGrain := preload("res://scripts/ui/paper_grain.gd")

@export var fill_color := Color("E9D8B4")
## 견본과 나란히 대어 맞춘 세기(판 N). 1.0이면 견본보다 짙다.
@export var grain := 0.55
@export var border_color := Color("3B2A1E")
@export var border_width := 3.0
@export var inner_color := Color("6B5440")
@export var inner_inset := 5.0
@export var inner_width := 1.0
@export var corner_color := Color("D2B98C")
@export var corner_radius := 4.0


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	if fill_color.a > 0.0:
		RenderingServer.canvas_item_add_rect(to_canvas_item, rect, fill_color)
	if grain > 0.0:
		_draw_grain(to_canvas_item, rect)
	if border_width > 0.0:
		_draw_frame(to_canvas_item, rect, border_width, border_color)
	if inner_width > 0.0:
		var inner := rect.grow(-inner_inset)
		_draw_frame(to_canvas_item, inner, inner_width, inner_color)
		if corner_radius > 0.0:
			for corner in [inner.position, Vector2(inner.end.x, inner.position.y),
					Vector2(inner.position.x, inner.end.y), inner.end]:
				_draw_diamond(to_canvas_item, corner)


# 텍스처 반복 설정에 기대지 않고 타일을 손으로 나눠 깐다(끝 타일은 같은 비로 잘라서).
func _draw_grain(item: RID, rect: Rect2) -> void:
	var texture: Texture2D = PaperGrain.texture()
	var tile: Vector2 = PaperGrain.DRAW_SIZE
	var scale_x := tile.x / float(PaperGrain.SIZE)
	var modulate := Color(1, 1, 1, grain)
	var y := rect.position.y
	while y < rect.end.y:
		var h := minf(tile.y, rect.end.y - y)
		var x := rect.position.x
		while x < rect.end.x:
			var w := minf(tile.x, rect.end.x - x)
			RenderingServer.canvas_item_add_texture_rect_region(item, Rect2(x, y, w, h),
				texture.get_rid(), Rect2(0, 0, w / scale_x, h), modulate)
			x += tile.x
		y += tile.y


# 테두리는 사각형 안쪽에 네 변의 채운 사각형으로 그린다(모서리가 비지 않게).
func _draw_frame(item: RID, rect: Rect2, width: float, color: Color) -> void:
	RenderingServer.canvas_item_add_rect(item, Rect2(rect.position, Vector2(rect.size.x, width)), color)
	RenderingServer.canvas_item_add_rect(item, Rect2(rect.position.x, rect.end.y - width, rect.size.x, width), color)
	RenderingServer.canvas_item_add_rect(item, Rect2(rect.position.x, rect.position.y + width, width, rect.size.y - 2.0 * width), color)
	RenderingServer.canvas_item_add_rect(item, Rect2(rect.end.x - width, rect.position.y + width, width, rect.size.y - 2.0 * width), color)


func _draw_diamond(item: RID, center: Vector2) -> void:
	var r := corner_radius
	var points := PackedVector2Array([center + Vector2(0, -r), center + Vector2(r, 0),
		center + Vector2(0, r), center + Vector2(-r, 0)])
	RenderingServer.canvas_item_add_polygon(item, points, PackedColorArray([corner_color]))
	var outline := points.duplicate()
	outline.append(points[0])
	RenderingServer.canvas_item_add_polyline(item, outline, PackedColorArray([border_color]), 1.0, true)
