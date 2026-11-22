extends RefCounted
## T74: 내 손 그림(계획 032). 손이 칼 뒤에 있고, 칼의 선, 어느 조준·상태에서도 소매 끝이 화면 밖, 비우면 자리 표시.

const DT := preload("res://scripts/duel/duel_types.gd")
const DUEL_PATH := "res://scenes/duel/duel.tscn"
const VIEW_PATH := "res://scenes/duel/player_sword_view.tscn"
const SCREEN := Vector2(1280, 720)
## 결정 305: 텍스처의 아래 두 모서리가 화면 아래 끝보다 이만큼 더 아래.
const SLEEVE_MARGIN := 8.0

var _tree: SceneTree


func list(tree: SceneTree) -> Array:
	_tree = tree
	return [
		{"id": "T74", "name": "내 손 그림: 칼 뒤의 손, 칼의 선, 소매 끝이 화면 밖(36경우), 비우면 자리 표시", "fn": t74_hand},
	]


func cleanup() -> void:
	_tree = null


func t74_hand() -> String:
	var errs: Array[String] = []
	var duel: Node = (load(DUEL_PATH) as PackedScene).instantiate()
	duel.set("mouse_aim_enabled", false)
	duel.set("rng_seed", 1)
	_tree.root.add_child(duel)
	var core: DuelCore = duel.get("core")
	var view := duel.get_node("PlayerSwordView") as PlayerSwordView
	var art := view.get_node("HandArt") as Sprite2D
	var sword := view.get_node("Sword") as Polygon2D
	if view.hand_art == null or not art.visible or art.texture != view.hand_art.texture:
		errs.append("HandArt가 보이지 않거나 텍스처가 hand_art와 다름")
	if art.get_index() >= sword.get_index():
		errs.append("HandArt가 Sword 앞(뒤에 그려짐)이 아님: %d, %d" % [art.get_index(), sword.get_index()])
	if (view.get_node("Hand") as CanvasItem).visible or (view.get_node("Label") as CanvasItem).visible:
		errs.append("그림이 있는데 Hand·Label이 보임")
	var outline := sword.get_node_or_null("Outline") as Line2D
	var warning := sword.get_node("BindWarning") as Line2D
	if outline == null or outline.points != sword.polygon or not is_equal_approx(outline.width, PlayerSwordView.OUTLINE_WIDTH):
		errs.append("Sword/Outline이 없거나 점·폭이 다름")
	if warning.width <= PlayerSwordView.OUTLINE_WIDTH:
		errs.append("엉킴 경고 폭 %.1f가 칼 선보다 넓지 않음" % warning.width)
	_check_sleeve(core, view, art, errs)
	duel.free()
	var bare: Node = (load(VIEW_PATH) as PackedScene).instantiate()
	bare.set("hand_art", null)
	_tree.root.add_child(bare)
	if not (bare.get_node("Hand") as CanvasItem).visible or not (bare.get_node("Label") as CanvasItem).visible \
			or (bare.get_node("HandArt") as CanvasItem).visible:
		errs.append("hand_art를 비웠는데 자리 표시가 보이지 않거나 HandArt가 보임")
	bare.free()
	return "OK" if errs.is_empty() else ", ".join(errs)


## 방향 3 × 높이 3 × 상태 넷(준비, 예비 동작의 끝, 회수의 처음, 막기). 상태는 코어의 필드를 직접 놓는다(판정 코드는 부르지 않는다).
func _check_sleeve(core: DuelCore, view: PlayerSwordView, art: Sprite2D, errs: Array[String]) -> void:
	var size := art.texture.get_size()
	var corners := [art.offset + Vector2(0, size.y), art.offset + size]
	# [이름, 상태, 표시 시각]
	var states := [["준비", DT.PlayerState.READY, 1.0], ["예비 동작 끝", DT.PlayerState.WINDUP, 1.0],
		["회수 처음", DT.PlayerState.RECOVER, 0.0], ["막기", DT.PlayerState.GUARD, 1.0]]
	var lowest := INF
	for dir in [DT.Direction.LEFT, DT.Direction.CENTER, DT.Direction.RIGHT]:
		for hgt in [DT.Height.HIGH, DT.Height.MID, DT.Height.LOW]:
			for st: Array in states:
				core.player_state = st[1]
				core.player_state_start = 0.0
				core.player_state_end = 1.0
				core.aim_direction = dir
				core.aim_height = hgt
				core.attack_direction = dir
				core.attack_height = hgt
				view.setup()
				view.update_view(core, st[2], SCREEN, 1.0)
				var xf := art.get_global_transform()
				for c: Vector2 in corners:
					var y := (xf * c).y
					lowest = minf(lowest, y)
					if y < SCREEN.y + SLEEVE_MARGIN:
						errs.append("소매 끝이 화면 안: 방향 %d 높이 %d %s, 모서리 y %.1f" % [dir, hgt, st[0], y])
	if errs.is_empty():
		print("  INFO T74 소매 모서리의 가장 높은 y %.1f (기대 728.1)" % lowest)
