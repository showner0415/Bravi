class_name ReputationRules
extends Resource
## 평판의 규칙. 전부 임시다(계획 010, 수치는 011, 승리·날의 배율은 012, 기본 보수는 013).
## 평판은 정수 점수 하나이고 별로 읽는다. 맡은 의뢰의 정산 때 움직이고, 별 수가 그날 오는 손님의 수와 기본 보수를 바꾼다.
## 함수는 전부 순수 함수다(상태는 DayState가 가진다).
## 값은 data/reputation_rules.tres에 있다. 기본값은 그 파일과 같되 pay_percent·day_scale만 일부러 비워 둔다(그 필드의 주석).

## 정산의 항목 이름. 정산 화면이 그대로 보여 준다.
const ITEM_ACCEPT_GOOD := "어려운 사람의 일을 맡았다"
const ITEM_ACCEPT_BAD := "궂은일을 맡았다"
const ITEM_WIN := "이겼다"
const ITEM_SUCCESS := "해냈다"
const ITEM_PERFECT := "흠 없이"
const ITEM_FAIL := "해내지 못했다"

## 거짓이면 평판이 없다(움직이지 않고, 보이지 않고, 손님 줄은 늘 기준이다).
@export var enabled := true
## 하루 플레이를 시작할 때의 평판.
@export var start := 20
@export var min_value := 0
@export var max_value := 44
## 별이 하나씩 오르는 점수. 오름차순이다. 별의 수는 1 + (점수 이하인 문턱의 수)다.
@export var star_thresholds := PackedInt32Array([8, 16, 24, 38])
## 별 1부터의 손님 수 증감. 칸이 없는 별은 0이다. 전부 0이면 대가가 없다(평판은 보이기만 한다).
@export var guest_delta := PackedInt32Array([-2, -1, 0, 1, 2])
## 흠 없이(충족도 100) 해냈을 때의 덤. 해냈을 때의 값이 0보다 큰 의뢰에만 붙는다.
@export var perfect_bonus := 2
## 별 1부터의 기본 보수 덧붙임(%). 칸이 없는 별은 0이다. 비면 평판은 돈을 건드리지 않는다. 팁은 별과 상관없다.
## 기본값이 비어 있는 것은, 이 필드를 적지 않은 규칙(테스트가 만든 것)이 계획 011까지와 같이 움직이게 하려는 것이다.
@export var pay_percent := PackedInt32Array()
## 날마다 평판의 항목에 곱하는 배율(%). 1일차부터이고, 표가 끝나면 마지막 값을 계속 쓴다. 비면 100이다.
## 기본값이 비어 있는 까닭은 pay_percent와 같다.
@export var day_scale := PackedInt32Array()


## 범위로 자른 평판.
func clamp_value(value: int) -> int:
	return clampi(value, min_value, maxi(max_value, min_value))


## 그 점수의 별 수(1부터).
func stars(value: int) -> int:
	var count := 1
	for threshold in star_thresholds:
		if value >= threshold:
			count += 1
	return count


## 별의 최대 수.
func max_stars() -> int:
	return star_thresholds.size() + 1


## 다음 별까지 남은 점수. 별이 최대면 0.
func to_next_star(value: int) -> int:
	for threshold in star_thresholds:
		if value < threshold:
			return threshold - value
	return 0


## 그 별 수의 손님 수 증감.
func guest_change(star_count: int) -> int:
	var slot := star_count - 1
	if slot < 0 or slot >= guest_delta.size():
		return 0
	return guest_delta[slot]


## 그 별 수의 기본 보수 덧붙임(%).
func pay_change(star_count: int) -> int:
	var slot := star_count - 1
	if slot < 0 or slot >= pay_percent.size():
		return 0
	return pay_percent[slot]


## 그날(1부터)의 배율(%). 표가 비면 100, 표가 끝나면 마지막 값이다.
func scale_for_day(day_number: int) -> int:
	if day_scale.is_empty():
		return 100
	return day_scale[clampi(day_number - 1, 0, day_scale.size() - 1)]


## 값에 배율(%)을 곱한다. 크기를 0.5 올림으로 반올림하고 부호는 그대로 둔다.
## 0이 아닌 값의 크기는 1보다 작아지지 않는다. 배율 100이면 값 그대로다.
static func scaled(value: int, percent: int) -> int:
	if value == 0:
		return 0
	var p := maxi(percent, 1)
	@warning_ignore("integer_division")
	return signi(value) * maxi(1, (absi(value) * p * 2 + 100) / 200)


## 정산의 항목. [이름, 값]의 목록이고 값이 0인 항목은 내지 않는다(0인지는 배율을 곱하기 전의 값으로 본다).
## effect는 의뢰의 reputation_effect다(키가 없으면 0, 값은 정수로 읽는다).
## - 맡은 값(accept): 결과와 상관없이.
## - 이겼다(win): won이 참이고 충족도가 0보다 클 때. 0점인 판에는 붙지 않는다(해내지 못한 값을 지우지 않는다).
## - 해냈다(success): 충족도가 팁 문턱을 넘었다. 흠 없이(100)면 덤이 붙는다(success가 0보다 클 때만).
## - 해내지 못했다(fail): 충족도 0.
## 다섯 항목 모두에 그날의 배율(scale_percent)을 곱한다. 0이 아닌 값의 크기는 1보다 작아지지 않는다.
func settle_items(effect: Dictionary, score: int, tip_floor: int, won := false, scale_percent := 100) -> Array:
	var items: Array = []
	var accept := int(effect.get("accept", 0))
	var success := int(effect.get("success", 0))
	var fail := int(effect.get("fail", 0))
	var win := int(effect.get("win", 0))
	if accept != 0:
		items.append([ITEM_ACCEPT_GOOD if accept > 0 else ITEM_ACCEPT_BAD, scaled(accept, scale_percent)])
	if won and score > 0 and win != 0:
		items.append([ITEM_WIN, scaled(win, scale_percent)])
	if score > tip_floor:
		if success != 0:
			items.append([ITEM_SUCCESS, scaled(success, scale_percent)])
		if score >= 100 and success > 0 and perfect_bonus != 0:
			items.append([ITEM_PERFECT, scaled(perfect_bonus, scale_percent)])
	elif score <= 0 and fail != 0:
		items.append([ITEM_FAIL, scaled(fail, scale_percent)])
	return items


## 항목의 값의 합.
static func items_total(items: Array) -> int:
	var total := 0
	for item: Array in items:
		total += int(item[1])
	return total


## 그날 오는 손님 수.
##   min(목록 길이, max(기준 손님 수 + 증감, min(기준 손님 수, 결투 수)))
## 기준 손님 수가 0 이하면 목록의 손님이 전부 온다(평판과 상관없다).
## 아래 한계(기준과 결투 수 가운데 작은 쪽)를 먼저 걸고 목록 길이를 맨 나중에 건다:
## 평판은 선택의 폭을 줄이지 결투를 빼앗지 않고, 없는 손님은 오지 않는다.
static func guest_count(list_size: int, base_guests: int, delta: int, duels: int) -> int:
	if base_guests <= 0:
		return list_size
	return mini(list_size, maxi(base_guests + delta, mini(base_guests, maxi(duels, 0))))
