# 화풍 명세

3단계의 기준 화풍을 말과 값으로 적은 것이다. 026의 `docs/STYLE_BIBLE.md`(4 인물, 6 배경, 8 색, 13 만드는 길)가 이 파일을 입력으로 쓴다.

- 근거: 계획 021 견본에 대한 사용자 답(2026-11-21, `docs/DECISIONS.md`). "svg로 만든 이미지 스타일에 훨씬 가까워"이므로 기준 화풍은 SVG 견본이다. 다리는 A·B를 섞어 "선은 깔끔하게 칠은 바랜색으로" 한다(결정 194·195).
- 계획 023에서 화풍·품질·게임 제약으로 나눠 다시 썼다. 근거: 2026-11-21 사용자 답("그림체 즉 화풍을 베껴서 새로운 그림을 그려달라는거지 원래 있던 그림을 조금만 바꿔달라는게 아니었어. 조금 더 게임에 쓸 수 있을 정도로 퀄리티를 높여서 다시 그려달란거였어." 품질의 정도는 "완성된 만화 일러스트"). 결정 202·203.
- 기준 견본: `docs/style/samples/022-mix.html`(섞기). 값은 그 파일의 `:root`와 같다.
- **사용자가 고른 길(계획 023, 2026-11-22. 결정 209)**: 아홉 장의 인물 시험 끝에 정해졌다. 이 파일에서 서로 어긋나는 말이 있으면 이 줄이 앞선다.
  1. 섞은 SVG 견본(`generated/in/022-in-*`)을 **화풍의 참고 그림**으로 넣는다. 말만으로는 SVG의 꼴이 옮겨지지 않았다(R1a·R1b는 둥글둥글, R1c는 각짐).
  2. 꼴과 디테일의 양은 **섞은 SVG만큼 단순하게** 둔다. 올리는 것은 만듦새(비례, 이음매, 물건을 쥔 손)다. 2부(품질)의 표는 이 한도 안에서 읽는다.
  3. 디테일은 **조금만** 더한다: 고른 그림을 바탕 그림으로 넣고 "실루엣은 그대로, 안쪽에 이것만"이라고 적는다(P-KEEP·S-KEEP). 실루엣이 화소 단위로 지켜진다.
  4. 전신 그림의 자세는 여유롭게 결투에 임하는 자세이고 **팔다리는 굽히지 않는다**. 표정은 자신 있는 미소(R1e·R1i). 게임에 쓸 파츠(정면, 떨어진 팔)는 파츠 시트에서 따로 그린다(3부).
  5. 선은 고르고 굵게(가운데 × k 5.0~5.6. 섞은 SVG의 5.2와 같다). 바지는 밝힌 값(`#836850`).
  - 기준 그림(로컬): 인물 `generated/023-R1i-bartolo-front.png`, 무대 `023-R2-stage-alley.png`, 의뢰인 `023-R3-client-clara.png`. 프롬프트는 `prompts/023-R1h`·`R1i`·`R2`·`R3`.
- **프롬프트는 이 파일 끝의 블록을 글자 그대로 옮긴다.** 고칠 때는 이 파일을 먼저 고치고 프롬프트에 다시 옮긴다.
- 단위는 상대의 파츠 단위(목~골반 = 200)다. 화면 px은 교전 ×0.85, 멀리 ×0.55다.

# 1부. 화풍 — 남기는 것

새 그림이 SVG 견본과 같은 집안으로 보이게 하는 것이다.

## 다리 섞기

| | A (020) | B (020·021) | **섞기 (022)** |
|---|---|---|---|
| 선 색 | `#1E1A17` | `#3B2A1E` | **`#3B2A1E`** |
| 바깥 선 | 6 | 4.6 + 거친 필터(`inkline`) | **5.2** |
| 안 선(×0.55) · 눈썹(×1.35) | 3.3 · 8.1 | 2.5 · 6.2 | **2.9 · 7.0** |
| 필터 | 없음 | `inkline` | **없음** |
| 칠·그림자 | 맑은 색 | 바랜 색 | **B 그대로** |

- 끝과 꺾임은 둥글다. 굵기는 한 선 안에서 변하지 않는다.
- 화면에서 교전 바깥 4.4px·안 2.5px, 멀리 2.9px·1.6px이다. 5.2는 임시 값이다(필터를 뺀 B는 가늘어 보이고 A의 6은 무거웠다).
- 생성 그림에서는 "고르고 굵은 선, 1024 폭에서 약 10화소"라는 말로 옮기고 K2의 범위(가운데 × k 3.6~7.8)로 본다. 사용자 답(2026-11-21 B1): 첫 답은 R1b만큼 굵게(11화소, 4.7), R1c(8화소, 3.6)를 보고는 "좋다". 프롬프트의 말은 R1d부터 "약 8화소"다.

## 꼴 (2026-11-21 승인 B1의 답으로 더했다)

- 사용자 답(R1a·R1b를 보고, 원문): "나는 원래 그림의 직선같은 그림체가 좋았어 직금은 묘사하는 데에 집중해서 너무 둥글둥글해졌어. 원래의 그 둥글지만 직선을 살린 그림체로 그려야해."
- **둥근 모서리의 곧은 꼴**이 화풍이다. 덩이는 곧은 변과 평평한 옆면으로 짓고 모서리만 둥글린다(SVG 견본의 몸통·소매·바지·다리). 퍼프 소매, 풍선 같은 바지, 곱슬머리, 물결치는 윤곽처럼 부풀거나 굽이치는 꼴은 쓰지 않는다.
- 품질(2부)은 이 꼴 안에서 올린다: 디테일도 같은 단순한 꼴로 그리고, 주름은 두세 줄까지다.
- 사용자 답(R1c를 보고, 원문): "너무 각졌어. svg 그림체로 만들라니까". 곧은 변을 살리되 **각지지 않게** 한다: 둥근 사각형과 캡슐 같은 부드러운 꼴이다. 모따기한 다각형, 뾰족한 모서리, 면을 나눈 꼴은 쓰지 않는다. 말만으로는 SVG의 꼴이 옮겨지지 않아, R1d부터 섞은 SVG를 화풍의 참고로 넣는다("스케치를 넣는 길").

## 선

- **바깥 윤곽**: 닫힌 꼴마다 같은 굵기로 두른다. 멀고 가까움이나 빛의 쪽에 따라 굵기를 바꾸지 않는다.
- **안 선**: 바깥과 같은 색, 약 절반 굵기이고, 굵기가 변하지 않는다. (얼마나 그리는지는 2부.)
- **그림자에는 선이 없다**: 그림자 꼴은 칠 층에만 있다.
- **무대의 선**: 형태 윤곽만 긋는다. 가까운 것이 먼 것보다 조금 굵다(견본의 값: 가까운 집 모서리 4, 처마 3, 덧창·통 2~2.6, 먼 벽 1.6, 돌 1.4). 색은 `#3B2A1E`와 옅은 `#6B5440`. 조용한 구역(x 433~847, y 62~683)에는 선이 없다.

## 칠과 그림자

- **칠**: 한 면에 한 색, 평평하다. 그러데이션·질감·하이라이트가 없고, 인물의 칠에는 종이 결도 없다.
- **그림자 한 단계**: 같은 색조로 조금 어둡게 한다(저고리 `#5C6F7E` → `#4A5A67`, 살 `#EBC49F` → `#C98E66`, 모자 `#A5533F` → `#84422F`. 바지는 팔레트의 "어두운 옷의 밝기").
- **그림자의 꼴과 자리**: 빛은 왼쪽 위다. 그림자는 형태의 보는 쪽 오른쪽에 놓이는 단단한 경계의 한 단계 덩이다. (견본의 값: 몸통 x 34~71의 띠, 바지·스타킹의 오른쪽 띠, 소매 오른쪽 띠, 얼굴 오른쪽 초승달, 모자 꼭대기 오른쪽. 새 그림은 이 좌표를 따르지 않는다.)
- 머리털·수염·구두·허리띠는 선과 같은 `#3B2A1E`로 칠한 덩이다(선과 붙어 짙은 실루엣이 된다).
- 생성 그림에서는 그림자가 선보다 분명히 밝아야 한다(상태 색 필터의 문턱 Y 0.30. 결정 181). 그래서 큰 면의 그림자 hex를 프롬프트에 준다(결정 204).

## 얼굴과 비례

- **큰 머리**: 머리(목~정수리) 104, 몸(목~발) 370으로 머리가 몸의 약 0.28이다. 모자 45, 깃털은 옆으로 눕는다. 의뢰인은 허리 위라 머리가 더 커 보인다(카운터의 220×390 안에 머리 높이 140~155).
- **단순한 얼굴**: 작은 점 눈 둘(흰자·하이라이트 없음), 짧고 굵은 눈썹 둘, 작고 단순한 입, 단순한 코, 콧수염·턱수염은 머리털 색 덩이.
- **표정은 눈썹 각·눈 꼴·입 꼴로만 바뀐다.** 프롬프트에는 이 표에서 그 그림의 표정 줄을 말로 옮긴다.

  | 표정 | 눈썹 | 눈 | 입 |
  |---|---|---|---|
  | 대기 | 얕은 호 | 점 | 짧은 선 |
  | 거만함 | 평평 | 아래로 휜 반달 선 | 비스듬한 선 |
  | 당황 | 높이 들림 | 흰자 원 안의 작은 점 | 작은 타원 |
  | 어지러움 | 비뚤어짐 | X | 물결 |
  | 화남 | 안으로 내려옴 | 점 | 이를 드러낸 네모 |
  | 집중 | 곧은 막대 | 한 눈 감음 | 곧은 선 |

- 홍조, 땀방울, 눈물, 눈 하이라이트, 속눈썹, 입술 색, 볼의 빗금은 없다.

## 무대

- **큰 평면**: 가운데(x 240~1040)는 짙은 톤 덩이 몇 개를 맞대어 놓은 것이다(그늘 `#3A3027`, 밤하늘 `#3E4A55`, 땅 `#4E4336`, 벽 `#5E4C39`·`#54473A`·`#4A3F34`). 경계는 색 차이로만 읽힌다. 가운데 L은 0.07~0.08이다(짙되 검지 않다).
- **가장자리만 밝다**: 가까운 집·담은 양피지 `#E9D8B4`이고, 종이 결은 이 밝은 면에만 있다. 나무 들보 `#7A5232`, 덧창·통은 짙은 나무 `#4A3A2C`.
- **빗금은 띠로만**: 평행 빗금을 벽 모서리를 따르는 좁은 띠와 문 안쪽에만 둔다(견본의 값: 6px 간격, −35°, 1.1px, 폭 40). 교차 빗금은 쓰지 않는다.
- **벽을 덮는 결은 없다**: 벽돌·돌 결·회벽 금·나무결로 면을 채우지 않는다. (가장자리의 창틀·기와 한 줄 같은 형태 디테일은 2부.)
- **원근은 단순하다**: 곳은 실루엣으로 읽힌다(내민 위층과 간판, 우물·나무·대문, 지붕선·종탑).
- 극장으로 읽히는 것(아치·틀, 커튼, 구경꾼, 난간, 무대 조명, 모이는 바닥선, 거울 같은 날개)과 사람·동물은 없다(결정 190).

## 의뢰인과 카운터

- 의뢰인은 인물 규칙 그대로이고, 성격은 표정과 옷 하나·소품 하나로 읽힌다(클라라: 리본 모자·앞치마·핀 둘, 비토리오: 털깃·금 사슬·돈주머니).
- 카운터는 020 B의 배경 그대로다(양피지 벽과 빗금 들보, 나무 카운터의 물결 결 네 줄, 양피지 패널).

## 팔레트

신호색은 이 표에 넣지 않는다(결정 181, 코드 값 그대로). Y = sRGB 값의 0.2126R + 0.7152G + 0.0722B. 신호 구역(S ≥ 55%이면서 V ≥ 85%)에 드는 색은 없다.

| 이름 | 값 | HSV | Y | 쓰는 곳 |
|---|---|---|---|---|
| `--line` / `--ink` | `#3B2A1E` | S49 V23 | 0.18 | 선, 머리털·수염·구두·허리띠, 비토리오 모자 |
| `--ink-soft` | `#6B5440` | S40 V42 | 0.34 | 무대의 옅은 선, 빗금 |
| `--parch-1` | `#E9D8B4` | S23 V91 | 0.85 | 가장자리 벽, 목깃·커프·스타킹·깃털, 앞치마, HUD 패널 |
| `--parch-2` | `#D2B98C` | S33 V82 | 0.73 | 앞치마 그림자, 바탕 |
| `--parch-3` | `#A8895E` | S44 V66 | 0.55 | 문·덧창(밝은 쪽), 털깃 |
| `--c-doublet` / `-sh` | `#5C6F7E` / `#4A5A67` | S27 V49 / S28 V40 | 0.42 / 0.34 | 바르톨로 저고리·소매 |
| `--c-legs` / `-sh` (견본의 값) | `#6B5440` / `#57442F` | S40 V42 / S46 V34 | 0.34 / 0.28 | 바르톨로 바지(020~022 견본) |
| 바지, **생성에 주는 값**(임시, 결정 204) | `#836850` / `#6E5642` | S39 V51 / S40 V43 | 0.42 / 0.35 | 바르톨로 바지(023부터의 프롬프트) |
| `--c-skin` / `-sh` | `#EBC49F` / `#C98E66` | S32 V92 / S49 V79 | 0.79 / 0.59 | 살 |
| `--c-hat` / `-sh` | `#A5533F` / `#84422F` | S62 V65 / S64 V52 | 0.39 / 0.31 | 모자 |
| `--c-steel` | `#CFC8BA` | S10 V81 | 0.79 | 칼날·코등이 |
| `--c-glove` / `-sh` | `#7A5232` / `#634228` | S59 V48 / S60 V39 | 0.35 / 0.28 | 내 장갑 |
| `--c-psleeve` | `#5E6648` | S29 V40 | 0.38 | 내 소매 |
| `--cl-dress` / `-sh` | `#6F7F4F` / `#59663F` | S38 V50 / S38 V40 | 0.47 / 0.38 | 클라라 옷 |
| `--cl-hair` | `#7A5232` | S59 V48 | 0.35 | 클라라 머리털 |
| `--cl-hat` · `--cl-ribbon` | `#A5533F` · `#E2D3B4` | S62 V65 · S20 V89 | 0.39 · 0.83 | 클라라 모자·리본 |
| `--vi-robe` / `-sh` | `#7E4A4A` / `#663B3B` | S41 V49 / S42 V40 | 0.33 / 0.27 | 비토리오 옷 |
| `--vi-fur` / `-sh` | `#A8895E` / `#8C7050` | S44 V66 / S43 V55 | 0.55 / 0.45 | 비토리오 털깃 |
| `--vi-gold` | `#C08A3E` | S68 V75 | 0.56 | 금 사슬·반지 |
| `--vi-purse` | `#7A5232` | S59 V48 | 0.35 | 돈주머니 |
| `--st-shade` | `#3A3027` | S33 V23 | 0.19 | 무대 가운데 그늘 |
| `--st-sky` | `#3E4A55` | S27 V33 | 0.28 | 밤하늘 |
| `--st-ground` | `#4E4336` | S31 V31 | 0.27 | 땅 |
| `--st-wall` · `-2` · `-3` | `#5E4C39` · `#54473A` · `#4A3F34` | S39 V37 · S31 V33 · S30 V29 | 0.31 · 0.29 · 0.25 | 그늘진 벽 |
| `--st-timber` · `--st-wood` | `#5A4632` · `#4A3A2C` | S44 V35 · S41 V29 | 0.29 · 0.24 | 짙은 나무(들보·덧창·통·대문) |
| `--st-iron` | `#2E2620` | S30 V18 | 0.15 | 쇠 장식 |
| `--st-leaf` | `#46503A` | S28 V31 | 0.30 | 잎 덩이 |
| `--st-sil` | `#2E2A28` | S13 V18 | 0.17 | 먼 실루엣 |
| `--st-emblem` | `#7A6449` | S40 V48 | 0.40 | 간판 무늬, 징 |
| `--wood` | `#7A5232` | S59 V48 | 0.35 | 밝은 벽의 나무 들보 |
| `--red` · `--green` · `--blue` · `--ochre` | `#A5533F` · `#6F7F4F` · `#5C6F7E` · `#C08A3E` | S62 V65 · S38 V50 · S27 V49 · S68 V75 | 0.39 · 0.47 · 0.42 · 0.56 | 소품, HUD |

### 어두운 옷의 밝기 (결정 204. 사용자 답 "색을 밝힌다")

- 상대의 큰 면은 칠 Y ≥ 0.42로 두고, 프롬프트에 큰 면의 **그림자 hex도 준다**(hex는 그대로 따랐다. 022).
- 바르톨로 바지: 견본의 `#6B5440`(Y 0.34) / `#57442F`(0.28) → 생성에 주는 값 **`#836850`(Y 0.42) / `#6E5642`(Y 0.35)**. 저고리는 그대로다.
- 임시 값이고 확정은 024다. 비토리오의 옷(`#7E4A4A`, Y 0.33)도 같은 문제라 024에서 같이 정한다. 견본 020~022의 값은 고치지 않는다.
- 필터의 문턱(0.22·0.30)은 건드리지 않는다(4단계 셰이더의 값이다).

## 하지 말 것 (021·022 생성에서 나온 것)

| 본 것 | 어디서 | 명세의 말 |
|---|---|---|
| 굵기가 변하고 끝이 가늘어지는 잉크 선, 거친 가장자리 | 021 인물 G1~G4 | 고른 굵기, 매끄러운 가장자리, 둥근 끝 |
| 부드러운 그림자 경계, 칠 안의 엷은 그러데이션 | 021 인물 | 단단한 경계의 한 단계 그림자, 평평한 칠 |
| 얼굴의 홍조, 땀방울 | 021 클라라(G3) 등 | 덧붙임 없음 |
| 옛 판화의 빗금·교차 빗금·벽 결·벽돌, 인물보다 세밀한 무대 | 021 무대 G5 셋 | 큰 평면, 빗금은 가장자리 띠만, 무대도 인물만큼 단순하게 |
| SVG보다 훨씬 어두운 가운데(L 0.03~0.05) | 021 무대 G5 | 짙되 검지 않게 |
| 스케치의 기하 덩이를 그대로 따라 그린 것 | 022 N1 | 새로 그린다, 스케치는 자리의 참고만 |
| 묘사에 치우쳐 둥글둥글해진 것(퍼프 소매, 풍선 바지, 곱슬머리, 주름 여러 줄) | 023 R1a·R1b | 둥근 모서리의 곧은 꼴, 디테일도 같은 꼴로 |
| 가는 선(바깥 선 2.8) | 023 R1a | 굵은 선(R1c의 3.6이 "좋다") |
| 각진 꼴(모따기한 다각형 소매·바지, 뾰족한 모서리) | 023 R1c | 둥근 사각형과 캡슐 같은 부드러운 꼴(SVG 견본의 꼴) |

# 2부. 품질 — 올리는 것

"완성된 만화 일러스트"다. 왼쪽은 SVG 스케치에 있던 꼴이고 화풍이 아니다.

| 스케치의 한계 | 새 그림에서 |
|---|---|
| 조악한 덩이(이음매가 어긋나고 비례가 거친 사다리꼴·관·막대) | 같은 곧은 꼴을 제대로 다듬는다(1부 "꼴"). 이음매와 비례가 맞고 어깨·허리·무릎이 읽힌다. 자연스러운 곡선으로 바꾸지 않는다(023 R1a·R1b가 그렇게 해서 둥글둥글해졌다). 근육·해부의 묘사는 하지 않는다 |
| 상자 주먹 | 엄지와 손가락이 있고 칼자루를 실제로 쥔 손 |
| 쐐기 구두 | 밑창·굽·버클이나 리본이 있는 구두 |
| 민무늬 띠 목깃 | 꼴이 있는 주름 목깃 |
| 옷의 디테일 없음(안 선은 주름 둘, 손가락 셋 …이 전부였다) | 단추, 커프, 허리띠 버클, 곧은 주름 두세 줄 |
| 띠 없는 모자, 납작한 깃털 | 챙과 띠가 있는 모자, 꼴이 분명한 깃털 |
| 점과 선뿐인 무표정 | 같은 재료(눈썹·눈·입)로 성격이 드러나는 매력 있는 표정 |
| 좌우가 같은 굳은 자세 | 머리와 몸통은 정면이되, 발끝·어깨의 기울기·옷자락은 자연스럽게(3부의 제약 안에서) |
| 무대: 민무늬 평면과 네모뿐 | 가장자리의 집과 물건에 믿을 만한 꼴과 고른 디테일 몇(창틀, 덧창, 간판, 처마의 기와 한 줄, 통). 가운데는 그대로 조용하다 |

- 디테일의 상한: 모든 디테일은 같은 선과 평평한 칠로 그린다. 멀리(화면 ×0.55)에서도 실루엣과 얼굴이 읽혀야 한다. 천 무늬·결·빗금으로 채우지 않는다("하지 말 것").

# 3부. 게임 제약 — 지키는 것

품질을 올려도 양보하지 않는다(결정 203).

| # | 제약 | 까닭 | 그림에서 보는 법 |
|---|---|---|---|
| G1 | 머리와 몸통은 **엄격한 정면**, 곧게 선 자세 | 2D 펀치아웃의 상대, 예비 동작이 일관되게 읽혀야 한다(원칙 4) | H1 |
| G2 | **파츠로 나눌 수 있다**: 칼 팔은 보는 쪽 왼쪽, 팔과 몸통 사이에 틈, 손은 허리 높이, 칼날은 위·바깥으로 기울어 몸과 머리를 가로지르지 않는다, 다른 손은 등 뒤, 깃털은 옆으로 눕고 얼굴을 가리지 않는다 | 결정 12(파츠 이름·관절), 4단계의 컷아웃 | H2 |
| G3 | **머리 104**(목~골반 = 200일 때)로 맞출 수 있다: 그림의 머리가 104의 0.85~1.25배 | 사용자 답(얼굴은 지금 크기) | H9 |
| G4 | 맞춘 뒤 교전 꼭대기 ≥ 142(모자 ≤ 53)로 **두 줄 글자 상자와 겹치지 않는다** | 결투의 텔 글자가 가려지면 안 된다 | H10 |
| G5 | 색은 신호 구역 밖, 상대 큰 면 S ≤ 50% | 결정 181 | H5 |
| G6 | **상태 색이 얹힌다**: 큰 면(저고리·소매·바지)의 칠과 그림자 모두 Y ≥ 0.30, 선은 Y < 0.22 | 결정 181·188의 밝기 문턱 필터 | H8 |
| G7 | 무대: 조용한 구역(1280×720에서 x 433~847, y 62~683)에 선과 물건이 없고, 가운데 L 평균 ≤ 0.20, 극장으로 읽히지 않는다 | 결정 182·190 | H6·H7·H11 |
| G8 | 의뢰인: 허리 위, 얼굴이 가려지지 않는다, 카운터의 220×390 안에서 머리 높이 140~155로 맞출 수 있다 | 카운터 화면의 자리 | 눈 확인 |

- 2부의 "자연스럽게"가 G1·G2와 부딪히면 제약이 이긴다. 제약의 세기는 사용자가 맡겼고(2026-11-21 "알아서 잘 할 수 있게해줘") **굳게**로 정했다: 시험 그림을 그 자리에서 잘라 상태 색과 글자 상자까지 확인할 수 있고, 굳은 자세가 싫으면 한 장만 다시 돌려 되돌릴 수 있다.
- 좌우가 같은 굳은 자세는 제약이 아니다. 지키는 것은 머리·몸통의 정면과 파츠의 틈뿐이다.
- **사용자 답(2026-11-21 B1 둘째, R1c를 보고): "굳다, 풀어 달라".** 전신 그림(R1d부터)은 정면이거나 아주 살짝 튼 자연스러운 자세로 그리고 팔은 몸에 가깝게 둔다. G1·G2는 024의 파츠 시트에서 지킨다(전신 그림은 파츠로 자르지 않는다). H1·H2는 부드러운 확인이 되고, H5·H8·H9·H10은 그대로 굳은 확인이다.

# 프롬프트 블록

영어, ASCII만, 큰따옴표 없이 쓴다(결정 187). 이름은 쓰지 않는다(결정 179). 블록은 계획 023의 것이다(결정 205·206).

## 스케치를 넣는 길

| 길 | 넣는 것 | 쓰는 곳 |
|---|---|---|
| 가. 자세 안내도 | 견본 `023-redraw.html`에서 구운 회색 실루엣(선·얼굴·옷 디테일·그림자 없음. 몸 `#9A9A9A`, 칼 팔과 칼 `#6E6E6E`, 바탕 `#D8D8D8`) | 인물 시험 R1a |
| 나. 글만 | 없음 | 인물 시험 R1b |
| 무대 | 섞은 SVG 무대(`022-in-stage-*`)를 배치의 참고로만 | 무대 |

- 처음에는 섞은 SVG 스케치(`022-in-front`)를 인물에 넣지 않았다(022 N1이 그대로 따라 그렸다. 결정 205).
- **R1d부터 고쳤다(사용자 답 "svg 그림체로 만들라니까")**: 섞은 SVG(`022-in-front`)를 **화풍의 참고**로 넣는다. 따라 그리지 않게 자세를 다르게 주고(풀린 자세), "베끼지 말고 더 잘 그린 새 그림"이라고 적는다.

## 지시 블록

022 N1의 지시 블록에서 `sketch`만 `guide image`로 바꾼 것이다. `{WORKDIR}`는 호출 스크립트가 작업 폴더로 바꾼다.

길 가·무대:

```
Task: call your image generation tool exactly once to create exactly one image. You may use the code tool only to make that one call. Pass the attached guide image to the image generation tool as a referenced image by its path: {WORKDIR}\in-1.png. Give the image generation tool the text from the line that starts with Image: to the end of this message, word for word, as its prompt. Do not run shell commands. Do not read, create, change or delete any file. Do not use a browser, web search, computer use, apps or any other tool. Do not retry. When the image is done, reply with one line: done.
```

길 나:

```
Task: call your image generation tool exactly once to create exactly one image. You may use the code tool only to make that one call. Do not pass any reference image to the image generation tool. Give the image generation tool the text from the line that starts with Image: to the end of this message, word for word, as its prompt. Do not run shell commands. Do not read, create, change or delete any file. Do not use a browser, web search, computer use, apps or any other tool. Do not retry. When the image is done, reply with one line: done.
```

## P-FIG (바르톨로 전신의 구도. R1d부터: 섞은 SVG를 화풍의 참고로 넣고 자세를 푼다)

```
Pose and layout:
- The attached image is our own earlier drawing of this same character. It is the style reference: use its drawing style, its soft rounded shapes, its face type, its colors and its big head. Do not trace it and do not copy its stiff pose: draw the character again as a new, better, finished illustration.
- Front view or a very slight turn. He stands at ease but ready for a duel: a relaxed, confident fencer's stance, feet apart, weight balanced on both legs. Calm and unhurried.
- His limbs are simple and straight, like in the reference image: the legs are straight with no bend at the knees or ankles, and the arms are straight with no bend at the elbow. Each arm and each leg is one simple straight rounded shape.
- His sword arm is on the viewer's left. The arm is short and straight, held out a little from the body at a slant, with the hand at waist height. The hand grips the rapier at the ready, with the blade pointing up and leaning outward, away from the body, so the blade crosses neither the body nor the head.
- His other hand is held behind his back, in the classic fencer's way.
- The feather lies sideways toward the viewer's right, not upward.
- Nothing covers the face. The whole figure is inside the image with a margin. Nothing is cropped.
```

- R1d의 자세("relaxed, natural pose … a little weight on one leg", 다른 손은 허리)는 사용자가 "좀 더 여유로우면서 결투에 임하는 느낌의 자세와 표정으로 바꿔줘"라고 해 R1e에서 위와 같이 고쳤다(2026-11-21 B1 셋째 답. 그림체와 선의 굵기는 "맞다"·"좋다").
- 앞선 판: R1a·R1c(자세 안내도, 엄격한 정면과 팔의 틈)의 원문은 `prompts/023-R1a-bartolo-front.txt`·`023-R1c-bartolo-front.txt`에 있다. 사용자가 자세를 "굳다, 풀어 달라"고 했다(2026-11-21 B1 둘째 답).

## S-FIG2 (인물의 화풍과 품질. R1d부터)

```
Style (draw a new, original illustration in the style of the attached reference image, as described here):
- A finished cartoon character illustration for a game, drawn with care, in the drawing style of the attached reference image: soft, simple, rounded-geometric shapes. The shapes have straight sides with generously rounded corners and rounded ends, like rounded rectangles and capsules. No sharp corners, no facets, no angular polygon shapes, and no puffy, bulging, wavy or curly shapes. Simple and flat: a clean cartoon, not realistic and not painterly.
- Big head, about one quarter of the height from the neck to the feet. Simple, charming face: small solid dark eyes without highlights, short thick eyebrows, a small simple mouth, a simple nose. The expression is clear and full of character and comes only from the eyebrows, the eyes and the mouth.
- Keep it as simple as the reference image: the same small number of shapes and the same few inner lines. Do not add details that the reference does not have. A plain band collar, not a ruffled one. Plain simple shoes without buckles. Plain cuffs. A simple fist with a few short finger lines. A plain hat with a band and a simple feather. No extra seams, folds or wrinkles. Improve only the craft: clean construction, good proportions, parts that join properly and a hand that clearly holds the sword.
- Outlines: very dark warm brown, hex 3B2A1E. One even, bold line weight on every outer contour, about 8 pixels thick in a 1024 pixel wide image, smooth clean edges, round ends. No tapering, no wobble, no rough or broken edges. Inner lines are the same color and about half as thick.
- Fills: flat solid colors, muted and faded. Hair, beard, belt and shoes are filled with the same very dark brown as the outlines.
- Shadows: exactly one shadow tone per color, a slightly darker version of the same color and still clearly lighter than the outlines. Each shadow is one simple flat shape with a hard edge on the right side of the form, as if the light comes from the upper left. Shadows have no outline.
- Do not add: hatching, cross-hatching, engraving or etching lines, brush or ink texture, paper texture on the figure, gradients, soft or blurred shadow edges, highlights or shine, blush or rosy cheeks, sweat drops, tears, freckles, skin texture, fabric patterns.
```

- 고친 경위(원문은 그때의 프롬프트 파일에 있다):
  - R1a·R1b: 첫 항목이 "appealing, confident shapes with natural curves, not stiff geometric blocks", 선은 "fairly bold". → 둥글둥글해졌다(B1 첫 답).
  - R1c: 첫 항목이 "geometric and sturdy: every shape is built from straight edges and flat sides with rounded corners, like shapes cut from paper", 선은 "about 10 pixels". → 너무 각졌다(B1 둘째 답). 선의 굵기(8화소)는 좋다고 했다.
  - R1d: 섞은 SVG를 화풍의 참고로 넣고, 꼴은 "둥근 사각형과 캡슐", 선은 "about 8 pixels".
  - R1d~R1g의 셋째 항목은 "Better drawn than the reference where it matters … a hand with a thumb and fingers that really grips, shoes with a sole, a heel and a buckle, clothes with buttons, cuffs, a belt buckle, a neat collar and only two or three fold lines, a hat with a real brim and a band …"이었다. → R1g를 보고 사용자가 "아니 섞은 SVG그림처럼 단순한 느낌을 원해"라고 했다(2026-11-22). R1h부터 위와 같이 "참고 그림만큼 단순하게, 없는 디테일을 더하지 않는다, 만듦새만 다듬는다"로 고쳤다. 주제 줄도 "small ruff collar"·"buckled shoes"를 "small plain collar"·"plain shoes"로 고친다.
  - 이 답은 2부(품질)의 "디테일을 올린다"를 좁힌다: 올리는 것은 만듦새(비례, 이음매, 손이 칼을 쥔 꼴)이고, 디테일의 양은 섞은 SVG 그대로다.

## P-KEEP · S-KEEP (R1i: 고른 그림의 실루엣을 지키고 디테일만 조금 더한다)

사용자 답(R1h를 보고, 2026-11-22 원문): "실루엣 그대로 디테일만 조금 살려줘". 넣는 그림은 우리 그림 R1h(`generated/023-R1h-bartolo-front.png`)다(결정 186). P-FIG 자리에 P-KEEP을, S-FIG2의 첫째·셋째 항목 자리에 S-KEEP의 두 항목을 쓴다. 나머지 항목(얼굴, 선, 칠, 그림자, Do not add)과 색·바탕은 그대로다.

```
Pose and layout:
- The attached image is our own drawing of this character and it is the base. Keep it: the same outer silhouette, the same pose, the same proportions, the same shapes, the same face and expression, the same colors and the same line weight. Redraw it the same.
- Change only one thing: add a few small details inside the existing shapes, as listed below. The outer silhouette does not change.
- Nothing covers the face. The whole figure is inside the image with a margin. Nothing is cropped.
```

```
- A finished cartoon character illustration for a game, drawn with care, in the drawing style of the attached image: soft, simple, rounded-geometric shapes with straight sides and rounded corners. Simple and flat: a clean cartoon, not realistic and not painterly.
- Add only a little detail, inside the existing silhouette: a buckle on the belt, a small buckle and a low heel on each shoe, a simple cuff line on the sleeve, a softly scalloped lower edge on the collar, two short fold lines on the breeches, one seam line down each side of the doublet, clearer fingers on the sword hand, a band on the hat. Nothing else is added. No puffy sleeves, no ballooning breeches, no curls, no extra wrinkles.
```

## C-FIG2 (인물의 색. 바르톨로)

```
Colors:
- Main fills and their shadow tones: dusty grey-blue 5C6F7E with shadow 4A5A67 for the doublet and the sleeve, light wood brown 836850 with shadow 6E5642 for the breeches, parchment E9D8B4 for the collar, cuffs, stockings and feather, skin EBC49F, faded brick red A5533F for the hat, pale warm grey CFC8BA for the blade and guard.
- Avoid bright saturated yellow, orange, red, blue, purple or green, and pure white. Large areas are greyish and low in saturation.
```

## S-ST2 (무대의 화풍과 품질)

```
Style (the attached image is our own rough layout sketch. Use it only for the layout: where the walls, openings, ground and sky are and how dark the middle is. Draw a new, finished background illustration in the style described here):
- A finished cartoon background illustration for a game, drawn with care: the buildings and objects near the edges have believable, charming shapes and a few well-chosen details such as window frames, shutters, a shop sign, a row of roof tiles, a barrel. Still simple and flat, with large calm planes of color. The background is as simple as the cartoon characters that will stand in front of it.
- Outlines: very dark warm brown, hex 3B2A1E, even weight, smooth clean edges. Near things have slightly thicker outlines than far things.
- The middle of the image is calm: a few deep, muted, dark flat tones, dark but not black, with no outlines, no objects and no details. All details stay near the left and right edges and along the bottom edge.
- Fills are flat, with at most one flat shadow tone per color and hard shadow edges. Only the light parchment colored walls near the left and right edges may have a faint even paper grain. A few narrow bands of simple parallel diagonal hatching may run along the edges of those walls and inside door openings.
- Do not add: an engraving or etching look, cross-hatching, dense linework, brick or stone texture covering the walls, wood grain, plaster cracks, gradients, haze, light rays, glow.
```

## C-ST2 (무대의 색)

```
Colors: Dark middle tones around 3A3027, 3E4A55, 4E4336 and 5E4C39. Edge walls parchment E9D8B4, beams wood brown 7A5232, shutters and barrels dark wood 4A3A2C. Avoid bright saturated yellow, orange, red, blue, purple or green, and pure white. The central dark area has no bright or saturated color.
```

## 사람마다 바꾸는 줄

S-FIG2의 둘째 항목 끝에 표정 문장을 붙이고, 셋째 항목(디테일)과 다섯째 항목의 짙은 덩이 문장, 색 블록을 사람마다 바꾼다.

**바르톨로 전신**

- **R1g부터는 R1e의 표정 문장과 주제 줄("vain and quarrelsome")로 되돌린다**(B1 다섯째 답, 원문: "미안한데 지금보니 r1e의 표정과 자세가 더 좋은거 같아. 근데 팔꿈치나 발꿈치 같은 부분을 최대한 안 구부린 "섞은 SVG"사진이랑 비슷한 느낌이면 좋겠어."). 자세는 R1e의 것에 "팔다리는 굽히지 않는다"를 더했다(P-FIG).
- R1f의 표정 문장(쓰지 않는다. B1 넷째 답 "여유로운거랑 거만한건 다른데, 지금은 오만하고 거만해보여"): `His eyes are open, small solid dark dots under relaxed, level eyebrows. A calm, faint, friendly smile. His character shows in the expression: composed, unhurried and quietly ready. He does not look smug, arrogant, sneering or angry.`
- R1f는 주제 줄도 고쳤었다: `Bartolo, a vain and quarrelsome gentleman duelist` → `Bartolo, a seasoned gentleman duelist`(거만함을 부르는 말을 뺀다).
- R1e의 표정 문장(B1 셋째 답 "좀 더 여유로우면서 결투에 임하는 느낌의 자세와 표정으로". 거만해 보였다): `His eyes are open, small solid dark dots under calm, level eyebrows, one eyebrow slightly raised. A small confident smirk. His character shows in the expression: at ease, sure of himself and ready to fight.`
- R1a~R1d의 표정 문장: `His eyes are short downward curves, smug. His character shows in the expression: smug and touchy.`
- 셋째·다섯째 항목: S-FIG2 그대로. 색: C-FIG2 그대로.

**클라라**

- 표정 문장: `Her eyes are small solid dots. Her character shows in the expression: worried and polite, eyebrows raised in the middle.`
- 셋째 항목:

```
- Well-drawn details where they matter, drawn in the same simple straight-edged way: hands with thumbs and fingers, clasped naturally, a dress with only two or three straight fold lines, an apron with ties and two pins, a small hat with a real brim and a ribbon, hair in a bun as one simple solid shape. Every detail is drawn with the same clean line and flat color and stays readable when the figure is shown small.
```

- 다섯째 항목: 짙은 덩이 문장을 뺀다(머리털이 나무 갈색이다). `- Fills: flat solid colors, muted and faded.`
- 색:

```
Colors:
- Main fills and their shadow tones: muted olive green 6F7F4F with shadow 59663F for the dress, parchment E9D8B4 for the apron, wood brown 7A5232 for the hair, faded brick red A5533F for the hat, pale parchment E2D3B4 for the ribbon, skin EBC49F.
- Avoid bright saturated yellow, orange, red, blue, purple or green, and pure white. Large areas are greyish and low in saturation.
```

# R2·R3의 블록 (2026-11-22. 인물에서 배운 것을 옮겼다)

사용자가 인물에서 고른 것은 "섞은 SVG의 그림체, 그만큼 단순하게, 만듦새를 다듬고 디테일만 조금"이다(R1d·R1h·R1i의 답). 무대와 의뢰인도 그 길로 그린다: 섞은 SVG를 화풍의 참고로 넣고, 단순함을 지키고, 디테일은 조금만 더한다. 위의 S-ST2와 클라라의 셋째 항목(첫 판: "believable, charming shapes and a few well-chosen details", "Well-drawn details where they matter")은 쓰지 않고 아래를 쓴다.

## S-ST3 (무대의 화풍. 넣는 그림은 `022-in-stage-*`)

```
Style (the attached image is our own drawing. It is the layout and the style reference: use its composition, its simple flat shapes, its colors and how dark and calm the middle is. Draw a new, finished background illustration that stays this simple):
- A finished cartoon background illustration for a game, in the drawing style of the attached image: large calm flat planes of color and simple shapes with clean edges. Keep it as simple as the attached image. Improve only the craft: clean construction, believable simple perspective and parts that join properly. Add only a little detail on the houses and objects near the left and right edges, such as window frames, shutter boards, the shop sign, a row of roof tiles and barrel hoops. The background is as simple as the cartoon characters that will stand in front of it.
- Outlines: very dark warm brown, hex 3B2A1E, even weight, smooth clean edges. Near things have slightly thicker outlines than far things.
- The middle of the image is calm: a few deep, muted, dark flat tones, dark but not black, with no outlines, no objects and no details. All details stay near the left and right edges and along the bottom edge.
- Fills are flat, with at most one flat shadow tone per color and hard shadow edges. Only the light parchment colored walls near the left and right edges may have a faint even paper grain. A few narrow bands of simple parallel diagonal hatching may run along the edges of those walls and inside door openings.
- Do not add: an engraving or etching look, cross-hatching, dense linework, brick or stone texture covering the walls, wood grain, plaster cracks, gradients, haze, light rays, glow.
```

## 클라라 (넣는 그림은 `022-in-client-1`)

구도의 첫 항목:

```
- The attached image is our own earlier drawing of this same character. It is the style reference: use its drawing style, its soft rounded shapes, its face type, its colors, its framing and its big head. Do not trace it: draw the character again as a new, better, finished illustration.
```

S-FIG2의 셋째 항목 자리:

```
- Keep it nearly as simple as the reference image: the same small number of shapes. Improve the craft: clean construction, good proportions, parts that join properly and hands with fingers that are clasped naturally. Add only a little detail inside the shapes: the apron ties, two pins, a ribbon band on the hat, a softly shaped collar edge, two or three short fold lines on the dress, a clear simple bun. Nothing else is added. No puffy sleeves, no curls, no extra wrinkles.
```

표정 문장·다섯째 항목·색은 "사람마다 바꾸는 줄"의 클라라 그대로다.

# 022의 블록 (쓰지 않는다)

기록으로 남긴다. 화풍 블록의 첫 줄이 스케치를 따라 그리게 만들었다(022 N1). 구도 블록과 바탕 블록은 021 프롬프트 그대로였고, 구도의 "Follow the attached sketch for …" 줄에 "and its drawing style"을 더했다.

### S-FIG (인물의 화풍)

```
Style (the attached sketch is our own drawing and it is the style reference: match its drawing style exactly and redraw it as a clean, finished illustration):
- Clean flat cartoon drawing, like a neat vector illustration. Simple rounded geometric shapes and few details.
- Big head, about one quarter of the height from the neck to the feet. Simple face: eyes exactly as in the sketch (small solid dark dots, or short curved lines for a smug or half-closed look), short thick eyebrows, a small mouth drawn as one short line, a simple nose shape. The expression comes only from the eyebrows, the eyes and the mouth.
- Outlines: very dark warm brown, hex 3B2A1E. One even line weight on every outer contour, smooth clean edges, round ends. No tapering, no wobble, no rough or broken edges. The few inner lines are the same color and about half as thick.
- Fills: flat solid colors, muted and faded, as in the sketch. Hair, beard, belt and shoes are filled with the same very dark brown as the outlines.
- Shadows: exactly one shadow tone per color, a slightly darker version of the same color and still clearly lighter than the outlines. Each shadow is one simple flat shape with a hard edge along the right side of the form, as if the light comes from the upper left. Shadows have no outline.
- Do not add: hatching, cross-hatching, engraving or etching lines, brush or ink texture, paper texture on the figure, gradients, soft or blurred shadow edges, highlights or shine, blush or rosy cheeks, sweat drops, tears, freckles, skin texture, fabric patterns, extra wrinkles or folds.
```

### C-FIG (인물의 색. 바르톨로)

```
Colors:
- Use the colors of the sketch. Main fills: dusty grey-blue 5C6F7E for the doublet and the sleeve, wood brown 6B5440 for the breeches, parchment E9D8B4 for the collar, cuffs, stockings and feather, skin EBC49F, faded brick red A5533F for the hat, pale warm grey CFC8BA for the blade and guard.
- Avoid bright saturated yellow, orange, red, blue, purple or green, and pure white. Large areas are greyish and low in saturation.
```

### S-ST (무대의 화풍)

```
Style (the attached sketch is our own drawing and it is the style reference: match its drawing style exactly and redraw it as a clean, finished illustration):
- Clean flat cartoon drawing with large flat planes of color and few details. Simple shapes and simple perspective, as in the sketch. The background is as simple as the characters that will stand in front of it.
- Outlines: very dark warm brown, hex 3B2A1E, even weight, smooth clean edges. Near things have slightly thicker outlines than far things. The calm middle has no outlines.
- Only the light parchment colored walls near the left and right edges may have a faint even paper grain. A few narrow bands of simple parallel diagonal hatching run only along the edges of those walls and inside door openings, as in the sketch. Paving stones appear only along the bottom edge, drawn as simple irregular shapes.
- The middle is a few deep, muted, dark flat tones as in the sketch: dark, but not black.
- Do not add: an engraving or etching look, cross-hatching, dense linework, brick or stone texture on walls, wood grain, plaster cracks, gradients, haze, light rays, glow.
```

### C-ST (무대의 색)

```
Colors: use the colors of the sketch. Dark middle tones around 3A3027, 3E4A55, 4E4336 and 5E4C39. Edge walls parchment E9D8B4, beams wood brown 7A5232, shutters and barrels dark wood 4A3A2C. Avoid bright saturated yellow, orange, red, blue, purple or green, and pure white. The central dark area has no bright or saturated color.
```

### 사람마다 바꾸는 줄 (022)

S-FIG의 둘째 항목 끝에 표정 한 문장을 붙이고, 넷째 항목의 짙은 덩이 문장과 C-FIG의 둘째 줄을 사람마다 바꿨다.

| 그림 | 표정 문장 | 짙은 덩이 문장 | C-FIG 둘째 줄의 색 목록 |
|---|---|---|---|
| 바르톨로 전신 | His character shows in the expression: smug and touchy. | 그대로 | 위 C-FIG 그대로 |
| 바르톨로 파츠 시트 | The three heads show the three expressions listed above and are clearly the same man. | 그대로 | 위 C-FIG 그대로 |
| 클라라 | Her character shows in the expression: worried and polite, eyebrows raised in the middle. | 뺀다(머리털이 나무 갈색이다) | Use the colors of the sketch. Main fills: muted olive green 6F7F4F for the dress, parchment E9D8B4 for the apron, wood brown 7A5232 for the hair, faded brick red A5533F for the hat, pale parchment E2D3B4 for the ribbon, skin EBC49F. |
| 비토리오 | His character shows in the expression: smug and self-satisfied, half-closed eyes and a thin smile. | His cap is filled with the same very dark brown as the outlines. | Use the colors of the sketch. Main fills: dusty dark red-brown 7E4A4A for the robe, ochre brown A8895E for the fur collar, very dark brown 3B2A1E for the cap, ochre C08A3E for the gold chain and the rings, wood brown 7A5232 for the purse, skin EBC49F. |
