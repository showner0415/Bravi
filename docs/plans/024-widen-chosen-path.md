# 계획 024: 고른 길로 넓히기 — 파츠 시트, 무대 둘, 비토리오, 기준 이미지와 팔레트

- 버전: v3 (1회차 검토 대응: T1·T2, 비차단 제안 둘. v2는 사용자 답 Q1. 끝의 "수정 기록")
- 개발 단계: CLAUDE.md 9장 **3단계(스타일 바이블)의 다섯째 계획**. 게임 코드·씬·데이터·테스트는 고치지 않는다(교체는 4단계)
- 근거:
  - 결정 201(3단계의 남은 나눔: 024는 넓히기·기준 이미지 고르기와 올리기·팔레트 확정), 결정 209(사용자가 고른 만드는 길. **다시 시험하지 않는다**), `docs/reports/023-style-transfer-new-drawing.md` 4번·5번.
  - 사용자 지시(2026-11-22): "계속 진행해줘. 내가 꼭 결정해야되는게 있으면 선택할 수 있는 창 띄워." → 묻는 것은 꼭 필요한 것만 선택지로. 되돌리기 쉬운 것은 이 계획이 정하고 까닭을 적는다("설계 결정").
  - 기준 그림(로컬 `docs/style/generated/`, 사용자가 셋 다 "맞다"): 인물 `023-R1i-bartolo-front.png`, 무대 `023-R2-stage-alley.png`, 의뢰인 `023-R3-client-clara.png`.
  - 023에서 배운 것(`docs/style/GENERATION.md` "계획 023", `docs/HANDOFF.md` 1번):
    - 꼴은 말보다 그림이 옮긴다. 우리 그림을 넣고 자세를 다르게 주고 "베끼지 말라"고 적으면 따라 그리지 않는다.
    - 고른 그림을 바탕으로 넣고 "그대로 두고 이것만"이라고 적으면 실루엣이 화소 단위로 지켜진다(R1h → R1i). 고칠 것은 이 길로 한 장에 하나씩 고친다.
    - 사용자는 그림을 보고 나서야 원하는 것을 말할 수 있었다(인물에 아홉 장, 상한 8에 11장). → 장 수는 그림마다의 몫으로 넉넉히 잡고, 승인은 그림을 보는 곳에만 둔다.
    - 전신의 재는 자리(K2′의 열두 점)는 굳은 정면 자세용이다. 파츠 시트는 021 G2 때의 파츠별 자리를 쓴다(`GENERATION.md` "화풍 판정의 기준 맞추기").
    - 한 장에 약 1분, 4만 토큰, 5시간 창 +0.4% 안팎.
  - 쓰는 것: 절차와 막는 장치는 `GENERATION.md` "절차"(결정 184·192)와 F11. 파츠로 나누기는 같은 파일 "파츠로 나누기와 비례 맞추기"(결정 188). 프롬프트 블록은 `docs/style/STYLE_SPEC.md`(결정 195: 명세를 먼저 고치고 프롬프트에 글자 그대로 옮긴다). 도구는 로컬 `docs/style/generated/tools/`.
  - 지키는 것: 결정 12(파츠 이름·계층·관절: `Legs` / `Torso` > `Head` > `Hat` / `Torso` > `Arm` > `Hand` > `Sword`), 결정 181(신호 구역 밖, 상대 큰 면 S ≤ 50%, 상태 색은 칠에만 80%), 결정 186(넣는 그림은 우리 그림뿐), 결정 189(생성 그림은 로컬만, 고른 것만 `docs/style/basis/`로), 결정 190(극장 금지), 명세 3부 G1~G8.
  - 넘지 않는 선:
    - 메인은 Godot을 어떤 방식으로도 실행하지 않는다. Edge headless 굽기·Codex CLI·화소 재기는 이 규칙 밖이다.
    - 그림은 Codex CLI로 `gpt-6.2-sol`·`high`만, 호출마다 명시하고 사용자의 Codex(`~/.codex/config.toml`, 로그인, 기능, `generated_images/`)는 바꾸지 않는다. 돌리기 전에 장 수를 알린다. 참고 스크린샷을 넣지 않고 게임·제작사·작가 이름을 쓰지 않는다.
    - 고치지 않는 것: `scripts/`, `scenes/`, `data/`, `tests/`, `project.godot`, `docs/BACKLOG.md`, 2단계의 보류 값, 견본 `020-bridge.html`·`021-detail.html`·`022-mix.html`·`023-redraw.html`, 020~023의 프롬프트 파일, 사용자의 파일(`.claude/agents/playtester.md`, `tools/`, `docs/plans/013-playtester.md`).
- 번호: 024. 결정 번호는 210부터다.

## 목표와 범위

**확인할 결과**. 메인은 파일 읽기·Grep·Glob·git, 구운 PNG와 생성 그림의 Read, 재기 스크립트로 확인한다. 화풍과 "같은 사람인가"의 마지막 판정은 사용자의 눈이다.

1. 바르톨로의 **파츠 시트**가 R1i와 같은 사람으로 그려졌고(정면, 떨어진 파츠 열, 머리 셋), 결정 12의 이름·관절로 잘려 견본에서 조립된다.
2. 그 파츠로 **023에서 못 한 확인**을 했다: 상태 색이 칠에만 얹히고 그림자까지 물드는가, 머리 104로 맞춰지는가, 두 줄 글자 상자와 겹치지 않는가, 멀리(×0.55)에서 선과 얼굴이 남는가.
3. **무대 둘**(안뜰·광장)과 **비토리오**가 결정 209의 길로 그려져 견본에 놓였다.
4. 사용자가 그림을 보고 **기준 이미지를 골랐고**, 고른 것이 `docs/style/basis/`에 색인과 함께 올라가 있다.
5. **팔레트가 확정**되었다: `STYLE_SPEC.md`에서 "임시"가 빠지고, 프롬프트에 주는 값과 기준 그림에서 잰 값이 나란히 있다.
6. 게임의 대기 자세로 "여유롭게 결투에 임하는" 느낌을 내는 길이 **견본에서만** 보이고, 4단계 제안으로 남았다(게임 코드는 그대로다).
7. 장·호출이 사용자가 답한 몫 안이고, 저장소(이 계획이 더한 것 말고)와 사용자의 Codex 설정이 그대로다.

**범위 밖**: 게임의 포즈 상수·씬·셰이더(4단계), 내 손과 칼·카운터 배경의 생성, 글꼴·UI·크기 기준(025), `docs/STYLE_BIBLE.md`·`assets/MANIFEST.md`(026), `assets/`에 파일 두기, 컷아웃 리깅. 3단계 완료 기준(기준 이미지 선택 **과** `STYLE_BIBLE.md`)은 이 계획으로 채워지지 않는다.

**한 계획에 다 넣는 까닭**(결정 210): 그림 넷(파츠 시트, 안뜰, 광장, 비토리오)은 서로 기대지 않아 한 번에 돌려 한 번에 보일 수 있고, 올리기와 팔레트는 그 답을 받아 적는 일이다. 나누면 사용자가 멈춰 서는 곳만 는다. 대신 묶음마다 따로 멈출 수 있게 했다: 한 그림이 몫을 다 써도 나머지는 끝까지 간다("장 수와 승인").

## 그림 넷과 넣는 것 (결정 212·215)

파일은 `024-<번호><차례>-<이름>`이다(차례는 a부터. 고친 그림은 b, c …). 프롬프트는 `docs/style/prompts/`, 그림은 로컬 `docs/style/generated/`.

| 번호 | 그림 | 이름 | 크기 | `-i`에 넣는 것 | 프롬프트의 뼈대 |
|---|---|---|---|---|---|
| P1 | 바르톨로 파츠 시트 | `bartolo-parts` | 1536×1024 | `in-1` = `023-R1i-bartolo-front.png`(사람), `in-2` = `in/022-in-parts.png`(배치) | 지시 블록(두 장) → `Image:` → `Subject:` → P-PARTS → S-FIG2(S-PARTS의 세 줄로 바꿈) → C-FIG2 → `Background:` |
| S1 | 무대 안뜰 | `stage-court` | 1536×1024 | `in/022-in-stage-court.png` | `023-R2-stage-alley.txt`의 꼴. `Image:`·`Subject:`·`Composition:`은 `021-G5-stage-court.txt`의 것 → S-ST3(곳의 구절) → `No text, no signature.` → C-ST2(곳의 줄) |
| S2 | 무대 광장 | `stage-piazza` | 1536×1024 | `in/022-in-stage-piazza.png` | 같다(`021-G5-stage-piazza.txt`) |
| V1 | 비토리오 | `client-vittorio` | 1024×1536 | `in/022-in-client-2.png` | `023-R3-client-clara.txt`의 꼴. `Image:`·`Subject:`는 `021-G4-client-vittorio.txt`의 것 → 구도(클라라의 줄을 옮김) → S-FIG2(비토리오의 줄) → 색 → `Background:` |

- **고칠 때**(차례 b부터): 직전 그림 하나를 바탕 그림으로 넣고 "그대로 두고 이것만 바꾼다"로 쓴다(인물·시트는 P-KEEP의 꼴, 무대는 같은 꼴의 한 줄). 한 장에 하나만 고친다. 바꾸는 한 줄은 그때 `STYLE_SPEC.md`에 먼저 적는다.
- 파츠 시트에 R1i와 섞은 SVG 배치도를 **둘 다** 넣는 까닭: 사람은 R1i가, 파츠의 수와 자리는 배치도가 옮긴다(021 G2가 이 꼴로 열 파츠를 한 번에 냈다). 배치도의 꼴을 따라 그릴 위험은 "배치만 본다, 꼴과 얼굴은 첫 그림"이라는 말과 눈 확인으로 막는다(위험 2).
- 파츠 시트는 **자세가 없다**(파츠가 곧게 따로 놓인다). 전신 그림의 "여유로운 자세"는 조립할 때의 놓임으로 낸다("대기 자세").

### 머리 셋 (결정 212)

| 시트의 머리 | 표정 | 쓰는 상태 | 까닭 |
|---|---|---|---|
| 첫째 | **자신 있는 미소**(R1i의 얼굴 그대로) | 대기, 예비 동작, 방심 | 사용자가 고른 얼굴이다(R1e·R1i). 022까지의 "거만함"(반달 눈)은 "오만하고 거만해보여"로 물렸다 |
| 둘째 | 당황 | 빈틈 | 명세 표정 표 그대로 |
| 셋째 | 어지러움 | 무너짐 | 명세 표정 표 그대로 |

- 바르톨로의 성격(의뢰 대사의 "허영심 많은 싸움꾼")은 얼굴이 아니라 깃털 모자와 대사, 그리고 당황·어지러움의 낙차로 낸다. 대사는 고치지 않는다(데이터는 범위 밖). 되돌리기 쉽다: 머리 하나만 "이것만 바꾼다"로 다시 그린다.
- 명세의 표정 표에 "자신 있는 미소" 줄을 더한다(작업 1). "거만함" 줄은 남긴다(다른 상대가 쓸 수 있다).

## 장 수와 승인 (결정 211. 몫은 Q1의 사용자 답이다)

- 세는 법은 021~023과 같다(장 = 만들어진 그림, 호출 = 모델까지 간 `codex exec`).
- **몫: 그림마다, 합 20**(사용자 답 2026-11-22 "넉넉히 20장"). 몫 안에서는 고칠 것이 많아도 장 수를 다시 묻지 않는다(돌리기 전에 알리기만 한다).

| 그림 | 처음 | 고치기·다시 뽑기 | 합 |
|---|---|---|---|
| P1 파츠 시트 | 1 | 7 | 8 |
| S1 안뜰 | 1 | 2 | 3 |
| S2 광장 | 1 | 2 | 3 |
| V1 비토리오 | 1 | 3 | 4 |
| 예비(어느 그림에나, 기술 실패 포함) | — | 2 | 2 |

- 몫을 쓰는 규칙:
  - 처음 넷은 Q1의 답으로 허락받은 것이다. 돌리기 직전에 "4장을 돌린다"고 한 줄 알리고 답을 기다리지 않는다.
  - **보이기 전의 다시 뽑기는 그림마다 한 번까지**: 자를 수 없는 그림(파츠가 빠졌다·서로 닿았다·머리가 셋이 아니다·잘렸다), 기술 실패, 무대의 H6(극장)·H11(조용한 구역의 선)에 걸린 그림만이다. 그 밖의 걸림은 결과와 함께 승인 B에 올린다(사용자의 눈이 앞선다).
  - 사용자가 승인 B에서 "고친다"고 한 그림은 그 그림의 몫 안에서 바로 돌린다(돌리기 전에 장 수만 알린다).
  - 한 그림의 몫과 예비를 다 쓰면 그 그림은 더 돌리지 않고, 있는 것 가운데 가장 가까운 것을 올릴지 뺄지를 묻는다. 몫을 그림 사이에 옮기는 것은 사용자가 그 자리에서 말할 때만 한다.
- **승인 지점은 하나다**(같은 물음을 고친 그림에만 되풀이한다).

| 지점 | 때 | 묻는 것 |
|---|---|---|
| 알림 | 작업 3 직전 | 묻지 않는다. "처음 4장을 돌린다(몫 20 가운데)" 한 줄 |
| **B** | 작업 4 뒤(넷을 재고 견본을 구운 뒤) | 그림마다 하나를 고른다: **맞다 — 기준 이미지로 올린다** / **고친다**(무엇을, 한 줄) / **뺀다**(올리지 않는다) |
| B′ | 고친 그림을 다시 구운 뒤 | 고친 그림에만 같은 물음 |

- **B에서 보이는 것**: 구운 견본의 경로(`parts-raw`, `parts-idle`, `parts-states`, `parts-duel`, `parts-far`, `idle-compare`, `stage-court`, `stage-piazza`, `cmp-stage`, `client-counter`, `cmp-client`, `basis`), 그림마다 걸린 확인(있으면 먼저), 남은 몫.
- **B의 물음은 넷**(선택지 도구의 한 번에 맞춘다): 파츠 시트 / 안뜰 / 광장 / 비토리오. 전신 R1i·뒷골목 R2·클라라 R3은 이미 "맞다"를 받았으므로 묻지 않고 올린다(B에서 "이 셋도 함께 올린다"고 알린다. 빼라고 하면 뺀다).
- **B에서 알리기만 하는 것**(답이 없으면 이 계획의 값으로 간다): 머리 셋의 표정, `idle-compare`의 대기 자세 제안(4단계로 넘긴다), 확정할 팔레트 값(바지, 선 굵기, 비토리오의 옷, R2의 기와 지붕).
- 선택지 도구가 거부되면 같은 선택지를 글로 묻는다(023에서 두 번 거부되었다).
- 기다리는 동안 `docs/HANDOFF.md` 1번을 그 자리("024 승인 B를 기다린다")로 적는다.

## 프롬프트 블록 (원문은 `STYLE_SPEC.md`의 새 절 "계획 024의 블록"에 두고 글자 그대로 옮긴다)

영어, ASCII만, 큰따옴표 없이(결정 187). 있는 블록(S-FIG2, C-FIG2, S-ST3, C-ST2, P-KEEP·S-KEEP, 클라라의 줄)은 고치지 않고 아래만 더한다.

### 지시 블록 (두 장)

```
Task: call your image generation tool exactly once to create exactly one image. You may use the code tool only to make that one call. Pass both attached images to the image generation tool as referenced images by their paths: {WORKDIR}\in-1.png and {WORKDIR}\in-2.png. Give the image generation tool the text from the line that starts with Image: to the end of this message, word for word, as its prompt. Do not run shell commands. Do not read, create, change or delete any file. Do not use a browser, web search, computer use, apps or any other tool. Do not retry. When the image is done, reply with one line: done.
```

- 한 장을 넣는 그림(S1·S2·V1과 고치기)은 `023-R1i-bartolo-front.txt`의 지시 블록 그대로다.

### P1의 `Image:`·`Subject:`·`Background:`

```
Image: Landscape, 1536x1024 pixels. One sheet of separate body parts of one character for cutout animation in a 2D duel game.

Subject: Bartolo, a vain and quarrelsome gentleman duelist from a Renaissance-era Italian town, the same character as in the first referenced image. Doublet with buttons and a small plain collar, breeches, stockings, simple shoes, a small low-crowned hat with one long feather. A rapier.
```

```
Background: one plain flat light grey color, about #D8D8D8, everywhere around the parts. No floor, no cast shadow, no scenery, no frame, no text, no letters, no signature, no watermark.
```

### P-PARTS (파츠 시트의 구도)

```
Pose and layout:
- The first referenced image is our own drawing of this character and it is the character reference: draw exactly the same man, with the same drawing style, the same shapes, the same face, the same clothes, the same colors and the same line weight.
- The second referenced image is our own layout sketch. Use it only to see which parts there are and where each part goes on the sheet. Do not copy its shapes or its faces: every part looks like the first image.
- Ten separate parts, all seen strictly from the front and upright:
  1. the head three times, without the hat, each with a short neck stub and with the top of the head and the hair drawn complete. The three heads are the same size;
  2. the hat alone, without the feather;
  3. the feather alone, lying sideways;
  4. the torso alone, without arms, legs or head: the doublet with its buttons, belt and collar, with the shoulders and the base of the neck drawn complete. No arm is attached on either side;
  5. the sword arm alone, from the shoulder to the wrist, as one straight sleeve with a rounded top and the cuff at the lower end. It hangs straight down and it is short, as in the layout sketch;
  6. the sword hand alone, a closed fist as if gripping;
  7. the rapier alone: blade, guard and grip, pointing straight up;
  8. the legs alone, from the waist down: breeches, stockings and shoes, both legs straight, feet a little apart.
- Each part is drawn complete, including the areas that would be hidden behind other parts.
- Clear empty space between all parts. No part touches or overlaps another. No labels, no numbers, no guide lines, no dots. Nothing is cropped.
```

### S-PARTS (S-FIG2에서 바꾸는 세 줄)

머리 줄(`Style (...)`)과 첫째 항목:

```
Style (draw a new, original illustration in the style of the first referenced image, as described here):
- A finished cartoon parts sheet for a game, drawn with care, in the drawing style of the first referenced image: soft, simple, rounded-geometric shapes with straight sides and rounded corners. Simple and flat: a clean cartoon, not realistic and not painterly.
```

둘째 항목은 S-FIG2 그대로 두고 끝에 붙인다:

```
The first head is at ease and confident, exactly the face of the first referenced image: open eyes drawn as small solid dark dots under calm, level eyebrows, one eyebrow slightly raised, and a small confident smirk. The second head is flustered and caught off guard: eyebrows raised high, eyes drawn as small dark dots inside plain light parchment colored circles, and a small oval mouth. The third head is dizzy and dazed: crooked eyebrows, eyes drawn as two small X marks, and a wavy line for a mouth. The three heads are clearly the same man.
```

셋째 항목:

```
- Keep exactly the amount of detail of the first referenced image: the same belt buckle, shoe buckles and low heels, cuff line, softly scalloped collar edge, short fold lines on the breeches, seam lines on the doublet, fingers on the fist and band on the hat. Nothing else is added. No puffy sleeves, no ballooning breeches, no curls, no extra wrinkles.
```

- 넷째~일곱째 항목(선, 칠, 그림자, Do not add)과 C-FIG2는 그대로다. F11의 세 구절은 `new, original illustration` · `line weight` · `Do not add`다.

### P-KEEP-SHEET (파츠 시트를 고칠 때. 넣는 그림은 직전 시트 하나)

```
Pose and layout:
- The attached image is our own parts sheet and it is the base. Keep it: the same parts in the same places, the same outer silhouettes, the same shapes, the same faces, the same colors and the same line weight. Redraw it the same.
- Change only one thing, as written in the line that starts with Change. Everything else stays exactly as it is.
- Clear empty space between all parts. No part touches or overlaps another. No labels, no numbers. Nothing is cropped.
Change: <one line>
```

- `<one line>`은 자리 표시다(v3, T2). 고칠 때 사용자가 짚은 한 가지를 영어 한 줄로 바꿔 넣는다.

- 화풍 블록은 S-FIG2의 머리 줄을 "in the style of the attached image"로 두고 첫째 항목은 S-KEEP의 첫째 줄, 셋째 항목은 `- Nothing is added except what the Change line says.`로 쓴다. 인물 한 사람(V1)을 고칠 때는 P-KEEP 그대로에 `Change:` 줄을 같은 꼴로 붙인다.
- 무대를 고칠 때: `Composition:`의 첫 항목을 `- The attached image is our own drawing and it is the base. Keep it: the same composition, the same shapes, the same colors and the same calm dark middle. Change only one thing, as written in the line that starts with Change.`로 바꾸고 `Change:` 줄을 붙인다.

### S-ST3에서 곳마다 바꾸는 구절 (S1·S2)

S-ST3 첫째 항목의 `Add only a little detail on the houses and objects near the left and right edges, such as window frames, shutter boards, the shop sign, a row of roof tiles and barrel hoops.`를 아래로 바꾼다. 나머지는 그대로다.

- 안뜰: `Add only a little detail on the things near the left and right edges, such as the stones and the wooden frame of the well, the bucket and its rope, the planks, iron bands and studs of the gate and a few simple leaf shapes on the tree.`
- 광장: `Add only a little detail on the things near the left and right edges, such as the rim and the column of the fountain, the rolled awning and the posts of the stall and the boards of the crates. The distant rooftops and the bell tower stay plain flat dark shapes.`

C-ST2의 `Edge walls parchment E9D8B4, beams wood brown 7A5232, shutters and barrels dark wood 4A3A2C.` 자리:

- 안뜰: `Light walls near the edges parchment E9D8B4, the gate and the well frame dark wood 4A3A2C, iron bands 2E2620, tree leaves muted dark green 46503A.`
- 광장: `Light stone near the edges parchment E9D8B4, the stall and the crates dark wood 4A3A2C, the distant rooftops and the bell tower very dark warm grey 2E2A28.`

`Composition:`의 첫 항목은 R2와 같이 `- Follow the attached layout sketch for the composition only.`다.

### 비토리오의 줄 (V1. 클라라의 줄을 옮겼다)

- 구도의 첫 항목: 클라라의 것에서 대명사 없이 그대로 쓴다(`The attached image is our own earlier drawing of this same character. …`). 둘째 항목은 `021-G4`의 `Front view or a slight three-quarter view, head straight, both hands visible at waist level (he stands behind a shop counter that is not drawn).`, 셋째는 클라라와 같다.
- S-FIG2 둘째 항목: `Big head, as big as in the reference image.`로 시작하고(클라라와 같다) 끝에 붙인다: `His eyes are half closed, drawn as short curved lines. A thin, pleased smile. His character shows in the expression: smug and self-satisfied.`
- 셋째 항목:

```
- Keep it nearly as simple as the reference image: the same small number of shapes. Improve the craft: clean construction, good proportions, parts that join properly and a hand with fingers that really holds the coin purse. Add only a little detail inside the shapes: the links of the gold chain and a round medallion, two rings, the drawstring of the purse, a softly shaped edge on the fur collar, two or three short fold lines on the robe. Nothing else is added. No fur texture, no curls, no extra wrinkles.
```

- 다섯째 항목: `- Fills: flat solid colors, muted and faded. His cap is filled with the same very dark brown as the outlines.`
- 색:

```
Colors:
- Main fills and their shadow tones: dusty dark red-brown 7E4A4A with shadow 663B3B for the robe, ochre brown A8895E with shadow 8C7050 for the fur collar, very dark brown 3B2A1E for the cap, ochre C08A3E for the gold chain and the rings, wood brown 7A5232 for the purse, skin EBC49F.
- Avoid bright saturated yellow, orange, red, blue, purple or green, and pure white. Large areas are greyish and low in saturation.
```

- 비토리오의 표정은 "거만하지 않게"를 옮기지 않는다: 사용자의 그 답은 바르톨로의 것이고, 비토리오는 의뢰 사연에서 제 잘못을 아는 능글맞은 대금업자다(결정 191). B에서 그림을 보고 고칠 수 있다.

## 대기 자세 — 견본에서만 보이고 제안으로 남긴다 (결정 213)

- 게임의 대기는 팔 자리 (−65, −180)·칼 −25°다(`scenes/duel/opponent_view.tscn`의 `Arm` 자리, `scripts/duel/opponent_view.gd`의 `REST_SWORD_ROTATION`). 게임은 팔을 **돌리지 않고 옮긴다**(팔 파츠는 늘 곧게 선다). 사용자가 고른 R1i는 칼 팔을 몸에서 떼어 비스듬히 내민 자세다.
- 이 계획은 포즈 상수를 바꾸지 않는다(3단계 범위 밖). 견본의 `idle-compare`에 같은 파츠로 셋을 나란히 세운다:

| 칸 | 놓임 | 게임에서 필요한 것 |
|---|---|---|
| 가. 지금 | 팔 (−65, −180), 칼 −25° | 없음 |
| 나. 상수만 | 팔을 바깥으로(R1i에서 잰 어깨~손의 가로 벌어짐만큼. 023 자세 안내도의 −98이 출발 값), 칼 각은 R1i에서 잰 값 | 포즈 상수 둘(4단계 제안) |
| 다. 팔 회전까지 | 나 + 팔을 R1i에서 잰 각만큼 기울임 | 팔 회전을 쓰는 코드(4단계 제안. 예비 동작의 포즈 값 전부에 닿는다) |

- 값은 R1i의 손질본에서 `scan.ps1`로 어깨 끝·손목·칼끝·칼자루의 화소를 읽어 각을 셈하고 견본의 주석에 적는다. "다"는 견본의 `opp()`에 팔 회전 선택 인자를 더해 보인다(새 견본 파일 안의 일이다).
- 발을 벌린 자세는 다리 파츠의 꼴로 들어간다(P-PARTS 8번 "feet a little apart"). 포즈 값과 상관없다.
- 보고서 4번에 올린다: "대기 자세를 가·나·다 가운데 무엇으로 할지(4단계에서 정한다)". 사용자가 B에서 말하면 그 답을 적는다. 답이 없어도 실행을 막지 않는다.
- 코드 읽기로만 확인해 보고서에 적는다: `opponent_view.gd`에서 팔 자리와 칼 각을 정하는 상수의 이름과 줄, 팔 회전을 쓰는 곳이 있는지(Grep `_arm.rotation`).

## 판정

마지막 판정은 사용자의 눈이다. 재는 확인은 **게임 제약(H)** 과 **화풍(K)** 만 본다. 통과 값은 023에서 얼린 것을 쓰고, 파츠 시트의 것만 작업 2에서 다시 맞춘다.

### 파츠 시트 P1 (재는 자리는 파츠마다. 결정 214)

관절과 파츠 상자는 `scan.ps1`의 가로줄·세로줄로 읽는다(021 G2와 같다). k = 200 ÷ (몸통 파츠의 골반 − 목).

| # | 무엇 | 재는 법과 통과 | 걸리면 |
|---|---|---|---|
| HP1 | 자를 수 있다 | `measure.ps1`로 바탕을 지운 뒤 `scan.ps1`로 파츠 상자 열을 읽는다: 머리 3, 모자, 깃털, 몸통, 팔, 주먹, 칼, 다리. 이웃한 상자 사이에 불투명 화소가 없는 가로줄이나 세로줄이 있다. 알파 상자가 그림 가장자리에 닿지 않는다 | 보이기 전 다시 뽑기 |
| H3 · H4 | 바탕 지우기 · 글자 없음 | 테두리 채우기 허용 차 28로 새는 곳 없음 · 눈 | 보이기 전 다시 뽑기 |
| H5 | 신호 구역, 큰 면 S ≤ 50% | `lum.ps1`의 신호 구역 비율, `measure.ps1 -Regions`로 저고리·소매·바지의 칠 | B에 올림 |
| H8 | 큰 면의 칠·그림자 Y ≥ 0.30, 선 Y < 0.22 | 몸통·팔·다리(바지)에서 칠 3점·그림자 3점씩 18점 | B에 올림 |
| H9s | 머리를 맞출 수 있다 | (목~머리털 꼭대기) × k가 117의 0.85~1.25배(99~146). 117은 모자 원점 104에 머리털이 얹힌 값이다(021 G2). 머리 셋의 높이가 서로 ±5% | B에 올림 |
| H10 | 두 줄 글자 상자 | 머리를 맞춘 뒤 모자(챙 밑~꼭대기) × k × 배율 ≤ 53이 되게 모자만 줄인다. 셈: 교전 꼭대기 = 446 − 0.85 × (200 + 104 + 53) = 142.6 ≥ 142. `idle-compare`를 `?bare=1`로 구우면 "가" 칸의 상대만 교전 자리(골반 640, 446 · 배율 0.85)에 선다. 바탕을 지운 뒤 `scan.ps1`로 x 640 세로줄의 첫 불투명 화소(모자 꼭대기)가 y ≥ 142인지 본다. 눈으로는 `parts-duel`에서 모자가 두 줄 글자와 겹치지 않는지 본다 | B에 올림 |
| HP2 | 팔·다리의 비례 | 팔(어깨~손목) × k가 105의 ±15%를 넘으면 세로로 105에 맞춘다. 다리(골반~발끝) × k와 틀 170의 비를 적는다 | 적기만 |
| K1 | 선 색 | 023의 기준(±30, R − B ≥ 5) | B에 올림 |
| K2′s | 선 굵기의 고름 | 열두 점: 몸통 y −150·−40 양옆, 팔 y 50 양옆, 바지 y 30 양옆, 스타킹 y 110 양옆, 첫째 머리 y −20 양옆(022 `calib.ps1`의 `Sheet`). **시작 x는 그 파츠의 상자에서 10화소 바깥**이다(다리를 벌린 꼴에서도 바깥 윤곽부터 잰다). 벗어난 점 ≤ 3, 가운데 × k 3.6~7.8 | B에 올림 |
| K3′ | 평평한 칠 | 몸통·바지·팔의 상자 셋(제자리·위·아래 24화소)에서 가장 작은 sd ≤ 0.025 | B에 올림 |
| K6 | 덧붙임 없음(눈) | 홍조·땀·눈물·하이라이트·천 무늬 없음. 당황의 밝은 눈 원은 된다 | B에 올림 |
| KP | R1i와 같은 색(부드러운 확인) | 저고리·바지의 칠과 그림자, 살, 모자의 가운데 RGB를 R1i의 같은 부위와 견줘 채널 차를 적는다 | 적기만 |

### 잘라서 보는 것 (023에서 못 한 확인. 목표 2)

| # | 무엇 | 재는 법과 통과 |
|---|---|---|
| T1 | 상태 색이 칠에만 얹힌다 | 아래 "상태 색을 재는 법"의 짝 굽기로 잰다. **빈틈**(파랑): 몸통·팔·바지의 칠과 그림자 여섯 점(3×3 평균)이 `lerp(끈 그림의 같은 화소, 신호색, 0.8)`와 채널마다 ±4. 같은 상태의 선 세 점(몸통·바지·팔의 바깥 윤곽, **선 가운데의 한 화소**)은 끈 그림과 ±4. **찌르기의 예비 동작**(노랑)과 **무너짐**(보라): 몸통의 칠·그림자 두 점씩이 같은 셈과 ±4 |
| T2 | 물들지 않는 곳 | 빈틈의 짝 굽기에서 머리의 살 한 점, 모자 한 점, 칼날 한 점(3×3 평균)이 끈 그림의 같은 화소와 ±4(켠 그림과 끈 그림은 같은 머리·같은 놓임이다) |
| T3 | 머리 104 | 셈: 머리 배율 × (목~머리털 꼭대기) × k가 117 ±5%(111~123. 모자 원점은 104). 구운 것: 모자를 벗긴 `parts-far`(`?bare=1`, 배율 0.55)에서 `scan.ps1`로 읽은 목~머리털 꼭대기의 화소가 61~68(= 111~123 × 0.55) |
| T4 | 두 줄 글자 상자 | H10의 세로줄(`idle-compare`, `?bare=1`)과 `parts-duel`의 눈 확인 |
| T5 | 멀리(×0.55)에서 남는다 | `parts-far`(HUD 없는 판)에서 `scan.ps1`: 몸통 허리 높이 가로줄의 바깥 선 폭 ≥ 2화소, 눈 높이 가로줄에서 눈 둘이 따로 선 어두운 덩이(각 폭 ≥ 2화소, 사이에 살 화소)로 읽힌다. 바깥 선의 화면 px을 적는다(025의 크기 기준 자료) |
| T6 | 구멍과 틈(눈) | 대기·예비 동작·무너짐에서 관절(목, 어깨, 손목, 골반)에 바탕이 비치는 틈이 없다. 있으면 자리와 화소를 적는다(4단계의 자료. 다시 뽑지 않는다) |
| T7 | 머리가 상태마다 바뀐다(눈) | 대기·예비·방심은 첫째, 빈틈은 둘째, 무너짐은 셋째 머리 |

**상태 색을 재는 법** (v3, T1. 칸끼리 견주지 않고 **같은 상태를 필터를 켜고 끈 두 장**으로 견준다)

- 굽기: `parts-states`에 `bare=1`·`cell=<1~4>`·`tint=0|1`을 주면 그 상태의 상대 하나만 한 색 바탕(`#D8D8D8`)에 **배율 1.5**(골반 640, 560), **모자를 씌워** 그린다. `tint=0`은 상태 색 필터만 끄고 놓임·머리·모자는 같다. 그래서 두 장의 같은 (x, y)가 같은 파츠의 같은 자리다(팔과 칼이 상태마다 옮겨지는 것, 머리가 상태마다 다른 것과 상관없다). 보는 판의 `parts-states`(네 칸, 0.55, 모자 없음)는 그대로다.
- 점: 견본의 표 `TINT_PTS`에 파츠 이름과 파츠 좌표로 둔다(몸통·팔·바지의 칠과 그림자, 살, 모자, 칼날, 선 점의 출발 자리와 방향). `cell`을 주면 견본이 그 상태의 변환으로 화소를 셈해 `<pre id="tint-pts">`에 `이름,종류,x,y[,dx,dy]` 줄로 적는다(화면에 그리지 않는다). `--dump-dom`에서 읽는다. 칠·그림자의 점이 주름이나 단추에 걸리면 표의 좌표를 옮기고 옮긴 값을 적는다.
- 읽기: 새 로컬 도구 `tintpair.ps1`(`tintcheck.ps1`을 복사해 고친다. 컴파일한 C#) — `-Off <끈 그림> -On <켠 그림> -Pts <위의 줄들> -Sig <hex>`. 종류 `fill`은 두 그림의 같은 (x, y) 3×3 평균을 읽어 `lerp(끈 값, Sig, 0.8)`와의 채널 차를 낸다. 종류 `same`은 두 3×3 평균의 차를 낸다. 종류 `line`은 끈 그림에서 (x, y)부터 (dx, dy)로 가며 Y < 0.22가 이어진 첫 구간을 찾아 **그 가운데 한 화소**를 두 그림에서 읽어 차를 낸다(배율 1.5에서 바깥 선은 약 7화소라 가운데 화소에 칠이 섞이지 않는다). 구간이 3화소보다 짧으면 "선이 가늘어 잴 수 없다"로 적고 그 점은 눈으로 본다.
- 신호색은 견본 `:root`의 값이다(빈틈 `--sig-recovery` `#4D80F2`, 찌르기 `--sig-thrust`, 무너짐 `--sig-stagger`. 020과 같은 줄).
- 도구의 맞음은 그림을 돌리기 전에 SVG 파츠로 본다(작업 2): 같은 굽기·같은 점으로 SVG 바르톨로의 빈틈을 재어 칠·그림자가 ±4 안, 선과 `same` 점이 ±4 안이어야 한다. 어긋나면 도구나 점을 고친다(그림 탓이 아니다).

### 무대 S1·S2 (023 R2와 같다. `calib023.ps1 -StagePath`)

K1, H6(극장 금지, 사람·동물 없음. 눈), H7(가운데 L 평균 ≤ 0.20, 95번째 ≤ 0.30), H11(조용한 구역 x 433~847·y 62~683의 선 밀도 ≤ 0.01), 가장자리 띠의 K5 ≤ 섞은 SVG의 1.5배(022의 얼린 값. 섞은 안뜰 0.040, 광장 0.063), K7(교차 빗금·벽을 덮는 결 없음. 눈). 광장의 K1은 먼 실루엣의 칠이 선 화소에 드는 것을 안다(R − B ≥ 5).

### 비토리오 V1 (023 R3과 같다. `calib023.ps1 -ClientPath`)

H3·H4·H5, K1, K2′(부드러운 확인), K3′, K6(눈), G8(허리 위, 얼굴이 가려지지 않는다, `client-counter`에서 220×390 안의 머리 높이 140~155. 눈과 견본의 배율 값). 더해 옷의 칠과 그림자의 Y를 `measure.ps1 -Regions`로 적는다(팔레트 확정의 자료. "팔레트 확정").

### 눈 확인 Q (메인이 적는다. 판정은 사용자)

파츠 시트가 R1i와 같은 사람인가, 머리 셋이 같은 사람인가, 조립한 대기가 R1i만큼 단정한가, 무대 둘이 R2와 같은 결인가, 비토리오가 클라라와 같은 집안인가, 디테일의 양이 섞은 SVG만큼 단순한가. **새 그림에서 대기 / 예비 동작 / 빈틈 / 무너짐 네 칸이 교전·멀리 크기에서 한눈에 갈리는가**(색, 팔과 칼의 실루엣, 머리. `parts-states`·`parts-duel`·`parts-far`. B에서 사용자에게 같이 보인다).

## 견본 `docs/style/samples/024-widen.html` (결정 218)

- 새 파일이다. `023-redraw.html`을 복사해 시작하고, 안뜰·광장의 무대 함수와 비토리오·`sheetParts`는 `022-mix.html`에서 **베껴 온다**(020~023 견본은 고치지 않는다). 규칙은 023과 같다(`<meta charset="utf-8">` 맨 앞, 바깥 자원 없음, 생성 그림은 `<image href="../generated/…">`만, 단독 보기 `#<id>`, 상대는 `data-part` 무리, 그림이 없으면 "만들지 않았다(까닭)").
- 파츠의 표(관절·다각형·k·배율·칼의 원래 각·상태별 머리)는 스크립트의 표 하나(`SHEET`)에 둔다. `?pick=`으로 시트의 차례(a, b …)를 고른다. `?bare=1`이면 HUD·글자·무대 없이 한 색 바탕(`#D8D8D8`) 위에 상대만 같은 자리·크기로 그린다(재기용. `measure.ps1`로 바탕을 지워 잰다). `parts-states`는 `bare=1`과 함께 `cell`·`tint`를 받는다("상태 색을 재는 법").

| 차례 | id | 무엇 |
|---|---|---|
| 1 | `parts-raw` | 파츠 시트의 원본 |
| 2 | `parts-idle` | 대기 셋을 같은 크기(0.65)·같은 무대 톤에: 섞은 SVG · R1i(자르지 않은 전신) · 시트를 조립한 것(지금 코드의 놓임) |
| 3 | `idle-compare` | 대기 자세 가·나·다("대기 자세"). R2 위, 교전 크기 |
| 4 | `parts-states` | 상태 넷(대기, 찌르기의 예비 동작, 빈틈, 무너짐). 머리는 상태마다 |
| 5 | `parts-duel` | R2 위의 큰 베기 예비 동작(진행 0.25, HUD, 두 줄 글자, 조준 테두리) |
| 6 | `parts-far` | 멀리·방심 |
| 7 | `stage-court` | S1 위에 같은 장면(시트가 없으면 SVG 바르톨로) |
| 8 | `stage-piazza` | S2 위에 같은 장면 |
| 9 | `cmp-stage` | 두 줄: 안뜰(섞은 SVG · 021 G5 · 024), 광장(같다). HUD·상대 없음 |
| 10 | `client-counter` | 카운터의 비토리오 |
| 11 | `cmp-client` | 비토리오 셋: 섞은 SVG · 021 G4 · 024 |
| 12 | `basis` | 기준 후보 일곱을 한 장에(전신 R1i, 파츠 시트, 무대 셋, 의뢰인 둘) |
| 13 | `palette` | 확정 팔레트: 주는 값 · 기준 그림에서 잰 값 · Y, 선 굵기 |

## 팔레트 확정 (결정 216)

묻지 않고 정한다(모두 값 몇 개라 되돌리기 쉽다). B에서 "이렇게 확정한다"고 알리고, 사용자가 다르게 말하면 그 값으로 적는다.

| 무엇 | 확정하는 값 | 까닭 |
|---|---|---|
| 바르톨로 바지 | `#836850` / 그림자 `#6E5642`. "임시"를 뗀다. 견본의 `#6B5440` / `#57442F`는 "020~022 견본의 값(기록)"으로 남긴다 | 사용자가 그림을 보고 두 번 "좋다"고 했다(R1a·R1b, R1d). 그림자가 상태 색 문턱(Y 0.30) 위다 |
| 선 굵기 | 벡터 5.2 그대로, "임시"를 뗀다. 생성 그림은 가운데 × k **5.0~5.6을 겨냥**하고 3.6~7.8을 받는다. 프롬프트의 말은 "about 8 pixels"(이 말로 10~12화소가 나왔다) | 사용자가 R1c(3.6)·R1d(5.6)에 "좋다"고 했고 고른 R1i가 5.0이다 |
| 주는 값과 잰 값 | **프롬프트에 주는 값이 정본**이다. 그림이 낸 값은 "기준 그림에서 잰 값" 열에 따로 적는다(저고리는 더 회색으로, 그림자는 준 값과 조금 다르게 나온다). 잰 값을 쫓아 주는 값을 고치지 않는다 | R1i·R2·R3은 지금의 hex로 나와 "맞다"를 받았다. hex를 바꾸면 그림이 다시 달라진다. 4단계에서 SVG·UI의 색을 그림 옆에 놓을 때는 잰 값에 맞춘다(026의 `STYLE_BIBLE.md` 8장이 두 열을 싣는다) |
| 받는 범위 | 상대의 큰 면: 칠·그림자 Y ≥ 0.30, 선 Y < 0.22, S ≤ 50%(G5·G6 그대로). 프롬프트에 주는 칠은 Y ≥ 0.42, 그림자 hex도 준다(결정 204 그대로) | 023의 아홉 장에서 그림자가 준 값보다 0.07까지 어둡게 나왔다. 0.42에서 시작하면 0.30 위에 남는다 |
| 비토리오의 옷 | `#7E4A4A`(Y 0.33) / `#663B3B`(0.27) **그대로** 준다 | 의뢰인에게는 상태 색이 얹히지 않는다(G6은 상대의 제약이다). 밝히면 짙은 벽돌 갈색 옷이라는 인물의 인상이 바뀐다 |
| 비토리오의 물림 값 | V1에서 옷 그림자의 Y가 0.24 아래로 나와 선과 붙어 보이면 `#8C5555`(Y 0.38) / `#734545`(0.31)로 한 장 고친다(V1의 몫) | 선(Y 0.18)과 그림자가 갈리지 않으면 "그림자에는 선이 없다"가 깨져 보인다 |
| R2의 왼쪽 기와 지붕 | 그대로 둔다. R2를 다시 그리지 않는다 | 사용자가 R2를 "맞다"고 했고 H11·K5·K7을 통과했다. 가장자리의 형태 디테일이다(명세 2부). 안뜰·광장에는 가까운 지붕이 없어 번지지 않는다 |

- 잰 값은 기준으로 올리는 그림마다 `measure.ps1 -Regions`(인물)와 `lum.ps1 -Rects`(무대)로 이름 붙은 색의 자리를 재어 가운데 RGB와 Y를 적는다. 자리(화소 상자)는 `GENERATION.md`에 남긴다.
- 필터의 문턱(0.22·0.30)과 신호색은 건드리지 않는다(결정 181, 4단계 셰이더의 값).

## 기준 이미지 올리기 (결정 217. 결정 189의 실행)

- B·B′에서 "맞다"를 받은 그림과 023의 셋을 `docs/style/basis/`로 **복사**한다(원본 PNG 그대로. 손질본·넣은 그림·몫 밖의 시험은 로컬에 남는다).

| 올리는 이름 | 로컬 원본 |
|---|---|
| `bartolo-front.png` | `023-R1i-bartolo-front.png` |
| `bartolo-parts.png` | 고른 `024-P1<차례>-bartolo-parts.png` |
| `stage-alley.png` | `023-R2-stage-alley.png` |
| `stage-court.png` · `stage-piazza.png` | 고른 `024-S1…` · `024-S2…` |
| `client-clara.png` | `023-R3-client-clara.png` |
| `client-vittorio.png` | 고른 `024-V1…` |

- `docs/style/basis/README.md`(색인): 파일마다 무엇, 크기, 프롬프트 파일, 넣은 그림, thread_id, 사용자의 판정 한 줄과 날, 손질 값(인물: 관절·k·머리와 모자의 배율, 무대: 맞춘 틀과 밝기 손질). 머리에 한 줄: "화풍의 기준이다. 게임에 쓰는 애셋이 아니다(`assets/`와 `MANIFEST.md`는 4단계·026)".
- 일곱 장이면 약 10MB가 저장소에 더해진다(한 장 1.2~1.7MB). 사용자가 뺀 그림은 올리지 않고 README에 "고르지 않았다(까닭)"로 적는다.

## 작업 목록

**공통 규칙**

- "넘지 않는 선"을 지킨다. 대조가 어긋나면 값을 맞추지 말고 멈춰서 보고한다.
- 편집은 작게 나눠 한다(절 하나씩).
- 구운 PNG와 작업 폴더는 scratchpad에 둔다. `docs/style/generated/tools/`의 스크립트를 scratchpad의 `tools\`로 복사하고 안의 scratchpad 경로를 이 세션의 것으로 고친다(`bake023`·`calib023`·`run-codex`. 한글이 든 `.ps1`은 BOM을 지킨다). 새로 쓴 도구(`bake024.ps1`, `calib024.ps1`, `tintpair.ps1`)는 끝에 로컬 `tools/`로 되돌려 둔다.
- 넓은 면을 도는 재기는 컴파일한 C#(`kmeasure.ps1`·`measure.ps1`의 꼴)으로 한다(`GetPixel`로 돌면 2분을 넘긴다).
- Codex가 도는 동안 저장소의 추적 파일을 고치지 않는다(전후 대조).

### 작업 0. 시작 상태

- `git status --short`가 이 계획 파일뿐인지 본다(022·023은 `14ac99a`로 커밋되었다). 다른 변경이 있으면 멈추고 묻는다.
- Glob으로 로컬 자료를 본다: `generated/023-R1i-bartolo-front.png`·`023-R2-stage-alley.png`·`023-R3-client-clara.png`와 그 `cut/`, `in/022-in-parts.png`·`022-in-stage-court.png`·`022-in-stage-piazza.png`·`022-in-client-2.png`, `021-G2`·`021-G4`·`021-G5-stage-court`·`piazza`, `tools/*.ps1`.
- 완료 확인: 결과가 보고서 2번에 있다. 기준 그림 셋이나 넣는 그림 넷, `tools/`가 없으면 멈추고 보고한다(다른 컴퓨터면 사용자가 옮겨야 한다). 021의 그림이 없으면 `cmp-*`의 그 칸만 "없다"로 둔다.

### 작업 1. 명세에 블록 더하기 — `docs/style/STYLE_SPEC.md`

- 끝의 "022의 블록" 앞에 새 절 "계획 024의 블록"을 두고 이 계획 "프롬프트 블록"의 원문을 그대로 옮긴다.
- 표정 표에 한 줄: "자신 있는 미소 | 평평, 한쪽을 살짝 듦 | 점 | 한쪽이 올라간 짧은 선". "사용자가 고른 길" 4번 끝에 "파츠 시트의 첫째 머리가 이 얼굴이다(계획 024)".
- 3부 G3 줄에 "파츠 시트에서는 목~머리털 꼭대기가 117의 0.85~1.25배(H9s)".
- 완료 확인:
  - 새 절 안에서 Grep `[^\x00-\x7F]`가 코드 블록 안에 0, 코드 블록 안의 `"` 0. 파일 전체에서 Grep `-i "pizza|potion|tapblaze|niceplay|tinybuild"` 0.
  - Grep `P-PARTS`·`S-PARTS`·`P-KEEP-SHEET` 각 1건 이상, `7E4A4A with shadow 663B3B` 1건.
  - 있던 블록(S-FIG2, C-FIG2, S-ST3, C-ST2, P-KEEP, S-KEEP, 클라라)의 `git diff`에 지운 줄이 없다(더한 줄뿐).

### 작업 2. 견본의 뼈대, 시트의 기준 맞추기, Codex 준비 (사용량 없음)

- `docs/style/samples/024-widen.html`을 "견본" 절대로 만든다. 이 작업에서는 SVG·021·023 칸과 `basis`의 023 셋, `palette`의 주는 값까지 그린다(024 칸은 "만들지 않았다").
- `calib024.ps1`(로컬 도구): 022 `calib.ps1`의 `Sheet`를 옮기고 K2′(벗어난 점의 수)·K3′를 쓰게 하며, 시작 x를 "파츠 상자에서 10화소 바깥"으로 받는다. 섞은 SVG 파츠 시트(`in/022-in-parts.png`)와 021 G2를 재어 `GENERATION.md`의 새 절 "계획 024 — 시트의 기준 맞추기"에 적고 얼린다: 섞은 SVG가 K1·K2′s·K3′를 통과해야 굳은 확인으로 쓴다. 통과하지 못하면 그 확인을 부드러운 확인으로 내리고 B에서 알린다.
- `idle-compare`의 값: R1i의 손질본에서 `scan.ps1`로 어깨 끝·손목·칼자루·칼끝을 읽어 팔의 벌어짐과 각, 칼의 각을 셈한다.
- Codex 준비: 023 작업 3과 같다(`codex --version`, `login status`, `debug models`의 `gpt-6.2-sol`, `config.toml` 해시를 `AA004752…186D`와 견줌, 끄기와 함께 `mcp list`). 해시가 다르면 켜진 플러그인·MCP를 읽기만 해 끄기 목록을 맞추고 새 해시를 이 계획의 처음 값으로 적는다. 로그인이 안 되어 있으면 사용자에게 부탁하고 멈춘다.
- 완료 확인:
  - Grep `<section id="` 13건이고 표의 id·차례와 같다. 바깥 자원 Grep(020 작업 3의 여덟) 0, 극장 함수 Grep `spectators|balustrade|folds` 0.
  - `git diff --stat -- docs/style/samples/020-bridge.html docs/style/samples/021-detail.html docs/style/samples/022-mix.html docs/style/samples/023-redraw.html`이 비어 있다.
  - `bake024.ps1`은 `bake023.ps1`에서 `-Page`·출력 폴더와 **shot 문법**을 바꾼 것이다: `<id>[@<pick>][+<키>=<값>]…` → `?pick=<pick>&<키>=<값>…#<id>`(예: `parts-states@a+bare=1+cell=3+tint=0`, `idle-compare+bare=1`). 파일 이름은 `@`·`+`·`=`를 `-`로 바꾼 것이다.
  - `tintpair.ps1`을 SVG 파츠로 맞춰 보았다("상태 색을 재는 법"의 끝 줄): SVG 바르톨로의 빈틈 짝 굽기(`cell=3`, `tint=0`·`1`)에서 칠·그림자 여섯 점, 선 세 점, `same` 세 점이 모두 ±4 안이고 그 값이 `GENERATION.md`에 있다. `<pre id="tint-pts">`의 줄 수가 `TINT_PTS`의 점 수와 같다.
  - `bake024.ps1`로 열세 섹션이 제 크기(1280×720)로 구워지고 `--dump-dom`의 섹션이 13이다. 끝난 뒤 우리 프로필의 `msedge.exe` 0개.
  - 시트의 기준 표에 섞은 SVG와 021 G2의 값, 얼린 문턱이 있다. 같은 그림을 두 번 재어 값이 같다.
  - `idle-compare`가 SVG 파츠로 구워지고(시트는 작업 4에서 갈아 끼운다) 세 칸의 팔 자리·팔 각·칼 각이 견본의 주석에 있다. R1i에서 읽은 네 점의 화소가 `GENERATION.md`에 있다.

### 작업 3. 처음 넷 — P1a · S1a · S2a · V1a

- 프롬프트 넷을 "그림 넷과 넣는 것"의 뼈대대로 써서 `docs/style/prompts/024-P1a-bartolo-parts.txt`·`024-S1a-stage-court.txt`·`024-S2a-stage-piazza.txt`·`024-V1a-client-vittorio.txt`에 둔다. "처음 4장을 돌린다"고 알린다.
- `run-codex.ps1 -Plan 024 -G <번호+차례> -Name <이름> -Images … -Phrases …`로 한 장씩, P1a부터 돌린다. P1a는 그림 둘(`in-1` R1i, `in-2` 배치도)이다.
- 호출마다 `GENERATION.md`의 새 표 "기록 (계획 024)"에 023의 칸대로 적는다(P1a의 참조 그림 인자는 **2장**이어야 한다. 다르면 적고 B에서 알린다).
- 그림마다 "판정"의 확인을 한다. P1a는 HP1부터: 자를 수 없으면 같은 프롬프트로(파츠가 닿았으면 `Clear empty space` 줄 앞에 `Leave at least 40 pixels of empty background between any two parts.` 한 줄을 명세에 먼저 더해) 한 번 다시 돌린다(P1b, 몫에서).
- 완료 확인:
  - 기록 표의 줄 수 = 호출 수 ≤ 몫. 모델·추론 칸이 세션 기록의 `gpt-6.2-sol`·`high`·read-only, 부른 도구가 그림 도구 하나, F11의 세 구절(인물 `new, original illustration`·`line weight`·`Do not add`, 무대 `new, finished background`·`even weight`·`Do not add`), 전후 대조(git·`config.toml` 해시·이전 그림 수) 같음.
  - 프롬프트 파일의 블록이 그때의 `STYLE_SPEC.md` 원문과 글자 그대로 같다(블록의 첫 줄과 끝 줄을 Grep으로 짝짓는다). `prompts/024-*`에서 Grep `-i "pizza|potion|tapblaze|niceplay|tinybuild"` 0, `[^\x00-\x7F]` 0, `"` 0, `reference/|screenshot` 0, `match its drawing style` 0.
  - 그림마다 H·K의 값이 `GENERATION.md`에 있다(통과·걸림과 수).

### 작업 4. 자르기, 얹기, 굽기 (→ 승인 B)

- P1의 파츠를 `SHEET` 표에 넣는다(관절·다각형·k, 머리와 모자의 배율, 팔의 세로 배율, 칼의 원래 각, 상태별 머리, 깃털의 밑동 자리). 방법은 `GENERATION.md` "파츠로 나누기와 비례 맞추기"의 G2 줄 그대로다.
- S1·S2를 1280×720 틀에 맞추고(H7에 걸리면 `brightness()` 손질 값을 적는다) V1의 바탕을 지워 카운터에 놓는다.
- 열세 섹션을 굽고 "잘라서 보는 것" T1~T7을 한다(T3·T4·T5는 `bare=1`로 구운 것을, T1·T2는 "상태 색을 재는 법"의 짝 굽기 여섯 장(`cell=2`·`3`·`4` × `tint=0`·`1`)을 `tintpair.ps1`로 잰다).
- **승인 B**("장 수와 승인"). "고친다"면 그 한 줄을 `Change:` 줄로 옮겨(명세에 먼저) 한 장 돌리고, 그 그림의 확인과 굽기를 다시 한 뒤 B′를 묻는다. 시트를 고쳤으면 `SHEET`의 관절을 다시 읽는다(P-KEEP-SHEET는 자리를 지키지만 확인한다: 파츠 상자가 직전 시트와 ±3화소).
- 완료 확인:
  - T1·T2의 점마다 끈 값·켠 값·셈한 값과 차가 `GENERATION.md`에 있다(빈틈 열두 점, 찌르기 예비와 무너짐 두 점씩. "잴 수 없다"로 적은 선 점은 눈 확인의 결과와 함께). T3의 값(111~123), T4의 첫 불투명 화소 y(≥ 142), T5의 선 폭과 눈 덩이의 폭이 있다.
  - `--dump-dom`의 섹션 13, 빈 장면 0(그림이 빠진 장은 `--virtual-time-budget=10000`으로 한 번 더).
  - B·B′의 답 원문이 `DECISIONS.md`에 옮겨질 수 있게 적혀 있다. 그림마다 쓴 장 수가 몫 표와 나란히 있다.

### 작업 5. 기준 이미지 올리기 — `docs/style/basis/`

- "기준 이미지 올리기"대로 복사하고 `README.md`를 쓴다. 견본 `basis` 섹션의 그림 경로는 `../generated/` 그대로 둔다(견본의 규칙).
- 완료 확인:
  - 올린 파일마다 `Get-FileHash`가 로컬 원본과 같다. 파일 수 = "맞다"를 받은 그림 수 + README 1.
  - `git status --short`에 `docs/style/basis/`가 보이고 `git check-ignore docs/style/basis/bartolo-front.png`가 아무것도 내지 않는다. `docs/style/generated/`는 보이지 않는다.
  - `docs/style/.gdignore`가 있다(Glob). `docs/style/basis/` 아래에 `.import` 파일이 없다(Glob. Godot을 띄우지 않았으니 생길 수 없다. 띄운 뒤의 확인은 "playtester에게 맡길 확인").
  - README의 줄 수 = 후보 일곱(고르지 않은 것은 까닭과 함께).

### 작업 6. 팔레트 확정 — `docs/style/STYLE_SPEC.md`, 견본 `palette`

- "팔레트 확정"의 표대로 명세를 고친다: 다리 섞기의 "5.2는 임시 값이다"와 "어두운 옷의 밝기"의 "임시 값이고 확정은 024다" 줄을 확정의 말로, 팔레트 표의 바지 두 줄을 "주는 값(확정)"과 "020~022 견본의 값(기록)"으로, 비토리오의 옷 줄에 정한 것을. 새 작은 표 "기준 그림에서 잰 값(계획 024)": 올린 그림마다 이름 붙은 색의 가운데 RGB·Y.
- 견본 `palette`에 같은 두 열을 그리고 다시 굽는다.
- 완료 확인:
  - `STYLE_SPEC.md`에서 Grep `임시`가 팔레트·다리 섞기·어두운 옷의 밝기 절에 0(경위를 적은 "고친 경위" 줄은 그대로 둔다).
  - 잰 값의 표에 올린 인물 그림마다 저고리·바지(바르톨로)나 옷(의뢰인)의 칠과 그림자, 살, 선이 있고, 상대(전신·시트)의 큰 면이 받는 범위(칠·그림자 Y ≥ 0.30, 선 < 0.22, S ≤ 50%) 안인지가 줄마다 적혀 있다.
  - 프롬프트에 준 hex(`prompts/023-R1i`·`024-*`의 `Colors:` 줄)와 명세의 "주는 값"이 Grep으로 같다.

### 작업 7. 기록과 보고

- `docs/DECISIONS.md`: 끝에 "2026-11-22 — 계획 024" 절. 결정 210~218 한 줄씩, 실행 전 답(Q1), 실행 중에 정한 것(얼린 시트 기준, B·B′의 답 원문, `Change:` 줄들, 장·호출과 몫, 올린 그림).
- `CLAUDE.md`: 9장 "현재 위치"에서 "계획 023(화풍을 옮겨 새로 그리기)까지 실행했다(…)." 문장 뒤에 "계획 024(고른 길로 넓히기)까지 실행했다(2026-11-22). 기준 그림은 `docs/style/basis/`에 있다."를 더하고, 그 줄에서 다음 계획과 남은 나눔을 가리키는 말(024를 "다음"·"예정"으로 적은 곳)을 "남은 나눔은 025(글꼴·UI·크기 기준)·026(STYLE_BIBLE)이다(결정 201)"로 맞춘다. 고치기 전에 그 줄을 읽고 바꾼 전후를 보고서에 적는다. 8장 `docs/`의 `style/` 괄호에 `basis/`를 더한다. 7장의 "고른 것만 올린다" 뒤에 "(`docs/style/basis/`)"를 더한다. 다른 줄은 고치지 않는다.
- `docs/style/GENERATION.md`: 머리의 결정 범위에 210~218, 새 절 "계획 024"(시트의 기준 맞추기, 기록 표, 그림마다의 잰 값, 잘라서 본 것, 배운 것).
- `docs/reports/024-widen-chosen-path.md`와 사용자 보고(10장 형식). 4번에 올릴 것: 대기 자세 가·나·다(4단계), 바르톨로의 대사와 얼굴의 어긋남(6단계의 글에서 볼지), 확정한 팔레트에 대한 다른 뜻, 걸린 채 올린 그림이 있으면 그 제약, 024의 커밋, 다음 계획 025의 범위(글꼴·UI·크기 기준. 026과 합칠지).
- `docs/HANDOFF.md`: 1번을 그때의 자리로, 3번에 "계획 024 보고서 4번" 한 줄(023 줄에서 답을 받은 것은 지운다).
- `docs/BACKLOG.md`는 건드리지 않는다(대기 자세는 고칠 거리가 아니라 사용자가 정할 제안이다).
- **playtester에게 맡길 확인**(사용자가 요청할 때만. 게임 코드는 바뀌지 않았다): `docs/style/basis/`에 PNG가 올라온 뒤에도 Godot이 그것을 가져오지 않는다(`docs/style` 아래 `.import` 0, `.godot/imported/`에 basis 그림 0), 테스트 `ALL PASS 65/65`와 스모크가 전과 같다.
- 완료 확인: 보고서에 "확인 못 한 것"이 있다(위 playtester 확인, 021~023에서 못 한 것 가운데 남은 것, 조립한 파츠가 실제 리깅에서 움직일 때의 틈). `config.toml` 해시가 작업 2의 값과 같다. 끝의 `git status --short`에 이 계획이 더한 것이 이 계획 파일, `CLAUDE.md`, `docs/DECISIONS.md`, `docs/HANDOFF.md`, `docs/style/STYLE_SPEC.md`, `docs/style/GENERATION.md`, `docs/style/prompts/024-*.txt`, `docs/style/samples/024-widen.html`, `docs/style/basis/*`, 보고서뿐이다. `scripts/`·`scenes/`·`data/`·`tests/`·`project.godot`·`docs/BACKLOG.md`의 diff가 없다.

## 설계 결정

211의 몫은 사용자 답(Q1 "넉넉히 20장")이다. 나머지는 planner가 정했고(사용자 지시 "꼭 결정해야 되는 것만 묻는다") 모두 되돌리기 쉽다.

| # | 결정 | 이유 | 되돌리기 |
|---|---|---|---|
| 210 | 024는 넓히기 전부(파츠 시트·잘라서 확인, 무대 둘, 비토리오, 기준 올리기, 팔레트 확정)를 한 계획에 둔다. 처음 넷을 한 번에 돌리고 승인은 한 곳(B)에서 그림마다 받는다. "맞다"가 곧 "기준으로 올린다"다 | 그림 넷이 서로 기대지 않는다. 사용자가 멈춰 서는 곳을 줄이라고 했다. 결정 209의 길은 다시 시험하지 않는다 | 쉬움. 한 그림이 몫을 다 써도 나머지는 끝난다 |
| 211 | 장·호출의 몫은 그림마다: 시트 8, 안뜰 3, 광장 3, 비토리오 4, 예비 2(합 20. 사용자 답 "넉넉히 20장"). 몫 안에서는 장 수를 다시 묻지 않는다. 보이기 전의 다시 뽑기는 그림마다 한 번, 자를 수 없거나 무대의 H6·H11에 걸린 때만 | 023은 한 상한(8)을 인물이 다 썼다. 그림마다 몫을 두면 한 그림의 되풀이가 다른 그림을 굶기지 않는다 | 쉬움 |
| 212 | 파츠 시트에는 R1i(사람)와 섞은 SVG 배치도(자리) 둘을 넣는다. 머리 셋은 자신 있는 미소·당황·어지러움이다(022까지의 "거만함" 자리에 사용자가 고른 얼굴). 고칠 때는 직전 그림을 바탕으로 한 장에 하나씩(P-KEEP-SHEET) | 꼴은 그림이 옮긴다(209). 021 G2가 같은 두 장 꼴로 열 파츠를 한 번에 냈다. 사용자가 "여유로운 것과 거만한 것은 다르다"고 했다 | 쉬움. 머리 하나만 다시 그린다 |
| 213 | 대기 자세는 게임 코드를 바꾸지 않고 견본 `idle-compare`의 세 칸(지금 / 상수만 / 팔 회전까지)으로 보이고 4단계 제안으로 남긴다 | 포즈 상수는 3단계 범위 밖이다. 파츠 시트는 자세가 없어 이 물음을 기다리지 않는다 | — (게임이 바뀌지 않는다) |
| 214 | 파츠 시트는 파츠별 자리로 잰다(022 `calib.ps1`의 `Sheet`). K2′의 시작 x는 파츠 상자 10화소 바깥. 머리는 목~머리털 꼭대기 117로 본다(H9s). 기준은 섞은 SVG 시트와 021 G2로 그림을 돌리기 전에 얼린다 | 전신의 재는 자리는 굳은 정면 자세용이라 팔이 나오면 걸렸다(R1e·R1f). 시트에서는 파츠가 따로 놓여 바깥에서 재면 꼴에 기대지 않는다 | 쉬움 |
| 215 | 무대 둘은 S-ST3에서 디테일의 구절과 색 한 줄만 곳에 맞게 바꾼다. 비토리오는 클라라의 줄을 옮기고 표정은 능글맞게 둔다 | R2·R3이 그 블록으로 "맞다"를 받았다. 바르톨로의 "거만하지 않게"는 그 사람의 답이다 | 쉬움 |
| 216 | 팔레트 확정: 바지 `#836850` / `#6E5642`와 선 굵기(5.2, 생성은 5.0~5.6을 겨냥)의 "임시"를 뗀다. 주는 값이 정본이고 잰 값은 따로 적는다. 비토리오의 옷은 그대로(의뢰인에는 상태 색이 얹히지 않는다), 물림 값은 `#8C5555` / `#734545`. R2의 기와 지붕은 그대로 | "팔레트 확정"의 표 | 쉬움. 값 몇 개 |
| 217 | 기준 이미지는 원본 PNG를 `docs/style/basis/`에 뜻이 드러나는 이름으로 복사하고 `README.md`에 색인을 둔다. 023의 셋은 다시 묻지 않고 함께 올린다 | 결정 189. 셋은 이미 "맞다"를 받았다 | 쉬움(파일 지우기). 저장소에 약 10MB가 남는다 |
| 218 | 견본은 새 파일 `024-widen.html`(섹션 열셋). 023에서 넘긴 `fig-states`·`fig-far`를 `parts-states`·`parts-far`로 채운다 | 020~023 견본은 고치지 않는다 | 쉬움 |

## 위험

1. **파츠 시트가 R1i와 다른 사람으로 나온다**(얼굴형, 수염, 옷의 디테일, 선 굵기). 대비: R1i를 사람의 참고로 넣고 "exactly the same man"으로 적는다. KP(색 차)와 K2′s를 재고, 다르면 B에서 사용자가 짚은 한 가지씩 P-KEEP-SHEET로 고친다(고치기 몫 7).
2. **배치도(섞은 SVG)의 꼴이나 얼굴을 따라 그린다**(반달 눈의 거만한 머리가 나온다). 대비: "배치만 본다"는 말, 머리 셋의 표정 문장, 눈 확인. 그래도 따라 그리면 배치도를 빼고 R1i 하나와 글로 돌린다(한 장, 몫에서).
3. **파츠가 닿거나 빠지거나, 가려진 부분이 그려지지 않는다**(몸통의 어깨, 머리의 정수리). 대비: HP1과 보이기 전의 다시 뽑기 한 번. 모자 밑의 정수리가 없으면 T6에 적고 P-KEEP-SHEET의 고칠 것으로 올린다.
4. **한 장에 하나씩 고치다 몫이 모자란다**(023의 되풀이). 대비: 그림마다의 몫과 예비 2, 다 쓰면 멈추고 묻는다. 한 장 1분·4만 토큰이라 몫을 늘리는 값은 작다.
5. **P-KEEP-SHEET가 다른 파츠까지 바꾼다.** 대비: 고친 뒤 파츠 상자를 직전 시트와 견준다(±3화소). 어긋나면 `SHEET`를 다시 읽는다.
6. **상태 색이 디테일의 선(Y 0.22~0.30의 어중간한 색)에서 얼룩진다.** 대비: T1의 점(세 상태)과 눈. 얼룩지면 자리와 화소를 적어 4단계 셰이더의 자료로 남긴다(다시 뽑지 않는다).
7. **멀리에서 얼굴이 뭉개진다.** 대비: T5. 걸리면 B에서 보이고, 고칠 것은 얼굴의 선이 아니라 025의 크기 기준(멀리의 배율)과 함께 본다.
8. **안뜰·광장의 가운데가 시끄럽다**(나뭇가지, 분수, 지붕선이 조용한 구역에 든다). 대비: H11과 보이기 전의 다시 뽑기 한 번. 광장의 지붕선은 선 없는 칠 덩이라 H11에 들지 않는다.
9. **비토리오의 짙은 옷에서 그림자가 선에 붙는다.** 대비: 옷 그림자의 Y를 재고 물림 값으로 한 장.
10. **시트의 기준이 가르지 못한다**(021 G2도 K2는 통과했다). 대비: 지키는 확인으로 쓰고, 가르는 일은 사용자의 눈에 둔다(022·023과 같은 규칙).
11. **올린 그림이 저장소를 키운다**(약 10MB). 대비: 고른 것만, 원본만. 사용자가 뺄 수 있다.
12. 막는 장치·사용자의 Codex 설정·두 게임을 닮아 보일 위험과 대비는 021 위험 2·3·9, 023 위험 9와 같다.

## 실행 전에 물을 것

**답을 받았다(2026-11-22, 선택 창). 남은 물음은 없다.**

- **Q1 답: 나** ("넉넉히 20장"). 파츠 시트 8, 안뜰 3, 광장 3, 비토리오 4, 예비 2. 고칠 것이 많아도 장 수를 다시 묻지 않는다. 처음 4장은 알리고 바로 돌린다. (약 20분, 5시간 창 +8% 안팎까지)

아래는 v1에서 물은 글의 기록이다.

**Q1. 새 그림의 장 수 몫** (그림은 사용자의 Codex 사용량으로 만든다. 한 장에 약 1분, 4만 토큰, 5시간 창 +0.4% 안팎)

- 가. **그림마다, 합 14(권함)**: 파츠 시트 5, 안뜰 2, 광장 2, 비토리오 3, 예비 2. 처음 4장은 알리고 바로 돌린다. (약 14분, 5시간 창 +6% 안팎까지)
- 나. 넉넉히, 합 20: 파츠 시트 8, 안뜰 3, 광장 3, 비토리오 4, 예비 2. 고칠 것이 많아도 다시 묻지 않는다.
- 다. 빠듯하게, 합 9: 파츠 시트 3, 안뜰 1, 광장 1, 비토리오 2, 예비 2. 몫을 다 쓰면 그때마다 묻는다.
- 답에 따라: "장 수와 승인"의 몫 표와 결정 211의 수만 바뀐다. 다른 절은 그대로다.

## 사용자 결정 필요 (실행을 막지 않는다. B에서 알리고 보고서 4번에 올린다)

| # | 무엇 | 이 계획이 정한 것 | 답이 다르면 |
|---|---|---|---|
| 1 | 024의 범위 | 넓히기 전부를 한 계획에(결정 210) | 나누라고 하면 무대·비토리오를 떼어 025로 밀고 뒤 번호를 하나씩 민다 |
| 2 | 파츠 시트의 자세와 게임의 대기 자세 | 시트는 자세 없이, 대기 자세는 견본의 세 칸으로 보이고 4단계 제안(결정 213) | "나"·"다"를 고르면 4단계 계획의 입력이 된다. 지금 고치라고 하면 단계 밖이라 따로 묻는다 |
| 3 | 바르톨로의 표정과 성격 | 기본 머리는 자신 있는 미소, 대사는 그대로(결정 212) | 머리 하나를 "이것만 바꾼다"로 다시 그린다(시트의 몫) |
| 4 | 임시 값 셋 | 바지·선 굵기 확정, R2의 기와 지붕 그대로(결정 216) | 값을 고친다. 지붕을 고치라면 R2를 바탕으로 한 장(예비 몫) |
| 5 | 비토리오의 옷 | 견본 값 그대로(결정 216) | 밝히라면 물림 값으로 한 장(V1의 몫) |
| 6 | 023의 셋(R1i·R2·R3)을 다시 묻지 않고 올리는 것 | 올린다(결정 217) | 빼라고 하면 올리지 않는다 |
| 7 | 024의 커밋, 다음 계획 025의 범위 | 정하지 않는다 | — |

- 3단계 완료 기준은 이 계획으로 채워지지 않는다(`STYLE_BIBLE.md`가 남는다). 단계 진행은 사용자가 정한다.
- 보류 중인 것(그대로 둔다): 2단계의 값과 결정(`docs/HANDOFF.md` 3번), `docs/BACKLOG.md`의 항목, `docs/plans/013-playtester.md`의 번호 겹침.

## 수정 기록

v2 → v3 (1회차 검토: design-reviewer APPROVE, tech-reviewer REVISE T1·T2).

- **T1 (수용)**: "잘라서 보는 것"의 T1·T2 줄을 고치고 그 아래에 "상태 색을 재는 법"을 더했다. 작업 2(도구와 SVG로 맞춰 보기), 작업 4(짝 굽기 여섯 장), 견본의 규칙 줄, 공통 규칙의 새 도구 목록을 맞췄다.
  - (a) 칸끼리(대기 ↔ 빈틈) 견주던 것을 **같은 상태의 필터를 켠 그림 ↔ 끈 그림**으로 바꿨다. 두 장의 같은 (x, y)를 읽는 새 로컬 도구 `tintpair.ps1`(`tintcheck.ps1`을 복사해 고친다)을 작업 2에 두고, 점은 견본이 파츠 좌표에서 셈해 `<pre id="tint-pts">`로 낸다.
  - (b) 선 점은 배율 1.5의 `bare=1` 굽기에서 선 구간의 가운데 한 화소를 읽는다. 구간이 3화소보다 짧으면 눈 확인으로 내린다.
  - (c) 재는 굽기는 모자를 씌운다(보는 판의 `parts-states`는 모자 없이 그대로). 모자 점은 이 굽기에서 잰다.
  - (d) 머리의 살 점은 같은 머리끼리(같은 상태의 켠 그림 ↔ 끈 그림) 견준다.
- **T2 (수용)**: P-KEEP-SHEET 코드 블록의 자리 표시를 `Change: <one line>`으로 바꾸고 설명은 블록 밖에 두었다.
- 기술 검토의 비차단 제안 (수용): 작업 2에 `bake024.ps1`의 shot 문법(`<id>[@<pick>][+<키>=<값>]…`)을 정했다.
- 디자인 검토의 비차단 제안 (수용): T1에 찌르기의 예비 동작과 무너짐의 칠·그림자 두 점씩을 더하고, 눈 확인 Q에 "네 상태가 한눈에 갈리는가"를 더했다. 위험 6의 말을 맞췄다.
- 그 밖에 바꾼 것: 없다(그림, 장 수, 승인, 블록의 글, 판정의 다른 줄은 그대로다).

v1 → v2 (검토 전. 사용자 답 Q1, 2026-11-22).

- **Q1 "넉넉히 20장"(나)**: "장 수와 승인"의 몫 표를 합 14(시트 5·안뜰 2·광장 2·비토리오 3·예비 2)에서 합 20(시트 8·안뜰 3·광장 3·비토리오 4·예비 2)으로 바꾸고 "몫 안에서는 장 수를 다시 묻지 않는다"를 더했다. 알림 줄의 "몫 14"를 "몫 20"으로, 결정 211과 "설계 결정"의 머리 줄, 위험 1의 시트 고치기 몫(4 → 7)을 맞췄다.
- "실행 전에 물을 것"을 받은 답으로 바꾸고 v1의 물음은 기록으로 남겼다.
- 그 밖에 바꾼 것: 없다.
