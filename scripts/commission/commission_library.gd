class_name CommissionLibrary
extends RefCounted
## 폴더 안의 의뢰 .tres를 모아 준다. 새 의뢰는 파일만 넣으면 목록에 나온다.
## 에디터 실행 기준이다(내보낸 빌드에서는 파일명이 .remap으로 바뀐다).


## dir_path 안의 .tres 중 Commission인 것을 파일 이름순으로 로드한다.
static func load_all(dir_path: String) -> Array[Commission]:
	var out: Array[Commission] = []
	var files := DirAccess.get_files_at(dir_path)
	files.sort()
	for file in files:
		if file.get_extension() != "tres":
			continue
		var commission := load(dir_path.path_join(file)) as Commission
		if commission != null:
			out.append(commission)
	return out


## dir_path와 그 아래 폴더의 의뢰를 모은다: 바로 아래의 파일(이름순) 다음에 하위 폴더(이름순)의 것(연습 화면, 결정 595).
static func load_tree(dir_path: String) -> Array[Commission]:
	var out: Array[Commission] = []
	if not DirAccess.dir_exists_absolute(dir_path):
		return out
	var files := Array(DirAccess.get_files_at(dir_path))
	files.sort()
	for file: String in files:
		# 내보낸 빌드에서는 .tres가 .remap으로 보인다.
		var path := dir_path.path_join(file.trim_suffix(".remap"))
		if path.get_extension() != "tres":
			continue
		var commission := load(path) as Commission
		if commission != null:
			out.append(commission)
	var folders := Array(DirAccess.get_directories_at(dir_path))
	folders.sort()
	for folder: String in folders:
		out.append_array(load_tree(dir_path.path_join(folder)))
	return out
