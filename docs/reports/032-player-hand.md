# 보고서 032: 내 손·칼 — 화면 아래의 손을 그림으로 (1부)

- 계획: `docs/plans/032-player-hand.md` v4. 검토는 v3까지 2회(두 관점 승인), 실행 중 변경으로 v4가 됐고 사용자가 허락한 추가 1회에서 디자인·기술 모두 APPROVE(차단 없음).
- 상태: 1부 끝(2026-11-23). 2부(playtester 확인 → 판 L → 판 M2)는 사용자가 하라고 할 때 031 2부와 함께.

## 1. 한 일

- **그림**: 빈 주먹 H1a 두 장 뒤 사용자 지시로 손 모양을 사진 `docs/style/reference/레이피어 파지.png`에 맞췄다. 사진은 생성에 한 번 넣었다(결정 186의 예외). H1b → H1c → H1d~H1k를 거쳐 사용자가 **H1h로 확정**했다. 몫은 4장에 4장씩 두 번 늘린 12장이고, 모두 썼다.
  - `docs/style/basis/player-hand.png`(H1h), `docs/style/prompts/032-H1b`~`H1k-player-hand.txt`.
- **자르기**: `docs/style/tools/cuthand.ps1`을 v4대로 다시 썼다. 바깥 선을 화소로 두껍게(`-Grow`) 하고, 비스듬한 소매를 늘이고(`-Extend`·`-Slope`), 관절을 낸다. 후보 셋을 잘라 판 M1로 보였다. 답은 M1-1 "가", M1-2 "이대로"였다.
  - `assets/art/player/hand.png`(1125×2262)와 `.png.import`(밉맵 켬)를 올렸다.
- **데이터·코드**:
  - `data/player/hand_art.tres`(관절 (169.5, 15), 단위/화소 0.17561).
  - `scenes/duel/player_sword_view.tscn`: `HandArt`를 첫 자식으로 두고 `hand_art`를 건다.
  - `scripts/duel/player_sword_view.gd`: `hand_art`, `Sword/Outline`(2.9), 엉킴 경고 폭 10, `_apply_hand_art()`.
- **테스트·찍기**:
  - `tests/hand_tests.gd`(T74)를 새로 쓰고 `tests/run_tests.gd`에 한 줄 더했다.
  - `tests/hand_shots.gd`·`.tscn`, `tests/run_hand_shots.ps1`.
- **문서**:
  - `docs/STYLE_BIBLE.md`: 2절 표, 3절 예외, 4절 내 손, 13.3 줄, 16절.
  - `docs/style/STYLE_SPEC.md`: "계획 032 H1h의 줄"을 더했다.
  - `docs/style/GENERATION.md`, `docs/style/basis/README.md`, `docs/style/tools/README.md`, `assets/MANIFEST.md`.
  - `docs/DECISIONS.md`: 301~311과 "실행 중에 정한 것".
  - `CLAUDE.md` 7·8·9장, `docs/HANDOFF.md`.

## 2. 직접 실행해서 확인한 것 / 확인 못 한 것

**확인한 것**(PowerShell 그림 도구, 실행 없는 읽기):

- **H1h 재기**: 바탕 한 색, 덩이 1, 신호 구역 0, K1·K2′·K3′ PASS.
- **후보 셋**: `-Verify` diff 0, 덩이 1. 가의 바깥 선은 자루·주먹·소매에서 4.9/5.1/5.3단위.
- **판정 코드**: `git diff b775927`이 0줄이다(`duel_core.gd`, `scripts/ai/`, `opponent_motion.gd`).
- **`update_view`**: 본문을 고치지 않았다.
- **정적 확인**:
  - 기계적 확인 다섯(들여쓰기, 타입 추론, 서식 자리 수)을 했다.
  - `bind_tests`가 보는 경로가 그대로다.
  - 자식 차례에 기대는 코드가 없다.
  - `run_hand_shots.ps1`은 구문 오류 0, ASCII다.
- **바이블 점검**: `check027.ps1` V1·V2·V4·V7·V9 못 찾은 수 0, V3 23/23.
- **T74의 손 셈**(가장 높은 자세, 원점 y 430): 텍스처 아래 모서리의 y.

  | θ | 왼쪽 모서리 | 오른쪽 모서리 |
  |---|---|---|
  | −0.4 | 805.0 | **728.1** |
  | 0 | 824.6 | 824.6 |
  | +0.4 | 781.9 | 858.8 |

  모두 728 이상이다. 다만 θ −0.4의 오른쪽 모서리는 여유가 0.1화소다.

**확인 못 한 것(2부, playtester)**:

- 테스트 `ALL PASS 75/75`(T74 포함)와 스모크.
- `hand.png`의 가져오기(uid가 생기는지, 밉맵).
- `run_hand_shots.ps1` 1280·1920의 15장.
- 게임 창의 손(날밑과 자루의 맞물림, 크기, 엉킴 경고).
- 판 M2.

## 3. 설계 문서와 다르게 구현한 부분과 이유

- **바깥 선 t가 17화소다**(계획의 어림은 약 13).
  - 가: g가 13이 됐다(계획의 어림보다 작다).
  - 다: k가 3.27이 됐다(계획의 어림 2.5).
  - 다는 소매를 208화소 늘여야 했다(계획은 0으로 어림).
- **N은 1108이다**(계획 어림 약 1,090). 식대로 4의 배수로 올린 값이다.
- **`.png.import`**: 030의 꼴에서 uid·`path`·`dest_files`를 뺐다. Godot이 가져올 때 채운다.
- **판 M1의 둘레 겹침**: 디자인 검토의 비차단 제안대로 상대 둘레의 왼쪽·오른쪽 절반으로 나눠 적었다.
- 기술 검토의 비차단 제안(그림을 절반으로 줄여 약 3.4MB로)은 하지 않았다. 아래 5번에 제안으로 남긴다.

## 4. 사용자가 결정해야 할 것

- **2부를 할지**: 031 2부와 함께 한 번의 playtester 확인으로 돌린다. 기대값은 테스트 75/75, 스모크, 찍기 셋(`run_opponent_shots -Stages`, `run_stage_shots`, `run_hand_shots`)이다. 그 뒤 판 L(L1~L4)과 판 M2(M2-1 손, M2-2 칼의 꼴, M2-3 엉킴 테두리)를 묻는다.

## 5. 다음 작업 제안

1. 031·032 2부(위 4번).
2. 손 그림 줄이기: 1920에서도 화면 ÷ 원본이 0.26이다. 절반(k′ 2.85)으로 줄이면 약 3.4MB가 된다. 값 하나와 다시 자르기로 할 수 있다.
3. 사용자의 플레이 확인 9판(030 작업 13).
4. 033(글꼴·UI의 꼴).

라운드: v3까지 2회, v4 추가 1회(사용자 허락). 최종 판정: 디자인 APPROVE, 기술 APPROVE.
