# 보고서 046: 법정과 궂은일

- 계획: `docs/plans/046-court-and-noble-errand.md` v2. 6단계(콘텐츠), 나눔 039의 046 줄. 결정 733~745, 테스트 T145~T147.
- 검토: 2회. 1회차 디자인 REVISE(D1) · 기술 REVISE(T1) → v2 → 2회차 디자인 APPROVE · 기술 APPROVE.
- 상태(2026-11-28): 구현 끝, verifier 확인 끝(147/147). 카운터 두 장은 메인이 읽었다. 메인(이 작업)은 Godot · 테스트 · 게임을 실행하지 않았다.

## 1. 한 일

- **의뢰 둘**(`data/commissions/variants/`): `court_beehive.tres`(양봉가 체칠리아 · 세라피나 · 안뜰 · 몸통, 스침도 본다 · 60/25 · 평판 `{0, +4, −4, win 1}` · 흥정 없음)와 `noble_baker.tres`(젊은 백작 레안드로 · 굴리엘모 · 뒷골목 · 다리 유효타만, `hit_penalty 15` · 90/30 · 평판 `{−2, −4, −1}` · 눈높이 1). 의뢰인은 색 도형(그림은 046b).
- **하루**: `data/days/day_05.tres`(체칠리아 · 레안드로 · `day_02`의 일곱, `base_guests 5`)와 `data/day_schedule.tres`의 다섯째 칸(일정이 닷새를 돈다).
- **코드 한 갈래**: `scripts/economy/reputation_rules.gd` — `ITEM_SUCCESS_BAD := "궂은일을 해냈다"`, `success < 0`일 때만(결정 738). `day_state.gd` · `settlement.gd` · `counter.gd`의 diff 0줄.
- **재는 도구**: `tests/duel_stats.gd`(`--finisher=low`, `parts,` 줄), `tests/run_duel_stats.ps1`(머리 주석, 출력 거름은 기존 `stat|routes|score|feint|withdraw`에 `parts`만 더함), `tests/verify.ps1`(`-Stats`에 `court` · `courtwrong` · `courtnaive` · `noble` · `noblewrong`).
- **테스트**: `tests/court_noble_tests.gd`(T145~T147, `run_tests.gd`의 `TEST_FILES` 끝), 표를 고친 `stage_tests`(T72) · `counter_art_tests`(T77) · `client_line_tests`(T59) · `second_opponent_tests` · `day_tests`(T37) · `reputation_tests` · `opening_chance_tests` · `fourth_opponent_tests`(T120 ⑦) · `seventh_opponent_tests`(T141 ⑥만). UI 찍기 `counter-court` · `counter-noble`(31 → 33장, `ui_shots.gd` · `run_ui_shots.ps1`).
- **문서**: `docs/DECISIONS.md` 733~745, `CLAUDE.md` 4 · 5 · 6 · 9장, `docs/HANDOFF.md`, `docs/BACKLOG.md` 046-1~3, 이 보고서.
- **글자 수**(공백 · 문장부호 포함, 문단 둘): 체칠리아의 사연 146 + 79(합 225), 한마디 해냄 50 · 부분 45 · 못 해냄 41 · 돌려보냄 42(모두 56 이내). 레안드로의 사연 157 + 88(합 245), 해냄 44 · 부분 44 · 못 해냄 38 · 돌려보냄 35, 흥정의 대답 둘 20 · 38(44 이내). 사연은 280 이내, 숫자 · 큰따옴표 · "치료비" 없음.

## 2. 직접 실행해서 확인한 것 / 확인 못 한 것

메인(이 작업)은 Godot · 테스트 · 게임을 실행하지 않았고, 아래는 verifier의 결과다.

- 가져오기 OK(새 파일 `tests/court_noble_tests.gd.uid`는 커밋에 넣는다). 테스트 147/147(court_noble 3 + 57 · 22 · 22 · 24 · 14 · 5). `verify.ps1 -Only counter` OK(10장, 겹침 0). `UI SHOTS OK 33`.
- V0: 고치기 전 HEAD에서 받은 spar(`-Finisher off`)와 opponent_04의 줄이 고친 뒤와 글자까지 같고, 두 줄에 `parts,`가 없다.
- V2 1차(자세 9 · 4): court 63.1초 조건 종료 60 ✓ · courtwrong 54.1초 패배 41 · 조건 종료 17 · 시간 초과 2 ✗(나: 조건 종료 < 30) · courtnaive 48.7초 평균 충족도 62.2(머리 스침 2.65 · 다리 1.13 · 몸통 2.80) · noble 66.4초 조건 종료 51 · 시간 초과 9 ✗(가: > 6) · noblewrong 64.6초 조건 종료 44 · 패배 13 · 시간 초과 3 ✓.
- 사다리 첫 칸(7 · 3, 두 의뢰): court 50.7초 ✓ · courtwrong 49.2초 패배 35 · 조건 종료 25 ✗ · courtnaive 38.0초 평균 69.8 · noble 51.6초 조건 종료 59 · 시간 초과 1 ✓ · noblewrong 52.9초 조건 종료 50 · 패배 9 ✓.
- 사다리 둘째 칸(법정만, 6 · 3) — 최종: court 44.3초 조건 종료 60 · 100점 60 · 몸통 밖 스침 0 ✓ · courtwrong 45.1초 패배 27 · 조건 종료 33 · 평균 55.0 ✓ · courtnaive 32.7초 평균 충족도 74.3(court와 차 25.7 ≥ 10 ✓), 판당 머리 스침 1.83 · 다리 스침 0.73 · 몸통 1.80, 몸통 밖 스침이 난 판 60.
- 귀족 최종 7 · 3: noble의 withdraw 줄 "판당 빠짐 4.77 · 따라붙어 닿음 2.83 · 닿은 몫 1.00", parts "몸통 스침 4.27 · 팔 1.43, 다리 유효타 0.98".
- T145~T147 3/3(법정 씨앗: 가슴 봇 25~30초 100점, 고지식한 봇 점수 60/60/60/70/70, 귀족 다리 봇 27~42초 100점). stage · counter_art · client_line · day · reputation · flow 22/22.
- 메인이 읽은 장(`run_ui_shots.ps1 -Shots`, 33장): `counter-court` — 이름, 사연 두 문단, 조건 글 "몸통만 — 스침도 본다 …", 흥정 줄 "값을 올려 부를 수 없는 손님이다", "상대: 세라피나 · 층층 찌르기", 보수 60 · 25가 말풍선 안에 다 서고 의뢰인은 색 도형이다(맡는 값 0이라 소문 줄은 없다). `counter-noble` — 같은 꼴에 소문 줄 "맡기만 해도 평판이 깎일 일이다", 흥정 줄과 받아 줄 때의 기본 보수 117, "상대: 굴리엘모 · 치고 빠지기". 겹침 없음.
- 확인 못 한 것: 손맛(판 L2), 그림이 없는 두 의뢰인(046b).

## 3. 설계 문서와 다르게 구현한 부분과 이유

- **`target_part`의 값**: 계획 표는 몸통을 1이라 적었고(작업 3이 읽어 적는다고 했다) `DuelTypes.Part`의 실제 값은 TORSO 2, LEGS 5다(HEAD 0 · HAT 1). 파일에 2와 5를 적었다.
- **단계 목록의 거름**: `verify.ps1`의 `spar`~`noblewrong` 출력 거름은 `^(stat|score|parts),`이고 `court` 계열도 같은 줄에 묶었다(기존 세 단계의 `parts`는 `TargetPartCondition`이 없어 줄이 안 나온다).
- **값 고침(결정 746)**: 사다리를 법정 두 칸(9 · 4 → 7 · 3 → 6 · 3), 귀족 한 칸(7 · 3)을 밟았다. 두 의뢰 `.tres`의 자세 칸 둘만 고쳤고 `verify.ps1`의 머리 주석 한 줄도 맞췄다.
- **V0**는 verifier가 고치기 전 HEAD에서 받아 견줬다(위).
- **T145 · T146의 봇**: 계획은 "쥐고 막는 봇"이라고만 적었다. 봇은 `duel_stats.gd`의 `-Counter mid / same`과 같은 설정(막기는 늘 쥐기, 받아치기 지연 0.25초, 끝내기 가운데 중단 또는 가운데 하단, 귀족은 `chase_fn`이 늘 참)이다.

## 4. 사용자가 결정해야 할 것

그 세션에서는 묻지 않고 메인이 골랐다. 나중에 직접 보고 뒤집을 수 있는 것은 판 L2-1~11(`docs/HANDOFF.md` 3번 "046 판 L"): 고쳐 찌르기가 읽는 맛인가 벌인가(`graze_penalty`), 법정의 판 길이, 판돈, 귀족의 맞바꿈과 맡고 못 해내는 길, 70점 뒤틀림(`hit_penalty 15`), "궂은일을 해냈다"의 읽힘, 한 악당이 같은 날 둘(049), 일정이 닷새를 돈다, 귀족의 손이 깃털 자르기와 다르게 느껴지는가.

## 5. 다음 작업 제안

- 값 고침은 끝났다(결정 746). 판 L2의 손맛 확인 뒤 값을 다시 본다.
- 047(둘이 함께 — `flags`, 굴리엘모가 의뢰인이 된다): 계획 파일부터. T141 ⑥의 목록에 그의 의뢰를 더한다. 046b(의뢰인 그림 둘)는 047과 함께 또는 따로.

라운드 수 2, 최종 판정: 디자인 APPROVE · 기술 APPROVE.
