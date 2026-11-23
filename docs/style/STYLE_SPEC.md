# 화풍 명세

3단계의 기준 화풍을 말과 값으로 적은 것이다. 규칙·판정·만드는 길은 `docs/STYLE_BIBLE.md`에 있고, 이 파일은 값의 원본·경위·프롬프트 블록의 원문이다(결정 242). 값이나 블록을 고치면 이 파일을 먼저 고치고 바이블의 옮긴 줄도 함께 고친다.

- 근거: 계획 021 견본에 대한 사용자 답(2026-11-21, `docs/DECISIONS.md`). "svg로 만든 이미지 스타일에 훨씬 가까워"이므로 기준 화풍은 SVG 견본이다. 다리는 A·B를 섞어 "선은 깔끔하게 칠은 바랜색으로" 한다(결정 194·195).
- 계획 023에서 화풍·품질·게임 제약으로 나눠 다시 썼다. 근거: 2026-11-21 사용자 답("그림체 즉 화풍을 베껴서 새로운 그림을 그려달라는거지 원래 있던 그림을 조금만 바꿔달라는게 아니었어. 조금 더 게임에 쓸 수 있을 정도로 퀄리티를 높여서 다시 그려달란거였어." 품질의 정도는 "완성된 만화 일러스트"). 결정 202·203.
- 기준 견본: `docs/style/samples/022-mix.html`(섞기). 값은 그 파일의 `:root`와 같다.
- **사용자가 고른 길(계획 023, 2026-11-22. 결정 209)**: 아홉 장의 인물 시험 끝에 정해졌다. 이 파일에서 서로 어긋나는 말이 있으면 이 줄이 앞선다.
  1. 섞은 SVG 견본(`generated/in/022-in-*`)을 **화풍의 참고 그림**으로 넣는다. 말만으로는 SVG의 꼴이 옮겨지지 않았다(R1a·R1b는 둥글둥글, R1c는 각짐).
  2. 꼴과 디테일의 양은 **섞은 SVG만큼 단순하게** 둔다. 올리는 것은 만듦새(비례, 이음매, 물건을 쥔 손)다. 2부(품질)의 표는 이 한도 안에서 읽는다.
  3. 디테일은 **조금만** 더한다: 고른 그림을 바탕 그림으로 넣고 "실루엣은 그대로, 안쪽에 이것만"이라고 적는다(P-KEEP·S-KEEP). 실루엣이 화소 단위로 지켜진다.
  4. 전신 그림의 자세는 여유롭게 결투에 임하는 자세이고 **팔다리는 굽히지 않는다**. 표정은 자신 있는 미소(R1e·R1i). 게임에 쓸 파츠(정면, 떨어진 팔)는 파츠 시트에서 따로 그린다(3부). 파츠 시트의 첫째 머리가 이 얼굴이다(계획 024).
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
- 화면에서 교전 바깥 4.4px·안 2.5px, 멀리 2.9px·1.6px이다. 5.2로 확정했다(결정 216. 생성 그림은 가운데 × k 5.0~5.6을 겨냥하고 3.6~7.8을 받는다. 필터를 뺀 B는 가늘어 보이고 A의 6은 무거웠다).
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
  | 자신 있는 미소 | 평평, 한쪽을 살짝 듦 | 점 | 한쪽이 올라간 짧은 선 |
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
- 카운터는 020 B의 배경 그대로다(양피지 벽과 빗금 들보, 나무 카운터의 물결 결 네 줄, 양피지 패널). UI의 꼴과 글꼴은 4부.

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
| `--c-legs` / `-sh` (020~022 견본의 값. 기록) | `#6B5440` / `#57442F` | S40 V42 / S46 V34 | 0.34 / 0.28 | 바르톨로 바지(020~022 견본) |
| 바지, **주는 값(확정. 결정 204·216)** | `#836850` / `#6E5642` | S39 V51 / S40 V43 | 0.42 / 0.35 | 바르톨로 바지(023부터의 프롬프트) |
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
- **확정했다(결정 216, 2026-11-22)**: 바지는 `#836850` / `#6E5642`. 사용자가 그림을 보고 "좋다"고 했다. 견본 020~022의 값은 기록으로 남기고 고치지 않는다.
- **프롬프트에 주는 값이 정본이다.** 그림이 낸 값은 아래 "기준 그림에서 잰 값"에 따로 적고, 잰 값을 쫓아 주는 값을 고치지 않는다(지금의 hex로 나온 그림이 "맞다"를 받았다). 4단계에서 SVG·UI의 색을 그림 옆에 놓을 때는 잰 값에 맞춘다.
- 받는 범위: 상대의 큰 면은 칠·그림자 Y ≥ 0.30, 선 Y < 0.22, S ≤ 50%. 주는 칠은 Y ≥ 0.42로 두고 그림자 hex도 준다(그림자가 준 값보다 0.07까지 어둡게 나왔다).
- 비토리오의 옷은 `#7E4A4A` / `#663B3B` 그대로다. 의뢰인에게는 상태 색이 얹히지 않는다(G6은 상대의 제약이다). 기준 그림의 옷 그림자는 Y 0.28이라 선(0.18)과 갈린다.

### 기준 그림에서 잰 값 (계획 024. `docs/style/basis/`)

가운데 RGB다(`measure.ps1 -Regions`. 자리는 `GENERATION.md` "계획 024 — 팔레트의 잰 값"). 상대의 큰 면은 모두 받는 범위 안이다.

| 그림 | 색 | 주는 값 | 잰 값 | Y | 받는 범위 |
|---|---|---|---|---|---|
| 바르톨로 전신 `bartolo-front` | 선 | `#3B2A1E` | `#442B1A` | 0.19 | 선 < 0.22 ✓ |
| | 저고리 / 그림자 | `#5C6F7E` / `#4A5A67` | `#6D7982` / `#546068` | 0.47 / 0.37 | ✓ (S 16%) |
| | 바지 / 그림자 | `#836850` / `#6E5642` | `#8F6D4C` / Y만 잼 | 0.45 / 0.37 | ✓ (S 47%) |
| | 살 · 모자 | `#EBC49F` · `#A5533F` | `#F2C197` · `#B75D43` | 0.79 · 0.43 | — |
| 바르톨로 파츠 시트 `bartolo-parts` | 선 | `#3B2A1E` | `#452B19` | 0.19 | ✓ |
| | 저고리 / 그림자 | `#5C6F7E` / `#4A5A67` | `#697680` / `#515E65` | 0.45 / 0.36 | ✓ (S 18%) |
| | 바지 / 그림자 | `#836850` / `#6E5642` | `#926D4B` / `#7A5838` | 0.45 / 0.36 | ✓ (S 49%) |
| | 살 · 모자 | `#EBC49F` · `#A5533F` | `#F4C195` · `#B3583E` | 0.79 · 0.41 | — |
| 클라라 `client-clara` | 선 | `#3B2A1E` | `#3C2616` | 0.16 | — |
| | 옷 / 그림자 | `#6F7F4F` / `#59663F` | `#788253` / `#646C45` | 0.49 / 0.41 | — |
| | 살 | `#EBC49F` | `#EBC09B` | 0.78 | — |
| 비토리오 `client-vittorio` | 선 | `#3B2A1E` | `#3E2B1F` | 0.18 | — |
| | 옷 / 그림자 | `#7E4A4A` / `#663B3B` | `#844E4B` / `#6A3D3C` | 0.35 / 0.28 | — |
| | 털깃 · 살 | `#A8895E` · `#EBC49F` | `#B28B60` · `#EABE99` | 0.57 · 0.77 | — |
| 무대 셋 `stage-*` | 선 | `#3B2A1E` | 뒷골목 `#3B291B` · 안뜰 `#32271B` · 광장 `#342C28` | — | — |
| | 조용한 구역의 L | 짙되 검지 않게 | 뒷골목 0.043 · 안뜰 0.057 · 광장 0.050 | — | 평균 ≤ 0.20 ✓ |

- 그림은 준 값보다 저고리를 더 회색으로(S 27% → 16~18%), 칠을 조금 밝게, 살을 조금 더 붉게 낸다. 선은 준 값과 거의 같다.
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
| G3 | **머리 104**(목~골반 = 200일 때)로 맞출 수 있다: 그림의 머리가 104의 0.85~1.25배. 파츠 시트에서는 목~머리털 꼭대기가 117의 0.85~1.25배(H9s) | 사용자 답(얼굴은 지금 크기) | H9 |
| G4 | 맞춘 뒤 교전 꼭대기 ≥ 142(모자 ≤ 53)로 **두 줄 글자 상자와 겹치지 않는다** | 결투의 텔 글자가 가려지면 안 된다 | H10 |
| G5 | 색은 신호 구역 밖, 상대 큰 면 S ≤ 50% | 결정 181 | H5 |
| G6 | **상태 색이 얹힌다**: 큰 면(저고리·소매·바지)의 칠과 그림자 모두 Y ≥ 0.30, 선은 Y < 0.22 | 결정 181·188의 밝기 문턱 필터 | H8 |
| G7 | 무대: 조용한 구역(1280×720에서 x 433~847, y 62~683)에 선과 물건이 없고, 가운데 L 평균 ≤ 0.20, 극장으로 읽히지 않는다 | 결정 182·190 | H6·H7·H11 |
| G8 | 의뢰인: 허리 위, 얼굴이 가려지지 않는다, 카운터의 220×390 안에서 머리 높이 140~155로 맞출 수 있다 | 카운터 화면의 자리 | 눈 확인 |

- 2부의 "자연스럽게"가 G1·G2와 부딪히면 제약이 이긴다. 제약의 세기는 사용자가 맡겼고(2026-11-21 "알아서 잘 할 수 있게해줘") **굳게**로 정했다: 시험 그림을 그 자리에서 잘라 상태 색과 글자 상자까지 확인할 수 있고, 굳은 자세가 싫으면 한 장만 다시 돌려 되돌릴 수 있다.
- 좌우가 같은 굳은 자세는 제약이 아니다. 지키는 것은 머리·몸통의 정면과 파츠의 틈뿐이다.
- **사용자 답(2026-11-21 B1 둘째, R1c를 보고): "굳다, 풀어 달라".** 전신 그림(R1d부터)은 정면이거나 아주 살짝 튼 자연스러운 자세로 그리고 팔은 몸에 가깝게 둔다. G1·G2는 024의 파츠 시트에서 지킨다(전신 그림은 파츠로 자르지 않는다). H1·H2는 부드러운 확인이 되고, H5·H8·H9·H10은 그대로 굳은 확인이다.

# 4부. 글꼴·UI·크기 기준 (계획 025)

값은 Edge에서 구운 견본(`samples/025-type-ui-size.html`)에서 정하고 잰 것이다. Godot의 글자 그리기(힌팅, 줄 높이, 테두리)는 다를 수 있어 4단계에서 게임 화면으로 다시 본다. 사용자가 2026-11-22 승인 B에서 골랐다(결정 221~231).

## 글꼴

| 역할 | 글꼴 | 굵기 | 쓰는 곳 |
|---|---|---|---|
| 본문 | **나눔스퀘어라운드** | **ExtraBold(800) 하나**. 긴 글·흐린 글자·버튼·HUD 모두 같다(사용자 답 "이대로 — 전부 ExtraBold") | 사연 대사, 조건, 장부의 줄, 버튼, HUD의 라벨 |
| 제목 | **송명** | 400(굵기가 하나다) | 가게 이름, 화면 머리 줄, 큰 수(충족도·손익), 주 버튼 |
| 결투의 상태 글자 | **Noto Sans KR** | 900 | 상대 머리 위의 한두 줄, 가운데의 엉킴 경고 |

- HUD의 글자는 본문 글꼴이다(사용자 답 "상태 글자만 고딕". 본문이 둥근 고딕이라 HUD도 고딕 계열이 되었다).
- 흐린 글자는 굵기가 아니라 색(`#6B5440`)으로 낸다. 강조는 색(붉은 글자)과 크기, 제목 글꼴로 낸다.
- **상태 글자**: 28, 흰 글자, 검은 테두리 8(지금 게임의 `StateLabel`). 상자는 폭 414(조용한 구역 x 433~847), 윗선 y 62(`STATE_LABEL_Y`), 아래 끝 y 142(G4). Noto Sans KR 900으로 잰 값: 가장 넓은 줄(`막기를 뗐다 다시 올려라`) 285, 두 줄의 아래 끝 79(윗선에서. 80 안), 자연 줄 높이 40.
- **가장 작은 글자**: 14. 나눔스퀘어라운드 ExtraBold는 12에서도 세로 획 0.96·가로 획 1.00으로 문턱(0.70·0.50)을 넘는다.

### 후보의 표 (모두 SIL Open Font License 1.1. 로컬 `generated/fonts/<키>/`에만 두었다)

| 글꼴(키) | 배포처 | 저작권 줄 | Reserved Font Name | 굵기 · 파일 | 한글 | 가장 작은 크기 | 판정 |
|---|---|---|---|---|---|---|---|
| 나눔스퀘어라운드 `nanumsquareround` | `hangeul.naver.com`의 `nanum-square-round.zip`. 라이선스 전문은 네이버 도움말(`OFL-NAVER.txt`로 옮겨 둠) | Copyright (c) 2010, NAVER Corporation / 파일 안: Copyright 2017 NAVER Corporation, designed by Sandoll | **있다**(Nanum, Naver Nanum, …, NanumSquareRound) | L·R·B·EB TTF, 각 약 1.0MB | 11,172 | EB 12 (R은 15) | **본문으로 고름**(사용자가 후보 밖에서 골랐다) |
| 고운바탕 `gowunbatang` | `google/fonts` `ofl/gowunbatang` | Copyright 2021 The Gowun Batang Project Authors | 없다 | Regular·Bold, 8.4MB·8.2MB | 11,172 | 20까지 문턱을 못 넘음(가는 획) | 고르지 않음 |
| 나눔명조 `nanummyeongjo` | `google/fonts` `ofl/nanummyeongjo` | Copyright (c) 2010, NHN Corporation | **있다**(Nanum …, NanumMyeongjo) | Regular·Bold·ExtraBold, 각 3.1MB | 11,172 | 13 | 고르지 않음(메인의 권함이었다) |
| Noto Serif KR `notoserifkr` | `google/fonts` `ofl/notoserifkr` | Copyright 2012 Google Inc. | 없다 | 가변(200~900), 23.8MB | 11,172 | 15 | 고르지 않음. 마루 부리(그 저장소에 없다) 대신 넣은 예비 |
| 송명 `songmyung` | `google/fonts` `ofl/songmyung` | Copyright 2018 The SongMyung Project Authors | 없다 | Regular, 2.0MB | **2,350** | 12 | **제목으로 고름** |
| 함렛 `hahmlet` | `google/fonts` `ofl/hahmlet` | Copyright 2020 The Hahmlet Project Authors | 없다 | 가변(100~900), 3.6MB | 2,788 | 12(700) | 고르지 않음(메인의 권함이었다) |
| Noto Sans KR `notosanskr` | `google/fonts` `ofl/notosanskr` | Copyright 2014-2021 Adobe | **있다**(Source) | 가변(100~900), 10.4MB | 11,172 | 12(500) | **상태 글자로 고름**(900) |
| 검은고딕 `blackhansans` | `google/fonts` `ofl/blackhansans` | Copyright 2015 The Black Han Sans Project Authors | 없다 | Regular, 1.0MB | 2,581 | — | 고르지 않음(줄 높이 28이라 두 줄이 붙는다. 폭 267) |
| 도현 `dohyeon` | `google/fonts` `ofl/dohyeon` | Copyright 2018 The Do Hyeon Project Authors | 없다 | Regular, 0.9MB | 2,437 | — | 고르지 않음(폭 248, 줄 높이 28) |
| 주아 `jua` | `google/fonts` `ofl/jua` | Copyright 2018 The Jua Project Authors | 없다 | Regular, 2.1MB | 2,367 | — | 예비. 쓰지 않았다(폭 262) |

- 한글 글자 수는 글꼴 파일의 글자 표에서 센 완성형 음절(U+AC00~U+D7A3)의 수다. **지금 게임의 글(`scripts/`·`data/`·`scenes/`)에 쓰인 한글 628자는 열 집안 모두에 다 있다.** 송명은 2,350자뿐이라 6단계에서 글이 늘면 빠지는 글자가 생길 수 있다(그때 다시 센다).
- 파일의 SHA256 앞 16자리: 나눔스퀘어라운드 EB `9E845FC35C5BC4A5`, 송명 `7F90AB2025091156`, Noto Sans KR `194018E6B2B293A7`.
- **배포할 때 지킬 것**: 글꼴마다 라이선스 글(OFL 1.1 전문)과 저작권 줄을 게임과 함께 낸다. Reserved Font Name이 있는 글꼴(나눔스퀘어라운드, Noto Sans KR)은 글자를 덜어 내거나 고친 파일을 그 이름으로 낼 수 없다(서브셋을 만들면 이름을 바꾼다). 글꼴만 따로 팔 수 없다.

## UI의 꼴 — "나 · 필사본" (사용자 답)

양피지 위의 잉크다. 자리·글·글자 크기는 지금 게임 그대로이고 꾸밈만 정했다.

| 무엇 | 값 |
|---|---|
| 패널 | `#E9D8B4` + 종이 결, 바깥 테두리 3(`#3B2A1E`) + 5 안쪽에 가는 선 1(`#6B5440`), 네 모서리에 작은 마름모(반지름 4, `#D2B98C`) |
| 패널의 머리 글 | 붉은 글자(`#84422F`)와 그 아래 가는 밑줄 1 |
| 버튼 | 양 끝이 제비꼬리로 갈라진 띠. 테두리 2.5, 위아래 안쪽에 가는 선 1. 칠 `#E9D8B4` |
| 버튼의 상태 | 올림 `#D2B98C` · 누름 `#B8996C`(2화소 내려앉는다) · 못 누름 `#D2B98C`에 글자 `#6B5440`·테두리 `#6B5440` · 값이 걸린 채 못 누름은 글자 `#7A5232` · 주 버튼은 제목 글꼴의 붉은 글자(`#84422F`) |
| 자세 칸 | 24×14 사각, 테두리 1.5. 찬 칸: 상대 `#7A5232`, 나 `#59663F`. 빈 칸: `#E9D8B4`에 빗금 |
| 막대(충족도) | 잉크 눈금이 있는 자. 찬 곳 `#59663F`, 빈 곳 `#E9D8B4`, 테두리 1.5 |
| 장부 | 줄 사이에 가는 줄선 1(`#6B5440`), 합계 위에 두 줄 선, 수는 오른쪽 맞춤 |
| 결투 HUD | 밝은 양피지 패널(위와 같다). 장식은 모서리에만. 조용한 구역(x 433~847, y 62~683)에는 아무것도 더하지 않는다 |
| 글자색 | 본문 `#3B2A1E` · 흐린 글자 `#6B5440` · 붉은 글자 `#84422F`(`#A5533F`는 양피지 위에서 3.8:1이라 쓰지 않는다). 카운터의 나무 띠 위에서는 `#E9D8B4` |
| 벽과 머리 줄 | 카운터·정산·폐점의 벽과 윗띠는 `#E9D8B4`(붉은 글자가 5.3:1. `#D2B98C` 위에서는 3.95라 쓰지 않는다) |

**경고가 읽히게 하는 규칙**(엉킴·방심 막대. 세 안 공통이었다)

1. 신호로 치는 경고 둘은 코드 값 그대로다: 엉킴 경고 `#FF7333`(`BindBar.COLOR_WARN`), 방심 가득 `#F2CC4D`(`ComplacencyBar.COLOR_FULL`). 색을 바꾸지 않는다.
2. 라벨과 막대를 **짙은 띠**(`#2E2620`) 하나 위에 두고 빈 곳은 그 띠의 색이다. 밝은 양피지를 빈 곳으로 쓰면 금색이 1.2:1이라 보이지 않는다.
3. 평소 칠은 경고와 색조가 뛴다: 엉킴 `#8FA3B3`(팔레트 밖의 새 색. S 20% V 70%, 신호 구역 밖), 방심 `#CFC8BA`. 황토·붉은 계열·나무 갈색은 평소 칠로 쓰지 않는다.
- 잰 값(`gauge-states`): 엉킴 — 색조 차 172°, 평소 칠 S 0.20, 경고 대 띠 5.48, 평소 대 띠 5.70. 방심 — 평소 칠 S 0.10(색조 차 6°), 경고 대 띠 9.56, 평소 대 띠 8.93. 경고 때의 라벨은 경고 색이다(띠와 5.48·9.56).
- 가운데의 엉킴 경고 글자(`칼이 엉킨다!`, 26, `#FF7333`)는 지금처럼 무대 위에 그대로 둔다.

고르지 않은 안(기록): "가 · 민 양피지"(평평한 칠, 고른 선, 둥근 모서리의 패널과 버튼, 둥근 막대), "다 · 나무와 쇠"(나무 테 안의 종이, 쇠 징, 나무 명패 버튼, 결투 HUD는 밝은 테두리를 두른 짙은 판).

## 크기 기준 (1280×720의 화소)

### 글자 크기의 단계

| 단계 | 크기 | 쓰는 곳 | 지금 크기 → 단계 |
|---|---|---|---|
| 간판 | 54 | 처음 화면의 가게 이름 | 54 |
| 큰 수 | 46 | 결투 결과의 충족도 | 46 |
| 수 | 34 | 정산의 충족도, 폐점의 손익 | 34, 32 → 34 |
| 머리 | 28 | 화면 머리 줄, 주 버튼, 받은 돈, 상태 글자, 엉킴 경고 | 28, 30 → 28, 26 → 28 |
| 강조 | 24 | 간격, 장부의 주요 줄 | 24, 22 → 24 |
| 본문 | 20 | 사연 대사, 목록, 보통 버튼 | 20, 19 → 20 |
| 보조 | 18 | 조건, HUD의 라벨, 작은 버튼 | 18, 17 → 18 |
| 설명 | 16 | 힌트, 살 것의 설명, 안내 | 16, 15 → 16 |
| 깨알 | 14 | 도움말 띠, 각주 | 14, 13 → 14 |

- 견본의 화면은 지금 게임의 크기 그대로 그렸다. 단계 밖의 크기(13·15·17·19·22·26·30·32)를 단계로 옮기는 것은 4단계의 일이다.
- 가장 작은 글자는 14다. 줄 높이는 글자 크기의 1.5배가 기준이다.

### 대비 (견본의 `contrast`. 고른 안 "나")

| 무엇 | 문턱 | 잰 값 |
|---|---|---|
| 24 미만의 글자와 바탕 | 4.5 | 본문 9.73 · 흐린 글자 5.04 · 붉은 글자 5.34 · 버튼 9.73 · 올린 버튼 7.20 · 누른 버튼 5.1(칠을 `#A8895E` 4.17에서 `#B8996C`로 고쳤다) |
| 못 누르는 버튼의 글자 | 3.0까지 받는다 | 3.73 · 값이 걸린 버튼 3.59 |
| 24 이상의 글자(주 버튼의 붉은 글자) | 3.0 | 5.34 |
| 게이지의 찬 곳과 빈 곳 | 3.0 | 자세 칸 상대 4.85 · 나 4.40 · 충족도 4.40 (024 견본의 황토 칸은 1.6이었다) |
| 패널이 바깥 바탕에서 갈린다(칠이나 테두리 가운데 하나) | 3.0 | 짙은 무대 위: 칠 9.16 · 밝은 벽 위: 테두리 9.73 |
| 카운터 띠 위의 글자(`#E9D8B4` 대 `#7A5232`) | 4.5 | 4.85 |

### 선 굵기

| 선 | 정한 값 | 잰 값(화면 화소) |
|---|---|---|
| 인물의 바깥 선(파츠 단위 5.2) | 멀리 2.9 · 교전 4.4 · 밀착 5.7(셈) | 멀리 3 · 교전 4 · 밀착 6 |
| UI: 패널의 바깥 테두리 | 3 | 3 |
| UI: 버튼의 테두리 | 2.5 | 꽉 찬 화소 2 + 반 화소 |
| UI: 게이지의 테두리 · 장식선과 줄선 | 1.5 · 1 | 견본의 값 |

- 규칙: **UI의 어떤 선도 교전의 인물 바깥 선보다 굵지 않다.** 화면에서 가장 굵은 선은 늘 인물의 것이다(패널 3 < 교전의 인물 4).

### 여백과 버튼

| 무엇 | 기준 |
|---|---|
| 화면 가장자리의 여백 | 카운터·정산·폐점 32, 결투 HUD 10 이상 |
| 패널 안의 여백 | 좌우 22, 위아래 16 |
| 버튼의 최소 크기 | 160×42, 글자는 16 이상 |
| 버튼의 높이 | 주 버튼 76, 보통 56, 작은 것 42~46 |
| 버튼 안 글자의 좌우 여백 | 각 16 이상. 나눔스퀘어라운드 ExtraBold로 버튼 열(카운터 넷, 정산 둘, 폐점 둘, 처음 화면 둘)의 글이 모두 들어간다(가장 빠듯한 것: "값을 올려 부른다" 124 / 210) |
| 버튼 사이 | 12 이상 |

### 그림의 원본 해상도 (결정 228)

화면 화소 ÷ 원본 화소 = (파츠 단위 ÷ 원본 화소) × 파츠 배율 × 간격의 배율 × 창의 배율. 1보다 크면 그림이 늘어난다.

- **기준: 1920×1080 창(창의 배율 1.5)의 밀착(×1.1)에서 1 이하.** 상대의 파츠는 목~골반이 원본 330화소 이상이어야 한다(2560×1440까지는 440).
- 지금 파츠 시트(`basis/bartolo-parts.png`, 목~골반 337화소): 몸통·다리·칼 0.65(1280) · 0.98(1920) · 1.31(2560), 머리 0.60 · 0.90 · 1.20, 팔 0.51 · 0.76 · 1.01. **1920의 기준에 겨우 걸친다.**
- 무대(1536 폭): 1280에서 0.83, 1920에서 1.25. **1920에서는 늘어난다.** 안뜰·광장(0.84배로 맞춤)은 1.26.
- 의뢰인(1024×1536을 300×450에): 0.29(1280) · 0.44(1920). 넉넉하다.
- 견본에서 본 늘어난 윤곽: 밀착의 바깥 선이 1배 4화소 · 1.5배 7화소 · 2배 9화소이고 가장자리의 번짐은 셋 모두 1화소였다(브라우저가 매끄럽게 늘린 결과다).

## 4단계로 넘기는 것

- (계획 033: 원본을 넣었다. 서브셋은 6단계 뒤) 글꼴 파일을 `assets/`에 넣기와 서브셋(Reserved Font Name의 이름 바꾸기, 라이선스 글 싣기). 송명의 글자 수(2,350).
- Godot에서의 글자 모습: 상태 글자의 상자와 줄 높이, 가장 작은 글자, 테두리의 꼴.
- (계획 033: 옮겼다) 단계 밖의 글자 크기 옮기기(위 표의 "지금 크기 → 단계").
- 파츠 시트와 무대의 해상도(더 크게 그리거나 나눠 그린다), 멀리에서 줄일 때의 밉맵.
- (계획 033: 방심 막대를 견본 자리로, 위 가운데 패널을 x 346~894로, 충족도 글은 막대 오른쪽으로) HUD의 자리: 견본은 024 견본의 자리를 따랐다. 024는 방심 막대를 시간 패널 안(x 906~1116, y 35~59)에 그렸고 코드의 자리는 화면 (850, 36) 150×22다. 위 가운데 패널(334~946)이 왼쪽·오른쪽 패널과 6·46화소 겹친다. 충족도 라벨이 찬 막대 위에 놓이면 읽기 어렵다.
- (계획 033: 경고 글자를 아래 가운데로 옮겼다) 밀착에서 모자가 가운데의 엉킴 경고 글자와 겹쳐 보인다(지금 게임에도 있는 일이다. BACKLOG 020-1).
- 그린 질감(양피지, 장식 테두리)을 쓸지: 지금은 견본의 필터로 흉내 낸 종이 결뿐이다. 사용자가 바라면 4단계에서 만들 길과 장 수를 정한다.

# 5부. 자세와 모션 (계획 026)

값은 견본(`samples/026-pose-motion.html`)의 SVG에서 세운 것이다. Godot의 `Node2D` 회전도 시계 방향이 +라 방향은 같지만, 4단계에서 게임 화면으로 다시 본다. 팔의 방법은 사용자가 골랐다(결정 220): **어깨 회전을 기본**으로 하고(팔 한 덩이를 어깨에서 돌린다. 팔꿈치는 나누지 않는다), **큰 동작만 팔 그림을 따로** 그린다. 승인 A의 답(2026-11-22): 포즈 "맞다", 곡선 "나 · 멈칫(hold)", 따로 그릴 팔 "큰 베기의 예비 동작, 찌르기의 타격"(결정 240).

## 포즈의 꼴

포즈 하나는 아래 열의 값 한 줄이다(결정 233).

| 열 | 뜻 |
|---|---|
| `arm_deg` | 팔 각(도). 어깨 (−65, −180)를 축으로 돈다. 0은 곧게 아래, +는 화면에서 시계 방향(칼 팔이 보는 쪽 왼쪽인 상대에서 + 는 바깥·위, − 는 몸 앞) |
| `sword_deg` | 칼 각(도, **화면 기준**). 0은 칼날이 위, 90은 오른쪽. 칼은 Arm > Hand의 자식이라 지역 각 = `sword_deg − arm_deg − lean_deg` |
| `head_deg` | 머리 각(도) |
| `lean_deg` | 몸 기울기(도). 골반에서 Torso를 돌린다. 절댓값 6 이하(G1) |
| `shoulder_dx`, `shoulder_dy` | 어깨 자리 옮김(파츠 단위). 각 25 이하 |
| `arm_art` | 팔 그림. `Arm`(024의 팔·주먹·칼 파츠) 또는 따로 그린 것(`armUp`, `armThrust`) |

- 국면: 공격마다 `tell_start`(예비 동작 시작) · `hold`(멈칫의 끝) · `strike`(타격) · `recover_end`(회수의 끝), 상대마다 `idle` · `stagger` · `complacent`. 피하기는 고개만(−20.1°, 0.3초), 받아넘김·밀어붙임은 글자만(포즈 없음).
- 만드는 규칙: 출발 값은 지금 게임의 손이 가는 방향(`atan2(−(손x − 어깨x), 손y − 어깨y)`). `hold` = `tell_start`에서 팔을 타격의 반대쪽으로 8° 더, `recover_end` = `strike`에서 **팔만** 0° 쪽으로 10°. 공격마다 실루엣의 집안을 하나씩 준다: 찌르기 **가로 선**, 왼쪽 베기 **바깥 위의 사선**, 오른쪽 베기 **몸 앞의 사선**, 큰 베기 **가장 큰 세로**.
- 무너짐과 회수 끝은 넷(팔 ≥ 15°, 칼 ≥ 30°, 어깨 ≥ 15, 고개 ≥ 10°) 가운데 둘 이상에서 다르다. 잰 값: 찌르기 3 · 왼쪽 베기 3 · 오른쪽 베기 4 · 큰 베기 2.
- 거울 규칙(제안): 칼 팔이 오른쪽인 상대는 x와 각의 부호를 뒤집는다.

## 포즈의 표 (고른 값. 견본의 `pose-table`)

| 공격 · 국면 | arm_deg | sword_deg | lean_deg | arm_art | 출발 값에서 고친 까닭 |
|---|---|---|---|---|---|
| 찌르기 · tell_start / hold | 85 / 93 | 95 | 0 | Arm | 출발 값 −61.7·180(팔이 몸 앞에서 칼을 아래로). 가로 선이 되게 팔을 바깥 어깨 높이로, 칼을 가슴 앞에 눕힌다 |
| 찌르기 · strike / recover_end | −30 / −20 | 180 | 0 | armThrust | 출발 −21.5. 앞으로 뻗은 팔 그림을 가운데 쪽으로 돌린다 |
| 왼쪽 베기 · tell_start / hold | 110 / 118 | −75 | 0 | Arm | 출발 67.6·−50. 바깥 위의 사선, 큰 베기와 갈리게 덜 든다 |
| 왼쪽 베기 · strike / recover_end | 20.8 / 10.8 | −120 | 0 | Arm | 출발 그대로 |
| 오른쪽 베기 · tell_start / hold | −88 / −96 | 45 | 0 | Arm | 출발 −80.8·50. 1회 −100은 멈칫(−108)의 주먹이 턱을 가려(R2 0.19) 시안의 범위(−100~−130) 밖으로 내렸다 |
| 오른쪽 베기 · strike / recover_end | −51.9 / −41.9 | 120 | 0 | Arm | 출발 그대로 |
| 큰 베기 · tell_start / hold | 152 / 160 | (−45) | −4 | armUp | 출발 −124.7·0은 팔이 얼굴 앞을 지나 R2 0.45. 머리 옆으로 곧게 들고 몸을 조금 젖힌다. 칼이 팔 그림에 들어 있어 `sword_deg`는 쓰이지 않고 화면의 칼은 팔과 한 줄(약 −28°/−20°) |
| 큰 베기 · strike / recover_end | −21.5 / −11.5 | 180 | 0 | Arm | 출발 그대로 |
| 대기 `idle` | 23 | −21 | 0 | Arm | 결정 220의 "다" |
| 무너짐 `stagger` | 0(어깨 dy 25) | 165 | 0 | Arm | 고개 22.9 |
| 방심 `complacent` | 23 | −140 | 0 | Arm | — |

지금 게임의 값(견본의 `game-table`, 팔은 자리만 옮긴다): 찌르기 예비 동작 30% 팔 (0, −211)·칼 180 · 큰 베기 25% (0, −277.5)·45 · 왼쪽 베기 회수 (−120, −140)·−120 · 무너짐 (−65, −130)·165·고개 22.9.

## 움직임

- 시간은 상대 데이터의 값만 쓴다: 대기 0.9 → 예비 동작(`tell_time`, 밀착 × 0.8) → 타격(빨강 0.1초) → 회수(막힘 `recovery_time`, 패리당함 +0.85, 헛침 × 0.55, 0이면 없다) → 대기. 손 계산과 견본의 `timeline`이 같다(찌르기·막힘 0.90/1.55/1.55, 큰 베기·막힘 0.90/2.00/3.60, 큰 베기·패리 4.45, 밀착 큰 베기 1.78/3.38 등).
- **고른 곡선 `hold`**(승인 A2 "나"): 예비 동작의 진행 0~0.2는 대기 → `tell_start`(끝이 느려진다), 0.2~`hold_end`는 `tell_start` → `hold`(멈칫), 마지막 `swing`초는 `hold` → `strike`(끝이 빨라진다). `swing = min(0.2 × 예비 동작, 패리 창 − 0.03)` = 찌르기 0.13 · 베기 0.15 · 큰 베기 0.15 · 밀착 찌르기 0.104초. 회수는 `strike` → `recover_end`(내내 느리게), 대기로 돌아감 0.2초.
- 두 규칙: **타격 순간은 바뀌지 않는다**(어느 곡선이든 고리가 0이 될 때 `strike`). **돌아감은 빠르게**(회수가 끝나면 더는 빈틈이 아니다).
- 팔 그림은 **국면의 경계에서만** 바꾼다: 예비 동작 내내 `tell_start`의 그림, 타격부터 회수 끝까지 `strike`의 그림.

## 원칙 4의 확인 (결정 235. 문턱은 임시)

한 색 실루엣(칼 팔 파랑, 머리 빨강, 몸 회색. 필터는 파츠의 그림마다)을 굽고 로컬 도구 `sil026.ps1`로 셌다. 도구는 알려진 도형으로 맞췄다(겹침 0.333, 가림 0.300, 두 번 같음).

| # | 무엇 | 문턱 | 지금 게임 | 어깨 회전 · `hold`(고른 것, 팔 그림 끼움) | 어깨 회전 · `game` 곡선(견줌) |
|---|---|---|---|---|---|
| R1 | 공격끼리·공격 대 대기의 칼 팔 겹침(교전·멀리, 진행 25%·60%) | ≤ 0.30 | 최대 0.305(찌르기 대 큰 베기) | **최대 0.160** | 최대 0.380(60%에서 타격 쪽으로 모인다) |
| R2 | 머리의 가림(교전) | ≤ 0.10 | 큰 베기 25% 0.317, 찌르기 25% 0.134 | **최대 0.057**(오른쪽 베기 60%) | 최대 0.003 |
| R4 | 상태 글자 상자(x 497~783 · y 62~142)의 칼(교전·밀착, 25%) | 적기만 | 0 | **0** | 큰 베기 교전 781 |

- 출발 값의 어깨 회전은 R2가 큰 베기 0.45였다(팔이 얼굴 앞). 고친 값으로 0.002.
- 멀리(×0.55)에서 읽히는지는 견본 `far-read`를 눈으로 보았다(값은 교전과 같은 꼴).

## 따로 그린 팔 (결정 237·241)

- 정한 법: 어깨 회전으로 먼저 세워 보고, 사용자가 A3에서 고른 것만 그린다. 고른 것: **큰 베기의 예비 동작(든 팔)**, **찌르기의 타격(나를 향해 뻗은 팔)**.
- 기준 그림: `basis/bartolo-arms.png`(손질 값은 `basis/README.md`). 파츠는 시트 위에 **세로로** 서 있고 기울기는 견본이 `arm_deg`로 준다. 두 파츠 모두 주먹과 칼이 그림에 들어 있다. 칼은 상태 색을 받지 않게 따로 자른다.
- 사용자가 고친 것(승인 B, 다섯 장): 주먹을 024의 주먹처럼, 든 팔은 칼을 쥐고 칼이 **팔과 한 줄**(자루에서 꺾이면 부자연스럽다), 앞으로 뻗은 팔은 넓은 타원 날밑과 나를 향해 **아래로 가늘어지는 칼날**, **아래를 향한 주먹은 손가락 마디가 왼쪽**(비교 그림에서 "나"). 그림 도구가 마지막 것을 두 번 못 해 화소로 뒤집었다.
- 판정(A1e, 손질본 A1f): 바탕 `#D5D5D4`·`borderSpreadR` 2·덩이 2, K1 77,46,23 PASS, K2 4.2단위·K2′ PASS, K3′ PASS, 칠 Y 0.52·그림자 0.41, 소매 폭 024의 0.91배.
- 계획 027에서 사용자가 "손가락이 3개뿐인게 이상해. 같은 구도 같은 실루엣에서 손가락만 4개로"라고 해, A1f를 바탕으로 두 주먹의 손가락만 4개로 고쳤다(A1g, P-KEEP-SHEET). 기준 그림은 A1g다. 판정: 바탕 `#D6D5D5`·`borderSpreadR` 2·덩이 2, K1 80,47,24 PASS, K2 3.7단위·K2′ PASS, K3′ PASS, 칠 Y 0.53·그림자 0.41.
- 넣는 그림: 처음은 우리 파츠 시트 + 견본 `arm-guide`에서 1536×1024로 구운 자세 안내도(파츠 `#9A9A9A`, 칼 `#6E6E6E`, 바탕 `#D8D8D8`), 고칠 때는 직전 시트 하나(P-KEEP-SHEET).
- 블록: 아래 "계획 026의 블록". 차례는 024의 P1과 같다(지시 → Image·Subject → Pose and layout → Style → Colors → Background).

## 4단계로 넘기는 것 (제안. 이 계획은 코드와 데이터를 고치지 않았다)

- `AttackData`의 포즈 필드: `pose_arm_offset`·`pose_sword_rotation`을 국면마다의 값으로. 이름 보기(ASCII): `tell_arm_deg`, `tell_sword_deg`, `hold_arm_deg`, `strike_arm_deg`, `strike_sword_deg`, `recover_arm_deg`, `tell_lean_deg`, `tell_shoulder`, `tell_arm_art`, `strike_arm_art`. 지금 코드의 `STRIKE_OFFSET`·`STRIKE_ROTATION`은 공격의 데이터로 옮긴다.
- `OpponentData`: `idle_arm_deg`, `idle_sword_deg`, `stagger_*`, `complacent_sword_deg`, 곡선의 값(`tell_in`, `swing`의 비율과 여유, `creep_deg`, 돌아감 시간). 지금의 상수(`REST_SWORD_ROTATION`, `STAGGER_*`, `COMPLACENT_SWORD_ROTATION`, `DODGE_*`)를 옮긴다.
- `opponent_view.gd`: `_arm.rotation`을 쓰고 예비 동작의 진행에 곡선을 건다. 따로 그린 팔은 Arm 아래에 그림을 두고 국면의 경계에서 보이기를 바꾼다(노드 이름과 관절은 결정 12 그대로). 칼이 든 팔 그림에서는 Hand와 Sword를 감춘다.
- **`hold` 곡선의 휘두름과 패리 창의 겹침을 플레이로 확인한다**: 휘두름(0.10~0.15초)은 패리 창(0.18초) 안에서 시작한다. 플레이(사용자 또는 playtester)로 볼 것은 둘이다. 하나는 플레이어가 고리가 아니라 휘두름을 보고 누르는지, 다른 하나는 큰 베기의 패리 성공률이 `game` 곡선보다 떨어지는지다. 그러면 `game` 곡선으로 돌리거나 `MOTION`의 값(`swing`, `tell_in`)을 바꾼다. 곡선은 데이터의 값이라 코드 없이 되돌린다.
- 지금 게임의 두 문제가 고른 포즈에서 준 정도: 큰 베기의 얼굴 가림 0.317 → 0.002, 상태 글자 상자의 칼은 둘 다 0(예비 동작 25%).
- 남은 것: 칼 팔이 오른쪽인 상대의 거울, 밀착의 포즈(지금은 크기만), 내 손과 칼의 움직임, 따로 그린 팔에서 대기로 돌아갈 때(0.2초) 그림이 국면 끝에서 바뀌는 것, 든 팔(1번)의 주먹 그림자가 왼쪽인 것(명세는 오른쪽. 손가락 방향을 뒤집으며 따라 옮겨졌다).

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

# 계획 024의 블록 (파츠 시트, 무대 둘, 비토리오. 결정 212·215)


영어, ASCII만, 큰따옴표 없이(결정 187). 있는 블록(S-FIG2, C-FIG2, S-ST3, C-ST2, P-KEEP·S-KEEP, 클라라의 줄)은 고치지 않고 아래만 더한다.

## 지시 블록 (두 장)

```
Task: call your image generation tool exactly once to create exactly one image. You may use the code tool only to make that one call. Pass both attached images to the image generation tool as referenced images by their paths: {WORKDIR}\in-1.png and {WORKDIR}\in-2.png. Give the image generation tool the text from the line that starts with Image: to the end of this message, word for word, as its prompt. Do not run shell commands. Do not read, create, change or delete any file. Do not use a browser, web search, computer use, apps or any other tool. Do not retry. When the image is done, reply with one line: done.
```

- 한 장을 넣는 그림(S1·S2·V1과 고치기)은 `023-R1i-bartolo-front.txt`의 지시 블록 그대로다.

## P1의 `Image:`·`Subject:`·`Background:`

```
Image: Landscape, 1536x1024 pixels. One sheet of separate body parts of one character for cutout animation in a 2D duel game.

Subject: Bartolo, a vain and quarrelsome gentleman duelist from a Renaissance-era Italian town, the same character as in the first referenced image. Doublet with buttons and a small plain collar, breeches, stockings, simple shoes, a small low-crowned hat with one long feather. A rapier.
```

```
Background: one plain flat light grey color, about #D8D8D8, everywhere around the parts. No floor, no cast shadow, no scenery, no frame, no text, no letters, no signature, no watermark.
```

## P-PARTS (파츠 시트의 구도)

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

## S-PARTS (S-FIG2에서 바꾸는 세 줄)

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

## P-KEEP-SHEET (파츠 시트를 고칠 때. 넣는 그림은 직전 시트 하나)

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

## S-ST3에서 곳마다 바꾸는 구절 (S1·S2)

S-ST3 첫째 항목의 `Add only a little detail on the houses and objects near the left and right edges, such as window frames, shutter boards, the shop sign, a row of roof tiles and barrel hoops.`를 아래로 바꾼다. 나머지는 그대로다.

- 안뜰: `Add only a little detail on the things near the left and right edges, such as the stones and the wooden frame of the well, the bucket and its rope, the planks, iron bands and studs of the gate and a few simple leaf shapes on the tree.`
- 광장: `Add only a little detail on the things near the left and right edges, such as the rim and the column of the fountain, the rolled awning and the posts of the stall and the boards of the crates. The distant rooftops and the bell tower stay plain flat dark shapes.`

C-ST2의 `Edge walls parchment E9D8B4, beams wood brown 7A5232, shutters and barrels dark wood 4A3A2C.` 자리:

- 안뜰: `Light walls near the edges parchment E9D8B4, the gate and the well frame dark wood 4A3A2C, iron bands 2E2620, tree leaves muted dark green 46503A.`
- 광장: `Light stone near the edges parchment E9D8B4, the stall and the crates dark wood 4A3A2C, the distant rooftops and the bell tower very dark warm grey 2E2A28.`

`Composition:`의 첫 항목은 R2와 같이 `- Follow the attached layout sketch for the composition only.`다.

## 비토리오의 줄 (V1. 클라라의 줄을 옮겼다)

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

# 계획 026의 블록 (따로 그린 팔. 결정 237·241)

영어, ASCII만, 큰따옴표 없이. 있는 블록은 고치지 않고 아래만 더한다. 처음 그릴 때의 차례: 지시 블록(두 장) → 아래 `Image:`·`Subject:` → P-ARMS → S-PARTS의 머리 줄과 첫째 항목 → S-ARMS → S-FIG2의 넷째~일곱째 항목 → C-FIG2 → P1의 `Background:`. 넣는 그림은 우리 파츠 시트(`basis/bartolo-parts.png`)와 견본 `arm-guide`에서 1536×1024로 구운 자세 안내도다.

## `Image:`·`Subject:` (팔 시트)

```
Image: Landscape, 1536x1024 pixels. One sheet of separate sword arm parts of one character for cutout animation in a 2D duel game.

Subject: Bartolo, the same character as in the first referenced image. Only his sword arm, his sword hand and his rapier, in a few different poses.
```

## P-ARMS (팔 시트의 구도. A1c의 것. 파츠 줄은 `- Part N:`으로 고른 동작마다 쓴다)

```
Pose and layout:
- The first referenced image is our own parts sheet of this character and it is the character reference: draw exactly the same sleeve, the same fist and the same rapier, with the same drawing style, the same shapes, the same colors and the same line weight.
- The second referenced image is our own pose sketch. It shows how many parts there are, where each part goes on the sheet and the pose of each part. Follow its poses and its places. Do not copy its flat grey shapes: every part looks like the first image.
- Each arm is one straight shape from the shoulder to the wrist, with no bend at the elbow, as in the first image. Every part stands straight up and down on the sheet, not tilted, exactly as in the second image.
- Part 1: the sword arm raised straight up and holding the rapier overhead: the shoulder end at the bottom, the cuff and the fist at the top. The fist wraps around the rapier grip: the grip passes through the fist, the guard sits just above the fist and the small round pommel shows just below the fist. The knuckles face the viewer and the short finger lines run across the grip. The blade goes up out of the guard and leans back over the shoulder, as in the second image. The rapier is part of this part.
- Part 2: the sword arm thrusting the rapier toward the viewer and slightly down, strongly foreshortened: a short upright sleeve with the shoulder end at the top, the cuff, then a large fist close to the viewer, seen from the knuckle side and gripping the rapier grip. In front of the fist the guard is a wide oval cup, and the blade comes out of the guard toward the viewer and down, drawn short and tapering, with the point at the bottom, as in the second image.
- Every fist is the same closed fist as in the first image: one rounded block with a few short finger lines on it, not a stack of separate long fingers.
- Each part is drawn complete. Clear empty space between all parts. No part touches or overlaps another. No body, no head, no labels, no numbers, no guide lines, no dots. Nothing is cropped.
```

- 처음(A1a)의 파츠 줄은 짧았다(`the fist seen from the front as if gripping a sword held overhead` 등). 사용자가 고친 것을 따라 A1b에서 주먹 줄(`Every fist is ...`)과 칼을 쥔 든 팔, A1c에서 폼멜·타원 날밑·가늘어지는 칼날을 더했다. 든 팔의 칼이 기우는 구절(`leans back over the shoulder`)은 A1d에서 "팔과 한 줄"로 고쳤다(아래 고치기).

## S-ARMS (S-FIG2의 셋째 항목 자리. 둘째 항목은 두지 않는다)

```
- Keep exactly the amount of detail of the first referenced image: the same cuff line, the same fingers on the fist and the same guard and grip on the rapier. Nothing else is added. No puffy sleeves, no extra wrinkles.
```

## 팔 시트를 고칠 때 (A1d·A1e. 넣는 그림은 직전 시트 하나)

- P-KEEP-SHEET 그대로, 지시 블록은 한 장의 것, `Subject:`의 `first referenced image`를 `attached image`로, 화풍은 P-KEEP-SHEET 아래의 규칙대로 쓴다. 쓴 `Change:` 줄 둘(사용자가 짚은 것을 한 줄에 둘씩 넣었다. "한 가지"보다 많다):

```
Change: in part 1 on the left, the rapier is held straight in line with the raised arm, so the grip, the guard and the blade form one straight line that goes straight up out of the fist with no bend or angle at the grip; in part 2 on the right, only the fist is turned the other way, so the fingers start at the right side of the fist and the finger lines run toward the left, while the shadow of the fist stays on its right side.
Change: in both parts, turn only the fist the other way, as if mirrored from left to right, so the finger lines on each fist point the opposite way from now; the rapier, the sleeves, the cuffs and everything else stay exactly as they are, and the shadow of each fist stays on its right side.
```

- A1e의 줄은 1번 주먹만 뒤집고 2번은 그대로 두었다. 좌우를 뒤집는 고치기는 그림 도구가 잘 따르지 않는다: 주먹 하나를 뒤집을 일이면 화소로 뒤집는다(결정 241).

# 계획 032의 블록 (내 손. 결정 301·307)

**H1a(빈 주먹)에만 썼다.** 확정 그림 H1h의 줄은 아래 "계획 032 H1h의 줄"이다(계획 032 v4 결정 307).

내 손(결투 화면 아래의 장갑 주먹과 소매)을 그린다. 넣는 그림은 둘: 1 = `basis/bartolo-arms2.png`(그리는 결), 2 = `generated/in/032-in-hand.png`(배치·꼴, 견본 `samples/032-player-hand.html`). 지시 블록은 "지시 블록 (두 장)". 블록의 차례는 `Task:` → `Image:` → `Subject:` → `Pose and layout:` → `Style (` → `Colors:` → `Background:`이고, `Style (`의 다섯째~일곱째 항목(칠, 그림자, Do not add)은 S-FIG2 그대로다(둘째 항목은 두지 않는다). 칼·날·무기·결투·싸움의 말은 쓰지 않는다(결정 289·307).

## 계획 032의 `Image:`·`Subject:`

```
Image: Portrait, 1024x1536 pixels. One illustration of a single gloved hand for a 2D game, seen from the player's own point of view.

Subject: the viewer's own gloved hand, seen from behind and slightly from above, as if the viewer looks down at their own closed fist held in front of the body. A brown leather fencing glove making a closed fist, a parchment colored cuff at the wrist, and a long plain olive green sleeve that widens toward its lower end.
```

## P-HAND

```
Pose and layout:
- The first referenced image is our own drawing of a different character. Use it only for the drawing style: how a closed fist, a cuff and a sleeve are drawn, the shapes, the line weight and the colors. Do not draw that character, his clothes or anything he holds.
- The second referenced image is our own layout sketch of this hand. Follow its shape, its place on the image and its size: the fist near the top, the cuff below it, and the sleeve going down and widening to its straight lower edge near the bottom of the image. Do not copy its flat look: the hand is drawn like the first image.
- One single piece, upright and centered: the closed fist seen from behind with the knuckles at the top and two short knuckle lines across the back of the fist, the cuff, and the long sleeve below it, as in the second image.
- The hand holds nothing. The fist is empty and closed.
- The piece is drawn complete. Empty space around it. No other parts, no labels, no numbers, no guide lines, no dots. Nothing is cropped.
```

## S-HAND (S-FIG2에서 바꾸는 넷. 머리 줄, 첫째·셋째·넷째 항목)

```
Style (draw a new, original illustration in the style of the first referenced image, as described here):
- A finished cartoon illustration of one gloved hand for a game, drawn with care, in the drawing style of the first referenced image: soft, simple, rounded-geometric shapes with straight sides and rounded corners. Simple and flat: a clean cartoon, not realistic and not painterly.
```

```
- Keep it as simple as the second referenced image: the same small number of shapes, two short knuckle lines on the back of the fist, a plain cuff and a plain sleeve. Draw the fist the way the first referenced image draws a fist, but do not copy the person, the clothes or anything held in the first image. No extra seams, folds, stitches or wrinkles.
```

```
- Outlines: very dark warm brown, hex 3B2A1E. One even, bold line weight on every outer contour, about 12 pixels thick in a 1024 pixel wide image, smooth clean edges, round ends. No tapering, no wobble, no rough or broken edges. Inner lines are the same color and about half as thick.
```

- 넷째 항목은 S-FIG2 넷째 항목의 글에서 숫자만 바꿨다(8 → 12: 2.4화소/단위에서 5.0단위. 결정 304, 바이블 4절).

## C-HAND

```
Colors:
- Main fills and their shadow tones: warm leather brown 7A5232 with shadow 634228 for the glove, parchment E9D8B4 for the cuff, dull olive green 5E6648 with a slightly darker shadow of the same hue for the sleeve.
- Avoid bright saturated yellow, orange, red, blue, purple or green, and pure white. Large areas are greyish and low in saturation.
```

## B-HAND

```
Background: one plain flat light grey color, about #D8D8D8, everywhere around the hand. No floor, no cast shadow, no scenery, no frame, no text, no letters, no signature, no watermark.
```

# 계획 032 H1h의 줄 (확정 그림. 결정 307)

## 계획 032 H1h의 줄 (확정 그림)

프롬프트 파일 `docs/style/prompts/032-H1h-player-hand.txt`가 정본이고 여기는 그 `Image:`부터 끝까지를 글자 그대로 옮긴 것이다(결정 195의 차례와 반대, 결정 307). 지시 블록은 세 장의 꼴(넣는 그림: 1 = `generated/032-H1c-player-hand.png` 바탕, 2 = `basis/bartolo-front.png`, 3 = `basis/bartolo-arms2.png` 화풍). 거기까지의 길: H1a → 사진 `reference/레이피어 파지.png`(결정 186의 예외, 사용자 지시) → H1b → H1c → H1h. 자루와 둥근 끝의 색(4A3A2C, 8A8680)은 `Colors:` 줄에 있고 신호가 아니다(결정 311).

```nImage: to the end of this message, word for word, as its prompt. Do not run shell commands. Do not read, create, change or delete any file. Do not use a browser, web search, computer use, apps or any other tool. Do not retry. When the image is done, reply with one line: done.

Image: Portrait, 1024x1536 pixels. One illustration of a single gloved hand holding a short handle, for a 2D game, seen from the player's own point of view.

Subject: the viewer's own right hand in a leather fencing glove, closed around a short upright handle, seen from behind. A parchment colored cuff at the wrist and a long plain olive green sleeve going down and to the right.

Pose and layout:
- The first referenced image is our own drawing of this hand and it is the base. Keep it: the same grip, the same angle of the hand and the wrist, the same size and place on the image, the short handle with the small round knob below the fist, and the sleeve going down and to the right to a straight lower edge near the bottom of the image. The sleeve keeps exactly the same width and outline as in the first image.
- The fist shows exactly four fingers, stacked one above another on the left side of the handle.
- The second and third referenced images are our own drawings of a different character, the main look of this game. Redraw the hand so it looks like it belongs to the same game as that character: the same kind of shapes, outlines, fills and shadows. Do not draw that character, his clothes or anything he holds.
- Change only the drawing style, as described in the Style lines below. The colors stay as in the first image.
- No guard, no rings, no blade, nothing above the flat end of the handle.
- The piece is drawn complete. Empty space around it. No other parts, no labels, no numbers, no guide lines, no dots. Nothing is cropped.

Style (draw a new, original illustration in the style of the second and third referenced images, as described here):
- A finished cartoon illustration of one gloved hand for a game, drawn with care, in the drawing style of the second and third referenced images: soft, simple, rounded-geometric shapes with straight sides and rounded corners. Simple and flat: a clean cartoon, not realistic and not painterly.
- Keep it as simple as the hands in the second and third images: the same small number of shapes. No extra seams, folds, stitches or wrinkles.
- Outlines: very dark warm brown, hex 3B2A1E. One even, bold line weight on every outer contour, the same line weight as the second image, smooth clean edges, round ends. No tapering, no wobble, no rough or broken edges. Inner lines are the same color and about half as thick.
- Fills: flat solid colors, muted and faded.
- Shadows: exactly one shadow tone per color, a slightly darker version of the same color and still clearly lighter than the outlines. Each shadow is one simple flat shape with a hard edge on the right side of the form, as if the light comes from the upper left. Shadows have no outline.
- Do not add: hatching, cross-hatching, engraving or etching lines, brush or ink texture, paper texture on the figure, gradients, soft or blurred shadow edges, highlights or shine, sweat drops, skin texture, fabric patterns, lace, embroidery.

Colors:
- Main fills and their shadow tones: warm leather brown 7A5232 with shadow 634228 for the glove, dark wood 4A3A2C for the wrapped handle, muted iron grey 8A8680 for the knob, parchment E9D8B4 for the cuff, dull olive green 5E6648 with a slightly darker shadow of the same hue for the sleeve.
- Avoid bright saturated yellow, orange, red, blue, purple or green, and pure white. Large areas are greyish and low in saturation.

Background: one plain flat light grey color, about #D8D8D8, everywhere around the hand. No floor, no cast shadow, no scenery, no frame, no text, no letters, no signature, no watermark.
```n
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

## 계획 032b의 블록 (내 칼)

프롬프트 `docs/style/prompts/032b-W1a-player-sword.txt`의 `Image:`부터 끝까지가 이 블록이다(결정 195의 차례: 명세가 먼저, 프롬프트가 옮겨 적는다). 넣는 그림 셋: 스케치 `generated/in/032b-in-sword.png`, `basis/player-hand.png`, `basis/bartolo-arms2.png`. 참고 사진은 넣지 않는다(사용자 답). 칠은 강철 `CFC8BA`, 그림자 `B3AB9C`(둘 다 Y 0.30 위라 상태 색 셰이더가 칠로 본다).

```
Image: Portrait, 1024x1536 pixels. One illustration of a single fencing rapier without its handle, for a 2D game, standing upright.

Subject: one fencing rapier for a stage duel, drawn alone, with no hand. A straight, slim blade that narrows evenly to a sharp point. At its base a low, round, dome shaped cup guard, and right below the cup a straight crossbar with rounded ends.

Pose and layout:
- The first referenced image is our own sketch of this rapier and it is the base. Keep it: the same outline, the same proportions, the same size and place on the image. The rapier stands perfectly upright in the middle of the image with the point at the top. The left half and the right half mirror each other.
- The blade is about 0.85 of the image height. The cup guard is a low dome, clearly wider than the blade and much lower than it is wide. The crossbar is a little wider than the cup.
- The lower edge of the crossbar is one straight horizontal line and it is the lowest thing in the drawing. Do not draw a handle, a grip, a knob or a hand below it. Nothing is drawn below the crossbar.
- The second and third referenced images are our own drawings from the same game: a gloved hand and a character holding a rapier. Redraw the rapier so it looks like it belongs to the same game: the same kind of shapes, outlines, fills and shadows. Do not draw that hand, that character, his clothes or his sleeves.
- The piece is drawn complete. Empty space around it. No other parts, no labels, no numbers, no guide lines, no dots. Nothing is cropped.

Style (draw a new, original illustration in the style of the second and third referenced images, as described here):
- A finished cartoon illustration of one rapier for a game, drawn with care, in the drawing style of the second and third referenced images: soft, simple, rounded-geometric shapes with straight sides and rounded corners. Simple and flat: a clean cartoon, not realistic and not painterly.
- Keep it as simple as the first image: the same small number of shapes. No engraving, no rivets, no rings, no extra bars, no ornaments.
- Outlines: very dark warm brown, hex 3B2A1E. One even, bold line weight on every outer contour, the same line weight as the second image, smooth clean edges, round ends. No tapering, no wobble, no rough or broken edges. Inner lines are the same color and about half as thick.
- Fills: flat solid colors, muted and faded.
- Shadows: exactly one shadow tone per color, a slightly darker version of the same color and still clearly lighter than the outlines. Each shadow is one simple flat shape with a hard edge on the right side of the form, as if the light comes from the upper left. Shadows have no outline.
- Do not add: hatching, cross-hatching, engraving or etching lines, brush or ink texture, paper texture, gradients, soft or blurred shadow edges, highlights or shine, sparkles, glow, blood.

Colors:
- Main fill and its shadow tone: pale warm steel grey CFC8BA with shadow B3AB9C for the blade, the cup guard and the crossbar. The shadow stays light, far lighter than the outlines.
- Avoid bright saturated yellow, orange, red, blue, purple or green, and pure white. The whole rapier is greyish and low in saturation.

Background: one plain flat light grey color, about #D8D8D8, everywhere around the rapier. No floor, no cast shadow, no scenery, no frame, no text, no letters, no signature, no watermark.
```
