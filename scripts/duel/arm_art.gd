class_name ArmArt
extends Resource
## 따로 그린 칼 팔 하나(결정 266). 보이는 동안 Arm의 그림과 Hand(칼·윤곽선 포함)를 감춘다(결정 237).

## PoseData.arm_art가 가리키는 이름(바이블 15절 armUp, armThrust).
@export var key: StringName
## 층 묶음의 회전(도). 든 팔은 시트에서 주먹이 위라 180으로 팔의 +y(손 쪽)에 맞춘다.
@export var rotation_deg := 0.0
@export var layers: Array[ArmLayer] = []
