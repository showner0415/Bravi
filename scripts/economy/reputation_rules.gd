class_name ReputationRules
extends Resource
## 평판의 규칙. 전부 임시다(계획 010).
## 평판은 정수 점수 하나이고 별로 읽는다. 맡은 의뢰의 정산 때 움직이고, 별 수가 그날 오는 손님의 수를 바꾼다.
## 함수는 전부 순수 함수다(상태는 DayState가 가진다).

## 정산의 항목 이름. 정산 화면이 그대로 보여 준다.
const ITEM_ACCEPT_GOOD := "어려운 사람의 일을 맡았다"
const ITEM_ACCEPT_BAD := "궂은일을 맡았다"
const ITEM_SUCCESS := "해냈다"
const ITEM_PERFECT := "흠 없이"
const ITEM_FAIL := "해내지 못했다"

## 거짓이면 평판이 없다(움직이지 않고, 보이지 않고, 손님 줄은 늘 기준이다).
@export var enabled := true
## 하루 플레이를 시작할 때의 평판.
@export var start := 9
@export var min_value := 0
@export var max_value := 20
## 별이 하나씩 오르는 점수. 오름차순이다. 별의 수는 1 + (점수 이하인 문턱의 수)다.
@export var star_thresholds := PackedInt32Array([4, 8, 12, 16])
## 별 1부터의 손님 수 증감. 칸이 없는 별은 0이다. 전부 0이면 대가가 없다(평판은 보이기만 한다).
@export var guest_delta := PackedInt32Array([-2, -1, 0, 1, 2])
## 흠 없이(충족도 100) 해냈을 때의 덤. 해냈을 때의 값이 0보다 큰 의뢰에만 붙는다.
@export var perfect_bonus := 1


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


## 정산의 항목. [이름, 값]의 목록이고 값이 0인 항목은 내지 않는다.
## effect는 의뢰의 reputation_effect다(키가 없으면 0, 값은 정수로 읽는다).
## - 맡은 값(accept): 결과와 상관없이.
## - 해냈다(success): 충족도가 팁 문턱을 넘었다. 흠 없이(100)면 덤이 붙는다(success가 0보다 클 때만).
## - 해내지 못했다(fail): 충족도 0.
func settle_items(effect: Dictionary, score: int, tip_floor: int) -> Array:
	var items: Array = []
	var accept := int(effect.get("accept", 0))
	var success := int(effect.get("success", 0))
	var fail := int(effect.get("fail", 0))
	if accept != 0:
		items.append([ITEM_ACCEPT_GOOD if accept > 0 else ITEM_ACCEPT_BAD, accept])
	if score > tip_floor:
		if success != 0:
			items.append([ITEM_SUCCESS, success])
		if score >= 100 and success > 0 and perfect_bonus != 0:
			items.append([ITEM_PERFECT, perfect_bonus])
	elif score <= 0 and fail != 0:
		items.append([ITEM_FAIL, fail])
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
