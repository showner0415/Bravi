# 보고서 033b: 그린 질감 — 종이·테두리·버튼, 헤진 가장자리

- 계획: `docs/plans/033b-painted-texture.md` v3. 검토 3회(1회차 디자인 REVISE D1 · 기술 REVISE T1 → 2회차 두 관점 APPROVE → 사용자가 한 번 더 허락한 3회차 두 관점 APPROVE).
- 근거: 038 Q2 "그린 질감은 4단계 완료의 조건이다"(2026-11-26).
- 상태(2026-11-26): 끝. **W-5 "충족 — 4단계 완료"**.

## 1. 한 일

- **그림 셋**(Codex `gpt-6.2-sol` · `high` · read-only, 몫 9장 가운데 3장): 양피지 종이 PP1a, 장식 테두리 FR1a, 제비꼬리 버튼 BT1a. 원본은 `docs/style/basis/ui-paper.png`·`ui-frame.png`, 게임에 거는 손질본은 `assets/ui/paper.png`·`panel_frame.png`·`panel_frame_plain.png`·`button.png`.
- **손질 도구** `docs/style/tools/cutui.ps1`: 종이 16:9 자르기와 세기(`-Flatten`)·밝기(`-Mean`)·색(`-Tint`), 테두리의 흰 바탕 풀기와 종이 위 잉크 떼기(`-OnPaper`)·바깥 선만(`-Plain`), 버튼 바탕 지우기, `-Verify`.
- **게임**:
  - `scripts/ui/painted_patch.gd`(9조각·종이·깎아 그리기), `scripts/ui/manuscript_panel_style.gd`·`swallowtail_style.gd`(그림 칸 — 비면 033 그대로), `scripts/ui/worn_edge.gd`(헤진 가장자리의 꼴과 화면 몫), `assets/ui/manuscript_theme.tres`(`Panel`과 `PanelContainer`를 떼어 헤짐은 `PanelContainer`에만), `assets/ui/wall_style.tres`, `scripts/day_ui.gd`(머리 띠).
  - 작은 판(짧은 변 160 미만 — 결투 HUD, 정산 말 띠 등)은 안쪽 선·마름모 없이 바깥 선만.
  - 헤진 가장자리: 화면에 뜬 UI 창의 30%를 판의 고정된 이름으로 골라 큰 판에만 1~3곳. 같은 판은 늘 같은 모양. 버튼·결투 HUD·벽은 늘 깨끗.
  - 버튼은 보기 "다": 못 누름은 비치지 않는 흰 종이, 올림은 붉은 글자 대비 4.5.
- **테스트·도구**: 새 T96(`tests/painted_ui_tests.gd`), `tests/ui_shots.gd`의 `wear,`·`wearq,` 줄.
- **문서**: `docs/DECISIONS.md` 488~499, `CLAUDE.md` 7장·9장, `docs/BACKLOG.md`, `docs/STYLE_BIBLE.md`, `docs/style/STYLE_SPEC.md`, `docs/style/GENERATION.md`, `assets/MANIFEST.md`, `docs/HANDOFF.md`, 이 보고서.

## 2. 직접 실행해서 확인한 것 / 확인 못 한 것

**확인한 것**
- verifier: V0(전) 95/95 → V1·V2·V3 96/96(오류·경고 0). 연습 화면 맞춤 `fit select 1248x716`이 내내 그대로, UI 15·패턴 38, 1600 찍기 15장.
- 메인 판정(원칙 4): 결투의 고리·번호와 칸 테두리가 새 판 위에서 V0만큼 읽힌다(`opponent_01-p0-l1-engage`·`-close`).
- 잰 값: 종이 평균 색 `#E9D8B4`(차 0), 평균 밝기 0.697, 흐린 글자 대비 4.79·붉은 글자 5.08. 못 누름 버튼 흐린 글자 4.74.
- 헤짐(V3, 화면마다 UI 창 → 헤진 판): 카운터 1→1, 정산 2→1, 폐점 2→1, 연습 3→1, 도움말 1→0, 결투 5→0.
- 판: U1(`%TEMP%\bravi-style\033b\board-U1.png`), U2a~d(`board-U2*.png`), 고친 뒤의 장(`%TEMP%\bravi-033b\after2\`·`after3\`).

**확인 못 한 것**
- 게임 창에서 손으로 돌아다니며 본 것은 없다(찍기 장과 판으로 봤다).

## 3. 설계 문서와 다르게 구현한 부분과 이유

- 테두리가 흰 바탕이 아니라 양피지 위에 그려졌다 — 다시 뽑지 않고 `-OnPaper`로 살렸다(몫 한 장을 아낌).
- 판 U2의 답으로 0장 고침 넷: 종이 색을 바랜 양피지로, 작은 판은 바깥 선만, 헤짐을 "판 셋에 하나 깨끗"에서 "화면의 UI 창 30%"로, 버튼은 "다". 검토 상한을 넘긴 뒤라 사용자가 직접 지시한 고침으로 실행했다.
- 창이 하나뿐인 화면(카운터)은 헤짐이 0% 아니면 100%이고 지금은 늘 헤진 쪽이다 — 사용자가 알고 "이대로 맞다".
- 하위 에이전트가 PowerShell로 쓴 `docs/style/tools/README.md`의 한 줄이 깨져(CP949) 메인이 새로 썼다.

## 4. 사용자가 결정해야 할 것

- 없음. 4단계는 끝났다.
- 뒤에 볼 수 있는 것(BACKLOG): 카운터 판을 손님마다 다르게 헤지게 하려면 판에 `wear_key` 메타를 단다. 코드로 만든 판의 이름은 형제 차례에 기대므로 판이 앞에 끼어들면 뒤 판의 헤짐이 바뀐다.

## 5. 다음 작업 제안

사용자 지시의 설정·편의 기능 S01(설정 저장 기반·설정 화면·음량, `docs/plans/S01-settings-and-volume.md` v2 — 검토 전, 두 검토자의 1회차부터) → S02 → S03 → S04 → 5단계(사운드).
