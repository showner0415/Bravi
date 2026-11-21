# 계획 022: 화풍 명세와 다시 만들기 — SVG 화풍을 말로 옮겨 Codex로 일곱 장을 다시 그린다

- 버전: v2 (1회차 검토 대응: D1·D2, T1~T3, 비차단 제안 둘. 사용자 답 Q1 "가". 끝의 "수정 기록")
- 개발 단계: CLAUDE.md 9장 **3단계(스타일 바이블)의 셋째 계획**. 게임 코드·씬·데이터·테스트는 고치지 않는다(교체는 4단계)
- 근거:
  - 021 견본에 대한 사용자 답(`docs/DECISIONS.md` 끝 "계획 021 견본에 대한 사용자 답", 2026-11-21):
    - 원문: "내가 원하는 이미지의 느낌은 svg로 만든 이미지 스타일에 훨씬 가까워. 따라서 svg로 만든 이미지의 스타일을 분석하고, 그 스타일로 gpt가 전부 다시 만들 수 있게해줘. 추가로 아까 말한 잉크같은 스타일의 B안이라고 했지만, 깔끔한 A안도 좋은거 같아. 그래서 A,B 안을 섞어서 선은 깔끔하게 칠은 바랜색으로 해줘."
    - 이어서 받은 답: 선 색은 짙은 고동색 `#3B2A1E`을 깔끔하게(고른 굵기, 매끄러운 가장자리, B의 `inkline` 필터는 쓰지 않는다). 새 그림의 장 수 상한 **10**. 바르톨로는 전신과 파츠 시트 **둘 다**. 021은 커밋했다(`9909fb9`).
  - 021에서 메인이 본 차이(보고서 2번 눈 확인 7·9, 4번의 4):
    - 생성 무대는 인물보다 세밀한 옛 판화(빗금·벽 결·벽돌)였다. SVG 무대는 큰 평면이고 가장자리에만 단순한 빗금 띠가 있다. 생성 무대의 가운데 L 평균 0.03~0.05, SVG는 0.07~0.08.
    - 생성 인물(G1~G4)은 프롬프트의 B 말("line weight varies … tapered ends, slightly rough edges")을 따라 거친 잉크 선, 부드러운 그림자 경계, 얼굴의 홍조·땀방울 같은 덧붙임이 있었다.
    - 그래도 생성 그림은 구도·자세·비례를 붙인 스케치대로 따랐다(G1: 칼 팔·칼의 각·손 높이·머리 크기·깃털 방향).
  - 분석할 SVG(planner가 읽은 것):
    - `docs/style/samples/021-detail.html`의 `:root`(팔레트), `.line`·`.fill` 규칙, `inkline` 필터(`feOffset` 1.4·1.7을 겹치고 `feDisplacementMap` 2.4로 흔든다), `P`(파츠의 꼴), `FACES`(표정 여섯), `PART`, `stageAlley()`·`stones()`·`hatchRect()`·`shutter()`, `clientClara()`·`clientVittorio()`, `counterScene()`.
    - `docs/style/samples/020-bridge.html`의 `.bridge-a`(`--line: #1E1A17; --lw: 6`, 필터 없음, 맑은 칠)와 `.bridge-b`(`--line: #3B2A1E; --lw: 4.6`, `inkline`, 바랜 칠).
  - 021이 정한 절차(그대로 쓴다): `docs/style/GENERATION.md` "절차"(결정 184·192). 021 실행 중에 더한 `--disable plugins/apps/computer_use/browser_use/browser_use_external`과 세션 기록 Grep의 꼴(도구는 정의의 `"name"`, 부른 도구는 호출 항목 줄)도 절차다. 파츠로 나누기와 비례 맞추기는 같은 파일 "파츠로 나누기와 비례 맞추기"(결정 188).
  - 지키는 것: 결정 12(파츠 이름·계층·관절), 결정 179(참고 스크린샷을 넣지 않음, 이름 쓰지 않음), 결정 181(신호색 코드 값, 신호 구역 HSV S ≥ 55%이면서 V ≥ 85% 밖, 상대 큰 면 S ≤ 50%, 상태 색은 칠에만 80%), 결정 182의 짙은 무대, 상대 머리 104, 결정 190(야외 무대와 극장 금지 목록), 결정 189(생성 그림은 로컬만).
  - 넘지 않는 선:
    - 메인은 Godot을 어떤 방식으로도 실행하지 않는다. Edge headless와 Codex CLI는 이 규칙 밖이다. 실행 확인은 사용자가 요청할 때 playtester가 한다.
    - 고치지 않는 것: `scripts/`, `scenes/`, `data/`, `tests/`, `project.godot`, `docs/BACKLOG.md`, 2단계의 보류 값(`docs/HANDOFF.md` 3번), `docs/style/samples/020-bridge.html`·`021-detail.html`, 021의 프롬프트 일곱, 사용자의 파일(`.claude/agents/playtester.md`, `tools/`, `docs/plans/013-playtester.md`), 사용자의 Codex(`~/.codex/config.toml`, `auth.json`, 로그인, 기능, 샌드박스, `generated_images/`의 파일).
- 번호: 022. 결정 번호는 193부터다(계획 021 절이 192로 끝난다. 그 뒤의 "사용자 답" 줄들에는 번호가 없다).

## 3단계를 나누는 법 (결정 193. 결정 183을 고친다)

| 계획 | 하는 것 | 끝나는 때 |
|---|---|---|
| 020 (끝) | 다리 견본 셋 | 답: B, 짙은 무대, 지금 크기, 야외 |
| 021 (끝) | 야외 무대 셋, 바르톨로 파츠, 의뢰인 둘(SVG와 생성), 생성 절차 | 답: SVG 화풍, 다리는 A·B 섞기, 그 화풍으로 다시 만든다 |
| **022 (이 계획)** | SVG 화풍의 명세(`docs/style/STYLE_SPEC.md`). 섞은 다리의 견본(`022-mix.html`). 명세로 쓴 프롬프트와 섞은 스케치로 일곱 장을 다시 만든다. 화풍 판정. 021 생성·022 생성·SVG를 나란히 | 사용자가 **기준 이미지**(무대·상대·의뢰인)와 4단계에서 **그림을 만드는 길**을 고른다 |
| 023 (예정) | 고른 그림을 `docs/style/basis/`로 올리기. 팔레트 확정(고른 그림과 명세에서). 한글 글꼴 후보(파일과 라이선스). UI 패널·버튼. 1280×720 크기 기준 | 사용자가 글꼴·UI를 고른다 |
| 024 (예정) | `docs/STYLE_BIBLE.md`, `assets/MANIFEST.md`의 꼴, CLAUDE.md 7장 갱신 | 3단계 완료 기준 충족 → 사용자 판정 |

- 까닭: 021의 답이 "다시 만들기"라는 일을 하나 더했다. 022가 원래 맡던 일(올리기·팔레트 확정·글꼴·UI·크기 기준)은 모두 **고른 기준 이미지**를 입력으로 쓰는데, 그 고름이 022의 끝으로 밀렸다. 그래서 그 일을 023으로 한 칸 민다. 022에 합치면 실행 중의 승인(B·C)에 사용자의 고름이 하나 더 끼어 한 번에 끝내기 어렵다.
- 023·024는 023의 답으로 다시 정하고 합칠 수 있다(글꼴·UI 답이 빨리 나오면 STYLE_BIBLE까지 한 계획으로).

## 목표와 범위

**확인할 결과**. 메인은 파일 읽기·Grep·Glob·git·손 계산, 구운 PNG와 생성 그림의 Read, `System.Drawing`의 화소 재기로 확인한다. 고르는 것은 사용자다.

1. **화풍 명세**가 `docs/style/STYLE_SPEC.md`에 있다. 선·칠·그림자·얼굴·몸·무대·의뢰인·팔레트의 값과, 021 생성에서 나와 "하지 말 것"이 된 목록, 프롬프트에 그대로 옮기는 영어 블록이 있다. 024의 STYLE_BIBLE 4·6·8·13번이 이 파일을 입력으로 쓴다.
2. **섞은 다리의 견본** `docs/style/samples/022-mix.html`에서 SVG 바르톨로·무대 셋·의뢰인 둘이 깔끔한 고동 선(고른 굵기, 필터 없음)과 B의 바랜 칠로 그려져 있다. 같은 바르톨로의 A·B·섞기 선을 나란히 볼 수 있다.
3. **Codex로 다시 만든 일곱 장**(바르톨로 전신·파츠 시트, 무대 셋, 의뢰인 둘)이 021의 절차·막는 장치·모델(`gpt-6.2-sol`·`high`)로, 상한 10과 사용자가 승인한 장 수 안에서 돌았다. 참고 스크린샷은 들어가지 않았고 저장소와 사용자의 Codex 설정(`config.toml` 해시)이 그대로다.
4. 새 그림마다 **화풍 판정**(굳은 확인 K1~K7, 021의 H1~H8, 부드러운 확인)의 결과가 숫자와 함께 `GENERATION.md`에 있다. 재는 확인은 021의 생성 그림으로 먼저 기준을 맞춰 "021 그림은 걸리고 섞은 SVG는 통과하는지"가 적혀 있다.
5. 새 바르톨로(전신·파츠 시트)가 021의 방법으로 파츠로 나뉘고, 상태 넷·큰 베기·멀리에 신호가 얹히고(칠에만), 머리 104·팔 105로 맞춰져 있다. 새 무대 셋 위에 같은 장면이 있다. 새 의뢰인 둘이 카운터에 있다.
6. **SVG(섞기) · 021 생성 · 022 생성**을 바르톨로·무대·의뢰인마다 한 화면에서 견줄 수 있다.
7. 끝에 사용자가 기준 이미지와 그림을 만드는 길을 고를 수 있다(보고서 4번).

**범위 밖**: 고른 그림을 저장소에 올리기·팔레트 확정·글꼴·UI·1280×720 크기 기준(023), `docs/STYLE_BIBLE.md`·`MANIFEST.md`(024), `assets/`, 카운터 배경의 생성(SVG 그대로), 상대 둘째, 명세 글만으로(스케치 없이) 만드는 시험(위험 3).

## SVG 화풍의 분석 (결정 194·195. `STYLE_SPEC.md`의 뼈대)

planner가 021·020 견본의 코드를 읽고 정리한 것이다. 메인은 이 표를 `STYLE_SPEC.md`로 옮기고, 색마다 HSV와 Y(sRGB 값의 0.2126R + 0.7152G + 0.0722B)를 셈해 더한다. 단위는 상대의 파츠 단위(목~골반 = 200)다. 화면 px은 교전 ×0.85, 멀리 ×0.55다.

### 다리 섞기 (결정 194)

| | A (020) | B (020·021) | **섞기 (022)** |
|---|---|---|---|
| 선 색 | `#1E1A17` | `#3B2A1E` | **`#3B2A1E`** (사용자 답) |
| 바깥 선 `--lw` | 6 | 4.6 + `inkline`(오른쪽 아래로 1.4·1.7 겹쳐 보이는 굵기는 약 6, 가장자리 흔들림 2.4) | **5.2** |
| 안 선(`.thin`, ×0.55) · 눈썹(`.thick`, ×1.35) | 3.3 · 8.1 | 2.5 · 6.2 | **2.9 · 7.0** |
| 필터 | 없음 | `inkline` | **없음** (사용자 답) |
| 칠·그림자 | 맑은 색(`#4A6F94` 등) | 바랜 색(`#5C6F7E` 등) | **B 그대로** |

- 5.2의 까닭(planner의 임시 결정, 되돌리기 쉬움: 변수 하나): B에서 필터를 빼면 겹침이 사라져 선이 4.6으로 가늘어 보인다. A의 6은 짙은 선과 함께 무거웠다. 그 사이의 5.2로 B에서 보던 무게를 남긴다. 화면에서는 교전 바깥 4.4px·안 2.5px, 멀리 2.9px·1.6px이다(023의 크기 기준 자료).
- 끝과 꺾임은 둥글다(`round`). 굵기는 한 선 안에서 변하지 않는다.

### 선

- **바깥 윤곽**: 파츠마다 닫힌 꼴 하나를 5.2로 두른다. 몸통·바지·스타킹·신·소매·커프·주먹·얼굴·귀·머리털·모자·칼 모두 같은 굵기다. 멀고 가까움이나 쪽(빛)에 따라 굵기를 바꾸지 않는다.
- **안 선**: 0.55배(2.9)이고 아주 적다. 몸통의 세로 주름 둘, 바지 주름 둘과 무릎 띠, 목깃의 물결 한 줄, 칼날의 가운데 줄, 코등이의 고리, 주먹의 손가락 셋, 깃털의 축과 결 일곱. 옷의 천 무늬·바느질·잔주름은 없다.
- **잉크 점**: 눈(r 4.6), 단추 다섯(r 3.4)은 선 색으로 채운 점이다.
- **그림자에는 선이 없다**: 그림자 꼴은 칠 층에만 있고 그 경계에 선을 긋지 않는다.
- **무대의 선**: 형태 윤곽만 1.4~4로 긋는다(가까운 집 모서리 4, 처마 3, 덧창·통 2~2.6, 먼 벽 1.6, 돌 1.4). 같은 색 `#3B2A1E`와 그보다 옅은 `#6B5440`(돌·결 한두 줄). 조용한 구역(결정 190, x 433~847·y 62~683)에는 선이 없다.

### 칠과 그림자

- **칠**: 한 면에 한 색, 평평하다(그러데이션·질감·하이라이트 없음). 인물의 칠에는 종이 결도 없다.
- **그림자 한 단계**: 같은 색조로 조금 어둡게(예: 저고리 `#5C6F7E` → `#4A5A67`, 바지 `#6B5440` → `#57442F`, 살 `#EBC49F` → `#C98E66`, 모자 `#A5533F` → `#84422F`).
- **그림자의 꼴과 자리**: 빛은 왼쪽 위다. 그림자는 형태의 **보는 쪽 오른쪽 가장자리를 따라가는 띠나 초승달 하나**다(몸통 x 34~71의 띠, 바지·스타킹의 오른쪽 띠, 소매 오른쪽 띠, 얼굴 오른쪽의 초승달, 모자 꼭대기 오른쪽). 안쪽 경계는 곧거나 완만한 곡선이고 단단하다(흐림 없음). 코는 그림자 색 덩이 하나로 그린다.
- 머리털·수염·구두·허리띠는 선과 같은 `#3B2A1E`로 칠한 덩이다(선과 붙어 하나의 짙은 실루엣이 된다).

### 얼굴과 비례

- **큰 머리**: 머리(목~정수리) 104, 몸(목~발) 370. 머리가 몸의 약 0.28이다. 모자 45, 깃털은 옆으로 눕는다. 의뢰인은 허리 위라 머리가 더 커 보인다(카운터의 220×390 안에 머리 높이 140~155).
- **단순한 얼굴**: 점 눈 둘(r 4.6, 흰자 없음), 짧고 굵은 눈썹 둘(7.0의 짧은 호나 곧은 막대), 입은 짧은 선 하나, 코는 그림자 색 덩이와 윤곽, 귀는 반달, 콧수염·턱수염은 머리털 색 덩이.
- **표정은 눈썹 각·눈 꼴·입 꼴로만** 바뀐다(`FACES`): 거만함(눈썹 평평, 눈은 아래로 휜 반달 선, 입 비스듬한 선), 당황(눈썹 높이 들림, 흰자 원 안의 작은 점 눈, 입은 작은 타원), 어지러움(X 눈, 물결 입), 화남(안으로 내려온 눈썹, 이를 드러낸 네모 입), 집중(한 눈 감음, 곧은 입), 대기(얕은 호 눈썹, 점 눈, 짧은 입).
- 홍조, 땀방울, 눈물, 눈 하이라이트, 속눈썹, 입술 색, 볼의 빗금은 없다.
- **생성에 넣는 스케치의 눈**(v2, D1): `in-front`는 021과 같은 거만한 얼굴(`smug`, 아래로 휜 반달 선 눈)이다. 021 G1과 같은 스케치를 넣어야 "화풍만 바꾼 견줌"이 되므로 바꾸지 않는다. 클라라(`in-client-1`)는 채운 점 눈(r 6), 비토리오(`in-client-2`)는 반쯤 감은 짧은 호 눈이다. 그래서 프롬프트의 눈 말은 "스케치의 눈 꼴대로"이고, K6도 스케치의 눈 꼴로 본다.

### 몸의 꼴

- 모든 덩이가 단순한 기하 꼴이다: 몸통은 어깨가 조금 넓은 둥근 사다리꼴(위 142, 아래 120), 바지는 다리 사이를 판 한 덩이, 스타킹은 곧은 막대 둘, 구두는 쐐기, 소매는 둥근 머리의 곧은 관, 주먹은 모서리가 둥근 상자, 칼은 곧은 막대와 반달 코등이.
- 엄격한 정면이고 칼 팔을 빼면 좌우가 같다. 근육·관절의 해부 표현이 없다.

### 무대

- **큰 평면**: 가운데(x 240~1040)는 짙은 톤 덩이 몇 개(그늘 `#3A3027`, 밤하늘 `#3E4A55`, 땅 `#4E4336`, 벽 `#5E4C39`·`#54473A`·`#4A3F34`)를 맞대어 놓은 것이다. 경계는 색 차이로만 읽힌다. 가운데 L은 0.07~0.08.
- **가장자리만 밝다**: 가까운 집·담은 양피지 `#E9D8B4`이고 종이 결 필터(`paper`, 큰 얼룩과 잔 알갱이)는 이 밝은 면에만 있다. 나무 들보 `#7A5232`, 덧창·통은 짙은 나무 `#4A3A2C`.
- **빗금은 띠로만**: 6px 간격, −35°, 1.1px, 불투명도 0.5~0.7의 평행 빗금을 벽 모서리를 따라가는 폭 40의 띠와 문 안쪽에만 둔다. 교차 빗금은 쓰지 않는다(020 C의 것).
- **돌은 바닥 가장자리 띠에만**: 불규칙한 네모를 1.4 선으로. 벽돌·벽 결·회벽 금·나무결은 없다(덧창의 세로 줄 셋, 통의 테가 전부다).
- **원근은 단순한 사다리꼴**: 물러나는 벽 셋이 차례로 작아진다. 곳은 실루엣(내민 위층과 간판, 우물·나무·대문, 지붕선·종탑)으로 읽힌다.
- 극장 금지(결정 190)와 사람·동물 없음은 그대로다.

### 의뢰인과 카운터

- 의뢰인은 인물 규칙 그대로이고, 성격은 표정과 옷 하나·소품 하나로 읽힌다(클라라: 리본 모자·앞치마·핀 둘, 비토리오: 털깃·금 사슬·돈주머니).
- 카운터는 020 B의 배경 그대로다(양피지 벽과 빗금 들보, 나무 카운터의 물결 결 네 줄, 양피지 패널).

### 하지 말 것 (021 생성에서 나온 것)

| 021에서 본 것 | 어디서 | 명세의 말 |
|---|---|---|
| 굵기가 변하고 끝이 가늘어지는 잉크 선, 거친 가장자리 | 인물 G1~G4 (프롬프트의 B 말을 따랐다) | 고른 굵기, 매끄러운 가장자리, 둥근 끝 |
| 부드러운 그림자 경계, 칠 안의 엷은 그러데이션 | 인물 | 단단한 경계의 한 단계 그림자, 평평한 칠 |
| 얼굴의 홍조, 땀방울 | G3 클라라 등 | 덧붙임 없음 |
| 옛 판화의 빗금·교차 빗금·벽 결·벽돌, 인물보다 세밀한 무대 | 무대 G5 셋 (프롬프트의 "engraving" 말) | 큰 평면, 빗금은 가장자리 띠만, 무대도 인물만큼 단순하게 |
| SVG보다 훨씬 어두운 가운데(L 0.03~0.05) | 무대 G5 | 짙되 검지 않게, 스케치의 톤대로 |

### 프롬프트에 옮기는 영어 블록 (결정 195. `STYLE_SPEC.md` 끝에 원문으로 둔다)

영어, ASCII만, 큰따옴표 없이(결정 187). 이름은 쓰지 않는다(결정 179). 프롬프트 파일은 이 블록을 **글자 그대로** 옮긴다. 고칠 때는 `STYLE_SPEC.md`를 먼저 고치고 프롬프트에 다시 옮긴다.

**S-FIG (인물의 화풍. N1·N2·N6·N7)**

```
Style (the attached sketch is our own drawing and it is the style reference: match its drawing style exactly and redraw it as a clean, finished illustration):
- Clean flat cartoon drawing, like a neat vector illustration. Simple rounded geometric shapes and few details.
- Big head, about one quarter of the height from the neck to the feet. Simple face: eyes exactly as in the sketch (small solid dark dots, or short curved lines for a smug or half-closed look), short thick eyebrows, a small mouth drawn as one short line, a simple nose shape. The expression comes only from the eyebrows, the eyes and the mouth.
- Outlines: very dark warm brown, hex 3B2A1E. One even line weight on every outer contour, smooth clean edges, round ends. No tapering, no wobble, no rough or broken edges. The few inner lines are the same color and about half as thick.
- Fills: flat solid colors, muted and faded, as in the sketch. Hair, beard, belt and shoes are filled with the same very dark brown as the outlines.
- Shadows: exactly one shadow tone per color, a slightly darker version of the same color and still clearly lighter than the outlines. Each shadow is one simple flat shape with a hard edge along the right side of the form, as if the light comes from the upper left. Shadows have no outline.
- Do not add: hatching, cross-hatching, engraving or etching lines, brush or ink texture, paper texture on the figure, gradients, soft or blurred shadow edges, highlights or shine, blush or rosy cheeks, sweat drops, tears, freckles, skin texture, fabric patterns, extra wrinkles or folds.
```

**C-FIG (인물의 색)**. 둘째 줄의 색 목록만 사람마다 `STYLE_SPEC.md`의 팔레트 표에서 바꾼다(N1·N2는 아래 그대로).

```
Colors:
- Use the colors of the sketch. Main fills: dusty grey-blue 5C6F7E for the doublet and the sleeve, wood brown 6B5440 for the breeches, parchment E9D8B4 for the collar, cuffs, stockings and feather, skin EBC49F, faded brick red A5533F for the hat, pale warm grey CFC8BA for the blade and guard.
- Avoid bright saturated yellow, orange, red, blue, purple or green, and pure white. Large areas are greyish and low in saturation.
```

- 그림자 색의 hex는 넣지 않는다: SVG의 바지 그림자 `#57442F`는 Y 약 0.28로 칠 문턱 0.30 아래라, 그대로 따르면 상태 색이 그림자에서 빠진다(H8). 그림자는 "선보다 분명히 밝게"라는 말로만 둔다.

**S-ST (무대의 화풍. N3~N5)**

```
Style (the attached sketch is our own drawing and it is the style reference: match its drawing style exactly and redraw it as a clean, finished illustration):
- Clean flat cartoon drawing with large flat planes of color and few details. Simple shapes and simple perspective, as in the sketch. The background is as simple as the characters that will stand in front of it.
- Outlines: very dark warm brown, hex 3B2A1E, even weight, smooth clean edges. Near things have slightly thicker outlines than far things. The calm middle has no outlines.
- Only the light parchment colored walls near the left and right edges may have a faint even paper grain. A few narrow bands of simple parallel diagonal hatching run only along the edges of those walls and inside door openings, as in the sketch. Paving stones appear only along the bottom edge, drawn as simple irregular shapes.
- The middle is a few deep, muted, dark flat tones as in the sketch: dark, but not black.
- Do not add: an engraving or etching look, cross-hatching, dense linework, brick or stone texture on walls, wood grain, plaster cracks, gradients, haze, light rays, glow.
```

**C-ST (무대의 색)**

```
Colors: use the colors of the sketch. Dark middle tones around 3A3027, 3E4A55, 4E4336 and 5E4C39. Edge walls parchment E9D8B4, beams wood brown 7A5232, shutters and barrels dark wood 4A3A2C. Avoid bright saturated yellow, orange, red, blue, purple or green, and pure white. The central dark area has no bright or saturated color.
```

- 구도 블록과 바탕 블록은 021의 프롬프트 그대로다(파츠로 나눌 정면, 칼 팔의 틈, 손 높이, 깃털 방향 / 무대 가운데 35%와 극장 금지 / 한 색 회색 바탕). 화풍 블록 앞의 "Follow the attached sketch for …" 줄에 "and its drawing style"을 더한다.

## 생성의 틀

### 절차 (결정 200. 021 그대로)

- 명령·띄우고 기다리기·결과 찾기·막는 장치 다섯 겹·전후 대조·세션 기록 Grep·실패 표 F1~F10은 `docs/style/GENERATION.md` "절차"와 계획 021 "생성의 틀"·작업 5 그대로다. 모델·추론은 `-m gpt-6.2-sol -c model_reasoning_effort=high`(결정 192).
- 바뀌는 것은 이름과 자리뿐이다.

  | 무엇 | 022 |
  |---|---|
  | 그림 번호 | N1~N7 (021의 G와 섞이지 않게) |
  | 작업 폴더 | `<scratchpad>\codex\N<n>-<시도>\` |
  | 생성 원본 | `docs/style/generated/022-N<n>-<이름>.png` (로컬만) |
  | 손질본 | `docs/style/generated/cut/022-N<n>-<이름>.png` (로컬만) |
  | 넣은 그림 | `docs/style/generated/in/022-in-<이름>.png` (로컬만. 021의 `in/` 파일은 덮어쓰지 않는다) |
  | 프롬프트 | `docs/style/prompts/022-N<n>-<이름>.txt` (올린다) |

- **더하는 확인 하나** (위험 1): 021에서 에이전트는 우리 프롬프트를 그림 도구에 맞게 다시 써서 넘겼다. 이번에는 화풍 말이 빠지면 안 되므로 지시 블록에 "그림 도구에는 `Image:` 줄부터 끝까지를 글자 그대로 넘긴다"를 더한다(아래 N1 전문). 호출마다 세션 기록의 그림 도구 인자 `prompt`를 Grep해(v2: 사용자 메시지 줄에도 같은 구절이 있으므로 `"type":"custom_tool_call"`(또는 `function_call`)이면서 `tools.image_gen__imagegen(`을 담은 줄만 본다. 021 `run-codex.ps1`의 `$callLines`와 같다), 세 구절 `even line weight`·`hard edge`·`Do not add`(무대는 `even weight`·`large flat planes`·`Do not add`)가 들어 있는지 적는다. 빠졌으면 **F11**: 그 그림은 쓰되 기록하고, 다음 승인 지점에서 알린다(시험이면 승인 B1에서 지시 블록을 고칠지 묻는다).
- 021 실행 뒤 사용자의 `config.toml`이 바뀌었을 수 있다. 작업 3에서 해시를 021의 처음 값(`AA004752…186D`)과 견주고, 다르면 켜진 플러그인 열·MCP를 다시 읽어(읽기만) 끄기 목록을 맞추고 `codex mcp list`로 확인한 뒤 새 해시를 이 계획의 처음 값으로 적는다.

### `-i`에 넣는 것 (결정 197)

- **섞은 견본을 구운 스케치가 구도와 화풍의 기준을 겸한다.** 021의 `in-*`는 B(거친 선)였고 프롬프트도 B의 말이었다. 이번에는 스케치를 섞기로 다시 굽고, 화풍 블록 첫 줄에 "붙인 스케치가 화풍의 기준"이라고 적는다. 우리 그림이라 결정 186 안이다.
- 따로 된 화풍 카드(다른 그림을 한 장 더)는 붙이지 않는다. 021에서 아는 것은 "붙인 그림의 구도·자세는 따랐다"까지이고, 두 장을 붙이면 어느 쪽을 구도로 따를지가 흐려진다. 화풍을 따르는 정도는 시험 N1의 K 확인으로 본다.
- 무대는 021처럼 SVG 무대 자체를 넣는다(HUD·상대·신호 없이). 021 무대가 판화가 된 것은 프롬프트의 "engraving" 말 때문으로 보고, 말을 바꾼다.
- N2는 021의 G2처럼 둘을 넣는다: N1 원본(`in-1`)과 섞은 `in-parts`(`in-2`).

| N | 그림 | 넣는 그림 | 프롬프트 |
|---|---|---|---|
| N1 | 바르톨로 전신 | `022-in-front` | 아래 전문 |
| N2 | 바르톨로 파츠 시트 | N1 원본, `022-in-parts` | 021 G2의 주제·구도 + S-FIG + C-FIG |
| N3 | 무대 뒷골목 | `022-in-stage-alley` | 021 `021-G5-stage-alley.txt`의 주제·구도 + S-ST + C-ST |
| N4 | 무대 안뜰 | `022-in-stage-court` | 같은 꼴(안뜰) |
| N5 | 무대 광장 | `022-in-stage-piazza` | 같은 꼴(광장) |
| N6 | 클라라 | `022-in-client-1` | 021 G3의 주제·구도 + S-FIG(표정 줄은 그 사람) + C-FIG(그 사람의 색) |
| N7 | 비토리오 | `022-in-client-2` | 021 G4의 같은 꼴 |

- 의뢰인의 S-FIG에서 "Hair, beard, belt and shoes …" 문장은 그 사람에게 맞게 바꾼다(클라라는 머리털이 `#7A5232`라 이 문장을 뺀다, 비토리오는 "His cap is filled with the same very dark brown as the outlines."). 표정 줄은 021 G3·G4의 성격 말을 쓰되 땀·홍조 같은 말은 넣지 않는다. 바꾼 줄은 `STYLE_SPEC.md`의 "사람마다 바꾸는 줄"에 둔다.

### N1 전문 (`docs/style/prompts/022-N1-bartolo-front.txt`)

```
Task: call your image generation tool exactly once to create exactly one image. You may use the code tool only to make that one call. Pass the attached sketch to the image generation tool as a referenced image by its path: {WORKDIR}\in-1.png. Give the image generation tool the text from the line that starts with Image: to the end of this message, word for word, as its prompt. Do not run shell commands. Do not read, create, change or delete any file. Do not use a browser, web search, computer use, apps or any other tool. Do not retry. When the image is done, reply with one line: done.

Image: one full-body character for a 2D duel game. Portrait, 1024x1536 pixels.

Subject: Bartolo, a vain and quarrelsome gentleman duelist from a Renaissance-era Italian town. Doublet with buttons and a small ruff collar, breeches, stockings, plain shoes, a small low-crowned hat with one long feather. He holds a rapier.

Pose and layout (the figure will be cut into separate parts, so keep the parts apart):
- Follow the attached sketch for the pose, the proportions, the place of every part and its drawing style. Keep the same large head size.
- Strictly front view, facing the viewer, standing upright, head straight, feet apart.
- His sword arm is on the viewer's left. It hangs down beside the body with a clear gap between the arm and the torso. The arm is short, as in the sketch: the hand is at waist height, just above the belt and higher than the hips. The hand holds the rapier with the blade pointing up and leaning outward, away from the body, so the blade crosses neither the body nor the head.
- His other hand is hidden behind his back.
- The feather lies sideways toward the viewer's right, not upward.
- Nothing covers the face. The whole figure is inside the image with a margin. Nothing is cropped.

(S-FIG 블록, 표정 줄 끝에 한 문장: His character shows in the expression: smug and touchy.)

(C-FIG 블록 그대로)

Background: one plain flat light grey color, about #D8D8D8, everywhere around the figure. No floor, no cast shadow, no scenery, no frame, no text, no letters, no signature, no watermark.
```

- 괄호 줄은 메인이 블록 원문으로 바꿔 쓴다. 저장된 파일에는 괄호 줄이 없고 `{WORKDIR}`만 남는다(021과 같다).
- 021 G1과 다른 줄: 지시 블록의 "word for word" 한 문장, 구도의 "and its drawing style", 화풍·색 블록 전체. 나머지는 글자 그대로 같아, 화풍만 바꾼 견줌이 된다.

### 장 수와 승인 (결정 198)

- 세는 법은 021과 같다(장 = 만들어진 그림, 호출 = 모델까지 간 `codex exec`, 옵션 오류로 바로 끝난 것은 세지 않는다). **장과 호출 모두 상한 10**(사용자 답).
- 10의 셈: 시험 N1 1 + 시험의 예비 1 + 묶음 6(N2~N7) + 다시 뽑기 2.
- **몫을 쓰는 규칙** (v2, T3. 상한 10을 실행 중의 판단에 맡기지 않는다):
  - 예비 몫(1)은 N1에만 쓴다: N1의 기술 실패(F2를 뺀 F4·F8·F9)나 승인 B1의 "나" 가운데 먼저 온 것.
  - 다시 뽑기 몫(2)은 나머지 모두가 함께 쓴다: 예비 몫을 쓴 뒤의 N1 다시 시험(B1 "나"), N3 다시 시험(B2 "나"), **묶음(N2~N7) 중의 기술 실패**(F4·F8·F9의 다시 돌리기), 굳은 확인에 걸린 그림의 다시 뽑기(승인 C). 쓴 만큼 승인 C가 준다.
  - 그래서 N1의 호출은 **최대 4**(시험 1 + 예비 1 + 다시 뽑기 2), N3은 최대 3이고, 모두 합해 10을 넘지 않는다.
  - 다시 뽑기 몫이 0이면 승인 B1·B2의 선택지는 "가/다"뿐이고 승인 C는 묻지 않는다.

| 지점 | 때 | 무엇 | 알리는 것과 묻는 것 |
|---|---|---|---|
| A | Q1 답 "가": 작업 3 뒤 돌리기 직전에 한 줄 알리고 답을 기다리지 않는다 | 시험 N1 한 장. 기술 실패면 예비 몫으로 한 번 더 | "시험 1장(기술 실패면 1장 더)을 돌린다" |
| B1 | 작업 4 뒤 | **인물 화풍의 판정**과 N2·N3·N6·N7 넷 | 아래 |
| B2 | N3 뒤(B1에서 N3을 승인했을 때) | **무대 화풍의 판정**과 N4·N5 둘 | 아래 |
| C | 작업 5 중이나 뒤(있을 때만) | 굳은 확인(K·H)에 걸린 그림의 다시 뽑기. 주제마다 한 번, 다시 뽑기 몫 안 | 주제, 걸린 확인과 잰 값, 바꾼 프롬프트 줄(`STYLE_SPEC.md`의 블록을 먼저 고친다) |

- 무대를 시험처럼 따로 보는 까닭(v2, 디자인 검토의 제안): 021에서 가장 멀었던 것이 무대이고 무대는 다른 블록(S-ST)을 쓴다. N1만 보고 무대 셋을 다 쓰면 사용자의 눈이 무대 화풍을 보기 전에 장이 나간다. N3은 사용자가 Q1에서 승인한 "시험 한 장"이 아니므로 바로 돌리지 않고 B1에서 승인을 받는다.
- **승인 B1에서 알리는 것**: N1의 자리·크기·시간·토큰·5시간 창 비율, 걸린 모델·추론, 덮어쓰기의 효과, F11의 세 구절, K·H 결과와 작업 3의 기준 맞추기 표, 구운 `g1-raw`와 `cmp-bartolo`의 윗줄(섞은 SVG · 021 G1 · 022 N1, 전신끼리. 페이지 경로를 준다), 남은 몫.
- **승인 B1에서 묻는 것** (사용자의 눈이 화풍의 마지막 판정이다):
  - 가. 인물 화풍이 맞다 → N2 → N3 → N6 → N7 차례로 돌린다. 끝에서부터 줄일 수 있다(N3을 빼면 B2와 N4·N5도 없다).
  - 나. 다르다(무엇이 다른지 한 줄) → 메인이 `STYLE_SPEC.md`의 S-FIG·C-FIG를 고치고 N1을 한 번 더 돌린 뒤 B1을 다시 묻는다(몫은 위 규칙).
  - 다. 그만 → 생성을 멈추고 섞은 SVG와 021 그림으로 작업 6~8을 한다.
  - N1이 굳은 확인에 걸렸으면 그 결과를 먼저 보이고 "나"를 권한다. 사용자가 "가"를 고르면 그대로 간다(사용자의 눈이 앞선다).
- **승인 B2에서 알리는 것**: N3의 기록(B1과 같은 항목), K1·K5·K7·H6·H7, 구운 `g-stage-alley`와 `cmp-stage`의 뒷골목 줄(섞은 SVG · 021 G5 · 022 N3), 남은 몫.
- **승인 B2에서 묻는 것**:
  - 가. 무대 화풍이 맞다 → N4 → N5.
  - 나. 다르다(한 줄) → S-ST·C-ST를 고치고 N3을 한 번 더 돌린 뒤 B2를 다시 묻는다(다시 뽑기 몫).
  - 다. 무대는 그만 → N4·N5를 돌리지 않는다.
  - B2를 기다리는 동안 메인은 B1에서 승인받은 N6·N7을 먼저 돌려도 된다(인물 블록은 B1에서 판정을 받았다).
- **묶음 안의 멈춤** (승인 받은 장 안에서 아끼는 규칙):
  - 무대 N3이 K5·K7에 걸리면 B2에서 그 결과를 먼저 보이고 "나"를 권한다(N4·N5는 B2의 답 전에는 돌리지 않는다).
  - 의뢰인 N6이 K5·K6에 걸리면 N7을 같은 프롬프트로 돌리지 않는다. 승인 C에서 N6을 고친 프롬프트로 다시 뽑을지 묻고, "예"면 N6(다시 뽑기 몫) 뒤에 N7을 고친 프롬프트로 돌린다(묶음 몫). "아니오"면 N7을 원래 프롬프트로 돌릴지, 돌리지 않을지 같이 묻는다.
  - 그 밖의 굳은 확인(H 등)에 걸린 그림은 묶음을 멈추지 않고 승인 C의 후보가 된다.
- 승인을 기다리는 동안 `docs/HANDOFF.md` 1번을 그 자리("승인 B1을 기다린다" 등)로 적어 둔다.
- 사용자가 줄이면 그만큼만 돌리고, 상한에 닿거나 그만이라고 하면 있는 그림으로 작업 6~8을 한다.

## 화풍 판정 (결정 199)

"화풍이 SVG 견본과 같은가"를 셋으로 본다: 재는 굳은 확인(K1~K5), 눈으로 보는 굳은 확인(K6·K7), 부드러운 확인. 021의 H1~H8도 그대로 한다. 마지막 판정은 사용자의 눈이다(승인 B1·B2, 보고서 4번).

### 재는 법 (메인이 scratchpad에 쓰는 C# 토막. 021의 `measure.ps1`·`scan.ps1`을 다시 만들어 넓힌다. 저장소에 넣지 않는다)

- Y = sRGB 값의 0.2126R + 0.7152G + 0.0722B (0~1). 021의 칠 문턱과 같은 식이다.
- 인물은 생성 해상도(1024×1536 등)에서 잰다. 섞은 SVG는 같은 크기로 구운 `022-in-*`에서 잰다. 무대는 가운데 1536×864를 1280×720로 맞춘 뒤 잰다(SVG도 `022-in-stage-*`를 같은 꼴로 잘라 맞춘다).
- 무대의 "가장자리 띠" = x < 290 또는 x > 990, y 64~550(HUD를 빼고 보이는 곳).
- **잴 자리는 손으로 고르지 않는다**(v2, T1·T2): 바르톨로(N1·N2와 섞은 SVG의 `022-in-front`·`022-in-parts`)는 잴 높이를 파츠 좌표(목~골반 = 200)로 정하고, 관절 점과 k로 그림의 화소로 바꾼다. 의뢰인은 인물 둘레 상자의 높이 비율(예: 옷 0.60·0.80, 얼굴은 머리 상자의 0.60)로 정한다. 정한 좌표와 비율은 작업 3에서 `GENERATION.md`에 적고, 모든 그림에 같은 것을 쓴다.
- **선 화소의 문턱은 Y < 0.22 하나다**(K1·K2·상태 색 필터와 같다). 섞기의 선은 Y 0.176이고, 0.30 아래의 그림자(바지 `#57442F` 0.277, 장갑 `#634228` 0.279, 비토리오 옷 `#663B3B` 0.267)도 0.22 위라 선으로 세지 않는다.

### 굳은 확인

| # | 무엇 | 재는 법과 통과 | 대상 | 가름 |
|---|---|---|---|---|
| K1 | 선 색 | 선 화소(Y < 0.22. 인물은 잘라 낸 알파 안, 무대는 가장자리 띠)의 가운데 RGB가 채널마다 `#3B2A1E`(59, 42, 30)와 ±30 안이고 R − B ≥ 12(따뜻함) | 전부 | 지킴 |
| K2 | 선 굵기의 고름 | 바깥 윤곽 위 **12점**. 바르톨로: 몸통 양옆 두 높이(가슴 y −150, 허리 y −40) 4, 소매 바깥 두 높이 2, 바지 양옆(y 30) 2, 스타킹 양옆(y 110) 2, 입 높이의 얼굴 양옆(목 위 20) 2. 의뢰인: 입 높이의 머리 양옆 2, 어깨 양옆 2, 옷 옆선 두 높이 양옆 4, 손 바깥 2, 앞치마(클라라)·털깃(비토리오) 양옆 2. 짙은 덩이(머리털·수염·구두·허리띠·비토리오의 모자)에 닿는 점은 넣지 않았다. 점마다 **바탕 쪽에서 윤곽에 수직으로 들어가, Y < 0.22인 화소가 처음 나온 곳부터 다시 Y ≥ 0.22가 되는 곳 앞까지**의 길이를 폭으로 잰다(안쪽의 그림자 띠는 들지 않는다). **최대 ÷ 최소 ≤ 1.8**. N1·N2는 가운데 값 × k가 3.6~7.8(5.2의 0.7~1.5배) | N1, N2, N6, N7 | 가름 |
| K3 | 평평한 칠 | 부위 셋(바르톨로: 몸통·바지·소매, 의뢰인: 옷 둘·얼굴)마다 칠 한 칸과 그림자 한 칸, 16×16 화소 칸 여섯의 Y 표준편차가 모두 ≤ 0.025 | N1, N2, N6, N7 | 지킴 |
| K4 | 그림자 경계 | 칠과 그림자의 경계 넷(바르톨로: 몸통 y −100·바지 y 30·소매 가운데·얼굴 목 위 40, 의뢰인: 옷 0.60·0.80·얼굴·손)을 정한 높이에서 왼쪽(칠)에서 오른쪽(그림자)으로 가로로 훑는다. ① 칠 Y와 그림자 Y를 어림해(칠 쪽·그림자 쪽 가운데 값) **그 중간값을 처음 지나는 화소를 경계**로 잡는다. ② 경계에서 −11~−7 화소의 평균을 칠 Y, +7~+11 화소의 평균을 그림자 Y로 다시 잡고 Δ = 차이. ③ **경계 ±6 화소(13화소) 안에서만** Y가 (그림자 + 0.2Δ)와 (칠 − 0.2Δ) 사이인 화소를 센다. 모든 범위는 생성 해상도(가로 1024 또는 1536의 화소)에서다. **모든 경계에서 ≤ 3**. Δ < 0.04이면 그 경계는 재지 않고 적는다. 경계를 못 찾으면(그림자가 있어야 할 자리에 없으면) 부드러운 확인으로 적는다. 이 범위를 빼고 센 값은 기준 맞추기에도 N 판정에도 쓰지 않는다 | N1, N2, N6, N7 | 가름 |
| K5 | 선 밀도 | 선 화소 = Y ≤ 0.45이면서 둘레 9×9 평균보다 0.08 이상 어두운 화소. 밀도 = 선 화소 ÷ 영역 화소. 영역은 인물의 알파 안, 무대의 가장자리 띠. **생성 ÷ 같은 주제의 섞은 SVG ≤ 1.5** | N1, N6, N7, N3~N5 | 가름 |
| K6 | 인물의 덧붙임 없음 (눈) | 얼굴을 2배로 잘라 구워 Read로 본다. 홍조·땀방울·눈물·눈 하이라이트·주근깨·볼 빗금이 없다. 칠 안에 빗금·천 무늬·결이 없다. 눈은 **넣은 스케치의 눈 꼴**이다(v2, D1): N1은 명세 표정 표의 거만함 꼴(아래로 휜 반달 선 눈), N6은 채운 점 눈, N7은 반쯤 감은 짧은 호 눈. 모두 하이라이트·흰자가 없다. N2의 세 얼굴은 명세의 표정 꼴(당황의 흰자 원은 된다)이면 된다 | N1, N2, N6, N7 | — |
| K7 | 무대의 판화 결 없음 (눈) | 교차 빗금이 없다. 벽에 벽돌·돌 결·회벽 금·나무결이 깔리지 않는다. 빗금은 가장자리 벽의 모서리 띠와 문 안에만 있다. 돌은 바닥 가장자리에만 있다. 조용한 구역에 선이 없다 | N3~N5 | — |

- 021의 H1~H8은 021 작업 6의 표 그대로 같은 대상에 한다(H1 정면, H2 파츠로 나눌 수 있음, H3 바탕 지우기, H4 글자 없음, H5 신호 구역과 큰 면 S ≤ 50%, H6 극장 금지, H7 무대 가운데 L 평균 ≤ 0.20·95번째 ≤ 0.30, H8 큰 면의 칠·그림자 Y ≥ 0.30). H7은 021처럼 다시 뽑기 아닌 손질(`brightness()`)이다.
- 걸리면: K1~K7·H1~H6·H8은 다시 뽑기 후보(승인 C)이고, 묶음 안의 멈춤 규칙(K5·K6·K7)을 따른다.

### 기준 맞추기 (작업 3. 사용량 없음. N1 전에 끝내고 기준을 얼린다)

- K1~K5를 아래에 재서 `GENERATION.md` "화풍 판정의 기준 맞추기" 표에 적는다.
  - 섞은 SVG: `022-in-front`, `022-in-parts`, `022-in-client-1`·`-2`, `022-in-stage-*` 셋.
  - 021의 B SVG: `generated/in/`의 021 넣은 그림(`in-front` 등).
  - 021 생성: G1~G4, G5 셋(K5 무대).
- **섞은 SVG는 모두 통과해야 한다.** 통과하지 못하면 잘못된 것은 재는 법이다. 그 K의 **통과 값 하나만** 한 번 늦추고(섞은 SVG가 여유 있게 통과할 만큼) 그 값과 까닭을 적는다(v2, T1). 늦출 수 있는 것: K1의 ±30, K2의 비 1.8과 3.6~7.8, K3의 0.025, K4의 3, K5의 1.5. **바꾸지 않는 것**: 선·칠의 Y 문턱(0.22, 0.30), K5 선 화소의 정의, 잴 자리와 범위(K2의 훑는 규칙, K4의 ±6·창).
- 늦춘 값으로 021 생성도 통과하게 되면 그 K는 가르지 못하는 것이다(다음 줄).
- **가르는 확인**(K2·K4·K5)은 021 생성 가운데 사용자가 "멀다"고 본 쪽(인물 G1·G3·G4 가운데 하나 이상, 무대는 G5 가운데 하나 이상)에서 걸려야 한다. 걸리지 않으면 그 확인은 가르지 못하는 것이라 **부드러운 확인으로 내리고**, 승인 B1(무대 K5는 B2)에서 그렇게 알린다. 문턱을 조여 억지로 가르지 않는다.
- K1·K3은 지키는 확인이라 섞은 SVG가 통과하면 된다.
- 여기서 정한 문턱은 N1을 돌린 뒤 바꾸지 않는다. 바꿔야 하면 그 까닭을 적고 모든 N에 다시 잰다.

### 부드러운 확인 (다시 뽑기의 까닭이 아니다. 보고서에 적는다)

- 섞은 SVG와 같은 집안으로 보이는가. 021 생성보다 SVG에 가까운가.
- 그림자가 보는 쪽 오른쪽에 있는가. 안 선이 바깥 선보다 가늘고 적은가(K2에서 안 선 세 점을 함께 잰다).
- 몸이 기하 덩이로 읽히는가(해부 표현이 없는가). 생성 원래의 머리 비(맞추기 전).
- 표정과 성격. N2의 세 얼굴이 같은 사람인가.
- 무대: 곳이 HUD를 얹은 채로 읽히는가, 인물과 무대의 결이 같은가(021에서 다르다고 본 것), 가운데 L 평균이 SVG(0.07~0.08)와 얼마나 다른가.
- SVG를 거의 그대로 따라 그렸는가, 아니면 다듬어진 것이 있는가(4단계에서 생성 길을 고를 때의 자료).

## 견본 `docs/style/samples/022-mix.html` (결정 196)

- **새 파일**이다. `021-detail.html`을 복사해 시작하고, 020·021 견본은 고치지 않는다(커밋된 기록을 남긴다). 020 작업 3의 규칙(`<meta charset="utf-8">` 맨 앞, 읽는 동안 한 번에 그림, 바깥 자원 없음, 상대는 `data-part` 무리)과 021의 꼴(생성 그림은 `<image href="../generated/…">`만, 단독 보기 `#<id>`·`#<id>--grid`, 넣은 그림의 `?stage=`)을 그대로 쓴다.
- **섞기로 바꾸는 것**: `:root`의 `--lw: 4.6` → `5.2`, 규칙 `.line { filter: url(#inkline); }`을 지운다. 칠·그림자·무대·HUD·신호의 값은 그대로다. `inkline` 필터 정의는 `mix-lines`의 B 칸에만 쓴다.
- **021의 생성 그림을 가리키는 표**(관절·k·배율·다각형)는 `cmp-*`에서 021 그림을 그리려고 옮겨 둔다. 022의 표는 작업 6에서 채운다.

| 차례 | id | 무엇 | 크기 |
|---|---|---|---|
| 1 | `mix-lines` | 같은 대기 바르톨로 셋(교전 0.85, 뒷골목 가운데 톤 위): A의 선(`#1E1A17`, 6) · B의 선(`#3B2A1E`, 4.6, `inkline`) · 섞기(`#3B2A1E`, 5.2). 칠은 셋 모두 B다(선만 견준다) | 1280×720 |
| 2~4 | `stage-alley`, `stage-court`, `stage-piazza` | 021과 같은 장면(큰 베기 0.25, 두 줄 글자, 고리, 조준, HUD), 섞은 선 | 1280×720 |
| 5 | `s-parts` | SVG 파츠 시트(머리 셋) | 1280×720 |
| 6 | `s-states` | SVG 상태 넷 | 1280×720 |
| 7·8 | `s-client-1`, `s-client-2` | 카운터의 클라라·비토리오(SVG) | 1280×720 |
| 9 | `g1-raw` | N1 원본 (`--grid`) | 1280×720 |
| 10 | `g1-states` | N1을 잘라 만든 상태 넷. 캡션 "N1은 얼굴 하나다" | 1280×720 |
| 11 | `g2-raw` | N2 원본 (`--grid`) | 1280×720 |
| 12 | `g2-states` | N2로 만든 상태 넷(머리는 상태마다) | 1280×720 |
| 13 | `g-duel` | 022 생성 바르톨로(N2, 없으면 N1)의 큰 베기, SVG 뒷골목 | 1280×720 |
| 14 | `g-far` | 같은 바르톨로의 멀리·방심 | 1280×720 |
| 15~17 | `g-stage-alley`, `g-stage-court`, `g-stage-piazza` | N3~N5 위에 `g-duel`의 장면 | 1280×720 |
| 18·19 | `g-client-1`, `g-client-2` | 카운터의 N6·N7 | 1280×720 |
| 20 | `cmp-bartolo` | 대기 바르톨로를 두 줄로, 여섯 모두 같은 크기(0.65)·같은 무대 톤(뒷골목 가운데)에. **윗줄(전신끼리)**: 섞은 SVG · 021 G1 · 022 N1. **아랫줄(파츠 시트끼리)**: 섞은 SVG · 021 G2 · 022 N2. 022 칸이 없으면 "만들지 않았다"(승인 B1 때는 아랫줄의 022 칸이 비어 있다). 021 칸과 022 칸은 늘 같은 길(전신 / 시트)끼리 짝짓는다(v2, D2) | 1280×720 |
| 21 | `cmp-stage` | 3×3 작은 그림(줄: 곳, 칸: 섞은 SVG · 021 G5 · 022 N). HUD·상대 없음 | 1280×720 |
| 22 | `cmp-client` | 2×3(줄: 사람, 칸: 섞은 SVG · 021 G3/G4 · 022 N6/N7) | 1280×720 |
| 23 | `palette` | 섞기 팔레트(`:root` 값과 HSV·Y), 선 굵기 표, 기준 맞추기와 K·H 결과, 생성 그림을 잰 값, 대비 표(021과 같은 여섯 줄 × 무대: SVG 셋과 N3~N5), 교전 꼭대기의 셈 | 1280×720 |
| 24·25 | `s-states-gray`, `g-states-gray` | 흑백 | 1280×720 |
| 26 | `in-front` | 생성에 넣는 바르톨로(섞기, 바탕 `#D8D8D8`) | 1024×1536 |
| 27 | `in-parts` | 파츠 배치(머리 셋, 이름·점 없음) | 1536×1024 |
| 28·29 | `in-client-1`, `in-client-2` | 의뢰인 허리 위 | 1024×1536 |
| 30 | `in-stage` | `?stage=`(alley·court·piazza)로 곳을 고른다 | 1536×1024 |

- 생성 섹션은 늘 두고, 그림이 없으면 "만들지 않았다(까닭)" 한 줄을 보인다(021과 같다).
- `data-part` 여덟 값의 수(그린 뒤의 문서에서): SVG 17(`mix-lines` 3 + `stage-*` 3 + `s-states` 4 + `s-states-gray` 4 + `in-front` 1 + `cmp-bartolo` 2) + 022 생성 19(`g1-states` 4 + `g2-states` 4 + `g-duel` 1 + `g-far` 1 + `g-stage-*` 3 + `g-states-gray` 4 + `cmp-bartolo` 2) + 021 생성 2(`cmp-bartolo`) = 다 그리면 각각 38. 그리지 않은 생성 섹션만큼 뺀다. 스크립트 안의 틀이 걸리면 빼고 적는다(021에서 1건).
- `data-sheet-part`: `s-parts`·`in-parts`라 `Head` 6, 나머지 일곱 값 각각 2(021과 같다).
- **파츠로 나누기와 얹기**는 `GENERATION.md` "파츠로 나누기와 비례 맞추기"와 021 "생성 인물을 파츠로 나누는 법" 그대로다: 테두리 채우기(채널 차 28)와 1px 깎기, 관절 읽기(격자), k = 200 ÷ (골반 − 목), 머리 104(±5%)로 목 중심 배율, 교전 꼭대기 ≥ 142가 안 되면 모자만 줄임(모자 ≤ 53), 팔 ±15%를 넘으면 세로로 105, 칼은 칼자루 중심으로 (r − θ0), N2의 머리는 상태마다(대기·찌르기·큰 베기·방심은 거만함, 빈틈은 당황, 무너짐은 어지러움), 상태 색은 밝기 문턱(Y < 0.22 선, > 0.30 칠) 필터로 칠에만 80%.
- 무대 N3~N5는 가운데 1536×864를 `xMidYMid slice`로 1280×720에 맞춘다. 바탕을 지우지 않는다.

## 작업 목록

**공통 규칙**

- 근거의 "넘지 않는 선"을 지킨다. 대조가 어긋나면 값을 맞추지 말고 멈춰서 보고한다.
- 차례는 결투 먼저다(원칙 4): 바르톨로 → 무대 → 의뢰인. 의뢰인을 다 못 하면 그 섹션을 빈 채로 두고 보고서 1번에 적는다.
- 구운 PNG와 재기 도구는 scratchpad에 둔다. `-i`로 넣는 것만 `docs/style/generated/in/022-in-*.png`로 복사한다.
- 굽기는 020 작업 4의 명령 그대로다(버전 폴더의 `msedge.exe`, 따로 된 `--user-data-dir`로 한 장씩, 60초를 넘기면 그 PID 나무와 우리 프로필만 끈다, 이름으로 끄지 않는다). `in-*`는 그 크기의 `--window-size`로 굽는다.

### 작업 0. 시작 상태와 CLAUDE.md 9장의 화풍 한 줄

- 시작 상태를 적는다: `git log -1 --oneline`이 `9909fb9`, `git status --short`에 이 계획 파일(`?? docs/plans/022-style-spec-and-regeneration.md`)만 있다. 다른 변경이 있으면 멈추고 사용자에게 묻는다.
- Glob `docs/style/reference/*.{png,jpg,jpeg,webp}` 0, Glob `docs/style/**/*.import` 0을 적는다(있으면 읽지도 쓰지도 않고 보고서에 적는다).
- 021 생성 그림이 로컬에 있는지 본다: Glob `docs/style/generated/021-G*.png` 7, `docs/style/generated/cut/021-*.png` 4, `docs/style/generated/in/*.png`. 없으면 기준 맞추기(작업 3)와 `cmp-*`의 021 칸을 "없다"로 두고 보고한다.
- **생성보다 먼저** CLAUDE.md 9장을 고친다(설계가 바뀌었다. CLAUDE.md 머리): 현재 위치의 "화풍의 방향: … 「Potion Craft」처럼(사용자 지시 2026-11-21)." 뒤에 한 문장 "기준 화풍은 계획 021의 SVG 견본이고, 선은 깔끔한 짙은 고동 선(고른 굵기), 칠은 바랜 색이다(020의 A·B 섞기. 사용자 답 2026-11-21, 결정 194)."를 더한다.
- 완료 확인: `git diff -- CLAUDE.md`가 9장의 이 한 문장뿐이다.

### 작업 1. 화풍 명세 — `docs/style/STYLE_SPEC.md` (새 파일)

- 머리: 쓰임(3단계의 기준 화풍을 말과 값으로 적은 것, 024 STYLE_BIBLE의 입력), 근거(021 견본에 대한 사용자 답, 결정 194·195), "프롬프트는 이 파일의 블록을 글자 그대로 옮긴다".
- 절: 다리 섞기, 선, 칠과 그림자, 얼굴과 비례(표정 표), 몸의 꼴, 무대, 의뢰인과 카운터, 팔레트, 하지 말 것, 프롬프트 블록(S-FIG, C-FIG, S-ST, C-ST, 사람마다 바꾸는 줄). 내용은 이 계획 "SVG 화풍의 분석"이다.
- 팔레트 표: `022-mix.html` `:root`의 인물·의뢰인·무대 색마다 값, HSV, Y, 쓰는 곳. 신호색은 표에 넣지 않고 "결정 181, 코드 값 그대로"로 가리킨다.
- 완료 확인:
  - 팔레트 표의 값이 `022-mix.html`의 `:root`와 같다(작업 2를 마친 뒤 Grep으로 값마다 대조한다).
  - 프롬프트 블록 안에서 Grep `[^\x00-\x7F]` 0, `"` 0. 파일 전체에서 Grep `-i "pizza|potion|tapblaze|niceplay|tinybuild"` 0.
  - 팔레트의 인물·무대 색 가운데 신호 구역(S ≥ 55%이면서 V ≥ 85%)이 0이다.

### 작업 2. 섞은 견본 — `docs/style/samples/022-mix.html` (새 파일)

- "견본" 절대로 만든다. 이 작업에서는 SVG 섹션, `in-*`, `cmp-*`의 SVG·021 칸까지 그린다(022 생성 칸은 "만들지 않았다").
- 완료 확인 (HTML 글에서):
  - Grep `<section id="` → 30건이고 표의 id와 차례가 같다.
  - Grep `--lw: 5.2` 1건. Grep `url\(#inkline\)` → `mix-lines`의 B 칸 규칙 하나뿐이다.
  - 신호색: Grep `--sig-|--sw-`의 줄이 `020-bridge.html`과 같은 값이다.
  - 바깥 자원: 020 작업 3의 Grep 여덟(`(src|href)\s*=\s*["']?https?:`, `url\(\s*["']?https?:`, `<img`, `<link`, `@import`, `fetch\(`, `data:image`, `reference/`) 모두 0. `href=`의 값은 `../generated/`, `#`, 이름공간뿐이다.
  - 극장의 함수 Grep `spectators|balustrade|folds` 0.
  - `git diff --stat -- docs/style/samples/020-bridge.html docs/style/samples/021-detail.html`이 비어 있다.
- 첫 굽기: SVG 섹션 전부, `cmp-*`, `in-front`, `in-parts`, `in-client-1`·`-2`, `in-stage`(셋). Read로 보고 `mix-lines`에서 섞기의 선이 매끄럽고 고른지, `in-*`에 글자·신호·HUD가 없는지 본다. `in-*`를 `generated/in/022-in-*.png`로 복사한다.

### 작업 3. 기준 맞추기와 Codex 준비 (사용량 없음)

- **기준 맞추기**: "화풍 판정"의 "기준 맞추기"대로 K1~K5를 재고 `GENERATION.md`에 새 절 "화풍 판정의 기준 맞추기 (계획 022)"로 표를 적는다(대상 · K마다 값 · 통과/걸림 · 가르는지). 가르지 못한 확인은 부드러운 확인으로 내렸다고 적는다.
- **Codex 준비**: `codex --version`(0.169.0인지. 다르면 `codex exec --help`를 다시 보고 옵션 이름을 맞춘다), `codex login status`, `codex debug models`(`gpt-6.2-sol`·`high`), `Get-FileHash ~/.codex/config.toml`(021의 처음 값과 견준다. 다르면 "절차"의 마지막 줄대로), `codex mcp list`를 끄기와 함께 한 번.
- 로그인이 안 되어 있으면(F1) 생성을 멈추고 사용자에게 `codex login`을 부탁한다. 메인은 로그인하지 않는다. SVG 작업과 작업 7·8은 계속한다.
- 완료 확인: 기준 맞추기 표가 있고 섞은 SVG가 모든 K에서 통과(늦춘 통과 값이 있으면 그 값과 까닭)다. K2·K4의 잴 자리(파츠 좌표와 의뢰인의 높이 비율)가 `GENERATION.md`에 있다. 같은 그림(섞은 `022-in-front`)을 두 번 재어 K2·K4 값이 같다. `GENERATION.md`에 버전·로그인·모델·해시·`mcp list`의 결과가 022 날짜로 있다.

### 작업 4. 시험 — N1 바르톨로 전신 (승인 A)

- Q1 답 "가"대로 돌리기 직전에 한 줄 알리고 답을 기다리지 않고 돌린다. 프롬프트는 "N1 전문"을 블록 원문으로 채워 `docs/style/prompts/022-N1-bartolo-front.txt`에 저장하고, 작업 폴더의 `prompt.txt`는 그 복사본에 `{WORKDIR}`를 바꾼 것이다. 넣는 그림은 `022-in-front` 하나.
- 끝나면 021 작업 5와 같은 것을 적는다(자리, 크기, 바이트, 시간, 토큰, 한도 비율, 모델·추론, 노출·호출된 도구, 그림 도구 인자, 덮어쓰기 효과, 전후 대조). 더해서 F11의 세 구절.
- 바탕 지우기와 관절 읽기(작업 6의 앞부분)를 먼저 하고 K1~K6·H1~H5·H8을 잰다. `g1-raw`·`cmp-bartolo`(윗줄)를 굽는다.
- 그다음 **승인 B1**("장 수와 승인"). "나"면 이 작업을 되풀이한다.
- 완료 확인: `GENERATION.md` 기록 표에 N1의 줄(021의 칸 + 새 칸 "화풍 확인(K)"과 "넘긴 프롬프트의 세 구절")이 호출마다 있다. N1의 호출 수 ≤ 4이고, 예비 몫과 다시 뽑기 몫을 어디에 썼는지 적혀 있다(v2, T3). 전후 대조가 같다. 모델·추론 칸이 세션 기록의 `gpt-6.2-sol`·`high`다. `generated/022-N1-bartolo-front.png`가 `System.Drawing`으로 열린다. 프롬프트 파일에서 S-FIG·C-FIG 블록이 `STYLE_SPEC.md`의 원문과 글자 그대로 같다(두 파일의 그 줄들을 Grep으로 대조).

### 작업 5. 묶음 — N2~N7 (승인 B1·B2)

- 사용자가 승인한 것만, 작업 4의 절차로 돌린다. B1의 넷은 N2 → N3 → N6 → N7, B2의 둘은 N4 → N5 차례다. N3 뒤에 `g-stage-alley`·`cmp-stage`(뒷골목 줄)를 굽고 **승인 B2**를 묻는다. 묶음 중의 기술 실패는 다시 뽑기 몫에서 다시 돌린다. 프롬프트는 "`-i`에 넣는 것"의 표대로 쓰고 `docs/style/prompts/022-N<n>-<이름>.txt`에 저장한다. 파일 이름은 `022-N2-bartolo-parts`, `022-N3-stage-alley`, `022-N4-stage-court`, `022-N5-stage-piazza`, `022-N6-client-clara`, `022-N7-client-vittorio`.
- 호출마다 K·H를 재고 "묶음 안의 멈춤"을 따른다. 걸린 그림이 있고 상한이 남았으면 **승인 C**를 묻는다. 다시 뽑기의 프롬프트는 `STYLE_SPEC.md`의 블록을 먼저 고친 뒤 옮긴다.
- 완료 확인:
  - 기록 표의 줄 수 = 호출 수. 장·호출 모두 상한 10과 승인한 수 이하. 몫마다(시험·예비·묶음·다시 뽑기) 쓴 수가 기록 표 아래에 있다.
  - 프롬프트 파일이 호출마다 있고, 화풍·색 블록이 그때의 `STYLE_SPEC.md` 원문과 같다.
  - 프롬프트 폴더의 `022-*`에서 Grep `-i "pizza|potion|tapblaze|niceplay|tinybuild"` 0, `[^\x00-\x7F]` 0, `"` 0, `reference/|screenshot` 0(021 실행 중에 좁힌 확인).
  - 기록 표의 "넣은 그림" 칸이 `022-in-*`나 N1 원본뿐이다.

### 작업 6. 손질과 얹기

- "견본"의 "파츠로 나누기와 얹기"대로 N1·N2를 나누고 N3~N5를 맞추고 N6·N7의 바탕을 지운다. 관절·다각형·θ0·k·배율·N2의 상태별 머리는 페이지 스크립트의 표 하나에 둔다.
- 재기(값은 `palette`와 `GENERATION.md`): 021 작업 7의 것(칠·그림자 세 점씩과 HSV·Y, 신호 구역 비율, 원래의 머리·팔 길이 × k, 무대 가운데 L 평균·95번째, x 290~990 L 평균, 대비 표의 생성 줄) + K1~K5의 값.
- 물든 칠 확인: `g1-states`·`g2-states`의 빈틈 칸 몸통의 칠 한 점·그림자 한 점이 `lerp(바탕, #4D80F2, 0.8)`와 ±4.
- 완료 확인: 생성 섹션마다 그림이 보이거나 "만들지 않았다(까닭)"가 있다. `g*-states`·`g-duel`·`g-far`·`g-stage-*`의 머리 104(±5%), 팔 105(±15% 안이거나 맞춘 것), 교전 꼭대기 ≥ 142.

### 작업 7. 굽기와 눈 확인

- 30 섹션 모두를 한 번 더 굽는다(최종본). 생성 그림이 빠진 장은 `--virtual-time-budget=10000`으로 한 번 더, 그래도 빠지면 실패 목록에 적는다.
- 그린 뒤의 문서(`--dump-dom`)에서 센다: 섹션 30, `data-part`(견본 절의 셈), `data-sheet-part`.
- 눈으로 볼 것(메인의 눈은 참고다. 어긋난 것은 고쳐 다시 굽는다):

  | # | 볼 것 | 섹션 |
  |---|---|---|
  | 1 | 섞기의 선이 A처럼 매끄럽고 고르며, 칠은 B처럼 바래 보인다. A·B·섞기가 선만 다르다 | `mix-lines` |
  | 2 | 무대 셋: 021 견본과 같은 장면이고 극장으로 읽히지 않으며, 조용한 구역이 짙고 신호가 또렷하다 | `stage-*` |
  | 3 | 상대 전체가 화면 안이고 두 줄 글자 상자와 겹치지 않는다 | `stage-*`, `g-duel`, `g-stage-*` |
  | 4 | 상태 넷이 칠 색으로 갈리고 그림자까지 물든다. 빈틈 칸의 머리는 물들지 않았다. N2는 상태마다 얼굴이 바뀐다. 구멍·유령·관절의 틈을 적는다 | `s-states`, `g1-states`, `g2-states` |
  | 5 | 흑백에서도 넷이 자세로 갈린다 | `*-states-gray` |
  | 6 | 멀리(0.55)에서 얼굴과 내려간 칼끝이 보인다. 생성 그림의 가장 가는 선이 화면에서 몇 px인지(023의 크기 기준 자료) | `g-far` |
  | 7 | 생성 무대가 극장으로 읽히지 않고, HUD를 얹은 채 곳이 읽히고, 판화 결이 없고, 상대와 같은 결로 보인다 | `g-stage-*`, `cmp-stage` |
  | 8 | 의뢰인이 카운터에 붙어 보이고 성격이 표정·옷으로 읽힌다. 덧붙임(땀·홍조)이 없다 | `s-client-*`, `g-client-*`, `cmp-client` |
  | 9 | **세 갈래 견줌**: 022 생성이 섞은 SVG와 같은 집안인가, 021 생성보다 가까운가(부드러운 확인의 말로 적는다) | `cmp-*` |

- 완료 확인: 최종본 30장(실패가 있으면 목록과 까닭), `--dump-dom`의 수와 눈 확인의 결과가 보고서 2번에 있다. 굽기를 마친 뒤 우리 프로필이 든 `msedge.exe`가 0개다.

### 작업 8. 기록과 보고

- **`docs/DECISIONS.md`**: 끝에 "2026-11-21 — 계획 022 (화풍 명세와 다시 만들기. `docs/plans/022-style-spec-and-regeneration.md` v<n>)" 절.
  - 근거: 위 "계획 021 견본에 대한 사용자 답"을 가리킨다. 실행 전 답(Q1)을 적는다.
  - 결정 193~200을 한 줄씩(아래 "설계 결정").
  - 실행 중에 정한 것: 늦춘 문턱과 부드러운 확인으로 내린 K, 덮어쓰기의 효과, F11의 결과, 바꾼 프롬프트 줄, 장·호출의 수와 몫마다 쓴 수, 승인 B1·B2·C의 답, 손질 값(머리·모자·팔의 배율, `brightness()`).
- **`CLAUDE.md`** (9장의 화풍 한 문장은 작업 0에서 고쳤다):
  - 8장 `docs/` 줄의 `style/ (samples/, prompts/, GENERATION.md, …)`에 `STYLE_SPEC.md`를 더한다.
  - 9장 현재 위치의 "계획 021(세부 견본과 그림 생성 시험)까지 실행했다. 3단계는 020~023으로 나눈다(결정 183)."를 "계획 022(화풍 명세와 다시 만들기)까지 실행했다. 3단계는 020~024로 나눈다(결정 193)."로 바꾼다.
  - 완료 확인: `git diff -- CLAUDE.md`에서 이 계획이 바꾼 줄이 8장 하나, 9장 하나(두 곳을 고친 같은 줄)뿐이다.
- **`docs/style/GENERATION.md`**: 머리의 결정 범위에 193~200을 더한다. "절차"에 022의 준비 결과와 바뀐 이름·자리, F11. "프롬프트의 틀"에 "화풍·색 블록은 `STYLE_SPEC.md`의 원문"을 더한다. 기록 표에 칸 둘(화풍 확인(K), 넘긴 프롬프트의 세 구절)을 더하고 021의 줄에는 "—"를 넣는다. "화풍 판정의 기준 맞추기" 절.
- **`docs/reports/022-style-spec-and-regeneration.md`**와 사용자 보고(CLAUDE.md 10장 형식):
  1. 한 일과 바꾼 파일.
  2. 확인한 것: 작업 0~7의 완료 확인, 기준 맞추기 표, K·H 결과, 장과 호출의 수, 전후 대조, 눈 확인. 확인 못 한 것: Windows 샌드박스가 실제로 막는지, `notify` 끄기의 효과, 밝기 문턱 필터가 Godot 셰이더로 같게 되는지(4단계), 다른 브라우저에서의 모습, 명세 글만으로(스케치 없이) 같은 화풍이 나오는지(위험 3).
  3. 설계와 다른 것: 3단계를 다섯으로 나눴다(결정 193), 다리 B를 섞기로 바꿨다(결정 194, 사용자 답), 선 굵기 5.2는 planner의 임시 값이다, 가르지 못해 부드러운 확인으로 내린 K, 그 밖의 손질.
  4. 사용자 결정: 아래 "보고서 4번의 물음"과 "사용자 결정 필요".
  5. 다음: 답을 받아 계획 023.
- **보고서 4번의 물음**:
  1. **화풍**: 022 생성이 원하신 SVG 화풍에 맞는가(맞다 / 다르다 — 무엇이). 선 굵기 5.2가 괜찮은가(`mix-lines`).
  2. **무대**: 곳마다(여럿이면 "모두") 섞은 SVG / 021 생성 / 022 생성.
  3. **바르톨로의 기준**: 섞은 SVG / 022 N1(전신을 자른 것) / 022 N2(파츠 시트). 021 G1·G2도 고를 수 있다.
  4. **의뢰인의 기준**: 사람마다 섞은 SVG / 022 생성(021 생성도 된다).
  5. **4단계에서 그림을 만드는 길**: 가 생성(명세 + 섞은 SVG 스케치 + 파츠 시트 + 손질) / 나 메인이 SVG로 / 다 섞기(예: 무대·의뢰인은 생성, 상대는 SVG) / 라 사람이 그린다. 물음 옆에 적는다: 이번 생성은 모두 섞은 SVG 스케치를 붙였다. 새 상대·새 의뢰인을 생성으로 만들려면 그 사람의 SVG 스케치를 먼저 그려야 한다(글만으로는 시험하지 않았다).
  6. **싫은 것**이 있으면 한 줄로.
  7. 고른 그림을 023의 첫 작업에서 `docs/style/basis/`로 올리는 것.
- **`docs/HANDOFF.md`**: 1번을 "022의 답을 기다린다. 다음은 023(올리기·팔레트·글꼴·UI·크기 기준). 화풍의 기준은 `docs/style/STYLE_SPEC.md`"로 고친다. 머리의 로컬 그림 줄에 022의 그림을 더한다. 3번에 "계획 022 보고서 4번" 한 줄. 1번의 "3단계는 020~023" 줄을 "020~024(결정 193)"로 고친다.
- `docs/BACKLOG.md`는 건드리지 않는다(게임 코드의 고칠 거리가 새로 생기지 않는다).
- playtester에게 맡길 확인: 없다(게임이 바뀌지 않는다. `.gdignore`는 021 뒤 playtester가 확인했다).
- 완료 확인:
  - 보고서 파일이 있고 2번에 "확인 못 한 것"이 있다.
  - `CLAUDE.md`·`DECISIONS.md`·`HANDOFF.md`에서 이 계획이 바꾼 줄이 위에 적은 것뿐이다.
  - `config.toml`의 해시가 작업 3에서 적은 값과 같다.
  - 끝의 `git status --short`에 새로 바뀐 것이 이 계획 파일, `CLAUDE.md`, `docs/DECISIONS.md`, `docs/HANDOFF.md`, `docs/style/STYLE_SPEC.md`, `docs/style/GENERATION.md`, `docs/style/prompts/022-*.txt`, `docs/style/samples/022-mix.html`, 보고서뿐이다. `docs/style/generated/`는 보이지 않는다.

## `docs/STYLE_BIBLE.md` 목차의 바뀐 칸 (021의 표에서. 쓰는 것은 024)

| # | 항목 | 022가 정하거나 모으는 것 | 정하는 계획 (021 → 022) |
|---|---|---|---|
| 2 | 기준 이미지 | 후보(섞은 SVG, 021·022 생성)와 사용자의 선택 | 021·022 → 022(고름) · 023(올림) |
| 4 | 인물 | `STYLE_SPEC.md`의 선·칠·그림자·얼굴·몸 | 그대로 → 022 |
| 6 | 배경·UI | `STYLE_SPEC.md`의 무대 | 021·022 → 022(배경) · 023(UI) |
| 8 | 색 | 섞기 팔레트와 생성 그림을 잰 값 | 022 → 023(확정) |
| 9·10 | 글꼴, 1280×720 크기 기준 | 섞기 선의 화면 px, 생성의 가장 가는 선 | 022 → 023 |
| 13 | 만드는 길 | 화풍 블록, 화풍 판정(K), 기준 맞추기 | 021 → 021·022 |
| 14 및 나머지 | | — | 023 → 024 |

## 설계 결정

번호는 193부터다. 194의 선 색·필터와 198의 상한 10은 사용자 답이다. 나머지는 planner가 위임으로 정했고 모두 임시다.

| # | 결정 | 이유 | 되돌리기 |
|---|---|---|---|
| 193 | 3단계를 다섯으로 다시 나눈다: 020·021(끝), 022 화풍 명세·섞은 견본·다시 만들기·견줌, 023 고른 그림 올리기·팔레트 확정·글꼴·UI·크기 기준, 024 STYLE_BIBLE·MANIFEST의 꼴·CLAUDE.md 7장. 결정 183을 고친다. 023·024는 합칠 수 있다 | 021의 답이 다시 만들기를 더했고, 원래 022의 일은 모두 고른 기준 이미지를 입력으로 쓰는데 그 고름이 022 끝으로 밀렸다. 022에 합치면 실행 중 승인에 고름이 하나 더 끼어 한 번에 끝내기 어렵다 | 쉬움. 023·024를 합친다 |
| 194 | 다리 섞기: 선 `#3B2A1E`, 바깥 5.2·안 2.9·눈썹 7.0(파츠 단위), 둥근 끝, 필터 없음. 칠·그림자는 B 그대로. 020의 "다리 B" 답을 고친다 | 사용자 답(선 색, 깔끔하게, 필터 없음). 굵기는 필터를 뺀 B(4.6)가 가늘어 보이고 A(6)가 무거웠던 사이 값이다(planner) | 쉬움. 변수 하나 |
| 195 | 화풍 명세는 `docs/style/STYLE_SPEC.md`에 둔다. 프롬프트의 화풍·색 블록(S-FIG, C-FIG, S-ST, C-ST)은 명세의 원문을 글자 그대로 옮기고, 고칠 때는 명세를 먼저 고친다. 024 STYLE_BIBLE 4·6·8·13번의 입력이다 | 사용자가 원한 것은 "SVG 화풍을 분석해 그 화풍으로 다시 만들기"다. 말과 값이 한 곳에 있어야 새 그림(4단계)에도 같은 말을 쓴다. `GENERATION.md`는 절차와 기록이라 따로 둔다 | 쉬움 |
| 196 | 견본은 새 파일 `022-mix.html`이다. 020·021 견본은 고치지 않는다. 섞은 SVG · 021 생성 · 022 생성을 견주는 섹션 셋(`cmp-*`)과 선만 다른 바르톨로 셋(`mix-lines`)을 둔다 | 커밋된 견본은 그때 사용자가 본 기록이다. 고르는 물음이 세 갈래라 한 화면에서 봐야 한다 | 쉬움 |
| 197 | `-i`에는 섞은 견본을 구운 스케치(`022-in-*`)를 넣고, 그것이 구도와 화풍의 기준을 겸한다. 화풍 카드를 따로 붙이지 않는다. 지시 블록은 그림 도구에 `Image:`부터 끝까지를 글자 그대로 넘기게 하고, 세션 기록의 인자에서 세 구절을 확인한다(F11) | 021은 스케치를 따랐지만 화풍은 프롬프트의 말을 따랐다. 스케치와 말을 같은 화풍으로 맞추는 것이 가장 단순하다. 두 장을 붙이면 무엇을 구도로 따를지 흐려진다. 021에서 에이전트가 프롬프트를 다시 썼다 | 쉬움. 화풍 카드는 다시 뽑기의 프롬프트에서 더할 수 있다 |
| 198 | 장과 호출 모두 상한 10(사용자 답): 시험 1 + 예비 1 + 묶음 6 + 다시 뽑기 2. 예비는 N1에만, 다시 뽑기 몫은 다시 시험·묶음의 기술 실패·승인 C가 함께 쓴다(N1 최대 4). 승인 A(시험 N1, Q1 답 "가"로 바로), B1(N1 뒤. 사용자가 인물 화풍을 보고 N2·N3·N6·N7 / 다시 시험 / 그만), B2(N3 뒤. 무대 화풍을 보고 N4·N5 / 다시 시험 / 그만), C(다시 뽑기). 몫이 0이면 B1·B2는 "가/다"뿐이다. 의뢰인 N6이 K5·K6에 걸리면 N7은 같은 프롬프트로 돌리지 않는다 | 화풍의 마지막 판정은 사용자의 눈이다. 인물과 무대는 블록이 달라 따로 본다(021에서 가장 멀었던 것이 무대다). 같은 말로 같은 실패를 되풀이하지 않게 아끼고, 몫의 쓰임을 미리 정해 상한을 실행 중의 판단에 맡기지 않는다(v2, T3) | 쉬움 |
| 199 | 화풍 판정: 재는 굳은 확인 K1~K5(선 색, 선 굵기의 고름, 평평한 칠, 그림자 경계, 선 밀도), 눈으로 보는 굳은 확인 K6·K7(인물의 덧붙임, 무대의 판화 결), 021의 H1~H8, 부드러운 확인. K2·K4·K5는 N1 전에 021 생성 그림으로 기준을 맞춰, 섞은 SVG는 통과하고 021 그림은 걸릴 때만 굳은 확인으로 쓴다. 선 화소는 Y < 0.22 하나로 정하고, 잴 자리는 파츠 좌표·높이 비율로 고정하며, 늦출 수 있는 것은 K마다 통과 값 하나다. 문턱은 N1 전에 얼린다. K6의 눈은 넣은 스케치의 눈 꼴로 본다 | 021에서 본 차이(거친 선, 부드러운 그림자, 덧붙임, 판화 결)를 하나씩 잰다. 재는 법이 사용자가 "멀다"고 본 그림을 가르지 못하면 숫자가 판정을 흐린다 | 쉬움. 견본의 방법이다 |
| 200 | 022의 그림은 N1~N7이고 파일은 `022-N<n>-<이름>`, 넣은 그림은 `generated/in/022-in-*`, 프롬프트는 `prompts/022-N<n>-*.txt`다. 절차는 `GENERATION.md` "절차" 그대로다(결정 184·192, 021 실행 중에 더한 `--disable` 다섯과 세션 기록 Grep의 꼴) | 021의 그림·넣은 그림을 덮어쓰지 않고 견줄 수 있게 한다 | 쉬움 |

## 위험

1. **에이전트가 화풍 말을 다시 써서 흐린다.** 021에서 에이전트는 프롬프트를 그림 도구에 맞게 다시 썼다. 대비: "글자 그대로" 지시와 F11(세션 기록의 세 구절). 빠지면 승인 B1에서 지시를 고칠지 묻는다.
2. **스케치를 붙여도 화풍을 따르지 않는다.** 021에서 확인한 것은 구도·자세뿐이다. 대비: 인물은 N1, 무대는 N3의 K 확인과 사용자의 눈(승인 B1·B2), 갈래마다 다시 시험(몫 안). 끝내 안 되면 보고서 4번의 "만드는 길"에서 SVG를 고를 자료가 된다.
3. **반대로 SVG를 거의 그대로 베끼면** 생성의 덧셈이 없고, 새 상대·의뢰인마다 SVG 스케치가 먼저 있어야 한다. 이번에는 글만으로 만드는 시험을 하지 않는다(상한 10이 일곱 장과 예비로 찬다). 대비: 부드러운 확인과 보고서 4번의 5에 적는다. 필요하면 다음 계획에서 한 장으로 시험한다.
4. **재는 확인이 가르지 못한다**(021 그림도 통과). 대비: 기준 맞추기에서 가르지 못한 것은 부드러운 확인으로 내리고 알린다. 판정은 사용자의 눈이 한다.
5. **색 hex를 그대로 따르면 그림자가 칠 문턱 아래로 간다.** 대비: 그림자 hex는 넣지 않고 "선보다 분명히 밝게"만 둔다. H8로 본다. 머리털·구두처럼 선과 같은 색 덩이는 물들지 않는다(021 위험 7과 같다. 결과로 적는다).
6. **깔끔한 선이 멀리에서 가늘다**(안 선 1.6px). 대비: `g-far`에서 재어 023의 크기 기준 자료로 둔다.
7. **사용자의 Codex 설정이 021 뒤 바뀌었을 수 있다.** 대비: 작업 3에서 해시를 견주고, 다르면 끄기 목록을 다시 맞추고 `mcp list`로 확인한다. 그 밖의 막는 장치·사용량·저장소 크기의 위험과 대비는 021 위험 2·3·9와 같다(한 장에 약 39,000 토큰, 5시간 창 +1% 안팎).
8. **실행 중에 사용자를 기다린다**(승인 B1·B2·C). 대비: SVG·기준 맞추기를 먼저 끝내고 기다린다. 기다리는 동안 `HANDOFF.md`를 그 자리로 적는다.
9. **계획이 크다**(섹션 30, 호출 최대 10, 재기). 대비: 견본은 021의 복사에서 시작한다. 결투 먼저, 의뢰인은 뒤. 다 못 하면 의뢰인 섹션을 빈 채로 보고한다.
10. **생성 그림이 두 게임을 닮아 보일 수 있다.** 대비: 이름과 참고 그림을 넣지 않았다(Grep). 닮았는지는 사용자가 본다(물음 6).

## 실행 전에 물을 것

**답을 받았다(2026-11-21). 남은 물음은 없다.**

- **Q1 답: 가**(예). 시험 N1 한 장(기술 실패면 예비 한 장)은 작업 3 뒤 돌리기 직전에 한 줄 알리고 바로 돌린다. 무대 N3은 이 답에 들지 않아 승인 B1에서 묻는다.

아래는 v1에서 물은 글의 기록이다.

**Q1. 시험 한 장(N1)을 실행 중에 바로 돌려도 될까요?** (021과 같은 물음입니다. 상한 10은 받았습니다)
- 가. 예 **(권함)**: 섞은 견본과 기준 맞추기를 마친 뒤, 돌리기 직전에 "시험 1장(기술 실패면 1장 더)을 돌린다"고 한 줄 알리고 답을 기다리지 않습니다. 묶음 여섯과 다시 뽑기는 어느 쪽이든 실행 중에 장 수를 알리고 승인을 받습니다.
- 나. 시험 전에도 다시 물어 달라 — 작업 3 뒤에 멈추고 묻습니다.
- 답에 따라: 승인 A의 때만 달라집니다. 장 수와 나머지 흐름은 같습니다.

## 사용자 결정 필요 (실행을 막지 않는다. 보고서 4번에 올린다)

| # | 무엇 | 이 계획이 정한 것 | 답이 다르면 |
|---|---|---|---|
| 1 | 화풍·기준 이미지·만드는 길 | 실행 뒤 보고서 4번의 물음 일곱 | 023의 입력(올릴 그림, 팔레트를 뽑을 그림)과 024의 STYLE_BIBLE 13번이 그 답을 따른다. 화풍이 "다르다"면 023 전에 명세를 고치는 계획이 먼저다 |
| 2 | 선 굵기 5.2 | planner의 임시 값(결정 194) | 다른 값이면 `--lw` 하나와 명세를 고친다. 이미 만든 생성 그림은 그 굵기를 따른 것이라, 차이가 크면 다시 만들지 정한다 |
| 3 | 3단계를 다섯으로 나눈 것 | 020~024(결정 193) | 넷으로 되돌리려면 023·024를 합친다 |
| 4 | 022의 커밋 | 정하지 않는다(사용자가 지시한다) | — |

보류 중인 것(그대로 둔다): 2단계의 값과 결정(`docs/HANDOFF.md` 3번), `docs/BACKLOG.md`의 항목, `docs/plans/013-playtester.md`의 번호 겹침.

## 수정 기록

v1 → v2 (1회차 검토: design-reviewer REVISE D1·D2, tech-reviewer REVISE T1~T3. 같은 때 받은 사용자 답 Q1 "가"도 반영했다).

- **D1 (수용, 통과 조건의 가)**: S-FIG의 눈 문장을 "eyes exactly as in the sketch (small solid dark dots, or short curved lines for a smug or half-closed look)"로 고쳤다. K6의 눈 기준은 "넣은 스케치의 눈 꼴"로 바꿨다(N1 거만함의 반달 선, N6 점, N7 반쯤 감은 호, 하이라이트·흰자 없음). "얼굴과 비례"에 스케치마다의 눈 꼴을 적었다. 결정 199에도 넣었다.
  - (나)를 고르지 않은 까닭: `in-front`를 021과 같은 `smug`로 두어야 N1과 021 G1이 화풍만 다른 견줌이 된다. 의뢰인 둘은 스케치의 눈이 달라(점 / 호), 어차피 "스케치대로"가 필요하다.
- **D2 (수용)**: 견본 표 20번 `cmp-bartolo`를 두 줄로 바꿨다. 윗줄은 전신끼리(섞은 SVG · 021 G1 · 022 N1), 아랫줄은 파츠 시트끼리(섞은 SVG · 021 G2 · 022 N2)이고, 여섯 모두 같은 크기 0.65·같은 무대 톤이다. 승인 B1의 문구는 윗줄을 가리킨다. 이에 따라 `data-part`의 셈을 35 → 38로 고쳤다(SVG 17 + 022 19 + 021 2).
- **T1 (수용)**:
  - K2의 선 문턱을 Y < 0.22로 바꿨다. 폭은 "바탕 쪽에서 들어가 Y < 0.22가 처음 나온 곳부터 다시 0.22 이상이 되기 앞까지"로 잰다(그림자 띠를 빼는 규칙).
  - 점 목록을 바르톨로·의뢰인 모두 정확히 12개로 맞췄다. 모자 챙·구두를 빼고, 짙은 덩이에 닿는 점이 없게 했다.
  - "재는 법"에 선 문턱 하나와, 0.30 아래 그림자 셋이 0.22 위라는 셈을 적었다.
  - 기준 맞추기에서 늦출 수 있는 것을 K마다의 통과 값 하나로 정했다. Y 문턱, 선 화소의 정의, 잴 자리와 범위는 바꾸지 않는다.
- **T2 (수용)**: K4에 세 가지를 정했다. 경계는 칠 Y와 그림자 Y의 중간값을 처음 지나는 화소다. 세는 범위는 경계 ±6 화소이고, 평균을 내는 창은 −11~−7과 +7~+11이다. 둘 다 생성 해상도 기준이다. Δ < 0.04면 재지 않으며, 범위를 뺀 셈은 쓰지 않는다. 잴 높이는 파츠 좌표와 높이 비율로 고정했다("재는 법"). 작업 3의 완료 확인에 "같은 그림을 두 번 재어 같다"를 더했다.
- **T3 (수용)**: "장 수와 승인"에 "몫을 쓰는 규칙"을 새로 넣었다.
  - 예비 몫은 N1에만 쓴다.
  - 다시 뽑기 몫은 다시 시험, 묶음의 기술 실패, 승인 C가 함께 쓴다. 쓴 만큼 C가 준다.
  - N1 호출은 최대 4, N3은 최대 3이다.
  - 몫이 0이면 B1·B2는 "가/다"뿐이다.
  - 작업 4의 완료 확인은 "호출 수 ≤ 2" → "N1 호출 ≤ 4, 몫의 쓰임 기록"으로, 작업 5에는 몫마다 쓴 수를 더했다. 결정 198도 고쳤다.
- **디자인 검토의 비차단 제안 (수용)**: 무대 N3을 무대 화풍의 시험으로 앞당겼다. N3은 Q1이 승인한 "시험 한 장"이 아니므로 바로 돌리지 않는다. 승인 B1에서 N2·N3·N6·N7을 승인받고, N3 뒤에 새 **승인 B2**에서 사용자가 `g-stage-alley`와 `cmp-stage`의 뒷골목 줄을 보고 N4·N5 / 다시 시험 / 그만을 고른다. 장 수는 그대로 10이다.
  - 이에 따라 고친 곳: 승인 표(B → B1·B2), 묶음의 차례(N2 → N3 → N6 → N7, 다음 N4 → N5), "묶음 안의 멈춤"(무대는 B2로 옮기고 의뢰인 규칙만 남김), 작업 4·5, 결정 198, 위험 2·8, 작업 8의 기록 항목, 화풍 판정 머리와 기준 맞추기의 알림 자리.
- **기술 검토의 비차단 의견 (수용)**: F11의 세션 기록 Grep은 `"type":"custom_tool_call"`(또는 `function_call`)이면서 `tools.image_gen__imagegen(`을 담은 줄만 본다("절차"의 더하는 확인).
- **사용자 답 Q1 "가"**: "실행 전에 물을 것"에 답을 받았다고 적고, v1의 물음은 기록으로 남겼다. 승인 A의 때를 "작업 3 뒤 바로"로 정했다(승인 표, 작업 4).
- 차단과 별개로 바꾼 것: 없다.
