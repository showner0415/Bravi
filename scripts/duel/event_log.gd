extends RefCounted
## 실행 확인용 기록(게임 창). 환경 변수 BRAVI_EVENT_LOG가 가리키는 파일에 판마다 요약 한 줄을 JSON으로 덧붙인다.
## 화면의 기록 글을 그림으로 읽지 않게 하려는 것이다. 변수가 없으면 아무것도 하지 않는다.

const Summary := preload("res://scripts/duel/duel_summary.gd")
const ENV := "BRAVI_EVENT_LOG"


## 판이 끝난 이벤트에서 부른다. 한 줄: {opponent, heights(높이 막기를 쓰는가), mode, ...요약, ...extra(결투 씬의 pauses·pause_drift·swallowed_attacks. 결정 515)}.
static func on_event(ev: Dictionary, core: DuelCore, mode: String, extra := {}) -> void:
	if ev["type"] != DuelRecord.END:
		return
	var path := OS.get_environment(ENV)
	if path == "":
		return
	var line := Summary.summarize(core.record)
	line["opponent"] = core.opponent_data.display_name
	line["heights"] = DuelHud.uses_heights(core.opponent_data)
	line["mode"] = mode
	line.merge(extra, true)
	var file := FileAccess.open(path, FileAccess.READ_WRITE) if FileAccess.file_exists(path) else FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return
	file.seek_end()
	file.store_line(JSON.stringify(line))
	file.close()
