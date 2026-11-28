class_name CoverMarks
extends Node2D
## 송곳 가림의 표지(계획 053 결정 831): 가린 세로줄의 두 가장자리와 위 끝의 송곳 꼭지.
## 첫 예비 동작부터 끝 타격의 판정까지는 점선(예고), 빈틈 동안에는 실선과 빗금(걸림). 모양은 정적 함수 cover_marks_of 하나로 정한다.

const COVER_COLOR := Color(0.80, 0.84, 0.90)
const COVER_EDGE := Color(0.20, 0.12, 0.08)
const COVER_TELL_WIDTH := 3.0
const COVER_TELL_ALPHA := 0.55
const COVER_LIVE_WIDTH := 4.0
const COVER_LIVE_ALPHA := 0.9
const COVER_HATCH_ALPHA := 0.10
const COVER_HATCH_GAP := 36.0
const COVER_TIP_SIZE := Vector2(14.0, 34.0)
## 왼쪽 위 HUD 판(바닥 156)보다 아래다.
const COVER_TIP_Y := 166.0
const COVER_DASH := 14.0

var core: DuelCore


## {"columns": Array[int], "live": bool}. 가림이 없으면 빈 사전이다.
static func cover_marks_of(p_core: DuelCore) -> Dictionary:
	if p_core == null or p_core.ended:
		return {}
	var brain := p_core.brain
	if brain.state == DuelTypes.OpponentState.TELL:
		var root: AttackData = brain.pattern_root if brain.pattern_root != null else brain.current_attack
		if root != null and not root.cover_columns.is_empty():
			return {"columns": root.cover_columns.duplicate(), "live": false}
		return {}
	if p_core.spike_live():
		return {"columns": p_core.covered_dirs.duplicate(), "live": true}
	return {}


func _draw() -> void:
	var marks := cover_marks_of(core)
	if marks.is_empty():
		return
	var size := get_viewport_rect().size
	var col_w := size.x / 3.0
	var live: bool = marks["live"]
	var width := COVER_LIVE_WIDTH if live else COVER_TELL_WIDTH
	var line_color := Color(COVER_COLOR, COVER_LIVE_ALPHA if live else COVER_TELL_ALPHA)
	for column: int in marks["columns"]:
		var left := col_w * column + width * 0.5
		var right := col_w * (column + 1) - width * 0.5
		for x in [left, right]:
			if live:
				draw_line(Vector2(x, 0.0), Vector2(x, size.y), line_color, width)
			else:
				draw_dashed_line(Vector2(x, 0.0), Vector2(x, size.y), line_color, width, COVER_DASH)
		if live:
			_draw_hatch(Rect2(col_w * column, 0.0, col_w, size.y))
		_draw_tip(Vector2(col_w * (column + 0.5), COVER_TIP_Y))


func _draw_hatch(rect: Rect2) -> void:
	var color := Color(COVER_COLOR, COVER_HATCH_ALPHA)
	var offset := 0.0
	while offset < rect.size.x + rect.size.y:
		# 오른쪽 위로 올라가는 사선을 칸 안에 잘라 긋는다.
		var a := Vector2(rect.position.x + offset, rect.position.y)
		var b := Vector2(rect.position.x, rect.position.y + offset)
		if a.x > rect.end.x:
			a = Vector2(rect.end.x, rect.position.y + (a.x - rect.end.x))
		if b.y > rect.end.y:
			b = Vector2(rect.position.x + (b.y - rect.end.y), rect.end.y)
		if a.y <= rect.end.y and b.x <= rect.end.x:
			draw_line(a, b, color, 3.0)
		offset += COVER_HATCH_GAP


func _draw_tip(top_center: Vector2) -> void:
	var half := COVER_TIP_SIZE.x * 0.5
	var points := PackedVector2Array([
		top_center + Vector2(-half, 0.0), top_center + Vector2(half, 0.0), top_center + Vector2(0.0, COVER_TIP_SIZE.y),
	])
	draw_colored_polygon(points, COVER_COLOR)
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[0]]), COVER_EDGE, 2.0)
