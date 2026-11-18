class_name OpponentData
extends Resource
## 상대 한 명의 데이터. OpponentBrain은 이 값을 읽기만 하고 고치지 않는다.

@export var display_name := "상대"
## 칼 든 팔이 화면의 어느 쪽에 보이는가 (LEFT 또는 RIGHT).
@export var sword_side: DuelTypes.Direction = DuelTypes.Direction.LEFT

@export_group("자세")
## 자세 최대값. 스침당할 때마다 1 깎이고 0이 되면 무너진다.
@export var posture_max := 14
## 무너짐 시간(초). 이 동안 닿은 공격이 유효타다.
@export var stagger_time := 1.5
## 무너짐이 끝났을 때 돌아오는 자세.
@export var stagger_recover_posture := 4
## 섣부른 공격(빈틈이 아닐 때 낸 공격)을 받아넘겼을 때 돌아오는 자세. 0이면 대가가 없다.
@export var rash_attack_posture_gain := 1
## 밀착에서 맞았을 때 깎이는 내 자세 칸 수. 1이면 교전과 같다(1보다 작은 값은 1로 본다).
@export var close_hit_posture_loss := 1

@export_group("리듬")
## 공격 사이 대기 시간 범위(초).
@export var idle_time_min := 0.9
@export var idle_time_max := 1.6
## 멀리에서 대기 상태가 이만큼 이어지면 교전 거리로 들어온다(초).
@export var approach_delay := 1.5
## 패리당했을 때 회수 시간에 더하는 값(초).
@export var parried_recovery_bonus := 0.55
## 헛쳤을 때 회수 시간에 곱하는 배율.
@export var whiff_recovery_multiplier := 0.55
## 밀착에서 예비 시간에 곱하는 배율.
@export var close_tell_multiplier := 0.8

@export_group("공격")
## 일반 공격 목록. 가중치로 고른다.
@export var attacks: Array[AttackData] = []
## 공격 가방. 0이면 공격마다 가중치로 독립 추첨한다. 1 이상이면 일반 공격마다
## "반올림한 가중치 x 이 값"장을 넣은 가방을 섞어 한 장씩 꺼내고, 다 쓰면 다시 채운다.
## 버릇 반응은 가방과 무관하다.
@export var attack_bag_sets := 0
## 버릇 목록.
@export var habits: Array[HabitData] = []
