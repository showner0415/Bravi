# 계획 029: 바르톨로를 결투에

- 버전: v3 (1회차 검토 대응: 디자인 D1·D2, 기술 T1·T2와 비차단 셋. 끝의 "검토 대응 기록". v2는 사용자 답 Q1 "맡긴다"와 028 뒤 확인의 결과를 반영했다)
- 개발 단계: CLAUDE.md 9장 **4단계(아트 교체)의 둘째 계획**. 처음으로 게임 코드·씬·데이터·테스트를 고친다. 그림은 만들지 않는다(Codex 호출 0).
- 근거:
  - 사용자 답(2026-11-22, 028 보고서 4번의 선택 창): 029를 시작한다. 포즈와 곡선을 게임에 **옮긴다 — 어깨 회전**(바이블 15절의 포즈 표를 데이터로). 그림의 원본 해상도는 **1920×1080까지**(파츠는 지금 그림 그대로, 무대는 031). playtester 실행 확인은 **맡긴다**.
  - 결정 12(파츠 이름·계층·원점), 결정 220·233·236·240(어깨 회전, 포즈의 꼴, 곡선 `hold`, 따로 그린 팔은 큰 베기 예비 동작과 찌르기 타격만), 결정 181·188·241(상태 색은 칠에만 80%, 문턱 Y 0.22·0.30, 칼은 받지 않는다), 결정 251·252(애셋은 잘라만 두었다, 이름).
  - 바이블 5절(파츠·상태 색의 층), 10절(간격 배율 0.55·0.85·1.1, 1920 기준), 11절(G4 교전 꼭대기 ≥ 142, R1 ≤ 0.30, R2 ≤ 0.10), 15절(포즈 표·곡선·두 규칙), 16절(넘긴 것), 명세 5부 "4단계로 넘기는 것"(필드 이름의 보기).
  - `assets/MANIFEST.md`(파츠 열 장의 크기·관절·단위/화소), 028 보고서 3번(경계의 밝은 화소 0, 윤곽 밖의 반투명한 어두운 번짐).
  - 견본 `docs/style/samples/026-pose-motion.html`: `opp()`(212~236행, 파츠 차례와 변환), `posesOf`·`tellPose`·`recoverPose`·`frameAt`(671~732행, 곡선과 머리 고르기), `tintFilters`(311~320행, Y 문턱의 식), `MOTION`(619행).
  - 지금 게임: `scripts/duel/opponent_view.gd`(팔은 옮기기만 한다: 190·208·222·232·239·242행), `scenes/duel/opponent_view.tscn`(Polygon2D `Shape`와 글자 `Label`), `scripts/ai/attack_data.gd` 20~26행(포즈 필드, "임시 — 4단계에서 대체"), `data/opponents/opponent_01.tres`.
  - 결정 번호는 254부터다.

### 넘지 않는 선

- 메인은 Godot·테스트·게임을 실행하지 않는다(`tests/run_tests.ps1`, `tests/run_smoke.ps1`, 헤드리스 Godot, `play.ps1`, 새 찍기 씬). PowerShell 도구, Edge headless 굽기, 화소 재기, `git`은 이 규칙 밖이다. 실행 확인은 사용자가 요청할 때 playtester가 한다(끝의 "playtester에게 맡길 확인").
- 판정은 바꾸지 않는다: `scripts/duel/duel_core.gd`, `scripts/ai/opponent_brain.gd`, 시간·자세·부위의 값은 그대로다. 이 계획의 코드는 **표시만** 바꾼다(타격 순간, 패리 창, 고리는 그대로. 바이블 15절 "타격 순간은 바뀌지 않는다").
- 고치지 않는 것: `assets/`의 그림(화소), `docs/style/basis/`, 견본 020~027, `docs/style/STYLE_SPEC.md`, 사용자의 파일(`tools/`, `.claude/agents/playtester.md`, `docs/plans/013-playtester.md`, `.codex/`, `AGENTS.md`). 내 손·칼(`player_sword_view`, 032), HUD·글꼴(033)도 건드리지 않는다.
- 편집은 작게 한다: Write 한 번과 Edit 한 번은 80줄 안쪽, 파일 하나·함수 하나씩.
- 실행 없이 고치는 스크립트는 HANDOFF 4번의 "기계적 확인 다섯"(들여쓰기는 탭만, 같은 함수 안의 이름 겹침, `:= .*\.get\(`·`:= .*\[`의 타입 추론, 서식 문자열의 자리 수와 `%%`, `@warning_ignore`의 위치)을 파일마다 본다.
- 코드 주석은 "왜"만 한 줄(CLAUDE.md 10장). 지키는 결정 번호를 적는다.

## 029와 030의 경계

| 계획 | 하는 것 | 까닭 |
|---|---|---|
| **029** | 파츠 그림 열 장을 결정 12의 노드에 건다, 상태 색·흰 번쩍임·조준 테두리를 한 셰이더로, 머리 셋을 상태마다, **팔은 어깨 회전**, 15절 포즈 표를 상대·공격 데이터로, **곡선 `hold`**(되돌리는 스위치도 데이터), 상대 그림을 데이터로, 그림 찍기 씬, 테스트 | 사용자가 "곡선도 옮긴다"고 답했다. 곡선은 데이터와 순수 함수라 헤드리스 테스트로 값까지 맞춰 볼 수 있다. 포즈와 곡선은 같은 코드(`update_view`의 팔·칼)를 한 번에 바꾼다 |
| 030 | 따로 그린 팔 둘(`armUp`, `armThrust`)의 자르기·`arm_art` 필드·국면 경계에서 바꿔 끼우기(Hand·Sword 감추기), 든 팔 주먹 그림자 고치기(그림 한 장, 결정 245), `hold` 곡선의 반응 싸움 플레이 확인(바이블 16절), 팔 그림을 끼운 뒤의 R1·R2 | 새 자르기(`bartolo-arms.png`)와 그림 한 장의 몫(사용자에게 물을 것)이 든다. 반응 싸움은 마지막 꼴(든 팔)에서 봐야 판정이 선다 |

- **029의 사이 상태**: 큰 베기의 예비 동작(15절 표의 `armUp`)과 찌르기의 타격·회수(`armThrust`)는 030까지 **보통 팔(`Arm`·`Hand`·`Sword`)을 표의 각도로 돌린다**. 큰 베기의 칼은 표의 `(−45)`를 쓴다(팔 그림이 없으므로 칼이 보인다). 이 모습은 견본의 `art=0`(026-pose-motion.html 753행 `USE_ART`)과 같다. 작업 0에서 그 모습의 R1·R2·R4를 먼저 잰다.

## 목표와 범위

**확인할 결과**:

1. 결투에서 바르톨로가 파츠 그림으로 나오고, 상태마다 포즈·머리·색이 바뀐다. 큰 베기의 얼굴 가림이 지금 게임(R2 0.317)보다 줄었다(작업 0의 값, 문턱 0.10).
2. 상태 색이 칠에만 80% 얹히고 선은 그대로다(바이블 5절). 칼과 모자는 상태 색을 받지 않는다. 닿은 부위의 흰 번쩍임과 조준 테두리가 그림 위에서 보인다.
3. 팔은 어깨에서 돈다. 예비 동작은 15절의 곡선 `hold`를 따르고, 고리가 0이 되는 순간에 `strike` 포즈다.
4. 포즈·곡선·그림은 `.tres`에 있고, 새 상대는 코드 없이 그림 `.tres`와 포즈를 더해 만들 수 있다(원칙 5).
5. 기존 테스트 65개가 그대로 통과하고(playtester), 새 테스트 셋(T65~T67)이 통과한다.
6. 사용자가 찍은 그림(게임의 렌더)을 보고 "맞다 / 고친다"를 고를 수 있다(끝의 "029 뒤 사용자가 볼 것").

**범위 밖**: 따로 그린 팔(030), 무대 그림(031. 029는 바탕 색만 바꾼다, 결정 262), 내 손·칼(032), HUD·글꼴·엉킴 경고의 자리(033), 칼 팔이 오른쪽인 상대의 그림과 포즈(결정 263), 감정 상태의 얼굴, MANIFEST의 `final` 판정(037).

## 설계 결정

254. **029·030의 경계**는 위 표다. 곡선은 029, 따로 그린 팔과 반응 싸움의 플레이 확인은 030.
255. **리그는 Node2D 파츠 + 잎 Sprite2D**: 결정 12의 노드(`Legs`, `Torso`, `Torso/Head`, `Torso/Head/Hat`, `Torso/Arm`, `Torso/Arm/Hand`, `Torso/Arm/Hand/Sword`)는 이름·계층·원점(관절)을 그대로 두고, 파츠마다 첫 자식으로 Sprite2D `Art`를 둔다(`centered = false`, `offset = −관절`, `scale = 단위/화소`). 깃털은 `Torso/Head/Hat/Feather`(Sprite2D, 모자 원점에 오프셋 없이, MANIFEST 11행). Polygon2D `Shape`와 글자 `Label`은 뺀다. 파츠는 굳은 판이라 Skeleton2D·Bone2D를 쓰지 않는다: 회전하는 Node2D가 곧 컷아웃이다. 변형(메시 굽힘)이 필요해지면 그때 Bone2D로 바꾼다(스크립트는 파츠를 Node2D 이상으로 가정하지 않는다, `opponent_view.gd` 7행). CLAUDE.md 7장의 "Skeleton2D 컷아웃 리깅" 구절을 이 뜻으로 고친다(작업 9). 되돌리기 쉽다.
256. **상대 그림은 데이터**: 새 Resource 둘. `PartArt`(`texture: Texture2D`, `joint: Vector2`(자른 그림의 화소), `units_per_px: Vector2`)와 `OpponentArt`(파츠 열: `legs`, `torso`, `head`, `head_oops`, `head_dizzy`, `hat`, `feather`, `arm`, `hand`, `sword`, 그리고 관절 자리 다섯(파츠 단위): `neck` (0, −200), `hat_at` (0, −104), `shoulder` (−65, −180), `hand_at` (0, 105), `sword_at` (0, 15)). 관절 자리의 값은 견본 `opp()`(224~231행)와 바이블 15절의 어깨다. `OpponentData.art: OpponentArt`. 바르톨로의 것은 `data/opponents/bartolo_art.tres`. `art`가 비어 있으면 그림 없이(텍스처 없음) 돌고 오류를 내지 않는다(테스트가 만든 상대가 씬에 들어가도 깨지지 않게).
257. **포즈는 데이터**: 새 Resource `PoseData`(15절 포즈의 꼴에서 `arm_art`를 뺀 다섯: `arm_deg`, `sword_deg`(화면 기준), `head_deg`, `lean_deg`, `shoulder: Vector2`(어깨 옮김, 파츠 단위)). `arm_art`는 030이 더한다(029에서는 쓰는 곳이 없다).
    - `AttackData`: `tell_pose: PoseData`, `hold_arm_deg: float`, `strike_pose: PoseData`, `recover_arm_deg: float`. `hold` = `tell_pose`에서 팔만 `hold_arm_deg`, `recover_end` = `strike_pose`에서 팔만 `recover_arm_deg`(15절 "만드는 규칙"이 팔만 바꾼다). 값을 직접 적는 까닭: 표가 정본이고, 규칙(8°·10°)으로 셈하면 표와 따로 놀 수 있다. `pose_arm_offset`·`pose_sword_rotation`과 `opponent_view.gd`의 `STRIKE_OFFSET`·`STRIKE_ROTATION`은 뺀다. `pose_color`(신호색)는 그대로다.
    - `OpponentData`(새 묶음 "그림과 포즈"): `art`, `idle_pose`, `stagger_pose`, `complacent_pose`, `dodge_head_deg` (−20.1), `dodge_time` (0.3). 묶음 "움직임": `hold_curve := true`, `tell_in` (0.2), `swing_ratio` (0.2), `swing_margin` (0.03), `return_time` (0.2). `REST_SWORD_ROTATION`·`STAGGER_*`·`COMPLACENT_SWORD_ROTATION`·`DODGE_*` 상수는 뺀다.
    - 값은 바이블 15절의 포즈 표 그대로다(작업 2의 표). 고개는 지금 상수의 라디안(0.4, −0.35)이 아니라 표의 도(22.9, −20.1)를 쓴다(차 0.02°·0.05°).
258. **움직임은 순수 함수**: 새 스크립트 `scripts/duel/opponent_motion.gd`(`class_name OpponentMotion`, 정적 함수만). 견본 `tellPose`·`recoverPose`·`timeline`(681~704행)을 옮긴다.
    - 예비 동작의 진행 p = (표시 시각 − 시작) ÷ `brain.tell_duration`(밀착 배율이 든 값). `swing = min(swing_ratio × tell_duration, 패리 창 − swing_margin)`, `hold_end = 1 − swing ÷ tell_duration`(`tell_in`보다 작으면 `tell_in`).
    - `hold_curve`가 참이면 p < `tell_in`: 시작 포즈 → `tell_pose`(easeOut), p < `hold_end`: `tell_pose` → `hold`(easeInOut), 나머지: `hold` → `strike_pose`(easeIn). 거짓이면 `tell_pose` → `strike_pose`를 고르게(견본의 "어깨 회전 · game 곡선").
    - 시작 포즈는 예비 동작이 시작될 때 **화면에 있던 포즈**다(보통 대기. 방심의 칼끝에서 들어올 때 칼이 튀지 않게). 견본은 늘 대기 포즈에서 시작한다. 대기에서 들어오면 같다.
    - 회수: 진행 q = (표시 시각 − 시작) ÷ (예정 종료 − 시작), `strike_pose` → `recover_end`(easeOut).
    - 그 밖의 바뀜(회수 → 대기, 무너짐으로, 무너짐 → 대기, 방심으로·에서): 그때 화면의 포즈에서 새 포즈로 `return_time`초 동안 easeInOut(견본 724행, "돌아감은 빠르게").
    - 바뀜의 시작 시각은 데이터에서 센다(T1). 상태가 바뀌면 `brain.state_start`다. 방심은 상태가 아니라 시각의 함수(`duel_core.gd` 158·163행, `opponent_brain.gd` 135~138행)이므로 따로 센다. 방심에 들 때는 `max(brain.state_start, brain.alert_since + opponent.complacent_time)`, 대기인 채 풀릴 때(런지가 판정돼 경계를 다시 세움)는 `brain.alert_since`다. 방심 중에 예비 동작이 시작되면 상태가 바뀐 것이므로 `brain.state_start`다.
    - 각은 도로 곧게 섞는다(견본의 `lerp`. 360° 감기를 하지 않는다). 칼의 지역 각 = `sword_deg − arm_deg − lean_deg`, 팔의 지역 각 = `arm_deg`(Torso가 `lean_deg`로 돈다), 고개는 `head_deg`(Head의 지역 각, 견본 `rotParams` 645행).
    - 간격의 크기·위치 보간(`exp(−14·delta)`)과 피하기의 고개 보간은 지금 그대로다.
259. **상태 색·번쩍임·조준 테두리는 셰이더 하나**: `scenes/duel/opponent_part.gdshader`(canvas_item). 유니폼 `tint_color: vec3`, `tint_amount: float`, `outline_on: bool`, `outline_texels: vec2`, `outline_color: vec4`.
    - 층(바이블 5절, 견본 312~319행과 같은 식): Y = 0.2126R + 0.7152G + 0.0722B(텍스처에서 읽은 sRGB 값), 선의 무게 = clamp((0.30 − Y) ÷ 0.08, 0, 1), 결과 = mix(mix(원래, 신호색, `tint_amount`), 원래, 선의 무게), 알파는 원래 그대로. 문턱 0.22·0.30은 셰이더의 `const`다(바꾸지 않는다, 결정 188). 프로젝트는 HDR 2D를 켜지 않아(`project.godot`에 `hdr_2d` 없음) 2D 셰이더가 sRGB 값으로 돈다는 것이 전제다(위험 R2).
    - 상태 색은 `tint_amount` 0.8(지금 `TINT_AMOUNT`). 닿은 부위의 흰 번쩍임은 흰색 1.0으로 **칠에만**(선이 남아 무엇이 닿았는지 읽힌다). 타격의 빨강 번쩍임은 지금처럼 물드는 파츠에 0.8.
    - 조준 테두리는 **안쪽 테두리**: 알파 ≥ 0.5인 화소 가운데 `outline_texels` 거리의 여덟 방향(과 그 절반 거리)에 알파 < 0.5가 있으면 `outline_color`(지금의 노랑 (1, 1, 0.4)). 굵기는 파츠 단위 5(지금 `Line2D.width`), 텍스처 화소로는 `5 ÷ units_per_px`. 바깥 테두리를 그리려면 그림에 투명한 여백이 있어야 하는데 잘린 그림의 여백은 1화소다(결정 251로 그림을 고치지 않는다).
    - 칼(`Sword/Art`)에는 재질을 두지 않는다(조준할 수 없고 상태 색을 받지 않는다, 결정 241). 모자와 깃털은 재질을 두되 상태 색은 받지 않고(지금 `TINTED`) 조준 테두리와 흰 번쩍임만 받는다. 모자를 조준하면 모자와 깃털 둘 다 테두리를 켠다.
    - 재질은 파츠마다 따로 만든다(`_ready`에서 `ShaderMaterial.new()`). 유니폼이 파츠마다 다르다.
260. **머리 셋**: `head` — 대기·예비 동작·방심·피하기, `head_oops` — 회수, `head_dizzy` — 무너짐(계획 024의 표 59~60행, 견본 `frameAt` 709·719행과 826~828행). 머리를 지키는 상대의 그냥 회수에서는 머리가 물들지 않는다(지금 `head_closed` 그대로). 텍스처를 바꿀 때 `offset`도 그 머리의 관절로 바꾼다(관절이 반 화소씩 다르다, MANIFEST 7~9행).
261. **테두리의 번짐(028의 R2)**: 그대로 둔다. 028이 잰 경계의 밝은 화소는 0이고, 보인 것은 선의 안티에일리어싱(어두운 반투명)이다. 짙은 바탕에서 보이는지는 찍은 그림을 2배로 잘라 본다(작업 11). 띠가 보이면 고칠 길(셰이더의 알파 곡선, 자를 때 한 화소 더 깎기)을 030에 넘긴다. 같이 하는 것: 멀리(텍스처 화소당 화면 0.33)에서 줄일 때의 밉맵. 열 장의 `.png.import`에 `mipmaps/generate=true`, OpponentView의 `texture_filter`를 `TEXTURE_FILTER_LINEAR_WITH_MIPMAPS`로. `process/fix_alpha_border=true`(Godot의 기본)는 그대로 둔다.
262. **결투의 바탕 색**을 `#3A3027`(`--st-shade`, 바이블 8절 "무대 가운데 그늘")로 바꾼다(`scenes/duel/duel.tscn` 23행, 지금 (0.12, 0.12, 0.15)). 그림의 상태 색과 번짐을 무대와 비슷한 바탕에서 판정하려고. 031이 무대 그림으로 바꾼다. 되돌리기 쉽다(한 줄).
263. **칼 팔이 오른쪽인 상대**: 029의 그림과 포즈는 왼쪽(바르톨로)만이다. 오른쪽이면 `setup`이 `push_warning` 한 번을 내고 지금처럼 어깨 x만 뒤집는다(그림은 뒤집지 않는다). 거울 규칙(15절의 제안)은 035~036에서 오른쪽 상대가 생길 때. `docs/BACKLOG.md`에 029-1로 남긴다.
264. **그림 찍기 씬**: `tests/opponent_shots.tscn`·`.gd`. 상대 뷰만 띄우고 상태를 정해(아래 도우미) 장면마다 PNG를 저장한다. `day_smoke.gd`의 `--shots=<폴더>` 꼴을 따른다(헤드리스면 저장하지 않고 오류 없이 돌기만 한다). 상태를 정하는 도우미 `tests/opponent_states.gd`를 T67과 함께 쓴다. 테스트 목록(`run_tests.gd`)에는 넣지 않는다.

## 작업 목록

차례대로 한다. 작업 0이 멈추면 코드를 고치지 않는다. `<R>` = `C:\godot\bravi`, `<W>` = 도구의 작업 폴더(`%TEMP%\bravi-style`, `docs/style/tools/paths.ps1`). 도구 명령은 작은 감싸개 `.ps1`(ASCII만, 절대 경로)에 적어 `powershell -NoProfile -File`로 띄운다(028 "넘지 않는 선").

### 작업 0. 시작 전의 확인 (메인)

- 대상: `assets/art/opponents/bartolo/*.png.import`, 견본 `026-pose-motion.html`(고치지 않는다).
- 할 일:
  1. `.png.import` 열 개가 있는지 Glob으로 본다. 028 뒤 playtester 확인이 만들어 커밋했다(`705ca31`: `ALL PASS 65/65`, 스모크 OK, 가져오기 OK, `docs/style` 아래 `.import` 0). 그래도 없으면 멈추고 보고한다. 있으면 열 개 모두 `mipmaps/generate=false`와 `process/fix_alpha_border=true`가 있는지 본다.
  2. 029의 사이 상태(보통 팔, "029와 030의 경계" 아래 항목)를 견본으로 굽고 잰다: `& '<R>\docs\style\tools\r026.ps1' -Col rot -Curve hold -Bake -Tag 'n029+art=0'`. `-Tag`의 `+art=0`이 주소의 `art=0`이 된다(`r026.ps1` 10~11행이 `+tag=<값>`을 shot에 붙이고, `bake025.ps1` 26~29행이 `+`로 나눠 주소에 넣는다). 출력의 이름 칸에 `art-0-`이 남는 것은 상관없다.
  3. 같은 것을 `-Tag 'n029b+art=0'`로 한 번 더 돌려 R1·R2·R4가 같은지 본다(굽기의 흔들림).
- 완료 확인:
  - 구운 장 가운데 넷(`atk=big+ph=tell+p=0.25+dist=mid`, `atk=thrust+ph=recover+dist=mid`, `atk=cutl+ph=tell+p=0.6+dist=mid`, `atk=big+ph=idle+dist=mid`)을 Read로 보아 팔 그림이 아니라 보통 팔·주먹·칼이 보인다(`art=0`이 먹었다).
  - R1의 최대 ≤ 0.30, R2의 최대 ≤ 0.10이면 다음 작업으로 간다. 값과 가장 큰 쌍을 보고서 2번에 적는다(바이블 11절 표의 셋째 열과 나란히). **넘으면 멈추고** 넘은 줄과 그 장을 사용자에게 보인다(사이 상태를 받아들일지, 그 공격만 030까지 다른 값을 쓸지는 계획의 수정이다).
  - R4(상태 글자 상자의 칼)는 적기만 한다.

### 작업 1. 데이터의 꼴 (Resource 스크립트)

- 대상(새 파일 셋, 고치는 파일 둘):
  - `scripts/duel/part_art.gd` — `class_name PartArt extends Resource`, 필드 셋(결정 256).
  - `scripts/duel/opponent_art.gd` — `class_name OpponentArt extends Resource`, 파츠 열과 관절 자리 다섯(결정 256, 기본값이 바르톨로의 값).
  - `scripts/duel/pose_data.gd` — `class_name PoseData extends Resource`, 필드 다섯(결정 257, 기본값 0과 `Vector2.ZERO`).
  - `scripts/ai/attack_data.gd` — 20~24행의 묶음과 두 필드를 결정 257의 넷으로 바꾼다. `pose_color`는 남긴다. 묶음 이름은 "포즈 (바이블 15절)".
  - `scripts/ai/opponent_data.gd` — 묶음 둘("그림과 포즈", "움직임")과 필드(결정 257). 끝의 `graze_cells`는 그대로다.
- 완료 확인(메인):
  - Grep `pose_arm_offset|pose_sword_rotation`이 `scripts/`·`data/`·`tests/`에서 0줄.
  - 새 필드 이름이 결정 257과 글자째 같다(Grep 한 번에 하나씩).
  - 기계적 확인 다섯. `@export var x: PoseData`처럼 타입을 적는다(`:=`로 Resource를 추론하지 않는다).
  - 기존 필드의 기본값을 바꾸지 않았다(`git diff`에서 지운 줄이 결정 257의 것뿐).

### 작업 2. 바르톨로의 그림과 포즈 (`.tres`)

- 대상: 새 파일 `data/opponents/bartolo_art.tres`(`OpponentArt` 하나, `PartArt` 하위 자원 열, 텍스처는 `res://assets/art/opponents/bartolo/<이름>.png`의 `ext_resource`). `data/opponents/opponent_01.tres`(공격 넷의 포즈, 대기·무너짐·방심의 포즈, `art`, 곡선 값. 지운 필드의 줄 여덟(15·16·27·28·39·40·52·53행)을 뺀다).
- `PartArt`의 값은 `assets/MANIFEST.md` 7~16행 그대로다(관절은 "관절" 칸, `units_per_px`는 "단위/화소" 칸. 팔만 x 0.4451 · y 0.4611, 나머지는 x·y가 같다). 깃털의 관절은 (−43, 81).
- 포즈(바이블 15절의 표. 빈칸은 0):

| 자리 | arm_deg | sword_deg | head_deg | lean_deg | shoulder | hold_arm_deg / recover_arm_deg |
|---|---|---|---|---|---|---|
| 찌르기 `tell_pose` · `strike_pose` | 85 · −30 | 95 · 180 | | | | 93 / −20 |
| 왼쪽 베기 | 110 · 20.8 | −75 · −120 | | | | 118 / 10.8 |
| 오른쪽 베기 | −88 · −51.9 | 45 · 120 | | | | −96 / −41.9 |
| 큰 베기(버릇 반응) | 152 · −21.5 | −45 · 180 | | −4 · 0 | | 160 / −11.5 |
| `idle_pose` | 23 | −21 | | | | |
| `stagger_pose` | 0 | 165 | 22.9 | | (0, 25) | |
| `complacent_pose` | 23 | −140 | | | | |

- 완료 확인(메인):
  - `bartolo_art.tres`의 `ext_resource` 열 개의 경로가 모두 있다(Test-Path). 하위 자원 열의 `joint`·`units_per_px`가 MANIFEST와 같다(줄마다 견준다).
  - `opponent_01.tres`에서 Grep `tell_pose|strike_pose`가 공격 수 × 2 = 8, `hold_arm_deg|recover_arm_deg`가 8. 위 표의 값이 모두 있다(값마다 Grep).
  - `load_steps`가 자원 수 + 1이다(`ext_resource`와 `sub_resource`를 센다). `sub_resource`의 id가 겹치지 않는다.
  - 판정에 쓰는 줄(`tell_time`, `recovery_time`, `weight`, `is_big`, `needs_raised_guard`, `posture_max`…)이 `git diff`에서 바뀌지 않았다.

### 작업 3. 셰이더

- 대상: 새 파일 `scenes/duel/opponent_part.gdshader`(결정 259).
- 할 일: `shader_type canvas_item;`, 유니폼 다섯, `const float LINE_Y = 0.22; const float FILL_Y = 0.30;`, `fragment()`에서 `texture(TEXTURE, UV)`를 읽어 층을 섞고 테두리를 얹는다. 테두리의 표본은 `TEXTURE_PIXEL_SIZE * outline_texels`로 잰다.
- 완료 확인(메인): 셰이더의 식을 견본의 `feColorMatrix`(313행, `−2.6575 −8.94 −0.9025 … 3.75` = 12.5 × (0.30 − Y))와 손으로 견준다: Y 0.22 → 선의 무게 1, 0.26 → 0.5, 0.30 → 0. 유니폼 이름이 결정 259와 같다. **셰이더의 문법은 헤드리스 테스트가 잡지 못한다**(위험 R3): playtester의 창 실행에서 `SHADER ERROR`가 없는지 본다.

### 작업 4. 움직임 (`OpponentMotion`)

- 대상: 새 파일 `scripts/duel/opponent_motion.gd`(결정 258). 정적 함수(이름을 바꾸면 T66이 깨진다):
  - `swing_time(tell_duration: float, parry_window: float, opp: OpponentData) -> float`, `hold_end(…같은 셋) -> float`
  - `tell_pose(atk: AttackData, from: PoseData, p: float, tell_duration: float, parry_window: float, opp: OpponentData) -> PoseData`
  - `recover_pose(atk: AttackData, q: float) -> PoseData`, `hold_of(atk) -> PoseData`, `recover_end_of(atk) -> PoseData`
  - `blend(a: PoseData, b: PoseData, k: float) -> PoseData`, `ease_in`, `ease_out`, `ease_in_out`(견본 624~626행)
- 새 `PoseData`를 돌려주고 받은 것을 고치지 않는다(데이터의 포즈는 공유된다).
- 완료 확인(메인): 견본 681~704행과 줄마다 견준다. p·q는 0~1로 자른다. 기계적 확인 다섯.

### 작업 5. 상대 뷰의 씬과 스크립트

- 대상: `scenes/duel/opponent_view.tscn`, `scripts/duel/opponent_view.gd`.
- 씬: 파츠 노드 일곱은 그대로(Node2D, 이름·부모 그대로). `Shape`(Polygon2D) 일곱과 `Label` 여섯을 빼고, 파츠마다 **첫 자식**으로 Sprite2D `Art`(`centered = false`)를 둔다. `Torso/Head/Hat/Feather`는 Polygon2D에서 Sprite2D로(`centered = false`). 차례: `Torso`의 자식은 `Art`, `Head`, `Arm`(견본 `opp()`처럼 팔이 머리 위에 그려진다). 루트에 `texture_filter = 4`(LINEAR_WITH_MIPMAPS, 결정 261). `StateLabel`은 그대로.
- 스크립트:
  - `setup(opponent, weapon, has_hat)`: `opponent.art`로 텍스처·`offset`(= −관절)·`scale`(= 단위/화소)을 걸고, 관절 자리 다섯을 노드 위치로 준다(`Head.position = neck`, `Hat.position = hat_at`, `Hand.position = hand_at`, `Sword.position = sword_at`, 어깨 = `shoulder`). 화면의 포즈를 `idle_pose`로 바로 놓는다(지금의 `_snap`). 칼 팔이 오른쪽이면 결정 263.
  - `_ready`: 재질을 파츠마다 만든다(결정 259). 조준 테두리용 `Line2D`를 만들지 않는다. `outline_texels` = 5 ÷ 그 파츠의 `units_per_px`(텍스처를 건 뒤라 `setup`에서 준다).
  - `update_view`: 상태별 분기는 지금 그대로 두고 팔·칼·몸·고개를 결정 258의 포즈로 바꾼다. 색은 `shape.color` 대신 재질의 `tint_color`·`tint_amount`. 머리 텍스처는 결정 260. 상태 글자·고리·방심 글자·받아넘김 글자의 줄은 고치지 않는다(T42·T51이 본다).
  - `set_target(part)`: 테두리를 켜고 끈다(모자면 깃털도).
  - `on_event`: 지금 그대로(닿은 부위·깃털 숨기기·피하기·받아넘김).
  - 남는 상수: `COLOR_*`, `TINT_AMOUNT`, `FLASH_TIME`, `TOUCH_FLASH_TIME`, `DEFLECT_TEXT_TIME`, `DISTANCE_SCALE`·`DISTANCE_SHIFT`, `RING_*`, `STATE_LABEL_Y`, `COMPLACENT_TEXT`. 빼는 상수: `CHEST`, `SHOULDER_X`, `REST_SWORD_ROTATION`, `STRIKE_OFFSET`, `STRIKE_ROTATION`, `STAGGER_*`, `COMPLACENT_SWORD_ROTATION`, `DODGE_*`(데이터로 갔다).
  - 화면의 포즈를 하나 들고 있고(`_pose: PoseData`), 바뀜의 시작(`_blend_from`, `_blend_start`, `_blend_to_state`)을 둔다. 상태가 바뀐 프레임을 `brain.state`와 `brain.state_start`로 안다. 바뀜의 시작 시각은 알아챈 프레임이 아니라 `brain.state_start`이고, 시작 포즈는 알아챈 프레임에 화면에 있던 포즈다(찍기와 T67이 `state_start`를 `return_time`보다 먼 과거로 두면 새 포즈에 다 와 있다). 방심이 바뀐 시각은 결정 258의 식으로 센다(알아챈 프레임의 `display_time`을 쓰지 않는다. T1). 그래서 `update_view`를 한 번만 불러도 방심 포즈에 다 와 있다(T67 6번, `complacent` 장).
- 완료 확인(메인):
  - Grep: `opponent_view.gd`에 `Polygon2D`, `Line2D`, `_shape_of`, `_outlines`, `STRIKE_OFFSET`, `_arm.position.lerp`가 0줄. `_arm.rotation_degrees`가 있다.
  - `opponent_view.tscn`에 `type="Polygon2D"`·`type="Label" parent="Legs"`류가 0, `type="Sprite2D"`가 8(Art 일곱 + Feather), `load_steps`가 맞다.
  - 씬의 노드 경로 일곱이 `tests/scene_tests.gd` 10~13행과 같다. `Torso/Head/Hat`·`Torso/Head/Hat/Feather`가 CanvasItem이다(T42가 `visible`을 본다).
  - 기계적 확인 다섯. 한 함수가 80줄을 넘으면 포즈 계산을 `_pose_for_state()` 같은 함수로 나눈다.

### 작업 6. 가져오기 설정과 바탕

- 대상: `assets/art/opponents/bartolo/*.png.import` 열(`mipmaps/generate=false` → `true`, 그 줄만), `scenes/duel/duel.tscn` 23행(`color = Color(0.2275, 0.1882, 0.1529, 1)` = `#3A3027`, 결정 262).
- 완료 확인(메인): 열 파일마다 `git diff`가 한 줄이다. `duel.tscn`의 다른 줄은 그대로다. 손 계산: 0x3A/255 = 0.2275, 0x30/255 = 0.1882, 0x27/255 = 0.1529.

### 작업 7. 테스트

- 대상: 새 파일 `tests/opponent_states.gd`(도우미), `tests/opponent_art_tests.gd`(T65~T67), `tests/run_tests.gd`(`TEST_FILES`에 한 줄), `tests/core_tests.gd` `_copy_opponent()`(83~104행에 새 필드를 베끼는 줄: `art`, `idle_pose`, `stagger_pose`, `complacent_pose`, `dodge_head_deg`, `dodge_time`, `hold_curve`, `tell_in`, `swing_ratio`, `swing_margin`, `return_time`). 이 함수로 만든 상대가 씬에 들어가는 테스트(T51, `lunge_tests.gd` 80~95행)가 그림 없는 상대가 되지 않게 한다.
- 도우미 `opponent_states.gd`: `static func put(core: DuelCore, state: int, atk: AttackData, progress: float, distance: int, settled := true) -> float`. 먼저 `core.distance = distance`를 정한다(밀착 배율이 간격을 읽는다. 기술 비차단). 그다음 `core.time`, `brain.state`, `current_attack`, `state_start`, `state_end`, `tell_duration`(밀착이면 배율), `wide_open`(회수에서 `atk.is_big`)을 정하고 표시 시각을 돌려준다. `settled`면 바뀜이 끝난 시각이다. 방심은 `core.time = 25`, `brain.alert_since = 0`, 대기의 `state_start = 0`(방심 20초, `opponent_01.tres` 81행). 방심의 시작은 max(0, 0 + 20) = 20이라 25에서 바뀜이 끝나 있다(결정 258).
- 기존 테스트의 가정: T14(파츠 경로 일곱이 Node2D, 600프레임), T42(모자 `visible`, 상태 글자), T51(상태 글자 "방심"), T24(입력)는 그대로 통과해야 한다. 노드 경로·이름·`StateLabel`을 바꾸지 않으므로 고칠 줄이 없다. 색과 포즈를 보는 기존 테스트는 없다(Grep `rotation|\.color|Polygon2D`가 `tests/`에서 `bind_tests.gd` 575행 하나, 내 칼의 것).

| ID | 이름 | 본다 |
|---|---|---|
| T65 | 상대 그림과 포즈의 데이터 | `opponent_01.tres`의 `art`에 파츠 열이 다 있고 텍스처가 로드되며 크기가 MANIFEST와 같다(225×255 … 147×399). `joint`·`units_per_px`가 MANIFEST의 값과 같다(테스트에 표를 둔다. MANIFEST를 고치면 이 표도). 일반 공격과 버릇 반응의 공격 모두 `tell_pose`·`strike_pose`가 있고, `idle_pose`·`stagger_pose`·`complacent_pose`가 있다. 무너짐과 회수 끝이 넷 가운데 둘 이상에서 갈린다(15절, 팔 ≥ 15°, 칼 ≥ 30°, 어깨 ≥ 15, 고개 ≥ 10°) |
| T66 | 포즈와 곡선의 값 | 아래 "T66의 기대 값". 로드한 상대·무기(`rapier.tres`의 패리 창)로 센다. `hold_curve`를 끈 사본은 고르게 간다. 받은 `PoseData`가 고쳐지지 않았다 |
| T67 | 상대 뷰: 포즈·머리·색·테두리가 상태를 따른다 | 상대 뷰를 혼자 띄우고(도우미로 상태를 정해 `update_view`를 부른다) 아래 "T67의 확인" |

**T66의 기대 값**(손 계산. 대기 (23, −21)에서 들어간다):

| 무엇 | 기대 |
|---|---|
| `swing_time` | 찌르기 0.13, 베기 0.15, 큰 베기 0.15, 밀착 찌르기(0.65 × 0.8) 0.104 |
| `hold_end` | 찌르기 0.8, 베기 0.8, 큰 베기 1 − 0.15 ÷ 1.1 = 0.86364 |
| 찌르기 p 0.1 | 팔 23 + 62 × 0.75 = 69.5, 칼 −21 + 116 × 0.75 = 66.0 |
| 찌르기 p 0.2 · 0.5 · 0.8 · 0.9 · 1 | 팔 85 · 89 · 93 · 62.25 · −30, 칼 95 · 95 · 95 · 116.25 · 180 |
| 큰 베기 p 0.5 · 1 | 몸 −4 · 0 |
| 왼쪽 베기 회수 q 0.5 | 팔 20.8 − 10 × 0.75 = 13.3, 칼 −120 |
| `hold_curve` 거짓, 찌르기 p 0.5 | 팔 27.5, 칼 137.5 |
| `blend` k 0.5 · `ease_in_out(0.5)` | 가운데 · 0.5 |

**T67의 확인**(허용 차 0.01):

1. `setup` 뒤: 파츠마다 `Art.texture`가 데이터의 것, `offset` = −관절, `scale` = 단위/화소. `Arm.position` = 어깨, `Arm.rotation_degrees` 23, `Sword.rotation_degrees` −21 − 23 = −44, 머리 텍스처 `head`.
2. 찌르기 예비 동작 p 0.5: 팔·칼이 `OpponentMotion.tell_pose`의 값. `Torso/Art` 재질의 `tint_color` = 찌르기의 `pose_color`, `tint_amount` 0.8. `Sword/Art.material`이 null. 모자 재질의 `tint_amount` 0.
3. 찌르기 p 1 바로 앞(0.9999): 팔이 −30에 0.5° 안.
4. 왼쪽 베기 회수(머리를 지키는 상대, 그냥 회수): 머리 텍스처 `head_oops`, 머리의 `tint_amount` 0, 몸통 `tint_color` = `COLOR_RECOVERY`. 큰 베기 회수(크게 열림): 머리도 물든다.
5. 무너짐(끝난 바뀜): 머리 `head_dizzy`, 팔·칼·고개·어깨가 `stagger_pose`, 색 `COLOR_STAGGER`. 무너짐에 막 들어간 프레임(`settled` 거짓, 0.1초 뒤): 팔이 시작 포즈와 `stagger_pose`의 가운데(`ease_in_out(0.5)`).
6. 방심(도우미의 방심 값, `update_view` 한 번): 칼이 −140 − 23 = −163의 지역 각, 머리 `head`. 시작 시각이 결정 258의 식(20)에서 나오는지 본다(T1).
7. `set_target(TORSO)`: 몸통만 `outline_on`. `set_target(HAT)`: 모자와 깃털. `set_target(-1)`: 모두 끔.
8. `on_event`(ATTACK, GRAZE, LEGS) 뒤 `update_view(delta 0.01)`: 다리 `tint_color` 흰색, `tint_amount` 1.0. STRIKE 뒤: 몸통 `COLOR_STRIKE`.

- 완료 확인(메인): 기계적 확인 다섯. 새 ID가 T65~T67이고 겹치지 않는다(Grep `"id": "T6[5-7]"`이 새 파일에만). 테스트의 기대 값이 위 표와 같다. 실행은 playtester(끝의 1).

### 작업 8. 그림 찍기 씬

- 대상: 새 파일 `tests/opponent_shots.tscn`·`tests/opponent_shots.gd`(결정 264), `tests/run_opponent_shots.ps1`(ASCII만, `run_smoke.ps1`의 꼴: Godot 찾기 → `--import` → 창으로 `res://tests/opponent_shots.tscn -- --shots=<폴더>` → 끝 줄 `OPPONENT SHOTS OK <장 수>`와 `ERROR`·`SHADER ERROR` 줄 0으로 판정). 폴더 인자가 없으면 헤드리스로 돌고 저장하지 않는다.
- 씬: 1280×720, 바탕 `#3A3027`(결정 262), `opponent_view.tscn` 하나, `anchor` = (640, 446.4)(`duel_scene.gd` 186행과 같은 0.5·0.62), 조준 칸·HUD·내 칼은 없다. `DuelCore`를 `opponent_01.tres`·`rapier.tres`로 `setup`하고, 장마다 `setup`(간격의 보간을 건너뛴다)을 부르고, `opponent_states.put`으로 간격과 상태를 정하고(간격이 먼저다. 그래야 밀착 두 장이 0.88초·0.52초의 예비 동작으로 찍힌다), `update_view`를 부르고 두 프레임 기다려 저장한다.
- 장(이름 · 상태):

| 묶음 | 장 |
|---|---|
| 대기 | `idle-far`, `idle-mid`, `idle-close`, `idle-mid-hat`(모자) |
| 공격 넷(`thrust`, `cutl`, `cutr`, `big`) × 교전 | `<공격>-tell25`, `<공격>-tell60`, `<공격>-hold`(p = `hold_end`), `<공격>-strike`(p 0.9999) |
| 밀착 | `big-tell25-close`, `thrust-tell25-close` |
| 멀리(D2) | `thrust-hold-far`, `cutl-hold-far`, `cutr-hold-far`, `big-hold-far`. 상대는 멀리에서 예비 동작을 시작하지 않으므로(`duel_core.gd` 327~330행) 이 모습은 예비 동작 중에 S로 물러났을 때만 나온다 |
| 상태 | `cutl-recover`(그냥 회수, 머리 닫힘), `big-recover`(크게 열림), `stagger`, `complacent`, `dodge`(피하기 0.15초) |
| 조준 테두리(모자를 쓴 판, 교전) | `aim-head`, `aim-hat`, `aim-torso`, `aim-arm`, `aim-hand`, `aim-legs` |
| 번쩍임 | `touch-legs`(닿은 다리), `strike-flash`(타격 0.05초) |
| 상태 색 짝(모자, 교전, 왼쪽 베기 회수) | `pair-off`(찍기 직전에 물드는 파츠의 `tint_amount`를 0으로), `pair-on` |

- 재는 점(T2): `pair-off`를 찍을 때 견본의 재는 점(026 견본 296~302행 `tintPts`의 열둘, 파츠 단위)을 파츠 노드의 `to_global`로 화면 좌표로 바꿔 한 줄에 하나씩 출력한다. 꼴은 `pt,<장 이름>,<점 이름>,<종류>,<x>,<y>[,<dx>,<dy>]`이고 x·y는 **정수로 반올림**한다(`tintpair.ps1` 19·23행이 `int.Parse`로 읽는다). 앞머리 `pt,<장 이름>,`을 떼면 `tintpair`의 `-Pts` 한 줄(`이름,종류,x,y[,dx,dy]`)과 같다. `pair-on`은 같은 포즈이므로 점을 다시 내지 않는다.
- 완료 확인(메인): 장 이름이 위 표와 같다(4 + 16 + 2 + 4 + 5 + 6 + 2 + 2 = 41장). 파일 이름에 한글이 없다. `run_opponent_shots.ps1`의 첫 세 바이트가 `EF BB BF`가 아니고 ASCII뿐이다. 실행은 playtester(끝의 2).

### 작업 9. 문서

| 파일 | 고칠 곳 | 바꿈 |
|---|---|---|
| `assets/MANIFEST.md` | 머리 셋 줄의 용도 | "Head — 대기·예비 동작·방심·피하기", "HeadOops — 회수", "HeadDizzy — 무너짐"(결정 260). 상태는 `generated` 그대로 |
| `docs/DECISIONS.md` 끝 | 새 절 "2026-11-22 — 계획 029" | 결정 254~264 한 줄씩과 실행 중에 정한 것 |
| `docs/STYLE_BIBLE.md` 16절 | "포즈를 게임에 옮기기", "상태 색 셰이더", "그림의 원본 해상도"의 셋째 칸 | "옮겼다(계획 029): 어깨 회전·포즈 표·`hold` 곡선. 따로 그린 팔은 030", "옮겼다(계획 029, `scenes/duel/opponent_part.gdshader`)", "사용자 답(2026-11-22): 1920×1080까지. 파츠는 지금 그림, 무대는 031. 밉맵은 029". 줄 수는 그대로. 고친 뒤 `check027.ps1`(인자 없음): 못 찾은 것 0 |
| `CLAUDE.md` 7장 | "Skeleton2D 컷아웃 리깅으로 움직인다" | "파츠 노드를 관절에서 돌려(컷아웃) 움직인다. 파츠를 굽혀야 할 때 Skeleton2D를 쓴다"(결정 255) |
| `CLAUDE.md` 8장 | `scripts/` 줄 | 바꾸지 않는다(새 스크립트는 `scripts/duel/`에 든다). `data/` 줄의 `opponents/` 뒤에 "(상대의 그림 데이터 `*_art.tres`도)" |
| `CLAUDE.md` 9장 | "4단계 진행 중" 문장 | 끝에 "계획 029(바르톨로를 결투에)." |
| `CLAUDE.md` 3장 "상대 AI" | 바꾸지 않는다 | — |
| `docs/BACKLOG.md` | 새 항목 | 029-1 칼 팔이 오른쪽인 상대의 그림·포즈(결정 263). 그 파일 머리의 꼴로 |
| `docs/HANDOFF.md` | 1번·2번·3번 | 029의 상태, playtester 확인, 029 보고서 4번 |

- 완료 확인(메인): `check027.ps1`의 V마다 못 찾은 수 0(V7의 검사한 개수만 늘 수 있다. 그 수를 보고서에 적는다). 바이블의 줄 수가 같다. `DECISIONS.md`에 `^254\.`~`^264\.`가 하나씩.

### 작업 10. playtester의 확인 (아래 "playtester에게 맡길 확인")

- 사용자가 Q1에 "맡긴다"고 답했다(2026-11-22, 선택 창). 이 답이 사용자의 요청이다: 메인은 작업 1~9를 마치면 다시 묻지 않고 바로 playtester를 부른다.
- playtester가 오류를 보고하면 018·019 보고서의 "가리는 순서"(HANDOFF 1번)로 가리고, 범위·규칙을 바꾸지 않는 오류면 고쳐서 같은 확인을 다시 맡긴다(CLAUDE.md 11장 "실행 중 변경").

### 작업 11. 찍은 그림의 판정과 사용자에게 보일 판 (메인)

- 대상: playtester가 남긴 `%TEMP%\bravi-029-shots\`의 PNG 41장과 `pts.txt`. 메인의 감싸개와 결과는 `<W>\029\`(저장소 밖).
- 할 일과 통과(모두 메인이 PowerShell·Read로 한다):

| # | 무엇 | 도구 | 통과 |
|---|---|---|---|
| S1 | 41장이 모두 1280×720이고 빈 장면이 아니다 | `System.Drawing` | 바탕 `#3A3027`(채널 차 8 밖)과 다른 화소가 장마다 1% 이상 |
| S2 | 교전 꼭대기(G4) | `idle-mid-hat`의 바탕과 다른 화소의 가장 위 y | ≥ 142(손 계산 143.5 = 446.4 − 0.85 × (200 + 104 + 52.4)) |
| S2b | 상태 글자 상자의 칼(R4) | 공격 넷의 `tell25`와 밀착 둘에서 x 497~783 · y 62~142의 바탕과 다른 화소 수 | 적기만 한다(작업 0의 R4와 나란히). 큰 베기의 칼끝은 손 계산으로 x ≈ 421, y ≈ 79라 상자 왼쪽 밖이다 |
| S3 | 상태 색이 칠에만(바이블 13.6 T1·T2) | 메인의 감싸개가 `pts.txt`에서 `pt,pair-off,`로 시작하는 줄을 골라 그 앞머리를 떼고 `;`로 이어(T2), `tintpair.ps1 -Off <pair-off.png> -On <pair-on.png> -Pts <이은 글> -Sig '#4D80F2'`(`COLOR_RECOVERY`)를 부른다. 출력의 `measured`가 12인지도 본다 | `off 0`(칠은 0.8 섞임, 선·머리·모자·칼은 같음, 차 ≤ 4) |
| S4 | 머리 셋 | Read: `idle-mid`, `cutl-recover`, `stagger` | 미소·당황·어지러움 |
| S5 | 이음매 | Read: 공격 넷의 `hold`·`strike`, `stagger`를 2배로 자른 어깨·목·손목 | 틈이나 떨어진 팔이 없다(겹침 여유, 바이블 5절) |
| S6 | 테두리 번짐(결정 261) | `idle-close`의 머리·어깨 둘레를 2배로 잘라 Read | 밝은 띠가 없다. 어두운 반투명은 적기만 한다 |
| S7 | 조준 테두리 | Read: `aim-*` 여섯 | 노란 테두리가 그 부위에만, 손에서도 보인다 |
| S8 | 번쩍임 | Read: `touch-legs`, `strike-flash` | 다리 칠이 희고 선이 남는다, 빨강이 칼·모자 밖에 |
| S9 | 칼은 물들지 않는다 | S3 출력의 `blade` 줄(종류 `same`, 칼 (0, −125.8)). 예비 동작의 색에서도 칼에 재질이 없다는 것은 T67 2번이 본다(T2로 줄였다) | `blade` 줄이 `OK`(차 ≤ 4) |

- 그다음 사용자에게 보일 판 넷을 `<W>\029\`에 만든다(`System.Drawing`으로 장을 50%로 줄여 나란히, 장 밑에 영어 이름. 보통 팔로 보이는 사이 상태의 장(`big-*`의 예비 동작, `thrust-strike`) 밑에는 `030까지 보통 팔`을 붙인다. 디자인 비차단 1):
  - 판 A "예비 동작 넷"(D1): `idle-mid`, `thrust-hold`, `cutl-hold`, `cutr-hold`, `big-hold`(교전). 멈칫의 실루엣이 서로, 그리고 대기와 갈리는지 나란히 본다(바이블 15절 "원칙 4에서 나온 규칙" 2).
  - 판 B "상태": `cutl-tell60`, `big-tell25`, `thrust-strike`, `cutl-recover`, `big-recover`, `stagger`, `complacent`, `dodge`.
  - 판 C "조준과 번쩍임": `aim-*` 여섯, `touch-legs`, `strike-flash`.
  - 판 D "간격"(D2): 윗줄 `idle-far`, `idle-mid`, `idle-close`, `big-tell25-close`, 아랫줄 `thrust-hold-far`, `cutl-hold-far`, `cutr-hold-far`, `big-hold-far`.
- 걸린 것(S2·S3·S5·S9가 통과하지 않음)은 사용자에게 보이기 전에 고치고 작업 10을 다시 맡긴다. S6·S7·S8은 그림과 함께 보고서 3번에 적는다.

### 작업 12. 보고서

- 대상: `docs/reports/029-bartolo-in-duel.md`(CLAUDE.md 10장의 다섯). 2번에 작업 0·S1~S9의 값, playtester의 결과, 확인 못 한 것. 3번에 계획과 다르게 한 것. 4번에 아래 "029 뒤 사용자가 볼 것"의 물음.

## playtester에게 맡길 확인

작업 10에서 메인이 아래와 기대 결과를 넘긴다. 게임·테스트·스모크·찍기를 띄우는 명령마다 같은 줄에서 `$env:BRAVI_SAVE_PATH = "user://bravi_playtest_save.json"`.

1. **테스트**: `tests/run_tests.ps1` → `ALL PASS 68/68`(65 + T65~T67), `SCRIPT ERROR`·`ERROR:` 줄 0. 스모크 `tests/run_smoke.ps1` → `RESULT: OK`. 실패하면 그 줄 전체.
2. **찍기**: `tests/run_opponent_shots.ps1`을 폴더 `%TEMP%\bravi-029-shots`로(창으로 뜬다) → 끝 줄 `OPPONENT SHOTS OK 41`, PNG 41장, `ERROR`·`SHADER ERROR` 줄 0. 출력의 `pt,` 줄을 같은 폴더의 `pts.txt`로 남긴다. 폴더 없이(헤드리스) 한 번 더 돌려 오류 줄 0.
3. **가져오기**: `.png.import` 열이 밉맵으로 다시 가져와졌다(가져오기 단계의 오류 0). 새로 생긴 `.uid` 파일(새 스크립트·셰이더·테스트)의 목록. `docs/style/` 아래 `.import` 0.
4. **게임 창**(`tools/start-playtest.ps1`): 처음 화면 → 연습(또는 가게를 연다 → 의뢰 하나) → 결투. 찍을 것: (가) 교전의 대기, (나) 마우스를 몸통 칸에 둔 조준 테두리, (다) 예비 동작 하나(무엇이든), (라) 막은 뒤의 회수(당황한 머리), (마) W로 밀착, S로 멀리. 판이 끝나면 결과·정산이 전과 같다. 게임 로그에 `ERROR`·`SHADER ERROR`가 없다. 팔이 어깨에서 떨어져 보이는 장이 있으면 그 장.
5. 확인하지 못한 것은 "미확인"으로, 실패는 입력·시점·기대와 실제·로그 줄로 남긴다.

## 029 뒤 사용자가 볼 것

4단계 완료 기준의 "placeholder 대체"를 상대 하나(바르톨로)에서 처음 보는 자리다. 보고서 4번에서 그림을 먼저 보이고(바이블 13.7) 선택 창으로 묻는다.

| 판 | 보는 것 | 묻는 것 |
|---|---|---|
| A "예비 동작 넷"(작업 11, D1) | 네 공격의 멈칫(가로 선 · 바깥 위 사선 · 몸 앞 사선 · 가장 큰 세로)이 게임 렌더에서 서로, 그리고 대기와 갈려 읽히는가. 원칙 4에서 가장 먼저 볼 것이다 | 맞다 / 고친다(무엇을 고칠지는 다음 글로) |
| B "상태" | 예비 동작·타격·회수·무너짐·방심·피하기에서 포즈와 머리와 색이 읽히는가, 큰 베기에서 얼굴이 가려지지 않는가 | 맞다 / 고친다 |
| C "조준과 번쩍임" | 노란 안쪽 테두리와 흰 번쩍임이 그림 위에서 읽히는가 | 맞다 / 고친다 |
| D "간격"(D2) | 멀리(예비 동작 중에 물러났을 때)에서도 네 공격이 갈리는가, 밀착에서 모자·칼이 상태 글자를 가리지 않는가 | 맞다 / 고친다 |
| playtester의 게임 창 (가)~(마) | 실제 게임에서 같은 모습인가 | 위 넷에 묶는다 |

- 사용자가 바라면 직접 결투 몇 판을 해 본다(`play.ps1`): 예비 동작의 끝에서 휘두름을 보고 누르게 되는지(원칙 4). 이것은 030의 정식 확인(바이블 16절 "`hold` 곡선의 반응 싸움")의 첫 인상이고 029의 완료 기준이 아니다.
- "맞다"여도 MANIFEST의 상태는 `generated` 그대로다(`final`은 037).

## 위험

- **R1 사이 상태의 팔**: 030 전까지 큰 베기의 예비 동작과 찌르기의 타격을 보통 팔로 보인다. 바이블 11절의 R1·R2 값(0.160·0.057)은 팔 그림을 끼운 값이라 029에 그대로 들지 않는다. 작업 0이 `art=0`으로 먼저 재고, 문턱을 넘으면 코드 전에 멈춘다.
- **R2 2D의 색 공간**: 셰이더의 Y 문턱은 sRGB 값에서 센다. 2D가 선형 공간에서 돌면(HDR 2D를 켜거나 엔진이 바뀌면) 선과 칠이 다르게 갈린다. S3(`tintpair`)이 잡는다: `off`가 0이 아니면 셰이더에서 색을 sRGB로 바꿔 센 뒤 다시 찍는다.
- **R3 셰이더는 헤드리스에서 컴파일되지 않는다**: 테스트(T67)는 유니폼의 값만 보고 화면을 보지 못한다. 셰이더의 문법·결과는 playtester의 창 실행(확인 2·4)과 S3·S7·S8에서만 드러난다.
- **R4 가져오기**: `.png.import` 열 개는 `705ca31`에 있다(없으면 작업 0에서 멈춘다). 밉맵을 켜면 Godot이 다시 가져온다. 새 `.uid`·`.import`는 playtester 확인 뒤의 커밋에 넣는다.
- **R5 `hold` 곡선의 반응 싸움**(원칙 4): 휘두름(0.13~0.15초)이 패리 창(0.18초) 안에서 시작한다. 고리와 타격 순간은 그대로이고, 곡선은 데이터다. 다만 `hold_curve = false`(고르게 가는 곡선)는 원칙 4로 보면 안전한 되돌림이 아니다: 바이블 11절에서 그 곡선의 R1 최대가 0.380(문턱 0.30)이다. 그래서 030의 정식 확인에 넘길 때 되돌리는 길은 끄기만이 아니라 곡선의 값(`swing_ratio`, `tell_in`, `swing_margin`)을 고치는 쪽을 먼저 둔다(디자인 비차단 2. 보고서 5번의 030 넘김 줄에 적는다).
- **R6 안쪽 테두리가 작은 파츠에서 안 읽힐 수 있다**: 손(100×109화소)과 멀리(×0.55). S7과 판 C로 본다. 읽히지 않으면 `BitMap.opaque_to_polygons`로 윤곽을 뽑아 지금처럼 `Line2D`를 바깥에 두는 길로 바꾼다(재질의 테두리만 끈다).
- **R7 테스트가 만든 상대**: `_copy_opponent()`가 새 필드를 베끼지 않으면 그 상대는 그림 없이 돈다(오류는 없다, 결정 256). 작업 7이 베끼고, T67은 로드한 상대로 본다.

## 사용자 결정 필요

**검토 전에 물은 것**: Q1의 답은 "① 맡긴다"(2026-11-22, 선택 창)이고 작업 10에 반영했다.

| # | 물음 | 선택지(첫째가 권함) | 답에 따라 달라지는 것 |
|---|---|---|---|
| Q1 | 029의 실행 확인(테스트 68개, 스모크, 그림 찍기, 게임 창)도 playtester에게 맡길까? 028에서 "맡긴다"고 답했고, CLAUDE.md 11장은 playtester를 사용자가 요청할 때만 부른다 | ① 맡긴다 — 작업 9를 마치면 바로 부른다 ② 작업 9 뒤에 다시 묻는다 | ①이면 작업 10이 바로 이어지고 판 넷까지 한 번에 보고한다. ②면 작업 9 뒤에 멈추고 보고한다(그때는 그림 없이 코드만의 보고다) |

묻지 않고 정한 것: 029·030의 경계(254), 리그는 Node2D와 Sprite2D(255), 그림·포즈의 데이터 꼴(256·257), 곡선의 함수와 바뀜의 섞기(258), 셰이더 하나와 안쪽 테두리·칠에만 흰 번쩍임(259), 머리 셋의 자리(260), 번짐은 두고 밉맵을 켬(261), 바탕 `#3A3027`(262), 오른쪽 칼 팔은 뒤로(263), 찍기 씬(264).

**029를 마친 뒤(보고서 4번)**: 위 "029 뒤 사용자가 볼 것"의 판 넷, 029의 커밋, 030의 시작과 그 몫(든 팔 주먹 그림자를 고칠 그림 한 장, 결정 245). 4단계 완료 기준에는 아직 닿지 않는다(상대 2~3명, 무대, UI, 내 손·칼이 남는다).

## 검토 대응 기록

1회차(v2. 디자인 REVISE D1·D2, 기술 REVISE T1·T2)에 대한 v3의 대응이다. 다음이 마지막 검토다(라운드 상한).

| ID | 대응 | 고친 곳 |
|---|---|---|
| D1 | 수용 | 작업 11의 판에 판 A "예비 동작 넷"(`idle-mid`와 공격 넷의 `-hold`, 교전)을 새로 두었다. 옛 판 A는 판 B "상태"가 되었다(`dodge`를 더했다). "029 뒤 사용자가 볼 것"의 표 첫 줄이 "네 멈칫이 서로, 그리고 대기와 갈리는가"를 묻는다. 찍는 장은 늘지 않았다(이미 찍던 `-hold` 넷이다) |
| D2 | 수용(가) | 작업 8의 장 표에 "멀리" 줄(`thrust-hold-far`, `cutl-hold-far`, `cutr-hold-far`, `big-hold-far`)을 더했다. 멀리에서는 예비 동작을 시작하지 않으므로 물러났을 때만 나온다는 것도 적었다(`duel_core.gd` 327~330행). 판 D "간격"의 아랫줄에 넣었고, 물음을 "멀리(예비 동작 중에 물러났을 때)에서도 네 공격이 갈리는가"로 고쳤다. 장 수는 37 → 41(4 + 16 + 2 + 4 + 5 + 6 + 2 + 2)이다. 작업 8의 완료 확인, 작업 11의 대상·S1, playtester 확인 2에 같은 수를 적었다 |
| T1 | 수용 | 결정 258에 바뀜의 시작 시각을 데이터에서 세는 항목을 더했다. 방심에 들 때는 `max(brain.state_start, brain.alert_since + complacent_time)`, 대기인 채 풀릴 때는 `brain.alert_since`다. 작업 5의 끝 문장을 이 식으로 바꿨고, 작업 7의 도우미에 방심 값(대기 `state_start = 0`, 시작 20)을, T67 6번에 −163과 시작 시각 20의 확인을 적었다 |
| T2 | 수용 | 작업 8: 점의 꼴을 `pt,<장 이름>,<점 이름>,<종류>,<x>,<y>[,<dx>,<dy>]`(정수 반올림)로 정했다. 앞머리를 떼면 `tintpair`의 `-Pts` 줄이다. S3: 메인의 감싸개가 `pt,pair-off,`를 떼어 `;`로 잇고 `measured 12`를 본다. S9: `tintpair`의 `blade` 줄 하나로 줄였다. 예비 동작 색에서 칼에 재질이 없다는 것은 T67 2번이 본다 |
| 기술 비차단(간격의 차례) | 수용 | 작업 7: `put`이 `distance`를 인자로 받아 먼저 정한다. 작업 8: 차례를 "뷰 `setup` → `put`(간격 → 상태) → `update_view`"로 바꿨다 |
| 디자인 비차단 1 | 수용 | 작업 11: 사이 상태의 장 밑에 `030까지 보통 팔`을 붙인다 |
| 디자인 비차단 2 | 수용 | 위험 R5: `hold_curve = false`는 원칙 4로 안전한 되돌림이 아니라고 적었다(그 곡선의 R1 0.380). 030에 넘길 때는 곡선 값을 고치는 길을 먼저 둔다(보고서 5번의 030 넘김 줄) |

- 스스로 고친 것: 위험 R6이 가리키는 판을 B에서 C로 바꿨다(판 이름이 밀렸다). Q1 칸의 "그림 37장"을 "그림"으로, "판 셋"을 "판 넷"으로 고쳤다.
