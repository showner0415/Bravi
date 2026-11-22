# 계획 030: 움직임 — 따로 그린 팔

- 버전: v4 (2회차 기술 검토의 신규 T4를 (가)로 수용. 사용자 답 2026-11-22 "(가)로 고치고 기술 검토 한 번 더". v3은 1회차 검토 대응: 디자인 D1·D2·D3, 기술 T1·T2·T3와 기술 비차단 하나. v2는 사용자 답 Q1 ①·Q2 ①·Q3 ①을 반영했다. 끝의 "검토 대응 기록")
- 개발 단계: CLAUDE.md 9장 **4단계(아트 교체)의 셋째 계획**(계획 028 "4단계 나눔"의 030). 게임 코드·씬·데이터·테스트와 판정 도구를 고친다. 그림은 한 장, 판정에 걸리면 한 장 더(최대 2장, 사용자 답 Q1).
- 근거:
  - 사용자 답(2026-11-22, 029 보고서 4번의 선택 창): 판 A·B·D "맞다", 판 C "맞다 — 손만 030에서 손본다"(손의 조준 테두리가 짧은 호로만 보이고 날밑과 겹쳐 약하다, 029 S7·위험 R6. 고른 선택지의 설명은 "몸통·모자·다리는 그대로, 손의 테두리를 바깥 윤곽선으로 바꾸는 길을 030에 넣는다", `docs/DECISIONS.md` 1158행), 029 커밋(`057928d`), 030 "시작한다".
  - 029 계획 "029와 030의 경계"(결정 254)와 029 보고서 3·5번: 따로 그린 팔 둘, 든 팔 주먹 그림자(결정 245), `hold` 곡선의 반응 싸움(029 위험 R5: 되돌리는 길은 곡선 값이 먼저, `hold_curve = false`는 R1 0.380), 게임 크기의 상태 색 재는 점(029 S3의 `torso-shadow`·`arm-line` OFF), 화소 전체 대조(`%TEMP%\bravi-style\029\pixrule.ps1`, 로컬).
  - 바이블 5절(따로 그린 팔은 Hand·Sword의 그림을 감춘다, 칼은 상태 색을 받지 않게 따로 자른다), 11절(R1 ≤ 0.30, R2 ≤ 0.10, R4 적기만), 13.2·13.3("시트·사람 고치기" 줄)·13.5·13.6·13.7, 15절(`arm_art`, "팔 그림은 국면의 경계에서만"), 16절("`hold` 곡선의 반응 싸움", "포즈의 남은 것"의 "따로 그린 팔에서 대기로 돌아갈 때", "든 팔(1번)의 주먹 그림자").
  - 견본 `docs/style/samples/026-pose-motion.html`: `opp()` 212~236행(Hand·Sword 감추기), 740~747행(자르는 상자·관절·배율 0.5333·든 팔 회전 180), `ARM_META` 748~752행(그리는 차례, 칼은 상태 색 없음), `frameAt` 706~732행(729행: 예비 동작은 `tell_start`의 그림, 타격부터 회수 끝까지 `strike`의 그림. 720~725행과 `mixPose` 643행: 돌아감이 끝날 때까지 나온 국면의 그림이 남는다), `silArt`·`silPose` 936~953행(실루엣: 칼 팔 파랑, 머리 빨강, 회수 q 0.5).
  - `docs/style/basis/README.md` 40~45행(팔 시트의 손질 값), `assets/MANIFEST.md`(꼴), `docs/style/tools/cutparts.ps1`(자르기의 꼴), `sil026.ps1`(실루엣 셈), `tintpair.ps1`(점의 꼴).
  - 지금 게임: `scripts/duel/opponent_view.gd`(`set_target` 144~150행, `_pose_for` 264~293행, `_apply_pose` 296~302행, `_apply_colors` 309~324행, `_apply_art` 333~349행), `scripts/duel/pose_data.gd` 3행("arm_art는 030이 더한다"), `scripts/duel/opponent_art.gd`, `scenes/duel/opponent_part.gdshader`, `scripts/duel/duel_scene.gd` `start_duel` 65~93행, `scripts/duel/duel_record.gd`(TELL_START의 `strike_time`·`duration`, GUARD_START의 `fresh`, STRIKE의 `result`), `tests/opponent_shots.gd`(41장, `TINT_PTS` 16~25행), `tests/opponent_states.gd`.
  - 찌르기의 `recovery_time`은 0이다(`data/opponents/opponent_01.tres` 71행): 막히거나 헛친 찌르기에는 회수가 없고, 패리당했을 때만 0.85초 회수가 있다(`parried_recovery_bonus` 147행).
  - 029의 교훈: 헤드리스 셰이더 컴파일러는 내장 `TEXTURE`를 사용자 함수 인자로 받지 못한다(`docs/DECISIONS.md` 1155행).
  - 결정 번호는 265부터다.

### 넘지 않는 선

- 029 계획의 "넘지 않는 선" 그대로다: 메인은 Godot·테스트·게임을 실행하지 않는다(PowerShell 도구, Edge 굽기, 화소 재기, Codex 호출, `git`은 메인이 한다). Write·Edit 한 번은 80줄 안쪽, 파일 하나·함수 하나씩. 스크립트마다 HANDOFF 4번의 기계적 확인 다섯. 주석은 "왜"만 한 줄, 지키는 결정 번호.
- **판정은 바꾸지 않는다**: `duel_core.gd`, `opponent_brain.gd`, 시간·자세·부위의 값은 그대로다. `hold_curve`는 표시만 읽는다(작업 8의 사본도 표시의 곡선만 다르다).
- 고치지 않는 것: 견본 020~027, `docs/style/STYLE_SPEC.md`(블록은 원문 그대로 쓴다), `docs/style/basis/bartolo-parts.png`, 사용자의 파일(`tools/`, `.claude/agents/playtester.md`, `docs/plans/013-playtester.md`, `.codex/`, `AGENTS.md`). 무대(031), 내 손·칼(032), HUD·고리의 자리(033)로 넘어가지 않는다.
- 그림은 몫(최대 2장, Q1) 안에서만 만들고, 돌리기 전에 장 수(이번 장, 쓴 장, 남은 몫)를 사용자에게 알린다(바이블 13.5).

## 목표와 범위

**확인할 결과**:

1. 큰 베기의 예비 동작에서는 든 팔 그림(`armUp`)이, 찌르기의 타격부터 회수와 그 뒤의 돌아감까지는 앞으로 뻗은 팔 그림(`armThrust`)이 보인다. 그동안 보통 팔·주먹·칼은 보이지 않는다. 따로 그린 팔의 칼(칼날·날밑)은 상태 색을 받지 않는다.
2. 따로 그린 팔에서도 칼 든 팔과 칼 든 손이 따로 조준 테두리·흰 번쩍임을 받는다. 손의 조준 테두리는 사용자가 고른 대로 바깥 윤곽선이 되어 칼 위에 끊기지 않는 둘레로 보인다(판 C의 고칠 거리, DECISIONS 1158행).
3. 게임 렌더에서 잰 R1 ≤ 0.30, R2 ≤ 0.10이다. 029 사이 상태의 값(0.160·0.057)과 나란히 적는다. 칼 팔의 꼴이 견본과 같다(실루엣 IoU ≥ 0.90).
4. 상태 색 짝 셋(왼쪽 베기 회수, 든 팔, 뻗은 팔)이 게임 크기에서 고른 재는 점으로 `off 0`이고, 화소 전체 대조가 문턱 안이다(029 S3의 OFF 둘이 풀린다).
5. 든 팔 주먹의 그림자가 오른쪽인 그림을 사용자가 판 E에서 고르면, 그 그림에서 자른 팔이 게임에 들어간다.
6. `hold` 곡선이 반응 싸움이 되는지를 사용자가 플레이로 보고, 판단에 쓸 수(공격별 패리 비율, 막기를 누른 때)가 기록에 남는다.
7. 기존 테스트 68개와 새 테스트(T68~T71)가 통과한다(playtester).

**범위 밖**: 곡선 값의 고침(반응 싸움 확인의 결과가 고치라고 하면 다음 계획이다), 칼 팔이 오른쪽인 상대(BACKLOG 029-1), 밀착의 포즈, 고리의 자리(033), 무대(031), 바르톨로 둘째 시트(머리·몸통)의 다시 그림, MANIFEST의 `final`(037).

## 설계 결정

265. **030의 차례**: 시작 확인 → 주먹 그림과 판 E로 고르기 → 고른 시트에서 자르기 → 데이터·뷰·테스트·찍기 → 반응 싸움 확인 장치 → playtester → 판정과 판 G → 보고서 → 사용자의 플레이 확인, 그 수의 덧붙임, 판 F(실제 움직임을 본 뒤). 그림을 먼저 고르는 까닭: 자르는 일이 고른 시트에 달려 있어 다시 자르고 다시 찍는 일을 없앤다. 반응 싸움은 마지막 꼴(따로 그린 팔을 끼운 뒤)에서 본다(029 "029와 030의 경계").
266. **따로 그린 팔은 데이터**: 새 Resource 둘. `ArmLayer`(`extends PartArt`, 더하는 필드 `part: int` = 이 층이 맡는 부위 `DuelTypes.Part`. −1이면 칼: 재질이 없고 상태 색·조준·번쩍임을 받지 않는다, 결정 241)와 `ArmArt`(`key: StringName`, `rotation_deg: float`(층 묶음의 회전, 든 팔 180), `layers: Array[ArmLayer]`(그리는 차례)). `OpponentArt.arm_arts: Array[ArmArt]`. `PoseData.arm_art: StringName`(기본 `&"Arm"` = 보통 팔, 바이블 15절의 열 이름과 값 `Arm`·`armUp`·`armThrust`). `OpponentData.strike_art_on_return: bool`(기본 참, 결정 268의 돌아감 갈래. 표시만 읽는다). 손 몫의 그림에는 바깥 윤곽선의 다각형 `PartArt.outline: PackedVector2Array`(자른 그림의 화소, 결정 269). 새 상대는 그림과 `.tres`만으로 따로 그린 팔을 더한다(원칙 5). 포즈에 없는 key는 경고 한 번과 보통 팔.
267. **자르기는 일곱 장, 주먹을 소매에서 가른다**: 견본은 소매와 주먹을 한 장으로 잘랐다(740~746행). 게임에서는 칼 든 손이 판정 부위이고(조준 테두리, 닿은 부위의 흰 번쩍임), 찌르기의 회수(뻗은 팔이 보이는 때)가 손을 칠 수 있는 때다. 한 장이면 "팔"과 "손"이 같은 둘레로 빛나 무엇을 노렸는지 읽히지 않는다. 그래서 소맷부리의 선에서 가르고, 주먹은 소매 쪽으로 2화소 더 잘라 소매 위에 겹친다(같은 화소라 보이지 않는다, 바이블 5절 겹침 여유). 날밑은 견본의 16각형 대신 같은 가운데·반지름의 타원으로 잘라 내고, 뻗은 팔의 주먹 장에서는 그 타원을 뺀다(주먹의 둘레가 날밑을 품지 않게). 배율은 0.5333 × 0.5935 = 0.3165 파츠 단위/화소, 화소는 줄이지 않는다(결정 251). 새 도구 `docs/style/tools/cutarms.ps1`.
268. **바꿔 끼우는 때**(바이블 15절 "국면의 경계에서만", 견본 729행·643행):
    - 예비 동작: 처음부터 끝까지 `tell_pose.arm_art`(대기 포즈에서 섞여 들어가는 0.2 구간도).
    - 타격부터 회수 끝까지: `strike_pose.arm_art`.
    - 그 뒤의 돌아감(`return_time` 동안 섞는 바뀜): 섞기가 끝날 때까지 **나온 국면의 그림**, 끝나면 그 상태의 그림(대기·방심·무너짐은 보통 팔). 예비 동작에서 곧장 대기로 간 경우(찌르기가 막혀 회수가 0)는 바뀜의 시작이 그 예비 동작의 `state_end`(타격 시각) 이상이면 타격이 있었던 것으로 보고 `strike_pose.arm_art`, 아니면(밀려나 공격이 사라짐) 예비 동작의 그림이다. 이 규칙이 없으면 찌르기의 뻗은 팔은 패리당한 찌르기에서만 보인다(근거의 `recovery_time` 0. 찌르기는 가방 가중치 3/5라 가장 자주 보이는 바꿔 끼우기가 막힌 찌르기 뒤의 이 0.2초다).
    - **맞바꿈과 갈래**(D2): 돌아감의 0.2초 동안 상대는 빈틈이 아니다(치면 섣부른 공격). 패리 뒤 회수에서 "뻗은 팔 = 손을 칠 수 있다"였던 그림이 빈틈이 아닐 때도 보여 그 신호를 흐릴 수 있다. 그래서 이 갈래를 상대 데이터 `strike_art_on_return`(기본 참 = 견본의 꼴)으로 두고, 거짓이면 따로 그린 팔은 회수에서만 보인다(돌아감은 바뀜의 시작부터 보통 팔). 사용자가 플레이 확인 뒤 판 F에서 고른다(작업 13). 바이블 16절 "따로 그린 팔에서 대기로 돌아갈 때"는 그 답으로 닫는다.
    - 따로 그린 팔이 보이는 동안 `Arm/Art`와 `Hand`(아래의 `Sword`·윤곽선까지)를 감추고, 그 묶음만 보인다(결정 237, 견본 `hideHand`·`hideSword`). 팔의 회전·어깨 자리는 지금 포즈 그대로 `Arm`이 준다.
269. **손의 조준 테두리는 칼 위의 바깥 윤곽선**(사용자 판정 2026-11-22, DECISIONS 1158행: 판 C "맞다 — 손만 030에서 손본다", 선택지의 설명 "몸통·모자·다리는 그대로, 손의 테두리를 바깥 윤곽선으로 바꾸는 길을 030에 넣는다"): `Torso/Arm/Hand`의 마지막 자식으로 `Line2D` `Outline`(닫힌 선, 둥근 이음, 색 `OUTLINE_COLOR`, 굵기 파츠 단위 5 = `OUTLINE_UNITS`)을 둔다. 차례가 `Art` → `Sword` → `Outline`이라 칼과 날밑 위에 끊기지 않는 둘레가 그려진다. 따로 그린 팔은 묶음의 끝에 주먹 층의 윤곽선을 둔다. 손을 노리면 윤곽선만 보이고 `Hand/Art`와 주먹 층의 안쪽 테두리는 늘 끈다(두 번 그리지 않게). 몸통·모자·다리·팔의 안쪽 테두리는 그대로다.
    - **다각형은 데이터다**: 029 위험 R6은 실행 중에 `BitMap.opaque_to_polygons`로 뽑는 길이었으나, 그러려면 텍스처의 화소를 읽어야 하고 헤드리스의 더미 렌더러에서 같게 도는지 모른다. 그래서 메인이 자를 때 PowerShell 도구(`docs/style/tools/outline.ps1`: 알파 ≥ 0.5의 가장 큰 덩이의 바깥 경계를 **화소의 모서리를 따라**(crack following, 꼭짓점이 화소 모서리의 정수 좌표) 돌고 1.5화소로 줄임. T4)로 뽑아 `PartArt.outline`(손 `hand`, `arm_up_fist`, `arm_thrust_fist`)에 적는다. 뷰는 (점 − 관절) × 단위/화소로 파츠 단위로 바꾸고(반 화소 차이가 없다: `centered = false`인 Sprite2D는 텍스처 화소 (0,0)의 왼쪽 위 **모서리**를 `offset` = −관절에 두므로, 모서리 좌표 x는 그대로 (x − 관절) × 단위/화소에 온다. 화소 가운데 좌표였다면 0.5화소가 어긋난다. 관절도 MANIFEST의 같은 모서리 기준 화소 좌표다) `Geometry2D.offset_polygon`으로 굵기의 절반(2.5)만큼 바깥으로 민 가장 큰 다각형을 선으로 쓴다(셈만이라 헤드리스에서도 같다). 셰이더는 고치지 않는다.
    - 기록된 결정과 같은 길이다(바깥 윤곽선). 029 R6과 다른 것은 다각형을 뽑는 때(실행 중 → 자를 때)뿐이고, 그 까닭을 보고서 3번에 적는다. 되돌리기 쉽다(노드 하나와 데이터 필드 하나).
270. **게임 렌더의 실루엣으로 R1·R2·R4를 잰다**: 찍기 씬의 `--sil`(견본 `silArt`와 같은 갈래: 칼 팔 묶음 전부 `#0000FF`, 머리 `#FF0000`, 다리·몸통 `#808080`, 모자·손 윤곽선·상태 글자·고리는 감춤, 바탕 흰색). 셰이더는 테스트 쪽 `tests/silhouette.gdshader`(게임 셰이더를 고치지 않는다). 셈은 `sil026.ps1`, 묶는 도구는 새 `docs/style/tools/rgame.ps1`(장의 이름과 쌍은 `r026.ps1` 15~20·38~48행과 같다). 상태 글자를 감추므로 029 S2b(글자와 칼이 섞여 세어짐)가 풀린다.
271. **상태 색 재는 점은 게임 크기에서 다시 고른다**: 점의 3×3 화면 상자가 교전 크기(×0.85)에서 덮는 텍스처의 반지름 r = ceil(2 ÷ (0.85 × 단위/화소)) + 1 텍셀(몸통·다리 5, 팔 7, 손 7, 따로 그린 팔 9). 칠·그림자·같음 점은 그 반지름 안에 Y < 0.30인 텍셀과 알파 < 1인 텍셀이 없다. 선 점은 걷는 방향에서 처음 만나는 Y < 0.22의 띠가 교전에서 4화소 이상이고, 띠의 양쪽이 같은 파츠의 불투명한 칠이다(바깥 윤곽에서 다른 파츠나 바탕이 뒤에 비치는 곳을 고르지 않는다. 029의 `arm-line`). 029의 이름 열둘은 그대로 두고 값만 바꾼다. 화소 전체 대조 `pixrule.ps1`을 인자(`-Off -On -Sig`)를 받게 고쳐 `docs/style/tools/`에 올린다(결정 249의 기준: 바이블 13.6의 판정이 쓰는 도구).
272. **주먹 그림자는 한 장으로 고친다**(결정 245, 몫은 Q1의 답: 1장, 걸리면 1장 더): 바이블 13.3 "시트·사람 고치기" 줄(P-KEEP-SHEET + `Change:` 한 줄, 넣는 그림은 지금 기준 `bartolo-arms.png` = A1g). 새 그림에서는 **1번 팔(시트의 왼쪽 절반 x 0~767)만** 쓰고 오른쪽 절반은 A1g를 화소째 잇는다(026의 A1f처럼 손질본. 2번 주먹의 손가락은 사용자가 비교 그림으로 고른 것이라 건드리지 않는다). 좌우가 걸린 고침이라 지금과 고친 것을 게임에서 보일 각으로 크게 나란히 보이고 고르게 한다(바이블 13.7, 판 E).
273. **반응 싸움은 사용자가 직접 보고, 게임이 기록한다**(사용자 답 Q2 ①): playtester는 화면을 찍어 보고 누르므로 0.18초의 패리 창을 눈으로 맞출 수 없어 이 확인을 할 수 없다. 환경 변수 `BRAVI_CURVE_CHECK=1`(또는 사용자 인자 `--bravi-curve-check`)이면 첫 판은 기록하지 않는 몸풀기, 그 뒤는 ABBA 차례(`hold`, 고르게, 고르게, `hold`, …)로 `hold`와 고르게 가는 곡선(`hold_curve = false`, 바이블 11절의 "어깨 회전 · game 곡선")을 쓰고, 판이 끝날 때 타격마다 한 줄을 `user://curve_check.csv`에 덧붙인다. 곡선은 플레이 중에 화면에 보이지 않고, 사용자가 판마다 느낌을 답한 뒤 메인이 판 번호별 곡선을 알린다. **정하는 것은 사용자의 답이다**: 기록의 수(패리 비율, 늦게 누른 비율)는 곡선 사이의 차이가 사건 2개 이상이면서 문턱을 넘을 때만 "걸림 의심"으로 붙여 사용자에게 보인다(위험 R5와 같다). 환경 변수를 쓰는 까닭은 T1(작업 8). 판정 기준과 되돌리는 차례는 작업 8.
274. **새 그림 일곱 장의 가져오기 설정**: 029가 켠 밉맵(결정 261)을 새 장에도 켠다. `.png.import`를 미리 쓴다(`hand.png.import`의 `[remap]` importer·type과 `[params]` 전부, `uid`·`path`·`[deps]`는 빼고 Godot이 채운다). playtester 확인 3이 본다(위험 R1).

## 작업 목록

차례대로 한다. `<R>` = `C:\godot\bravi`, `<W>` = 도구의 작업 폴더(`%TEMP%\bravi-style`, `paths.ps1`). 도구 명령은 작은 감싸개 `.ps1`(ASCII만, 절대 경로)에 적어 `powershell -NoProfile -File`로 띄운다. 메인의 감싸개와 결과는 `<W>\030\`(저장소 밖).

### 작업 0. 시작 전의 확인 (메인)

- `git status`가 깨끗하고 HEAD가 `057928d` 뒤다. 바르톨로 `.png.import` 열 개가 모두 `mipmaps/generate=true`다.
- **견본의 기준 값**: `& '<R>\docs\style\tools\r026.ps1' -Col rot -Curve hold -Bake -Tag n030`(주소에 `art=0`이 없어 팔 그림을 끼운 모습, 견본 753행)과 `-Tag n030b`를 한 번씩. 두 번의 R1·R2·R4가 같고 R1 최대 0.160·R2 최대 0.057(바이블 11절 표의 넷째 열)과 같은지 본다. 이 실루엣 장은 S10(견본과 게임의 IoU)에 쓴다.
- `%TEMP%\bravi-029-shots\aim-hand.png`가 있는지 본다(판 G의 전후). 없으면 판 G는 030의 장만 쓴다.
- `~/.codex/config.toml`의 해시가 처음 값(`AA004752…186D`, 바이블 13.5)인지 본다.
- 완료 확인: 위 넷의 값을 보고서 2번에 적는다. 견본 값이 바이블과 다르면 멈추고 보고한다(도구나 견본이 바뀐 것).

### 작업 1. 든 팔 주먹을 고칠 그림과 판 E (메인)

- 프롬프트: `docs/style/prompts/030-A1h-bartolo-arms.txt` = `027-A1g-bartolo-arms.txt`를 복사해 `Change:` 줄만 바꾼다(13.3 "시트·사람 고치기", 13.2 "한 가지만"). 넣는 그림: `docs/style/basis/bartolo-arms.png`. 바꾼 줄(영어, ASCII, 큰따옴표 없음):
  `Change: on the left part only (the raised arm with the long upright blade), move the shadow tone of the fist from the left side of the fist to the right side of the fist, the same as on the fist of the right part; the four fingers and the way they point, the outline of the fist, the cuff, the sleeve, the rapier and the whole right part stay exactly as they are.`
- 돌리기: 장 수를 알리고(이번 1장, 쓴 장 0, 남은 몫 1장), `run-codex.ps1 -Plan 030 -G A1h … -DryRun`으로 명령을 본 뒤 돌린다. 바이블 13.5의 막는 장치를 모두 보고 `docs/style/GENERATION.md`에 표 한 줄을 남긴다.
- 판정(바이블 13.6): 생성의 막는 장치, A-1a(바탕), A-1b(덩이 2), A-2(`calib026.ps1`의 K1·K2′·K3′), A-3(소매·주먹의 칠·그림자 Y ≥ 0.30). 새 판정 **A-6 1번 팔의 꼴이 같다**: 바탕을 지운 두 시트의 왼쪽 절반(x 0~767)의 알파 마스크 IoU ≥ 0.97(자르는 상자와 관절을 그대로 쓰려고. 임시 문턱). 눈: 1번 주먹의 그림자가 오른쪽, 손가락 넷과 방향이 그대로.
- 걸리면 한 장 더(같은 프롬프트, 몫의 둘째 장. 돌리기 전에 다시 알린다). 둘 다 걸리면 A1g로 가고 보고서 4번에 걸린 그림을 보인다.
- 손질본: 통과한 그림의 x 0~767과 A1g의 x 768~1535를 이은 `docs/style/generated/030-A1i-bartolo-arms.png`. 두 시트 모두 x 640~900에 바탕 아닌 화소가 0인지 먼저 본다(이음매가 바탕에만 있다).
- **판 E** `<W>\030\board-E-fist.png`: 위 줄에 가 = 지금(A1g), 나 = 고친 것(A1i)의 1번 팔(소매·주먹·칼)을 게임의 멈칫 각(팔 160° + 그림 180° = 화면 −20°)으로 돌려 교전 크기의 2배(0.85 × 0.3165 × 2)로, 바탕 `#3A3027`에 크게 나란히. 아래 줄에 두 시트의 1번 주먹을 돌리지 않고 2배로. 밑의 글은 영어(`A now`, `B fixed`).
- **실행 중의 물음**(선택 창, 그림을 먼저 보인다): "든 팔의 주먹" ① 나 — 올린다(권함) ② 가 — 지금대로 둔다 ③ 고친다(무엇을 고칠지는 다음 글로). ③이면 몫이 남을 때 그 글을 `Change:`에 담아 한 장 더, 몫이 없으면 ②로 가고 보고서 4번에 남긴다.
- ①이면: `docs/style/basis/bartolo-arms.png`를 A1i로 바꾸고 `basis/README.md` 16행(프롬프트 `030-A1h`, 넣은 그림 `027-A1g`, thread_id, 손질 "왼쪽 절반만 A1h", 사용자의 판정)을 고친다. 바이블 2절은 작업 10.
- 완료 확인: 판정의 값, 해시 전후, `git status`(저장소에 생긴 것은 프롬프트 파일과, ①이면 기준 그림·README뿐).

### 작업 2. 팔 시트 자르기 (메인)

- 새 도구 `docs/style/tools/cutarms.ps1`(`cutparts.ps1`의 꼴과 출력 줄, 한글이 있으면 UTF-8 BOM). 인자 `-Sheet`(기본 `docs/style/basis/bartolo-arms.png`), `-Rows 'upgrip=<y>;upcuff=<y>;thrustcuff=<y>'`. 바탕은 `measure.ps1 -Src -Cut`(허용 차 28)으로 지운다. 결과는 `assets/art/opponents/bartolo/`.

| 파일(결정 252) | 시트의 파츠 이름 | 맡는 부위 | 자르는 곳(시트의 화소) | 시트의 관절 |
|---|---|---|---|---|
| `arm_up_sword.png` | ArmUpSword | 칼 (−1) | x 372~534 · y 14~`upgrip` | (455, 923) |
| `arm_up.png` | ArmUp | 칼 든 팔 | x 390~532 · y `upcuff`~982 | (455, 923) |
| `arm_up_fist.png` | ArmUpFist | 칼 든 손 | x 390~532 · y `upgrip`+1~`upcuff`+2 | (455, 923) |
| `arm_thrust.png` | ArmThrust | 칼 든 팔 | x 985~1215 · y 188~`thrustcuff` | (1098, 250) |
| `arm_thrust_fist.png` | ArmThrustFist | 칼 든 손 | x 985~1215 · y `thrustcuff`−2~500에서 날밑 타원을 뺀 곳 | (1098, 250) |
| `arm_thrust_sword.png` | ArmThrustSword | 칼 (−1) | 타원 가운데 (1098, 500), 반지름 112 × 58 안 | (1098, 250) |
| `arm_thrust_blade.png` | ArmThrustBlade | 칼 (−1) | x 1068~1132 · y 540~814 | (1098, 250) |

- 행 셋은 `scan.ps1`로 고른 시트에서 잰다: `upgrip` = 1번 날밑의 아래 선의 마지막 행(시작 값 565, README 44행), `upcuff` = 1번 소맷부리의 위 선의 첫 행, `thrustcuff` = 2번 소맷부리의 아래 선의 마지막 행. 상자의 다른 값은 README 44~45행 그대로이고, 고치면 까닭과 함께 README와 MANIFEST에 적는다.
- `.png.import` 일곱(결정 274).
- 완료 확인(메인):
  - 출력 줄(T2): 장마다 **자른 선이 아닌 변**의 불투명 0, 자른 선(행 셋으로 가른 변, 날밑 타원의 둘레, 칼날 상자의 윗변) 위의 불투명 화소 수는 적기만 한다(이어진 그림을 가르므로 0이 아닌 것이 맞다). 옮긴 화소의 다름 0, 경계의 밝은 화소 수(적는다), 관절(자른 그림의 화소), 단위/화소 0.3165. 자른 선에 투명 여백을 덧대지 않는다(덧대면 이음매가 반투명해져 바탕이 비친다). 이음매는 아래 "다시 맞추기"(화소 다름 0)와 S5가 보증한다.
  - 손 윤곽선(결정 269): 새 도구 `docs/style/tools/outline.ps1 -Png <파일>`로 `hand.png`, `arm_up_fist.png`, `arm_thrust_fist.png`의 다각형(자른 그림의 화소 모서리 좌표, 점 수와 넓이)을 낸다. 다각형의 넓이가 알파 ≥ 0.5 화소 수의 ±3% 안이고(모서리를 따르므로 줄이기 전에는 덩이의 화소 수와 같다, T4), 다각형을 그림 위에 그린 판(`<W>\030\board-outline.png`)을 Read로 보아 둘레를 따른다.
  - `blobs026.ps1`: 장마다 덩이 1.
  - 섞임 없음: 소매·주먹 장에 칼 색(`#CFC8BA` ±16)인 화소 ≤ 1%, 칼 세 장에 살갗(`#EBC49F` ±16)·소매(`#5C6F7E`·`#4A5A67` ±16) 화소 0.
  - **다시 맞추기**: 일곱 장을 시트의 자리(관절)로 다시 놓은 그림과 바탕 지운 시트의 두 팔이 화소 다름 0(겹친 곳은 같은 화소다).
  - 판(어두운 바탕·양피지)을 Read로 보아 장마다 그 부위만 있다.
  - `assets/MANIFEST.md`에 일곱 줄(바이블 14절 꼴. 상태 `generated`, 출처 = 프롬프트·thread와 상자·행·타원, 따른 기준 `bartolo-arms`). `basis/README.md` 42~45행의 표에 ArmUpFist·ArmThrustFist와 잰 행을 더한다.

### 작업 3. 데이터 (Resource 스크립트와 `.tres`)

- 새 파일: `scripts/duel/arm_layer.gd`(`class_name ArmLayer extends PartArt`, `@export var part := -1`), `scripts/duel/arm_art.gd`(`class_name ArmArt extends Resource`, `key: StringName`, `rotation_deg := 0.0`, `layers: Array[ArmLayer]`). 결정 266.
- 고치는 파일: `scripts/duel/opponent_art.gd`(묶음 "따로 그린 팔", `@export var arm_arts: Array[ArmArt]`), `scripts/duel/pose_data.gd`(`@export var arm_art := &"Arm"`, 3행의 "030이 더한다"를 지운다), `scripts/duel/part_art.gd`(`@export var outline: PackedVector2Array`, 비면 윤곽선 없음), `scripts/ai/opponent_data.gd`(묶음 "움직임"에 `@export var strike_art_on_return := true`, 결정 268), `tests/core_tests.gd` `_copy_opponent()`(새 필드 한 줄).
- `bartolo_art.tres`의 `hand`·`arm_up_fist`·`arm_thrust_fist`에 `outline`(작업 2의 `outline.ps1` 출력).
- `data/opponents/bartolo_art.tres`: `ArmLayer` 하위 자원 일곱(값은 작업 2의 출력 줄), `ArmArt` 둘. 층의 차례는 그리는 차례다(견본 `ARM_META`, 칼은 −1):
  - `armUp`(`rotation_deg` 180): `arm_up_sword`(−1) → `arm_up`(3 = SWORD_ARM) → `arm_up_fist`(4 = SWORD_HAND). 자루는 주먹 뒤, 주먹은 소매 위.
  - `armThrust`(0): `arm_thrust`(3) → `arm_thrust_fist`(4) → `arm_thrust_sword`(−1) → `arm_thrust_blade`(−1). 날밑은 주먹 앞.
- `data/opponents/opponent_01.tres`: `pose_big_cut_tell`에 `arm_art = &"armUp"`, `pose_thrust_strike`에 `arm_art = &"armThrust"`(바이블 15절 표의 `arm_art` 열). 다른 포즈는 기본값(`Arm`)이라 줄을 쓰지 않는다.
- 완료 확인(메인): `ext_resource` 일곱의 경로가 있다(Test-Path). 하위 자원의 `joint`·`units_per_px`·`part`가 작업 2의 출력과 MANIFEST와 같다(줄마다). `load_steps` = 자원 수 + 1, `sub_resource` id가 겹치지 않는다. `opponent_01.tres`의 `git diff`가 두 줄 더함뿐이다. 기계적 확인 다섯(`@export var x: Array[ArmLayer]`처럼 타입을 적는다).

### 작업 4. 셰이더 (v3에서 뺐다)

- 결정 269가 바깥 윤곽선(`Line2D`)으로 바뀌어 `scenes/duel/opponent_part.gdshader`는 고치지 않는다. 완료 확인: `git diff`에 그 파일이 없다.

### 작업 5. 상대 뷰: 바꿔 끼우기와 손의 윤곽선

- 씬 `scenes/duel/opponent_view.tscn`: `Torso/Arm/Hand`의 마지막 자식으로 `Line2D` `Outline`(`closed = true`, 둥근 이음, 처음엔 감춤). Hand의 자식 차례는 `Art` → `Sword` → `Outline`. `load_steps`가 맞다.
- 스크립트 `scripts/duel/opponent_view.gd`:
  - `_apply_art`: `Hand/Outline`의 점을 손 그림의 `outline`에서 만든다(결정 269: (점 − 관절) × 단위/화소, `Geometry2D.offset_polygon`으로 2.5 바깥, 가장 큰 다각형, 굵기 `OUTLINE_UNITS`, 색 `OUTLINE_COLOR`). `outline`이 비면 점 없음. `art.arm_arts`마다 `Torso/Arm`의 자식 Node2D(이름 = key)를 `Art` 바로 뒤에 만들고(`rotation_degrees` = `rotation_deg`, 처음엔 감춤), 층마다 Sprite2D(`centered = false`, `offset = −joint`, `scale = units_per_px`, `part ≥ 0`이면 재질), 손 층마다 같은 꼴의 윤곽선 `Line2D`를 묶음 끝에 둔다. 같은 그림으로 `setup`을 다시 부르면 다시 만들지 않고, 다른 그림이면 옛 묶음을 떼어 지운다(찍기 씬이 장마다 `setup`을 부른다).
  - 바꿔 끼우기(결정 268): `_pose_for`가 바뀜을 알아챌 때 나온 국면의 그림을 잡아 두고(예비 동작이면 그때의 `state_end`와 새 시작을 견준다), 프레임마다 보일 key를 정해 `Arm/Art`·`Hand`와 묶음의 `visible`을 맞춘다. `strike_art_on_return`이 거짓이면 돌아감은 시작부터 그 상태의 그림이다.
  - 색·테두리·번쩍임: 한 부위의 재질 모두(보통 파츠의 것과 그 부위를 맡은 층의 것)에 같은 값을 준다. 칼 층에는 재질이 없다. 손을 노리면 윤곽선(보통 손과 따로 그린 팔의 주먹)의 `visible`만 켜고, 손 몫 재질의 `outline_on`은 늘 거짓이다(결정 269).
  - 지금의 줄(상태 글자·고리·방심 글자·받아넘김, 포즈의 곡선)은 고치지 않는다. 판정을 읽는 곳도 그대로다.
- 완료 확인(메인): Grep — `opaque_to_polygons`, `get_image`, `BitMap`이 `opponent_view.gd`에 0줄(화소를 읽지 않는다). 씬의 노드 경로 일곱이 `tests/scene_tests.gd` 10~13행과 같다. 기계적 확인 다섯. 한 함수가 80줄을 넘지 않고, 파일이 480줄을 넘으면 묶음 만들기를 새 스크립트(`scripts/duel/opponent_arm_art.gd`)로 뺀다. 기존 T67은 고치지 않고 통과해야 한다(고쳐야 하면 읽는 줄만 고치고 보고서 3번에 적는다).

### 작업 6. 테스트

- 대상: `tests/opponent_art_tests.gd`(T68~T70), 새 파일 `tests/curve_check_tests.gd`(T71)와 `tests/run_tests.gd`의 한 줄, 도우미 `tests/opponent_states.gd`(앞 상태에서 넘어온 꼴: 예비 동작이나 회수를 정해 `update_view`를 부른 뒤 대기로 넘기는 것. 대기의 시작을 앞 상태의 `state_end`와 같게 또는 앞서게 고를 수 있게).

| ID | 이름 | 본다 |
|---|---|---|
| T68 | 따로 그린 팔의 데이터 | `bartolo_art.tres`의 `arm_arts`에 `armUp`·`armThrust`가 있고 층 수 3·4, 층의 차례와 `part`(위 작업 3), 회전 180·0, 텍스처가 로드되고 크기·관절·단위/화소가 MANIFEST와 같다(테스트에 표를 둔다). `data/opponents/`의 모든 상대에서 포즈의 `arm_art`가 `Arm`이거나 그 상대의 `arm_arts`에 있다. 바르톨로는 큰 베기 `tell_pose`가 `armUp`, 찌르기 `strike_pose`가 `armThrust`, 나머지는 `Arm` |
| T69 | 상대 뷰: 팔 그림 바꿔 끼우기 | 아래 "T69의 확인" |
| T70 | 손의 조준 윤곽선 | `Hand`의 자식 차례가 `Art`·`Sword`·`Outline`이고 `Outline`이 `Line2D`(`closed` 참, 점 ≥ 8, 굵기 `OUTLINE_UNITS`)다. 점마다 손 그림의 다각형(파츠 단위로 바꾼 것) **밖**에 있다(`Geometry2D.is_point_in_polygon` 거짓, 바깥 윤곽선). `set_target(SWORD_HAND)`에서 `Outline`만 보이고 손 몫 재질의 `outline_on`은 거짓. `set_target(-1)`에서 감춰진다. 큰 베기의 예비 동작에서 `set_target(SWORD_HAND)`면 `armUp` 묶음의 주먹 윤곽선이 보인다. `outline`이 빈 `PartArt`(테스트가 만든 상대)로도 오류 없이 점 0 |
| T71 | 반응 싸움의 기록 | 아래 작업 8의 `CurveCheck.rows`를 만든 기록으로: 찌르기 예비 동작 시작 1.0, 타격 1.65, 새 막기 1.50 → 앞선 0.15, 패리. 막기가 타격 뒤 0.2초 → 늦은 0.2, 앞선 빈칸. 새 막기가 아닌 것(`fresh` 거짓)은 세지 않는다. `curve_for`: 0은 몸풀기(기록 안 함), 1~8이 `hold`·flat·flat·`hold`·`hold`·flat·flat·`hold`. `enabled_from(args, env)`: 인자 `--bravi-curve-check`만 · 환경 값 `"1"`만 · 둘 다 없음 · 환경 값 `"0"` → 참·참·거짓·거짓. 테스트 실행에서 `enabled()`가 거짓 |

**T69의 확인**(도우미로 상태를 정해 `update_view`를 부른다):

1. 대기: 묶음이 모두 감춰지고 `Arm/Art`·`Hand`가 보인다.
2. 큰 베기 예비 동작 p 0.1(섞여 들어가는 중)·0.5·0.9999: `armUp`만 보이고 `Arm/Art`·`Hand`가 감춰진다. `armUp`의 `rotation_degrees` 180, `Arm.rotation_degrees`는 `OpponentMotion.tell_pose`의 팔.
3. 찌르기 예비 동작 p 0.9999: 보통 팔. 찌르기 회수 q 0.5: `armThrust`. 큰 베기 회수: 보통 팔.
4. 찌르기 회수 → 대기 0.1초(섞는 중): `armThrust`, `return_time` 뒤: 보통 팔.
5. 찌르기 예비 동작 → 대기(시작 = 타격 시각, 0.1초 뒤): `armThrust`. 시작이 타격 시각보다 앞이면(사라진 공격) 보통 팔. 큰 베기가 사라지면 0.1초 뒤 `armUp`, `return_time` 뒤 보통 팔. `strike_art_on_return`을 거짓으로 둔 사본에서는 4·5의 섞는 중이 모두 보통 팔이고, 회수 q 0.5는 그대로 `armThrust`.
6. 찌르기 회수: 소매·주먹 층 재질의 `tint_color` = `COLOR_RECOVERY`, `tint_amount` 0.8. 칼 층 둘의 `material`이 null.
7. 찌르기 회수에서 `set_target(SWORD_ARM)`: 소매 층만 `outline_on`. `on_event`(ATTACK, GRAZE, SWORD_HAND) 뒤: 주먹 층 `tint_amount` 1.0·흰색, 소매 층은 회수 색.
8. `setup`을 같은 그림으로 두 번: `Torso/Arm`의 자식 수가 같다.

- 완료 확인(메인): 기계적 확인 다섯. 새 ID가 겹치지 않는다(Grep `"id": "T(6[89]|7[01])"`이 새 줄에만). 실행은 playtester.

### 작업 7. 그림 찍기: 새 장, 재는 점, 실루엣

- 대상: `tests/opponent_shots.gd`, `tests/run_opponent_shots.ps1`(ASCII만, BOM 없음), 새 파일 `tests/silhouette.gdshader`(`fragment` 안에서 `TEXTURE`의 알파만 읽어 `step(0.5, a)`로 한 색).
- **색 장**: 029의 41장(이름 그대로, 029와 견준다) + 새 16장 = **57장**.

| 장 | 상태 |
|---|---|
| `big-swing` | 큰 베기 예비 동작, p = `hold_end` + (1 − `hold_end`) × 0.5(휘두르는 중의 든 팔) |
| `thrust-recover` | 찌르기 회수 q 0.5(뻗은 팔) |
| `thrust-return`, `thrust-return-end` | 찌르기 회수 q 0.99 → 대기 0.1초 · 대기 섞기 끝(패리당한 찌르기) |
| `thrust-blocked-005`, `thrust-blocked-015`, `thrust-blocked-end` | 막힌 찌르기(D2): 예비 동작 p 0.9999(타격 직전 = 029의 `thrust-strike`) → 대기(시작 = 타격 시각) 0.05초 · 0.15초 · 섞기 끝. 가장 자주 보이는 바꿔 끼우기 |
| `aim-hand-up`, `aim-arm-up` | 큰 베기 멈칫(p = `hold_end`), 손 · 팔을 노림 |
| `aim-hand-thrust`, `aim-arm-thrust` | 찌르기 회수 q 0.5, 손 · 팔을 노림 |
| `touch-hand-thrust` | 찌르기 회수 q 0.5, 손에 스침(흰 번쩍임) |
| `pair-up-off`, `pair-up-on` | 큰 베기 멈칫, 상태 색 짝(신호색 `#FF801A` = 큰 베기의 `pose_color`) |
| `pair-thrust-off`, `pair-thrust-on` | 찌르기 회수 q 0.5, 상태 색 짝(`#4D80F2`) |

- 모자는 029의 장과 같고 새 장은 모두 모자 없이다. `pair-*-off`는 029의 `pair-off`처럼 그 부위의 재질(따로 그린 팔의 층 포함)의 `tint_amount`만 0으로 둔다.
- **짝 장에서는 고리와 상태 글자를 감춘다**(T3): `pair-off`·`pair-on`·`pair-up-*`·`pair-thrust-*` 여섯 장 모두 off·on 둘 다 `Ring`과 `StateLabel`을 `visible = false`로 둔다(찍기 씬에서만). 큰 베기의 멈칫은 예비 동작이라 고리가 가슴께 (640, 306)에 반지름 43의 반투명 원(알파 0.22)으로 그려지고, 그 밑은 규칙(칠에만 신호색 80%)과 크게 어긋나기 때문이다. 029의 짝은 회수라 고리가 없었다.
- **재는 점**(결정 271): `TINT_PTS`의 열둘을 게임 크기에서 다시 고른 값으로 바꾸고(이름·종류는 그대로), `pair-up`에는 소매 칠·주먹 칠·칼 같음·소매 안쪽 선, `pair-thrust`에는 소매 칠·주먹 칠·날밑 같음·칼날 같음·소매 안쪽 선을 묶음 노드(`Torso/Arm/armUp` 등)의 좌표로 둔다. 점을 고르는 셈은 메인의 감싸개가 잘린 그림에서 한다(반지름 r 안의 Y·알파). 찍은 점 줄의 꼴은 029 그대로(`pt,<장 이름>,…`), 짝마다 `-off` 장에서 낸다. 따로 그린 팔은 교전에서 화면 화소/텍셀이 0.85 × 0.3165 = 0.269라 4화소 띠에는 시트의 선 굵기 약 15텍셀이 든다. 그런 선이 없으면 그 짝의 "소매 안쪽 선" 점은 내지 않고 까닭을 보고서 2번에 적는다(선이 물들지 않는 것은 `pixrule.ps1`의 어두운 화소 바뀜이 본다).
- **실루엣 장**(`--sil`, 결정 270): 28장. 이름은 `sil-<공격>-tell25-mid`, `-tell25-far`, `-tell60-mid`, `-tell60-far`, `-recover-mid`(q 0.5), `-tell25-close`(공격 넷, `thrust`·`cutl`·`cutr`·`big`) 24장과 `sil-idle-mid`, `sil-idle-far`, `sil-complacent-mid`, `sil-idle-mid-noarm`(`Torso/Arm` 감춤). 진행·간격은 `r026.ps1` 15~20행과 같다.
- `run_opponent_shots.ps1`: `-Sil` 스위치가 `--sil`을 넘기고 끝 줄 `OPPONENT SHOTS OK 28`을, 없으면 `OPPONENT SHOTS OK 57`을 본다. `ERROR`·`SHADER ERROR` 줄 0.
- 완료 확인(메인): 장 이름과 수가 위와 같다(41 + 16, 28). 파일 이름에 한글이 없다. `run_opponent_shots.ps1`이 ASCII뿐이고 첫 세 바이트가 `EF BB BF`가 아니다. 고른 점의 값과 그 셈의 결과(반지름 안의 가장 낮은 Y·알파)를 보고서 2번에 적는다.

### 작업 8. 반응 싸움 확인 장치 (메인. 사용자 답 Q2 ①)

- 새 파일 `scripts/duel/curve_check.gd`(`class_name CurveCheck extends RefCounted`, 정적 함수만): `ARG := "--bravi-curve-check"`, `ENV := "BRAVI_CURVE_CHECK"`, `enabled_from(args: PackedStringArray, env: String) -> bool`(순수: 인자에 `ARG`가 있거나 `env == "1"`), `enabled()`(= `enabled_from(OS.get_cmdline_user_args(), OS.get_environment(ENV))`), `curve_for(index: int) -> bool`(`hold_curve`의 값. 0 = 몸풀기: `hold`로 돌고 기록하지 않음, 1부터는 ABBA: (index − 1) % 4가 0·3이면 `hold`, 1·2면 고르게), `rows(record: DuelRecord, curve: String, duel_id: String) -> Array[PackedStringArray]`(순수), `append(rows, path := "user://curve_check.csv")`.
  - **환경 변수를 쓰는 까닭**(T1): playtester는 `tools/start-playtest.ps1`로만 게임을 띄우는데, 이 런처는 게임 인자를 `--log-file …`, `--`, `--bravi-virtual-mouse`로 고정한다(9행. 사용자의 파일이라 고치지 않는다). 사용자 쪽의 `play.ps1 -- --bravi-curve-check`는 PowerShell이 `--`를 먹으면 플래그가 엔진 인자로 넘어가 기록이 조용히 0줄이 된다. 환경 변수는 `BRAVI_SAVE_PATH`처럼 자식 프로세스에 그대로 물려진다(런처 80~84행의 `CreateProcess`는 환경을 물려받는다).
  - **실행 줄**(글자 그대로. PowerShell 한 줄):
    - playtester: `$env:BRAVI_SAVE_PATH = "user://bravi_playtest_save.json"; $env:BRAVI_CURVE_CHECK = "1"; powershell -ExecutionPolicy Bypass -File tools\start-playtest.ps1`
    - 사용자: `$env:BRAVI_CURVE_CHECK = "1"; powershell -ExecutionPolicy Bypass -File play.ps1` (끝나면 `Remove-Item Env:BRAVI_CURVE_CHECK`. 테스트를 같은 창에서 돌리기 전에 지운다)
  - 한 줄 = 타격 하나: `session, duel_id, curve(hold|flat), attack_name, is_big, close(TELL_START의 duration < 공격의 tell_time), strike_t, result(StrikeResult 이름), lead, late`. `lead` = 그 예비 동작 시작 뒤 타격 전의 마지막 새 막기(`GUARD_START`의 `fresh` 참)가 타격보다 앞선 초(없으면 빈칸). `late` = 타격 뒤 0.3초 안의 첫 새 막기까지의 초(없으면 빈칸): 휘두름을 보고 누르면 여기에 모인다.
- `scripts/duel/duel_scene.gd` `start_duel`: `CurveCheck.enabled()`면 상대 데이터의 사본(`duplicate()`)의 `hold_curve`를 `curve_for(n)`에 따라 두고 코어와 뷰에 같은 사본을 준다(n은 이 실행에서 연 판의 수, 0부터). `END` 이벤트에서 n ≥ 1이면 `rows`를 덧붙인다. `session`은 첫 판을 연 시각(`Time.get_datetime_string_from_system()`). **곡선은 화면에 보이지 않는다**(글자·HUD를 더하지 않는다). 꺼져 있으면 지금과 한 글자도 다르게 돌지 않는다.
- 새 파일 `tests/curve_check_report.ps1`(ASCII, `-Session <값>` 또는 마지막 세션): 곡선 × (큰 베기 / 그 밖) 표: 타격 수, 패리·막힘·맞음(스침·유효타)의 수와 비율, `lead`의 가운데 값, `late`가 있는 타격의 수와 비율, 그리고 판 번호별 곡선의 목록. playtester의 확인이 끝나면 메인이 그 줄을 `curve_check-playtest.csv`로 옮겨 사용자의 기록과 섞이지 않게 한다.
- **사용자에게 주는 안내**(보고서 4번): 연습 결투 9판(몸풀기 1 + 곡선마다 4판). 판마다 막기를 세 번 이어 큰 베기를 두세 번 끌어낸다. 판마다 끝나면 "막기 쉬웠다 / 보통 / 어려웠다"를 판 번호와 함께 적어 둔다(어느 판이 어느 곡선인지는 끝난 뒤 메인이 알린다).
- **판정 기준**(임시, 결정 273. **정하는 것은 사용자의 답이다**, 위험 R5와 같다): (다) 사용자의 답 "고리·멈칫을 보고 눌렀다 / 휘두름을 보고 누르게 됐다 / 모르겠다"와, 곡선을 알리기 전에 받은 판마다의 쉬움을 곡선별로 모은 것이 정한다. (가) 큰 베기의 패리 비율의 차 > 15%p, (나) `late` 비율의 차 > 10%p는 `hold` 쪽이 나쁘고 **그 차가 사건 2개 이상**일 때만 "걸림 의심"으로 표에 붙여 사용자에게 보인다(곡선마다 큰 베기 8~12번이면 사건 하나가 8~12%p라 하나로는 뒤집히지 않게). 수가 "걸림 의심"인데 사용자의 답이 "고리·멈칫을 보고 눌렀다"면 사용자에게 한 번 더 묻는다. 걸리면 다음 계획에서 **곡선 값(`swing_ratio`, `tell_in`, `swing_margin`)을 먼저** 고치고 같은 기록으로 다시 본다. `hold_curve = false`는 R1 0.380이라 포즈를 함께 고쳐야 해서 마지막 길이다(029 위험 R5).
- 완료 확인(메인): 위 실행 줄 둘이 작업 8과 보고서에 글자째 같다. Grep `OS.get_environment`가 `curve_check.gd`의 한 곳. Grep `hold_curve`가 `scripts/`에서 `opponent_data.gd`·`opponent_motion.gd`·`curve_check.gd`·`duel_scene.gd`뿐. `opponent_brain.gd`·`duel_core.gd`가 상대 데이터에 값을 쓰지 않는다(Grep `opponent_data\.[a-z_]+ =`, `opp\.[a-z_]+ =`). `git diff`에서 `duel_scene.gd`의 바뀐 줄이 `CurveCheck`를 부르는 곳뿐. 기계적 확인 다섯.

### 작업 9. 판정 도구 셋 (메인)

- `docs/style/tools/pixrule.ps1`: 029의 로컬 것(`%TEMP%\bravi-style\029\pixrule.ps1`)을 인자 `-Off -On -Sig '#RRGGBB'`로 받게 고친다(형 이름 `PixRule`, ASCII). 출력은 029의 한 줄에 `PASS`/`FAIL`을 붙인다: 바뀐 화소 가운데 규칙과 맞는 것 ≥ 97%, 어두운 화소(Y < 0.20)의 바뀜 ≤ 1%(임시 문턱. 029는 98.7%·23화소).
- `docs/style/tools/rgame.ps1 -Dir <실루엣 폴더> [-Sample <견본 실루엣 폴더> -SampleTag <tag>]`: 작업 7의 28장 이름으로 R1(쌍 열, 진행 둘 × 간격 둘)·R2(1 − 빨강 ÷ `noarm`의 빨강)·R4(x 497~783 · y 62~142의 파랑)를 `sil026.ps1`로 내고, `-Sample`이 있으면 S10의 IoU를 낸다. 출력 줄은 `r026.ps1`의 꼴(`R1,<p>,<간격>,<장>,<장>,<값>`).
- `cutarms.ps1`(작업 2).
- `docs/style/tools/outline.ps1 -Png <파일>`(결정 269): 알파 ≥ 128의 가장 큰 덩이의 바깥 경계를 화소의 모서리를 따라 돌고(crack following: 꼭짓점은 화소 모서리의 정수 좌표, 화소 가운데를 잇는 무어 이웃이 아니다. T4) 1.5화소로 줄인 다각형을 `x,y;…`(자른 그림의 모서리 좌표)와 점 수·넓이(줄이기 전과 뒤)로 낸다. 알려진 그림으로 맞춘다: 메인이 만든 40×30 사각형 PNG에서 점 4(꼭짓점 (0,0)·(40,0)·(40,30)·(0,30)), 넓이 1,200 정확히. 그리고 한 칸 들어간 L자(40×30에서 10×10을 뺀 것)에서 점 6, 줄이기 전 넓이 1,100 정확히.
- `docs/style/tools/README.md`의 표에 네 줄.
- 완료 확인(메인) — 알려진 그림으로 먼저 맞춘다(바이블 13.6):
  - `pixrule.ps1`을 029의 `pair-off`·`pair-on`과 `#4D80F2`로: 029의 값(바뀐 24,996, 98.7%, 어두운 화소 23)과 같다.
  - `rgame.ps1`의 R1 한 쌍과 R2 한 장을 `sil026.ps1 -Iou`·`-Count`로 손으로 낸 값과 견준다(같다). 견본의 `sil-check` 장(견본 954행: 겹침 0.333, 가림 0.300)을 `sil026.ps1`로 세어 도구 자체를 맞춘다.
  - 세 파일의 BOM·ASCII 규칙(`docs/style/tools/README.md` 25행).

### 작업 10. 문서

| 파일 | 고칠 곳 | 바꿈 |
|---|---|---|
| `assets/MANIFEST.md` | 끝 | 일곱 줄(작업 2) |
| `docs/style/basis/README.md` | 16행(판 E가 ①일 때), 40~45행 | 기준 그림의 줄, 팔 시트의 손질 값에 주먹 둘·잰 행·타원 |
| `docs/STYLE_BIBLE.md` 2절 | `bartolo-arms`의 판정 칸과 "알려진 어긋남"의 첫 줄 | 판 E가 ①이면 판정 칸에 "2026-11-22 1번 주먹의 그림자를 오른쪽으로(계획 030)"를 잇고 어긋남 줄을 지운다. ②면 그대로 |
| 바이블 5절 | "기준 시트의 파츠 이름" | `ArmUpFist`·`ArmThrustFist`를 더한다(주먹을 가른 까닭은 결정 267) |
| 바이블 15절 | `arm_art` 줄, "팔 그림은 국면의 경계에서만" 줄 | 기본값 `Arm`, 돌아감의 갈래 `strike_art_on_return`(결정 268) |
| 바이블 16절 | "`hold` 곡선의 반응 싸움", "포즈의 남은 것", "든 팔(1번)의 주먹 그림자"의 셋째 칸 | 확인의 길(결정 273)과 결과는 사용자의 플레이 뒤, 돌아갈 때의 그림은 판 F의 답으로(결정 268), 주먹은 판 E의 답 |
| `docs/style/GENERATION.md` | 호출 표 | A1h(와 다시 뽑은 것) |
| `docs/style/tools/README.md` | 표 | 작업 9 |
| `docs/DECISIONS.md` 끝 | 새 절 "2026-11-22 — 계획 030" | 결정 265~274 한 줄씩과 실행 중에 정한 것, 판 E의 답 |
| `CLAUDE.md` 9장 | "4단계 진행 중" 문장 | 끝에 "계획 029(바르톨로를 결투에), 030(따로 그린 팔)." |
| `CLAUDE.md` 8장 | `tests/` 줄 | 바꾸지 않는다 |
| `docs/HANDOFF.md` | 1·2·3번 | 030의 상태, playtester 확인, 사용자의 플레이 확인이 남았는지 |

- 바이블을 고친 뒤 `check027.ps1`(인자 없음): V마다 못 찾은 수 0(V7의 검사한 개수는 늘 수 있다. 그 수를 보고서에 적는다). 바이블의 절 번호를 바꾸지 않는다.
- 완료 확인(메인): `DECISIONS.md`에 `^265\.`~`^274\.`가 하나씩. MANIFEST의 새 줄 수 7.

### 작업 11. playtester의 확인 (아래 "playtester에게 맡길 확인")

- 사용자가 Q3에 "맡긴다"고 답했다(2026-11-22, 선택 창). 이 답이 사용자의 요청이다: 메인은 작업 1~10을 마치면 다시 묻지 않고 바로 playtester를 부른다. 오류는 029의 "가리는 순서"(HANDOFF 1번)로 가리고, 범위·규칙을 바꾸지 않는 오류면 고쳐서 같은 확인을 다시 맡긴다(CLAUDE.md 11장 "실행 중 변경").

### 작업 12. 찍은 그림의 판정과 판 F·G (메인)

대상: playtester가 남긴 `%TEMP%\bravi-030-shots\`(57장과 `pts.txt`), `%TEMP%\bravi-030-sil\`(28장).

| # | 무엇 | 도구 | 통과 |
|---|---|---|---|
| S1 | 85장이 모두 1280×720이고 빈 장면이 아니다 | `System.Drawing` | 바탕과 다른 화소가 장마다 1% 이상 |
| S2 | 교전 꼭대기(G4) | `idle-mid-hat` | ≥ 142(029는 143) |
| S3 | 상태 색이 칠에만(짝 셋: `pair`, `pair-up`, `pair-thrust`) | `tintpair.ps1`(029의 감싸개 꼴), `pixrule.ps1` | 짝마다 `off 0`, `measured` = 낸 점 수, `pixrule` PASS |
| S4 | 바꿔 끼우기 | Read: `big-tell25`, `big-hold`, `big-swing`, `big-strike`, `thrust-strike`, `thrust-blocked-005`, `thrust-blocked-015`, `thrust-blocked-end`, `thrust-recover`, `thrust-return`, `thrust-return-end` | 결정 268대로(든 팔 넷, 보통 팔, 뻗은 팔 둘, 보통 팔, 뻗은 팔 둘, 보통 팔). 감춘 주먹·칼이 비치지 않는다 |
| S5 | 이음매 | Read: 2배로 자른 어깨(소매 머리가 몸통에 묻힌다), 소맷부리의 가름, 날밑과 칼날의 가름(`big-hold`, `thrust-recover`) | 틈·줄·한 화소의 띠가 없다 |
| S6 | R1·R2·R4 | `rgame.ps1 -Dir %TEMP%\bravi-030-sil` | R1 ≤ 0.30, R2 ≤ 0.10. 029 사이 상태(0.160·0.057)와 작업 0의 견본 값과 나란히 적는다. R4는 적기만(이제 칼만 센다) |
| S7 | 손의 조준 윤곽선 | Read: 029의 `aim-hand`와 030의 `aim-hand`를 2배로 나란히, `aim-hand-up`, `aim-hand-thrust`, `aim-arm-up`, `aim-arm-thrust`. 손 상자(주먹 그림의 둘레 + 10화소) 안의 노랑(R ≥ 230, G ≥ 230, B ≤ 130) 화소 수 | 윤곽선이 주먹 바깥에 칼 위로 닫힌 둘레로 보이고 노랑 화소가 029보다 많다. 팔의 테두리(안쪽)와 손의 윤곽선(바깥)이 저마다 그 층에만 |
| S8 | 번쩍임 | Read: `touch-hand-thrust` | 주먹의 칠만 희고 선과 소매는 그대로 |
| S9 | 칼은 물들지 않는다 | S3의 `pair-up`·`pair-thrust`에서 칼 점(`same`) | OK(차 ≤ 4) |
| S10 | 견본과 같은 꼴 | `rgame.ps1 -Sample`: 게임과 견본(작업 0)의 파랑 IoU, `big` 60% 교전, `thrust` 회수 교전, `cutl` 60% 교전, 대기 교전 | 넷 모두 ≥ 0.90 |

- 걸린 것(S2·S3·S6·S9·S10)은 사용자에게 보이기 전에 가린다. S6이 문턱을 넘으면 **멈추고** 넘은 쌍과 그 장을 보고한다(포즈나 곡선을 바꾸는 일은 계획의 수정이다). S5·S7·S8은 그림과 함께 보고서 3번에 적는다.
- 판(`System.Drawing`으로 장을 50%로 줄여 나란히, 장 밑에 영어 이름. `<W>\030\`):
  - 판 F "따로 그린 팔": S4의 열한 장을 시간 차례로 세 줄(큰 베기 / 막힌 찌르기 / 패리당한 찌르기). 막힌 찌르기 줄 밑에 "not open (rash attack)"를 붙인다(이 0.2초는 빈틈이 아니다).
  - 판 G "손의 조준": 윗줄 029 `aim-hand` · 030 `aim-hand`(2배로 자른 손), 아랫줄 `aim-hand-up`, `aim-hand-thrust`, `aim-arm-up`, `aim-arm-thrust`, `touch-hand-thrust`.

### 작업 13. 보고서와 사용자의 플레이 확인

- `docs/reports/030-separate-arms.md`(CLAUDE.md 10장의 다섯). 2번에 작업 0·2·7·9의 값, S1~S10, playtester의 결과. 4번에 아래 "030 뒤 사용자가 볼 것".
- 사용자가 플레이를 마치면 메인은 (1) 판마다의 쉬움(사용자가 적은 것)과 (다)의 느낌을 받고, (2) 그 뒤에 판 번호별 곡선을 알리고, (3) `curve_check_report.ps1`로 센 표("걸림 의심" 표시 포함)를 보이고, (4) 판 F의 물음을 묻는다(실제 움직임을 본 뒤라야 "튐"에 답할 수 있다, D2). 모두 보고서 끝의 "사용자 판정"에 덧붙인다(판정 기준은 작업 8). 기록이 없으면 "미확인"으로 둔다.
- 판 F의 답이 "뻗은 팔은 회수에서만"이면 `opponent_01.tres`에 `strike_art_on_return = false` 한 줄을 더하고 T69 5의 거짓 갈래가 그 꼴임을 보고서에 적는다(데이터 한 줄이라 다시 검토하지 않는다. 다음 playtester 확인 때 테스트로 본다).

## playtester에게 맡길 확인

작업 11에서 메인이 아래와 기대 결과를 넘긴다. 게임·테스트·스모크·찍기를 띄우는 명령마다 같은 줄에서 `$env:BRAVI_SAVE_PATH = "user://bravi_playtest_save.json"`.

1. **테스트**: `tests/run_tests.ps1` → `ALL PASS 72/72`(68 + T68~T71), `SCRIPT ERROR`·`ERROR:`·`SHADER ERROR` 줄 0. 스모크 `tests/run_smoke.ps1` → `RESULT: OK`.
2. **찍기**: `tests/run_opponent_shots.ps1`을 폴더 `%TEMP%\bravi-030-shots`로 → `OPPONENT SHOTS OK 57`, `pt,` 줄을 같은 폴더의 `pts.txt`로. `-Sil`과 폴더 `%TEMP%\bravi-030-sil`로 → `OPPONENT SHOTS OK 28`. 폴더 없이(헤드리스) 한 번씩 더 돌려 오류 줄 0.
3. **가져오기**: 새 `.png.import` 일곱에 `uid`가 생겼고 `mipmaps/generate=true`가 남았다(위험 R1). 가져오기의 오류 0. 새로 생긴 `.uid` 파일의 목록. `docs/style/` 아래 `.import` 0.
4. **게임 창**(`tools/start-playtest.ps1`): 연습 결투에서 (가) 교전 대기, (나) 손을 노린 조준 테두리, (다) 막기를 세 번 이어 큰 베기를 끌어내 그 예비 동작(든 팔), (라) 찌르기를 패리한 뒤의 회수(뻗은 팔), (마) 막힌 찌르기 직후의 돌아감. 찍을 수 있는 만큼 찍고 못 본 것은 "미확인"(찍기 57장에 같은 모습이 있다). 로그에 `ERROR`·`SHADER ERROR`가 없다. 판이 끝나면 결과·정산이 전과 같다.
5. **반응 싸움의 기록**: 작업 8의 playtester 실행 줄(글자 그대로: `$env:BRAVI_SAVE_PATH = "user://bravi_playtest_save.json"; $env:BRAVI_CURVE_CHECK = "1"; powershell -ExecutionPolicy Bypass -File tools\start-playtest.ps1`)로 연습 결투 세 판을 끝까지(몸풀기 1 + 2) → `user://curve_check.csv`의 실제 경로, 줄 수, 첫 두 줄. 기록된 판은 둘이고 `duel_id` 1·2의 `curve` 칸이 `hold`·`flat`이다. 화면에 곡선이 보이지 않는다. 끝나면 `Remove-Item Env:BRAVI_CURVE_CHECK`. 확인 1(테스트)은 이 변수가 없는 창에서 돌린다. 반응 싸움 자체는 보지 않는다(결정 273).
6. 확인하지 못한 것은 "미확인"으로, 실패는 입력·시점·기대와 실제·로그 줄로 남긴다.

## 030 뒤 사용자가 볼 것

보고서 4번에서 그림을 먼저 보이고(바이블 13.7) 선택 창으로 묻는다.

| 판·일 | 보는 것 | 묻는 것 |
|---|---|---|
| 판 G "손의 조준" | 손의 바깥 윤곽선이 칼 위에 닫힌 둘레로 읽히는가, 팔과 손이 따로 읽히는가 | 맞다 / 고친다 |
| 플레이 확인 | 작업 8의 사용자 실행 줄로 연습 결투 9판(몸풀기 1 + 곡선마다 4판, 곡선은 감춤). 판마다 막기를 세 번 이어 큰 베기를 두세 번 끌어낸다. 판마다 쉬움을 적어 둔다 | 플레이 뒤(곡선을 알리기 전): "고리·멈칫을 보고 눌렀다 / 휘두름을 보고 누르게 됐다 / 모르겠다" |
| 판 F "따로 그린 팔"(플레이 확인 뒤에 묻는다) | 실제 결투에서 본 움직임과 판 F: 든 팔의 휘두름, 막힌 찌르기 뒤 0.2초의 뻗은 팔, 패리당한 찌르기의 뻗은 팔이 한 사람의 움직임으로 읽히는가, 튐이 거슬리는가, 빈틈이 아닐 때의 뻗은 팔이 헷갈리는가 | ① 맞다 — 지금대로(돌아감에도 뻗은 팔) ② 뻗은 팔은 회수(패리당한 찌르기)에서만 보인다(`strike_art_on_return = false`) ③ 고친다(무엇을 고칠지는 다음 글로) |
| 030의 커밋, 031(무대) 시작 | — | 커밋한다 / 031 시작한다 |

- "맞다"여도 MANIFEST의 상태는 `generated` 그대로다(`final`은 037).
- 플레이 확인이 `hold`를 걸리게 하면(작업 8의 기준) 031 전에 곡선 값을 고치는 작은 계획을 제안한다.

## 위험

- **R1 `.import`를 미리 쓰기**: Godot이 `[params]`를 지키지 않고 기본값(밉맵 꺼짐)으로 다시 쓰면 일곱 장이 멀리에서 거칠어진다. playtester 확인 3이 잡는다. 그러면 메인이 그 줄만 고치고 다음 확인에서 다시 가져온다(멀리의 모습만 다르고 테스트·판정에는 닿지 않는다).
- **R2 고친 그림의 꼴이 바뀐다**: P-KEEP-SHEET도 꼴을 화소째 지키지 못할 수 있다. A-6(IoU ≥ 0.97)이 걸리면 자르는 상자·관절이 맞지 않으므로 그 그림은 쓰지 않는다(작업 1의 다시 뽑기·A1g로).
- **R3 실행 중에 만드는 노드의 차례**: 묶음과 윤곽선을 만드는 자리가 틀리면 주먹이 칼 밑에 가거나 Hand가 묶음 위에 그려진다. T69·T70이 자식 차례를 보고, S4·S7이 그림으로 본다.
- **R4 바뀌는 순간의 튐**: 국면의 경계에서 보통 팔 ↔ 따로 그린 팔이 한 프레임에 바뀐다(견본과 같다). 돌아감 끝(대기 포즈에서 뻗은 팔 → 보통 팔)이 가장 눈에 띌 수 있다. 판 F로 본다. 거슬리면 그 바뀜만 섞기 앞으로 당기는 고침(데이터 아님, 뷰 한 곳)이다.
- **R5 반응 싸움의 수는 적다**: 사용자 한 사람의 몇 판이라 비율은 참고다. 정하는 것은 사용자의 답이고, 수는 사건 2개 이상의 큰 차이만 "걸림 의심"으로 붙인다(작업 8과 같다). 몸풀기 판과 ABBA 차례로 손이 풀리는 치우침을 줄인다.
- **R8 손 윤곽선의 다각형**: `outline.ps1`이 주먹의 오목한 곳(손가락 사이)을 1.5화소로 줄이며 뭉갤 수 있다. 넓이 ±3%와 판(작업 2)으로 보고, 바깥으로 2.5 민 선이라 손가락 사이의 작은 오목은 어차피 메워진다.
- **R6 사본으로 바꾼 곡선**: 작업 8의 사본이 판정에 닿으면 원칙 위반이다. `hold_curve`를 읽는 곳의 Grep(작업 8)과, 사본을 쓴 판과 쓰지 않은 판의 판정이 같은지(T71은 기록만 본다. 기존 T50 밸런스는 인자 없이 돈다)로 본다.
- **R7 짙은 바탕의 번짐**: 새 일곱 장도 028·029의 열 장처럼 윤곽 밖에 어두운 반투명이 있을 수 있다. S5에서 함께 본다(029 S6은 눈에 띄지 않았다).

## 사용자 결정 필요

**검토 전에 물은 것**: 답은 모두 2026-11-22 선택 창이고 v2에 반영했다.

| # | 물음 | 사용자의 답 | 반영한 곳 |
|---|---|---|---|
| Q1 | 든 팔(1번) 주먹의 그림자를 고칠 그림의 몫 | ① 1장, 판정에 걸리면 1장 더(최대 2장) | 작업 1(돌리기·다시 뽑기), 결정 272 |
| Q2 | `hold` 곡선이 반응 싸움이 되는지를 어떻게 볼까(playtester는 0.18초 창을 맞출 수 없다) | ① 직접 한다 — 기록 있음(v3: 켜는 길은 환경 변수 `BRAVI_CURVE_CHECK=1`, 몸풀기 1판 + ABBA, 곡선은 감춤, 타격마다 기록) | 결정 273, 작업 8, T71(테스트 72개), playtester 확인 5, 작업 13 |
| Q3 | 030의 실행 확인을 playtester에게 맡길까 | ① 맡긴다 | 작업 11: 이 답이 요청이다. 작업 1~10을 마치면 다시 묻지 않고 부른다 |

**실행 중에 물을 것**: 판 E "든 팔의 주먹"(작업 1).

**묻지 않고 정한 것**: 030의 차례(265), 따로 그린 팔의 데이터 꼴(266), 주먹을 소매에서 갈라 일곱 장으로(267), 돌아감이 끝날 때까지 나온 국면의 그림을 기본으로 하고 갈래는 데이터로(268, 판 F에서 사용자가 고른다), 손의 테두리는 사용자 판정대로 칼 위의 바깥 윤곽선이고 다각형은 자를 때 뽑는다(269), 게임 렌더의 실루엣으로 R1·R2·R4(270), 재는 점의 기준과 `pixrule.ps1`을 저장소로(271), 새 그림에서 1번 팔만 옮겨 쓰기(272), 반응 싸움의 판정 기준과 되돌리는 차례(273), `.import`를 미리 쓰기(274). 029에서 남긴 BACKLOG·보고서의 작은 것 가운데 030에 든 것은 S2b(상태 글자와 칼이 섞여 세어짐, 결정 270으로 풀림)뿐이다. 고리의 자리는 033, 칼 팔이 오른쪽인 상대(029-1)는 035~036이다.

**030을 마친 뒤(보고서 4번)**: 위 "030 뒤 사용자가 볼 것". 4단계 완료 기준에는 아직 닿지 않는다(상대 2~3명, 무대, UI, 내 손·칼이 남는다).

## 검토 대응 기록

1회차(v2. 디자인 REVISE D1·D2·D3, 기술 REVISE T1·T2·T3)에 대한 v3의 대응과, 2회차(v3. 디자인 APPROVE, 기술 REVISE 신규 T4)에 대한 v4의 대응이다.

| ID | 대응 | 고친 곳 |
|---|---|---|
| D1 | 수용 | (1) 정하는 것은 사용자의 답이고, (가)·(나)는 `hold` 쪽이 나쁘고 차가 사건 2개 이상이면서 문턱을 넘을 때만 "걸림 의심"으로 붙인다: 결정 273, 작업 8 "판정 기준", 위험 R5(같은 말로 맞췄다). (2) 첫 판은 기록하지 않는 몸풀기이고, 그 뒤는 ABBA: `curve_for`(작업 8), T71. (3) 곡선은 플레이 중에 감추고, 판마다의 쉬움과 느낌을 받은 뒤에 판 번호별 곡선을 알린다: 결정 273, 작업 8 "사용자에게 주는 안내"(9판, 판마다 막기 세 번으로 큰 베기를 두세 번), 작업 13, "030 뒤 사용자가 볼 것"의 플레이 확인 줄 |
| D2 | 수용 | (1) 막힌 찌르기의 차례 `thrust-blocked-005`·`-015`·`-end`(타격 직전은 029의 `thrust-strike`): 작업 7의 표(57장), S4, 판 F의 세 줄. (2) 판 F는 플레이 확인 뒤에 묻는다: 결정 265, 작업 13, "030 뒤 사용자가 볼 것"의 판 F 줄. (3) "뻗은 팔은 회수에서만"을 판 F의 선택지 ②로 두고, 데이터 `OpponentData.strike_art_on_return`(기본 참) 한 줄로 바꾸게 했다: 결정 266·268(빈틈이 아닌 0.2초의 맞바꿈을 적음), 작업 3·5, T69 5, 작업 13 |
| D3 | 수용(가) | 메인이 전한 사실(판 C의 선택지 설명 "손의 테두리를 바깥 윤곽선으로 바꾸는 길")대로 바깥 윤곽선을 넣는다. 결정 269를 다시 썼다(칼 위의 `Line2D`, 굵기 5, 바깥으로 2.5). 다각형은 029 R6의 실행 중 `opaque_to_polygons` 대신 자를 때 `outline.ps1`로 뽑아 `PartArt.outline`에 둔다(헤드리스에서 같게 돌게). 그 차이는 보고서 3번에 적는다. 근거의 첫 줄에 1158행과 선택지 설명, 목표 2, 작업 2·3·5·9, T70, S7, 판 G, 위험 R8. 셰이더 고침(작업 4)은 뺐다 |
| T1 | 수용 | 켜는 길에 환경 변수 `BRAVI_CURVE_CHECK=1`을 더했다(`enabled_from(args, env)` 순수 함수). 런처와 `play.ps1`에서 인자가 막히는 까닭과 playtester·사용자의 실행 줄을 글자 그대로 작업 8에, playtester 확인 5에 같은 줄. T71에 인자만·환경만·없음·`"0"`의 네 갈래. 테스트는 변수가 없는 창에서, playtester 기록은 `curve_check-playtest.csv`로 옮겨 섞이지 않게 했다 |
| T2 | 수용 | 작업 2의 완료 확인: "자른 선이 아닌 변의 불투명 0", 자른 선 위의 불투명 수는 적기만. 투명 여백을 덧대지 않는다고 적었고, 이음매는 "다시 맞추기"(화소 다름 0)와 S5가 맡는다 |
| T3 | 수용 | 작업 7: 짝 여섯 장(`pair-*`) 모두 off·on 둘 다 `Ring`·`StateLabel`을 감춘다(찍기 씬에서만). 작업 9의 029 맞추기(24,996, 98.7%, 23)는 029의 장으로 하므로 그대로다 |
| 기술 비차단(따로 그린 팔의 선 점) | 수용 | 작업 7 "재는 점": 4화소 띠가 되는 선이 없으면 그 점은 내지 않고 까닭을 보고서에 적는다. 선이 물들지 않는 것은 `pixrule.ps1`의 어두운 화소가 본다 |
| T4(2회차 신규) | 수용(가) | `outline.ps1`이 화소 가운데를 잇는 무어 이웃이 아니라 화소 모서리를 따라 돈다(꼭짓점 = 모서리의 정수 좌표): 결정 269 "다각형은 데이터다", 작업 2 "손 윤곽선", 작업 9 `outline.ps1` 줄(사각형 점 4·넓이 1,200 정확히, L자 점 6·넓이 1,100 정확히). 모서리 좌표가 (점 − 관절) × 단위/화소에 반 화소 차 없이 맞는 까닭(`centered = false`의 Sprite2D는 화소 (0,0)의 모서리를 `offset`에 둔다)을 결정 269에 한 줄 적었다. T70은 같은 데이터로 재므로 그대로다 |

- **라운드 상한을 넘는 검토**: 2회차(v3) 결과 디자인 APPROVE, 기술 REVISE(신규 T4. T1~T3 해결)로 상한에 닿았다. 사용자가 "(가)로 고치고 기술 검토 한 번 더"를 골랐다(2026-11-22, 선택 창). v4는 T4만 고쳤고 디자인 승인 근거(플레이 규칙·확인 기준)는 건드리지 않았다. v4는 기술 검토 한 번만 받는다.
- 함께 고친 것(v3): 장 수 54 → 57, S1의 82 → 85, 도구 README 세 줄 → 네 줄(`outline.ps1`), "묻지 않고 정한 것"의 268·269 줄, Q2 답 칸에 켜는 길의 바뀜.
