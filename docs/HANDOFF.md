# 인수인계 — 2026-11-22 계획 023을 닫은 뒤

이 파일은 새 세션이 읽고 이어 가기 위한 것이다. 사용자가 "계획 계속 진행해줘"라고 하면 이 파일의 "1. 바로 다음에 할 일"부터 시작한다. 이어 받은 세션은 일을 마칠 때마다 이 파일을 지금 상태로 고치거나, 더 필요 없으면 지운다.

- 브랜치: `stage2-day-loop-v2`
- 2단계(계획 004~019), 사용자의 playtest 장치(`7c718b3`), 계획 020·021(`9909fb9`)까지 커밋했다. **계획 022와 023의 변경은 커밋 전이다**(사용자가 지시하면 커밋한다). 원격에는 올리지 않았다(원격에는 계획 015까지 있다).
- 로컬에만 있는 것(저장소에 올라가지 않는다. 다른 컴퓨터에서 이어 받으면 사용자가 따로 옮긴다): 참고 스크린샷 자리 `docs/style/reference/`(비어 있다), 생성 그림 `docs/style/generated/`(021의 일곱 장, 022의 N1, 023의 열한 장, 손질본 `cut/`, 넣은 그림 `in/`), 도구 스크립트 `docs/style/generated/tools/`.
- 멈춘 때의 상태: 돌고 있는 하위 에이전트와 명령이 없고, 중간에 끊긴 수정도 없다.

## 1. 바로 다음에 할 일

**3단계(스타일 바이블) 진행 중. 계획 023을 닫았다(2026-11-22 사용자: "둘 다 맞아. 023 닫고 보고서 써줘"). 다음은 새 계획 024: 고른 길로 넓히기.** 보고서는 `docs/reports/023-style-transfer-new-drawing.md`. planner에게 아래를 넘겨 계획을 쓰게 한다(CLAUDE.md 11장. 검토는 계획마다 최대 2회). 먼저 보고서 4번의 답(024의 범위와 장 수 상한, 커밋)을 사용자에게 받는다.

- **사용자가 고른 만드는 길**(결정 209. `docs/style/STYLE_SPEC.md` 머리):
  1. 섞은 SVG 견본(`generated/in/022-in-*`)을 화풍의 참고 그림으로 넣어 새로 그린다.
  2. 꼴과 디테일의 양은 섞은 SVG만큼 단순하게. 올리는 것은 만듦새(비례, 이음매, 손).
  3. 디테일은 조금만: 고른 그림을 바탕 그림으로 넣고 "실루엣은 그대로, 안쪽에 이것만"(P-KEEP·S-KEEP).
  4. 전신 그림은 여유롭게 결투에 임하는 자세, 팔다리는 굽히지 않는다. 표정은 자신 있는 미소(거만해 보이면 안 된다).
  5. 선은 섞은 SVG의 굵기(5.0~5.6), 바지는 `#836850`.
- **기준 그림**(로컬): 인물 `generated/023-R1i-bartolo-front.png`, 무대 `023-R2-stage-alley.png`, 의뢰인 `023-R3-client-clara.png`. 프롬프트는 `docs/style/prompts/023-R1h`·`R1i`·`R2`·`R3`. 사용자의 답 원문은 `docs/DECISIONS.md` "계획 023"의 "실행 중에 정한 것".
- **024가 할 것**(결정 201, 보고서 5번): 바르톨로 파츠 시트(R1i를 바탕 그림으로. 정면, 떨어진 팔) → 잘라서 상태 넷·멀리 확인(023에서 못 한 것) → 무대 둘(안뜰·광장) → 비토리오 → 기준 이미지 고르기와 `docs/style/basis/`로 올리기 → 팔레트 확정(바지, 비토리오의 옷 Y 0.33).
- **023에서 배운 것**:
  - 꼴은 말보다 그림이 옮긴다. 말만으로는 둥글둥글하거나(R1a·R1b) 각지게(R1c) 나왔다.
  - 섞은 SVG를 넣어도 자세를 다르게 주고 "베끼지 말라"고 적으면 따라 그리지 않는다(022 N1과 다르다).
  - 고칠 것은 한 번에 하나씩, 바탕 그림을 넣어 고친다. 사용자는 그림을 보고 나서야 원하는 것을 말할 수 있었다(아홉 장). 승인은 그림 묶음마다 받고, 장 수 상한은 넉넉히 묻는다(상한 8에 11장을 썼다).
  - 선택지 도구(AskUserQuestion)가 두 번 거부되었다. 사용자가 "선택지 다시"라고 하면 글로 묻는다.
  - 재는 값: R1e·R1f의 K2′ 걸림은 앞으로 나온 팔 탓이었다(굳은 정면 자세용의 재는 자리).
- **쓸 수 있는 것**:
  - 도구(로컬 `docs/style/generated/tools/`): `bake023.ps1`(굽기. `-Shots fig-duel@R1i`처럼 `?pick=`을 준다), `run-codex.ps1`(`-Plan 023 -G R2 -Name stage-alley -Images … -Phrases …`), `calib023.ps1`(`-FrontPath … -Pel x,y -Ppu …` / `-ClientPath` / `-StagePath`), `kmeasure.ps1`(K2′·K3′ 포함), `measure.ps1`·`scan.ps1`·`lum.ps1`·`tintcheck.ps1`. 스크립트 안의 scratchpad 경로는 앞 세션의 것이라 새 세션의 scratchpad로 고쳐 쓴다(`bake023`·`calib023`·`run-codex`). `calib023.ps1`은 다른 스크립트를 scratchpad의 `tools\`에서 찾는다. 한글 주석이 든 `.ps1`은 BOM이 있어야 PowerShell 5.1이 읽는다. `GetPixel`로 넓은 면을 도는 재기는 2분을 넘긴다(컴파일한 C#으로 잰다).
  - 그림 생성의 절차와 막는 장치(결정 184·192): `docs/style/GENERATION.md` "절차". Codex가 도는 동안 저장소의 추적 파일을 고치지 않는다. 한 장에 약 1분, 4만 토큰, 5시간 창 +0.4% 안팎.
  - 견본: `docs/style/samples/023-redraw.html`(브라우저로 열면 로컬의 생성 그림이 보인다), `022-mix.html`, `021-detail.html`, `020-bridge.html`.

playtester가 오류를 보고하면: 018·019 보고서의 "가리는 순서"로 가리고, 고칠 것이 범위·규칙을 바꾸지 않는 오류면 고쳐서 보고한다. 범위나 규칙이 바뀌면 CLAUDE.md 11장의 수정 절차를 따른다.

## 2. 실행 확인

- 계획 020~023은 게임을 바꾸지 않았다. 022·023 뒤에는 실행 확인을 하지 않았다(생성 그림 한 장과 스케치가 `docs/style/generated/`에 더 들어왔을 뿐이다). 2026-11-21 playtester가 021 뒤를 확인했다: `.gdignore`가 듣는다(`docs/style` 아래 `.import` 0, `.godot/imported/`에 생성 그림 0), `ALL PASS 65/65`, 스모크 OK, 게임 창의 카운터→결투→정산이 전과 같다. 결과는 `docs/reports/021-style-detail-and-generation.md` 끝.

- **계획 018·019는 2026-11-21 playtester가 확인했다. 실패한 항목은 없다**(`ALL PASS 65/65`, 스모크 OK, 게임 창 확인 17개 통과).
  - 018이 바꾼 파일: `scripts/title.gd`, `scripts/day_ui.gd`, `scripts/commission/counter.gd`, `scripts/economy/settlement.gd`, `scripts/economy/closing.gd`, `scripts/save_store.gd`, `tests/safety_tests.gd`(새 파일, T60~T62), `tests/run_tests.gd`(한 줄), `tests/day_smoke.gd`(주석 한 줄).
  - 019가 바꾼 파일: `scripts/day_ui.gd`, `scripts/title.gd`, `scripts/commission/counter.gd`, `scripts/economy/settlement.gd`, `scripts/economy/closing.gd`, `scripts/economy/day_state.gd`, `scripts/economy/economy_rules.gd`, `scripts/game_session.gd`, `scripts/economy/reputation_rules.gd`, `tests/tidy_tests.gd`(새 파일, T63·T64), `tests/run_tests.gd`(한 줄).
- **계획 015·016·017은 2026-11-20 playtester가 확인했다. 실패한 항목은 없다**(`ALL PASS 60/60`, 스모크 OK, 게임 창의 확인 전부 통과). 결과는 `docs/reports/017-client-lines.md` 끝에 있다. 확인하지 못한 것 둘(015-9의 뒷부분, 이네스의 성공 판)도 거기에 있다. 아래 목록은 그 확인이 덮은 파일이다. 메인은 테스트와 게임을 직접 실행하지 않는다(아래 4번).

- 015: `scripts/economy/economy_rules.gd`, `scripts/economy/day_state.gd`, `scripts/commission/counter.gd`, `scripts/economy/settlement.gd`, `data/economy_rules.tres`, `tests/haggle_tests.gd`(T55)
- 016: `scripts/save_store.gd`(새 파일), `scripts/economy/day_state.gd`, `scripts/game_session.gd`, `scripts/title.gd`, `scripts/commission/counter.gd`, `scripts/economy/closing.gd`, `tests/save_tests.gd`(T56~T58), `tests/run_tests.gd`, `tests/day_smoke.gd`
- 017: `scripts/commission/commission.gd`, `scripts/economy/day_state.gd`(`settle()`의 두 줄), `scripts/economy/settlement.gd`, `scripts/commission/counter.gd`(`_refresh_haggle()`의 두 줄), `data/commissions/`의 일곱 `.tres`(더한 줄 26), `tests/client_line_tests.gd`(T59), `tests/run_tests.gd`(한 줄)
- 통과하면 테스트의 마지막 줄이 `ALL PASS 60/60`이다. 새 테스트 파일 셋은 한 번도 실행되지 않았다. 파싱 오류가 있으면 러너가 거기서 멈춘다.
- 계획 011~014는 2026-11-20에 playtester가 확인했다(`ALL PASS 55/55`, 스모크 `RESULT: OK`).

## 3. 사용자가 보류했거나 아직 답하지 않은 결정

고칠 거리(코드·화면)는 `docs/BACKLOG.md`에 있다. 여기는 값과 결정만이다.

값은 전부 지금 그대로 두고 있다. 사용자가 다시 말하기 전에는 건드리지 않는다.

- 계획 012 보고서 4번: 승리의 값(+1), 별에 따른 하루 결투 수, 궂은일을 맡는 값, 별이 차는 속도, 토마소를 못 해냈을 때의 합. 사용자가 "보류"라고 했다.
- 계획 013 보고서 4번: 기본 보수 덧붙임의 크기(±20%), 낮은 별의 깎임.
- 계획 014 보고서 4번: 100점 조건이 팁에도 걸리는 것, +30%와 의뢰인의 값.
- 계획 015 보고서 4번의 넷과 디자인 검토자의 의견 셋.
- 계획 016 보고서 4번: 하루를 다시 했을 때의 주사위, 읽을 수 없는 저장의 백업, 화면의 글과 자리, 하루를 다시 하는 길. ("새로 시작한다"를 빠르게 두 번 눌렀을 때는 계획 018이 고쳤다: 0.6초.)
- 계획 017 보고서 4번: 글 26줄의 문장, 성향 한 줄을 의뢰인별로 쓸지, 거절의 까닭, 정산의 글을 더 잘게 가를지, 이미 있던 21줄. (커밋은 016·017을 한 번에 했다.)
- 계획 018 보고서 4번: 폐점의 소지금 줄의 뜻과 정산·폐점의 평판 줄의 자리는 사용자가 "나중에"라고 해 `docs/BACKLOG.md`(018-F7·F8)로 옮겼다. 계획 019는 했다. 018의 커밋은 했다. 0.4초는 사용자가 직접 해 보고 괜찮다고 했다(2026-11-21). 남은 것: 0.6초("새로 시작한다"의 두 번째 누름).
- 계획 019 보고서 4번: 저장 실패 때 "저장했다"가 사라지기만 하는 것. (나중 목록의 자리는 사용자가 괜찮다고 했다. 019는 커밋했다.)
- 계획 020 보고서 4번: 답을 받았다(2026-11-21): 다리 B, 짙은 무대, 얼굴은 지금 크기, 극장 같은 무대는 싫다 → 야외(뒷골목·안뜰·광장). 그림은 메인이 Codex CLI로 만들고, 약관은 사용자가 게임에 써도 된다고 확인했다. 020은 커밋했다.
- 계획 021 보고서 4번: 답을 받았다(2026-11-21). SVG 화풍으로 다시 만든다(계획 022). 021은 커밋했다.
- 계획 022 보고서 4번: 022의 커밋(아직). 다음 계획으로 넘긴 물음 셋은 023에서 답을 받았다(선 굵기 "좋다", 게임 제약은 전신 그림에서 풀고 파츠 시트에서 지킨다, 바지는 밝힌다).
- 계획 023 보고서 4번: 022·023의 커밋, 024의 범위와 장 수 상한, 파츠 시트의 자세(대기 자세), 바르톨로의 성격과 표정, 임시 값 셋(바지 `#836850`, 선 굵기, R2의 기와 지붕).
- playtester가 올린 것(`docs/reports/014-counter-haggle.md` 끝): 정산과 폐점의 평판 줄이 패널 밖에 놓이는 것과 폐점의 소지금 표기(`소지금 -18 → -78`)는 `docs/BACKLOG.md`(018-F8·F7)로 옮겼다. `치료비 -0`은 018이 고쳤다. T53의 이름은 맞는 값이었다(고치지 않았다).
- `docs/plans/013-playtester.md`(사용자의 파일)의 번호 013이 `013-reputation-base-pay-and-fail-scale.md`와 겹친다. 정리할지 답을 받지 못했다.
- 사용자가 아직 플레이하지 않은 체크리스트: 013 보고서의 Q, 014의 R, 015의 S, 016의 T, 017의 U, 018의 V.
- 코드 주석 규칙(사용자 지시 2026-11-21): "왜"만 한 줄로. `CLAUDE.md` 10장 끝에 있다.

## 4. 작업 규칙 (사용자가 2026-11-20에 정한 것)

원래 컴퓨터와 계획 016을 실행한 컴퓨터의 메모리에는 들어 있다. 다른 컴퓨터의 세션은 여기서 읽는다.

- **메인 에이전트는 테스트와 게임을 직접 실행하지 않는다.** `tests/run_tests.ps1`, `tests/run_smoke.ps1`, 헤드리스 Godot, `play.ps1` 전부다. 모델과 상관없다.
- **실행 확인은 사용자가 요청할 때만 `playtester` 에이전트에게 맡긴다.** 스스로 띄우지 않는다. `playtester`는 Opus 5.5로만 돈다. 호출할 때 모델과 effort 인자는 생략해 에이전트 정의를 따른다(CLAUDE.md 11장). Opus 5.5로 돌 수 없으면 멈추고 까닭을 보고한다.
- 세션 모델이 Fable 5.2일 때는 어떤 방식으로도 테스트를 돌리지 않는다. Opus 5.5만 돌릴 수 있다. 세션이 Opus 5.5여도 메인은 직접 돌리지 않는다(위 규칙. 계획 017은 세션 도중 Opus 5.5로 바뀐 뒤에도 그렇게 했다).
- 그래서 계획의 완료 기준은 코드 읽기, Grep, 값 대조, 손 계산으로 잡고, 실행이 필요한 확인은 보고서의 "playtester에게 맡길 확인" 목록으로 적는다. 작업 보고(CLAUDE.md 10장)의 2번에는 돌리지 않은 확인을 "확인 못 한 것"으로 적는다.
- 스크립트를 실행 없이 고칠 때는 계획 012~016의 "공통 규칙"(기계적 확인 다섯 가지)을 따른다: 들여쓰기 Grep(탭만), 같은 함수 안의 이름 겹침, `:= .*\.get\(`와 `:= .*\[`의 타입 추론, 서식 문자열의 자리 수와 `%%`, `@warning_ignore("integer_division")`의 위치.
- playtester는 게임·테스트·스모크를 띄우는 명령마다 `$env:BRAVI_SAVE_PATH = "user://bravi_playtest_save.json"`을 같은 줄에서 건다(사용자의 실제 저장 `bravi_save.json`을 건드리지 않게. 계획 016).
- 사용자가 "NNN 계획 보고서"라고 하면 `docs/reports/`의 그 번호 파일을 그대로 보여 준다(예: "004 계획 보고서"는 `docs/reports/004-day-loop-skeleton.md`).
- 이 프로젝트를 만든 컴퓨터(Windows)에는 쓸 수 있는 Python이 없었다. 계산이 필요하면 셸이나 손 계산으로 했다.
- 계획 하나의 검토는 2회가 상한이다(CLAUDE.md 11장). 하위 에이전트가 큰 편집 도중 응답이 끊긴 적이 있어, planner에게 편집을 작게 나눠 하라고 부탁해 왔다.

## 5. 커밋에 넣지 않은 것

- `.codex/`와 `AGENTS.md`: 사용자의 파일이고 원래 컴퓨터에만 있다.
- playtester가 남긴 실행 로그와 화면 캡처: 저장소 밖의 임시 폴더에 있다.
