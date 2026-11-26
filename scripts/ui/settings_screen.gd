class_name SettingsScreen
extends Control
## 설정 화면(계획 S01, 결정 502). 처음 열 때 만드는 덮개: 탭 줄과 탭의 몸, 닫기. 코드로 짓는다(도움말의 덮개 꼴).
## 일시정지 아래에서도 돌도록(S02) 덮개는 PROCESS_MODE_ALWAYS이고 시간은 Time.get_ticks_msec()만 쓴다.

const Ui := preload("res://scripts/day_ui.gd")

## [갈래 키, 탭 글, 몸을 짓는 메서드의 이름]. const에는 Callable을 담을 수 없어 이름을 담고 call()로 부른다.
## S03은 조작, S04는 화면 탭을 이 목록에 한 줄씩 더한다.
const TABS: Array = [[&"audio", "소리", &"_build_audio"]]

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
var _slider: HSlider
var _volume_value: Label
var _mute_button: Button
var _muted_note: Label
var _last_preview_msec := -100000
## 거른 미리 듣기가 있다. drag_ended는 이것이 켜져 있을 때만 소리를 낸다(홈을 한 번 누를 때 두 번 울리지 않게).
var _preview_pending := false


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
	_body = VBoxContainer.new()
	_body.name = "TabBody"
	_body.add_theme_constant_override("separation", 16)
	column.add_child(_body)

	var close := Ui.add_button(self, CLOSE_TEXT, 20, "SettingsClose")
	close.position = Vector2(540, 636)
	close.size = Vector2(200, 54)
	close.pressed.connect(_close)

	(_tab_group.get_buttons()[0] as Button).set_pressed_no_signal(true)
	_select_tab(0)
	# Space·Enter가 아래의 버튼을 누르지 않게 초점을 닫기 버튼에 둔다.
	close.grab_focus()


func _select_tab(index: int) -> void:
	for child in _body.get_children():
		_body.remove_child(child)
		child.queue_free()
	call(TABS[index][2], _body)


func _build_audio(body: VBoxContainer) -> void:
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


func _close() -> void:
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
