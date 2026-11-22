class_name PartArt
extends Resource
## 상대 파츠 하나의 그림. 값은 assets/MANIFEST.md의 "관절"·"단위/화소" 칸이다(결정 256).

@export var texture: Texture2D
## 관절의 자리(자른 그림의 화소). 이 점이 파츠 노드의 원점에 온다.
@export var joint := Vector2.ZERO
## 그림 한 화소가 파츠 단위로 몇인가(가로, 세로).
@export var units_per_px := Vector2.ONE
