class_name UpgradeData
extends Resource
## 업그레이드 하나. 효과는 하나다: 대상 규칙의 숫자 속성 하나에 양을 더한다.
## 기존 숫자 속성을 건드리는 업그레이드는 .tres만 더해서 만든다. 이름·값·양은 전부 임시다(계획 005).

## 효과가 닿는 규칙.
enum Target { ECONOMY, DUEL }
## 업그레이드의 갈래(CLAUDE.md 5장의 넷).
enum Branch { GEAR, TRAINING, INTERIOR, APPRENTICE }

## 겹치지 않는 이름. 가진 것은 이것으로 적는다.
@export var id: StringName
@export var display_name := ""
## 가게에 보이는 설명 한 줄.
@export var description := ""
@export var branch: Branch = Branch.INTERIOR
@export var price := 0

@export var target: Target = Target.ECONOMY
## 대상 규칙(EconomyRules 또는 DuelRules)의 숫자 속성 이름. 정수나 실수여야 한다.
@export var property: StringName
## 더할 양. 정수 속성에는 소수부가 없는 양만 쓴다.
@export var amount := 0.0


## 규칙 하나에 이 효과를 더한다. 그 속성이 없거나 숫자가 아니면 건너뛰고 경고를 남긴다.
func apply_to(rules: Resource) -> bool:
	var current: Variant = rules.get(property) if rules != null else null
	match typeof(current):
		TYPE_INT:
			rules.set(property, int(current) + int(amount))
		TYPE_FLOAT:
			rules.set(property, float(current) + amount)
		_:
			push_warning("업그레이드 %s: 대상 규칙에 숫자 속성 %s 이(가) 없다" % [id, property])
			return false
	return true


## 기본 규칙의 사본에 upgrades 가운데 대상이 p_target인 효과를 전부 더해 돌려준다. 기본 규칙은 고치지 않는다.
static func applied(base: Resource, p_target: Target, upgrades: Array[UpgradeData]) -> Resource:
	if base == null:
		return null
	var out := base.duplicate()
	for upgrade in upgrades:
		if upgrade != null and upgrade.target == p_target:
			upgrade.apply_to(out)
	return out
