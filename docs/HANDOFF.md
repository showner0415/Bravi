# 인수인계 — 2026-11-23 계획 033 1부를 실행한 뒤(2부 확인과 판 N 전)

이 파일은 새 세션이 읽고 이어 가기 위한 것이다. 사용자가 "계획 계속 진행해줘"라고 하면 이 파일의 "1. 바로 다음에 할 일"부터 시작한다. 이어 받은 세션은 일을 마칠 때마다 이 파일을 지금 상태로 고치거나, 더 필요 없으면 지운다.

- 브랜치: `stage2-day-loop-v2`
- 계획 030·030b·030c를 한 커밋으로 올렸다(2026-11-23, 사용자 "커밋해". 플레이 확인 9판보다 먼저). 계획 031·032의 1부를 한 커밋으로 올렸다(2026-11-23, 사용자 "작업 끝나면 일단 커밋". 실행 확인 전). 원격에는 계획 026(`1643e9b`)까지 올렸다(027~030c는 로컬 커밋만).
- 로컬에만 있는 것(저장소에 올라가지 않는다): 참고 자리 `docs/style/reference/`(손 모양 사진 `레이피어 파지.png`와 `레이피어참조.jfif`가 있다. 결정 178·179로 올리지 않는다), 생성 그림 `docs/style/generated/`(021~027의 그림 전부, 손질본 `cut/`, 넣은 그림 `in/`), 글꼴 `docs/style/generated/fonts/`(약 71MB), 옛 도구 `docs/style/generated/tools-before-028/`(물린 자리. 022~024의 옛 도구 일곱도 여기). 판정 도구는 저장소의 `docs/style/tools/`에 있다. 기준 이미지 여덟 장은 `docs/style/basis/`, 게임 애셋은 `assets/`(목록 `assets/MANIFEST.md`).
- 멈춘 때의 상태: 돌고 있는 하위 에이전트와 명령이 없고, 중간에 끊긴 수정도 없다.

## 1. 바로 다음에 할 일

**계획 033(글꼴과 필사본 UI, `docs/plans/033-type-and-manuscript-ui.md` v3, 검토 2회, 두 관점 승인) 1부를 실행했다(2026-11-23, 결정 312~325). 2부(playtester의 테스트 76/76·찍기 `run_ui_shots` → 견본 025와 나란히 댄 판 N → N1 질감 "코드 그대로 / 그림으로(033b)", N2 견본처럼 보이는가, N3 엉킴 테두리)가 남았다. N2가 "맞다"이기 전에는 033을 끝났다고 보지 않는다. 견본 굽기는 `docs/style/tools/bake025.ps1 -Shots @('ui-duel+ui=b', …)`, 구운 장과 좌표 표는 `%TEMP%\bravi-style\033\samples\`·`sample-rects.txt`, 고치기 전 사본은 `%TEMP%\bravi-style\033\before\`. 031·032 2부는 확인했고(75/75) 판 L·M2의 답도 받았다(DECISIONS "2부의 판정"): 무대는 크게 다시 그린다(031b), 칼은 레이피어 꼴로 그린다(032b). 둘 다 033 뒤다. 031~033은 커밋하지 않았다.**

**계획 032(내 손, `docs/plans/032-player-hand.md` v4. v3 검토 2회 + 사용자가 허락한 추가 1회, 두 관점 승인) 1부를 실행했다(2026-11-23, 결정 301~311). 보고서 `docs/reports/032-player-hand.md`. 손 그림은 사진의 쥔 손을 따른 H1h(`docs/style/basis/player-hand.png`, 사용자 "H1h로 확정"), 판 M1 답 M1-1 "가"·M1-2 "이대로", 게임 애셋 `assets/art/player/hand.png`(1125×2262). 다음: 사용자가 하라고 하면 031·032 2부를 한 번의 playtester 확인으로(테스트 75/75, 스모크, `run_opponent_shots -Stages`·`run_stage_shots`·`run_hand_shots` 찍기) → 판 L → 판 M2. 031·032 1부는 커밋했다(2026-11-23 사용자 "작업 끝나면 일단 커밋"). 판 M1·후보는 로컬 `%TEMP%\bravi-style\032\`(`board-M1-hand-v4.png`, `cand.txt`, `measure-H1h.txt`).**

**계획 031(결투 무대 셋, `docs/plans/031-duel-stages.md` v3, 검토 2회, 두 관점 승인)의 1부를 실행했다(결정 294~300, 커밋 전). 보고서 `docs/reports/031-duel-stages.md`. 다음: 사용자가 하라고 하면 031 2부(작업 9 playtester 확인 → 작업 10 판 L과 L1~L4 → 작업 8의 2부 줄). 1부의 코드·데이터·테스트·찍기 씬은 실행 없이 정적 확인만 받았다(위험 R6). 되돌릴 곳: `%TEMP%\bravi-style\031\before\`(열네 파일)과 `git diff b775927`, 무대 그림은 기준 그림에서 `cutstage.ps1`로 다시 자른다.**

**4단계(아트 교체) 진행 중. 계획 030c(레이피어 쥐는 법과 겨누기, `docs/plans/030c-rapier-grip-and-poses.md` v3, 검토 2회, 두 관점 승인)를 실행했다(결정 282~293, 판 I·J·K의 답 "나·나1·나", "올린다", "맞다". 2부의 playtester 확인 통과). 보고서 `docs/reports/030c-rapier-grip-and-poses.md`. 030b는 030c로 닫았다. 다음: 사용자의 플레이 확인 9판(030 작업 13: `$env:BRAVI_CURVE_CHECK = "1"`, 기록 `%APPDATA%\Godot\app_userdata\Bravi\curve_check.csv`, 세기 `tests/curve_check_report.ps1`), 031. 030·030b·030c는 커밋했다. 판 F는 "맞다 — 지금대로"(2026-11-23).** 030의 보고서는 `docs/reports/030-separate-arms.md`. 028 보고서는 `docs/reports/028-tools-in-repo-and-bartolo-parts.md`, 4단계 나눔(028~037)의 제안은 그 계획의 "4단계 나눔".

- 030c의 확인(2026-11-23 playtester): 테스트 `ALL PASS 72/72`, 스모크 OK, 찍기 57·28장(`%TEMP%\bravi-030c-shots`, `-sil`), 게임 창 여섯 장면. 판 F(030c 찍기)는 "맞다 — 지금대로". 030 전으로 되돌릴 곳은 커밋 `057928d`, 030c 전(030·030b 상태)으로는 로컬의 애셋 백업 `%TEMP%\bravi-style\030b\backup\`(030의 열일곱 장), 고치기 전의 파일 사본 `%TEMP%\bravi-style\030c\before\`.

- 바이블 16절의 사용자 결정은 그 일을 하는 계획을 시작할 때 묻는다(029 전에 포즈와 해상도를 한 선택 창에서, 033 전에 그린 질감). 포즈를 물을 때는 026 견본의 "지금 게임"과 "어깨 회전 · `hold`"를 그림으로 나란히 보이고 바이블 11절의 R2(지금 게임 큰 베기 0.317, 문턱 0.10)를 곁들인다.
- 사용자의 지시(2026-11-22): "계속 진행해줘. 내가 꼭 결정해야되는게 있으면 선택할 수 있는 창 띄워." → 묻는 것은 꼭 필요한 것만 선택지 도구로. **고칠 거리는 글로 받는다**. 좌우·방향처럼 말이 어긋나기 쉬운 것은 처음부터 두 안을 크게 나란히 그려 고르게 한다(바이블 13.7).
- **쓸 수 있는 것**:
  - 견본: `027-bible.html`(한 장 보기), `026-pose-motion.html`(포즈·움직임·따로 그린 팔), `025-type-ui-size.html`(글꼴·UI), `024-widen.html`.
  - 도구: `docs/style/tools/`(쓰는 법은 그 폴더의 `README.md`). 작업 폴더는 `BRAVI_STYLE_WORK`(없으면 `%TEMP%\bravi-style`). 명령은 작은 감싸개 `.ps1`에 적어 `-File`로 띄운다(따옴표·`$`의 펼침 문제를 피한다).
  - 바르톨로 파츠 열 장: `assets/art/opponents/bartolo/`(관절·배율은 `assets/MANIFEST.md`).
  - 그림 생성의 절차와 막는 장치: 바이블 13.5와 `docs/style/GENERATION.md` "절차".

playtester가 오류를 보고하면: 018·019 보고서의 "가리는 순서"로 가리고, 고칠 것이 범위·규칙을 바꾸지 않는 오류면 고쳐서 보고한다. 범위나 규칙이 바뀌면 CLAUDE.md 11장의 수정 절차를 따른다.

## 2. 실행 확인

- **계획 029가 처음으로 게임 코드를 고쳤다(상대 뷰·데이터·셰이더·테스트). 2026-11-22 playtester가 세 번 확인했다: 마지막에 `ALL PASS 68/68`, 스모크 OK, 찍기 41장(헤드리스·창) OK, 게임 창 로그 오류 0. 결과는 `docs/reports/029-bartolo-in-duel.md` 2번.** 계획 020~028은 게임 코드를 바꾸지 않았다(028은 `assets/`에 그림 열 장을 더했다). 2026-11-22 playtester가 028 뒤를 확인했다: 65/65, 스모크 OK, 파츠 열 장 가져오기 OK(`docs/style` 아래 `.import` 0), 게임 흐름 그대로. 022~027 뒤에는 실행 확인을 하지 않았다(024 보고서 2번에 playtester에게 맡길 확인 둘이 있다: `docs/style/basis/`를 Godot이 가져오지 않는지, 테스트 65/65)(생성 그림 한 장과 스케치가 `docs/style/generated/`에 더 들어왔을 뿐이다). 2026-11-21 playtester가 021 뒤를 확인했다: `.gdignore`가 듣는다(`docs/style` 아래 `.import` 0, `.godot/imported/`에 생성 그림 0), `ALL PASS 65/65`, 스모크 OK, 게임 창의 카운터→결투→정산이 전과 같다. 결과는 `docs/reports/021-style-detail-and-generation.md` 끝.

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
- 계획 023 보고서 4번: 답을 받았거나 024가 정했다(022·023은 커밋 `14ac99a`, 팔레트는 확정, 대기 자세와 바르톨로의 성격은 024 보고서 4번으로).
- 계획 030 보고서 4번: 판 G(→ 030b → 030c가 받았다), 플레이 확인 9판과 그 물음, 판 F(030c 찍기로 "맞다 — 지금대로". 원문은 플레이 뒤), 030 커밋, 031 시작.
- 계획 030c 보고서 4번: 판 K는 "맞다"(2026-11-23). 판 F "맞다 — 지금대로". 남은 것: 플레이 확인 9판, 030·030b·030c 커밋, 031. 재는 도구의 손질 하나는 `docs/BACKLOG.md` 030c-1.
- 계획 029 보고서 4번: 판 넷은 모두 "맞다"(판 C는 손의 테두리만 030에서). 029 "커밋한다", 030 "시작한다"(2026-11-22).
- 계획 028 보고서 4번: 모두 답을 받았다(커밋, 포즈 옮기기, 해상도 1920, playtester 확인 통과).
- 계획 027 보고서 4번: 027의 커밋, 3단계 완료 판정(나중에), 든 팔 주먹의 그림자(4단계로), 판정 도구를 저장소에 올릴지, 바이블 16절의 사용자 결정.
- 계획 026 보고서 4번: 024·025·026의 커밋, 고른 포즈와 곡선을 4단계에서 그대로 옮길지, hold 곡선의 반응 싸움 확인(4단계 플레이), 든 팔(1번)의 주먹 그림자가 왼쪽(명세는 오른쪽).
- 계획 025 보고서 4번: 024·025의 커밋, 해상도의 기준(1920×1080)과 4단계의 일, 그린 질감, 송명의 글자 수(2,350), 글자 크기 옮기기와 HUD의 자리.
- 계획 024 보고서 4번: 024의 커밋, 대기 자세 가·나·다(4단계), 바르톨로의 대사와 얼굴(6단계), 큰 베기의 예비 동작에서 든 팔이 얼굴을 가리는 것(4단계), 025의 범위(026과 합칠지).
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
