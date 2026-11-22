class_name CurveCheck
extends RefCounted
## hold 곡선이 반응 싸움이 되는지 사용자가 직접 보는 판(계획 030 결정 273). 켜져 있으면 판마다 표시의 곡선을
## 바꾸고(hold / 고르게), 판이 끝날 때 타격마다 한 줄을 남긴다. 곡선은 화면에 보이지 않는다(D1).
## 판정은 바꾸지 않는다: hold_curve는 표시만 읽는다(opponent_motion.gd).

const ARG := "--bravi-curve-check"
## 환경 변수도 읽는다: playtester의 런처는 게임 인자를 고정하고, play.ps1은 PowerShell이 "--"를 먹을 수 있다(T1).
const ENV := "BRAVI_CURVE_CHECK"
const PATH := "user://curve_check.csv"
const HEADER := "session,duel_id,curve,attack_name,is_big,close,strike_t,result,lead,late"
## 타격 뒤 이만큼 안의 첫 새 막기를 "늦게 누름"으로 센다(휘두름을 보고 누르면 여기에 모인다).
const LATE_WINDOW := 0.3

## 이 실행에서 연 판의 수(0부터, 하루 모드는 판마다 씬을 새로 띄우므로 정적이다)와 지금 판.
static var opened := 0
static var session := ""
static var current_id := -1
static var current_curve := ""


static func enabled_from(args: PackedStringArray, env: String) -> bool:
	return args.has(ARG) or env == "1"


static func enabled() -> bool:
	return enabled_from(OS.get_cmdline_user_args(), OS.get_environment(ENV))


## 0은 기록하지 않는 몸풀기(hold). 1부터 ABBA: hold, 고르게, 고르게, hold, …(첫 판의 치우침을 없앤다, D1).
static func curve_for(index: int) -> bool:
	if index <= 0:
		return true
	var r := (index - 1) % 4
	return r == 0 or r == 3


## 켜져 있으면 표시의 곡선만 다른 사본을 돌려준다(코어와 뷰가 같은 사본을 받는다). 꺼져 있으면 그대로.
static func prepare(opponent: OpponentData) -> OpponentData:
	current_id = -1
	if not enabled():
		return opponent
	if session == "":
		session = Time.get_datetime_string_from_system()
	current_id = opened
	opened += 1
	var copy := opponent.duplicate() as OpponentData
	copy.hold_curve = curve_for(current_id)
	current_curve = "hold" if copy.hold_curve else "flat"
	return copy


## 판이 끝나면 덧붙인다(몸풀기는 빼고).
static func on_event(ev: Dictionary, core: DuelCore) -> void:
	if ev["type"] == DuelRecord.END and current_id >= 1:
		append(rows(core.record, current_curve, str(current_id), session))


## 타격 하나 = 한 줄. lead = 그 예비 동작 시작 뒤 타격 전의 마지막 새 막기가 타격보다 앞선 초,
## late = 타격 뒤 LATE_WINDOW 안의 첫 새 막기까지의 초(없으면 빈칸). 새 막기가 아닌 것(fresh 거짓)은 세지 않는다.
static func rows(record: DuelRecord, curve: String, duel_id: String, session_id: String) -> Array[PackedStringArray]:
	var fresh: Array[float] = []
	for ev in record.of_type(DuelRecord.GUARD_START):
		if ev.get("fresh", false):
			fresh.append(float(ev["t"]))
	var out: Array[PackedStringArray] = []
	var tell_t := -INF
	var tell_duration := 0.0
	for ev in record.events:
		if ev["type"] == DuelRecord.TELL_START:
			tell_t = float(ev["t"])
			tell_duration = float(ev.get("duration", 0.0))
		elif ev["type"] == DuelRecord.STRIKE:
			var atk: AttackData = ev["attack"]
			var strike_t := float(ev["t"])
			var lead := ""
			var late := ""
			for g in fresh:
				if g >= tell_t and g < strike_t:
					lead = "%.3f" % (strike_t - g)
				elif g > strike_t and g <= strike_t + LATE_WINDOW and late == "":
					late = "%.3f" % (g - strike_t)
			var close := tell_duration < atk.tell_time - 0.0001
			var result_name: String = DuelTypes.StrikeResult.keys()[int(ev["result"])]
			out.append(PackedStringArray([session_id, duel_id, curve, atk.attack_name, str(atk.is_big), str(close),
					"%.3f" % strike_t, result_name, lead, late]))
	return out


static func append(lines: Array[PackedStringArray], path := PATH) -> void:
	var exists := FileAccess.file_exists(path)
	var file := FileAccess.open(path, FileAccess.READ_WRITE if exists else FileAccess.WRITE)
	if file == null:
		push_warning("CurveCheck: %s를 열 수 없다" % path)
		return
	file.seek_end()
	if not exists:
		file.store_line(HEADER)
	for line in lines:
		file.store_line(",".join(line))
	file.close()
