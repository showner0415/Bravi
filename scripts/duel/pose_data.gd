class_name PoseData
extends Resource
## 상대의 포즈 하나(바이블 15절 "포즈의 꼴"). 각은 도, 시계 방향이 +다. 따로 그린 팔(arm_art)은 030이 더한다.

## 칼 든 팔의 각. 0이면 팔이 곧게 아래로 내려온다.
@export var arm_deg := 0.0
## 칼의 화면 각. 0이면 칼끝이 위.
@export var sword_deg := 0.0
@export var head_deg := 0.0
## 몸의 기울기(골반에서).
@export var lean_deg := 0.0
## 어깨 옮김(파츠 단위).
@export var shoulder := Vector2.ZERO
