class_name SettingsScreen
extends Control
## 설정 화면(계획 S01, 결정 502). 처음 열 때 만드는 덮개: 탭 줄과 탭의 몸, 닫기. 코드로 짓는다(도움말의 덮개 꼴).
## 일시정지 아래에서도 돌도록(S02) 덮개는 PROCESS_MODE_ALWAYS이고 시간은 Time.get_ticks_msec()만 쓴다.

const Ui := preload("res://scripts/day_ui.gd")

## [갈래 키, 탭 글, 몸을 짓는 메서드의 이름]. const에는 Callable을 담을 수 없어 이름을 담고 call()로 부른다.
## S03은 조작, S04는 화면 탭을 이 목록에 한 줄씩 더한다.
const TABS: Array = [[&"audio", "소리", &"_build_audio"], [&"controls", "조작", &"_build_controls"], [&"display", "화면", &"_build_display"]]
const Controls := preload("res://scripts/controls.gd")
const Display := preload("res://scripts/display.gd")
const DISPLAY_HINT := "F11로도 바꾼다 · 그림은 늘 16:9이고 남는 곳은 검은 띠 · 이 모니터에 들어가지 않는 크기는 뺐다"
const DISPLAY_REPAIRED_NOTE := "읽을 수 없는 화면 설정을 처음 값으로 돌렸다"
const BIND_WAIT_TEXT := "누른다…"
const BIND_WAIT_NOTE := "%s에 쓸 키나 마우스 버튼을 누른다 — 좌클릭은 이 칸이나 빈 곳에서. Esc나 다른 버튼은 취소"
const CONTROLS_HINT := "조준은 마우스 위치 그대로다 · Esc·R·F1·F11·Space·Enter는 쓸 수 없다"
const CONTROLS_EMPTY_WARN := "비어 있는 동작: %s — 결투에서 쓸 수 없다"
const CONTROLS_REPAIRED_NOTE := "읽을 수 없는 조작이 있어 처음 값으로 돌렸다"

const TITLE_TEXT := "설정"
const CLOSE_TEXT := "돌아간다"
const PANEL_RECT := Rect2(240, 110, 800, 480)
const CONTENT_WIDTH := 560.0
## 미리 듣기를 거르는 간격(밀리초, 결정 504).
const PREVIEW_GAP_MSEC := 120
const VOLUME_STEP := 5
const GRABBER_SIZE := 20
const MUTE_TEXT := "소리를 끈다"
const UNMUTE_TEXT := "소리를 켠다"
const MUTED_NOTE := "소리를 끈 상태다 — 미리 듣기도 나지 않는다"

## 닫을 때(닫기 버튼, Esc). 연 쪽이 초점을 되돌린다.
signal closed

## 미리 듣기가 난 횟수(테스트가 본다 — 헤드리스는 소리를 들을 수 없다).
var preview_count := 0

var _settings
var _beeper: Beeper
var _body: VBoxContainer
var _tab_group := ButtonGroup.new()
## TABS 순서의 탭 버튼(ButtonGroup.get_buttons()는 순서를 보장하지 않는다).
var _tabs: Array[Button] = []
var _slider: HSlider
var _volume_value: Label
var _mute_button: Button
var _muted_note: Label
var _last_preview_msec := -100000
## 거른 미리 듣기가 있다. drag_ended는 이것이 켜져 있을 때만 소리를 낸다(홈을 한 번 누를 때 두 번 울리지 않게).
var _preview_pending := false
## 조작 탭의 기다림(결정 520). 비면 기다리지 않는다. 시작 시각은 테스트가 고칠 수 있다.
var _waiting: StringName = &""
var _capture_msec := 0
## 잡은 누름의 뗌(부호)은 GUI에 닿지 않게 한 번 먹는다.
var _eat_release := ""
var _binds := {}
var _note: Label
var _warn: Label
## 화면 탭의 칸(다른 탭으로 옮기면 비운다: 지워진 노드를 처리기가 건드리지 않게).
var _mode_buttons := {}
var _size_buttons := {}
var _display_now: Label


static func open(parent: Control, settings: Node) -> SettingsScreen:
	var screen := SettingsScreen.new()
	screen._settings = settings
	# 도움말 덮개처럼 붙이기 전에 앵커를 둔다: _ready 안에서 두면 그 크기가 0인 채로 배경이 그려져 아래 글이 비쳤다.
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(screen)
	return screen


func _ready() -> void:
	name = "SettingsScreen"
	process_mode = Node.PROCESS_MODE_ALWAYS
	# 아래 버튼의 클릭을 막는다(결정 314).
	mouse_filter = Control.MOUSE_FILTER_STOP
	Ui.add_background(self)
	_beeper = Beeper.new()
	_beeper.name = "Beeper"
	add_child(_beeper)

	var column := Ui.add_panel(self, PANEL_RECT, 14)
	Ui.add_title(column, TITLE_TEXT, 28)
	var tab_row := HBoxContainer.new()
	tab_row.name = "TabRow"
	tab_row.add_theme_constant_override("separation", 10)
	column.add_child(tab_row)
	for i in TABS.size():
		var tab := Ui.add_button(tab_row, TABS[i][1], 20, "Tab" + String(TABS[i][0]).capitalize())
		tab.toggle_mode = true
		tab.button_group = _tab_group
		tab.custom_minimum_size = Vector2(140, 44)
		tab.pressed.connect(_select_tab.bind(i))
		_tabs.append(tab)
	_body = VBoxContainer.new()
	_body.name = "TabBody"
	_body.add_theme_constant_override("separation", 16)
	column.add_child(_body)

	var close := Ui.add_button(self, CLOSE_TEXT, 20, "SettingsClose")
	close.position = Vector2(540, 636)
	close.size = Vector2(200, 54)
	close.pressed.connect(_close)

	# 탭 밖(F11)이나 창을 끌어서 바뀐 것을 글에 옮긴다. 처리기는 글과 눌림만 고친다(결정 527·529).
	_settings.changed.connect(_on_settings_changed)
	get_window().size_changed.connect(_refresh_display)

	_select_tab(0)
	# Space·Enter가 아래의 버튼을 누르지 않게 초점을 닫기 버튼에 둔다.
	close.grab_focus()


func _select_tab(index: int) -> void:
	# 신호만 보낸 호출에서도 고른 탭 하나만 눌린 모습 — set_pressed_no_signal은 묶음의 다른 버튼을 풀지 않는다.
	for i in _tabs.size():
		_tabs[i].set_pressed_no_signal(i == index)
	_waiting = &""
	_eat_release = ""
	_binds.clear()
	_mode_buttons.clear()
	_size_buttons.clear()
	_display_now = null
	for child in _body.get_children():
		_body.remove_child(child)
		child.queue_free()
	call(TABS[index][2], _body)


func _build_audio(body: VBoxContainer) -> void:
	body.add_theme_constant_override("separation", 16)
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(CONTENT_WIDTH, 0)
	row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	body.add_child(row)
	Ui.add_label(row, "음량", 24)
	_volume_value = Ui.add_label(row, str(_settings.volume), 24)
	_volume_value.name = "VolumeValue"
	_volume_value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_volume_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	_slider = HSlider.new()
	_slider.name = "VolumeSlider"
	_slider.min_value = 0
	_slider.max_value = 100
	_slider.step = VOLUME_STEP
	_slider.custom_minimum_size = Vector2(CONTENT_WIDTH, 32)
	_slider.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_style_slider(_slider)
	body.add_child(_slider)

	_mute_button = Ui.add_button(body, UNMUTE_TEXT if _settings.muted else MUTE_TEXT, 20, "MuteButton")
	_mute_button.toggle_mode = true
	_mute_button.custom_minimum_size = Vector2(280, 50)
	_mute_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN

	_muted_note = Ui.add_label(body, MUTED_NOTE, 16, Ui.DIM)
	_muted_note.name = "MutedNote"
	_muted_note.visible = _settings.muted

	# 처음 값은 신호 없이 넣고 신호는 그 뒤에 잇는다: 열기만 해서는 미리 듣기·저장이 생기지 않는다(결정 500).
	_slider.set_value_no_signal(_settings.volume)
	_mute_button.set_pressed_no_signal(_settings.muted)
	_slider.value_changed.connect(_on_volume_changed)
	_slider.drag_ended.connect(_on_drag_ended)
	_mute_button.toggled.connect(_on_mute_toggled)


func _on_volume_changed(value: float) -> void:
	_settings.set_volume(int(value))
	_volume_value.text = str(_settings.volume)
	if _settings.muted:
		return
	var now := Time.get_ticks_msec()
	if now - _last_preview_msec < PREVIEW_GAP_MSEC:
		_preview_pending = true
		return
	_preview(now)


func _on_drag_ended(_value_changed: bool) -> void:
	if _preview_pending and not _settings.muted:
		_preview(Time.get_ticks_msec())
	_settings.save()


func _on_mute_toggled(on: bool) -> void:
	_settings.set_muted(on)
	_mute_button.text = UNMUTE_TEXT if on else MUTE_TEXT
	_muted_note.visible = on
	_settings.save()


func _preview(now: int) -> void:
	_last_preview_msec = now
	_preview_pending = false
	preview_count += 1
	_beeper.play(&"block")


func _build_controls(body: VBoxContainer) -> void:
	body.add_theme_constant_override("separation", 8)
	for action in Controls.ACTIONS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		body.add_child(row)
		var label := Ui.add_label(row, Controls.LABELS[action], 24)
		label.custom_minimum_size = Vector2(160, 0)
		var button := Ui.add_button(row, "", 20, "Bind_" + String(action))
		button.custom_minimum_size = Vector2(240, 42)
		button.pressed.connect(_begin_wait.bind(action))
		_binds[action] = button
	var reset_row := HBoxContainer.new()
	reset_row.add_theme_constant_override("separation", 16)
	body.add_child(reset_row)
	var reset := Ui.add_button(reset_row, "처음 값으로", 20, "ControlsReset")
	reset.custom_minimum_size = Vector2(220, 42)
	reset.pressed.connect(_on_controls_reset)
	var hint := Ui.add_wrapped(reset_row, CONTROLS_HINT, 16, Ui.DIM)
	hint.name = "ControlsHint"
	hint.custom_minimum_size = Vector2(320, 0)
	_note = Ui.add_wrapped(body, "", 18)
	_note.name = "ControlsNote"
	_note.custom_minimum_size = Vector2(CONTENT_WIDTH, 0)
	_warn = Ui.add_wrapped(body, "", 18, Ui.ACCENT)
	_warn.name = "ControlsEmptyWarn"
	_warn.custom_minimum_size = Vector2(CONTENT_WIDTH, 0)
	_set_note(CONTROLS_REPAIRED_NOTE if _settings.controls_repaired else "")
	_settings.controls_repaired = false
	_refresh_controls()


func _set_note(text: String) -> void:
	_note.text = text
	_note.visible = text != ""


## 버튼 글과 빈 동작의 경고를 지금 값으로 다시 쓴다.
func _refresh_controls() -> void:
	var empties: Array[String] = []
	for action in Controls.ACTIONS:
		var code := String(_settings.controls[action])
		var button := _binds[action] as Button
		button.text = BIND_WAIT_TEXT if _waiting == action else Controls.name_of(code)
		if code == "" and _waiting != action:
			button.add_theme_color_override("font_color", Ui.ACCENT)
		else:
			button.remove_theme_color_override("font_color")
		if code == "":
			empties.append(String(Controls.LABELS[action]))
	_warn.text = CONTROLS_EMPTY_WARN % " · ".join(PackedStringArray(empties)) if not empties.is_empty() else ""
	_warn.visible = not empties.is_empty()


func _begin_wait(action: StringName) -> void:
	_waiting = action
	_capture_msec = Time.get_ticks_msec()
	_eat_release = ""
	_refresh_controls()
	_set_note(BIND_WAIT_NOTE % Controls.LABELS[action])


func _end_wait(note: String) -> void:
	_waiting = &""
	_refresh_controls()
	_set_note(note)


func _on_controls_reset() -> void:
	_waiting = &""
	_eat_release = ""
	var changed: bool = _settings.reset_controls()
	_refresh_controls()
	_set_note("처음 값으로 되돌렸다" if changed else "이미 처음 값이다")
	_settings.save()


## 기다리는 동안의 입력을 GUI보다 먼저 받는다(잡은 누름이 아래 버튼에 닿지 않게). 결정 520.
func _input(event: InputEvent) -> void:
	if _eat_release != "" and not event.is_pressed() and Controls.code_of(event) == _eat_release:
		_eat_release = ""
		get_viewport().set_input_as_handled()
		return
	if _waiting == &"" or not (event is InputEventKey or event is InputEventMouseButton) or not event.is_pressed():
		return
	_eat_release = ""
	if Ui.is_arrival_press(event, _capture_msec, Time.get_ticks_msec()):
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT \
			and _over_other_button((event as InputEventMouseButton).position):
		_end_wait("")
		return
	get_viewport().set_input_as_handled()
	if event.is_action_pressed(&"ui_cancel"):
		_end_wait("그대로 두었다")
		return
	var code := Controls.code_of(event)
	if code == "":
		_set_note("쓸 수 없는 입력이다 — 다른 것을 누른다")
		return
	var result: Dictionary = _settings.set_control(_waiting, code)
	var action := _waiting
	match result["result"]:
		&"reserved":
			_set_note("쓸 수 없는 키다 (%s · %s) — 다른 것을 누른다" % [Controls.name_of(code), result["use"]])
		&"same":
			_eat_release = code
			_end_wait("그대로 두었다")
		&"cleared":
			_eat_release = code
			_end_wait("겹쳤다 — %s: %s · %s 이제 비었다" % [Controls.LABELS[action], Controls.name_of(code), Controls.TOPICS[result["other"]]])
			_settings.save()
		_:
			_eat_release = code
			_end_wait("")
			_settings.save()


## 기다리는 칸 밖의 보이는 버튼 위인가(위치는 뷰포트 좌표이고 설정 화면의 층에는 변환이 없다).
func _over_other_button(point: Vector2) -> bool:
	for node in find_children("*", "BaseButton", true, false):
		var button := node as BaseButton
		if button == _binds.get(_waiting) or not button.is_visible_in_tree():
			continue
		if button.get_global_rect().has_point(point):
			return true
	return false


func _build_display(body: VBoxContainer) -> void:
	body.add_theme_constant_override("separation", 12)
	var mode_row := HBoxContainer.new()
	mode_row.add_theme_constant_override("separation", 12)
	body.add_child(mode_row)
	var mode_label := Ui.add_label(mode_row, "화면", 24)
	mode_label.custom_minimum_size = Vector2(160, 0)
	var mode_group := ButtonGroup.new()
	for mode in Display.MODES:
		var button := Ui.add_button(mode_row, Display.MODE_LABELS[mode], 20, "DisplayWindowed" if mode == &"windowed" else "DisplayFullscreen")
		button.toggle_mode = true
		button.button_group = mode_group
		button.custom_minimum_size = Vector2(160, 42)
		_mode_buttons[mode] = button
	var size_row := HBoxContainer.new()
	size_row.add_theme_constant_override("separation", 8)
	body.add_child(size_row)
	var size_label := Ui.add_label(size_row, "창 크기", 24)
	size_label.custom_minimum_size = Vector2(160, 0)
	var size_group := ButtonGroup.new()
	var row := size_row
	var count := 0
	for dims: Vector2i in _settings.available_sizes():
		# 170폭 버튼 다섯은 한 줄에 못 든다(판 폭 800): 한 줄에 셋씩, 둘째 줄은 라벨 폭만큼 들여 쓴다.
		if count > 0 and count % 3 == 0:
			row = HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			body.add_child(row)
			var indent := Control.new()
			indent.custom_minimum_size = Vector2(160, 0)
			row.add_child(indent)
		count += 1
		var button := Ui.add_button(row, Display.size_name(dims), 18, "Size_%dx%d" % [dims.x, dims.y])
		button.toggle_mode = true
		button.button_group = size_group
		button.custom_minimum_size = Vector2(170, 42)
		_size_buttons[dims] = button
	_display_now = Ui.add_label(body, "", 18)
	_display_now.name = "DisplayNow"
	var hint := Ui.add_wrapped(body, DISPLAY_HINT, 16, Ui.DIM)
	hint.name = "DisplayHint"
	hint.custom_minimum_size = Vector2(CONTENT_WIDTH, 0)
	var notes: Array[String] = []
	if _settings.display_repaired:
		notes.append(DISPLAY_REPAIRED_NOTE)
		_settings.display_repaired = false
	var plan: Dictionary = _settings.last_plan
	if bool(plan.get("clamped", false)):
		var wanted: Vector2i = _settings.display["size"]
		var opened: Vector2i = plan["size"]
		notes.append("이 모니터에 %s 창이 들어가지 않아 %s 열었다" % [Display.size_name(wanted), _with_ro(Display.size_name(opened))])
	var note := Ui.add_wrapped(body, "\n".join(PackedStringArray(notes)), 18)
	note.name = "DisplayNote"
	note.custom_minimum_size = Vector2(CONTENT_WIDTH, 0)
	note.visible = not notes.is_empty()
	# 처음 값은 신호 없이 넣고 신호는 그 뒤에 잇는다(결정 500). pressed로 잇는다: 이미 눌린 버튼을 다시 눌러도 닿는다(결정 526).
	_refresh_display()
	for mode in _mode_buttons:
		(_mode_buttons[mode] as Button).pressed.connect(_on_display_mode.bind(mode))
	for dims in _size_buttons:
		(_size_buttons[dims] as Button).pressed.connect(_on_display_size.bind(dims))


## 마지막 글자의 받침으로 "으로"와 "로"를 고른다(크기 이름은 숫자로 끝난다: 1·8은 ㄹ 받침, 0·3·6·7은 받침).
static func _with_ro(text: String) -> String:
	return text + ("으로" if text.right(1) in ["0", "3", "6", "7"] else "로")


func _on_display_mode(mode: StringName) -> void:
	_settings.set_display_mode(mode)
	_settings.save()
	_refresh_display()


func _on_display_size(dims: Vector2i) -> void:
	_settings.set_window_size(dims)
	_settings.save()
	_refresh_display()


func _on_settings_changed(section: StringName, _key: StringName) -> void:
	if section == &"display":
		_refresh_display()


## 눌림과 "지금" 글만 다시 쓴다. 노드를 붙이거나 떼지 않는다(결정 527).
func _refresh_display() -> void:
	if _display_now == null or not is_instance_valid(_display_now):
		return
	var mode: StringName = _settings.display["mode"]
	for key in _mode_buttons:
		(_mode_buttons[key] as Button).set_pressed_no_signal(key == mode)
	# 전체 화면에서도 창으로 돌아갈 크기가 눌려 있다. 적힌 크기가 목록에 없으면(줄인 때) 줄인 크기가 눌린다.
	var wanted: Vector2i = _settings.display["size"]
	var plan: Dictionary = _settings.last_plan
	var pressed: Vector2i = wanted if _size_buttons.has(wanted) else plan.get("size", wanted)
	for key in _size_buttons:
		(_size_buttons[key] as Button).set_pressed_no_signal(key == pressed)
	var text := "지금: %s" % Display.MODE_LABELS[mode]
	if _settings.window_locked:
		if mode == &"windowed":
			text += " " + Display.size_name(plan.get("size", wanted))
	else:
		var window := get_window()
		var window_size := window.size
		var fullscreen := window.mode == Window.MODE_FULLSCREEN
		text = "지금: %s %s" % ["전체 화면" if fullscreen else "창", Display.size_name(window_size)]
		if not fullscreen and mode == &"windowed" and window_size != plan.get("size", window_size):
			text += " — 끌어서 바꿨다 · 다음에 켜면 %s" % Display.size_name(wanted)
	_display_now.text = text


func _close() -> void:
	_waiting = &""
	if _settings.changed.is_connected(_on_settings_changed):
		_settings.changed.disconnect(_on_settings_changed)
	if get_window().size_changed.is_connected(_refresh_display):
		get_window().size_changed.disconnect(_refresh_display)
	_settings.save()
	closed.emit()
	var parent := get_parent()
	if parent != null:
		parent.remove_child(self)
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		# _close가 트리에서 떼기 전에 뷰포트를 쥔다.
		var viewport := get_viewport()
		_close()
		viewport.set_input_as_handled()


## 테마에 HSlider의 꼴이 없어(033b) 이 스크립트가 잉크 줄과 원 손잡이로 덮는다(결정 502).
func _style_slider(slider: HSlider) -> void:
	var track := StyleBoxFlat.new()
	track.bg_color = Ui.INK
	track.content_margin_top = 2
	track.content_margin_bottom = 2
	var filled := StyleBoxFlat.new()
	filled.bg_color = Ui.ACCENT
	filled.content_margin_top = 2
	filled.content_margin_bottom = 2
	slider.add_theme_stylebox_override("slider", track)
	slider.add_theme_stylebox_override("grabber_area", filled)
	slider.add_theme_stylebox_override("grabber_area_highlight", filled)
	slider.add_theme_icon_override("grabber", _make_grabber(Ui.PARCHMENT))
	slider.add_theme_icon_override("grabber_highlight", _make_grabber(Ui.PARCHMENT.lightened(0.25)))


## 잉크 테두리에 양피지 속의 원.
static func _make_grabber(fill: Color) -> ImageTexture:
	var image := Image.create(GRABBER_SIZE, GRABBER_SIZE, false, Image.FORMAT_RGBA8)
	var center := (GRABBER_SIZE - 1) / 2.0
	var radius := GRABBER_SIZE / 2.0
	for y in GRABBER_SIZE:
		for x in GRABBER_SIZE:
			var dist := Vector2(x - center, y - center).length()
			var edge := clampf(radius - dist, 0.0, 1.0)
			var color := Ui.INK if dist > radius - 2.5 else fill
			color.a = edge
			image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)
