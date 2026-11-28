extends SceneTree
## 지킴의 골든(계획 044 결정 679): 일곱 상대 x 단 {1, 마지막} x 봇 둘 = 28판의 이벤트 줄을 SHA-256으로 줄여 골든 파일과 견준다.
## 실행: tests/run_event_digest.ps1 [-Write]. -Write면 골든을 쓰고(코드를 고치기 전 커밋에서만), 아니면 견줘서 줄을 낸다.
## 셈은 정적 함수 digest_row 하나다. T134(feint_tests.gd)가 같은 함수를 부른다.

const Bot := preload("res://tests/duel_bots.gd")

const GOLDEN_PATH := "res://tests/golden/event_digest.txt"
const RULES_PATH := "res://data/duel_rules.tres"
const WEAPON_PATH := "res://data/weapons/rapier.tres"
const OPPONENT_PATHS: Array[String] = [
	"res://data/opponents/opponent_01.tres",
	"res://data/opponents/opponent_02.tres",
	"res://data/opponents/opponent_03.tres",
	"res://data/opponents/opponent_04.tres",
	"res://data/opponents/opponent_05.tres",
	"res://data/opponents/opponent_06.tres",
	"res://data/opponents/opponent_07.tres",
]
const TIERS: Array[String] = ["1", "last"]
const BOTS: Array[String] = ["first_blood", "parry"]
const SEEDS := 7
const LIMIT := 60.0
const DELTA := 1.0 / 60.0
## 통계의 -Opening 3과 같은 사본이다.
const OPENING_DAY := 3
const JITTER := 0.15


func _initialize() -> void:
	var write := "--write" in OS.get_cmdline_user_args()
	var lines: PackedStringArray = []
	for path in OPPONENT_PATHS:
		for tier in TIERS:
			for bot in BOTS:
				var row := digest_row(path, tier, bot)
				lines.append(str(row["line"]))
				print("digest,%s" % row["line"])
	if write:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(GOLDEN_PATH.get_base_dir()))
		var file := FileAccess.open(GOLDEN_PATH, FileAccess.WRITE)
		if file == null:
			print("ERROR: 골든 파일을 열지 못함 %s" % GOLDEN_PATH)
			quit(1)
			return
		for line in lines:
			file.store_line(line)
		file.close()
		print("EVENT DIGEST WRITTEN %d" % lines.size())
		quit(0)
		return
	var result := check(read_golden())
	for message: String in result["messages"]:
		print(message)
	if bool(result["ok"]):
		print("EVENT DIGEST OK %d skipped %d" % [int(result["rows"]), int(result["skipped"])])
		quit(0)
	else:
		print("EVENT DIGEST FAIL")
		quit(1)


## 골든 파일의 줄들(빈 줄 제외). 파일이 없으면 빈 배열이다.
static func read_golden() -> PackedStringArray:
	var out: PackedStringArray = []
	if not FileAccess.file_exists(GOLDEN_PATH):
		return out
	var text := FileAccess.get_file_as_string(GOLDEN_PATH)
	for line in text.split("\n", false):
		var trimmed := line.strip_edges()
		if trimmed != "":
			out.append(trimmed)
	return out


## 골든의 줄들을 다시 셈해 견준다. 데이터의 해시가 다른 줄은 건너뛴다(그 상대의 데이터가 뒤에 바뀌었다).
## 돌려줌: ok, rows, skipped, diffs(Array[String]), messages(Array[String]). 줄이 없거나 모두 건너뛰어지면 ok는 거짓이다.
static func check(golden: PackedStringArray) -> Dictionary:
	var diffs: Array[String] = []
	var messages: Array[String] = []
	var skipped := 0
	if golden.is_empty():
		diffs.append("골든 파일 %s가 없거나 비었다 — run_event_digest.ps1 -Write로 쓴다" % GOLDEN_PATH)
	for line in golden:
		var fields := line.split(",")
		if fields.size() != 6:
			diffs.append("줄의 꼴이 다르다: %s" % line)
			continue
		var row := digest_row(fields[0], fields[1], fields[2])
		if str(row["data_sha"]) != fields[3]:
			skipped += 1
			messages.append("  INFO 데이터가 바뀌어 건너뜀: %s 단 %s 봇 %s" % [fields[0], fields[1], fields[2]])
			continue
		if str(row["digest"]) != fields[4] or int(row["events"]) != int(fields[5]):
			diffs.append("%s 단 %s 봇 %s: 이벤트 줄이 다르다 (골든 %s %s개 · 지금 %s %d개)" % [
				fields[0], fields[1], fields[2], fields[4].left(12), fields[5], str(row["digest"]).left(12), int(row["events"])])
	if not golden.is_empty() and skipped == golden.size():
		diffs.append("골든의 %d줄이 모두 건너뛰어졌다 — 지킴이 낡았다" % skipped)
	for diff in diffs:
		messages.append("  DIFF %s" % diff)
	return {"ok": diffs.is_empty(), "rows": golden.size(), "skipped": skipped, "diffs": diffs, "messages": messages}


## 한 줄: tier는 "1" 또는 "last", bot은 "first_blood" 또는 "parry".
## 돌려줌: line(골든의 한 줄), data_sha, digest, events. 상대 · 규칙 · 칼은 캐시를 쓰지 않고 읽는다(T134가 한 프로세스에서 메모리를 고친 자원을 보지 않게).
static func digest_row(path: String, tier: String, bot: String) -> Dictionary:
	var rules: DuelRules = ResourceLoader.load(RULES_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as DuelRules
	var weapon: WeaponData = ResourceLoader.load(WEAPON_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as WeaponData
	var base: OpponentData = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as OpponentData
	var data_ctx := HashingContext.new()
	data_ctx.start(HashingContext.HASH_SHA256)
	for data_path in [path, RULES_PATH, WEAPON_PATH]:
		data_ctx.update(FileAccess.get_sha256(data_path).to_utf8_buffer())
	var data_sha := data_ctx.finish().hex_encode()
	var opponent: OpponentData = base
	if tier == "last":
		opponent = base.at_tier(base.tier_count() - 1)
	opponent = opponent.with_opening(rules.opening_chance_for(opponent.opening_chance, OPENING_DAY))
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	var count := 0
	for seed_value in range(1, SEEDS + 1):
		ctx.update(("seed %d\n" % seed_value).to_utf8_buffer())
		var record := _play(rules, weapon, opponent, seed_value, bot)
		for ev in record.events:
			ctx.update((event_text(ev) + "\n").to_utf8_buffer())
			count += 1
	var digest := ctx.finish().hex_encode()
	return {
		"line": "%s,%s,%s,%s,%s,%d" % [path, tier, bot, data_sha, digest, count],
		"data_sha": data_sha, "digest": digest, "events": count,
	}


static func _play(rules: DuelRules, weapon: WeaponData, opponent: OpponentData, seed_value: int, bot: String) -> DuelRecord:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	# 박자 봇의 흔들림은 판의 난수와 따로 뽑는다(통계 도구와 같다).
	var beat := RandomNumberGenerator.new()
	beat.seed = 2000 + seed_value
	var core := DuelCore.new()
	core.setup(rules, weapon, opponent, rng)
	var cfg: Dictionary = Bot.first_blood_cfg()
	if bot == "parry":
		var parry := func(_atk: AttackData, _index: int) -> StringName:
			return &"parry"
		cfg["guard_fn"] = parry
		cfg["step_fn"] = parry
		cfg["parry_error_fn"] = func(wait: float) -> float:
			return JITTER * wait * (beat.randf() * 2.0 - 1.0)
	var driver := Bot.new(core, cfg)
	while not core.ended and core.time < LIMIT:
		core.tick(DELTA)
		driver.update()
	return core.record


## 이벤트 하나의 글: 종류, 열쇠를 글자 차례로 늘어놓은 "열쇠=값". 값은 value_text.
static func event_text(ev: Dictionary) -> String:
	var names: Array[String] = []
	var keys := {}
	for key in ev:
		names.append(str(key))
		keys[str(key)] = key
	names.sort()
	var parts: PackedStringArray = []
	for key_name in names:
		parts.append("%s=%s" % [key_name, value_text(ev[keys[key_name]])])
	return ",".join(parts)


## 직렬화 규칙: 공격 자원은 attack_name|direction|tell_time(%.5f), 실수는 %.5f, 배열은 [..], 사전은 열쇠 차례의 {..}, 나머지는 str.
## 시각 · 경로 · 인스턴스 번호처럼 흔들리는 값은 넣지 않는다.
static func value_text(value: Variant) -> String:
	if value is AttackData:
		var atk: AttackData = value
		return "%s|%d|%.5f" % [atk.attack_name, int(atk.direction), atk.tell_time]
	if value is float:
		return "%.5f" % value
	if value is Array:
		var items: PackedStringArray = []
		for item in value:
			items.append(value_text(item))
		return "[%s]" % ";".join(items)
	if value is Dictionary:
		return "{%s}" % event_text(value)
	if value is Object:
		return "obj"
	return str(value)
