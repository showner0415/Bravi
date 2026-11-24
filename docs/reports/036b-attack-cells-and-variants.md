# 보고서 036b: 공격의 칸과 변주

- 계획: `docs/plans/036b-attack-cells-and-variants.md` v2. 검토 2회(디자인 APPROVE · 기술 APPROVE).
- 근거: 사용자(2026-11-25) "공격이 항상 나오는 칸에만 나오니까 살짝 예상이 되는거 같아", "칸은 총 9개가 있는데, 공격은 정해진 칸에서만 나오거나 정해진 순서대로 나오고 있음".
- 상태(2026-11-25): 끝. 사용자의 답 — 높이 막기 "9칸으로 간다", 변주 "쓴다", "읽고 막는 맛이 난다", 이어 베기와 휩쓸기 "다르다".

## 1. 한 일

- **판정**: `scripts/ai/attack_data.gd`(`heights`, `variants`), `scripts/ai/opponent_data.gd`(`use_heights`, `flat()`), `scripts/ai/opponent_brain.gd`(예비 동작에서 변주와 높이를 한 번에 뽑는다), `scripts/duel/duel_core.gd`(방향과 높이가 모두 맞아야 막힘·패리, `guard_miss`), `scripts/duel/duel_record.gd`.
- **표시**: `scripts/duel/opponent_view.gd`(고리의 줄, 따라가는 점이 먼저 가 기다림, 칸 이름), `scripts/duel/duel_scene.gd`(타격 칸의 테두리), `scripts/duel/duel_hud.gd`(막는 법, 맞은 까닭), `scripts/commission/commission_select.gd`("(가로만)" 버튼).
- **데이터**: `data/opponents/trial/bartolo_patterns.tres`, `bruno_patterns.tres`. 하루의 상대·의뢰·날 데이터는 해시가 그대로다.
- **테스트**: `tests/pattern_cell_tests.gd`(T83~T85), `tests/duel_bots.gd`, `tests/pattern_tests.gd`(T81의 한 줄), `tests/run_tests.gd`.
- **확인 도구**(사용자 지시 "테스트를 확실하게 최적화"): `tests/verify.ps1`, `tests/run_duel_stats.ps1`·`duel_stats.gd`, `tests/run_pattern_shots.ps1`·`pattern_shots.gd/.tscn`, `scripts/duel/duel_summary.gd`·`event_log.gd`(`BRAVI_EVENT_LOG`), 러너 넷의 `-SkipImport`, `tests/ui_shots.gd`(창 없이도 돈다), `.claude/agents/verifier.md`, `.claude/agents/playtester.md`의 비용 규칙.
- **문서**: `CLAUDE.md`(3장 조작 표·공격 패턴 소절, 8장, 9장, 11장의 "싼 길부터"), `docs/DECISIONS.md` 382~395, `docs/HANDOFF.md`, `docs/BACKLOG.md`(036b-1~4, 확인 도구 한 줄), 이 보고서.
- **커밋**: `1f2177b`(판정 판 전), `517fa3e`(확인 도구), 문서로 한 번 더.

## 2. 직접 실행해서 확인한 것 / 확인 못 한 것

**확인한 것**
- playtester(Godot 4.7.2): 테스트 85/85, 스모크 OK, 찍기 57·15 OK, 게임 창에서 "패턴만" 넷의 변주·고리의 줄·칸 테두리·맞은 까닭, 자유 결투 네 판, 회귀(의뢰 카드와 하루 1일차).
- verifier(확인 도구를 만든 뒤): `tests/verify.ps1 -Stats` 통과 — 테스트 85/85, 스모크, 찍기 57·15·30, 봇 통계. 9칸과 가로만의 판 길이(바르톨로 48.0 / 47.5초, 브루노 43.5 / 43.0초)와 반격이 닿는 비율(67~70%)이 거의 같다.
- 사용자가 직접 해 보고 넷에 답했다.

**확인 못 한 것**
- playtester의 결투는 화면을 읽는 스크립트로 했다. 손맛은 사용자의 답으로만 안다.
- 밀착·멀리에서의 고리 겹침(창). `BRAVI_EVENT_LOG`와 찍기의 `-Shots`는 돌려 보지 않았다.
- 패턴 찍기가 브루노의 내려 긋기에서 고리 둘을 "화면 밖"으로 낸다. 도구의 셈인지 가리지 못했다(BACKLOG).

## 3. 설계 문서와 다르게 구현한 부분과 이유

- 확인 도구와 verifier 에이전트는 계획에 없던 것이다. 사용자의 지시로 메인이 직접 만들었다("니가 직접 스스로 … 새로운 파일을 만들어도 상관없어"). 게임 코드에는 `duel_scene.gd` 두 줄(환경 변수가 없으면 아무 일도 하지 않는다)만 닿는다.
- 확인 도구의 실행은 Haiku 에이전트에게 맡겼다(메인은 돌리지 않는다는 규칙 그대로).
- 메인이 게임을 한 번 직접 켰다(사용자 "확인 끝나면 게임 켜줘").

## 4. 사용자가 결정해야 할 것

- playtester의 모델(지금 Opus·high 고정)을 낮출지.
- 메인이 `tests/verify.ps1`을 직접 돌려도 되는지(에이전트 호출 하나가 빠진다).
- 036c(빈틈의 확률)의 남은 선택은 계획이 나오면 여쭙는다.

## 5. 다음 작업 제안

1. 036c: 빈틈이 열릴 확률(상대의 값 × 날, 업그레이드로 올림).
2. 패턴·높이·변주를 하루의 결투에 넣기, 제한 시간, 속임수.
3. 037(상대 셋째), 038(4단계 점검).

라운드: 검토 2회. 최종 판정: 디자인 APPROVE, 기술 APPROVE.
