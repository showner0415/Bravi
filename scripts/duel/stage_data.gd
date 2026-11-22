class_name StageData
extends Resource
## 결투 무대 하나(결정 294). 표시만 하고 판정에 쓰지 않는다. 의뢰의 stage 칸이 가리킨다.

@export var stage_name := ""
## 16:9로 잘라 둔 무대 그림(assets/art/stages/, 결정 296). 결투 씬이 비율을 지켜 화면을 덮는다.
@export var texture: Texture2D
