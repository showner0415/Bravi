class_name HabitData
extends Resource
## 상대의 버릇 하나. 트리거가 채워지면 다음 공격이 response로 바뀐다.

## 1단계는 BLOCKED_STREAK만 구현한다. 끝에만 추가한다.
enum Trigger { BLOCKED_STREAK }

@export var trigger: Trigger = Trigger.BLOCKED_STREAK
## BLOCKED_STREAK: 공격이 연속으로 이만큼 막히면 발동한다.
@export var count := 3
## 발동했을 때 나가는 공격.
@export var response: AttackData
## 사람이 읽는 설명(대사 힌트, 디버그 표시).
@export_multiline var description := ""
