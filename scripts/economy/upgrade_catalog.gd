class_name UpgradeCatalog
extends Resource
## 가게에 나오는 업그레이드의 목록. 배열의 순서대로 보인다.

@export var upgrades: Array[UpgradeData] = []


## id로 찾는다. 없으면 null.
func find(id: StringName) -> UpgradeData:
	for upgrade in upgrades:
		if upgrade != null and upgrade.id == id:
			return upgrade
	return null
