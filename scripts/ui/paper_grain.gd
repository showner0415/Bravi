extends RefCounted
## 견본 025의 `paper` 필터(큰 결과 잔 결)를 코드로 옮긴 결 텍스처(결정 312 가). 처음 부를 때 한 번 만든다.

const SIZE := 256
## 견본의 큰 결은 가로 0.012 · 세로 0.02다. 세로 값으로 만들고 가로로 1.67배 늘려 깐다.
const DRAW_SIZE := Vector2(427, 256)
## SVG 난류의 값은 대개 가운데 절반에 모인다. 정규화한 노이즈를 그 폭으로 좁혀 견본의 세기에 맞춘다(어림, 판 N1에서 본다).
const SPAN := 0.5
const BIG_COLOR := Color(0.36, 0.25, 0.15)
const FINE_COLOR := Color(0.3, 0.2, 0.12)

static var _texture: ImageTexture


static func texture() -> Texture2D:
	if _texture == null:
		_texture = ImageTexture.create_from_image(_make())
	return _texture


static func _make() -> Image:
	var big: Image = _noise(2, 0.02, 3).get_seamless_image(SIZE, SIZE)
	var fine: Image = _noise(5, 0.85, 2).get_seamless_image(SIZE, SIZE)
	var out := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for y in SIZE:
		for x in SIZE:
			var a_big := clampf(0.45 * _span(big.get_pixel(x, y).r) - 0.14, 0.0, 1.0)
			var a_fine := clampf(0.3 * _span(fine.get_pixel(x, y).r) - 0.08, 0.0, 1.0)
			# 견본의 feMerge 차례: 잔 결이 큰 결 위에 얹힌다.
			var a := a_fine + a_big * (1.0 - a_fine)
			if a <= 0.0:
				out.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			var rgb := (FINE_COLOR * a_fine + BIG_COLOR * a_big * (1.0 - a_fine)) / a
			out.set_pixel(x, y, Color(rgb.r, rgb.g, rgb.b, a))
	return out


static func _noise(seed_value: int, frequency: float, octaves: int) -> FastNoiseLite:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.seed = seed_value
	noise.frequency = frequency
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = octaves
	return noise


static func _span(value: float) -> float:
	return 0.5 + (value - 0.5) * SPAN
