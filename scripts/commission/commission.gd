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
