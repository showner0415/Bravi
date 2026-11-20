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
## 의뢰인의 한마디 둘. 선택이다(비어 있으면 그 줄이 없을 때의 동작이다).
## 해냈을 때: 정산에서 충족도가 팁 문턱을 넘으면 공통 문구 대신 나온다.
## 흠 없이 해냈다고 단정하지 않는다(문턱과 100 사이의 점수에서도 나온다).
@export_multiline var success_line := ""
## 돌려보냈을 때: 다음 화면(다음 손님의 카운터 또는 폐점)의 흐린 한 줄로 나온다.
@export_multiline var decline_line := ""


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
