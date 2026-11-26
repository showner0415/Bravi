extends RefCounted
## 화면 모드·창 크기의 셈(계획 S04, 결정 525). 정적 함수만 둔다. 창을 건드리는 API는 부르지 않는다: 테스트가 셈만 본다.

const MODES: Array = [&"windowed", &"fullscreen"]
const MODE_LABELS := {&"windowed": "창", &"fullscreen": "전체 화면"}
const STANDARD_SIZES: Array = [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1440), Vector2i(3840, 2160)]
const DEFAULT_SIZE := Vector2i(1280, 720)
## 창 테두리·제목 줄을 못 쟀을 때의 값(임시).
const DECOR_FALLBACK := Vector2i(16, 40)
## 창이 잠긴 실행(결정 531)의 본보기 모니터: 찍기의 장이 돌리는 모니터에 따라 달라지지 않게.
const LOCKED_USABLE := Vector2i(2560, 1400)
const LOCKED_DECOR := Vector2i(16, 40)
const MIN_WIDTH := 640
const MIN_SIZE := Vector2i(640, 360)
const MAX_WIDTH := 7680


static func base() -> Vector2i:
	return Vector2i(int(ProjectSettings.get_setting("display/window/size/viewport_width", 1280)),
			int(ProjectSettings.get_setting("display/window/size/viewport_height", 720)))


static func default_display() -> Dictionary:
	return {"mode": &"windowed", "size": DEFAULT_SIZE}


static func size_name(size: Vector2i) -> String:
	return "%d×%d" % [size.x, size.y]


## 정확히 16:9, 폭은 64의 배수, 640~7680. 표준 목록 밖이어도 이 꼴이면 읽는다.
static func is_valid_size(size: Vector2i) -> bool:
	return size.x * 9 == size.y * 16 and size.x % 64 == 0 and size.x >= MIN_WIDTH and size.x <= MAX_WIDTH


static func fits(size: Vector2i, usable: Vector2i, decor: Vector2i) -> bool:
	return size.x + decor.x <= usable.x and size.y + decor.y <= usable.y


## 표준 크기 가운데 들어가는 것. 하나도 없으면 들어가는 가장 큰 16:9 하나, 640×360도 안 들어가면 BASE 하나.
@warning_ignore("integer_division")
static func sizes_for(usable: Vector2i, decor: Vector2i) -> Array:
	var out := []
	for size in STANDARD_SIZES:
		if fits(size, usable, decor):
			out.append(size)
	if not out.is_empty():
		return out
	var avail := usable - decor
	var width := mini(avail.x, avail.y * 16 / 9) / 64 * 64
	if width < MIN_WIDTH:
		return [base()]
	return [Vector2i(width, width * 9 / 16)]


static func fit_size(want: Vector2i, usable: Vector2i, decor: Vector2i) -> Vector2i:
	if fits(want, usable, decor):
		return want
	return sizes_for(usable, decor).back()


## canvas_items · keep의 그림 자리: 배율은 작은 쪽, 가운데 정렬, 나머지는 띠.
static func content_rect(window: Vector2i) -> Rect2:
	var view := Vector2(base())
	var scale := minf(window.x / view.x, window.y / view.y)
	var size := view * scale
	return Rect2((Vector2(window) - size) / 2.0, size)


## 창 좌표 → 뷰포트 좌표(content_rect의 역).
static func to_viewport(point: Vector2, window: Vector2i) -> Vector2:
	var rect := content_rect(window)
	return (point - rect.position) / (rect.size.x / float(base().x))


## 전체 화면의 크기는 엔진이 모니터에 맞추므로 size는 창으로 돌아갈 때의 값이다.
static func plan(display: Dictionary, usable: Vector2i, decor: Vector2i) -> Dictionary:
	var want: Vector2i = display["size"]
	var fitted := fit_size(want, usable, decor)
	return {"mode": display["mode"], "size": fitted, "clamped": fitted != want}
