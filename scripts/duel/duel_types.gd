class_name DuelTypes
extends RefCounted
## 결투 전반에서 쓰는 열거형과 표시용 이름.
## enum 값은 .tres에 정수로 저장된다. 끝에만 추가하고 재정렬하지 않는다.

enum Direction { LEFT, CENTER, RIGHT }
enum Height { HIGH, MID, LOW }
enum Distance { FAR, ENGAGE, CLOSE }
enum Part { HEAD, HAT, TORSO, SWORD_ARM, SWORD_HAND, LEGS }

## 상대 상태. ATTACK은 길이 0(타격 판정 시각)이라 머무르지 않는다.
enum OpponentState { IDLE, TELL, ATTACK, RECOVERY, STAGGER }
enum PlayerState { READY, WINDUP, RECOVER, GUARD, STEPPING }

## 상대 타격의 결과.
enum StrikeResult { WHIFF, BLOCKED, PARRIED, GRAZE, HIT }
## 플레이어 공격의 결과.
enum AttackResult { WHIFF, BLOCKED, GRAZE, HIT }
## 플레이어가 맞았을 때의 상황.
enum Situation { UNGUARDED, WRONG_GUARD, IN_ATTACK }
enum EndReason { NONE, PLAYER_DEFEATED, OPPONENT_HIT, TIME_UP, CONDITION }

const DIRECTION_NAMES := ["왼쪽 베기", "찌르기", "오른쪽 베기"]
const GUARD_NAMES := ["왼쪽", "가운데", "오른쪽"]
const HEIGHT_NAMES := ["상단", "중단", "하단"]
const DISTANCE_NAMES := ["멀리", "교전", "밀착"]
const PART_NAMES := ["머리", "모자", "몸통", "칼 든 팔", "칼 든 손", "다리"]
const OPPONENT_STATE_NAMES := ["대기", "예비 동작", "공격", "회수", "무너짐"]
const PLAYER_STATE_NAMES := ["준비", "공격 예비", "공격 회수", "막기", "이동"]
const SITUATION_NAMES := ["무방비", "틀린 방향 막기", "공격 중"]

## 지금 누르면 닿는지의 미리 셈한 답(계획 R02). 판정(_verdict)과 같은 말이다. UNSURE는 미리 알 수 없다는 뜻이다.
enum Forecast { UNSURE, NO_OPENING, REACH, OUT_OF_RANGE, LATE, HEAD_GUARDED, BIND_CUT }
const FORECAST_NAMES := ["미정", "빈틈 아님", "닿는다", "멀다", "늦다", "피한다", "엉킴"]
