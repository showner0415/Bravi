extends RefCounted
## 저장 파일의 읽기와 쓰기. 파일만 안다(무엇이 읽을 수 있는 저장인지는 DayState가 안다).
## 깨진 파일은 예상한 입력이다: 오류를 찍지 않고 빈 Dictionary를 돌려준다.
## 쓰기는 옆의 임시 파일에 다 적고 다시 읽어 견준 뒤 원래 파일과 바꿔 끼운다(쓰는 도중 꺼져도 원래 파일이 남는다).

## 임시 파일의 이름: 원래 경로 뒤에 붙인다.
const TEMP_SUFFIX := ".tmp"

## _write_text의 결과: 다 적었다 / 열지 못했다 / 열었지만 다시 읽은 글이 다르다(덜 적혔다).
const WRITTEN := 0
const NOT_OPENED := 1
const MISMATCH := 2


## 파일의 내용. 경로가 비었거나, 파일이 없거나, 열리지 않거나, JSON이 아니거나, 맨 위가 {…}가 아니면 빈 Dictionary다.
## 원래 파일이 없고 임시 파일만 있으면(바꿔 끼우는 사이에 꺼졌다) 임시 파일을 읽는다.
## 원래 파일이 있으면 그것만 본다(깨졌어도 임시 파일로 대신하지 않는다).
static func read(path: String) -> Dictionary:
	if path == "":
		return {}
	if FileAccess.file_exists(path):
		return _parse_file(path)
	return _parse_file(path + TEMP_SUFFIX)


## 적는다. 경로가 비었거나 적지 못했으면 false다.
## 임시 파일에 다 적었으면 바꿔 끼운다. 바꿔 끼우지 못했거나 임시 파일을 열지 못했으면 경고 한 줄을 남기고
## 전처럼 원래 파일에 바로 적는다. 임시 파일이 덜 적혔으면(디스크가 찼다 등) 원래 파일은 건드리지 않고 false다.
static func write(path: String, content: Dictionary) -> bool:
	if path == "":
		return false
	var text := JSON.stringify(content)
	var temp := path + TEMP_SUFFIX
	var result := _write_text(temp, text)
	if result == MISMATCH:
		push_warning("저장: 임시 파일이 다 적히지 않아 원래 파일을 그대로 두었다: %s" % path)
		_remove(temp)
		return false
	if result == WRITTEN:
		if DirAccess.rename_absolute(temp, path) == OK:
			return true
		push_warning("저장: 임시 파일을 바꿔 끼우지 못해 바로 적는다: %s" % path)
		_remove(temp)
	else:
		push_warning("저장: 임시 파일을 열지 못해 바로 적는다: %s" % path)
	return _write_text(path, text) == WRITTEN


## 원래 파일이나 임시 파일이 있는가(읽히는지는 보지 않는다).
static func exists(path: String) -> bool:
	return path != "" and (FileAccess.file_exists(path) or FileAccess.file_exists(path + TEMP_SUFFIX))


## 원래 파일과 임시 파일을 지운다(테스트의 뒷정리가 쓴다).
static func erase(path: String) -> void:
	if path == "":
		return
	_remove(path)
	_remove(path + TEMP_SUFFIX)


## 그 파일 하나를 JSON으로 읽는다. 없거나 깨졌으면 빈 Dictionary다. 오류 줄을 찍지 않는다.
static func _parse_file(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		return {}
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return {}
	var text := file.get_as_text()
	file.close()
	# 파싱에 실패해도 엔진이 오류 줄을 찍지 않는 쪽을 쓴다(돌려준 값만 본다).
	var json := JSON.new()
	if json.parse(text) != OK:
		return {}
	if json.data is Dictionary:
		var found: Dictionary = json.data
		return found
	return {}


## 그 파일에 글을 적고 다시 읽어 견준다(WRITTEN / NOT_OPENED / MISMATCH).
static func _write_text(file_path: String, text: String) -> int:
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		return NOT_OPENED
	file.store_string(text)
	file.close()
	return WRITTEN if FileAccess.get_file_as_string(file_path) == text else MISMATCH


static func _remove(file_path: String) -> void:
	if FileAccess.file_exists(file_path):
		DirAccess.remove_absolute(file_path)
