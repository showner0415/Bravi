class_name StyleTier
extends Resource
## 검술의 한 단(2단부터). 상대의 공격 목록을 통째로 바꾸는 값이다(계획 040, 결정 579).

## 이 날부터 이 단이다.
@export var from_day := 1
## 그 단의 일반 공격 전부(기본과 고유를 함께 적는다).
@export var attacks: Array[AttackData] = []
