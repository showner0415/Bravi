# 계획 023: 화풍을 옮겨 새로 그리기 — 명세를 둘로 나누고, 시험으로 사용자의 눈에 맞춘다

- 버전: v3 (1회차 검토 대응: T1, 비차단 제안 둘. v2는 사용자 답 Q1~Q3. 끝의 "수정 기록")
- 개발 단계: CLAUDE.md 9장 **3단계(스타일 바이블)의 넷째 계획**. 게임 코드·씬·데이터·테스트는 고치지 않는다(교체는 4단계)
- 근거:
  - 사용자 답(2026-11-21, `docs/DECISIONS.md` "계획 022 실행 중 — 승인 B1의 사용자 답"): "그림체 즉 화풍을 베껴서 새로운 그림을 그려달라는거지 원래 있던 그림을 조금만 바꿔달라는게 아니었어. 조금 더 게임에 쓸 수 있을 정도로 퀄리티를 높여서 다시 그려달란거였어." 품질의 정도는 "완성된 만화 일러스트"(형태를 제대로 다듬고 손·옷·구두·모자의 디테일과 표정의 매력을 더한다. 여전히 단순하고 평평한 그림체).
  - 그대로인 답: 기준 화풍은 SVG 견본, 선은 깔끔한 짙은 고동 `#3B2A1E`, 칠은 바랜 색(결정 194). 짙은 무대, 상대 머리 104, 야외 무대 셋과 극장 금지(결정 190), 의뢰인 클라라·비토리오(결정 191), 그림은 메인이 Codex CLI로 `gpt-6.2-sol`·`high`만(결정 192), 돌리기 전에 장 수를 알린다, 참고 스크린샷을 넣지 않고 게임·작가 이름을 쓰지 않는다(결정 179·186).
  - 022에서 배운 것(`docs/style/GENERATION.md` "계획 022를 닫았다"):
    - 화풍 블록의 "match its drawing style exactly and redraw it"과 스케치를 함께 주면 스케치를 거의 그대로 따라 그린다. 선·칠·그림자의 말은 잘 듣는다.
    - 021의 프롬프트(스케치는 자세·비례의 참고, 화풍은 말로)는 새로 그린 그림을 냈다(G3·G4).
    - 색 hex는 그대로 따른다. SVG의 바지색(Y 0.34)을 주면 그림자가 Y 0.28이 되어 상태 색 필터의 칠 문턱(0.30) 아래로 간다(H8).
    - N1의 K2는 얼린 자리 탓에 걸렸다(열두 점 가운데 아홉은 고르다). 새로 그린 그림은 꼴이 스케치와 달라 같은 일이 더 잦다.
  - 쓰는 것: 절차와 막는 장치는 `docs/style/GENERATION.md` "절차"(결정 184·192)와 022의 F11. 재는 법과 얼린 기준은 같은 파일 "화풍 판정의 기준 맞추기". 파츠로 나누기는 "파츠로 나누기와 비례 맞추기"(결정 188). 도구는 로컬 `docs/style/generated/tools/`.
  - 지키는 것: 결정 12(파츠 이름·계층·관절), 결정 181(신호색 코드 값, 신호 구역 S ≥ 55%이면서 V ≥ 85% 밖, 상대 큰 면 S ≤ 50%, 상태 색은 칠에만 80%), 결정 189(생성 그림은 로컬만).
  - 넘지 않는 선:
    - 메인은 Godot을 어떤 방식으로도 실행하지 않는다. Edge headless·Codex CLI·화소 재기는 이 규칙 밖이다.
    - 고치지 않는 것: `scripts/`, `scenes/`, `data/`, `tests/`, `project.godot`, `docs/BACKLOG.md`, 2단계의 보류 값, 견본 `020-bridge.html`·`021-detail.html`·`022-mix.html`, 021·022의 프롬프트 여덟, 사용자의 파일(`.claude/agents/playtester.md`, `tools/`, `docs/plans/013-playtester.md`), 사용자의 Codex(`~/.codex/config.toml`, `auth.json`, 로그인, 기능, 샌드박스, `generated_images/`의 파일).
- 번호: 023. 결정 번호는 201부터다(계획 022 절이 200으로 끝난다).

## 3단계의 남은 나눔 (결정 201. 결정 193을 고친다)

| 계획 | 하는 것 | 끝나는 때 |
|---|---|---|
| 020~022 (끝) | 다리 견본, 세부 견본과 생성 절차, 섞은 다리와 명세 초판(시험 N1에서 닫음) | — |
| **023 (이 계획)** | 명세를 "화풍 / 품질 / 게임 제약"으로 다시 쓴다. 새로 그리는 프롬프트를 **화풍 블록마다 한 장씩** 사용자의 눈에 맞춘다: 인물(바르톨로 전신), 무대(뒷골목), 의뢰인(클라라). 고른 바르톨로를 파츠로 잘라 게임 제약을 확인한다 | 사용자가 인물·무대·의뢰인의 새 그림을 "맞다"고 한다(또는 다시 시험 몫을 다 쓰고 멈춘다) |
| 024 (예정) | 맞춘 프롬프트로 넓힌다(바르톨로 파츠 시트, 무대 안뜰·광장, 비토리오). 기준 이미지를 고르고 `docs/style/basis/`로 올린다. 팔레트 확정(어두운 옷의 밝기 포함) | 사용자가 기준 이미지를 고른다 |
| 025 (예정) | 한글 글꼴 후보(파일·라이선스), UI 패널·버튼, 1280×720 크기 기준 | 사용자가 글꼴·UI를 고른다 |
| 026 (예정) | `docs/STYLE_BIBLE.md`, `assets/MANIFEST.md`의 꼴, CLAUDE.md 7장 | 3단계 완료 기준 충족 → 사용자 판정 |

- 까닭: 022는 일곱 장을 한 계획에 넣었다가 첫 장에서 전제가 바뀌어 닫았다. 이번에는 "프롬프트가 사용자의 눈에 맞는가"만 먼저 확인하고(블록이 셋이라 장도 셋), 장을 많이 쓰는 넓히기는 맞춘 뒤의 계획으로 뗀다.
- 025·026은 합칠 수 있다. 024부터의 나눔은 023의 답으로 다시 정한다.

## 목표와 범위

**확인할 결과**. 메인은 파일 읽기·Grep·Glob·git, 구운 PNG와 생성 그림의 Read, 재기 스크립트로 확인한다. 화풍과 품질의 마지막 판정은 사용자의 눈이다.

1. `docs/style/STYLE_SPEC.md`가 **화풍(남기는 것) · 품질(올리는 것) · 게임 제약(지키는 것)** 셋으로 나뉘어 있고, 프롬프트 블록이 "새 그림을 그린다"로 바뀌어 있다. "match its drawing style exactly and redraw it"은 어디에도 없다.
2. 바르톨로 전신의 **시험 두 장**(자세 안내도를 넣은 것 / 글만으로 그린 것)이 021의 절차·막는 장치·모델로 돌았고, 사용자가 나란히 보고 판정했다.
3. 사용자가 "맞다"고 한 바르톨로가 파츠로 나뉘어 상태 넷에 신호가 얹히고, 머리 104로 맞춘 채 두 줄 글자 상자와 겹치지 않는다(게임 제약의 확인).
4. 같은 길로 그린 무대 한 장(뒷골목)과 의뢰인 한 장(클라라)이 견본에 놓였고 사용자가 판정했다.
5. 그림마다 굳은 확인(H·K)과 부드러운 확인의 결과가 `GENERATION.md`에 있다. 장·호출이 상한 안이고 저장소와 사용자의 Codex 설정이 그대로다.

**범위 밖**: 파츠 시트·무대 둘·비토리오·내 손과 칼(024), 고른 그림 올리기와 팔레트 확정(024), 글꼴·UI·크기 기준(025), `docs/STYLE_BIBLE.md`·`MANIFEST.md`(026), `assets/`, 카운터 배경의 생성.

## 명세를 다시 쓰는 법 (결정 202·203. `STYLE_SPEC.md`의 뼈대)

지금의 명세에서 절을 옮기고 고친다. 값(팔레트, 다리 섞기 표, 표정 표, 하지 말 것)은 그대로 쓰고 아래에 적은 것만 바꾼다.

### 1부. 화풍 — 남기는 것 (새 그림이 SVG 견본과 같은 집안으로 보이게 하는 것)

| 절 | 지금의 명세에서 | 바꾸는 것 |
|---|---|---|
| 다리 섞기 | 그대로 | "5.2는 임시 값"에 한 줄: 생성 그림에서는 "고르고 조금 굵은 선"이라는 말로 옮기고 K2의 범위(가운데 × k 3.6~7.8)로 본다 |
| 선 | 바깥 윤곽·그림자에 선 없음·무대의 선 | "안 선은 아주 적다"와 그 목록(주름 둘, 손가락 셋 …)을 **뺀다**(2부로). 남는 규칙: 안 선은 같은 색, 바깥의 약 절반 굵기, 굵기가 변하지 않는다 |
| 칠과 그림자 | 그대로 | 그림자의 SVG 좌표(x 34~71 등)는 "견본의 값"이라고 표시한다. 규칙은 "빛은 왼쪽 위, 형태의 오른쪽에 단단한 경계의 한 단계 그림자" |
| 얼굴과 비례 | 큰 머리, 단순한 얼굴, 표정 표, 없는 것의 목록 | "표정은 눈썹·눈·입으로만"은 남긴다. "스케치의 눈 꼴대로"는 뺀다(스케치를 따르지 않는다). 눈 꼴은 표정 표에서 그 그림의 표정 줄을 말로 옮긴다 |
| 무대 | 큰 평면, 가장자리만 밝다, 빗금은 띠로만, 극장 금지 | "벽돌·벽 결·나무결은 없다"는 "벽을 덮는 결은 없다"로 좁힌다(가장자리의 창틀·기와 한 줄 같은 형태 디테일은 2부) |
| 팔레트 | 그대로 | 아래 "어두운 옷의 밝기" |
| 하지 말 것 | 그대로 | 줄 하나를 더한다: "022 N1 — 스케치의 기하 덩이를 그대로 따라 그린 것 → 새로 그린다, 스케치는 자리의 참고만" |

### 2부. 품질 — 올리는 것 ("완성된 만화 일러스트". SVG 스케치의 한계였던 것)

지금의 "몸의 꼴" 절을 지우고 이 표로 바꾼다. 왼쪽은 스케치에 있던 꼴이고 화풍이 아니다.

| 스케치의 한계 | 새 그림에서 |
|---|---|
| 기하 덩이(사다리꼴 몸통, 곧은 관 소매, 막대 다리) | 자연스러운 곡선의 다듬은 형태. 어깨·허리·무릎·발목이 읽힌다. 여전히 단순하고, 근육·해부의 묘사는 하지 않는다 |
| 상자 주먹 | 엄지와 손가락이 있고 칼자루를 실제로 쥔 손 |
| 쐐기 구두 | 밑창·굽·버클이나 리본이 있는 구두 |
| 민무늬 띠 목깃 | 꼴이 있는 주름 목깃 |
| 옷의 디테일 없음 | 솔기, 단추, 커프, 허리띠 버클, 자리가 좋은 주름 몇 줄 |
| 띠 없는 모자, 납작한 깃털 | 챙과 띠가 있는 모자, 꼴이 분명한 깃털 |
| 점과 선뿐인 무표정 | 같은 재료(눈썹·눈·입)로 성격이 드러나는 매력 있는 표정 |
| 좌우가 같은 굳은 자세 | 머리와 몸통은 정면이되, 발끝·어깨의 기울기·옷자락은 자연스럽게(3부의 제약 안에서) |
| 무대: 민무늬 평면과 네모뿐 | 가장자리의 집과 물건에 믿을 만한 꼴과 고른 디테일 몇(창틀, 덧창, 간판, 처마의 기와 한 줄, 통). 가운데는 그대로 조용하다 |

- 디테일의 상한: 모든 디테일은 같은 선과 평평한 칠로 그린다. 멀리(화면 ×0.55)에서도 실루엣과 얼굴이 읽혀야 한다. 천 무늬·결·빗금으로 채우지 않는다("하지 말 것").

### 3부. 게임 제약 — 지키는 것 (결정 203. 품질을 올려도 양보하지 않는다)

| # | 제약 | 까닭 | 그림에서 보는 법 |
|---|---|---|---|
| G1 | 머리와 몸통은 **엄격한 정면**, 곧게 선 자세 | 2D 펀치아웃의 상대(1장), 예비 동작이 일관되게 읽혀야 한다(원칙 4) | H1 |
| G2 | **파츠로 나눌 수 있다**: 칼 팔은 보는 쪽 왼쪽, 팔과 몸통 사이에 틈, 손은 허리 높이, 칼날은 위·바깥으로 기울어 몸과 머리를 가로지르지 않는다, 다른 손은 등 뒤, 깃털은 옆으로 눕고 얼굴을 가리지 않는다 | 결정 12(파츠 이름·관절), 4단계의 컷아웃 | H2 |
| G3 | **머리 104**(목~골반 = 200일 때)로 맞출 수 있다: 그림의 머리가 104의 0.85~1.25배 | 사용자 답(얼굴은 지금 크기). 021 G1은 1.16배, 022 N1은 1.13배였고 줄여 맞췄다 | H9(새 확인) |
| G4 | 맞춘 뒤 교전 꼭대기 ≥ 142(모자 ≤ 53)로 **두 줄 글자 상자와 겹치지 않는다** | 결투의 텔 글자가 가려지면 안 된다 | H10(새 확인. 021의 규칙) |
| G5 | 색은 신호 구역 밖, 상대 큰 면 S ≤ 50% | 결정 181 | H5 |
| G6 | **상태 색이 얹힌다**: 큰 면(저고리·소매·바지)의 칠과 그림자 모두 Y ≥ 0.30, 선은 Y < 0.22 | 결정 181·188의 밝기 문턱 필터 | H8 |
| G7 | 무대: 조용한 구역(1280×720에서 x 433~847, y 62~683)에 선과 물건이 없고, 가운데 L 평균 ≤ 0.20, 극장으로 읽히지 않는다 | 결정 182·190 | H6·H7·H11(새 확인) |
| G8 | 의뢰인: 허리 위, 얼굴이 가려지지 않는다, 카운터의 220×390 안에서 머리 높이 140~155로 맞출 수 있다 | 카운터 화면의 자리 | 눈 확인 |

- 2부의 "자연스럽게"가 G1·G2와 부딪히면 제약이 이긴다. Q2의 답은 "알아서 잘 할 수 있게해줘"(맡김)였고 planner가 **굳게**로 정했다(결정 203). 까닭: 시험 그림을 그 자리에서 잘라 상태 색과 글자 상자까지 확인할 수 있고, 굳은 자세가 싫으면 한 장만 다시 돌려 되돌릴 수 있다. 반대로 느슨하게 시작하면 게임에 쓸 수 있는지를 024의 파츠 시트까지 알 수 없다.
- **뒤집는 자리**: B1에서 "자세가 굳어 보이는가"를 그림과 함께 묻는다. 사용자가 "굳다, 풀어 달라"고 하면 "장 수와 승인"의 "B1에서 제약을 푸는 길"을 따른다.

### 어두운 옷의 밝기 (결정 204. 022 보고서 4번의 H8)

- **색으로 푼다**(Q3의 답 "색을 밝힌다"). 상대의 큰 면은 칠 Y ≥ 0.42로 두고, 프롬프트에 큰 면의 **그림자 hex도 준다**(hex는 그대로 따랐다. 022).
- 바르톨로 바지: `#6B5440`(Y 0.34) / `#57442F`(0.28) → **`#836850`(Y 0.42, S 39% V 51%) / `#6E5642`(Y 0.35)**. 저고리 `#5C6F7E`(0.42) / `#4A5A67`(0.34)는 그대로다.
- 임시 값이다(되돌리기 쉬움: 명세의 두 값과 프롬프트의 두 hex). 팔레트 표에는 견본의 값 옆에 "생성에 주는 값"으로 적고, 확정은 024다. 비토리오의 옷(`#7E4A4A`, Y 0.33)도 같은 문제라 024에서 같이 정한다. 견본 020~022의 값은 고치지 않는다.
- 필터의 문턱(0.22·0.30)은 건드리지 않는다. 문턱은 4단계 셰이더의 값이고 지금은 견본의 필터뿐이다.

## 프롬프트 (결정 205·206. 원문은 `STYLE_SPEC.md` 끝에 두고 글자 그대로 옮긴다. 결정 195)

영어, ASCII만, 큰따옴표 없이, 이름 없이(결정 179·187). 지금의 S-FIG·C-FIG·S-ST·C-ST는 "022의 블록(쓰지 않는다)"이라는 머리 아래로 옮겨 기록으로 남기고, 아래 블록을 새로 둔다.

### 스케치를 넣는 길 둘 (결정 205)

| 길 | `-i`에 넣는 것 | 까닭 |
|---|---|---|
| **가. 자세 안내도** | 견본에서 구운 **회색 실루엣**(선·얼굴·옷 디테일·그림자 없음. 몸은 `#9A9A9A`, 칼 팔과 칼은 `#6E6E6E`, 바탕 `#D8D8D8`) | 자리와 비례(머리 크기, 팔의 틈, 손 높이, 칼의 기울기)만 주고 **따라 그릴 그림체를 주지 않는다**. 게임 제약 G2·G3를 지키기 쉽다 |
| **나. 글만** | 없음 | 그림 도구가 가장 자유롭게 새로 그린다. 제약은 글로만 지킨다 |

- 섞은 SVG 스케치(`022-in-front`)는 인물에 넣지 않는다. 깔끔한 선의 말과 같은 그림체의 스케치를 함께 주면 다시 따라 그릴 위험이 가장 크다(022 N1).
- **시험은 두 길을 한 장씩** 돌려 사용자가 나란히 본다. 어느 길이 "새로 그린 그림"과 게임 제약을 함께 내는지는 해 보아야 안다.
- 무대는 섞은 SVG 무대(`022-in-stage-alley`)를 **배치의 참고**로 넣는다. 조용한 가운데와 가장자리의 자리는 글만으로 맞추기 어렵고, 무대는 따라 그려도 인물만큼 어긋나지 않는다. 말은 "배치만 따르고 새로 그린다"다.
- 의뢰인은 B1에서 고른 길을 따른다(가면 의뢰인의 자세 안내도, 나면 글만).

### 지시 블록

- 길 가·무대: 022 N1의 지시 블록 그대로("Pass the attached sketch …"의 `sketch`를 `guide image`로만 바꾼다. "word for word" 문장 포함).
- 길 나: 참조 그림 문장을 "Do not pass any reference image to the image generation tool."로 바꾼다. 나머지는 같다.

### P-FIG (바르톨로 전신의 구도. 길 가)

```
Pose and layout (the figure will be cut into separate parts, so keep the parts apart):
- The attached image is only a rough placement guide made of plain grey shapes. It shows where the head, hat, torso, sword arm, hand, blade and legs go and how big the head is. Use it for placement and proportions only. Do not copy its blocky shapes: draw every part properly, as a new illustration.
- Strictly front view: the head and the torso face the viewer squarely. He stands upright, head straight, feet apart. The feet may turn slightly outward.
- His sword arm is on the viewer's left. It hangs down beside the body with a clear gap between the arm and the torso. The arm is short: the hand is at waist height, just above the belt and higher than the hips. The hand grips the rapier with the blade pointing up and leaning outward, away from the body, so the blade crosses neither the body nor the head.
- His other hand is hidden behind his back.
- The feather lies sideways toward the viewer's right, not upward.
- Nothing covers the face. The whole figure is inside the image with a margin. Nothing is cropped.
```

- 길 나는 첫 항목만 뺀다(머리 크기의 말은 S-FIG2에 있다).

### S-FIG2 (인물의 화풍과 품질)

```
Style (draw a new, original illustration in the style described here):
- A finished cartoon character illustration for a game, drawn with care: appealing, confident shapes with natural curves, not stiff geometric blocks. Still simple and flat: a clean cartoon, not realistic and not painterly.
- Big head, about one quarter of the height from the neck to the feet. Simple, charming face: small solid dark eyes without highlights, short thick eyebrows, a small simple mouth, a simple nose. The expression is clear and full of character and comes only from the eyebrows, the eyes and the mouth.
- Well-drawn details where they matter: a hand with a thumb and fingers that really grips, shoes with a sole, a heel and a buckle, clothes with seams, buttons, cuffs, a properly shaped collar and a few well-placed folds, a hat with a real brim and a band, a feather with a clear shape. Every detail is drawn with the same clean line and flat color and stays readable when the figure is shown small.
- Outlines: very dark warm brown, hex 3B2A1E. One even, fairly bold line weight on every outer contour, smooth clean edges, round ends. No tapering, no wobble, no rough or broken edges. Inner lines are the same color and about half as thick.
- Fills: flat solid colors, muted and faded. Hair, beard, belt and shoes are filled with the same very dark brown as the outlines.
- Shadows: exactly one shadow tone per color, a slightly darker version of the same color and still clearly lighter than the outlines. Each shadow is one simple flat shape with a hard edge on the right side of the form, as if the light comes from the upper left. Shadows have no outline.
- Do not add: hatching, cross-hatching, engraving or etching lines, brush or ink texture, paper texture on the figure, gradients, soft or blurred shadow edges, highlights or shine, blush or rosy cheeks, sweat drops, tears, freckles, skin texture, fabric patterns.
```

- 둘째 항목 끝에 그 그림의 표정 문장을 붙인다. 바르톨로 전신: `His eyes are short downward curves, smug. His character shows in the expression: smug and touchy.`
- 022의 블록에서 뺀 말: "the attached sketch … is the style reference: match its drawing style exactly and redraw it", "like a neat vector illustration", "Simple rounded geometric shapes and few details", "eyes exactly as in the sketch", "as in the sketch", "extra wrinkles or folds".
- F11의 세 구절(그림 도구 인자에서 찾는다): 인물 `new, original illustration` · `line weight` · `Do not add`, 무대 `new, finished background` · `even weight` · `Do not add`.

### C-FIG2 (바르톨로의 색)

```
Colors:
- Main fills and their shadow tones: dusty grey-blue 5C6F7E with shadow 4A5A67 for the doublet and the sleeve, light wood brown 836850 with shadow 6E5642 for the breeches, parchment E9D8B4 for the collar, cuffs, stockings and feather, skin EBC49F, faded brick red A5533F for the hat, pale warm grey CFC8BA for the blade and guard.
- Avoid bright saturated yellow, orange, red, blue, purple or green, and pure white. Large areas are greyish and low in saturation.
```

### 바르톨로 전신의 전문 (`docs/style/prompts/023-R1a-bartolo-front.txt`, 길 나는 `023-R1b-…`)

지시 블록 → `Image:` 줄 → `Subject:` 줄 → P-FIG → S-FIG2(표정 문장 포함) → C-FIG2 → `Background:` 줄. `Image:`·`Subject:`·`Background:` 줄은 `022-N1-bartolo-front.txt`와 글자 그대로 같다. 다만 `Subject:`의 "plain shoes"는 "buckled shoes"로 바꾼다(2부).

### S-ST2 · C-ST2 (무대)

```
Style (the attached image is our own rough layout sketch. Use it only for the layout: where the walls, openings, ground and sky are and how dark the middle is. Draw a new, finished background illustration in the style described here):
- A finished cartoon background illustration for a game, drawn with care: the buildings and objects near the edges have believable, charming shapes and a few well-chosen details such as window frames, shutters, a shop sign, a row of roof tiles, a barrel. Still simple and flat, with large calm planes of color. The background is as simple as the cartoon characters that will stand in front of it.
- Outlines: very dark warm brown, hex 3B2A1E, even weight, smooth clean edges. Near things have slightly thicker outlines than far things.
- The middle of the image is calm: a few deep, muted, dark flat tones, dark but not black, with no outlines, no objects and no details. All details stay near the left and right edges and along the bottom edge.
- Fills are flat, with at most one flat shadow tone per color and hard shadow edges. Only the light parchment colored walls near the left and right edges may have a faint even paper grain. A few narrow bands of simple parallel diagonal hatching may run along the edges of those walls and inside door openings.
- Do not add: an engraving or etching look, cross-hatching, dense linework, brick or stone texture covering the walls, wood grain, plaster cracks, gradients, haze, light rays, glow.
```

- C-ST2는 지금의 C-ST에서 첫 문장 "use the colors of the sketch."만 뺀 것이다.
- 무대 뒷골목의 전문(`023-R2-stage-alley.txt`): 지시 블록 → `021-G5-stage-alley.txt`의 `Image:`·`Subject:`·`Composition:` 블록 그대로(첫 항목 "Follow the attached sketch for the composition."만 "Follow the attached layout sketch for the composition only."로) → S-ST2 → C-ST2. 021의 `Style:` 줄과 `Colors to avoid` 줄은 쓰지 않고, S-ST2 뒤에 `No text, no signature.` 한 줄을 둔다.

### 클라라 (`023-R3-client-clara.txt`)

- 지시 블록(B1에서 고른 길) → `021-G3-client-clara.txt`의 `Image:`·`Subject:`·`Pose and layout:` 블록(길 가면 둘째 항목을 P-FIG 첫 항목의 꼴로 바꾼다: "The attached image is only a rough placement guide made of plain grey shapes … Use it for the framing and the head size only. Do not copy its blocky shapes." 길 나면 그 항목을 "The head is large. Keep the figure from the waist up."로 바꾼다) → S-FIG2 → 색 블록 → `Background:` 줄.
- S-FIG2에서 사람마다 바꾸는 줄: 표정 문장은 `Her eyes are small solid dots. Her character shows in the expression: worried and polite, eyebrows raised in the middle.`, 셋째 항목(디테일)은 그 사람의 것으로(`hands with thumbs and fingers, clasped naturally, a dress with seams and a few well-placed folds, an apron with ties and two pins, a small hat with a real brim and a ribbon, hair in a bun with a clear shape`), 다섯째 항목의 짙은 덩이 문장은 뺀다(머리털이 나무 갈색이다).
- 색 블록: 지금 명세 "사람마다 바꾸는 줄"의 클라라 색 목록에서 "Use the colors of the sketch."를 빼고 옷에 그림자 hex를 더한다(`muted olive green 6F7F4F with shadow 59663F for the dress`).
- B1에서 인물 블록을 고쳤으면 고친 블록을 쓴다.

## 장 수와 승인 (결정 207. 상한 8은 Q1의 답)

- 세는 법은 021·022와 같다(장 = 만들어진 그림, 호출 = 모델까지 간 `codex exec`). 그림 번호는 R, 파일은 `023-R<n><길>-<이름>`이다.
- **상한 8(사용자 답)**: 시험 2(R1a·R1b) + 인물 다시 시험 2 + 무대 1(R2) + 의뢰인 1(R3) + 다시 뽑기 2.
- 몫을 쓰는 규칙:
  - 인물 다시 시험은 **두 번까지**다. 한 번에 한 장(B1에서 사용자가 가깝다고 한 길로). 두 번 뒤에도 "다르다"면 멈추고 보고한다(무대·의뢰인은 돌리지 않는다).
  - 다시 뽑기 몫(2)은 기술 실패(F4·F8·F9)의 다시 돌리기, 무대·의뢰인의 다시 시험(B2 "나"), 굳은 확인에 걸린 그림의 다시 뽑기가 함께 쓴다. 인물 다시 시험에서 남은 몫도 여기에 쓸 수 있다.
  - 남은 몫이 무대 1 + 의뢰인 1보다 적어지면 B1에서 그렇게 알리고 어느 쪽을 돌릴지 묻는다.

| 지점 | 때 | 무엇 | 묻는 것 |
|---|---|---|---|
| A | 작업 3 뒤, 돌리기 직전에 한 줄 알리고 답을 기다리지 않는다(Q1의 답) | 시험 R1a·R1b 두 장 | "시험 2장(기술 실패면 다시 뽑기 몫에서)을 돌린다" |
| B1 | 작업 4 뒤 | 인물의 판정 | 아래 |
| B2 | 작업 5의 R2·R3 뒤 | 무대와 의뢰인의 판정 | 아래 |

- **B1에서 알리는 것**: 두 장의 기록(자리·크기·시간·토큰·한도, 모델·추론, 도구, F11), H·K의 결과, 구운 `fig-raw`·`cmp-bartolo`·`fig-duel`의 경로, 남은 몫. 메인의 눈 확인(아래 Q 표)은 참고로만 적는다.
- **B1에서 묻는 것**:
  - 가. 맞다 — 어느 그림을 기준으로 삼을지(R1a / R1b) → 그 그림을 파츠로 자르고(작업 5) R2·R3를 그 길로 돌린다.
  - 나. 다르다(무엇이 다른지 한 줄, 어느 길이 더 가까운지) → `STYLE_SPEC.md`의 블록을 먼저 고치고 그 길로 한 장 다시 돌린 뒤 B1을 다시 묻는다.
  - 다. 그만 → 있는 그림으로 작업 6·7을 한다.
  - 같이 묻는 것 셋(답이 없으면 지금 값): 선의 굵기가 괜찮은가(굵다 / 가늘다 / 좋다. 022 보고서 4번의 5.2), 바지의 새 밝기가 괜찮은가, **자세가 굳어 보이는가**(괜찮다 / 굳다, 풀어 달라). "풀어 달라"의 대가를 물음에 함께 적는다: 그 그림은 파츠로 자르지 않고, 상태 넷과 멀리의 확인(`fig-states`·`fig-far`)이 024의 파츠 시트로 넘어가며, 인물 다시 시험 몫을 한 번 쓴다.
  - **B1에서 제약을 푸는 길**(Q2를 맡긴 답의 뒤집는 자리. 사용자가 "굳다, 풀어 달라"고 했을 때만):
    - P-FIG의 둘째 항목을 "Front view or a very slight turn. He stands in a relaxed, natural pose, feet apart."로, 셋째 항목의 "with a clear gap between the arm and the torso"를 "close to the body"로 고쳐(명세의 블록을 먼저) 한 장 다시 돌린다. 인물 다시 시험 몫(두 번)에서 쓴다.
    - 그 그림부터 G1·G2는 "024의 파츠 시트에서 지킨다"가 되고 H1·H2는 부드러운 확인으로 적는다. H9·H10·H5·H8은 그대로 굳은 확인이다(머리 크기, 글자 상자, 색, 밝기).
    - 작업 5의 자르기(`fig-states`·`fig-far`)는 하지 않고 "024로 넘겼다(까닭)"를 그 섹션에 적는다. `stage-duel`은 자르지 않은 그림을 세운다. 명세 3부의 G1·G2 줄과 결정 203에 그 답을 적는다.
  - 굳은 확인(H1·H2·H9·H10)에 걸린 그림은 그 결과를 먼저 보이고 기준으로 삼기를 권하지 않는다. 사용자가 고르면 그대로 간다(사용자의 눈이 앞선다. 걸린 제약은 보고서 4번에 올린다).
- **B2에서 알리는 것**: R2·R3의 기록과 H·K, 구운 `stage-duel`·`cmp-stage`·`client-counter`·`cmp-client`의 경로, 남은 몫.
- **B2에서 묻는 것**: 무대와 의뢰인 각각 맞다 / 다르다(한 줄. 다시 뽑기 몫이 있으면 블록을 고쳐 한 장 다시) / 그만.
- 기다리는 동안 `docs/HANDOFF.md` 1번을 그 자리("023 승인 B1을 기다린다" 등)로 적는다.

## 판정

마지막 판정은 사용자의 눈이다. 재는 확인은 **게임 제약(H)** 을 지키는지와 **화풍(K)** 이 남았는지만 본다. "새로 그렸는가, 품질이 올랐는가"는 숫자로 가르지 않고 눈 확인(Q)으로 적어 사용자에게 보인다.

### 굳은 확인 (걸리면 다시 뽑기 후보. B1·B2에서 먼저 알린다)

| # | 무엇 | 재는 법과 통과 | 대상 |
|---|---|---|---|
| H1 | 정면 | 눈: 머리와 몸통이 정면이다(얼굴 가운데 선이 몸통 가운데와 맞는다) | R1 |
| H2 | 파츠로 나눌 수 있다 | 팔과 몸통 사이 바탕 화소의 틈 ≥ 6px(생성 해상도), 칼날이 몸·머리를 가로지르지 않는다, 깃털이 얼굴을 덮지 않는다 | R1 |
| H3 · H4 | 바탕 지우기 · 글자 없음 | 021과 같다(테두리 채우기 허용 차 28, 새는 곳 없음) | R1, R3 |
| H5 | 신호 구역, 큰 면 S ≤ 50% | 021과 같다 | R1, R3 |
| H8 | 큰 면의 칠·그림자 Y ≥ 0.30 | 021과 같다(18점). 더해 빈틈 칸의 물든 값이 `lerp(바탕, #4D80F2, 0.8)`와 ±4(고른 그림을 자른 뒤) | R1 |
| H9 | 머리를 104로 맞출 수 있다 | 원래의 (목~정수리) × k가 104의 0.85~1.25배(88~130) | R1 |
| H10 | 두 줄 글자 상자 | 머리 104로 맞춘 뒤 교전 꼭대기 ≥ 142(모자만 줄여 ≤ 53). `fig-duel`에서 상대가 글자 상자와 겹치지 않는다 | R1 |
| H6 · H7 | 극장 금지 · 무대 가운데 L 평균 ≤ 0.20, 95번째 ≤ 0.30 | 021과 같다(H7은 손질 `brightness()`로 푼다) | R2 |
| H11 | 조용한 구역에 선이 없다 | 1280×720에 맞춘 뒤 x 433~847, y 62~683 안의 K5 선 밀도 ≤ 기준 맞추기에서 얼린 값 | R2 |
| K1 | 선 색 | 022의 얼린 기준 그대로(±30, R − B ≥ 5) | 전부 |
| K2′ | 선 굵기의 고름 | 022의 열두 자리(파츠 좌표·높이 비율)에서 잰 폭 가운데 **가운데 값의 0.6~1.6배를 벗어난 점이 3개 이하**. R1은 가운데 × k가 3.6~7.8 | R1, R3 |
| K3′ | 평평한 칠 | 부위 셋마다 고정 칸 셋(022의 칸과 그 위아래 24화소)의 Y 표준편차 가운데 **가장 작은 값 ≤ 0.025**(칸이 주름·단추에 걸려도 평평한 칸이 하나 있으면 된다) | R1, R3 |
| K6 | 인물의 덧붙임 없음(눈) | 홍조·땀·눈물·눈 하이라이트·주근깨·볼 빗금·천 무늬·결이 없다. 눈 꼴은 프롬프트의 표정 문장대로 | R1, R3 |
| K7 | 무대의 판화 결 없음(눈) | 교차 빗금, 벽을 덮는 결이 없다 | R2 |

- K2′·K3′·H11은 **작업 3에서 다시 기준을 맞춘다**(사용량 없음. 022의 규칙 그대로): 섞은 SVG는 통과해야 하고, K2′는 021 G1·G4가 걸리고 022 N1은 통과해야 굳은 확인으로 쓴다. 가르지 못하면 부드러운 확인으로 내리고 B1에서 알린다. 문턱은 R1 전에 얼린다.
- K2′를 바꾸는 까닭: 022의 "최대 ÷ 최소"는 한 점이 다른 윤곽을 스치면 걸린다(N1). 새로 그린 그림은 꼴이 달라 그런 점이 생기기 쉽다.

### 부드러운 확인 (적기만 한다)

- K4(그림자 경계), K5(인물의 선 밀도. 디테일이 늘면 오른다. 섞은 SVG와의 비를 적는다), 무대 가장자리 띠의 K5.
- 자세 안내도와 생성 그림의 실루엣이 얼마나 겹치는가(길 가가 덩이를 따라 그렸는지의 참고).

### 눈 확인 Q (메인이 보고 적는다. 판정은 사용자)

| # | 볼 것 |
|---|---|
| Q1 | 스케치의 기하 덩이가 아니다: 어깨·허리·무릎이 읽히는 다듬은 형태 |
| Q2 | 손이 엄지와 손가락으로 칼자루를 쥐고 있다 |
| Q3 | 구두(굽·버클), 목깃, 단추·솔기·커프, 모자의 챙과 띠, 깃털의 꼴 |
| Q4 | 표정에서 성격이 읽힌다 |
| Q5 | 섞은 SVG와 같은 집안으로 보인다(고른 고동 선, 평평한 바랜 칠, 한 단계 그림자, 큰 머리) |
| Q6 | 멀리(×0.55)로 줄여도 얼굴과 실루엣이 읽힌다 |
| Q7 | 무대: 가장자리에 고른 디테일이 있고 가운데는 조용하다. 인물과 같은 결이다 |

## 견본 `docs/style/samples/023-redraw.html` (결정 208)

- 새 파일이다. `022-mix.html`을 복사해 시작하고 섹션을 아래 열둘로 줄인다. 020~022 견본은 고치지 않는다. 규칙은 022와 같다(`<meta charset="utf-8">` 맨 앞, 바깥 자원 없음, 생성 그림은 `<image href="../generated/…">`만, 단독 보기 `#<id>`, 상대는 `data-part` 무리, 그림이 없으면 "만들지 않았다(까닭)" 한 줄).

| 차례 | id | 무엇 | 크기 |
|---|---|---|---|
| 1 | `in-pose` | 바르톨로의 자세 안내도. `in-front`와 같은 자리·크기의 파츠를 선 없이 회색으로만 채운다(몸 `#9A9A9A`, 칼 팔·칼 `#6E6E6E`, 바탕 `#D8D8D8`). 얼굴·단추·주름·그림자·깃털의 결은 그리지 않는다 | 1024×1536 |
| 2 | `in-pose-client` | 클라라의 자세 안내도(같은 꼴. 머리·몸 `#9A9A9A`, 손 `#6E6E6E`) | 1024×1536 |
| 3 | `fig-raw` | 인물 시험의 원본을 나란히(가장 최근 것까지 네 칸. 칸마다 번호와 길) | 1280×720 |
| 4 | `cmp-bartolo` | 같은 크기(목~골반을 맞춘 0.65)·같은 무대 톤에 섞은 SVG · 022 N1 · 023의 시험들. 자르지 않은 그림이다 | 1280×720 |
| 5 | `fig-duel` | SVG 뒷골목의 교전 장면(HUD, 두 줄 글자, 고리)에 시험 그림을 자르지 않고 세운다(목~골반 = 200 × 0.85, 머리는 H9의 배율로 맞춘 104의 자리에 테두리 상자를 겹쳐 보인다). `?pick=`로 그림을 고른다 | 1280×720 |
| 6 | `fig-states` | B1에서 고른 그림을 파츠로 잘라 만든 상태 넷(물든 칠). 캡션 "얼굴은 하나다" | 1280×720 |
| 7 | `fig-far` | 같은 파츠의 멀리·방심 | 1280×720 |
| 8 | `stage-duel` | R2 위에 고른 바르톨로의 큰 베기(0.25, HUD, 두 줄 글자) | 1280×720 |
| 9 | `cmp-stage` | 뒷골목 셋: 섞은 SVG · 021 G5 · 023 R2 (HUD·상대 없음) | 1280×720 |
| 10 | `client-counter` | 카운터의 R3 클라라 | 1280×720 |
| 11 | `cmp-client` | 클라라 셋: 섞은 SVG · 021 G3 · 023 R3 | 1280×720 |
| 12 | `palette` | 바꾼 색(바지의 견본 값과 생성에 주는 값, HSV·Y), 잰 값(H·K), 기준 맞추기 | 1280×720 |

- 파츠로 나누기와 얹기는 `GENERATION.md` "파츠로 나누기와 비례 맞추기" 그대로다(테두리 채우기, 관절 읽기, k, 머리 104, 모자 ≤ 53, 팔 ±15%면 105, 칼은 칼자루 중심으로 돌림, 밝기 문턱 필터).
- 무대의 넣는 그림은 로컬의 `docs/style/generated/in/022-in-stage-alley.png`를 그대로 쓴다. 없으면 `022-mix.html#in-stage?stage=alley`를 구워 만든다(견본은 고치지 않는다).

## 작업 목록

**공통 규칙**

- "넘지 않는 선"을 지킨다. 대조가 어긋나면 값을 맞추지 말고 멈춰서 보고한다.
- 편집은 작게 나눠 한다(절 하나씩).
- 구운 PNG와 작업 폴더는 scratchpad에 둔다. 도구는 `docs/style/generated/tools/`의 것을 쓰고, 스크립트 안의 scratchpad 경로를 이 세션의 것으로 고친다(로컬 파일이라 저장소에 남지 않는다. 한글이 든 `.ps1`은 BOM을 지킨다).
- 굽기는 020 작업 4의 명령 그대로다(따로 된 `--user-data-dir`, 한 장씩, 우리 프로필의 프로세스만 끈다).
- Codex가 도는 동안 저장소의 추적 파일을 고치지 않는다(전후 대조).

### 작업 0. 시작 상태

- `git status --short`가 HANDOFF 머리에 적힌 것(022의 변경, 또는 사용자가 커밋했으면 깨끗함)과 이 계획 파일뿐인지 본다. 다른 변경이 있으면 멈추고 묻는다.
- 로컬 자료를 Glob으로 본다: `docs/style/generated/022-N1-bartolo-front.png`, `021-G*.png` 7, `in/022-in-*.png`, `tools/*.ps1`. 없는 것은 적고, 그것을 쓰는 칸(`cmp-*`의 021·022 칸, 기준 맞추기)을 "없다"로 둔다. `tools/`가 없으면 멈추고 보고한다(재는 도구를 다시 만드는 것은 이 계획의 크기를 넘는다).
- 완료 확인: 위 결과가 보고서 2번에 있다.

### 작업 1. 명세 다시 쓰기 — `docs/style/STYLE_SPEC.md`

- "명세를 다시 쓰는 법"대로 1부·2부·3부로 나누고 "어두운 옷의 밝기"를 팔레트 절에 넣는다. 머리의 "다시 써야 한다" 인용 상자는 지우고 한 줄로 바꾼다("계획 023에서 화풍·품질·게임 제약으로 나눠 다시 썼다. 근거: 2026-11-21 사용자 답").
- 프롬프트 블록: 022의 넷을 "022의 블록(쓰지 않는다)" 아래로 옮기고, P-FIG·S-FIG2·C-FIG2·S-ST2·C-ST2와 "사람마다 바꾸는 줄"(바르톨로·클라라)을 이 계획의 원문 그대로 둔다.
- 완료 확인:
  - Grep `match its drawing style`·`as in the sketch`·`colors of the sketch`가 "022의 블록" 절 안에만 있다.
  - 새 블록 안에서 Grep `[^\x00-\x7F]` 0, `"` 0. 파일 전체에서 Grep `-i "pizza|potion|tapblaze|niceplay|tinybuild"` 0.
  - Grep `836850`·`6E5642`가 팔레트 절과 C-FIG2에 있다. 3부의 표에 G1~G8이 있다.
  - "몸의 꼴"이라는 절 제목이 없다.

### 작업 2. 견본과 자세 안내도 — `docs/style/samples/023-redraw.html`

- "견본" 절대로 만든다. 이 작업에서는 `in-pose`·`in-pose-client`와 `cmp-*`의 SVG·021·022 칸, `palette`의 색 줄까지 그린다(023 칸은 "만들지 않았다").
- 완료 확인:
  - Grep `<section id="` 12건이고 표의 id·차례와 같다.
  - 바깥 자원 Grep 여덟(020 작업 3) 모두 0, 극장 함수 Grep `spectators|balustrade|folds` 0, 신호색 줄이 `020-bridge.html`과 같다.
  - `git diff --stat -- docs/style/samples/020-bridge.html docs/style/samples/021-detail.html`이 비어 있고, `022-mix.html`의 해시가 작업 0 때와 같다.
  - `in-pose`·`in-pose-client`를 구워 Read로 본다: 선·얼굴·글자·신호·HUD가 없고 회색 둘과 바탕뿐이다. `generated/in/023-in-pose.png`·`023-in-pose-client.png`로 복사한다.
  - 자리가 `in-front`와 같은지는 실루엣에서 읽히는 것으로만 본다(v3, T1. 안내도에는 목·골반의 경계가 없어 `scan.ps1`로 읽을 수 없고, 읽히는 표시를 따로 두지 않는다: 표시가 그림 도구에 넘어가 그려질 수 있다):
    - 견본 파일에서: `in-pose`가 `in-front`와 같은 파츠 꼴(`P`)·같은 포즈·같은 변환(자리와 배율)을 쓰고 다른 것은 칠·선의 규칙뿐임을 코드 읽기와 Grep으로 확인한다(두 섹션의 그리는 호출을 나란히 적는다). `in-pose-client`와 `022-mix.html`의 `in-client-1`도 같다.
    - 구운 그림에서: `measure.ps1`로 바탕을 지운 뒤 알파 상자(꼭대기·발끝·좌·우)를 `022-in-front`의 알파 상자와 견준다. 변마다 차이가 **0~8px 안쪽**(윤곽선 반 굵기 약 6px + 2px)이면 통과다. 칼 팔 덩이(`#6E6E6E` 화소의 상자)가 몸 덩이의 보는 쪽 왼쪽에 있고 둘 사이에 바탕 화소의 틈이 있다.
    - `022-in-front`가 로컬에 없으면 `022-mix.html#in-front`를 구워 견준다.

### 작업 3. 기준 다시 맞추기와 Codex 준비 (사용량 없음)

- `kmeasure.ps1`에 K2′(벗어난 점의 수)와 K3′(칸 셋의 최솟값), H11(조용한 구역의 선 밀도)을 더하고, K1의 판정 상수를 얼린 기준(R − B ≥ 5)으로 맞추고(지금 스크립트는 12로 찍는다) `calib.ps1`로 잰다: 섞은 SVG(전신·클라라·뒷골목), 021 G1·G3·G4·G5 뒷골목, 022 N1. 결과를 `GENERATION.md`의 새 절 "계획 023 — 기준 다시 맞추기"에 표로 적고 문턱을 얼린다. H11의 통과 값은 섞은 SVG의 값 + 0.01로 잡고, 021 G5의 값을 같이 적는다.
- Codex 준비: 022 작업 3과 같다(`codex --version`, `login status`, `debug models`, `config.toml` 해시를 `AA004752…186D`와 견줌, 끄기와 함께 `mcp list`). 해시가 다르면 켜진 플러그인 열·MCP를 읽기만 해 끄기 목록을 맞추고 새 해시를 이 계획의 처음 값으로 적는다. 로그인이 안 되어 있으면(F1) 사용자에게 부탁하고 멈춘다.
- 완료 확인: 표에서 섞은 SVG가 K1·K2′·K3′·H11을 통과한다. K2′가 021 G1·G4를 가르는지, N1이 통과하는지가 적혀 있다(가르지 못하면 "부드러운 확인으로 내림"). 같은 그림을 두 번 재어 값이 같다. 준비의 결과가 023 날짜로 있다.

### 작업 4. 시험 — R1a·R1b (승인 A → B1)

- 프롬프트 둘을 "바르톨로 전신의 전문"대로 써서 `docs/style/prompts/023-R1a-bartolo-front.txt`·`023-R1b-bartolo-front.txt`에 둔다. 돌리기 직전에 장 수를 한 줄 알린다(승인 A).
- `run-codex.ps1`로 한 장씩 돌린다. R1a는 `023-in-pose` 하나를 넣고, R1b는 `--image`를 주지 않는다(스크립트가 그림 없는 호출을 받지 않으면 그 인자만 고른다).
- 호출마다 `GENERATION.md`의 새 표 "기록 (계획 023)"에 022의 칸대로 적는다(R1b는 참조 그림 인자가 **없어야** 한다. 있으면 F12로 적고 B1에서 알린다).
- 그림마다: 바탕 지우기, 관절·k, H1~H5·H8(자르기 전의 18점)·H9, K1·K2′·K3′·K6, 부드러운 확인, 눈 확인 Q1~Q6. `fig-raw`·`cmp-bartolo`·`fig-duel`(그림마다)을 굽고 H10을 본다.
- **승인 B1**. "나"면 `STYLE_SPEC.md`의 블록을 먼저 고치고 고친 프롬프트를 `023-R1c-…`(다음은 `R1d`)로 두고 이 작업을 한 장으로 되풀이한다.
- 완료 확인: 기록 표의 줄 수 = 호출 수, 모델·추론 칸이 세션 기록의 `gpt-6.2-sol`·`high`·read-only, 부른 도구가 그림 도구 하나, F11의 세 구절, 전후 대조(git·`config.toml` 해시·이전 그림 수) 같음. 프롬프트 파일의 P-FIG·S-FIG2·C-FIG2가 그때의 `STYLE_SPEC.md` 원문과 글자 그대로 같다. 프롬프트 폴더의 `023-*`에서 Grep `-i "pizza|potion|tapblaze|niceplay|tinybuild"` 0, `[^\x00-\x7F]` 0, `"` 0, `reference/|screenshot` 0, `match its drawing style` 0.

### 작업 5. 고른 그림 자르기, 무대 R2, 의뢰인 R3 (B1 "가" 뒤 → B2)

- 고른 바르톨로를 파츠로 나눠 `fig-states`·`fig-far`를 그린다. H8의 물든 값과 H10을 다시 본다(머리 104, 팔, 교전 꼭대기).
- R2(뒷골목)와 R3(클라라)의 프롬프트를 "프롬프트" 절대로 써서 `023-R2-stage-alley.txt`·`023-R3-client-clara.txt`에 두고, 장 수를 알린 뒤 차례로 돌린다. 기록과 확인은 작업 4와 같다(R2: K1·H6·H7·H11·K7·Q7, R3: H3~H5·K1·K2′·K3′·K6·G8·Q).
- `stage-duel`·`cmp-stage`·`client-counter`·`cmp-client`를 굽고 **승인 B2**. "나"면 블록을 고쳐 다시 뽑기 몫 안에서 한 장 다시 돌린다.
- 완료 확인: `fig-states`의 머리 104(±5%), 교전 꼭대기 ≥ 142, 빈틈 칸 몸통·바지의 칠과 그림자가 셈과 ±4. 기록 표의 줄 수 = 호출 수 ≤ 상한. 몫마다 쓴 수가 표 아래에 있다.

### 작업 6. 굽기와 눈 확인

- 열두 섹션을 최종본으로 굽고(`fig-duel`은 그림마다) `--dump-dom`으로 섹션 12를 센다. 그림이 빠진 장은 `--virtual-time-budget=10000`으로 한 번 더.
- 눈 확인: Q1~Q7, 상대 전체가 화면 안이고 글자 상자와 겹치지 않는다, 상태 넷이 칠 색으로 갈리고 그림자까지 물든다(구멍·관절의 틈을 적는다), 멀리에서 가장 가는 선의 화면 px(025의 크기 기준 자료), 의뢰인이 카운터에 붙어 보인다.
- 완료 확인: 최종본과 눈 확인의 결과가 보고서 2번에 있다. 끝난 뒤 우리 프로필의 `msedge.exe`가 0개다.

### 작업 7. 기록과 보고

- `docs/DECISIONS.md`: 끝에 "2026-11-21 — 계획 023" 절. 결정 201~208 한 줄씩, 실행 전 답(Q1~Q3), 실행 중에 정한 것(얼린 문턱, 승인 B1·B2의 답 원문, 고친 블록 줄, 장·호출과 몫).
- `CLAUDE.md` 9장 현재 위치: "다음은 새 계획 023이고, 3단계의 남은 나눔은 그 계획에서 다시 정한다."를 "계획 023(화풍을 옮겨 새로 그리기)까지 실행했다. 3단계의 남은 나눔은 023~026이다(결정 201)."로 바꾼다. 다른 줄은 고치지 않는다.
- `docs/style/GENERATION.md`: 머리의 결정 범위에 201~208, 새 절 "계획 023"(기준 다시 맞추기, 기록 표, 배운 것: 두 길의 차이).
- `docs/reports/023-style-transfer-new-drawing.md`와 사용자 보고(10장 형식). 4번에 올릴 것: 인물·무대·의뢰인의 판정, 스케치를 넣는 길(024의 만드는 길), 선 굵기, 바지의 밝기(임시), 걸린 게임 제약이 있으면 그것, 다음 계획 024의 범위(파츠 시트·무대 둘·비토리오·올리기·팔레트 확정), 023의 커밋.
- `docs/HANDOFF.md`: 1번을 그때의 자리로, 3번에 "계획 023 보고서 4번" 한 줄.
- `docs/BACKLOG.md`는 건드리지 않는다.
- **playtester에게 맡길 확인: 없다**(게임이 바뀌지 않는다. `docs/style/`의 `.gdignore`는 021 뒤에 확인했다).
- 완료 확인: 보고서에 "확인 못 한 것"이 있다(021·022에서 못 한 셋 그대로, 넓혔을 때 같은 프롬프트가 다른 사람·곳에도 통하는지). `config.toml` 해시가 작업 3의 값과 같다. 끝의 `git status --short`에 이 계획이 더한 것이 이 계획 파일, `CLAUDE.md`, `docs/DECISIONS.md`, `docs/HANDOFF.md`, `docs/style/STYLE_SPEC.md`, `docs/style/GENERATION.md`, `docs/style/prompts/023-*.txt`, `docs/style/samples/023-redraw.html`, 보고서뿐이다. `docs/style/generated/`는 보이지 않는다.

## 설계 결정

상한 8(207)과 색으로 풀기(204)는 사용자 답이다. 203은 사용자가 맡겨 planner가 정했다. 나머지도 planner가 정했고 모두 임시다.

| # | 결정 | 이유 | 되돌리기 |
|---|---|---|---|
| 201 | 3단계의 남은 나눔: 023 명세 다시 쓰기와 맞추기(인물·무대·의뢰인 한 장씩), 024 넓히기·기준 이미지 고르기·올리기·팔레트 확정, 025 글꼴·UI·크기 기준, 026 STYLE_BIBLE. 결정 193을 고친다 | 022는 일곱 장을 한 계획에 넣었다가 첫 장에서 닫았다. 눈에 맞추기를 먼저 떼면 장과 검토를 덜 버린다 | 쉬움. 025·026은 합칠 수 있다 |
| 202 | `STYLE_SPEC.md`를 화풍(남기는 것) · 품질(올리는 것) · 게임 제약(지키는 것)으로 나눈다. "몸의 꼴"과 "안 선은 아주 적다"는 화풍이 아니라 스케치의 한계로 옮긴다 | 사용자 답: 화풍을 옮겨 새로, 완성된 만화 일러스트로 | 쉬움 |
| 203 | 게임 제약 G1~G8은 품질과 부딪히면 제약이 이긴다. 좌우가 같은 굳은 자세는 제약이 아니다(머리·몸통의 정면과 파츠의 틈만 지킨다) | 사용자가 맡겼다(Q2 "알아서 잘 할 수 있게해줘"). 굳게 시작하면 시험 한 장으로 게임 제약(자르기·상태 색·글자 상자)까지 확인되고, 자세의 자연스러움은 4단계의 컷아웃 애니메이션이 더한다. 원칙 4, 결정 12·181·190 | 쉬움. B1에서 사용자가 "굳다"고 하면 P-FIG 두 줄을 고쳐 한 장 다시 돌린다(그때 자르기는 024의 파츠 시트로 간다) |
| 204 | 어두운 옷은 색으로 푼다: 상대 큰 면의 칠 Y ≥ 0.42, 프롬프트에 그림자 hex도 준다. 바르톨로 바지 `#836850` / `#6E5642`(임시, 확정은 024) | 022에서 hex는 그대로 따랐고, 필터의 문턱은 4단계 셰이더의 값이라 지금 옮기면 다른 색 전부를 다시 재야 한다 | 쉬움. 값 둘 |
| 205 | 인물에는 섞은 SVG 스케치를 넣지 않는다. 시험은 두 길(회색 자세 안내도 / 글만)을 한 장씩 돌려 사용자가 나란히 본다. 무대는 SVG 무대를 배치의 참고로만 넣는다 | 같은 그림체의 스케치와 깔끔한 선의 말을 함께 주면 따라 그린다(022 N1). 어느 길이 새 그림과 제약을 함께 내는지는 해 보아야 안다 | 쉬움 |
| 206 | 화풍 블록을 새로 쓴다(P-FIG, S-FIG2, C-FIG2, S-ST2, C-ST2). "새로 그린다"와 디테일의 말을 넣고 "스케치대로"의 말을 모두 뺀다. 022의 블록은 기록으로 남긴다 | 결정 197이 사용자 답으로 맞지 않게 되었다 | 쉬움 |
| 207 | 장·호출 상한 8: 시험 2 + 인물 다시 시험 2 + 무대 1 + 의뢰인 1 + 다시 뽑기 2. 인물 다시 시험은 두 번까지이고, 그래도 다르면 멈춘다. 승인은 A(시험)·B1(인물)·B2(무대·의뢰인) | 마지막 판정이 사용자의 눈이라 다시 시험의 몫이 있어야 하고, 끝없이 돌지 않게 멈출 곳도 있어야 한다 | 쉬움 |
| 208 | 견본은 새 파일 `023-redraw.html`(섹션 열둘). 판정은 게임 제약 H(새 H9·H10·H11)와 화풍 K(K2′·K3′로 고침)만 재고, "새로 그렸는가·품질"은 눈 확인 Q로 적는다. K2′·K3′·H11은 R1 전에 다시 기준을 맞춰 얼린다 | 022의 K2는 재는 자리 탓에 걸렸다. 품질은 숫자로 가르면 판정을 흐린다 | 쉬움 |

## 위험

1. **두 길 모두 사용자의 눈에 맞지 않는다.** 대비: 다시 시험 두 번(답의 한 줄로 블록을 고친다). 그래도 다르면 멈추고 보고한다. 그때의 선택지(사람이 그린다, 다른 도구, 사용자가 직접 프롬프트를 고친다)는 보고서 4번에 올린다.
2. **글만으로 그리면 게임 제약이 깨진다**(팔이 붙는다, 머리가 작다, 몸이 틀어진다). 대비: H1·H2·H9·H10을 재서 B1에서 먼저 알린다. 자세 안내도의 길이 그 대비다.
3. **자세 안내도의 덩이를 다시 따라 그린다.** 대비: "Do not copy its blocky shapes"와 눈 확인 Q1, 실루엣 겹침(부드러운 확인). 글만의 길이 그 대비다.
4. **디테일이 늘어 멀리에서 뭉개지거나 상태 색이 얼룩진다**(디테일의 선이 Y 0.22~0.30 사이의 어중간한 색이 된다). 대비: Q6, `fig-far`, 빈틈 칸의 물든 값. 걸리면 블록의 디테일 문장을 줄인다.
5. **에이전트가 프롬프트를 다시 써서 흐린다.** 대비: "word for word"와 F11(022에서 들었다).
6. **새 K2′·K3′가 가르지 못한다.** 대비: 부드러운 확인으로 내리고 알린다(022와 같은 규칙). 판정은 사용자의 눈이다.
7. **바지색을 밝혀 견본(020~022)과 색이 달라진다.** 대비: `palette`에 두 값을 나란히 보이고 B1에서 묻는다. 확정은 024다.
8. **실행 중에 사용자를 기다린다**(B1이 최대 세 번, B2). 대비: 기다리는 동안 `HANDOFF.md`에 자리를 적는다. 사용량은 한 장에 약 4만 토큰, 5시간 창 +1% 안팎이다(021).
9. **생성 그림이 두 게임을 닮아 보인다.** 대비: 이름과 참고 그림을 넣지 않는다(Grep). 닮았는지는 사용자가 본다.
10. 막는 장치·사용자의 Codex 설정의 위험과 대비는 021 위험 2·3·9, 022 위험 7과 같다.

## 실행 전에 물을 것

**답을 받았다(2026-11-21). 남은 물음은 없다.**

- **Q1 답: 가** ("상한 8"). 시험 두 장은 돌리기 직전에 한 줄 알리고 바로 돌린다.
- **Q2 답: 맡김** (원문 "알아서 잘 할 수 있게해줘"). 선택지를 고르지 않았다. planner가 **굳게**로 정했고(결정 203, 명세 3부 끝의 까닭), B1에서 사용자가 그림을 보고 뒤집을 수 있다("장 수와 승인"의 "B1에서 제약을 푸는 길").
- **Q3 답: 가** ("색을 밝힌다"). 바지 `#836850`, 그림자 `#6E5642`. 임시 값이고 확정은 024다.

아래는 v1에서 물은 글의 기록이다.

**Q1. 새 그림의 장 수 상한과 시험의 시작**
- 가. **상한 8, 시험 두 장은 알리고 바로 돌린다(권함)**: 시험 2 + 인물 다시 시험 2 + 무대 1 + 의뢰인 1 + 다시 뽑기 2.
- 나. 상한 6: 시험 2 + 다시 시험 1 + 무대 1 + 의뢰인 1 + 다시 뽑기 1.
- 다. 상한 4, 인물만: 시험 2 + 다시 시험 2. 무대·의뢰인은 024로 넘긴다.
- 답에 따라: "장 수와 승인"의 몫과 결정 207, 다면 목표 4·작업 5의 R2·R3와 섹션 8~11이 빠지고 024가 그것을 맡는다. 시험 전에도 다시 묻기를 원하시면 승인 A에서 멈춘다.

**Q2. 품질을 올릴 때 게임 제약을 얼마나 지킬까요?** (022 보고서 4번)
- 가. **굳게(권함)**: 머리·몸통은 정면, 칼 팔은 몸통과 떨어뜨리고, 머리는 104로 맞출 수 있는 크기. 디테일과 형태의 다듬기는 그 안에서 한다. 한 장을 잘라 바로 상태를 얹어 볼 수 있다.
- 나. 느슨하게: 살짝 튼 자세나 몸에 붙은 팔도 받는다. 그림은 더 자연스럽지만 전신 그림을 파츠로 자를 수 없어, 게임에 쓸 파츠는 024의 파츠 시트에서만 나온다.
- 답에 따라: 나면 3부의 G1·G2가 "파츠 시트에서 지킨다"로 바뀌고 H1·H2가 부드러운 확인이 되며, 작업 5의 자르기(`fig-states`·`fig-far`)가 024로 간다.

**Q3. 어두운 옷의 그림자(H8)를 어떻게 풀까요?** (022 보고서 4번)
- 가. **색으로(권함)**: 바지를 조금 밝힌다(`#6B5440` → `#836850`). 상태 색이 그림자까지 고르게 얹힌다. 견본의 바지보다 밝아 보인다.
- 나. 그대로 둔다: 바지 그림자만 상태 색이 덜 물든다(022 N1에서 셈과 최대 29 차이). 문턱은 4단계 셰이더에서 다시 본다.
- 답에 따라: 나면 결정 204와 C-FIG2의 바지 hex 둘이 SVG 값으로 돌아가고 H8의 바지 그림자는 "알고 둔 것"으로 적는다.

## 사용자 결정 필요 (실행을 막지 않는다. B1과 보고서 4번에서 묻는다)

| # | 무엇 | 이 계획이 정한 것 | 답이 다르면 |
|---|---|---|---|
| 1 | 선 굵기 5.2 (022 보고서 4번) | 그대로 두고 프롬프트에는 "even, fairly bold"로 옮긴다. B1에서 그림을 보며 묻는다 | 굵다·가늘다면 S-FIG2의 그 말과 명세의 값을 고치고, 다시 시험 몫이 있으면 한 장 다시 돌린다 |
| 2 | 스케치를 넣는 길 | 시험 두 장을 보고 B1에서 고른다 | 024의 만드는 길이 그 답을 따른다(자세 안내도면 새 사람마다 안내도를 먼저 만든다) |
| 3 | 3단계의 남은 나눔 | 023~026(결정 201) | 넓히기를 이 계획에 붙이려면 상한과 승인을 다시 정해 이 계획을 고친다 |
| 4 | 022·023의 커밋 | 정하지 않는다(사용자가 지시한다) | — |
| 5 | 게임 제약의 세기 (Q2를 맡긴 답) | 굳게(결정 203). B1에서 "자세가 굳어 보이는가"를 묻는다 | "굳다, 풀어 달라"면 P-FIG 두 줄을 고쳐 한 장 다시 돌리고, G1·G2와 자르기는 024의 파츠 시트로 간다 |
| 6 | 바지의 밝기 (Q3 답) | `#836850` / `#6E5642`, 임시 | B1에서 너무 밝다고 하면 값 둘을 고친다. 확정은 024 |

보류 중인 것(그대로 둔다): 2단계의 값과 결정(`docs/HANDOFF.md` 3번), `docs/BACKLOG.md`의 항목, `docs/plans/013-playtester.md`의 번호 겹침.

## 수정 기록

v2 → v3 (1회차 검토: design-reviewer APPROVE, tech-reviewer REVISE T1).

- **T1 (수용)**: 작업 2 완료 확인의 "`scan.ps1`로 목·골반 높이 ±2px"를 지우고, 실루엣에서 읽히는 둘로 바꿨다: 견본 파일에서 `in-pose`가 `in-front`와 같은 파츠 꼴·포즈·변환을 쓰는지(코드 읽기와 Grep), 구운 그림의 알파 상자가 `022-in-front`보다 변마다 0~8px 안쪽인지와 칼 팔 덩이의 자리·틈. 안내도에 목·골반 표시는 두지 않는다.
- 기술 검토의 비차단 제안 (수용): 작업 3에서 `kmeasure.ps1`의 K1 판정 상수를 R − B ≥ 5로 맞춘다.
- 디자인 검토의 비차단 제안 (수용): B1의 "자세가 굳어 보이는가" 물음에 "풀어 달라"의 대가를 함께 적는다.
- 그 밖에 바꾼 것: 없다.

v1 → v2 (검토 전. 사용자 답 Q1~Q3, 2026-11-21).

- **Q1 "상한 8"**: "장 수와 승인"의 머리·상한 줄·승인 A의 때를 권함에서 사용자 답으로 바꿨다. 값은 v1과 같다.
- **Q2 맡김**: 값은 v1의 권함(굳게)을 유지했다. 더한 것: 명세 3부 끝에 맡긴 답과 까닭, B1의 같이 묻는 것에 "자세가 굳어 보이는가"(둘 → 셋), 새 항목 "B1에서 제약을 푸는 길"(P-FIG 두 줄을 고쳐 한 장 다시, H1·H2는 부드러운 확인으로, 자르기는 024로), 결정 203의 이유와 되돌리기(보통 → 쉬움), "사용자 결정 필요" 5번.
- **Q3 "색을 밝힌다"**: "어두운 옷의 밝기"의 권함 표시를 사용자 답으로 바꿨다. 값은 v1과 같다. "사용자 결정 필요" 6번을 더했다.
- "설계 결정"의 머리 줄과 "실행 전에 물을 것"을 받은 답으로 바꾸고 v1의 물음은 기록으로 남겼다.
- 그 밖에 바꾼 것: 없다.
