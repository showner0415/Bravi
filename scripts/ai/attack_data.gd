class_name AttackData
extends Resource
## 상대의 공격 하나.

@export var attack_name := "공격"
## 들어오는 방향(화면 기준). 플레이어는 이 방향으로 막아야 한다.
@export var direction: DuelTypes.Direction = DuelTypes.Direction.CENTER
## 예비 동작 시간(초). 끝나는 시각이 타격 순간이다.
@export var tell_time := 0.7
## 막혔을 때의 회수 시간(초). 0이면 막아도 빈틈이 없다.
@export var recovery_time := 0.0
## 일반 공격 목록에서 뽑힐 가중치.
@export var weight := 1.0
## 큰 공격(버릇 반응 등). 표시를 더 과장한다.
@export var is_big := false
## 표시된 공격: 예비 동작이 시작된 뒤에 올린 막기(또는 패리)만 받아낸다.
## 그 전부터 들고만 있던 막기는 버티기만 한다(막힘이지만 빈틈이 없다).
@export var needs_raised_guard := false

@export_group("포즈 (바이블 15절)")
## 예비 동작에 들어선 포즈.
@export var tell_pose: PoseData
## 멈칫(hold)의 팔 각. 나머지는 tell_pose 그대로다. 규칙(8°)으로 셈하지 않고 표의 값을 적는다(결정 257).
@export var hold_arm_deg := 0.0
## 타격 순간의 포즈.
@export var strike_pose: PoseData
## 회수 끝의 팔 각. 나머지는 strike_pose 그대로다.
@export var recover_arm_deg := 0.0
## 예비 동작 동안의 색.
@export var pose_color := Color(1.0, 0.85, 0.2)
