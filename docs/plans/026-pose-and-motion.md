# 계획 026: 자세와 모션 시안

- 버전: v3 (1회차 검토 대응: D1, T1~T5, 비차단 제안 둘. v2는 Q1의 사용자 답 "16장". 끝의 "수정 기록")
- 개발 단계: CLAUDE.md 9장 **3단계(스타일 바이블)의 일곱째 계획**. 견본에서만 한다. 게임 코드·씬·데이터·테스트는 고치지 않는다(포즈 값을 데이터에 넣고 팔 회전을 코드에 더하는 일은 4단계다. 결정 219)
- 근거:
  - 사용자(2026-11-22, 원문): "자세나 모션같은걸 만들어야하는데, 특히 팔이 중요하고 이 게임에선. 어떤식으로 만들 수 있어. 이거 만드는것도 계획에 추가로 넣어줄래?" 선택 창의 답: 넣을 자리 "글꼴·UI 뒤에", 팔의 방법 **"어깨 회전 + 큰 동작만 따로 그림"**(결정 219·220).
  - 결정 220: 팔 한 덩이를 어깨를 축으로 돌리고 손과 칼이 따라온다. 팔꿈치를 나누지 않는다. 024 `idle-compare`의 "다"(팔 23°, 칼 −21°)가 이 방법의 대기 자세다.
  - 그림체(결정 209, `docs/style/STYLE_SPEC.md` 머리 "사용자가 고른 길"): 섞은 SVG만큼 단순하게, 디테일은 조금, **팔다리는 굽히지 않는다**. 자세는 "여유롭게 결투에 임하는" 느낌이고 거만해 보이지 않는다. 고칠 때는 바탕 그림 + "이것만"(P-KEEP·P-KEEP-SHEET).
  - 설계 원칙 4: 예비 동작은 일관되고 과장되게 보이고, 반응 속도 싸움이 되면 안 된다. 원칙 5: 포즈는 데이터의 꼴로 둔다.
  - 024 보고서 4번: 대기 자세의 세 안(결정 220이 "다"로 정했다), **큰 베기의 예비 동작에서 든 팔이 얼굴을 가린다**.
  - 결정 231(글꼴·UI): 상태 글자 Noto Sans KR 900, 본문·HUD 나눔스퀘어라운드 ExtraBold, UI "나 · 필사본". 글꼴 파일은 로컬 `docs/style/generated/fonts/`에 있다. 무대는 뒷골목(`basis/stage-alley.png`, 로컬 원본 `generated/023-R2-stage-alley.png`).
  - 사용자 지시(2026-11-22): "계속 진행해줘. 내가 꼭 결정해야되는게 있으면 선택할 수 있는 창 띄워." → 묻는 것은 꼭 필요한 것만 선택지로(최대 넷). 사용자는 글보다 견본을 보고 고른다.
  - 번호: 026. 결정 번호는 232부터다.

### 지금 게임의 포즈 (읽기만 했다. 견본의 `GAME` 표는 이 값을 옮긴다)

| 무엇 | 값 | 자리 |
|---|---|---|
| 포즈의 기준 `CHEST` · 어깨 `SHOULDER_X` | (0, −180) · 65 | `scripts/duel/opponent_view.gd` 35·36행 |
| 대기의 칼 `REST_SWORD_ROTATION` | −25° | 같은 파일 37행 |
| 타격의 팔 자리 `STRIKE_OFFSET`(왼쪽·가운데·오른쪽, `CHEST` 기준) | (−120, 40) · (0, 60) · (120, 40) | 39행 |
| 타격의 칼 `STRIKE_ROTATION` | −120° · 180° · 120° | 40행 |
| 무너짐: 팔 처짐 · 칼 · 고개 | (0, 50) · 165° · 0.4 rad(22.9°) | 41~43행 |
| 방심의 칼 | −140°(팔은 그대로) | 45행 |
| 피하기: 시간 · 고개 | 0.3초 · −0.35 rad(−20.1°) | 31·32행 |
| 번쩍임: 타격 빨강 · 닿은 부위 흰색 · 받아넘김 글자 | 0.1 · 0.18 · 0.6초 | 27~29행 |
| 간격의 배율 · 세로 이동 | 0.55 · 0.85 · 1.1 / −40 · 0 · 30 | 49·50행 |
| 고리: 속도 · 자리 | 240 px/초 · (−270, −150) · (0, −140) · (270, −150) | 55·56행 |
| 예비 동작의 포즈 | 팔 = `CHEST + pose_arm_offset.lerp(STRIKE_OFFSET[방향], 진행)`, 칼 = `lerpf(pose_sword_rotation, STRIKE_ROTATION[방향], 진행)`. 진행은 0→1 고르게(직선). 보간 없이 바로 놓는다(`exact`) | 205~210·238~240행 |
| 회수의 포즈 | 타격 자리 그대로 | 219~223행 |
| 그 밖의 옮김 | `1 − exp(−14 × delta)`의 지수 보간(95%까지 약 0.21초) | 175·242·243·246행 |
| 팔 회전 | 쓰는 곳이 없다(`_arm.rotation` 0건) | 024 보고서 2번 |
| 파츠의 자리 | Torso 원점 = 골반, Head (0, −200), Arm (−65, −180), 팔 다각형 길이 105, Hand (0, 105), Sword (0, 15). 그리는 차례는 Head 다음 Arm(팔이 머리 위에 그려진다) | `scenes/duel/opponent_view.tscn` 39·75·79·91·107행 |

| 공격(`data/opponents/opponent_01.tres`) | 방향 | 예비 동작 | 회수(막힘) | `pose_arm_offset` | `pose_sword_rotation` | 자리 |
|---|---|---|---|---|---|---|
| 찌르기 | 1 가운데 | 0.65 | 0.0 | (0, −70) | 180 | 7~17행 |
| 왼쪽 베기 | 0 왼쪽 | 0.75 | 0.55 | (−150, −70) | −50 | 19~29행 |
| 오른쪽 베기 | 2 오른쪽 | 0.75 | 0.55 | (150, −70) | 50 | 31~41행 |
| 큰 베기(버릇 반응, `is_big`, `needs_raised_guard`) | 1 가운데 | 1.1 | 1.6 | (0, −150) | 0 | 43~54행 |

- 상대의 값(같은 파일): `sword_side = 0`(칼 팔이 보는 쪽 왼쪽, 67행), `guards_head = true`(72행), `stagger_time = 1.5`(73행), `idle_time_min = 0.9`(77행), `parried_recovery_bonus = 0.85`(80행), `whiff_recovery_multiplier = 0.55`(83행), `close_tell_multiplier = 0.8`(84행). 패리 창 0.18(`data/weapons/rapier.tres` 12행).
- 회수 시간(`scripts/ai/opponent_brain.gd` 74~97행): 막힘 = `recovery_time`(버티기면 0), 패리당함 = `recovery_time + 0.85`, 헛침 = `recovery_time × 0.55`, 플레이어에게 닿음 = 0. 0이면 회수 없이 대기로 간다. 패리당했거나 큰 공격이면 "크게 열림"(91행). 밀착의 예비 동작은 × 0.8(65·66행).
- `scripts/ai/attack_data.gd` 20~26행: 포즈 필드 셋은 "임시 — 4단계에서 애니메이션 이름으로 대체"라고 적혀 있다.
- 손 계산으로 본 지금의 문제 둘:
  - **큰 베기의 얼굴 가림**: 예비 동작 처음의 팔 자리는 (0, −330)이라 팔(−330~−225)과 주먹(−225~−195)이 머리(−200~−317) 앞을 덮는다(024 보고서 4번의 까닭).
  - **큰 베기의 칼끝이 상태 글자 상자에 든다**: 같은 때 칼끝은 (0, −400), 교전의 화면에서 (640, 106)이다. 상태 글자의 상자(y 62~142)의 가운데다. 지금은 글자가 칼 위에 그려져(`z_index` 9) 글은 읽힌다.

### 넘지 않는 선

- 메인은 Godot·테스트·게임을 어떤 방식으로도 실행하지 않는다. Edge headless 굽기, Codex CLI, 화소 재기, `node --check`는 이 규칙 밖이다.
- 고치지 않는 것: `scripts/`, `scenes/`, `data/`, `tests/`, `project.godot`, `assets/`, `docs/BACKLOG.md`, 2단계의 보류 값, 견본 020~025, 020~025의 프롬프트 파일, `docs/style/basis/`의 있는 파일(새 그림을 올릴 때 `README.md`에 줄을 더하는 것만 한다), 사용자의 파일(`.claude/agents/playtester.md`, `tools/`, `docs/plans/013-playtester.md`).
- 그림을 만들면 메인이 Codex CLI로 `gpt-6.2-sol`·`high`만 쓰고, 사용자의 Codex 설정은 바꾸지 않으며, 돌리기 전에 장 수를 알린다. 참고 스크린샷을 넣지 않고 게임·작가 이름을 쓰지 않는다(우리 그림은 넣어도 된다. 결정 186). 생성 그림은 로컬 `docs/style/generated/`에만, 고른 것만 `docs/style/basis/`로.
- 신호색·상태 색·고리·상태 글자의 글과 자리는 지금 게임 그대로다(결정 181).

## 목표와 범위

**확인할 결과**. 메인은 파일 읽기·Grep·Glob·git, 구운 PNG의 Read, 견본이 `<pre>`로 낸 값(`--dump-dom`), 로컬 도구가 낸 값, 손 계산으로 확인한다. 읽히는지의 마지막 판정은 사용자의 눈이다.

1. **포즈 시안**: 공격 넷(찌르기, 왼쪽 베기, 오른쪽 베기, 큰 베기)마다 대기 → 예비 동작(시작·멈칫) → 타격 → 회수의 포즈가 024에서 자른 파츠(`basis/bartolo-parts.png`)로 서 있고, **지금 게임의 포즈(팔을 옮기기만 한다)와 어깨 회전의 포즈가 나란히** 보인다. 지금 게임에 있는 상태(빈틈, 크게 열림, 무너짐, 방심, 피하기, 받아넘김·밀어붙임, 닿은 부위의 번쩍임)도 같은 꼴로 보인다.
2. **움직임 시안**: 국면 사이가 이어져 움직인다. 시간은 상대 데이터의 값이고, 국면 안의 곡선은 지금 게임의 것(`game`)과 planner의 시안(`hold`: 예비 동작에서 멈칫, 정해진 짧은 휘두름, 느린 회수)을 나란히 보인다. 사용자의 원문은 "자세나 모션"과 "특히 팔"이고, 멈칫·빠름·느림은 사용자의 말이 아니라 이 계획의 시안이다. 견본은 브라우저에서 실제로 움직이고, 구운 그림은 시간을 주소 인자로 받아 연속 장면의 띠로 남는다.
3. **원칙 4를 값으로 본다**: 예비 동작의 팔·칼 실루엣이 공격마다 서로 다르고(교전과 멀리 ×0.55), 큰 베기의 든 팔이 얼굴을 덜 가린다. 두 열(지금 게임 / 어깨 회전)의 값이 함께 적힌다.
4. **따로 그린 팔**: 어떤 동작에 따로 그린 팔이 필요한지가 정해졌다(승인 A). 그렸다면 그 그림이 판정을 거쳐 견본에 끼워져 있다(승인 B).
5. 사용자가 고른 포즈와 움직임이 **데이터의 꼴**(공격마다·국면마다의 값의 표)로 `docs/style/STYLE_SPEC.md`의 새 **5부**에 적혀 있다(027의 `STYLE_BIBLE.md`와 4단계가 입력으로 쓴다).

**범위 밖**: 게임의 포즈 코드와 `AttackData`의 새 필드(4단계 제안으로 명세 5부에만 적는다), 내 손과 칼의 움직임(`player_sword_view.gd`. 사용자는 상대의 팔을 짚었다), 감정 상태와 페인트(게임에 없다), 롱소드, Skeleton2D 리깅, 소리, `docs/STYLE_BIBLE.md`(027). 3단계 완료 기준(`STYLE_BIBLE.md` 작성)은 이 계획으로 채워지지 않는다.

## 포즈의 꼴 (결정 233)

포즈 하나는 아래 열의 값 한 줄이다. 견본의 표 `POSES`와 명세 5부의 표가 같은 열을 쓴다(열 이름은 4단계에서 필드 이름으로 옮길 수 있게 ASCII다).

| 열 | 뜻 | 기본 |
|---|---|---|
| `arm_deg` | 팔 각(도). 어깨 (−65, −180)를 축으로 돈다. 0은 팔이 곧게 아래, **+는 화면에서 시계 방향**(Godot·SVG와 같다. 칼 팔이 왼쪽인 지금 상대에서 + 는 바깥·위로 들림, − 는 몸 앞으로) | — |
| `sword_deg` | 칼 각(도, **화면 기준**). 0은 칼날이 위, 90은 오른쪽. 칼은 Arm > Hand의 자식이라 지역 각 = `sword_deg − arm_deg − lean_deg`다(견본이 셈한다) | — |
| `head_deg` | 머리 각(도). 게임은 라디안이다(0.4 rad = 22.9°) | 0 |
| `lean_deg` | 몸 기울기(도). 골반을 축으로 Torso를 돌린다(머리와 팔이 따라온다). G1(머리와 몸통은 정면)을 지키려고 **절댓값 6 이하** | 0 |
| `shoulder_dx`, `shoulder_dy` | 어깨 자리를 옮김(파츠 단위). 회전만으로 못 가는 자리에만, **각 25 이하** | 0, 0 |
| `arm_art` | 팔 그림의 이름. `Arm`(024의 팔 파츠) 또는 따로 그린 것의 이름 | `Arm` |

- 국면(`phase`): 공격마다 `tell_start`(예비 동작 시작) · `hold`(멈칫의 끝) · `strike`(타격) · `recover_end`(회수의 끝), 상대마다 `idle` · `stagger` · `complacent`. 피하기는 `head_deg`만, 받아넘김·밀어붙임은 포즈가 없다(지금 게임도 글자뿐이다. `opponent_view.gd` 150~153·164~168행).
- 지금 상대는 `sword_side = 0` 하나뿐이다. 칼 팔이 오른쪽인 상대의 거울 규칙(x와 각의 부호를 뒤집는다)은 명세 5부에 4단계 제안으로만 적는다.
- 칼 팔은 늘 한 덩이이고 팔꿈치가 없다(결정 220). 따로 그린 팔도 곧은 한 덩이다.

## 어깨 회전의 포즈 — 출발 값과 고치는 길 (결정 234)

### 출발 값: 지금 게임의 손 방향

어깨 회전의 출발 값은 **지금 게임의 손이 가는 방향**이다. 견본의 함수 `fromGame()`이 셈한다(값을 손으로 박지 않는다).

- 지금 게임의 손 자리 h = 팔 자리 + (0, 105). 어깨 s = (−65, −180). `arm_deg = atan2(−(h.x − s.x), h.y − s.y)`(도). 팔의 길이는 105로 그대로이므로 손은 그 방향의 105 자리에 온다(지금 게임의 손과 거리는 다를 수 있다).
- `sword_deg` = 지금 게임의 칼 각(지금 게임은 팔을 돌리지 않으므로 그 값이 곧 화면 기준 각이다).
- `idle`은 결정 220의 "다"(팔 23°, 칼 −21°)다. `hold` = `tell_start`에서 팔을 타격의 반대쪽으로 8° 더 당긴 것(아래 "움직임"의 `creep_deg`), `recover_end` = `strike`에서 팔만 0° 쪽으로 10° 늘어뜨린 것("고치는 길").

planner의 손 계산(견본의 `fromGame()`이 내는 값과 소수 첫째 자리까지 같아야 한다):

| 공격 | `tell_start` 손 자리 → `arm_deg` · `sword_deg` | `strike` 손 자리 → `arm_deg` · `sword_deg` |
|---|---|---|
| 찌르기 | (0, −145) → −61.7 · 180 | (0, −15) → −21.5 · 180 |
| 왼쪽 베기 | (−150, −145) → 67.6 · −50 | (−120, −35) → 20.8 · −120 |
| 오른쪽 베기 | (150, −145) → −80.8 · 50 | (120, −35) → −51.9 · 120 |
| 큰 베기 | (0, −225) → −124.7 · 0 | (0, −15) → −21.5 · 180 |

| 상태 | 출발 값 |
|---|---|
| `stagger` | 지금 게임의 팔 처짐 (0, 50)을 `shoulder_dy` 25(상한)와 `arm_deg` 0으로, 칼 165, 고개 22.9 |
| `complacent` | `idle`의 팔(23°), 칼 −140 |
| 피하기 | `idle`에 고개 −20.1, 0.3초 |

### 고치는 길 (메인이 견본에서 눈과 값으로 고친다)

출발 값은 지금 게임을 옮긴 것일 뿐이라 그대로는 원칙 4를 채우지 못할 수 있다(큰 베기의 손이 턱 앞에 온다: 손 (21, −240)). 메인은 아래 방향으로 값을 고치고, 고칠 때마다 "원칙 4를 재는 법"의 R1·R2를 다시 잰다. 공격마다 **실루엣의 집안을 하나씩** 준다:

| 공격 | 예비 동작의 실루엣(planner의 시안) | 고칠 때 볼 것 |
|---|---|---|
| 찌르기 | **가로 선**: 팔을 어깨 높이 바깥으로 당기고(`arm_deg` 70~100) 칼을 가로로 눕혀 가운데를 겨눈다(`sword_deg` 70~110) | 칼이 머리를 가로지르지 않는다(어깨 높이 아래) |
| 왼쪽 베기 | **바깥 위의 사선**: 팔을 바깥 위로 들고(`arm_deg` 100~150) 칼을 바깥 위로 젖힌다(`sword_deg` −40~−80) | 찌르기의 가로 선과 칼의 각이 30° 이상 다르다 |
| 오른쪽 베기 | **몸 앞을 가로지른 사선**: 팔을 몸 앞으로 돌려 반대쪽 어깨로(`arm_deg` −100~−130, 필요하면 `shoulder_dx` +25) 칼을 오른쪽 위로(`sword_deg` 30~70) | 팔이 얼굴이 아니라 가슴 앞을 지난다(R2) |
| 큰 베기 | **가장 큰 세로**: 팔을 머리 옆 높이로 곧게 들고(`arm_deg` 140~175) 칼을 머리 위나 뒤로(`sword_deg` −60~30). 몸을 조금 젖힌다(`lean_deg` −3~−6) | 얼굴을 가리지 않는다(R2), 칼끝이 상태 글자의 잉크 상자를 덜 덮는다(R4) |

- `strike`는 공격의 방향으로 팔과 칼이 뻗은 자리다. 출발 값에서 크게 바꾸지 않는다(타격 순간은 짧고, 플레이어가 막을 방향은 고리와 방향 글자로도 읽힌다).
- `recover_end`는 `strike`에서 **팔만** 0° 쪽으로 10° 늘어뜨린 자리다(빈틈의 "힘이 빠진" 꼴). 칼 각은 `strike` 그대로, `head_deg` 0, 어깨 이동 0이다(이 셋은 고치지 않는다. 늘어뜨림은 10~15°까지).
- **무너짐과 갈리는 기준**(v3, T1): `recover_end`와 `stagger`가 아래 넷 가운데 **둘 이상**에서 다르다: 팔 각의 차 ≥ 15° · 칼 각의 차 ≥ 30°(360°로 돌려 작은 쪽) · `shoulder_dy`의 차 ≥ 15 · `head_deg`의 차 ≥ 10°. `stagger`는 어깨가 25 처지고 고개가 22.9° 기우므로, 위 규칙대로면 뒤의 둘이 늘 갈린다. 얼굴(어지러움)과 색(보라 / 파랑)도 다르다. 견본이 `<pre id="pose-check">`에 `atk,dArm,dSword,dShoulder,dHead,count,ok`로 낸다.

  출발 값의 손 계산(`stagger`: 팔 0, 칼 165, `shoulder_dy` 25, 고개 22.9):

  | 공격 | `recover_end` 팔 · 칼 | 팔의 차 | 칼의 차 | 어깨의 차 | 고개의 차 | 갈린 수 |
  |---|---|---|---|---|---|---|
  | 찌르기 | −11.5 · 180 | 11.5 | 15 | 25 | 22.9 | 2 |
  | 왼쪽 베기 | 10.8 · −120 | 10.8 | 75 | 25 | 22.9 | 3 |
  | 오른쪽 베기 | −41.9 · 120 | 41.9 | 45 | 25 | 22.9 | 4 |
  | 큰 베기 | −11.5 · 180 | 11.5 | 15 | 25 | 22.9 | 2 |
- 바르톨로의 성격(결정 209·212): 대기와 예비 동작은 여유롭고 자신 있게, 거만하게 젖히지 않는다(`lean_deg`는 큰 베기에만).
- 각 범위는 planner의 시안이다. 메인은 범위를 벗어나도 되지만 그 값과 까닭을 견본의 주석과 보고서 3번에 적는다.
- 고치는 차례: 큰 베기 → 오른쪽 베기 → 찌르기 → 왼쪽 베기(문제가 클 것부터). 공격마다 값을 고쳐 다시 재는 것은 **세 번까지**다. 세 번 뒤에도 R1·R2에 걸리는 공격은 그대로 두고 승인 A에 "따로 그린 팔의 후보"로 올린다("따로 그린 팔을 정하는 법").

## 원칙 4를 재는 법 (결정 235)

### 실루엣 굽기

견본의 섹션 `sil`은 **재기 전용의 한 색 그림**을 그린다: 흰 바탕(`#FFFFFF`), 무대·HUD·고리·글자·조준 테두리 없음, 모자 없음. SVG 필터(`feFlood` + `feComposite operator="in"` + `SourceAlpha`)로 한 색을 덮되, **필터는 파츠의 그림(`<image>`·도형)마다 건다**(v3, 기술의 비차단 제안). 묶음 `<g>`에 걸면 Head·Arm이 Torso의 자식이라 모두 회색으로 덮인다. 024 `genPartSvg`가 상태 색 필터를 파츠마다 건 길과 같다.

| 묶음 | 색 | 파츠 |
|---|---|---|
| 칼 팔 | 파랑 `#0000FF` | Arm과 그 자식(Hand, Sword. 따로 그린 팔이면 그 그림) |
| 머리 | 빨강 `#FF0000` | Head(목 그루터기 포함. 모자는 숨긴다) |
| 몸 | 회색 `#808080` | Legs, Torso |

- 그리는 차례는 게임과 같다(머리 다음 팔. 팔이 머리를 덮으면 그 화소는 파랑이다).
- 주소 인자: `col=game|rot`(지금 게임 / 어깨 회전), `atk=thrust|cutl|cutr|big`, `ph=idle|tell|strike|recover|stagger|complacent`, `p=<예비 동작의 진행 0~1>`, `dist=far|mid|close`, `noarm=1`(팔을 숨긴다. 머리의 넓이를 재려고). `curve`는 `hold`로 둔다(어깨 회전 열의 `p`는 "움직임"의 곡선을 지난 값이다. A2에서 `game`을 고르면 작업 7의 다시 재기는 `curve=game`으로 한다).
- 놓임: 교전 (640, 446)·×0.85, 멀리 (640, 406)·×0.55, 밀착 (640, 476)·×1.1(025 견본과 같다. 게임의 `anchor` y = 720 × 0.62와 `DISTANCE_SHIFT`).

### 재는 도구 `sil026.ps1` (로컬 `docs/style/generated/tools/`에 새로 둔다)

`scan.ps1`처럼 `Add-Type`의 C#으로 PNG를 읽는다. 화소의 갈래: 파랑 = B ≥ 160·R ≤ 90·G ≤ 90, 빨강 = R ≥ 160·G ≤ 90·B ≤ 90(가장자리의 섞인 화소는 갈래에 들지 않는다). 내는 줄:

- `count,<파일>,blue,red` — 갈래의 화소 수.
- `iou,<파일1>,<파일2>,<값>` — 두 장의 파랑 마스크의 겹침(교집합 ÷ 합집합). 놓임이 같은 두 장만 견준다.
- `box,<파일>,<x0>,<y0>,<x1>,<y1>,blue` — 상자 안의 파랑 화소 수.

**도구의 맞음**(먼저 한다): 견본의 섹션 `sil-check`가 알려진 도형을 그린다: 파랑 100×100 사각 둘(하나는 (100, 100), 다른 장은 (150, 100)에서 시작) → 겹침 셈 5000 ÷ 15000 = **0.333**, 빨강 100×100 위에 파랑 30×100을 덮은 장 → 가림 **0.300**. 도구가 이 둘을 ±0.01 안으로 내야 쓴다. 같은 굽기를 두 번 재어 값이 같아야 한다.

### 판정 (문턱은 모두 임시다. 지금 게임 열의 값을 함께 적어 견준다)

| # | 무엇 | 재는 장 | 통과(어깨 회전 열) |
|---|---|---|---|
| R1 | **공격마다 실루엣이 다르다**: 칼 팔 마스크의 겹침 | 공격 넷의 `ph=tell`을 `p=0.25`와 `p=0.6`에서, 교전과 멀리. 쌍 여섯(공격끼리)과 넷(공격 대 `idle`) | 모든 쌍이 **0.30 이하** |
| R2 | **얼굴을 가리지 않는다**: 머리의 가림 = 1 − (그 장의 빨강 ÷ `noarm=1` 장의 빨강) | 교전. 공격 넷의 `tell`(`p=0.25`·`0.6`)과 `recover`, `idle`, `complacent` | **0.10 이하**. `strike`는 재지 않는다(타격은 한순간이다). 큰 베기의 `recover`는 머리가 열리는 때(크게 열림)라 특히 본다 |
| R3 | 팔다리가 곧다 | — | 만든 꼴로 선다(팔은 한 덩이, 팔꿈치 없음). 따로 그린 팔은 B에서 눈으로 본다 |
| R4 | 칼끝이 상태 글자를 덜 덮는다: 잉크 상자 x 497~783 · y 62~142 안의 파랑 화소 | 교전과 밀착의 공격 넷 `tell`(`p=0.25`) | **적기만 한다**(굳은 확인이 아니다). 지금 게임 열보다 늘지 않으면 좋다. 상자의 폭은 025에서 잰 상태 글자의 가장 넓은 줄 285(가운데 640) |

- R1에서 멀리(×0.55)의 장은 마스크가 작아 칼날이 한두 화소로 줄어든다. 값은 적고 판정은 교전의 값으로 한다. 멀리에서 읽히는지는 섹션 `far-read`를 메인과 사용자가 눈으로 본다.
- 문턱이 가르지 못하면(두 열 모두 모든 쌍이 0.1 아래이거나, 어깨 회전이 아무리 고쳐도 0.30을 넘는 쌍이 여럿) 값만 적고 판정은 승인 A에서 사용자의 눈으로 한다(022~025의 "가르지 못하는 확인"과 같은 규칙).
- 상태 색(노랑·주황·파랑·보라)은 R1·R2에 들지 않는다. 색은 지금 게임의 규칙 그대로이고 실루엣만 잰다(색이 없어도 읽혀야 한다).

## 움직임 (결정 236)

### 시간표 — 상대 데이터의 값만 쓴다

견본의 함수 `timeline(atk, out, dist)`가 국면의 시각을 낸다. 고르는 것: `out=blocked|parried|whiff`(막힘 / 패리당함 / 헛침), `dist=mid|close`.

- 대기 0.9초(`idle_time_min`) → 예비 동작(`tell_time`, 밀착이면 × 0.8) → 타격(예비 동작의 끝, 빨강 번쩍임 0.1초) → 회수("지금 게임의 포즈"의 회수 시간 셈. 0이면 없다) → 대기로 돌아감 → 처음으로 되풀이.
- 상태 글자와 색은 게임 그대로다: 예비 동작 동안 공격 이름(큰 베기는 `큰 베기!!`에 둘째 줄 `받아낼 준비`. 024·025 견본의 장면과 같다)과 `pose_color`, 회수에 파랑과 `빈틈`(패리당했거나 큰 베기면 `크게 열림!`, 그 밖에는 머리가 물들지 않는다), 고리(`RING_SPEED` 240, 패리 띠 반지름 240 × 0.18 = 43.2).
- 상태의 시간표: 무너짐(대기 → 무너짐 1.5초 → 대기), 방심(대기 → 칼끝을 내린 채 머문다), 피하기(대기 중 고개 0.3초), 받아넘김·밀어붙임(대기 중 글자 0.6초).

손 계산(견본이 `<pre id="timeline">`에 `atk,out,dist,tellStart,strike,recoverEnd,swing,hold_end`로 낸다. 앞의 여섯 열은 아래 표와, 뒤의 두 열은 "국면 안의 곡선"의 손 계산과 같아야 한다):

| atk · out · dist | 예비 동작 시작 | 타격 | 회수 끝 |
|---|---|---|---|
| thrust · blocked · mid | 0.9 | 1.55 | 1.55(회수 없음) |
| thrust · parried · mid | 0.9 | 1.55 | 2.40 |
| cutl · blocked · mid | 0.9 | 1.65 | 2.20 |
| cutr · blocked · mid | 0.9 | 1.65 | 2.20 |
| big · blocked · mid | 0.9 | 2.00 | 3.60 |
| big · parried · mid | 0.9 | 2.00 | 4.45 |
| big · whiff · mid | 0.9 | 2.00 | 2.88 |
| big · blocked · close | 0.9 | 1.78 | 3.38 |

### 국면 안의 곡선

| 곡선 `curve` | 예비 동작 | 회수 | 대기로 돌아감 |
|---|---|---|---|
| `game`(지금 게임) | 시작에 `tell_start`로 바로 놓고, 진행에 따라 `strike`까지 **고르게** 옮긴다 | `strike` 그대로 | 지수 보간(`1 − exp(−14 × delta)`), 약 0.2초 |
| `hold`(planner의 시안) | 진행 0~`tell_in`(0.2): `idle` → `tell_start`(끝이 느려지는 꼴) · `tell_in`~`hold_end`: `tell_start` → `hold`(조금 더 당기며 **멈칫**) · 마지막 `swing`초: `hold` → `strike`(**빠르게**, 끝이 빨라지는 꼴). `swing = min(0.2 × 예비 동작 시간, 패리 창 − 0.03)`, `hold_end = 1 − swing ÷ 예비 동작 시간` | `strike` → `recover_end`(회수 시간 내내 **느리게** 늘어진다) | 0.2초(지금 게임과 같다) |

- 어깨 회전 열은 두 곡선을 다 보일 수 있다(`col=rot&curve=game|hold`). 지금 게임 열은 늘 `game`이다.
- 값 넷(`tell_in` 0.2, `swing`의 식(비율 0.2와 여유 0.03), `creep_deg` 8, 돌아감 0.2초)은 planner의 시안이고 견본 머리의 표 `MOTION`에 둔다. 공격마다 같은 값을 쓴다(일관되게. 원칙 4).
- **휘두름은 정해진 짧은 시간이다**(v3, 디자인의 비차단 제안을 받았다): 패리 창 0.18(`rapier.tres` 12행)에서 `swing`의 상한은 0.15초다. 손 계산: 찌르기 0.13초(`hold_end` 0.80), 베기 0.15초(0.80), 큰 베기 0.15초(0.864. 비율로 두면 0.22초라 패리 창보다 먼저 시작한다), 밀착의 큰 베기 0.15초(예비 동작 0.88, 0.830), 밀착의 찌르기 0.104초(0.52, 0.80). 견본이 `<pre id="timeline">`의 끝에 `swing,hold_end` 두 열을 더해 낸다. 휘두름은 늘 패리 창 안에서 시작하고 공격마다 길이가 거의 같다.
- **타격 순간은 바뀌지 않는다**: 어느 곡선이든 `strike`에 닿는 때는 예비 동작의 끝(= 고리가 0이 되는 때)이다. 휘두름은 패리 창 안에 들지만 신호는 그대로 고리다. **휘두름을 보고 누르는 반응 싸움이 되는지는 이 견본으로 판단하지 않는다**(견본에는 입력이 없다). 4단계의 플레이로 확인한다(위험 2, 명세 5부 "4단계로 넘기는 것").
- **돌아감은 빠르게 둔다**: 게임에서 회수가 끝나면 곧 대기(더는 빈틈이 아니다)이고 색도 곧 꺼진다. 돌아가는 팔이 느리면 아직 열린 것처럼 보인다(원칙 4). 느린 것은 회수 안에서만이다.
- 큰 베기의 `hold`와 `strike` 사이에서 팔의 각이 크게(100° 넘게) 돈다. 칼끝이 원을 그리며 지나가는 자리가 상태 글자 위를 덮는지는 띠에서 눈으로 본다.

## 견본 `docs/style/samples/026-pose-motion.html` (결정 238)

- 새 파일이다. `025-type-ui-size.html`을 복사해 시작하고 쓰지 않는 섹션과 함수(글꼴 후보의 견줌, UI의 세 안 가운데 "가"·"다", 카운터·정산·폐점, 크기 재기, `<pre>` 여섯)를 덜어 낸다. 남기는 것: 글꼴을 읽고 그리는 길(`FontFace` → `Promise.allSettled` → 그리기 → `data-ready="1"`, 오류는 `data-error`), 고른 글꼴과 UI "나"의 `duelHud`(`PICK`은 025의 고른 값 그대로), 조립한 바르톨로(`SHEET.a`, `opp()`), 상태 색 필터(`tintFilters()`), 뒷골목, 고리(`ring()`), 상태 글자(`stateText()`), 내 손(`playerHand()`). 020~025 견본은 고치지 않는다.
- 규칙은 025와 같다(`<meta charset="utf-8">` 맨 앞, 바깥 자원 없음, 그림은 `../generated/…`, 글꼴은 `../generated/fonts/…`만, 단독 보기 `#<id>`, 그림이 없으면 "만들지 않았다(까닭)").
- `opp()`에 셋을 더한다: `lean`(Torso를 골반에서 돌림), `armArt`(팔 그림 바꿔 끼우기), 칼의 지역 각 셈(`sword_deg − arm_deg − lean_deg`). 지금의 인자(`arm`, `armRot`, `sword`, `head`)는 그대로 둔다. 어깨 회전 열은 `arm = 어깨 + (shoulder_dx, shoulder_dy)`, `armRot = arm_deg`로 부른다.
- 스크립트 머리의 표: `GAME`(지금 게임의 값. 줄마다 출처의 파일·행을 주석으로), `ATTACKS`(공격 넷의 데이터 값), `POSES`("포즈의 꼴"의 열. `start`는 `fromGame()`이 채우고 `final`은 메인이 고친 값), `MOTION`(곡선의 값 넷), `ARMS`(따로 그린 팔. 처음에는 비어 있다).
- 주소 인자: `col`, `atk`, `ph`, `p`, `dist`, `out`, `curve`, `t`(초), `noarm`, `case`(재기의 맞음), `art=0|1`(따로 그린 팔을 끼울지). **`t`가 있으면 그 시각 한 장을 그리고 멈춘다. `t`가 없으면 움직이는 섹션은 `requestAnimationFrame`으로 돌고** 그린 장 수를 `<body data-frames="N">`에 적는다.
- `<pre>` 다섯(`display:none`): `pose-table`(`POSES`의 `final`을 "포즈의 꼴"의 열로), `game-table`(지금 게임의 포즈를 작업 1의 네 점에서 셈한 것), `timeline`, `pose-check`("무너짐과 갈리는 기준"), `font-status`(글꼴마다 `key,status`. 025와 같은 `FontFace.status`).

| 차례 | id | 무엇 | 굽는 것 |
|---|---|---|---|
| 1 | `pose-pair` | 공격 하나(`atk`)의 국면 다섯(`idle` · `tell` 진행 0 · `tell` 진행 0.6 · `strike` · `recover`)을 두 줄로: 위 지금 게임, 아래 어깨 회전(`curve=hold`). 양피지 바탕, 상태 색과 글자를 얹는다. 칸 256×360, 크기 ×0.45 | `atk` 넷 = 4 |
| 2 | `pose-states` | 상태 여섯(빈틈: 왼쪽 베기가 막힌 뒤 · 크게 열림: 큰 베기 뒤 · 무너짐 · 방심 · 피하기 · 받아넘김)을 두 줄로(위 지금 게임, 아래 어깨 회전). 칸 213×360 | 1 |
| 3 | `strip` | 결투 화면의 연속 장면 여덟 칸(4×2, 칸 320×360): 대기 · 예비 동작 10% · 30% · 60% · 90% · 타격 · 회수의 가운데 · 회수 끝 0.1초 뒤. 칸마다 화면의 x 340~940 · y 30~690을 잘라 0.533배로. 칸의 머리에 시각(초)과 국면. 회수가 없으면 그 칸에 "회수 없음(막혀도 빈틈이 없다)" | 공격 넷 × (`col=game`, `col=rot&curve=hold`), `out=blocked` = 8. 더해 `atk=thrust&out=parried`, `atk=big&out=parried`를 `rot`로 = 2 |
| 4 | `motion` | 결투 화면 한 장(뒷골목, HUD, 고리, 상태 글자, 내 손. 025 `ui-duel`의 자리). `t`의 그 시각 | 시각 확인 3(아래 작업 5) |
| 5 | `motion-pair` | 브라우저에서 보는 곳: 왼쪽 지금 게임, 오른쪽 어깨 회전을 640×360 둘로 같은 시계로 움직인다. 공격·결과·곡선·빠르기(×1 · ×0.5 · ×0.25)를 누름 단추로 바꾼다 | `t=1.2` 한 장(정지 화면 확인) |
| 6 | `far-read` | 멀리(×0.55) 뒷골목 위에 공격 넷의 `tell` 진행 0.6을 나란히(위 지금 게임, 아래 어깨 회전). 칸 320×360 | 1 |
| 7 | `sil` | "원칙 4를 재는 법"의 실루엣 | 작업 4의 표 |
| 8 | `sil-check` | 도구의 맞음(`case=a|b|c|d`) | 4 |
| 9 | `arm-guide` | 따로 그릴 팔의 자세 안내도(회색 실루엣. 승인 A 뒤) | 그릴 때 1 |
| 10 | `arm-art` | 따로 그린 팔을 끼운 `pose-pair`와 같은 꼴(승인 B 전) | 그릴 때 끼운 공격마다 1 |

- 굽기는 로컬 `tools/bake025.ps1`에 `-Page 026-pose-motion.html -OutDir 026 -Budget 5000`을 준다(글꼴을 기다린다. shot 문법 `<id>[@<pick>][+<키>=<값>]…`). `?pick=`는 쓰지 않는다(`SHEET.a` 하나). `arm-guide`만 1536×1024이고 크기 인자를 더한 `bake026.ps1`로 굽는다(작업 6).
- 페이지 머리의 "보는 법": `motion-pair`를 Edge나 Chrome으로 연다(로컬 그림·글꼴을 읽는다. Firefox는 막을 수 있다), 단추의 뜻, 아래에 승인 A의 물음.
- 움직이는 GIF는 **만들지 않아도 되는 것**이다. 메인이 작업 0에서 `Get-Command ffmpeg, magick`을 보고, 있으면 큰 베기 하나(`col=rot&curve=hold&out=blocked`, 0~3.8초)를 0.1초 간격으로 구운 39장을 이어 한 개를 만들어 A에서 함께 보인다(로컬 scratchpad에만. 굽기 한 장에 몇 초라 수 분이 든다). 없으면 띠(섹션 3)와 `motion-pair`로 본다.

## 따로 그린 팔 (결정 237)

### 정하는 법

1. **먼저 어깨 회전만으로 세운다**(작업 3·4). 024의 팔 파츠 하나를 돌린다.
2. 고친 뒤에도 R1·R2에 걸리는 공격·국면을 **후보**로 올린다. 걸리지 않아도 메인이 띠와 `far-read`에서 "곧은 팔을 돌린 것으로는 그 동작으로 읽히지 않는다"고 본 것을 까닭 한 줄과 함께 후보에 더한다. planner가 미리 보는 후보 둘:
   - **찌르기의 타격**: 플레이어를 향해 앞으로 뻗은 팔은 정면에서 짧아 보여야 하는데(앞으로 줄어 보임), 곧은 팔을 돌려서는 그 꼴이 나오지 않는다. 지금 게임은 칼을 아래로 돌려(180°) 대신한다.
   - **큰 베기의 예비 동작**: 머리 옆으로 곧게 든 팔이 돌린 소매로 읽히는지(소매 끝과 주먹이 위에 오는 꼴).
3. **승인 A에서 사용자가 고른다**(A2). 고른 것만 그린다. 고른 것이 없으면 그림을 만들지 않고 결과만 명세에 적는다.
4. 끼우는 때: 따로 그린 팔은 **국면의 경계에서만** 바꿔 끼운다(예비 동작 시작, 타격). 움직이는 도중에 그림이 바뀌면 튀어 보인다. 끼운 공격의 `POSES`에 `arm_art`를 적는다.

### 그리는 법 (그림 생성. 장 수는 몫 **16장** 안에서. 사용자 답 Q1)

- **한 장에 팔 파츠만의 작은 시트**: 1536×1024 가로, 고른 동작마다 한 파츠(셋까지). 파츠의 꼴은 고른 동작에 따라 메인이 정한다: 소매 + 주먹(칼은 024의 칼 파츠를 돌려 쓴다) 또는 소매 + 주먹 + 칼(앞으로 줄어 보이는 찌르기처럼 칼도 줄어 보여야 할 때). **모든 파츠에 주먹이 든다**(A-4의 배율을 주먹으로 잡는다).
- **시트 위의 파츠는 팔의 축이 세로로 곧게 선다**(v3, T3): 어깨 끝이 위거나 아래이고, 기울기는 그리지 않는다. 기울이는 것은 견본이 `arm_deg`로 한다. 그래서 파츠마다 다른 것은 "어느 끝이 위인가, 무엇이 보이는가, 앞으로 줄어 보이는가"뿐이고, 가로줄로 재는 도구(K2, `scan.ps1 -Rows`)가 소매를 바로 가로지른다. 안내도와 `<PART_LINES>`도 이 꼴로 쓴다.
- **넣는 그림 둘(우리 그림)**: in-1 = `docs/style/basis/bartolo-parts.png`(인물·화풍·소매·주먹·칼의 기준), in-2 = 견본 `arm-guide`에서 구운 자세 안내도(023 길 "가"의 색: 파츠 `#9A9A9A`, 칼 `#6E6E6E`, 바탕 `#D8D8D8`. 선·얼굴·디테일 없음. 시트 위 파츠의 자리와 세로로 선 꼴만. **1536×1024**로 굽는다: 작업 6). in-2는 로컬 `generated/in/026-in-arms.png`에 둔다.
- **프롬프트의 블록과 차례**(v3, T5. 024의 P1과 같은 차례다):
  1. 지시: 024의 "두 장"(`STYLE_SPEC.md` "계획 024의 블록" > "지시 블록 (두 장)").
  2. `Image:` · `Subject:`: 아래 새 블록 첫째.
  3. `Pose and layout:`: 아래 새 블록 둘째(`P-ARMS`).
  4. 화풍: S-PARTS의 머리 줄(`Style (...)`)과 첫째 항목, 둘째 항목 자리에는 아무것도 두지 않는다(S-FIG2의 둘째 항목은 머리와 얼굴이라 뺀다), 셋째 항목은 아래 `S-ARMS`, 넷째~일곱째 항목(선, 칠, 그림자, Do not add)은 S-FIG2 그대로.
  5. 색: C-FIG2 그대로.
  6. 바탕: P1의 `Background:` 블록 그대로(`one plain flat light grey color, about #D8D8D8, …`. `STYLE_SPEC.md` "P1의 `Image:`·`Subject:`·`Background:`"의 둘째 블록). A-1a의 바탕 지우기가 이 줄에 기댄다.
- F11의 세 구절(`new, original illustration` · `line weight` · `Do not add`)이 들어 있는지 본다.
- 새 블록(명세 5부의 블록 절에 더한다. 영어, ASCII만, 큰따옴표 없이. `<PART_LINES>`는 자리 표시다):

```
Image: Landscape, 1536x1024 pixels. One sheet of separate sword arm parts of one character for cutout animation in a 2D duel game.

Subject: Bartolo, the same character as in the first referenced image. Only his sword arm, his sword hand and his rapier, in a few different poses.
```

```
Pose and layout:
- The first referenced image is our own parts sheet of this character and it is the character reference: draw exactly the same sleeve, the same fist and the same rapier, with the same drawing style, the same shapes, the same colors and the same line weight.
- The second referenced image is our own pose sketch. It shows how many parts there are, where each part goes on the sheet and the pose of each part. Follow its poses and its places. Do not copy its flat grey shapes: every part looks like the first image.
- Each arm is one straight shape from the shoulder to the wrist, with no bend at the elbow, as in the first image. Every part stands straight up and down on the sheet, not tilted, exactly as in the second image.
<PART_LINES>
- Each part is drawn complete. Clear empty space between all parts. No part touches or overlaps another. No body, no head, no labels, no numbers, no guide lines, no dots. Nothing is cropped.
```

```
- Keep exactly the amount of detail of the first referenced image: the same cuff line, the same fingers on the fist and the same guard and grip on the rapier. Nothing else is added. No puffy sleeves, no extra wrinkles.
```

- `<PART_LINES>`: 고른 동작마다 `- Part N: ` 로 시작하는 영어 한 줄(무엇이 드는지, 방향, 앞으로 줄어 보이는지). 보기: `- Part 1: the sword arm with the fist, pointing straight up: the shoulder end at the bottom, the cuff and the fist at the top, the fist seen from the front as if gripping a sword held overhead.` · `- Part 2: the sword arm, the fist and the rapier pointing straight at the viewer, strongly foreshortened: a short upright sleeve with the shoulder end at the top, the fist in front below it, the guard as a round shape and only a short piece of the blade.`
- 고칠 때는 P-KEEP-SHEET(`STYLE_SPEC.md`) 그대로, 넣는 그림은 직전의 팔 시트 하나, `Change:` 줄에 사용자가 짚은 한 가지.
- 파일 이름: `026-A1<차례>-bartolo-arms`(그림 `generated/`, 프롬프트 `docs/style/prompts/`).

### 판정 (보이기 전에 메인이 본다. 있는 도구로)

| # | 무엇 | 도구 | 굳은가 |
|---|---|---|---|
도구가 실제로 내는 값으로 적는다(v3, T2·T3). 아래의 "손질본"은 `measure.ps1 -Src <원본> -Cut <손질본>`(허용 차 28)이 낸 그림이다.

| # | 무엇 | 도구와 그 출력 | 통과 | 굳은가 |
|---|---|---|---|---|
| A-1a | 바탕이 한 색이다 | `measure.ps1 -Src -Cut`의 출력 줄 `bg #RRGGBB borderSpreadR n … cornersAlpha a,b,c,d` | `bg`의 세 채널이 `#D8D8D8`의 ±16 안(021~024의 바탕은 `#D2D1D1`~`#D4D4D3`), `borderSpreadR` ≤ 6(021~024는 2~3), `cornersAlpha` 넷 모두 0 | 굳음 |
| A-1b | 파츠가 서로 닿지 않고 바탕 지우기가 파츠 안으로 새지 않는다 | 새 로컬 도구 `blobs026.ps1`(`scan.ps1`처럼 `Add-Type`의 C#): 손질본의 alpha ≥ 128 화소를 8방향으로 이어 덩이를 세고, 500화소 이상인 덩이마다 `blob,<n>,<x0>,<y0>,<x1>,<y1>,<px>`를 낸다 | 덩이 수 = `<PART_LINES>`의 줄 수. 새는지는 메인이 손질본을 Read로 보아 파츠 안의 구멍이 없는지 본다 | 덩이 수는 굳음, 구멍은 눈 |
| A-2 | 선 색·굵기·평평한 칠 | `calib024.ps1`의 복사본 `calib026.ps1`: `Sheet()`의 재는 자리를 팔 파츠로 바꾼다. 파츠마다 A-1b의 상자에서 소매 길이의 1/3·2/3 높이의 가로줄 둘, 양옆에서 들어가는 K2 점 넷(시작 x는 상자의 가장자리 밖 4화소), K3′ 상자 하나(소매 상자의 가로 가운데 50% · 세로 20~80%). `-Ppu`는 아래 A-4의 배율에서 셈한다. 출력은 `KM`의 세 줄(`K1 median r,g,b … PASS|FAIL`, `K2 widths […] median m (u units) … K2' out n PASS|FAIL`, `K3' min-sd per part […] PASS|FAIL`) | K1 `PASS`, K2′ `PASS`이고 `u`가 3.6~7.8, K3′ `PASS`(024의 얼린 기준) | 굳음 |
| A-3 | 상태 색이 얹힌다(G6/H8) | `measure.ps1 -Cut <손질본> -Regions "<이름>,x0,y0,x1,y1;…"`: 소매마다 A-2의 K3′ 상자와 같은 상자. 출력 `fill … median #… Y… || shadow … median #… Y…` | `fill`·`shadow`의 `Y`가 둘 다 0.30 이상. 선(Y < 0.22)은 K1이 그 정의로 고른 화소이므로 A-2의 K1 `PASS`로 본다 | 굳음 |
| A-4 | 크기가 024의 파츠와 맞는다 | `scan.ps1 -Img <손질본> -Rows "y,x0,x1"`의 출력(`a-b:LINE` 구간)에서 **첫 `LINE` 구간의 시작부터 마지막 `LINE` 구간의 끝까지**를 바깥 폭으로 잰다. 024 손질본(`generated/cut/024-P1a-bartolo-parts.png`): 팔 `-Rows "656,830,946"`(팔 상자 y 519~793의 가운데), 주먹 `-Rows "639,1051,1170"`(주먹 상자 y 585~693의 가운데). 새 시트: A-1b의 상자에서 소매의 가운데 높이, 주먹의 가운데 높이(앞으로 줄어 보이는 파츠는 주먹만) | 배율 f = 새 주먹 폭 ÷ 024 주먹 폭. 소매 폭 ÷ f가 024 팔 폭의 0.85~1.15배(앞으로 줄어 보이는 파츠는 소매를 재지 않고 적기만). A-2의 `-Ppu` = (337 ÷ 200) × f(024 시트의 목~골반 337화소 = 200단위) | 굳음 |
| A-5 | 안내도를 따랐다: 파츠가 세로로 서 있고 팔꿈치가 굽지 않았다 | 메인이 Read로 본다. 세로는 A-1b 상자의 높이 ÷ 폭(소매 + 주먹 파츠는 2 이상)으로도 본다 | 눈(비는 적는다) | 눈 |
| A-6 | 끼운 뒤 R1·R2 | `sil` + `sil026.ps1`(`art=1`) | 값을 적는다 | 적기만 |

- 보이기 전의 다시 뽑기는 A-1a·A-1b(자를 수 없음)·A-3·기술 실패에만, 그림마다 한 번(024와 같다). A-2·A-4에 걸리면 B에 "걸린 그림"으로 올린다(사용자가 고친다·뺀다를 고른다).
- 자르기: 바탕을 지운 손질본을 `generated/cut/`에 두고, 파츠마다 관절(어깨: 소매 윗끝의 가운데, 손목 또는 칼을 쥔 점)을 `scan.ps1`로 읽어 `ARMS`에 `joint`·배율·자르는 상자를 적는다(024의 `SHEET.a`와 같은 꼴).
- 그림 호출의 절차와 막는 장치는 `docs/style/GENERATION.md` "절차" 그대로다(모델·추론·read-only, 부른 도구는 그림 도구 하나, `config.toml` 해시와 저장소의 전후 대조, 이전 그림 수).

## 승인 (결정 239)

### 승인 A — 어깨 회전의 포즈와 움직임을 본 뒤 (작업 5 뒤)

선택지 도구로 한 번에 묻는다. 거부되면 같은 선택지를 한 번 더 띄우고, 또 거부되면 글로 묻는다.

| # | 물음 | 선택지 | 권함을 정하는 법 |
|---|---|---|---|
| A1 | 공격 넷의 어깨 회전 포즈 | 맞다 / 고칠 것을 적는다 | 메인이 R1·R2의 값과 띠를 보고 한 줄로 |
| A2 | 예비 동작의 움직임 | 가. 지금처럼 고르게(`curve=game`) / 나. 멈칫하고 짧게 휘두르고 느리게 회수(`curve=hold`). 두 선택지의 설명에 같은 한 줄을 넣는다: "나의 휘두름(0.10~0.15초)은 패리 창 안이다. 반응 싸움이 되는지는 이 견본으로 판단하지 않고 4단계 플레이로 본다. 되면 가나 곡선 값으로 되돌린다." | "나": 멈칫 동안 예비 동작의 실루엣(`hold`)이 예비 동작의 60~66%(찌르기·베기 0.8 − 0.2, 큰 베기 0.864 − 0.2) 동안 거의 그대로 머물러 읽을 틈이 길다. 근거는 R1·R2의 값(`p=0.25`·`0.6`이 같은 실루엣)이다. "나"에서 R1·R2가 "가"보다 나빠지면 "가" |
| A3 | 따로 그릴 팔(여럿 고를 수 있다) | 후보마다 한 칸(셋까지) / 없음 — 어깨 회전으로 충분 | 고친 뒤에도 R1·R2에 걸린 것. 걸린 것이 없으면 메인이 눈으로 본 까닭이 있는 것만, 없으면 "없음" |

- A에서 보이는 것: `motion-pair`의 경로(브라우저로 연다), 구운 장의 경로(`pose-pair` 넷, `pose-states`, `strip` 열, `far-read`, GIF가 있으면 그것), R1·R2·R4의 표(두 열), 고친 값과 까닭, 걸린 확인(있으면 맨 앞).
- **A에서 알리기만 하는 것**(답이 없으면 이 계획의 값으로 간다): 포즈의 꼴(열과 단위), 곡선의 값 넷, 상태의 포즈(무너짐·방심·피하기), 받아넘김에 포즈를 더하지 않은 것, 4단계로 넘기는 것.
- **A′**: A1에서 고칠 것을 적거나 A2·A3에서 후보 밖의 답이 오면, 그것만 고쳐 다시 굽고 같은 물음을 묻는다. 두 번까지다. 그 뒤에도 정해지지 않으면 멈추고 남은 물음을 보고한다.
- A3의 선택지 설명에 "그림 몫 16장 안에서 그린다(고른 것만)"를 적는다. "없음"을 고르면 그림을 만들지 않는다.
- 기다리는 동안 `docs/HANDOFF.md` 1번을 그 자리("026 승인 A를 기다린다")로 적는다.

### 승인 B — 따로 그린 팔을 끼운 뒤 (A3에서 고른 것이 있을 때만)

- 그림마다: 맞다 — 올린다 / 고친다(무엇을 적는다) / 뺀다(그 동작은 어깨 회전으로 둔다). 024의 B와 같은 꼴이다.
- 보이는 것: 팔 시트(원본과 손질본), A-1~A-4의 값, `arm-art`(끼운 `pose-pair`), A-6의 R1·R2, 쓴 장 수와 남은 몫.
- 고친다면 P-KEEP-SHEET로 그 그림만 다시 그리고 B를 되풀이한다. 몫을 다 쓰면 멈추고, 그때의 그림과 남은 고칠 거리를 보고한다.

## 명세에 적을 것 — `docs/style/STYLE_SPEC.md`의 새 5부

"# 4부. 글꼴·UI·크기 기준"과 "# 프롬프트 블록" 사이에 `# 5부. 자세와 모션 (계획 026)`을 둔다. 있는 절은 고치지 않는다(머리의 셋째 줄이 이미 "027의 `docs/STYLE_BIBLE.md`"인지 보고, 아니면 그 줄만 고친다).

| 5부의 절 | 담는 것 |
|---|---|
| 머리 | 값은 견본(`samples/026-pose-motion.html`)의 SVG에서 세운 것이다. Godot의 `Node2D` 회전과 방향은 같지만(시계 방향 +) 4단계에서 게임 화면으로 다시 본다. 팔의 방법(결정 220)과 사용자의 답 |
| 포즈의 꼴 | 이 계획 "포즈의 꼴"의 열과 단위, 칼의 지역 각 셈, 범위(`lean_deg` ≤ 6, 어깨 이동 ≤ 25), 거울 규칙(제안) |
| 포즈의 표 | `pose-table`을 그대로 옮긴 표(공격 넷 × 국면 넷, `idle`·`stagger`·`complacent`, 피하기의 고개). 출발 값과 고친 값을 함께, 고친 까닭 한 줄씩. 지금 게임의 값(`game-table`)도 한 표로 |
| 움직임 | 시간표의 규칙과 손 계산의 표, 고른 곡선과 값 넷, "타격 순간은 바뀌지 않는다"·"돌아감은 빠르게"의 두 규칙 |
| 원칙 4의 확인 | R1·R2·R4의 정의와 문턱, 두 열의 잰 값, 도구(`sil026.ps1`)와 그 맞음 |
| 따로 그린 팔 | 정하는 법, A3의 답, 그렸다면 블록(`P-ARMS`의 두 블록과 `S-ARMS`)과 프롬프트의 차례, "세로로 그리고 견본이 돌린다"는 규칙, 넣은 그림, 판정의 값, 관절·배율·자르는 상자, 끼우는 때 |
| 4단계로 넘기는 것 | 아래 목록 |

**4단계로 넘기는 것**(제안으로만 적는다. 이 계획은 코드와 데이터를 고치지 않는다):

- `AttackData`의 포즈 필드: 지금의 `pose_arm_offset`·`pose_sword_rotation`(팔 자리·칼 각 하나씩)을 국면마다의 값으로 바꾼다. 이름의 보기(ASCII): `tell_arm_deg`, `tell_sword_deg`, `hold_arm_deg`, `hold_sword_deg`, `strike_arm_deg`, `strike_sword_deg`, `recover_arm_deg`, `recover_sword_deg`, `tell_lean_deg`, `tell_shoulder`, `arm_art`. 지금 코드의 상수 `STRIKE_OFFSET`·`STRIKE_ROTATION`(방향마다 같은 타격)은 공격의 데이터로 옮긴다.
- `OpponentData`: `idle_arm_deg`, `idle_sword_deg`, `stagger_*`, `complacent_sword_deg`, 곡선의 값 넷(`tell_in`, `swing`의 비율과 여유, `creep_deg`, 돌아감 시간). 지금 코드의 상수(`REST_SWORD_ROTATION`, `STAGGER_*`, `COMPLACENT_SWORD_ROTATION`, `DODGE_*`)를 옮긴다.
- `opponent_view.gd`: `_arm.rotation`을 쓰고, 예비 동작의 진행에 곡선을 건다. 따로 그린 팔은 Arm 아래에 그림을 둘 두고 국면의 경계에서 보이기를 바꾼다(노드 이름과 관절은 결정 12 그대로).
- 지금 게임에 있는 문제 둘(큰 베기의 얼굴 가림, 칼끝이 상태 글자 상자에 듦)이 고른 포즈에서 얼마나 줄었는지(R2·R4의 두 열의 값)와 남은 것.
- 칼 팔이 오른쪽인 상대의 거울 규칙, 밀착에서의 포즈(지금은 크기만 다르다), 내 손과 칼의 움직임.
- **`hold` 곡선의 휘두름과 패리 창의 겹침을 플레이로 확인한다**(v3, D1): 고른 곡선이 `hold`면 게임에 넣은 뒤 플레이(사용자 또는 playtester)로 본다. 볼 것: 플레이어가 고리가 아니라 휘두름을 보고 누르는지, 큰 베기의 패리 성공률이 `game` 곡선보다 떨어지는지. 그러면 `game` 곡선으로 돌리거나 `MOTION`의 값(`swing`·`tell_in`)을 바꾼다. 곡선은 데이터의 값이라 코드 없이 되돌릴 수 있게 둔다.

## 작업 목록

**공통 규칙**

- "넘지 않는 선"을 지킨다. 코드·파일과의 대조가 어긋나면 값을 맞추지 말고 멈춰서 보고한다(R1·R2에 걸리는 것은 "대조"가 아니다. "고치는 길"대로 한다).
- 편집은 작게 나눠 한다(견본은 함수 하나·섹션 하나씩, 명세는 절 하나씩).
- 구운 PNG와 `--dump-dom`의 결과는 scratchpad의 `026\`에 둔다. 아래에서 "굽는다"는 모두 `docs/style/generated/tools/bake025.ps1 -Page 026-pose-motion.html -OutDir 026 -Budget 5000`이다(도구 안의 scratchpad 경로가 이 세션의 것이 아니면 고친 복사본을 쓴다. 한글이 든 `.ps1`은 BOM을 지킨다). "값을 읽는다"는 같은 도구의 `-DumpDom -DomQuery "?…" -DomOut <이름>.html`이다.
- 견본의 스크립트 문법: `<script>`의 안을 scratchpad의 `.js`로 떼어 `node --check`로 본다. 고칠 때마다 다시 본다.
- 빈 장면이 나오면 `--dump-dom`의 `<body data-error="…">`를 읽는다. `data-ready="1"`이 없으면 그 굽기는 실패로 센다.

### 작업 0. 시작 상태

- `git status --short`를 처음 값으로 적는다(024·025의 변경이 커밋 전이다). 처음 값에 더해진 것이 이 계획 파일뿐인지 본다.
- `docs/style/samples/020-bridge.html`~`025-type-ui-size.html` 여섯의 `Get-FileHash`를 적는다(024·025는 커밋 전이라 git diff로 볼 수 없다).
- Glob으로 로컬 자료를 본다: `generated/cut/024-P1a-bartolo-parts.png`, `generated/023-R2-stage-alley.png`, `generated/fonts/`의 고른 둘(Noto Sans KR, 나눔스퀘어라운드), `tools/`의 `bake025.ps1`·`scan.ps1`·`measure.ps1`·`calib024.ps1`·`kmeasure.ps1`·`run-codex.ps1`·`bake023.ps1`(크기 분기를 `bake026.ps1`에 옮긴다).
- `node --version`, `Get-Command ffmpeg, magick -ErrorAction SilentlyContinue`의 결과를 적는다.
- 완료 확인: 결과가 보고서 2번에 있다. 생성 그림이 없으면(다른 컴퓨터) 견본은 SVG 바르톨로로 그리고 "파츠가 없어 SVG로 그렸다"를 A의 맨 앞에 적는다. `tools/`나 `node`가 없으면 멈추고 보고한다.

### 작업 1. 지금 게임의 값을 옮기고 대조한다

- "지금 게임의 포즈"의 표를 견본의 `GAME`·`ATTACKS`로 옮긴다. 줄마다 출처의 파일·행을 주석으로 둔다.
- 완료 확인:
  - Grep으로 코드에서 값이 잡힌다: `opponent_view.gd`에서 `CHEST := Vector2\(0, -180\)`, `SHOULDER_X := 65.0`, `REST_SWORD_ROTATION := -25.0`, `Vector2\(-120, 40\), Vector2\(0, 60\), Vector2\(120, 40\)`, `-120.0, 180.0, 120.0`, `STAGGER_ARM_DROP := Vector2\(0, 50\)`, `STAGGER_SWORD_ROTATION := 165.0`, `STAGGER_HEAD_ROTATION := 0.4`, `COMPLACENT_SWORD_ROTATION := -140.0`, `DODGE_HEAD_ROTATION := -0.35`, `RING_SPEED := 240.0`. `opponent_01.tres`에서 공격 넷의 `tell_time`·`recovery_time`·`pose_arm_offset`·`pose_sword_rotation`과 `stagger_time = 1.5`, `idle_time_min = 0.9`, `parried_recovery_bonus = 0.85`, `whiff_recovery_multiplier = 0.55`, `close_tell_multiplier = 0.8`. `rapier.tres`에서 `parry_window = 0.18`. 잡힌 값이 견본의 `GAME`·`ATTACKS`와 같다.
  - `game-table`의 값이 손 계산과 같다(024 견본의 장면과 같은 점이다): 찌르기 예비 동작 진행 0.3 → 팔 (0, −211)·칼 180, 큰 베기 진행 0.25 → 팔 (0, −277.5)·칼 45, 왼쪽 베기 회수 → 팔 (−120, −140)·칼 −120, 무너짐 → 팔 (−65, −130)·칼 165·고개 22.9.
  - `timeline`의 여덟 줄이 "움직임"의 손 계산 표와 같고, `swing`·`hold_end`가 "국면 안의 곡선"의 손 계산(찌르기 0.13·0.80, 베기 0.15·0.80, 큰 베기 0.15·0.864, 밀착의 큰 베기 0.15·0.830)과 같다.

### 작업 2. 견본의 뼈대 — `docs/style/samples/026-pose-motion.html`

- "견본"대로 025를 복사해 덜어 내고, `opp()`의 더함 셋, 표 다섯, 주소 인자, `<pre>` 다섯, 움직이는 길(`t`가 없을 때의 `requestAnimationFrame`과 `data-frames`)을 넣는다. 섹션 열(1~10)을 두고 아직 그리지 않은 것은 "만드는 중"으로 둔다.
- 완료 확인:
  - Grep `<section id="`가 10건이고 "견본"의 표의 id·차례와 같다.
  - 바깥 자원: 025 작업 2의 Grep 여덟(`(src|href)\s*=\s*["']?https?:`, `url\(\s*["']?https?:`, `<img`, `<link`, `@import`, `fetch\(`, `data:image`, `reference/`) 모두 0. `url\(`로 잡힌 줄은 `url(#…)`이거나 `../generated/fonts/`로 시작하는 것뿐이다.
  - `node --check` 통과. `-DumpDom`의 결과에 `data-ready="1"`이 있고 `data-error`가 없다. `font-status`의 줄이 모두 `loaded`다.
  - `-DumpDom -DomQuery "#motion-pair"`(`t` 없음)의 결과에서 `data-frames`가 10보다 크다(가상 시간 5초 동안 움직임이 돌았다). 0이면 돌림을 `setTimeout(16)`으로 바꿔 다시 보고, 바꾼 것을 보고서 3번에 적는다.
  - 020~025 견본의 해시가 작업 0의 값과 같다.

### 작업 3. 포즈 섹션 — 출발 값으로 세운다

- `fromGame()`으로 `POSES`의 `start`를 채우고 `final`을 처음에는 `start`로 둔다. `pose-pair`(공격 넷)와 `pose-states`를 그린다.
- 완료 확인:
  - `pose-table`(이때는 `start`와 같다)의 `arm_deg`·`sword_deg`가 "출발 값"의 손 계산 표와 소수 첫째 자리까지 같다(여덟 칸). `idle`이 23 · −21이다. `recover_end` 넷이 "무너짐과 갈리는 기준"의 표와 같고 `pose-check`가 모두 `ok`다.
  - 다섯 장(`pose-pair` 넷, `pose-states`)이 1280×720으로 구워지고, 메인이 Read로 보아 칸마다 파츠가 이어져 있다(팔이 어깨에서 떨어지거나 칼이 주먹에서 떨어진 칸이 없다). 떨어진 칸이 있으면 `opp()`의 지역 각 셈이나 관절을 고친다.
  - 지금 게임 줄의 칸이 024 견본의 같은 상태와 같아 보인다(024 `STATES`의 넷: 대기, 찌르기 진행 0.3, 왼쪽 베기의 빈틈, 무너짐을 같은 인자로 그렸다).

### 작업 4. 재기와 고치기

- `sil-check` 네 장을 굽고 `sil026.ps1`을 만든다(로컬 `docs/style/generated/tools/`. BOM). 도구의 맞음을 본다.
- 지금 게임 열과 출발 값의 어깨 회전 열을 재고, "고치는 길"대로 `final`을 고쳐 다시 잰다.
- 굽는 장(한 번 잴 때. 열 하나마다): `sil+col=<열>+atk=<공격>+ph=tell+p=0.25|0.6+dist=mid|far` 16, `ph=recover`(교전) 4, `ph=idle`(교전·멀리) 2, `ph=complacent` 1, `noarm=1`(교전) 1, R4의 밀착 `p=0.25` 4 = 28장. 두 열에 56장, 고칠 때마다 고친 공격의 장만 다시 굽는다.
- 완료 확인:
  - 재기 전의 확인(견본이 색을 바로 칠했는가): `noarm=1` 장의 `count`에서 빨강 > 0·파랑 = 0, 공격 장마다 파랑 > 0·빨강 > 0. 아니면 견본의 필터를 고친다.
  - `sil-check`에서 겹침 0.333 ± 0.01과 가림 0.300 ± 0.01이 나오고, 같은 장을 두 번 재어 값이 같다. 아니면 도구를 고치고, 고칠 수 없으면 R1·R2를 눈의 확인으로 내리고 A의 맨 앞에 적는다.
  - R1·R2·R4의 표가 두 열 모두 있다(겹침: 쌍 열 × 진행 둘 × 간격 둘 = 40, 가림: 공격 넷 × (`tell` 둘 + `recover`) + `idle` + `complacent` = 14, 상자: 교전·밀착 × 공격 넷 = 8).
  - 어깨 회전 열의 R1·R2가 통과하거나, 공격마다 세 번 고친 기록(값과 잰 값)이 있고 걸린 것이 A3의 후보로 적혀 있다.
  - 고친 값이 "포즈의 꼴"의 범위(`lean_deg` ≤ 6, 어깨 이동 ≤ 25) 안이다. "고치는 길"의 각 범위를 벗어난 값은 까닭이 견본의 주석에 있다.
  - `pose-check`의 네 줄이 모두 `ok`(갈린 수 ≥ 2. "무너짐과 갈리는 기준")이다. 출발 값에서는 "고치는 길"의 손 계산 표와 같다. `pose-pair`·`pose-states`를 `final`로 다시 구워 Read로 본다.

### 작업 5. 움직임 섹션과 굽기 (→ 승인 A)

- `strip`, `motion`, `motion-pair`, `far-read`를 그린다. 굽는다: `strip` 10장, `motion` 3장, `motion-pair+t=1.2` 1장, `far-read` 1장. GIF는 작업 0에서 도구가 있었을 때만.
- 완료 확인:
  - 열다섯 장이 1280×720이고 Read로 보아 빈 장면·깨진 글자(네모)가 없다. 상태 글자가 Noto Sans KR 900으로, HUD가 나눔스퀘어라운드로 그려졌다(`font-status`가 `loaded`이고, 눈으로는 025 B′의 장과 견준다).
  - `t`가 먹는다: `motion+atk=big+col=rot+curve=hold+out=blocked+t=1.0`·`+t=1.5`·`+t=2.4` 세 장에서 국면이 다르게 보인다(대기와 예비 동작 시작 사이 / 멈칫 / 회수). 같은 `t`를 두 번 구워 `Get-FileHash`가 같다.
  - `strip`의 칸 머리의 시각이 `timeline`의 값에서 셈한 것과 같다(큰 베기·막힘: 대기 0.45, 예비 동작 10% 1.01 · 30% 1.23 · 60% 1.56 · 90% 1.89, 타격 2.00, 회수의 가운데 2.80, 회수 끝 0.1초 뒤 3.70. 나머지는 같은 셈으로 견본이 적는다).
  - 띠에서 `curve=hold`의 멈칫(30%와 60%의 칸이 거의 같은 포즈)과 빠른 휘두름(90%와 타격 칸의 차가 큼)이 보인다. 지금 게임 열은 30%·60%·90%가 고르게 옮겨 간다.
  - "승인 A"의 표대로 권함을 정하고 **A를 묻는다.** A′가 있으면 고친 것만 다시 굽고 묻는다(두 번까지). 답의 원문이 `docs/DECISIONS.md`에 옮길 수 있게 적혀 있다.

### 작업 6. 따로 그린 팔 (A3에서 고른 것이 있을 때만. 몫 16장 → 승인 B)

- `arm-guide`를 1536×1024로 그려 굽는다(v3, T4): `bake025.ps1`은 창을 1280×720으로 박아 두었으므로(43·49행) 크기 인자 `-Size "1536,1024"`를 더한 복사본 `bake026.ps1`(로컬 `tools/`. 023 `bake023.ps1`의 크기 분기와 같은 꼴: 원하는 크기로 창을 열고, 찍힌 크기가 다르면 차만큼 창을 늘려 한 번 더)을 만들어 `bake026.ps1 -Page 026-pose-motion.html -OutDir 026 -Budget 5000 -Size "1536,1024" arm-guide`로 굽고 `generated/in/026-in-arms.png`로 둔다. `arm-guide` 섹션은 1536×1024의 SVG 하나를 그린다(다른 섹션은 1280×720 그대로. `-Size`를 주지 않으면 지금과 같다).
- `blobs026.ps1`을 만든다(로컬 `tools/`. BOM. "판정" A-1b의 출력 꼴). 맞음은 안내도로 본다(아래 완료 확인의 첫 줄: 덩이 수가 안내도에 그린 파츠 수와 같다).
- 프롬프트를 "그리는 법"의 블록과 차례로 만들어 `docs/style/prompts/026-A1a-bartolo-arms.txt`에 둔다.
- **돌리기 전에 장 수를 사용자에게 알린다**(이번 한 장, 쓴 장과 남은 몫. 알리기만 하고 몫 안에서는 다시 묻지 않는다. 사용자 답 Q1). `run-codex.ps1`(scratchpad 경로를 이 세션의 것으로)로 부르고, 결과를 `generated/026-A1a-bartolo-arms.png`로 복사한다.
- "판정"의 A-1~A-5를 보고, 통과하면 잘라 `ARMS`에 넣고 `arm-art`를 굽고 A-6을 잰다. 그리고 **B를 묻는다.** 고친다면 P-KEEP-SHEET로 `026-A1b…`를 만들고 B를 되풀이한다.
- 완료 확인:
  - 안내도: `026-in-arms.png`가 1536×1024다(`bake026.ps1`의 `ok … 1536x1024` 줄). `measure.ps1 -Src <안내도> -Cut <scratchpad의 임시>`의 출력이 `bg #D8D8D8`·`borderSpreadR 0`이다. `blobs026.ps1`이 같은 손질본에서 낸 덩이 수가 `<PART_LINES>`의 줄 수와 같다.
  - 프롬프트 파일: ASCII만(비ASCII 0), 큰따옴표 0, Grep `-i "pizza|potion|tapblaze|niceplay|tinybuild|reference/|screenshot"` 0, F11의 세 구절이 있다, `<PART_LINES>`가 남아 있지 않다.
  - **블록의 차례와 빠짐**(v3, T5): 파일을 위에서 읽어 아래 머리가 이 차례로 한 번씩 나온다(Grep `-n`으로 행 번호가 커진다): `Task:` → `Image:` → `Subject:` → `Pose and layout:` → `Style (` → `Colors:`(C-FIG2의 첫 줄) → `Background:`. `Style (`과 `Background:` 사이에 S-FIG2의 넷째~일곱째 항목의 첫 낱말(`- Outlines:`, `- Fills:`, `- Shadows:`, `- Do not add:`)이 다 있다. 각 블록이 `STYLE_SPEC.md`의 원문과 글자 그대로 같다(그 블록을 떼어 `Compare-Object`).
  - 호출마다: 세션 기록의 모델 `gpt-6.2-sol`·추론 `high`·`read-only`, 부른 도구는 그림 도구 하나, `config.toml` 해시가 처음 값(`AA004752…186D`)과 같다, 호출 전후의 `git status --short`와 이전 그림 수가 같다. 기록이 `GENERATION.md`의 표 꼴로 적혀 있다. 넣은 그림 둘이 그림 도구에 넘어갔는지는 세션 기록에서 `in-1.png`·`in-2.png`의 경로를 Grep해 적되, 024처럼 셀 수 없으면 "확인 못 함"으로 적는다(굳은 확인이 아니다).
  - A-1a·A-1b·A-2·A-3·A-4의 출력 줄이 그대로 기록에 있고 "판정"의 통과에 맞다(못 하면 다시 뽑기의 규칙대로 하고, 그래도 못 하면 그 그림을 B에 "걸린 그림"으로 올린다).
  - 쓴 장 수가 몫 16장을 넘지 않는다.
  - B의 답 원문이 적혀 있다. "맞다 — 올린다"인 그림만 `docs/style/basis/bartolo-arms.png`(원본 그대로. `Get-FileHash`가 로컬 원본과 같다)로 올리고 `docs/style/basis/README.md`의 표에 한 줄과 손질 값(관절·배율·자르는 상자)을 더한다. 있던 줄은 바뀌지 않는다(`git diff`로 더한 줄만).

### 작업 7. 고른 것으로 마무리하고 명세에 적기

- A·B의 답대로 `POSES`(`final`, `arm_art`)와 `MOTION`(고른 곡선)을 고치고, `pose-pair` 넷, `pose-states`, `strip`의 어깨 회전 넷, `far-read`를 다시 굽는다. R1·R2·R4를 마지막 값으로 다시 잰다.
- `docs/style/STYLE_SPEC.md`에 5부를 "명세에 적을 것"대로 절 하나씩 쓴다. 쓰기 전에 그 파일을 scratchpad에 복사해 둔다.
- 완료 확인:
  - 다시 구운 장이 1280×720이고 Read로 보아 고른 포즈·팔 그림으로 그려졌다.
  - Grep `^# 5부`가 1건이고 "명세에 적을 것"의 일곱 절이 있다. "4단계로 넘기는 것"에 `hold` 곡선의 플레이 확인 줄(볼 것 둘과 되돌리는 길)이 있다. 5부의 포즈의 표가 마지막 `pose-table`(`-DumpDom`)과 줄마다 같다(메인이 두 글을 견준다). 잰 값이 마지막 재기와 같다.
  - scratchpad의 복사본과 견줘(`git diff --no-index`) 지운 줄이 없다(5부를 더하기만 했다). 프롬프트 블록의 있던 줄은 하나도 바뀌지 않았다. 5부의 코드 블록 안에 비ASCII 0·큰따옴표 0.
  - 파일 전체에서 Grep `-i "pizza|potion|tapblaze|niceplay|tinybuild"` 0.

### 작업 8. 기록과 보고

- `docs/DECISIONS.md`: 끝에 "2026-11-22 — 계획 026" 절. 결정 232~239 한 줄씩, 실행 중에 정한 것(고친 값과 까닭, 잰 값, Q1·A·A′·B의 답 원문, 쓴 장 수).
- `CLAUDE.md`: 9장 "현재 위치"의 한 줄만 고친다: 025를 닫은 말 뒤에 "계획 026(자세와 모션 시안)을 실행했다(날짜). 포즈와 움직임은 `docs/style/STYLE_SPEC.md` 5부에 있다. 다음은 027(STYLE_BIBLE)이다"가 되게 맞춘다. 고치기 전에 그 줄을 읽고 바꾼 전후를 보고서에 적는다. 다른 줄은 고치지 않는다.
- `docs/HANDOFF.md`: 1번을 그때의 자리(다음은 027)로, 3번에 "계획 026 보고서 4번" 한 줄.
- 그림을 만들었으면 `docs/style/GENERATION.md` 끝에 "계획 026" 절(준비, 기록, 승인 B와 마무리).
- `docs/reports/026-pose-and-motion.md`와 사용자 보고(10장 형식). 4번에 올릴 것: 026의 커밋(024·025와 함께), 고른 포즈와 곡선을 4단계에서 그대로 옮길지, 따로 그린 팔(그렸으면 몇 장, 아니면 4단계에서 그릴 것), 남은 원칙 4의 걸림, 휘두름이 반응 싸움이 되는지(4단계의 플레이로 본다). 5번: 027(STYLE_BIBLE). 3단계 완료 기준의 "STYLE_BIBLE.md 작성"이 남았다.
- **playtester에게 맡길 확인**: 새로 생기는 것이 없다(게임은 바뀌지 않았다). 024 보고서의 둘이 그대로 남아 있다. 팔 그림을 `basis/`에 올렸으면 "Godot이 그 PNG를 가져오지 않는다"가 그 둘에 든다.
- 완료 확인:
  - 보고서 2번에 "확인 못 한 것"이 있다: Godot에서의 회전과 그리는 차례(4단계), 실제 플레이에서 예비 동작이 읽히는지와 휘두름의 반응 싸움, 사용자의 브라우저에서 `motion-pair`가 도는지(메인은 headless의 `data-frames`로만 보았다), 멀리에서의 읽힘(눈으로만).
  - 끝의 `git status --short`가 작업 0의 처음 값에 이 계획 파일, `docs/style/samples/026-pose-motion.html`, `docs/reports/026-pose-and-motion.md`, (그렸으면) `docs/style/prompts/026-*.txt`·`docs/style/basis/bartolo-arms.png`를 더한 것과 같다(`CLAUDE.md`·`docs/DECISIONS.md`·`docs/HANDOFF.md`·`docs/style/STYLE_SPEC.md`·`docs/style/GENERATION.md`·`docs/style/basis/README.md`는 처음 값에 이미 있거나 이 계획이 고친 것이다). `scripts/`·`scenes/`·`data/`·`tests/`·`project.godot`·`assets/`·`docs/BACKLOG.md`의 변경이 처음 값에서 달라지지 않았다. 020~025 견본의 해시가 작업 0의 값과 같다.

## 설계 결정

모두 planner가 정했다(사용자 지시 "꼭 결정해야 되는 것만 묻는다"). 사용자가 고르는 것(포즈, 곡선, 따로 그릴 팔, 그림)은 견본을 본 뒤 A·B에서 정해진다.

| # | 결정 | 이유 | 되돌리기 |
|---|---|---|---|
| 232 | 026은 견본 하나(`026-pose-motion.html`)에서 포즈·움직임·따로 그린 팔을 한 계획에 둔다. 승인은 A(포즈·곡선·그릴 팔)와 B(그렸을 때만) | 팔 그림이 필요한지는 어깨 회전의 포즈를 세워 보아야 안다. 같은 견본에서 끼워 다시 잰다 | 쉬움 |
| 233 | 포즈 하나는 `arm_deg`·`sword_deg`(화면 기준)·`head_deg`·`lean_deg`·어깨 이동·`arm_art`의 한 줄이고 국면은 `tell_start`·`hold`·`strike`·`recover_end`(공격마다)와 `idle`·`stagger`·`complacent`(상대마다). 각은 도, 시계 방향 + | 원칙 5: 4단계가 필드로 그대로 옮긴다. 칼을 화면 기준으로 적어야 팔을 고쳐도 칼의 읽힘이 바뀌지 않는다. `lean`(≤ 6)과 어깨 이동(≤ 25)은 G1과 "어깨 회전이 기본"을 지키는 상한이다 | 쉬움(열) |
| 234 | 어깨 회전의 출발 값은 지금 게임의 손 방향(`fromGame()`), 대기는 결정 220의 "다". 메인이 공격마다 실루엣의 집안(가로 · 바깥 위 사선 · 몸 앞 사선 · 가장 큰 세로)을 향해 세 번까지 고친다 | 지금 게임의 읽힘(방향)을 지키며 시작한다. 손으로 박은 값보다 대조할 수 있다. 실루엣의 집안이 달라야 색 없이도 읽힌다(원칙 4) | 쉬움 |
| 235 | 원칙 4는 한 색 실루엣 굽기와 새 로컬 도구 `sil026.ps1`로 잰다: R1 칼 팔의 겹침 ≤ 0.30, R2 얼굴의 가림 ≤ 0.10, R4 상태 글자 상자의 칼은 적기만. 문턱은 임시이고 지금 게임 열을 함께 적는다. 도구는 알려진 도형으로 먼저 맞춘다 | 앞의 세 계획이 "잴 수 없는 확인"으로 REVISE를 받았다. 생성 그림이 든 SVG는 캔버스로 옮겨 재기 어려워 PNG를 굽고 화소를 센다. 색을 빼야 실루엣만 견준다 | 쉬움(문턱) |
| 236 | 움직임은 상대 데이터의 시간만 쓰고, planner의 곡선 `hold`(진행 0.2까지 들기, 멈칫하며 8° 더 당김, 마지막 `swing` = min(0.2 × 예비 동작, 패리 창 − 0.03)초의 휘두름, 회수 내내 느린 늘어짐, 돌아감 0.2초)를 시안으로 지금 게임의 `game`과 나란히 보인다. 타격 순간은 바뀌지 않는다. 반응 싸움인지는 4단계 플레이로 본다 | 멈칫 동안 예비 동작의 실루엣이 오래 머물러 읽을 틈이 길다(원칙 4. R1·R2로 본다). 휘두름을 정한 시간으로 두면 공격마다 같은 리듬이고 늘 패리 창 안에서 시작한다. 고리와 판정의 시각을 건드리지 않는다. 돌아감이 느리면 빈틈이 끝난 뒤에도 열린 것처럼 보인다. 사용자의 원문에는 곡선에 대한 말이 없다(시안이다) | 쉬움(값 넷) |
| 237 | 따로 그린 팔은 어깨 회전으로 세워 본 뒤 걸린 것(R1·R2, 또는 메인이 눈으로 본 까닭)만 후보로 올리고 사용자가 A3에서 고른다. 그리면 팔 파츠만의 작은 시트(우리 파츠 시트 + 1536×1024로 구운 우리 자세 안내도, 바탕 `#D8D8D8`), 파츠는 팔의 축이 세로로 서게 그리고 기울기는 견본이 준다. 프롬프트는 024 P1과 같은 차례(지시 → Image·Subject → Pose and layout → Style → Colors → Background). 판정은 도구가 내는 값으로(A-1a~A-4). 고칠 때 P-KEEP-SHEET. 끼우는 것은 국면의 경계에서만 | 결정 220("큰 동작만 따로"). 024의 파츠와 같은 사람·같은 꼴이어야 하므로 기준 시트를 넣는다. 자세는 말보다 안내도가 옮긴다(023 길 "가") | 쉬움(그림을 빼면 어깨 회전으로 돌아간다) |
| 238 | 견본은 `t`로 한 시각을 그리고, 없으면 움직인다. 구운 그림은 띠(여덟 칸)와 한 장씩. GIF는 도구가 있을 때만 | Edge headless의 스크린샷은 한 장뿐이다. 사용자는 브라우저로 움직임을 본다 | 쉬움 |
| 239 | 승인은 A(물음 셋: 포즈, 곡선, 그릴 팔)와 B(그림마다). 결과는 `STYLE_SPEC.md` 5부에 4단계의 필드 이름 보기와 함께 적고, 게임은 고치지 않는다 | 눈으로 고를 것만 묻는다. 결정 219. 027의 STYLE_BIBLE과 4단계가 입력으로 쓴다 | 쉬움 |

## 위험

1. **어깨 회전만으로는 공격이 서로 비슷하다**(팔 한 덩이와 칼 하나뿐이다). 대비: 실루엣의 집안을 공격마다 정하고, 세 번 고쳐도 걸리면 따로 그린 팔의 후보로 올린다. 문턱이 가르지 못하면 사용자의 눈으로 한다.
2. **`hold` 곡선이 반응 싸움을 부른다**: 짧은 휘두름(0.10~0.15초)이 패리 창(0.18초. 타격 전 0.18초 안에 새로 누른 막기)과 겹친다. 대비: 타격 순간과 고리는 그대로이고, 휘두름은 정해진 짧은 시간이라 늘 패리 창 안에서 시작하며(큰 베기도 0.15초), 멈칫이 길어 무엇이 오는지는 더 오래 보인다. **확인은 4단계의 플레이에서 한다**(견본에는 입력이 없어 판단할 수 없다): 플레이어가 고리가 아니라 휘두름을 보고 누르는지, 큰 베기의 패리 성공률이 `game` 곡선보다 떨어지는지. 떨어지면 `game` 곡선이나 `MOTION`의 값(`swing`·`tell_in`)을 바꿔 되돌린다. 명세 5부 "4단계로 넘기는 것"과 보고서 4번에 적는다.
3. **큰 베기를 높이 들면 칼이 상태 글자 상자로 더 들어간다**(얼굴을 비키려면 팔이 위로 간다). 대비: R4를 두 열로 적고 칼을 머리 뒤로 눕히는 쪽을 먼저 본다. 글자는 칼 위에 그려져 읽힘은 그대로다.
4. **크게 돌린 팔의 이음매**: 024의 팔 파츠는 아래로 늘어진 꼴로 그려져 크게 돌리면 어깨의 둥근 윗끝이 몸통에서 떠 보일 수 있다. 대비: 작업 3·4에서 칸마다 이음매를 본다. 떠 보이는 동작은 따로 그린 팔의 후보가 된다.
5. **따로 그린 팔이 024의 파츠와 다른 사람처럼 보인다**. 대비: 기준 시트를 넣고 A-2~A-4로 선·색·크기를 맞춘다. 사용자가 B에서 본다.
6. **장 수**. 대비: 몫 16장 안에서만 돌리고(돌리기 전에 알린다), 다시 뽑기는 그림마다 한 번.
7. **움직임이 사용자의 브라우저에서 돌지 않는다**(로컬 그림·글꼴). 대비: 띠와 한 장씩의 그림으로도 판정할 수 있다. 페이지 머리에 Edge·Chrome을 적는다.
8. **재기 굽기가 많다**(처음 56장, 고칠 때마다 더). 대비: 고친 공격의 장만 다시 굽는다.
9. **포즈가 거만해 보인다**(큰 베기의 젖힘). 대비: `lean_deg`는 큰 베기에만, 6 이하. 사용자가 A1에서 본다.

## 실행 전에 물을 것 (검토 전에 메인이 선택지로 묻는다)

| # | 물음 | 선택지 | 권함 | 답에 따라 달라지는 것 |
|---|---|---|---|---|
| Q1 | 따로 그린 팔에 쓸 그림 장 수의 몫(상한) | 0장 / 4장 / 8장(planner의 권함) / 16장 | **답(2026-11-22, 선택 창): "16장"** | 몫은 16장이다. 몫 안에서는 장 수를 다시 묻지 않고 돌리기 전에 알리기만 한다. 실제로 그리는 것은 A3에서 사용자가 고른 동작뿐이다(작업 6) |

- 이 물음은 답을 받았다. 더 물을 것은 없다.
- 그 밖에는 묻지 않는다. 포즈·곡선·그릴 팔은 견본을 본 뒤 A에서 묻는다(사용자는 글보다 견본으로 고른다).

## 사용자 결정 필요 (실행을 막지 않는다. A에서 알리고 보고서 4번에 올린다)

| # | 무엇 | 이 계획이 정한 것 | 답이 다르면 |
|---|---|---|---|
| 1 | 포즈의 꼴(열과 단위)과 4단계의 필드 이름 | "포즈의 꼴"(결정 233) | 열 이름만 바뀐다 |
| 2 | 곡선의 값 넷 | `tell_in` 0.2 · `swing` = min(0.2 × 예비 동작, 패리 창 − 0.03) · 8° · 0.2초(결정 236) | 견본의 `MOTION`만 고친다 |
| 3 | 받아넘김·밀어붙임에 포즈를 더할지 | 더하지 않는다(지금 게임도 글자뿐) | 4단계 제안에 한 줄을 더한다 |
| 4 | 026의 커밋(024·025와 함께) | 정하지 않는다 | — |

- 3단계 완료 기준은 이 계획으로 채워지지 않는다(027이 남는다). 단계 진행은 사용자가 정한다.
- 보류 중인 것(그대로 둔다): 2단계의 값과 결정(`docs/HANDOFF.md` 3번), `docs/BACKLOG.md`, 024·025 보고서 4번의 것들.

## 수정 기록

v1 → v2 (검토 전. 사용자 답 Q1 "16장", 2026-11-22):

- "실행 전에 물을 것": 권함 8장 → 받은 답 16장. 몫 안에서는 다시 묻지 않고 알리기만 한다.
- 몫이 적힌 곳을 16장으로 바꿨다: "그리는 법"의 머리, 승인 A의 A3 설명(몫 0일 때의 "기록만" 줄을 지웠다), 작업 6의 머리·알리기 줄·완료 확인, 위험 6.
- 그 밖에 바꾼 것: 없다.

v2 → v3 (1회차 검토: design-reviewer REVISE D1, tech-reviewer REVISE T1~T5):

- **D1 (수용)**. "멈칫·빠름·느림"은 사용자의 원문이 아니다(메인이 HANDOFF에 풀어 쓴 말). 계획 어디에서도 사용자의 말로 돌리지 않는다.
  - (1) 승인 A의 A2 권함: "사용자가 말한 움직임" → "멈칫 동안 실루엣이 예비 동작의 60~66% 동안 머문다. R1·R2의 값". 결정 236의 이유도 같이 고쳤다. "목표와 범위" 2도 "planner의 시안"으로.
  - (2) A2의 두 선택지 설명에 "휘두름은 패리 창 안이다. 이 견본으로 판단하지 않고 4단계 플레이로 본다. 되면 가나 곡선 값으로 되돌린다"를 넣었다.
  - (3) 위험 2: "A2에서 사용자가 보고 고르고" → "확인은 4단계의 플레이에서"(볼 것 둘과 되돌리는 길).
  - (4) "명세에 적을 것"의 "4단계로 넘기는 것"에 `hold` 곡선의 플레이 확인 줄을 더했고, 작업 7의 완료 확인에 그 줄의 Grep을 더했다.
  - 비차단 제안(수용): 휘두름을 정한 시간 `swing = min(0.2 × 예비 동작, 패리 창 − 0.03)`으로 바꿨다(큰 베기 0.22 → 0.15초). "국면 안의 곡선"의 표와 손 계산, `timeline`의 두 열, 작업 1의 완료 확인, 결정 236, "사용자 결정 필요" 2.
- **T1 (수용)**: "고치는 길"의 `recover_end`를 "팔만 10° 늘어뜨림(칼·고개·어깨는 그대로)"로 고치고(칼을 15° 떨구는 것을 뺐다), 무너짐과 가르는 기준을 "팔 각 ≥ 15° · 칼 각 ≥ 30° · 어깨 ≥ 15 · 고개 ≥ 10° 가운데 둘 이상"으로 바꿨다. 공격 넷의 손 계산 표(갈린 수 2·3·4·2)와 `<pre id="pose-check">`를 더하고, 작업 3·4의 완료 확인을 그것으로 바꿨다.
- **T2 (수용)**: A-3의 도구를 `lum.ps1` → `measure.ps1 -Cut -Regions`(칠·그림자의 가운데 Y)로, 선은 A-2의 K1로 본다. 재는 상자는 A-2의 K3′ 상자(소매 상자의 가로 가운데 50% · 세로 20~80%)다.
- **T3 (수용)**: (가) 시트 위의 파츠는 팔의 축이 세로로 서게 그리고 기울기는 견본이 준다("그리는 법", `P-ARMS`의 한 줄, `<PART_LINES>`의 보기, A-5). (나) A-2의 `-Ppu` = (337 ÷ 200) × f, f = 새 주먹 폭 ÷ 024 주먹 폭(A-4). 024의 재는 줄(팔 y 656 · x 830~946, 주먹 y 639 · x 1051~1170)과 폭을 읽는 법(첫 `LINE` 시작 ~ 마지막 `LINE` 끝)을 적었다. (다) 새 로컬 도구 `blobs026.ps1`(이어진 덩이, 출력 `blob,…`)을 A-1b와 작업 6에 두었다. A-1은 A-1a(바탕: `measure.ps1` 출력의 `bg`·`borderSpreadR`·`cornersAlpha` 문턱)와 A-1b로 나눴다.
- **T4 (수용)**: 작업 6에 크기 인자를 더한 `bake026.ps1`(023 `bake023.ps1`의 크기 분기)로 `arm-guide`를 1536×1024로 굽는 길과, 크기·`bg #D8D8D8`·덩이 수의 완료 확인을 더했다. "견본"의 굽기 줄과 작업 0의 Glob에도 적었다.
- **T5 (수용)**: "그리는 법"에 블록의 차례 여섯(지시 → `Image:`·`Subject:` → `Pose and layout:` → `Style (` → `Colors:` → `Background:`)을 적고 P1의 `Background:`를 넣었다(024 `P1a`의 프롬프트 파일과 같은 차례다). 작업 6의 완료 확인에 차례·빠짐·원문 일치를 보는 항목을 더했다.
- 기술의 비차단 제안(수용): 실루엣의 한 색 필터를 파츠의 그림마다 건다("실루엣 굽기"). 작업 4에 재기 전의 확인(`noarm=1`의 빨강 > 0·파랑 = 0, 공격 장의 파랑 > 0)을 더했다.
- 스스로 훑어 고친 것:
  - 작업 6의 "넣은 그림 두 장의 경로"는 024에서 셀 수 없었던 확인이라 굳은 확인에서 뺐다(Grep해 적고, 못 세면 "확인 못 함").
  - 글꼴이 실제로 쓰였는지를 눈으로만 보던 것에 `<pre id="font-status">`를 더했다(작업 2·5). `<pre>`는 셋 → 다섯.
  - A-2·A-4에 걸린 그림은 다시 뽑지 않고 B에 "걸린 그림"으로 올린다(다시 뽑기는 A-1a·A-1b·A-3·기술 실패에만).
- 그 밖에 바꾼 것: 없다(포즈의 꼴, 출발 값, R1·R2·R4, 시간표, 섹션, 승인 A의 물음 셋, 장 수 16은 그대로다).
