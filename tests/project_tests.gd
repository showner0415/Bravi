extends RefCounted
## T0: 프로젝트 설정 검사.


func list(_tree: SceneTree) -> Array:
	return [
		{"id": "T0", "name": "입력 액션 7개", "fn": t0_input_actions},
	]


func t0_input_actions() -> String:
	# [액션, 종류("mouse"/"key"), 버튼 번호 또는 physical_keycode]
	var expected := [
		["attack", "mouse", MOUSE_BUTTON_LEFT],
		["guard", "mouse", MOUSE_BUTTON_RIGHT],
		["step_forward", "key", KEY_W],
		["step_back", "key", KEY_S],
		["retry", "key", KEY_R],
		["back", "key", KEY_ESCAPE],
		["debug_toggle", "key", KEY_F1],
	]
	var errs: Array[String] = []
	for row in expected:
		var action: String = row[0]
		if not InputMap.has_action(action):
			errs.append("%s 액션 없음" % action)
			continue
		var events := InputMap.action_get_events(action)
		if events.size() != 1:
			errs.append("%s 이벤트 수 %d" % [action, events.size()])
			continue
		var ev := events[0]
		if row[1] == "mouse":
			if not (ev is InputEventMouseButton):
				errs.append("%s 가 마우스 버튼이 아님" % action)
			elif (ev as InputEventMouseButton).button_index != row[2]:
				errs.append("%s 버튼 번호 %d" % [action, (ev as InputEventMouseButton).button_index])
		else:
			if not (ev is InputEventKey):
				errs.append("%s 가 키가 아님" % action)
			elif (ev as InputEventKey).physical_keycode != row[2]:
				errs.append("%s physical_keycode %d" % [action, (ev as InputEventKey).physical_keycode])
	# 화면을 넘기는 키(Space / Enter)는 엔진의 기본 액션을 쓴다. 이벤트가 여럿이라 위의 표에 넣지 않는다.
	if not InputMap.has_action("ui_accept"):
		errs.append("ui_accept 액션 없음")
	return _result(errs, ", ")


## 통과면 "OK". 빈 문자열은 통과가 아니다(런타임 오류로 함수가 중단되면 ""가 돌아오므로).
func _result(errs: Array[String], sep: String) -> String:
	return "OK" if errs.is_empty() else sep.join(errs)
