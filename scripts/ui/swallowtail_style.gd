@tool
extends StyleBox
## 필사본 버튼(결정 312 다): 견본 `UI.b.button`의 제비꼬리 띠. 누름은 `sink`만큼 내려앉는다.

@export var fill_color := Color("E9D8B4")
@export var border_color := Color("3B2A1E")
@export var border_width := 2.5
@export var notch_max := 12.0
@export var notch_ratio := 0.28
@export var inner_inset := 5.0
@export var inner_alpha := 0.7
@export var sink := 0.0


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
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
