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

@export_group("부위")
## 부위마다 스쳤을 때 깎이는 자세 칸 수. 1보다 작은 값은 1로 본다. 유효타에는 쓰이지 않는다.
@export var graze_head := 1
@export var graze_hat := 1
@export var graze_torso := 1
@export var graze_sword_arm := 1
@export var graze_sword_hand := 1
@export var graze_legs := 1
## 머리를 지킨다: 머리는 크게 열렸을 때(패리당했거나 큰 공격을 쓴 뒤의 회수)와 무너졌을 때만 닿는다.
## 그 밖의 빈틈에서 머리를 노린 공격은 피한다. 거짓이면 어느 빈틈에서나 머리에 닿는다.
@export var guards_head := false

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

@export_group("방심")
## 방심하는 데 걸리는 시간(초). 내가 이만큼 먼저 치지 않으면 대기 중에 칼끝을 내리고, 그때 멀리에서 뛰어드는
## 런지(선공)가 닿는다. 판 처음에는 경계하고 있다(게이지 0). 0 이하면 방심하지 않는다(선공이 없다).
@export var complacent_time := 0.0
## 한 판에 런지에 찔리는 횟수의 상한. 이만큼 찔리면 그 판에서는 다시 방심하지 않는다. 0 이하면 제한이 없다.
@export var complacent_limit := 1

@export_group("공격")
## 일반 공격 목록. 가중치로 고른다.
@export var attacks: Array[AttackData] = []
## 공격 가방. 0이면 공격마다 가중치로 독립 추첨한다. 1 이상이면 일반 공격마다
## "반올림한 가중치 x 이 값"장을 넣은 가방을 섞어 한 장씩 꺼내고, 다 쓰면 다시 채운다.
## 버릇 반응은 가방과 무관하다.
@export var attack_bag_sets := 0
## 버릇 목록.
@export var habits: Array[HabitData] = []
## 거짓이면 이 상대의 모든 타격이 높이 없이 나온다(견줘 보는 길과 되돌림. 결정 391).
@export var use_heights := true

@export_group("빈틈의 확률 (계획 036c)")
## 막힘·패리가 빈틈이 될 확률의 바탕(1일차, 업그레이드 없음). 1.0 이상이면 이 규칙이 꺼진 상대다: 날에 깎이지 않고 난수도 부르지 않는다(결정 396).
@export var opening_chance := 1.0
## 연속으로 안 열릴 수 있는 횟수. 그만큼 안 열렸으면 다음은 반드시 열린다. 0이면 상한이 없다(결정 401).
@export var opening_miss_limit := 2

@export_group("그림과 포즈")
## 비어 있으면 그림 없이 돈다(테스트가 만든 상대가 씬에 들어가도 깨지지 않게. 결정 256).
@export var art: OpponentArt
@export var idle_pose: PoseData
@export var stagger_pose: PoseData
## 방심: 팔은 대기 그대로 두고 칼끝만 내린다(무너짐과 헷갈리지 않게).
@export var complacent_pose: PoseData
## 머리를 노린 공격을 피할 때 고개를 젖히는 각(도)과 시간(초).
@export var dodge_head_deg := -20.1
@export var dodge_time := 0.3

@export_group("움직임")
## 예비 동작을 hold 곡선(들어서기 → 멈칫 → 휘두름)으로 그린다. 거짓이면 고르게 간다(결정 236).
## 거짓은 원칙 4로 안전한 되돌림이 아니다(그 곡선의 R1 0.380. 계획 029 위험 R5).
@export var hold_curve := true
## 예비 동작의 진행 가운데 들어서기의 몫.
@export var tell_in := 0.2
## 휘두름 = min(이 값 x 예비 시간, 패리 창 - swing_margin). 휘두름이 패리 창 안에서 시작하게 한다.
@export var swing_ratio := 0.2
@export var swing_margin := 0.03
## 그 밖의 바뀜(회수 → 대기, 무너짐, 방심)에 걸리는 시간(초).
@export var return_time := 0.2
## 타격 뒤 대기로 돌아가는 동안에도 타격의 팔 그림을 둔다. 거짓이면 따로 그린 팔은 회수에서만 보인다(결정 268, 판 F).
@export var strike_art_on_return := true


## 그 부위를 스쳤을 때 깎이는 자세 칸 수(1 이상).
func graze_cells(part: int) -> int:
	var cells := 1
	match part:
		DuelTypes.Part.HEAD:
			cells = graze_head
		DuelTypes.Part.HAT:
			cells = graze_hat
		DuelTypes.Part.TORSO:
			cells = graze_torso
		DuelTypes.Part.SWORD_ARM:
			cells = graze_sword_arm
		DuelTypes.Part.SWORD_HAND:
			cells = graze_sword_hand
		DuelTypes.Part.LEGS:
			cells = graze_legs
	return maxi(cells, 1)


## 패턴 하나만 되풀이하는 연습용 상대(결정 377). 이 자원은 고치지 않고 새 배열을 넣은 사본을 돌려준다.
func drill(pattern: AttackData) -> OpponentData:
	var copy := duplicate() as OpponentData
	var only: Array[AttackData] = [pattern]
	var none: Array[HabitData] = []
	copy.attacks = only
	copy.habits = none
	copy.attack_bag_sets = 0
	return copy


## 높이 막기만 끈 사본(결정 391). 이 자원은 고치지 않는다.
func flat() -> OpponentData:
	var copy := duplicate() as OpponentData
	copy.use_heights = false
	return copy


## 빈틈의 확률만 바꾼 사본(연습의 날 고르기와 통계. 결정 407). 이 자원은 고치지 않는다.
func with_opening(chance: float) -> OpponentData:
	var copy := duplicate() as OpponentData
	copy.opening_chance = chance
	return copy
