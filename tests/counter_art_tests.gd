extends RefCounted
## T77: 카운터 그림(계획 034). 의뢰인 그림의 자리·대신 서는 도형·이름 글, 배경 두 장과 층, 정산의 그림 경로.
## 화면에는 day를 직접 넣는다(GameSession 오토로드에 의존하지 않는다).

const Session := preload("res://scripts/game_session.gd")
const Ui := preload("res://scripts/day_ui.gd")
const ECONOMY_PATH := "res://data/economy_rules.tres"
## 판 X1에서 "맞다"를 받은 의뢰인(결정 354). 의뢰 파일 -> 그림 파일. 없는 의뢰는 도형이다.
const PORTRAITS := {
	"feather_cut.tres": "clara.png", "first_blood_usurer.tres": "vittorio.png", "first_blood.tres": "emilio.png",
	"throw_match.tres": "ines.png", "throw_bet.tres": "gasparo.png", "legs_only.tres": "orsola.png",
	"first_blood_poor.tres": "tomaso.png", "spar.tres": "agostino.png",
}
## 그림이 아직 없는 의뢰(도형이어야 한다). 그림이 오면 PORTRAITS로 옮긴다(BACKLOG 046-1).
const NO_PORTRAIT: Array[String] = ["court_beehive.tres", "noble_baker.tres"]
const PORTRAIT_DIR := "res://assets/art/clients/"
const PORTRAIT_SIZE := Vector2i(450, 675)
## 앞 띠 첫 행의 아홉 점이 짙은 선이어야 한다(T2: 의뢰인 위에 벽 줄이 얹히지 않는다).
const LINE_Y := 0.22

var _tree: SceneTree


func list(tree: SceneTree) -> Array:
	_tree = tree
	return [
		{"id": "T77", "name": "카운터 그림: 의뢰인 그림의 자리·대신 서는 도형·이름 글, 배경 두 장과 층, 정산의 그림 경로", "fn": t77_counter_art},
	]


func cleanup() -> void:
	_tree = null


func _spawn_screen(path: String, day: DayState) -> Node:
	var screen: Node = (load(path) as PackedScene).instantiate()
	screen.set("day", day)
	_tree.root.add_child(screen)
	return screen


func _day_with(commission: Commission) -> DayState:
	var data := DayData.new()
	var list_one: Array[Commission] = [commission]
	data.commissions = list_one
	return DayState.new(load(ECONOMY_PATH) as EconomyRules, data)


## 화면의 바로 아래 자식 가운데 이름이 node_name인 것, 또는 그 이름이 비면 첫 PanelContainer의 차례. 없으면 -1.
func _index(screen: Node, node_name: String) -> int:
	for child in screen.get_children():
		if node_name == "" and child is PanelContainer:
			return child.get_index()
		if node_name != "" and child.name == node_name:
			return child.get_index()
	return -1


func _expect_order(errs: Array[String], screen: Node, names: Array[String], label: String) -> void:
	var last := -1
	for node_name in names:
		var at := _index(screen, node_name)
		if at < 0 or at <= last:
			errs.append("%s: 층 %s의 차례 %d (앞의 것 %d)" % [label, node_name if node_name != "" else "첫 패널", at, last])
		last = at


## 그림이 있으면 Room·CounterFront, 없으면 들보와 나무 띠의 이름 없는 노드다. 그림이 있을 때만 층을 이름으로 본다.
func _art_on() -> bool:
	return ResourceLoader.exists(Ui.COUNTER_ROOM_PATH) and ResourceLoader.exists(Ui.COUNTER_FRONT_PATH)


func _check_client(errs: Array[String], screen: Node, commission: Commission, label: String) -> void:
	var client := screen.get_node_or_null("Client") as Control
	if client == null:
		errs.append("%s: Client가 없음" % label)
		return
	var portrait := client.get_node_or_null("Portrait") as TextureRect
	if commission.client_portrait != null:
		if portrait == null or portrait.texture != commission.client_portrait:
			errs.append("%s: Portrait가 없거나 그 의뢰의 그림이 아님" % label)
		elif not Rect2(portrait.position, portrait.size).is_equal_approx(Ui.CLIENT_ART_RECT):
			errs.append("%s: Portrait의 자리 %s (기대 %s)" % [label, Rect2(portrait.position, portrait.size), Ui.CLIENT_ART_RECT])
		if client.has_node("Body") or client.has_node("Head"):
			errs.append("%s: 그림이 있는데 도형이 남아 있음" % label)
	elif portrait != null or not client.has_node("Body") or not client.has_node("Head"):
		errs.append("%s: 그림이 없는데 도형이 아님" % label)
	if not Ui.all_text(client).contains(commission.client_name):
		errs.append("%s: 의뢰인 이름 글이 없음" % label)


func t77_counter_art() -> String:
	var errs: Array[String] = []
	var all: Array[Commission] = CommissionLibrary.load_all("res://data/commissions")
	all.append_array(CommissionLibrary.load_all("res://data/commissions/variants"))
	if all.size() != PORTRAITS.size() + NO_PORTRAIT.size():
		errs.append("의뢰 %d개 (기대 %d)" % [all.size(), PORTRAITS.size() + NO_PORTRAIT.size()])
	var art := _art_on()
	for commission in all:
		var file := commission.resource_path.get_file()
		var label := file.get_basename()
		# 1. 데이터: 맞다를 받은 의뢰인만 그림이 있고 450×675다.
		var want_path: String = PORTRAIT_DIR + String(PORTRAITS.get(file, "")) if PORTRAITS.has(file) else ""
		var got_path := commission.client_portrait.resource_path if commission.client_portrait != null else ""
		if got_path != want_path:
			errs.append("%s: 그림 %s (기대 %s)" % [label, got_path, want_path])
		elif commission.client_portrait != null and Vector2i(commission.client_portrait.get_size()) != PORTRAIT_SIZE:
			errs.append("%s: 그림 크기 %s" % [label, Vector2i(commission.client_portrait.get_size())])
		# 2. 카운터: 자리, 미끄러짐의 시작, 이름 글.
		var day := _day_with(commission)
		var counter := _spawn_screen(Session.COUNTER_PATH, day)
		_check_client(errs, counter, commission, label + " 카운터")
		var client := counter.get_node_or_null("Client") as Control
		var start_x: float = -Ui.CLIENT_ART_RECT.end.x if commission.client_portrait != null else -Ui.CLIENT_SIZE.x
		if client != null and not is_equal_approx(client.position.x, start_x):
			errs.append("%s: 연 직후 Client.x %.1f (기대 %.1f)" % [label, client.position.x, start_x])
		# 3. 층: 방 < 의뢰인 < 앞 띠 < 말풍선.
		if art:
			_expect_order(errs, counter, ["Room", "Client", "CounterFront", ""], label + " 카운터")
		counter.free()
		# 5. 정산: 결과의 그림 경로와 정산 화면의 그림.
		day.accept()
		var record := DuelRecord.new()
		record.ended = true
		record.end_reason = DuelTypes.EndReason.CONDITION
		day.finish_duel(record)
		if String(day.last_result().get("client_portrait", "?")) != got_path:
			errs.append("%s: 정산 결과의 client_portrait '%s' (기대 '%s')" % [label, day.last_result().get("client_portrait", "?"), got_path])
		var settlement := _spawn_screen(Session.SETTLEMENT_PATH, day)
		_check_client(errs, settlement, commission, label + " 정산")
		if art:
			_expect_order(errs, settlement, ["Room", "Client", "CounterFront", ""], label + " 정산")
		settlement.free()
		day.proceed()
		if day.phase == DayState.Phase.CLOSING and art and file == "first_blood.tres":
			var closing := _spawn_screen(Session.CLOSING_PATH, day)
			_expect_order(errs, closing, ["Room", "CounterFront", ""], "폐점")
			closing.free()
	# 4. 배경 두 장: 크기, 앞 띠의 자리와 높이, 앞 띠의 첫 행이 짙은 선.
	if not art:
		errs.append("배경 그림 %s·%s가 없음" % [Ui.COUNTER_ROOM_PATH, Ui.COUNTER_FRONT_PATH])
	else:
		var room := load(Ui.COUNTER_ROOM_PATH) as Texture2D
		var front := load(Ui.COUNTER_FRONT_PATH) as Texture2D
		var f := roundi(Ui.COUNTER_FRONT_Y * 1.5)
		if Vector2i(room.get_size()) != Vector2i(1920, 1080):
			errs.append("room.png 크기 %s" % Vector2i(room.get_size()))
		if Vector2i(front.get_size()) != Vector2i(1920, 1080 - f):
			errs.append("front.png 크기 %s (기대 1920×%d)" % [Vector2i(front.get_size()), 1080 - f])
		var image := front.get_image()
		if image != null:
			if image.is_compressed():
				image.decompress()
			for k in range(1, 10):
				var c := image.get_pixel(roundi(1920.0 * k / 10.0), 0)
				var y := 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
				if y >= LINE_Y:
					errs.append("front.png 첫 행 x %d의 Y %.3f (짙은 선이 아님)" % [roundi(1920.0 * k / 10.0), y])
		else:
			errs.append("front.png의 화소를 읽지 못함")
		var probe := Control.new()
		_tree.root.add_child(probe)
		Ui.add_counter_front(probe)
		var band := probe.get_node_or_null("CounterFront") as TextureRect
		if band == null or not is_equal_approx(band.position.y, Ui.COUNTER_FRONT_Y) or not is_equal_approx(band.position.y + band.size.y, 720.0):
			errs.append("CounterFront의 자리 %s" % (Rect2(band.position, band.size) if band != null else "없음"))
		probe.free()
	return "OK" if errs.is_empty() else ", ".join(errs)
