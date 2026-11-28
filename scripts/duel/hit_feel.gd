class_name HitFeel
extends RefCounted
## 타격감의 값과 고르기(계획 H02, 결정 921·925). 읽고 맞춘 순간, 내 공격이 닿은 순간, 내가 맞은 순간만 이름을 갖고
## 나머지는 &""다(대비를 위해 일부러 비운다). 판정에는 관여하지 않는다. 값은 전부 임시다.

const HIT_DEALT := &"hit_dealt"
const PARRY_OPEN := &"parry_open"
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
## 상대의 움찔 크기(px). 방향이 있는 것은 flinch가 정한다.
const HIT_FLINCH := 28.0
const GRAZE_FLINCH := [10.0, 18.0]
const PARRY_FLINCH := 14.0
const OPEN_FLINCH := 10.0


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
					return PARRY_OPEN if ends else &""
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


## 상대의 움찔 벡터(최대). 왼쪽 베기는 +x, 오른쪽 베기는 -x, 찌르기는 -y(뒤로 밀림)다.
static func flinch(moment: StringName, ev: Dictionary) -> Vector2:
	var size := 0.0
	match moment:
		HIT_DEALT:
			size = HIT_FLINCH
		GRAZE_DEALT:
			size = GRAZE_FLINCH[1 if int(ev.get("cells", 1)) >= 2 else 0]
		PARRY_OPEN:
			return Vector2(0.0, -PARRY_FLINCH)
		SWEEP_OPEN, DIVE_OPEN:
			return Vector2(0.0, -OPEN_FLINCH)
		_:
			return Vector2.ZERO
	match int(ev.get("direction", DuelTypes.Direction.CENTER)):
		DuelTypes.Direction.LEFT:
			return Vector2(size, 0.0)
		DuelTypes.Direction.RIGHT:
			return Vector2(-size, 0.0)
	return Vector2(0.0, -size)
