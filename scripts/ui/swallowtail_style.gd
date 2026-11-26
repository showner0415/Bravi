@tool
extends StyleBox
## 필사본 버튼(결정 312 다): 견본 `UI.b.button`의 제비꼬리 띠. 누름은 `sink`만큼 내려앉는다.

const PaintedPatch := preload("res://scripts/ui/painted_patch.gd")

@export var fill_color := Color("E9D8B4")
@export var border_color := Color("3B2A1E")
@export var border_width := 2.5
@export var notch_max := 12.0
@export var notch_ratio := 0.28
@export var inner_inset := 5.0
@export var inner_alpha := 0.7
@export var sink := 0.0
@export_group("그린 질감 (계획 033b)")
## 비면 033의 코드 그리기. 있으면 `sink`만큼 내린 사각형에 9조각.
@export var texture: Texture2D
## 9조각의 좌우 조각(화면 화소).
@export var cap := 16.0
## 9조각의 위아래 조각(화면 화소).
@export var band := 8.0
@export var density := 1.5
## 상태의 칠은 곱하는 색으로 바꾼다(결정 492). 못 누름은 알파로 비친다.
@export var tint := Color.WHITE
## 두 축 모두 늘이기: 세로 되풀이는 제비꼬리 홈이 W가 된다(결정 490).
@export var axis_x := RenderingServer.NINE_PATCH_STRETCH
@export var axis_y := RenderingServer.NINE_PATCH_STRETCH


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	if texture != null:
		PaintedPatch.draw_nine_patch(to_canvas_item, Rect2(rect.position + Vector2(0, sink), rect.size),
			texture, Vector4(cap * density, band * density, cap * density, band * density), density,
			axis_x, axis_y, tint)
		return
	var r := Rect2(rect.position + Vector2(0, sink), rect.size)
	var n := minf(notch_max, r.size.y * notch_ratio)
	var x := r.position.x
	var y := r.position.y
	var w := r.size.x
	var h := r.size.y
	var points := PackedVector2Array([Vector2(x, y), Vector2(x + w, y), Vector2(x + w - n, y + h / 2.0),
		Vector2(x + w, y + h), Vector2(x, y + h), Vector2(x + n, y + h / 2.0)])
	RenderingServer.canvas_item_add_polygon(to_canvas_item, points, PackedColorArray([fill_color]))
	# 견본은 둥근 이음(stroke-linejoin round)이다. 변마다 선을 긋고 꼭짓점에 원을 얹는다.
	for i in points.size():
		var a := points[i]
		var b := points[(i + 1) % points.size()]
		RenderingServer.canvas_item_add_line(to_canvas_item, a, b, border_color, border_width, true)
		RenderingServer.canvas_item_add_circle(to_canvas_item, a, border_width / 2.0, border_color)
	var inner := Color(border_color, border_color.a * inner_alpha)
	var left := x + n + 6.0
	var right := x + w - n - 6.0
	if right > left:
		RenderingServer.canvas_item_add_line(to_canvas_item, Vector2(left, y + inner_inset),
			Vector2(right, y + inner_inset), inner, 1.0, true)
		RenderingServer.canvas_item_add_line(to_canvas_item, Vector2(left, y + h - inner_inset),
			Vector2(right, y + h - inner_inset), inner, 1.0, true)
