@tool
extends StyleBox
## 필사본 패널(결정 312 나): 칠 → 결 → 바깥 테두리 → 안쪽 가는 선 → 네 모서리 마름모. 값이 0인 몫은 그리지 않는다(벽은 칠과 결만).

const PaperGrain := preload("res://scripts/ui/paper_grain.gd")
const PaintedPatch := preload("res://scripts/ui/painted_patch.gd")
const WornEdge := preload("res://scripts/ui/worn_edge.gd")
const WEAR_LINE_WIDTH := 1.5

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
@export_group("그린 질감 (계획 033b)")
## 비면 칠·결로 그린다. 있으면 그 그림의 한 곳을 잘라 깐다.
@export var paper: Texture2D
## 비면 테두리·안쪽 선·마름모를 코드로 그린다. 있으면 9조각(가운데는 비운다).
@export var frame: Texture2D
## 짧은 변이 `frame_small_below` 아래인 작은 판의 테두리(바깥 선만. 판 U2-2). 비면 `frame`.
@export var frame_small: Texture2D
@export var frame_small_below := 160.0
## 9조각의 조각 크기(화면 화소).
@export var frame_margin := 24.0
## 테두리의 원본 화소 수 = 화면 1.
@export var density := 1.5
## 테두리 가장자리의 늘이기 방식, 두 축에 같이(R5의 값 하나).
@export var frame_axis := RenderingServer.NINE_PATCH_TILE_FIT
@export_group("헤진 가장자리 (계획 033b, 결정 498)")
## 0이면 깎지 않는다(033·그림 길 그대로). 1 적게 · 2 보통 · 3 많이.
@export var wear := 0
## 짧은 변이 이보다 짧은 판은 깎지 않는다.
@export var wear_min_side := 160.0
@export var wear_seed := 0
@export var wear_edge_color := Color("8C7354", 0.7)


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	if paper != null or frame != null:
		_draw_painted(to_canvas_item, rect)
		return
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


# 종이와 테두리는 따로 비울 수 있다(결정 489). 한쪽만 그림이면 다른 쪽은 033의 코드 그리기를 그대로 쓴다.
func _draw_painted(item: RID, rect: Rect2) -> void:
	if wear > 0 and paper != null and frame != null and minf(rect.size.x, rect.size.y) >= wear_min_side:
		_draw_worn(item, rect)
		return
	if paper != null:
		PaintedPatch.draw_paper(item, rect, paper, paper.get_width() / 1280.0, Color.WHITE)
	else:
		if fill_color.a > 0.0:
			RenderingServer.canvas_item_add_rect(item, rect, fill_color)
		if grain > 0.0:
			_draw_grain(item, rect)
	if frame != null:
		var m := frame_margin * density
		PaintedPatch.draw_nine_patch(item, rect, _frame_for(rect), Vector4(m, m, m, m), density,
			frame_axis, frame_axis, Color.WHITE, false)
		return
	if border_width > 0.0:
		_draw_frame(item, rect, border_width, border_color)
	if inner_width > 0.0:
		var inner := rect.grow(-inner_inset)
		_draw_frame(item, inner, inner_width, inner_color)
		if corner_radius > 0.0:
			for corner in [inner.position, Vector2(inner.end.x, inner.position.y),
					Vector2(inner.position.x, inner.end.y), inner.end]:
				_draw_diamond(item, corner)


func _frame_for(rect: Rect2) -> Texture2D:
	if frame_small != null and minf(rect.size.x, rect.size.y) < frame_small_below:
		return frame_small
	return frame


# 씨앗은 크기·형제 순서·단계·wear_seed뿐이다: 화면 위치를 쓰면 판이 움직일 때 찢김이 떨린다(결정 498).
func _draw_worn(item: RID, rect: Rect2) -> void:
	var drawn := get_current_item_drawn()
	var index := drawn.get_index() if drawn != null else 0
	var outline := WornEdge.outline(rect.size, index, wear, wear_seed)
	PaintedPatch.draw_paper_clipped(item, rect, paper, paper.get_width() / 1280.0, Color.WHITE, outline)
	var m := frame_margin * density
	PaintedPatch.draw_nine_patch_clipped(item, rect, _frame_for(rect), Vector4(m, m, m, m), density,
		frame_axis, frame_axis, Color.WHITE, outline)
	for cut in WornEdge.cuts(rect.size, index, wear, wear_seed):
		PaintedPatch.draw_edge_line(item, rect.position, cut["points"], wear_edge_color, WEAR_LINE_WIDTH)


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
