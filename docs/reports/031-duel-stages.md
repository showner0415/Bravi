# 계획 031 보고서 — 결투 무대 셋 (1부)

- 계획: `docs/plans/031-duel-stages.md` v3. 검토 2회(1회차 디자인 REVISE D1 · 기술 REVISE T1, 2회차 두 관점 APPROVE, 남은 차단 없음).
- 1부(실행 없이 되는 것)를 마쳤다. 사용자 답 "맡기되 일단 테스트하지 마"에 따라 테스트·스모크·찍기·게임 창은 돌리지 않았다. 2부는 사용자가 하라고 할 때 한다.

## 1. 한 일

- **작업 0**: HEAD `b775927`, 작업 트리 깨끗(계획 파일 하나). 기준 그림 셋의 해시(`%TEMP%\bravi-style\031\hash-before.txt`), 고칠 파일 열넷의 사본(`%TEMP%\bravi-style\031\before\`), 030c의 `pts.txt`가 있다.
- **작업 1**: 새 도구 `docs/style/tools/cutstage.ps1`. 무대 셋 `assets/art/stages/alley.png`(1536×864)·`court.png`·`piazza.png`(1524×857)를 줄이지 않고 잘라만 뒀다.
- **작업 2**: `scripts/duel/stage_data.gd`(`StageData`)와 `data/stages/alley.tres`·`court.tres`·`piazza.tres`.
- **작업 3**: `Commission.stage`. 의뢰 일곱 `.tres`에 무대를 걸었다(에밀리오·비토리오 광장, 클라라·가스파로·토마소 뒷골목, 이네스·오르솔라 안뜰).
- **작업 4**: 결투 씬 `Background/Stage`(TextureRect, 비율 지켜 덮기)와 `DuelScene._apply_stage`(의뢰의 무대 → 기본 뒷골목 → 없으면 바탕 색).
- **작업 5**: HUD 임시 손질(033까지). 모든 라벨에 짙은 테두리, 칸·막대 묶음 셋 뒤에 짙은 띠 `BandTopLeft`·`BandTop`·`BandBottomLeft`.
- **작업 6**: `tests/stage_tests.gd`(T72 무대, T73 HUD 띠)와 `run_tests.gd` 한 줄. 테스트는 72 → 74.
- **작업 7a**: `tests/opponent_shots.gd --stages`(무대 셋 × 일곱 장 = 21, 장마다 `ext,` 화면 상자)와 `tests/run_opponent_shots.ps1 -Stages`. 인자가 없을 때의 길은 그대로다.
- **작업 7b**: `tests/stage_shots.gd`·`.tscn`(1일차 의뢰 셋 × 간격 셋 = 9장, 장마다 `size,`·`scale,`)과 `tests/run_stage_shots.ps1`(`-Resolution`).
- **작업 8**: 문서.
  - `assets/MANIFEST.md` 세 줄.
  - `docs/DECISIONS.md` 294~300과 실행 중에 정한 것.
  - `docs/STYLE_BIBLE.md` 6·10·16절.
  - `docs/style/tools/README.md` 한 줄.
  - `CLAUDE.md` 4·8·9장, `docs/HANDOFF.md`, 이 보고서.

바뀐 파일:
- **고친 것**: `CLAUDE.md`, `assets/MANIFEST.md`, `data/commissions/` 일곱, `docs/DECISIONS.md`, `docs/HANDOFF.md`, `docs/STYLE_BIBLE.md`, `docs/style/tools/README.md`, `scenes/duel/duel.tscn`, `scripts/commission/commission.gd`, `scripts/duel/duel_hud.gd`, `scripts/duel/duel_scene.gd`, `tests/opponent_shots.gd`, `tests/run_opponent_shots.ps1`, `tests/run_tests.gd`
- **새로 만든 것**: `assets/art/stages/` 셋, `data/stages/` 셋, `scripts/duel/stage_data.gd`, `docs/style/tools/cutstage.ps1`, `tests/stage_tests.gd`, `tests/stage_shots.gd`, `tests/stage_shots.tscn`, `tests/run_stage_shots.ps1`, 이 보고서

## 2. 직접 실행해서 확인한 것 / 확인 못 한 것

메인은 그림 도구·`git`·PowerShell 구문 검사만 돌렸다. Godot·테스트·게임은 돌리지 않았다.

**확인한 것**

- **자르기(작업 1)**:
  - `-Verify` 셋 모두 `diff 0`. 크기는 1536×864 · 1524×857 · 1524×857이다.
  - 안뜰·광장의 위아래 세 행에 띠 색(원본 10·1013행의 RGB ±10)이 0%다.
  - 기준 그림 셋의 해시는 작업 0과 같다.
- **데이터(작업 2·3)**:
  - `.tres`의 `load_steps`가 자원 수 + 1과 같다(무대 셋 3, 의뢰 일곱 7). id 겹침 0, 경로가 모두 있다.
  - 의뢰 일곱의 무대가 결정 295의 표와 같다(의뢰인 이름과 함께 대조).
  - `git diff --stat`에서 의뢰 일곱은 각 +3/−1줄이다.
- **사본과의 대조**: `git diff --no-index`(열네 파일)가 계획의 줄뿐이다. `opponent_shots.gd`는 `--stages` 갈래와 `_shot`의 끝 인자(기본 −1)만 더해졌고, 인자 없이 지나는 줄은 그대로다.
- **판정 코드**: `duel_core.gd`·`scripts/ai/`·`opponent_motion.gd`의 `git diff b775927`이 0줄이다. 이들과 `opponent_view.gd`에 `StageData`는 0줄이다.
- **기계적 확인 다섯**:
  - 고친·새 GDScript 여덟 파일 모두 탭 들여쓰기이고, 이름 겹침이 없다.
  - 새 줄에 `:= …get(` / `:= …[` 추론은 없다(찍기 씬의 한 줄을 명시 타입으로 고쳤다).
  - 서식 문자열의 자리 수가 맞고, `warning_ignore`는 없다.
  - HUD `_ready`는 72줄(80 안)이다.
- **PowerShell**: `cutstage.ps1`·`run_stage_shots.ps1`·`run_opponent_shots.ps1`의 구문 오류가 0이고 모두 ASCII다.
- **바이블**: `check027.ps1`의 못 찾은 수가 0이다(V1·V2 밖·V3 23/23·V4·V7·V9). DECISIONS의 294~300은 하나씩이다.
- **손으로 셈한 기대 값**:

  | 무엇 | 값 |
  |---|---|
  | 무대 그림 크기(T72) | alley 1536×864, court·piazza 1524×857 |
  | 의뢰 → 무대(T72) | first_blood·first_blood_usurer → piazza, feather_cut·throw_bet·first_blood_poor → alley, throw_match·legs_only → court. 1일차(first_blood·feather_cut·throw_match) 세 곳이 다르다 |
  | 결투 씬의 무대(T72) | feather_cut → alley.png, throw_match → court.png, 의뢰 없음 → 씬이 쓴 의뢰의 무대 또는 alley.png |
  | 띠의 화면 사각형(T73, 앵커 × 1280×720 + 오프셋) | BandTopLeft (12, 6, 334×148) → x 12~346 · y 6~154, BandTop (0.5×1280 − 306 = 334, 6, 672×55) → x 334~1006 · y 6~61, BandBottomLeft (12, 720 − 156 = 564, 334×52) → x 12~346 · y 564~616 |
  | 조용한 구역 (433, 62, 414×621)과의 겹침 | 셋 모두 없다(346 < 433, 61 < 62) |
  | 띠가 덮는 것 | 상대 자세 글자·칸 x 340~940 · y 10~54, 방심 막대 x 850~1000 · y 36~58 → BandTop 안. 간격 글자·엉킴 막대·조건·충족도 x 20~330 · y 12~148 → BandTopLeft 안. 내 자세 y 570~614 → BandBottomLeft 안 |
  | 찍기 수 | `--stages` 3 × 7 = 21, `stage_shots` 3 × 3 = 9, 인자 없는 57·`-Sil` 28은 그대로 |
  | `scale,` 판정 | far 0.55 · mid 0.85 · close 1.1, ±0.01 |

**확인 못 한 것(2부)**:
- 테스트 74개(T72·T73 포함)와 스모크.
- 무대 그림 셋의 가져오기(`.import`의 uid, 밉맵 끔).
- 찍기 세 가지: `--stages` 21장과 `ext`, 인자 없는 57·28장의 회귀와 `pts.txt` 대조, `stage_shots` 1280·1920의 9장씩.
- 게임 창(1일차 세 결투의 무대, 연습, 세 간격의 읽힘, HUD 띠, 큰 베기의 칼끝과 위 띠).
- 판 L(L1~L4)의 답.

"미확인(2부)"으로 남긴 칸:
- 바이블 10절 무대 줄과 16절 해상도 줄의 L3 답.
- MANIFEST 뒷골목 줄의 `.import`(밉맵 끔).
- DECISIONS의 판 L 답.

실행 없이 고친 코드라 스크립트 오류가 2부에서야 드러날 수 있다(위험 R6).

## 3. 설계 문서와 다르게 구현한 부분과 이유

- **찍기 씬(7b)이 판을 흘리는 길**: 계획은 "프레임마다 `advance(1/60)`, 36프레임과 실제 0.5초가 다 차면"이었다. 기술 2회차의 비차단 제안대로, 목표 간격에 닿은 뒤 36프레임만 판을 흘리고 남은 실제 시간은 판을 멈춘 채 기다리게 했다.
  - 까닭: 주사율이 높으면 판 시각이 늘어나, 멀리 장에서 상대가 접근 시간(1.5초)을 넘어 다가올 수 있다.
  - 걸음(`core.step`)은 플레이어가 준비일 때만 받으므로, 목표 간격에 닿을 때까지 되풀이해 부른다. 판이 끝났으면 걷지 않는다(`scale,` 판정이 잡는다).
- **T73의 띠 확인**: `get_global_rect()` 대신 앵커·오프셋에서 1280×720의 화면 사각형을 셈해 본다. 씬을 붙인 직후 Control의 크기가 언제 정해지는지에 기대지 않게 했다. 보는 값(결정 298의 사각형, 조용한 구역과 겹치지 않음)은 같다.
- **T72의 "의뢰 없음" 경우**: 결투 씬은 의뢰가 없으면 세션의 의뢰를 받을 수 있다(`_ready`). 그래서 기대를 "씬이 실제로 쓴 의뢰의 무대, 없으면 뒷골목"으로 셈한다.
- **`cutstage.ps1`의 `-W`·`-H`**: 변수 `$Width`·`$Height`의 별칭으로 만들었다. 도구들이 함께 읽는 `paths.ps1`의 `$w`와 이름이 겹쳤다(PowerShell 변수는 대소문자를 가리지 않는다).
- **`run_opponent_shots.ps1 -Stages`**: `pts.txt`를 쓰지 않고 `ext.txt`만 쓴다(무대 찍기에는 재는 점이 없다).

## 4. 사용자가 결정해야 할 것

1. **2부를 할지**. 하라고 하시면 다시 묻지 않고 playtester에게 아래를 맡긴다(계획의 "playtester에게 맡길 확인").
   - 테스트 `ALL PASS 74/74`와 스모크 `RESULT: OK`.
   - 무대 셋의 `.import`: uid가 생기고, 밉맵 끔.
   - 찍기:
     - `run_opponent_shots.ps1 -Stages` 21장과 `ext.txt` 21줄.
     - 회귀: 인자 없는 57장, `-Sil` 28장. 새 `pts.txt`가 030c 것과 같은지.
     - `run_stage_shots.ps1` 1280과 `-Resolution 1920x1080`.
   - 게임 창:
     - (가) 1일차 세 결투가 광장·뒷골목·안뜰
     - (나) 연습 에밀리오가 광장, R 뒤에도 같다
     - (다) 띠 없이 화면을 채우고, 세 간격에서 상대·조준·상태 글자·HUD가 읽히며, 큰 베기 칼끝이 위 띠에 가리지 않는다
     - (라) 결과 겹창
     - 로그 오류 0
   - 그 뒤 메인이 판 L(`board-L-stages`·`board-L-hud`·`board-L-1920`)을 만들어 묻는다.
     - L1 무대 셋
     - L2 HUD 임시 띠
     - L3 1920의 늘어남 "괜찮다 / 크게 그린다(031b)"
     - L4 의뢰마다의 무대
2. 커밋: 요청할 때. 사용자의 플레이 확인 9판(반응 싸움)은 아직이다. 031 뒤에 하면 무대가 들어간 화면에서 본다.

## 5. 다음 작업 제안

- 2부를 먼저 한다. 1부의 코드가 실행된 적이 없어, 판 L 전에 오류를 가려 두는 편이 낫다.
- 그다음은 L3의 답에 따라 031b(무대를 크게 그리기) 또는 032(내 손·칼).
- 후보: 카운터에 결투 장소 한 줄, 결정 293의 찌르기 예비 동작의 칼, BACKLOG `030c-1`.

라운드 수와 최종 판정: 검토 2회, 2회차 디자인 APPROVE · 기술 APPROVE(남은 차단 없음).

### 1부 뒤에 고친 것 (2026-11-23, 계획 032 기술 검토 T1에서 알게 됨)

- `tests/stage_shots.gd`가 결투 노드의 물리 처리를 `add_child` 앞에서 껐는데, Godot은 `_physics_process`가 있는 노드의 물리 처리를 `_ready` 직전에 다시 켠다. 그래서 판이 물리 틱으로도 흘러, 멀리 장에서 상대가 다가올 수 있었다. `add_child` 뒤에 끄도록 고쳤다(한 줄 옮김). 실행 확인은 2부다.
