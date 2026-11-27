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
## 참이면 이 상대의 고유 검술의 공격(뿌리와 변주에 적는다. 걸음은 뿌리를 따른다. 결정 581).
@export var signature := false

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

@export_group("이어 치기 (계획 036)")
## 이 공격 뒤에 한 예비 동작으로 이어지는 타격(걸음). 비면 단발이다. 이 공격(뿌리)이 첫 타격이고
## 이름·예비·끝의 회수·큰 공격·가중치를 정한다(결정 370).
## 걸음에서 읽는 칸은 direction, tell_time(앞 타격부터의 간격), attack_name, 포즈, pose_color뿐이다.
# 자기 클래스를 원소 타입으로 쓰면 스크립트가 자신을 붙잡아 끝날 때 누수 오류가 난다(계획 036 E1). 원소는 모두 AttackData다.
@export var chain: Array[Resource] = []
## 참이면 휩쓸기: 이 공격과 chain이 한 번의 긴 베기가 닿는 점들이다. 패리가 없고 막기를 쥔 채 끌어야 한다(결정 372).
@export var sweep := false

@export_group("뛰어들기 (계획 037b)")
## 참이면 판정 뒤 간격을 한 칸 좁힌다(결정 450).
@export var dive := false

@export_group("칸과 변주 (계획 036b)")
## 이 타격이 올 수 있는 높이(DuelTypes.Height의 값)의 묶음. 비면 높이가 없는 타격이라 막기가 방향만 본다.
## 나올 때마다 하나를 고르게 뽑는다(같은 값을 여러 번 적으면 그만큼 자주 나온다. 결정 384).
@export var heights: Array[int] = []
## 이 공격의 다른 길들(원소는 모두 AttackData. chain과 같은 까닭으로 Resource 배열이다). 가방에서 이 공격이 나오면
## 이 공격과 변주 가운데 하나를 고르게 뽑는다. 변주의 variants·weight는 읽지 않는다.
@export var variants: Array[Resource] = []

@export_group("표시 (계획 042a)")
## 번호 고리의 꼴(뿌리와 변주에 적는다. 걸음은 뿌리를 따른다). 빈 값이면 원 그대로이고 뜻이 있는 값은 OpponentView.MARK_SHAPES에 있다(결정 631).
@export var mark_shape: StringName = &""
## 예비 동작 동안 귀띔 자리에 뜨는 글(뿌리의 값을 쓴다). 빈 값이면 없다(결정 633).
@export var tell_hint := ""
