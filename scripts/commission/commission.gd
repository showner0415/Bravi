class_name Commission
extends Resource
## 의뢰 하나. CLAUDE.md 4장의 필드를 그대로 따른다.

@export var client_name := ""
## 의뢰인의 사연 대사. 상대 버릇의 힌트를 담는다.
@export_multiline var dialogue := ""
@export var opponent: OpponentData
## 이 의뢰의 결투에서 상대가 모자를 쓰는가. 모자는 상대의 고정 부위가 아니다.
## 참이면 조준 상단의 베기 두 칸이 모자에 걸린다. 모자를 노리는 조건을 가진 의뢰는 참이어야 한다.
@export var opponent_wears_hat := false
## 결투의 무대(결정 295). 비면 결투 씬의 기본 무대다. 표시만 하고 판정에 넘기지 않는다.
@export var stage: StageData
## 카운터와 정산에 서는 의뢰인 그림(결정 347). 비면 색 도형이다.
@export var client_portrait: Texture2D
## 상대의 자세 칸을 이 의뢰가 정한다(계획 043 결정 659). 0이면 상대 데이터 그대로다. 두 칸이 0이면 fit_opponent는 같은 객체를 돌려준다.
@export var opponent_posture_max := 0
@export var opponent_recover_posture := 0
@export var conditions: Array[CommissionCondition] = []
@export var base_reward := 0
@export var tip_max := 0
## 평판 변화. 맡은 의뢰의 정산 때 한 번 더해진다(ReputationRules.settle_items).
## "accept": 맡았으면 결과와 상관없이 / "success": 해냈을 때(충족도가 팁 문턱을 넘음) / "fail": 해내지 못했을 때(충족도 0).
## "win": 이겼을 때(유효타를 넣고 지지 않음. 충족도가 0보다 클 때만). 선택이고 없으면 0이다.
@export var reputation_effect := {"accept": 0, "success": 0, "fail": 0}
## 흥정("값을 올려 부른다")의 눈높이. 0이면 흥정할 수 없는 손님이다(버튼이 없다).
## 1~5면 지금 평판의 별에서 이 값을 뺀 차로 받아 줄 확률이 정해진다(EconomyRules.haggle_chance_for). 값이 낮을수록 잘 받아 준다.
@export var haggle_min_stars := 1
## 의뢰인의 한마디. 전부 선택이다(비어 있으면 그 줄이 없을 때의 동작이다).
## 해냈을 때: 정산에서 충족도가 팁 문턱을 넘으면 공통 문구 대신 나온다.
## 흠 없이 해냈다고 단정하지 않는다(문턱과 100 사이의 점수에서도 나온다).
@export_multiline var success_line := ""
## 돌려보냈을 때: 다음 화면(다음 손님의 카운터 또는 폐점)의 흐린 한 줄로 나온다.
@export_multiline var decline_line := ""
## 해내지 못했을 때(충족도 0)와 부탁대로는 아니었을 때(0보다 크고 팁 문턱 이하)의 한마디.
## 비어 있으면 정산의 공통 문구가 나온다. 그 구간이 될 수 있는 모든 판에서 참인 말만 쓴다
## (무엇이 0점이고 무엇이 문턱 이하인지는 조건이 정한다). 문턱 이하의 글은 팁을 말하지 않는다.
@export_multiline var fail_line := ""
@export_multiline var partial_line := ""
## 흥정의 대답 둘: 받아 줄 때와 거절할 때. 비어 있으면 카운터의 공통 문구가 나온다.
## 한 줄로 쓴다(줄바꿈되지 않는 자리다). 까닭(가게의 이름, 별)은 말하지 않는다.
@export var haggle_agree_line := ""
@export var haggle_refuse_line := ""


## 의뢰의 칸으로 상대의 자세를 맞춘다. 칸이 비면 받은 상대 그 객체다.
func fit_opponent(base: OpponentData) -> OpponentData:
	if base == null:
		return null
	return base.with_posture(opponent_posture_max, opponent_recover_posture)


## 조건 설명을 한 줄씩.
func describe() -> Array[String]:
	var lines: Array[String] = []
	for condition in conditions:
		if condition != null:
			lines.append(condition.describe())
	return lines


## 충족도 0~100. 조건이 여러 개면 평균이다. 종료된 record에 대해서만 의미가 있다.
func evaluate(record: DuelRecord) -> int:
	var total := 0
	var count := 0
	for condition in conditions:
		if condition != null:
			total += condition.evaluate(record)
			count += 1
	return roundi(float(total) / count) if count > 0 else 0


## 결과 화면의 항목별 내역(모든 조건의 것을 이어 붙인다).
func explain(record: DuelRecord) -> Array[String]:
	var lines: Array[String] = []
	for condition in conditions:
		if condition != null:
			lines.append_array(condition.explain(record))
	return lines


## 함께 와서 맞서는 다른 쪽(계획 047). 목록에 서는 의뢰에만 적는다(서로 가리키면 .tres 불러오기가 돈다 — 결정 749).
@export var partner: Commission
## 이 의뢰를 맡아 정산했을 때 남기는 플래그. 결과로 갈리지 않는다(결정 752).
@export var sets_flags := PackedStringArray()
## 이 플래그가 모두 있어야 하루의 목록에 선다.
@export var requires_flags := PackedStringArray()
## 이 플래그가 하나라도 있으면 목록에 서지 않는다.
@export var excluded_flags := PackedStringArray()


## 가진 플래그로 목록에 서는가(결정 752).
func allowed_by(flags: PackedStringArray) -> bool:
	for flag in requires_flags:
		if not flags.has(flag):
			return false
	for flag in excluded_flags:
		if flags.has(flag):
			return false
	return true
