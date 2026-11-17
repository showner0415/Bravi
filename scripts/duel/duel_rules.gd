class_name DuelRules
extends Resource
## 결투 한 판의 공통 규칙 수치.

## 제한 시간(초). 지나면 시간 초과로 끝난다.
@export var time_limit := 90.0
## 플레이어 자세. 이만큼 스침당한 뒤 한 번 더 맞으면 패배한다.
@export var player_posture_max := 3
## 빈틈 인정 유예(초). 상대의 빈틈(회수·무너짐)이 끝난 뒤 이 시간 안에 누른 공격은 섣부른 공격으로 치지 않는다.
@export var opening_grace := 0.15
