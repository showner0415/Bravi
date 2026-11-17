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
