extends Control
## 폐점: 왼쪽은 오늘의 장부(의뢰, 수입과 지출, 손익), 오른쪽은 가게(업그레이드 구매).
## 다음 날을 열거나 처음 화면으로 돌아간다. 산 것의 효과는 다음 날부터 난다.

const Ui := preload("res://scripts/day_ui.gd")

const SHOP_HINT := "살 것이 있다 — 고르거나, 그냥 '다음 날을 연다'를 누른다"
const SAVED_NOTE := "저장했다 — 끄고 다시 켜도 %d일차 아침부터 이어진다"

## 하루 플레이의 상태. 비어 있으면 /root/GameSession의 것을 본다.
var day: DayState
## 화면에 내보인 오늘의 손익. shown이 거짓이면 내보인 것이 없다.
var shown_profit := 0
var shown := false
## 가게가 내보인 지금 소지금.
var shown_money := 0

var _proceed: Button
var _money_label: Label
var _hint: Label
## 평판과 내일의 손님(두 줄). 평판이 없으면 null이다. 글은 refresh_shop()이 채운다.
var _reputation_ledger: Label
## 가게의 버튼과 그 버튼의 업그레이드. 목록의 순서다.
## 처음에 한 번 만들고, 다시 그릴 때는 글과 disabled만 고친다.
var _buy_buttons: Array[Button] = []
var _buy_upgrades: Array[UpgradeData] = []


func _ready() -> void:
	var session := get_node_or_null(^"/root/GameSession")
	if day == null and session != null and session.get("day") is DayState:
		day = session.get("day")
	Ui.add_background(self)
	if day == null or day.phase != DayState.Phase.CLOSING or day.closing_summary().is_empty():
		day = null
		call_deferred("_return_to_title")
		return
	_build(day.closing_summary())


func _build(summary: Dictionary) -> void:
	var header := Ui.add_label(self, "%d일차 — 가게를 닫는다" % day.day_number, 30)
	header.name = "Header"
	header.position = Vector2(32, 20)
	# 마지막 손님을 돌려보내서 폐점에 왔으면 그 손님의 한마디.
	Ui.add_declined_line(self, day.last_declined, Rect2(420, 30, 828, 22))

	var book := Ui.add_panel(self, Rect2(32, 84, 600, 500), 8)
	Ui.add_label(book, "오늘의 의뢰", 20, Ui.DIM)
	if day.results.is_empty():
		Ui.add_label(book, "맡은 의뢰가 없다", 20)
	for result in day.results:
		var line := "%s — 충족도 %d · 기본 보수 %d · 팁 %d" % [
			result["client_name"], result["score"], result["base"], result["tip"]]
		if result["injured"]:
			line += " · 다침"
		Ui.add_label(book, line, 20)
	var declined: Array = summary.get("declined", [])
	if not declined.is_empty():
		# 이름이 여럿이면 장부보다 길다. 줄바꿈되는 글자로 둔다.
		var names := Ui.add_wrapped(book, "돌려보낸 손님: %s" % ", ".join(PackedStringArray(declined)), 17, Ui.DIM)
		names.name = "DeclinedNames"
	var missed := int(summary.get("missed", 0))
	if missed > 0:
		var missed_line := Ui.add_label(book, "만나지 못한 손님 %d명" % missed, 17, Ui.DIM)
		missed_line.name = "MissedLine"

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 10)
	book.add_child(gap)

	Ui.add_label(book, "수입   +%d" % summary["income"], 22)
	Ui.add_label(book, "임대료   -%d" % summary["rent"], 22)
	# 단가는 적지 않는다(결과마다 그때의 단가가 들어 있고, 날마다 달라질 수 있다).
	Ui.add_label(book, "치료비   -%d  (%d회)" % [summary["medical"], summary["injuries"]], 22)
	shown_profit = int(summary["profit"])
	shown = true
	var profit_text := "오늘의 손익   %s%d" % ["+" if shown_profit >= 0 else "", shown_profit]
	var profit := Ui.add_label(book, profit_text, 32, Ui.GOLD if shown_profit >= 0 else Ui.RED)
	profit.name = "Profit"
	Ui.add_label(book, "소지금   %d → %d" % [summary["money_before"], summary["money_after"]], 22)

	# 평판과 내일의 손님: 장부 패널 아래. 평판이 없는 하루면 만들지 않는다.
	if day.has_reputation() and summary.has("reputation"):
		_reputation_ledger = Ui.add_label(self, "", 16, Ui.GOLD)
		_reputation_ledger.name = "ReputationLedger"
		_reputation_ledger.position = Vector2(40, 585)
		_reputation_ledger.size = Vector2(600, 46)

	_build_shop()

	_hint = Ui.add_label(self, SHOP_HINT, 16, Ui.GOLD)
	_hint.name = "ShopHint"
	_hint.position = Vector2(656, 592)
	_hint.size = Vector2(592, 24)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	_proceed = Ui.add_button(self, "다음 날을 연다", 28, "Proceed")
	_proceed.position = Vector2(868, 622)
	_proceed.size = Vector2(380, 76)
	_proceed.pressed.connect(_next_day)

	var quit := Ui.add_button(self, "처음 화면으로", 18, "Quit")
	quit.position = Vector2(32, 638)
	quit.size = Vector2(220, 46)
	quit.pressed.connect(_quit)

	# 이 실행에서 내일의 아침을 적는 데 성공했을 때만 알린다(세션이 없거나 저장이 꺼져 있으면 없다).
	var session := get_node_or_null(^"/root/GameSession")
	if session != null and int(session.get("saved_day")) == day.day_number + 1:
		var saved_note := Ui.add_label(self, SAVED_NOTE % (day.day_number + 1), 16, Ui.DIM)
		saved_note.name = "SavedNote"
		saved_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		saved_note.position = Vector2(268, 650)
		saved_note.size = Vector2(590, 24)

	refresh_shop()


## 가게의 노드를 한 번 만든다. 글과 눌림 여부는 refresh_shop()이 채운다.
func _build_shop() -> void:
	var shop := Ui.add_panel(self, Rect2(656, 84, 592, 500), 6)
	Ui.add_label(shop, "살 것 — 효과는 내일부터", 20, Ui.DIM)
	if day.catalog != null:
		for upgrade in day.catalog.upgrades:
			if upgrade != null:
				_buy_upgrades.append(upgrade)
	if _buy_upgrades.is_empty():
		Ui.add_label(shop, "살 것이 없다", 20)
	for upgrade in _buy_upgrades:
		var button := Ui.add_button(shop, "", 22, "Buy_%s" % upgrade.id)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_buy.bind(upgrade))
		_buy_buttons.append(button)
		Ui.add_wrapped(shop, upgrade.description, 16, Ui.DIM)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 6)
	shop.add_child(gap)
	_money_label = Ui.add_label(shop, "", 22)
	_money_label.name = "Money"


## 가게를 지금의 day에 맞춰 다시 그린다. 노드를 새로 만들지 않고 글과 disabled만 고친다.
## (같은 프레임에 지운 노드는 트리에 남아, 같은 이름의 새 버튼이 다른 이름을 받는다.)
func refresh_shop() -> void:
	if day == null or _proceed == null:
		return
	for i in _buy_buttons.size():
		var upgrade := _buy_upgrades[i]
		var button := _buy_buttons[i]
		if day.owns(upgrade):
			button.text = "%s — 샀다" % upgrade.display_name
			button.add_theme_color_override("font_disabled_color", Ui.GOLD)
		else:
			button.text = "%s — 값 %d" % [upgrade.display_name, upgrade.price]
			button.remove_theme_color_override("font_disabled_color")
		button.disabled = not day.can_buy(upgrade)
	shown_money = day.money
	_money_label.text = "지금 소지금 %d" % shown_money
	# 내일의 손님 수는 살 때마다 다시 센다(결투 수를 올리는 것을 사면 아래 한계가 바뀐다).
	if _reputation_ledger != null:
		_reputation_ledger.text = reputation_ledger_text(day)

	# 살 것이 있으면 어떤 버튼에도 포커스를 두지 않는다(정산에서 넘어온 Space가 가게를 지나치지 않게).
	# 없으면 지금처럼 "다음 날을 연다"에 둔다.
	var buyable := day.has_buyable()
	_hint.visible = buyable
	if buyable:
		var focused := get_viewport().gui_get_focus_owner()
		if focused != null and is_ancestor_of(focused):
			get_viewport().gui_release_focus()
	else:
		_proceed.grab_focus()


## 폐점의 평판 두 줄:
##   "평판 20 → 37 · 별 3 → 4 · 38부터 별 5 — 손님 +1, 보수 +10% → +20%" / "내일의 손님 6명 (보통 5명) · 내일의 보수 +10%".
## 첫 줄의 뒤쪽은 다음 별이 되는 점수와 그때 달라지는 것이다. 손님 수는 차이로, 기본 보수는 지금 별의 비율에서
## 다음 별의 비율로 적는다. 달라지지 않는 쪽은 빼고, 별이 가득이면 "(별이 가득 찼다)"다.
## 둘째 줄의 괄호는 내일의 기준 손님 수가 있을 때만, 내일의 보수는 0이 아닐 때만 붙는다.
static func reputation_ledger_text(p_day: DayState) -> String:
	var rules := p_day.reputation_rules
	var before := int(p_day.closing_summary().get("reputation_start", p_day.reputation))
	var after := p_day.reputation
	var first := "평판 %d → %d" % [before, after] if before != after else "평판 %d — 그대로" % after
	var stars_before := rules.stars(before)
	var stars_after := rules.stars(after)
	first += " · 별 %d → %d" % [stars_before, stars_after] if stars_before != stars_after else " · 별 %d" % stars_after
	var to_next := rules.to_next_star(after)
	if to_next > 0:
		var next_star := stars_after + 1
		first += " · %d부터 별 %d" % [after + to_next, next_star]
		var guest_gain := rules.guest_change(next_star) - rules.guest_change(stars_after)
		var pay_now := rules.pay_change(stars_after)
		var pay_next := rules.pay_change(next_star)
		var changes: Array[String] = []
		if guest_gain != 0:
			changes.append("손님 %+d" % guest_gain)
		if pay_next != pay_now:
			changes.append("보수 %+d%% → %+d%%" % [pay_now, pay_next])
		if not changes.is_empty():
			first += " — " + ", ".join(PackedStringArray(changes))
	else:
		first += " (별이 가득 찼다)"
	var second := "내일의 손님 %d명" % p_day.tomorrow_guests()
	var base := p_day.tomorrow_base_guests()
	if base > 0:
		second += " (보통 %d명)" % base
	# 내일의 기본 보수 덧붙임은 지금 평판의 별이 정한다(내일을 시작할 때의 별이다).
	var tomorrow_pay := rules.pay_change(stars_after)
	if tomorrow_pay != 0:
		second += " · 내일의 보수 %+d%%" % tomorrow_pay
	return first + "\n" + second


## 눌리지 않는 버튼의 신호가 코드로 발사돼도 day가 거절하므로 아무것도 바뀌지 않는다.
func _buy(upgrade: UpgradeData) -> void:
	if day != null and day.buy(upgrade):
		_save_now()
		refresh_shop()


## 내일의 아침을 다시 적는다(산 뒤에는 소지금과 가진 것이 바뀌었다). 테스트가 붙인 화면에서는 적지 않는다.
func _save_now() -> void:
	var session := get_node_or_null(^"/root/GameSession")
	if session != null and is_inside_tree() and get_tree().current_scene == self:
		session.call("save_game")


func _next_day() -> void:
	if day == null or not day.next_day():
		return
	var session := get_node_or_null(^"/root/GameSession")
	if session != null and get_tree().current_scene == self:
		session.call("go_to_phase_scene")


func _quit() -> void:
	var session := get_node_or_null(^"/root/GameSession")
	if session == null or get_tree().current_scene != self:
		return
	session.call("end_day_play")
	session.call("go_to_title")


func _return_to_title() -> void:
	var session := get_node_or_null(^"/root/GameSession")
	if session != null and is_inside_tree() and get_tree().current_scene == self:
		session.call("go_to_title")
