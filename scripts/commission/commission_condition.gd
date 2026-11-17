class_name CommissionCondition
extends Resource
## 의뢰 조건의 기반 클래스.
## 하위 클래스는 내부 상태를 갖지 않는다. 판단 근거는 전부 record에서 읽는다.
## (Resource는 로드 캐시로 공유되므로, 상태를 가지면 다시 하기 때 이전 판이 샌다.)


## 의뢰 선택 화면과 HUD에 쓰는 조건 설명.
func describe() -> String:
	return ""


## 결투를 끝내야 하면 종료 사유 문구를, 계속이면 빈 문자열을 돌려준다.
func check_end(_record: DuelRecord) -> String:
	return ""


## 충족도 0~100. 종료된 record에 대해서만 의미가 있다.
func evaluate(_record: DuelRecord) -> int:
	return 0


## 결과 화면의 항목별 내역.
func explain(_record: DuelRecord) -> Array[String]:
	return []


## 결투 중 HUD 게이지. 비어 있으면 게이지 없음.
## 있으면 {label: String, value: int 0~100, pending: int}.
func live_meter(_record: DuelRecord) -> Dictionary:
	return {}
