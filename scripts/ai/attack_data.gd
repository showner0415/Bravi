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

@export_group("예비 동작 포즈 (임시 — 4단계에서 애니메이션 이름으로 대체)")
## 예비 동작 시작 때 팔(어깨 관절)의 위치. 가슴 중앙의 어깨 높이 기준(화면 좌표, 좌우 대칭).
@export var pose_arm_offset := Vector2.ZERO
## 예비 동작 시작 때 칼의 회전(도). 0은 칼끝이 위.
@export var pose_sword_rotation := 0.0
## 예비 동작 동안의 색.
@export var pose_color := Color(1.0, 0.85, 0.2)
