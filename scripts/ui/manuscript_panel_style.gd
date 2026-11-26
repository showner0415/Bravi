@tool
extends StyleBox
## 필사본 패널(결정 312 나): 칠 → 결 → 바깥 테두리 → 안쪽 가는 선 → 네 모서리 마름모. 값이 0인 몫은 그리지 않는다(벽은 칠과 결만).

const PaperGrain := preload("res://scripts/ui/paper_grain.gd")
const PaintedPatch := preload("res://scripts/ui/painted_patch.gd")
const WornEdge := preload("res://scripts/ui/worn_edge.gd")
const WEAR_LINE_WIDTH := 1.5
const STYLE_PATH := "res://scripts/ui/manuscript_panel_style.gd"

static var _screens := {}

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
		var worn_seed := worn_seed_of(get_current_item_drawn())
		if worn_seed >= 0:
			_draw_worn(item, rect, worn_seed)
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


# 씨앗은 크기·단계·wear_seed·판의 이름 해시뿐이다: 화면 위치·형제 순서를 쓰면 판이 움직일 때 찢김이 떨린다(결정 498).
func _draw_worn(item: RID, rect: Rect2, name_seed: int) -> void:
	var outline := WornEdge.outline(rect.size, wear, wear_seed + name_seed)
	PaintedPatch.draw_paper_clipped(item, rect, paper, paper.get_width() / 1280.0, Color.WHITE, outline)
	var m := frame_margin * density
	PaintedPatch.draw_nine_patch_clipped(item, rect, _frame_for(rect), Vector4(m, m, m, m), density,
		frame_axis, frame_axis, Color.WHITE, outline)
	for cut in WornEdge.cuts(rect.size, wear, wear_seed + name_seed):
		PaintedPatch.draw_edge_line(item, rect.position, cut["points"], wear_edge_color, WEAR_LINE_WIDTH)


# ---- 어느 판이 헤지는가(결정 498, 판 U2-3): 화면(장면)의 UI 창 가운데 30%를 판의 고정된 이름으로 고른다.

## 헤질 판이면 그 판의 이름 씨앗(0 이상), 깨끗하면 -1.
static func worn_seed_of(control: Node) -> int:
	if not (control is PanelContainer) or (control as Control).has_theme_stylebox_override("panel"):
		return -1
	var root := screen_root(control)
	if root == null:
		return -1
	var pname := panel_name(root, control)
	return WornEdge.hash_int("s:" + pname) if quota(root)["worn"].has(pname) else -1


## 화면의 뿌리: 표시한 노드(`wear_screen` 메타. 찍기 도구가 장면을 얹을 때) → 현재 장면 → 가장 위의 장면 파일 노드.
static func screen_root(control: Node) -> Node:
	var tree := control.get_tree()
	var current: Node = tree.current_scene if tree != null else null
	var top: Node = null
	var found_current := false
	var n := control
	while n != null:
		if n.has_meta("wear_screen"):
			return n
		if n == current:
			found_current = true
		if n.scene_file_path != "":
			top = n
		n = n.get_parent()
	return current if found_current else top


## 판의 고정된 이름: 장면 파일 + 뿌리에서 그 판까지의 경로 (+ 메타 `wear_key`). 화면 위치·크기·형제 순서는 쓰지 않는다.
static func panel_name(root: Node, control: Node) -> String:
	var parts := PackedStringArray()
	var n := control
	while n != null and n != root:
		parts.append(_step_name(n))
		n = n.get_parent()
	parts.reverse()
	return "%s|%s|%s" % [root.scene_file_path, "/".join(parts), str(control.get_meta("wear_key", ""))]


# 자동 이름(@로 시작)의 번호는 실행 전체에서 쌓이는 전역 번호라 장면을 다시 만들면 바뀐다: 같은 부모 아래 같은 클래스 형제 가운데 차례로 바꾼다.
static func _step_name(node: Node) -> String:
	var node_name := String(node.name)
	if not node_name.begins_with("@"):
		return node_name
	var order := 0
	var parent := node.get_parent()
	if parent != null:
		for sibling in parent.get_children():
			if sibling == node:
				break
			if sibling.get_class() == node.get_class():
				order += 1
	return "%s#%d" % [node.get_class(), order]


## {"n": UI 창 수, "k": 몫, "worn": {이름: true}}. 한 프레임에 한 번만 훑는다(같은 상태면 같은 결과).
static func quota(root: Node) -> Dictionary:
	var id := root.get_instance_id()
	var frame := Engine.get_frames_drawn()
	var entry = _screens.get(id)
	if entry != null and entry["frame"] == frame:
		return entry
	var ids := PackedStringArray()
	var eligible: Array[bool] = []
	_collect(root, root, ids, eligible)
	var key := root.scene_file_path if root.scene_file_path != "" else str(root.name)
	var worn := {}
	for i in WornEdge.pick(ids, eligible, key):
		worn[ids[i]] = true
	entry = {"frame": frame, "n": ids.size(), "k": int(floor(WornEdge.SHARE * ids.size() + WornEdge.hash01(key))), "worn": worn}
	if _screens.size() > 32:
		for stale in _screens.keys():
			if not is_instance_valid(instance_from_id(stale)):
				_screens.erase(stale)
	_screens[id] = entry
	return entry


static func _collect(root: Node, node: Node, ids: PackedStringArray, eligible: Array[bool]) -> void:
	if node is CanvasItem and not (node as CanvasItem).visible:
		return
	if node is PanelContainer or node is Panel:
		var c := node as Control
		if not c.has_theme_stylebox_override("panel"):
			var sb := c.get_theme_stylebox("panel")
			if sb != null and sb.get_script() != null and (sb.get_script() as Script).resource_path == STYLE_PATH:
				ids.append(panel_name(root, node))
				eligible.append(node is PanelContainer and int(sb.get("wear")) > 0 and sb.get("paper") != null
					and sb.get("frame") != null and minf(c.size.x, c.size.y) >= float(sb.get("wear_min_side")))
	for child in node.get_children():
		_collect(root, child, ids, eligible)


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
