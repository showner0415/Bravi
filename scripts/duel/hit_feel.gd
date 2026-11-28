class_name HitFeel
extends RefCounted
## 타격감의 값과 고르기(계획 H02, 결정 921·925). 읽고 맞춘 순간, 내 공격이 닿은 순간, 내가 맞은 순간만 이름을 갖고
## 나머지는 &""다(대비를 위해 일부러 비운다). 판정에는 관여하지 않는다. 값은 전부 임시다.

const HIT_DEALT := &"hit_dealt"
const PARRY_OPEN := &"parry_open"
## 패턴 가운데의 패리(멈칫 0 — 스냅·소리·불꽃만. 계획 H03 결정 944).
const PARRY_MID := &"parry_mid"
const STAGGER := &"stagger"
const SWEEP_OPEN := &"sweep_open"
const DIVE_OPEN := &"dive_open"
const DIVE_WHIFF := &"dive_whiff"
const GRAZE_DEALT := &"graze_dealt"
const HIT_TAKEN := &"hit_taken"
const GRAZE_TAKEN := &"graze_taken"

## 멈칫(ms). 스침 넣음은 칸 수로 갈린다(stop_msec).
const STOP_MSEC := {
	HIT_DEALT: 120, HIT_TAKEN: 120, PARRY_OPEN: 90, STAGGER: 90,
	SWEEP_OPEN: 70, DIVE_OPEN: 70, DIVE_WHIFF: 70, GRAZE_TAKEN: 70,
}
const GRAZE_STOP_MSEC := [50, 70]
## 내가 맞았을 때 세계의 킥 크기(px, 계획 H03 결정 942). 넣은 쪽의 평행이동은 없다(맞은 포즈·떨림이 갈음한다 — 결정 938).
const HIT_KICK := 18.0
const GRAZE_KICK := 12.0
## 멈칫 동안 맞은 쪽 그림의 떨림 폭(px, 결정 935). 스침 넣음은 칸 수로 갈린다.
const SHAKE_PX := {
	HIT_DEALT: 8.0, HIT_TAKEN: 8.0, GRAZE_TAKEN: 5.0, PARRY_OPEN: 5.0, SWEEP_OPEN: 5.0, DIVE_OPEN: 5.0, STAGGER: 6.0,
}
const GRAZE_SHAKE_PX := [4.0, 5.0]


## 이벤트 하나가 어느 순간인가. root는 지금 패턴의 뿌리(TELL_START의 attack)이고 없으면 null이다.
static func moment_of(ev: Dictionary, root: AttackData) -> StringName:
	var result: int = ev.get("result", -1)
	match ev.get("type", &""):
		DuelRecord.STAGGER_START:
			return STAGGER
		DuelRecord.ATTACK:
			if ev.get("spiked", false) or ev.get("dodged", false) or ev.get("rash", false):
				return &""
			if result == DuelTypes.AttackResult.HIT:
				return HIT_DEALT
			if result == DuelTypes.AttackResult.GRAZE:
				return GRAZE_DEALT
		DuelRecord.STRIKE:
			# 안 열린 순간에 연출이 있으면 "열렸다"로 읽힌다(원칙 4).
			if ev.get("closed", false) or ev.get("bitten", false) or ev.get("braced", false):
				return &""
			var ends: bool = float(ev.get("next_strike", -1.0)) < 0.0
			match result:
				DuelTypes.StrikeResult.HIT:
					return HIT_TAKEN
				DuelTypes.StrikeResult.GRAZE:
					return GRAZE_TAKEN
				DuelTypes.StrikeResult.PARRIED:
					return PARRY_OPEN if ends else PARRY_MID
				DuelTypes.StrikeResult.BLOCKED:
					if ends and root != null:
						if root.sweep and not root.chain.is_empty():
							return SWEEP_OPEN
						if root.dive:
							return DIVE_OPEN
				DuelTypes.StrikeResult.WHIFF:
					if ends and root != null and root.dive and float(ev.get("recovery", 0.0)) > 0.0:
						return DIVE_WHIFF
	return &""


static func stop_msec(moment: StringName, ev: Dictionary = {}) -> int:
	if moment == GRAZE_DEALT:
		return GRAZE_STOP_MSEC[1 if int(ev.get("cells", 1)) >= 2 else 0]
	return STOP_MSEC.get(moment, 0)


## 세계의 킥(상대 뿌리에 거는 움찔의 길). 내가 맞았을 때만 있다: 왼쪽에서 온 타격은 -x, 오른쪽은 +x, 찌르기는 +y.
## 넣은 쪽(상대가 맞음·패리당함)은 0이다 — 맞은 포즈·쳐내진 포즈·떨림이 갈음한다(결정 938).
static func flinch(moment: StringName, ev: Dictionary) -> Vector2:
	var size := 0.0
	match moment:
		HIT_TAKEN:
			size = HIT_KICK
		GRAZE_TAKEN:
			size = GRAZE_KICK
		_:
			return Vector2.ZERO
	var attack: Variant = ev.get("attack")
	match (attack as AttackData).direction if attack is AttackData else DuelTypes.Direction.CENTER:
		DuelTypes.Direction.LEFT:
			return Vector2(-size, 0.0)
		DuelTypes.Direction.RIGHT:
			return Vector2(size, 0.0)
	return Vector2(0.0, size)


## 떨림의 한 tick(결정 935): 멈칫의 남은 tick(remaining)이 전체(total)에서 0으로 곧게 줄고 부호가 뒤집힌다. 받는 쪽은 씬이 가른다.
static func shake_px(moment: StringName, remaining: int, total: int, ev: Dictionary = {}) -> float:
	if total <= 0 or remaining <= 0:
		return 0.0
	var amount: float = GRAZE_SHAKE_PX[1 if int(ev.get("cells", 1)) >= 2 else 0] if moment == GRAZE_DEALT else SHAKE_PX.get(moment, 0.0)
	return amount * float(remaining) / float(total) * (1.0 if remaining % 2 == 0 else -1.0)


## 떨림을 받는 쪽: 내가 맞음이면 내 손, 아니면 상대.
static func shakes_me(moment: StringName) -> bool:
	return moment == HIT_TAKEN or moment == GRAZE_TAKEN
