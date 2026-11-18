class_name HabitData
extends Resource
## 상대의 버릇 하나. 트리거가 채워지면 다음 공격이 response로 바뀐다.

## 1단계는 BLOCKED_STREAK만 구현한다. 끝에만 추가한다.
enum Trigger { BLOCKED_STREAK }

@export var trigger: Trigger = Trigger.BLOCKED_STREAK
## BLOCKED_STREAK: 공격이 연속으로 이만큼 막히면 발동한다.
@export var count := 3
## BLOCKED_STREAK: 참이면 상대가 스침당할 때(자세가 남은 채 닿을 때) 연속 막힘이 0으로 돌아간다.
## 받아칠 때마다 박자가 처음부터 다시 세어진다.
@export var reset_on_touched := false
## 발동했을 때 나가는 공격.
@export var response: AttackData
## 사람이 읽는 설명(대사 힌트, 디버그 표시).
@export_multiline var description := ""
