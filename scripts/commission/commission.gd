class_name Commission
extends Resource
## 의뢰 하나. CLAUDE.md 4장의 필드를 그대로 따른다.

@export var client_name := ""
## 의뢰인의 사연 대사. 상대 버릇의 힌트를 담는다.
@export_multiline var dialogue := ""
@export var opponent: OpponentData
@export var conditions: Array[CommissionCondition] = []
@export var base_reward := 0
@export var tip_max := 0
## 평판 변화. 키: "accept", "success", "fail".
@export var reputation_effect := {"accept": 0, "success": 0, "fail": 0}


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
