extends RefCounted
## 저장 파일의 읽기와 쓰기. 파일만 안다(무엇이 읽을 수 있는 저장인지는 DayState가 안다).
## 깨진 파일은 예상한 입력이다: 오류를 찍지 않고 빈 Dictionary를 돌려준다.


## 파일의 내용. 경로가 비었거나, 파일이 없거나, 열리지 않거나, JSON이 아니거나, 맨 위가 {…}가 아니면 빈 Dictionary다.
static func read(path: String) -> Dictionary:
	if path == "" or not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
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


## 한 번에 적는다. 경로가 비었거나 파일이 열리지 않으면 false다.
static func write(path: String, content: Dictionary) -> bool:
	if path == "":
		return false
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(content))
	file.close()
	return true


static func exists(path: String) -> bool:
	return path != "" and FileAccess.file_exists(path)


## 파일을 지운다(테스트의 뒷정리가 쓴다).
static func erase(path: String) -> void:
	if exists(path):
		DirAccess.remove_absolute(path)
