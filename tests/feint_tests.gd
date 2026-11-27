extends RefCounted
## T134: 지킴의 골든(계획 044 결정 679). 코드를 고치기 전에 적은 이벤트 줄의 SHA-256이 고친 뒤에도 같다.
## T135(헛손질의 규칙)는 작업 2에서 이 파일에 더한다.

const Digest := preload("res://tests/event_digest.gd")


func list(_tree: SceneTree) -> Array:
	return [
		{"id": "T134", "name": "이벤트 줄의 지킴: 골든의 줄을 도구와 같은 digest_row로 다시 셈해 견준다(데이터가 바뀐 줄은 건너뛰고, 모두 건너뛰면 실패)", "fn": t134_event_digest},
	]


func t134_event_digest() -> String:
	var golden := Digest.read_golden()
	if golden.is_empty():
		return "골든 파일 %s가 없거나 비었다 — tests/run_event_digest.ps1 -Write로 쓴다" % Digest.GOLDEN_PATH
	var result := Digest.check(golden)
	print("  INFO T134 골든 %d줄, 건너뜀 %d줄" % [int(result["rows"]), int(result["skipped"])])
	for message: String in result["messages"]:
		if message.begins_with("  INFO"):
			print(message)
	if bool(result["ok"]):
		return "OK"
	var diffs: Array = result["diffs"]
	return "; ".join(PackedStringArray(diffs))
