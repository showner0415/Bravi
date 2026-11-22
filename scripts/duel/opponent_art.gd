class_name OpponentArt
extends Resource
## 상대 한 명의 그림: 파츠 열 장과 관절 자리(결정 256). 비어 있는 파츠는 그리지 않는다.

@export_group("파츠")
@export var legs: PartArt
@export var torso: PartArt
## 머리 셋: 대기·예비 동작·방심·피하기 / 회수 / 무너짐(결정 260).
@export var head: PartArt
@export var head_oops: PartArt
@export var head_dizzy: PartArt
@export var hat: PartArt
## 깃털은 모자 원점에 오프셋 없이 둔다. 관절은 그림 밖의 피벗이다(MANIFEST).
@export var feather: PartArt
@export var arm: PartArt
@export var hand: PartArt
@export var sword: PartArt

@export_group("관절 자리 (파츠 단위)")
## 목: Torso 좌표에서 Head의 원점.
@export var neck := Vector2(0, -200)
## Head 좌표에서 Hat의 원점.
@export var hat_at := Vector2(0, -104)
## 칼 든 팔의 어깨: Torso 좌표에서 Arm의 원점(칼 팔이 왼쪽일 때).
@export var shoulder := Vector2(-65, -180)
## Arm 좌표에서 Hand의 원점(손목).
@export var hand_at := Vector2(0, 105)
## Hand 좌표에서 Sword의 원점(쥔 점).
@export var sword_at := Vector2(0, 15)
