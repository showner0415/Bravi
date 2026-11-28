# 보고서 054: 의뢰인 그림 셋 — 양봉가 체칠리아 · 젊은 백작 레안드로 · 세탁부 넬라

- 계획: `docs/plans/054-client-portraits.md` v2. 2주차 콘텐츠 묶음(052)의 054 줄 — 옛 046b. 카운터의 마지막 색 도형 셋이 제 그림을 얻어 열셋의 의뢰인이 모두 그림으로 선다(052 완료 기준 4).
- 일하는 방식: 그 세션에서는 묻지 않고 이어 갔고, 사용자가 고를 것(장 수, 판의 판정, 문턱, 다시 그리기)을 메인이 대신 골랐다(사용자 위임 2026-11-27). 대신 고른 것은 4번과 `docs/DECISIONS.md`의 054 절.
- 검토: 2회. 1회차 디자인 REVISE(D1 · D2) · 기술 APPROVE(비차단 넷) → v2 → 2회차 디자인 APPROVE · 기술 APPROVE.
- 상태(2026-11-28): 그림 · 데이터 · 테스트 · 문서 · 확인 끝. 코드(`scripts/`) 0줄. 확인(verifier — 테스트 167/167, smoke, UI 46장, 카운터 찍기 열 장)은 2번. 찍기 도구의 헤드리스 길 하나가 054 전부터 돌지 않는 것을 찾았다(BACKLOG 054-2 → 057).

## 1. 한 일

- **그림 넷**(쓴 장 4 / 몫 5, 다시 그리기 1, 053b에서 빌린 것 0): C1a 체칠리아 · L1a 레안드로 · N1a 넬라(받지 않음 — 눈썹이 안쪽이 내려간 V자, 화남으로 읽힘) · N1b 넬라(N1a + 눈썹의 `Change:` 한 줄, 넣는 그림은 같은 스케치). Codex `gpt-6.2-sol` · `high` · read-only, 막힌 호출 0, 네 호출 모두 `git-before.txt` · `git-after.txt`가 같았다. 기록은 `docs/style/GENERATION.md` "계획 054".
- **판 D0**(생성 0장): 견본 `docs/style/samples/054-clients.html`(034의 손 — 220×390 틀, 선 5.2, 층을 뒤에서 앞으로)과 재는 도구(작업 폴더 `%TEMP%\bravi-style\054\lib054.ps1` — 분류 · 얼굴 상자 · 머리 위 덩이(원래 자와 덩이 자) · 어깨 줄 · 소품의 긴 축 · 팔뚝 · 구멍 · 틀 · key 장의 분류 확인 · 눈썹 기울기). 작업 0이 열하나의 애셋을 같은 자로 쟀다(`measure-T0.txt`). 넬라의 스케치는 판의 답으로 두 번 고쳤다(머릿수건을 천으로 — 목덜미 쪽 매듭과 두 끝 · 입을 0.6배).
- **명세 · 바이블**: 팔레트 9줄(체칠리아 · 레안드로 · 넬라의 대표 면과 딸린 면), 표정 표 세 줄(실눈 · 질색 · 억울함), 명세 "계획 054의 줄"(공통 + 사람마다 C1a · L1a · N1a · N1b), 바이블 4절의 의뢰인 문단 · 8절 · 13.3의 의뢰인 줄.
- **올림**: `docs/style/basis/client-cecilia.png` · `client-leandro.png`(원본), `assets/art/clients/cecilia.png` · `leandro.png`(450×675, `.png.import` 밉맵 끔), `docs/style/basis/README.md` · `assets/MANIFEST.md`의 줄. 넬라(N1b)는 판 D3의 판정(결정 871d) 뒤에 올렸다: `docs/style/basis/client-nella.png`(N1b 원본), `assets/art/clients/nella.png`(+ `.import`), README · MANIFEST의 줄(N1a를 받지 않은 까닭 포함).
- **데이터 · 테스트**: `data/commissions/variants/court_beehive.tres` · `noble_baker.tres` · `washer_ledger.tres`에 `client_portrait`(ext_resource `6_portrait`, `load_steps` 7 → 8). `tests/counter_art_tests.gd` — T77의 `PORTRAITS` 세 줄 · `NO_PORTRAIT := []`, 새 **T167**(① `client_name` ↔ 그림 파일이 서로 한 값 — 역방향은 그림 없는 의뢰를 뺀다, ② 쓰지 않는 그림은 INFO(지금 `cornelia.png` 하나 — 057이 건다), ③ 새 셋의 틀 — `is_compressed()`면 풀고 위 두 모서리 알파 0 · 위 4줄 · 위쪽 450행의 좌우 4열 불투명 0). `tests/week_tests.gd` 380행(T159 — 넬라의 그림이 `nella.png`), `tests/ui_shots.gd` 599 · 608행의 장 설명("색 도형" → "그림"), `tests/client_shots.gd`(세 장)과 `tests/run_client_shots.ps1`(`$count` 10, 머리 주석). `tests/run_tests.gd`는 그대로다(T167이 `counter_art_tests`에 든다). 테스트의 합 166 → **167**.
- **문서**: `docs/DECISIONS.md` 054 절(결정 863~878과 실행 줄 863a · 865a · 867a~867d · 868a · 871a~871d), `CLAUDE.md` 4장(`client_portrait` 줄) · 9장(054 줄), `docs/HANDOFF.md`(1번 · 3번 판 W2-D), `docs/BACKLOG.md`(046-1 · 049-1 닫음, 054-1), `docs/style/GENERATION.md` "계획 054", 계획의 결정 863(빌림 1장) · 레안드로 표지(덩이 자) · 판 W2-D-1.

바뀐 저장소 파일: `CLAUDE.md`, `assets/MANIFEST.md`, `assets/art/clients/cecilia.png`(+ `.import`), `assets/art/clients/leandro.png`(+ `.import`), `data/commissions/variants/court_beehive.tres` · `noble_baker.tres` · `washer_ledger.tres`, `docs/BACKLOG.md`, `docs/DECISIONS.md`, `docs/HANDOFF.md`, `docs/STYLE_BIBLE.md`, `docs/plans/054-client-portraits.md`, `docs/reports/054-client-portraits.md`, `docs/style/GENERATION.md`, `docs/style/STYLE_SPEC.md`, `docs/style/basis/README.md` · `client-cecilia.png` · `client-leandro.png`, `docs/style/prompts/054-C1a-client-cecilia.txt` · `054-L1a-client-leandro.txt` · `054-N1a-client-nella.txt` · `054-N1b-client-nella.txt`, `docs/style/samples/054-clients.html`, `tests/client_shots.gd`, `tests/counter_art_tests.gd`, `tests/run_client_shots.ps1`, `tests/ui_shots.gd`, `tests/week_tests.gd`, `assets/art/clients/nella.png`(+ `.import`), `docs/style/basis/client-nella.png`, `.claude/agents/verifier.md`(차례표 `-MaxWaitSec` 150 → 100 — 아래 2번).

## 2. 직접 실행해서 확인한 것 / 확인 못 한 것

메인은 Godot · 테스트를 돌리지 않는다. 그림의 굳은 확인은 작업 폴더의 재는 도구로 했다.

| 판 | 무엇 | 결과 |
|---|---|---|
| D0 | 셋의 스케치(`measure-D0.txt`) | 얼굴 높이 · 대표 면 · 틀 · 구멍 · 얼굴 상자 안 소품 · 분류 확인 모두 넘음. 레안드로 가발은 덩이 자로 1.793(원래 자 2.870은 넘을 수 없다 — 결정 871a) |
| D1 | 체칠리아 C1a(`measure-D1.txt`) | 얼굴 높이 0.843(띠 0.85 — 적고 받음, 결정 871b) 말고 모두 넘음 |
| D2 | 레안드로 L1a(`measure-D2.txt`) | 어깨 줄 1.289 Fw(문턱 1.165 — 자의 줄이 허리에 짚은 팔꿈치를 잡았다, 적고 받음, 결정 871c) 말고 모두 넘음 |
| D3 | 넬라 N1a(`measure-D3-N1a.txt`) | 눈썹 −9.1 / −8.3px(안쪽이 낮다 — 화남). 받지 않음(결정 867c) |
| D3 | 넬라 N1b(`measure-D3-N1b.txt`) | 눈썹 +12.6 / +12.1px(안쪽이 높다), 입 안 밝은 화소 0, 팔뚝(굵은 쪽) 62.9px, 방망이 1.254 Fh 등 모두 넘음 — 머릿수건 솟음 0.370(문턱 0.35) 하나만 걸림 — 천 머릿수건으로 읽혀 적고 받음, 올림(결정 871d) |
| D4 | 게임의 카운터 찍기와 열넷의 나란히 | 넘음 — `counter-cecilia` · `-leandro` · `-nella`(`%TEMP%\bravi-style\054\shots`)에서 그림이 이름 아래 틀 안에 서고 말풍선과 겹치지 않는다. 체칠리아의 챙이 가장 넓지만 틀 안. 열넷의 나란히는 판 D3의 첫째 · 둘째 줄 |

verifier의 확인(공용 차례표 `tests/wait_turn.ps1`, 이름 `main-054-verify`, 한 호출 3분 안). 첫 verifier는 줄 앞의 다른 세션(H02 테스트 중 · H03 대기)을 기다리다 호출이 백그라운드로 넘어가 차례를 받지 못하고 반납했다 — 메인이 같은 이름으로 줄에 서서(백그라운드 대기) TURN을 받은 뒤 둘째 verifier가 돌렸다. 그 뒤 `.claude/agents/verifier.md`의 차례표 대기를 `-MaxWaitSec 100`으로 줄였다.

- V1 테스트: 가져오기 포함 `counter_art_tests,stage6_tests` **3/3**(가져오기 오류 0, T167의 `INFO` 줄은 `cornelia.png` 하나 — 기대), 이어서 `-SkipImport` 조각 열 — hold 4/4, client_line · stage · reputation · day · second · fifth · sixth · eighth 32/32, pair · court_noble · spar · third · seventh · style · save · opening_chance 30/30, project · core · commission · scene · flow · part · bind · lunge 41/41, haggle · safety · tidy · opponent_art · curve_check · hand · manuscript · pattern · pattern_cell · painted_ui 25/25, settings · pause · controls · display · part_effect · practice_screen · fourth · state_hint · mark_shape 24/24, feint 2/2, withdraw 1/1, week 4/4, cover 1/1 — 합 **167/167**, 오류 · 경고 줄 0.
- V1 그 밖: `verify.ps1 -Only smoke` OK(DAY SMOKE OK), `verify.ps1 -Only ui` OK(UI SHOTS OK 46, 1280×720 — 법정 · 귀족 · 빨래터의 카운터 장이 그림으로 바뀐 것이 기대된 변화). `cecilia.png.import` · `leandro` · `nella`에 `uid=`(가져오기가 더했다)와 `mipmaps/generate=false`.
- V2 찍기: `run_client_shots.ps1 -Shots "%TEMP%\bravi-style\054\shots"`(창) **RESULT OK**(CLIENT SHOTS OK 10, 1280×720, 오류 0), `portrait,` 열 줄 모두 `80,120,300,450`.
- **V2 헤드리스 길은 실패**: `run_client_shots.ps1`(`-Shots` 없이)이 두 번 다 `RESULT: FAIL (no "CLIENT SHOTS OK 10" line)` — `client_shots.gd:73`의 `Cannot call method 'get_width' on a null value`와 엔진의 `Parameter "t" is null`(texture_2d_get, 더미 렌더러). 헤드리스에서 뷰포트 텍스처의 `get_image()`가 null인 것이고 70~73행은 034 그대로라 054가 만든 실패가 아니다(054는 장 셋과 `$count`만 바꿨다). 확인 몫은 창 길이 다 했다. 도구 고침은 `client_shots.gd`를 어차피 건드리는 057로 넘긴다(BACKLOG 054-2).
- 확인 못 한 것: 게임 창에서 셋이 미끄러져 들어오는 모습과 정산 화면(판 W2-D에서 사용자가 본다).

## 3. 설계 문서와 다르게 구현한 부분과 이유

- **레안드로 가발의 문턱**: 계획은 "열하나의 머리 위 덩이 ÷ 얼굴 폭의 최대 × 1.15"였으나 그 최대가 베아트리체의 모자핀(2.496 Fw)이라 넘을 수 없었다(계획의 멈춤 경우). 7×7로 연 가장 큰 덩이로 재는 덩이 자(최대 토마소 1.418 → 1.631)로 바꿨다(결정 871a).
- **팔뚝의 자**: "얼굴 밖의 가장 큰 살 덩이"가 두 팔이 비슷할 때 흔들려 두 팔 가운데 굵은 쪽으로 판정했다(결정 867d).
- **넬라의 스케치를 생성 전에 두 번 고쳤다**(머릿수건 · 입 — 결정 867a · 867b)와 **넬라를 한 장 다시 뽑았다**(N1b — 결정 867c). 표정 표의 억울함 줄도 고쳤다.
- **구도 셋째 항목**에 사람마다 틀 안에 둘 것(챙의 양 끝 · 가발 · 머릿수건과 방망이)을 덧붙였다(053b의 길. 계획은 E1a 그대로라 했다).
- **`.png.import`를 미리 썼다**(밉맵 끔 — 053b의 꼴). 계획 결정 874는 Godot이 쓰게 두라 했으나 메인의 지시를 따랐다.
- **재는 도구**: 계획이 이름 붙인 새 스크립트 일곱(`mFace` 등)을 한 라이브러리 `lib054.ps1`의 함수로 모았다. "4단위 안의 선"은 450에서 6px로 잡았다.

## 4. 사용자가 결정해야 할 것

없다 — 메인이 대신 골랐다(사용자 위임 2026-11-27). 손 · 눈이 있어야 아는 것은 **판 W2-D**(HANDOFF 3번, W2-D-1~6)에 모았다: 셋의 그림(체칠리아의 망사 판이 통처럼 넓다, 레안드로가 허리에 짚은 몸짓이 가스파로와 같다, 실루엣의 가발 덩이), 씨앗에서 바뀐 넷과 그리지 않은 둘, 표정(실눈 · 질색 · 억울함), 색, 소품, 몫. 메인이 적고 받은 둘(체칠리아의 얼굴 높이 0.843, 레안드로의 어깨 줄 1.289)과 넬라 N1b의 머릿수건 솟음 0.370도 그 판에서 본다.

## 5. 다음 작업 제안

- 052의 차례대로 **056(세라피나의 도전장 — 경쟁 의뢰소의 대리인이 직접 도전장을 들고 온다, 결정 818)**. 체칠리아 · 레안드로 · 넬라가 2주차에 다시 설 때는 같은 그림을 건다(T167이 지킨다).
- 057이 `cornelia.png`를 그녀의 의뢰에 걸면 T167의 `INFO` 줄이 사라진다.
- 다음에 의뢰인을 그리는 계획이 오면 BACKLOG 054-1(재는 도구를 `docs/style/tools/`로, 어깨 줄과 팔뚝의 자를 고친다).
- 057은 BACKLOG 054-2(찍기 도구의 헤드리스 길)를 함께 고친다.

라운드 2 · 최종 판정: 디자인 APPROVE · 기술 APPROVE.
