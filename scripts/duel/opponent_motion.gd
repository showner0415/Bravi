class_name OpponentMotion
extends RefCounted
## 상대 포즈의 곡선(결정 236·258). 견본 026-pose-motion.html의 timeline·tellPose·recoverPose를 옮겼다.
## 순수 함수만 둔다: 받은 PoseData를 고치지 않고 늘 새것을 돌려준다(데이터의 포즈는 공유된다).
## 이름을 바꾸면 T66이 깨진다.


## 휘두름의 길이(초). 패리 창 안에서 시작하게 둔다(바이블 15절).
static func swing_time(tell_duration: float, parry_window: float, opp: OpponentData) -> float:
	return minf(opp.swing_ratio * tell_duration, parry_window - opp.swing_margin)


## 멈칫이 끝나는 진행(0~1).
static func hold_end(tell_duration: float, parry_window: float, opp: OpponentData) -> float:
	var swing := swing_time(tell_duration, parry_window, opp)
	return maxf(1.0 - swing / maxf(tell_duration, 0.001), opp.tell_in)


## 예비 동작의 진행 p에서의 포즈. from은 예비 동작이 시작될 때 화면에 있던 포즈다.
static func tell_pose(atk: AttackData, from: PoseData, p: float, tell_duration: float,
		parry_window: float, opp: OpponentData) -> PoseData:
	var k := clampf(p, 0.0, 1.0)
	var start := _or_rest(atk.tell_pose)
	var strike := _or_rest(atk.strike_pose)
	if not opp.hold_curve:
		return blend(start, strike, k)
	var tin := opp.tell_in
	var he := hold_end(tell_duration, parry_window, opp)
	if k < tin:
		return blend(_or_rest(from), start, ease_out(k / tin))
	var hold := hold_of(atk)
	if k < he:
		return blend(start, hold, ease_in_out((k - tin) / (he - tin)))
	if he >= 1.0:
		return blend(hold, strike, 1.0)
	return blend(hold, strike, ease_in((k - he) / (1.0 - he)))


## 회수의 진행 q에서의 포즈: 타격에서 회수 끝으로 늘어진다.
static func recover_pose(atk: AttackData, q: float) -> PoseData:
	return blend(_or_rest(atk.strike_pose), recover_end_of(atk), ease_out(clampf(q, 0.0, 1.0)))


static func hold_of(atk: AttackData) -> PoseData:
	var pose := blend(_or_rest(atk.tell_pose), _or_rest(atk.tell_pose), 0.0)
	pose.arm_deg = atk.hold_arm_deg
	return pose


static func recover_end_of(atk: AttackData) -> PoseData:
	var pose := blend(_or_rest(atk.strike_pose), _or_rest(atk.strike_pose), 0.0)
	pose.arm_deg = atk.recover_arm_deg
	return pose


## 각은 도로 곧게 섞는다(360° 감기를 하지 않는다. 견본의 lerp).
static func blend(a: PoseData, b: PoseData, k: float) -> PoseData:
	var r := PoseData.new()
	r.arm_deg = lerpf(a.arm_deg, b.arm_deg, k)
	r.sword_deg = lerpf(a.sword_deg, b.sword_deg, k)
	r.head_deg = lerpf(a.head_deg, b.head_deg, k)
	r.lean_deg = lerpf(a.lean_deg, b.lean_deg, k)
	r.shoulder = a.shoulder.lerp(b.shoulder, k)
	return r


static func ease_in(k: float) -> float:
	return k * k


static func ease_out(k: float) -> float:
	return 1.0 - (1.0 - k) * (1.0 - k)


static func ease_in_out(k: float) -> float:
	return 2.0 * k * k if k < 0.5 else 1.0 - 2.0 * (1.0 - k) * (1.0 - k)


# 포즈가 없는 데이터(테스트가 만든 공격)도 깨지지 않게 0 포즈로 본다.
static func _or_rest(pose: PoseData) -> PoseData:
	return pose if pose != null else PoseData.new()
