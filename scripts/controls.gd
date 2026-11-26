extends RefCounted
## 조작(공격·막기·전진·후퇴)의 부호·이름·예약과 InputMap에 거는 길(계획 S03, 결정 517). 정적 함수만 둔다.
## 부호는 "mouse:<버튼>" · "key:<물리 키>" · 빈 글(없음). 처음 값의 원본은 project.godot 하나다.

const ACTIONS: Array = [&"attack", &"guard", &"step_forward", &"step_back"]
const LABELS := {&"attack": "공격", &"guard": "막기", &"step_forward": "전진", &"step_back": "후퇴"}
## 알림의 토씨(이름이 넷으로 정해져 있어 표로 둔다).
const TOPICS := {&"attack": "공격은", &"guard": "막기는", &"step_forward": "전진은", &"step_back": "후퇴는"}
const MOUSE_NAMES := {1: "좌클릭", 2: "우클릭", 3: "가운데 클릭", 8: "옆 버튼 1", 9: "옆 버튼 2"}
## 바꿀 수 없는 동작의 액션. 받지 않는다: Esc·Space를 공격에 주면 같은 누름에 멈춤·넘기기가 함께 걸린다(Q1 "다"에서도).
const RESERVED := {&"back": "멈춤", &"ui_cancel": "멈춤", &"retry": "다시 하기", &"debug_toggle": "디버그", &"ui_accept": "화면 넘기기", &"toggle_fullscreen": "전체 화면"}
const NONE_NAME := "없음"
const DASH := "—"


## 못 쓰는 입력은 빈 글. 물리 키가 없는 키는 keycode로 대신 적지 않는다(event_of가 그 수를 물리 키로 지어 실제 누름에 맞지 않는다).
static func code_of(event: InputEvent) -> String:
	if event is InputEventMouseButton:
		var button := int((event as InputEventMouseButton).button_index)
		return "mouse:%d" % button if MOUSE_NAMES.has(button) else ""
	if event is InputEventKey:
		var key := event as InputEventKey
		var physical := int(key.physical_keycode)
		if key.echo or physical == 0 or physical == KEY_META:
			return ""
		return "key:%d" % physical
	return ""


## 수식키를 담지 않는다: Shift 같은 키를 줄 때 뗌이 액션에 맞지 않아 막기가 풀리지 않는 일을 막는다.
static func event_of(code: String) -> InputEvent:
	var parts := code.split(":")
	if parts.size() != 2 or not parts[1].is_valid_int():
		return null
	var number := parts[1].to_int()
	if parts[0] == "mouse" and MOUSE_NAMES.has(number):
		var mouse := InputEventMouseButton.new()
		mouse.device = -1
		mouse.button_index = number as MouseButton
		return mouse
	if parts[0] == "key" and number > 0 and number != KEY_META:
		var key := InputEventKey.new()
		key.device = -1
		key.physical_keycode = number as Key
		return key
	return null


static func is_valid(code: String) -> bool:
	return code == "" or event_of(code) != null


## 자판 배열을 따르지 않는 물리 자리의 미국식 이름이다(DisplayServer의 배열 이름은 헤드리스에서 오류 줄을 낼 수 있다).
static func name_of(code: String) -> String:
	var event := event_of(code)
	if event is InputEventMouseButton:
		return MOUSE_NAMES[int((event as InputEventMouseButton).button_index)]
	if event is InputEventKey:
		return OS.get_keycode_string((event as InputEventKey).physical_keycode)
	return NONE_NAME


static func default_code(action: StringName) -> String:
	var setting: Variant = ProjectSettings.get_setting("input/%s" % action)
	if setting is Dictionary:
		var events: Array = (setting as Dictionary).get("events", [])
		if not events.is_empty():
			return code_of(events[0])
	return ""


static func default_codes() -> Dictionary:
	var out := {}
	for action in ACTIONS:
		out[action] = default_code(action)
	return out


## 예약된 동작의 이벤트와 같으면 그 쓰임의 이름, 아니면 빈 글. 키는 physical_keycode와 keycode 둘 다로 견준다(엔진의 ui_accept는 keycode로 적혀 있다).
static func reserved_use(code: String) -> String:
	var event := event_of(code)
	if event == null:
		return ""
	for action in RESERVED:
		if not InputMap.has_action(action):
			continue
		for other in InputMap.action_get_events(action):
			if event is InputEventKey and other is InputEventKey:
				var number := int((event as InputEventKey).physical_keycode)
				if number == int((other as InputEventKey).physical_keycode) or number == int((other as InputEventKey).keycode):
					return RESERVED[action]
	return ""


## 액션 자체는 지우지 않는다(빈 동작도 액션이 남아 is_action_pressed가 오류 없이 거짓이다).
## 바뀐 동작만 놓아 준다: 쥐고 있던 버튼의 뗌이 더는 맞지 않아 눌린 채 남으면 돌아올 때 막기가 붙는다.
static func apply_codes(codes: Dictionary, changed: Array = ACTIONS) -> void:
	for action in ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		InputMap.action_erase_events(action)
		var event := event_of(String(codes.get(action, "")))
		if event != null:
			InputMap.action_add_event(action, event)
	for action in changed:
		Input.action_release(action)


static func action_name(action: StringName) -> String:
	var events := InputMap.action_get_events(action) if InputMap.has_action(action) else []
	if events.is_empty():
		return NONE_NAME
	return name_of(code_of(events[0]))


## 도움말용: 빈 동작은 "—".
static func help_name(action: StringName) -> String:
	var label := action_name(action)
	return DASH if label == NONE_NAME else label


static func empty_actions() -> Array:
	var out := []
	for action in ACTIONS:
		if not InputMap.has_action(action) or InputMap.action_get_events(action).is_empty():
			out.append(action)
	return out
