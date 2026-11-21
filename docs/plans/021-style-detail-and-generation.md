# 계획 021: 세부 견본과 그림 생성 시험 — 야외 무대, 바르톨로의 파츠, 의뢰인 둘

- 버전: v3 (1회차 검토 대응: D1~D4, T1~T4. 검토 중에 받은 사용자 지시(그림 생성의 모델과 추론)도 반영했다. 끝의 "수정 기록". v2는 검토 전 수정이었다)
- 개발 단계: CLAUDE.md 9장 **3단계(스타일 바이블)의 둘째 계획**. 게임 코드·씬·데이터는 고치지 않는다(교체는 4단계)
- 근거:
  - 020의 답(`docs/DECISIONS.md` "계획 020 견본에 대한 사용자 답", 2026-11-21):
    - 다리 **B**(굵기가 변하는 고동색 잉크 선, 배경과 같은 바랜 칠, 평평한 그림자 한 단계).
    - 결투는 **짙은 무대**(결정 182의 짙은 쪽. 상대 둘레의 상대 휘도 L ≤ 0.20).
    - 얼굴과 비례는 **020 견본의 크기**(상대 머리 104, 모자 45, 깃털은 옆으로 눕힘).
    - 싫은 것(원문): "무대가 너무 극장같은 느낌임. 맘에 안듬." → **야외(뒷골목·안뜰·광장)**. 짙은 톤과 상대 뒤 가운데의 조용함은 지킨다.
    - 그림 생성은 **메인이 Codex CLI로 직접** 한다(사용자의 ChatGPT 계정 사용량). 메인은 돌리기 전에 장 수를 알린다. 약관은 사용자가 "확인했다, 게임에 써도 된다". 생성 그림은 4단계의 애셋 후보도 된다(`MANIFEST.md`에 출처 generated).
    - 참고 스크린샷은 020 때 "021에서 준다"고 했다. 021 전의 답은 **이번에도 없이**다(Q1 답 "나", 2026-11-21).
  - 021 실행 전의 사용자 답(2026-11-21. "실행 전에 물을 것"):
    - 장 수 상한은 **8**(Q2 답 "가").
    - **시험 한 장**(실패하면 한 번 더, 호출 최대 2)은 실행 중에 바로 돌려도 된다. 묶음과 다시 뽑기는 실행 중에 장 수를 알리고 승인을 받는다.
  - 검토 중에 받은 사용자 지시(2026-11-21, 원문): "이미지 제작에 사용되는 모델이나 effort값은 정해져있어? 없으면 gpt 6.2 sol high으로만 작업해"
    - → 그림을 만드는 모든 Codex 호출은 **`-m gpt-6.2-sol`과 추론 `high`**로만 한다(결정 192). 사용자의 `config.toml`은 바꾸지 않고 호출마다 명시한다. v2의 "추론 `low`로 낮춰 아낀다"는 없어졌다.
    - 메인이 확인한 것: `codex debug models`에 `gpt-6.2-sol`이 있고, 추론 단계 low·medium·high·xhigh·max·ultra를 지원한다.
    - 메인이 이 지시를 `docs/DECISIONS.md` 끝(907줄쯤)에 한 줄 적었다. 커밋은 하지 않았다(작업 0·9가 이 줄을 받아들인다).
    - 의뢰인 둘은 **클라라·비토리오**(Q3 답 "가"). 클라라는 `data/commissions/feather_cut.tres`, 비토리오는 `data/commissions/variants/first_blood_usurer.tres`다.
  - 020이 021에 넘긴 것(020 "3단계를 나누는 법"과 보고서 5번): 바르톨로를 파츠별로, 의뢰인 둘, 팔레트 확정, 한글 글꼴 후보, UI 패널·버튼, 참고 색인, 생성과 SVG의 비교, `.gdignore` 사후 확인. 이 계획은 **무대·바르톨로·의뢰인·생성 시험·비교**를 하고, 팔레트 확정·글꼴·UI는 022로 옮긴다(결정 183). 참고 색인은 채우지 않는다(Q1 답). `.gdignore` 사후 확인은 첫 PNG가 참고 그림이 아니라 생성 그림이 되었다(작업 9).
  - 지키는 것:
    - 결정 12: 파츠 이름·계층 `Legs` / `Torso` > `Head` > `Hat`(> `Feather`) / `Torso` > `Arm` > `Hand` > `Sword`, 원점은 관절. 자리(`scenes/duel/opponent_view.tscn`, 원점 = 골반): 다리 0~170, 목 (0, −200), 어깨 (−65, −180), 손목은 어깨에서 (0, 105), 칼자루는 손목에서 (0, 15). 칼은 회전 0에서 위(−y)를 가리키고 대기 회전은 −25°다. 팔은 돌지 않고 옮겨지기만 한다(포즈 상수 `CHEST`·`STRIKE_OFFSET`). 상대가 가진 팔은 칼 팔 하나다.
    - 결정 179(따라 그리지 않는 선 넷)와 CLAUDE.md 7장의 그 줄.
    - 결정 181: 신호색은 코드 값 그대로, 바탕·인물 색은 신호 구역(HSV S ≥ 55%이면서 V ≥ 85%) 밖, 상대의 큰 면(몸통·다리·팔)은 S ≤ 50%, 상태 색은 칠 층에만 80%.
    - 두 줄 상태 글자의 상자(화면 x 540~740, y 62~142)를 교전의 상대가 가리지 않는다. 020 작업 3의 셈: 교전(원점 y 446, 크기 0.85)에서 목 위로 157 이하, 모자 쓴 판은 머리 + 모자 ≤ 157. 020 견본은 꼭대기 y 149.4, 깃털 끝 (769, 162)이었다.
  - 020의 견본 `docs/style/samples/020-bridge.html`에 상대(`opp`), HUD(`duelHud`·`panel`·`cells`), 고리(`ring`), 상태 글자(`stateText`), 내 손(`playerHand`), 의뢰인(`client`), 카운터(`sceneCounter`)의 함수가 있다. 극장으로 읽힌 것은 `duelStage()`에 있다: 가운데를 감싸는 아치 길(`Q290,58 640,58`), 커튼 주름(`folds`), 구경꾼(`spectators`), 난간(`balustrade`), 가운데로 모이는 바닥선(`floor`). 굽는 법은 020 작업 4다(Edge headless를 한 장씩 띄워 끝을 기다리고, 우리 `--user-data-dir`로 뜬 것만 끈다).
  - 도구 사정:
    - 메인이 확인한 것: Codex CLI 0.169.0(`C:\Users\shown\AppData\Roaming\npm\codex.ps1`, 같은 폴더에 `codex.cmd`), `codex features list`에서 `image_generation`이 stable·켜짐, `codex exec`에 `-m`·`-s`·`-i`·`--output-schema`가 있다. `OPENAI_API_KEY`는 없다.
    - planner가 본 것(읽기만 했다):
      - `C:\Users\shown\.codex\auth.json`이 있다(로그인했다고 보인다. 확인은 작업 4).
      - `C:\Users\shown\.codex\generated_images\<세션 id>\exec-<id>.png`가 25개 있다. 그림은 열어 보지 않았다. 폴더 이름은 세션(thread) id다. 이 폴더에는 `codex exec`의 그림만이 아니라 **Codex Desktop 세션의 그림도 쌓인다**(v3, T3).
      - 0.169.0의 세션 기록 둘(v3, T3·T1. 검토자가 짚은 것을 planner가 Grep으로 다시 봤다):
        - `C:\Users\shown\.codex\sessions\2026\11\18\rollout-2026-11-18T00-28-14-01a1ea1f-7a17-75d2-b563-7fb9385c1861.jsonl`은 `"originator":"codex_exec"`, 모델 `gpt-6.1-sol`, 추론 `medium`의 판이다.
          - 그림 도구는 `image_gen.imagegen(args: {prompt, referenced_image_paths?, num_last_images_to_include?, transparent_background?})`다. **크기를 정하는 인자가 없다.**
          - 도구는 코드 모드의 `exec` 도구 안에서 `tools.image_gen__imagegen({…})`로 불린다(17줄). 결과는 `generated_images\<그 세션 id>\exec-….png`다(19줄).
          - `-i`로 붙인 그림은 에이전트가 `referenced_image_paths`로 넘겨야만 그림 도구에 닿는다.
          - 덮어쓰기를 하지 않은 그 판의 도구 목록에 `mcp__cua_repl`, `js`, `web__run`, `codex_apps__…`가 들어 있다.
        - `…\2026\11\14\rollout-…-01a1d872-….jsonl`은 `"originator":"Codex Desktop"`이다.
      - 사용자의 `C:\Users\shown\.codex\config.toml`:
        - 모델 `gpt-6.2-astra`, `model_reasoning_effort = "high"`. 그림 생성에는 쓰지 않는다(결정 192).
        - 턴이 끝날 때마다 데스크톱 앱의 프로그램을 부르는 `notify`.
        - **켜진 플러그인 열**(14~42줄, 키에 큰따옴표가 든다):
          - `codex-app-tools@openai-bundled`, `browser@openai-bundled`, `unified-computer-use@openai-bundled`, `visualize@openai-bundled`, `computer-use@openai-bundled`.
          - `documents@openai-primary-runtime`, `pdf@openai-primary-runtime`, `spreadsheets@openai-primary-runtime`, `presentations@openai-primary-runtime`, `template-creator@openai-primary-runtime`.
        - MCP 서버 `node_repl`(44줄).
        - `[windows] sandbox = "elevated"`.
        - 같은 폴더(`node_modules\@openai\codex\…`)에 `codex-windows-sandbox-setup.exe`가 있다.
    - 메인이 모르는 것: `gpt-6.2-sol`이 그림 도구를 쓰는지(같은 계열 `gpt-6.1-sol`은 썼다), 에이전트가 붙인 그림을 참조 그림으로 넘기는지, 프롬프트의 크기 말이 듣는지, 덮어쓰기가 실제로 걸리는지. → **작업 5의 시험 한 장**으로 정한다.
  - CLAUDE.md 7장 154줄 "화풍과 프롬프트 기준은 3단계에서 `docs/STYLE_BIBLE.md`로 고정한다. 그 전에는 이미지 생성을 하지 않는다."가 사용자 지시(021에서 생성한다)와 어긋난다 → 작업 0에서 생성보다 먼저 고친다(CLAUDE.md 머리: 설계가 바뀌면 이 파일을 먼저 고친다). 모델·추론의 규칙도 계속 지킬 것이라 같은 줄에 넣는다(v3).
  - 020 `duelHud()`의 자리(v3, D1): 위 패널은 가운데 x 334~946·y 4~62, 왼쪽 x 10~340·y 6~156, 오른쪽 x 900~1272·y 6~64다. 아래 패널은 왼쪽 y 556~614, 오른쪽 x 780~1272·y 550~614다. 아래 띠는 y 616~720 전체다. 무대가 보이는 곳은 대략 y 64~550이다.
  - 넘지 않는 선:
    - 메인은 Godot을 어떤 방식으로도 실행하지 않는다. Edge headless와 Codex CLI는 이 규칙 밖이다.
    - 고치지 않는 것:
      - 게임: `scripts/`, `scenes/`, `data/`, `tests/`, `project.godot`.
      - 문서: `docs/BACKLOG.md`, 2단계의 보류 값(`docs/HANDOFF.md` 3번), `docs/style/samples/020-bridge.html`.
      - 사용자의 파일: `.claude/agents/playtester.md`, `tools/`, `docs/plans/013-playtester.md`.
      - 사용자의 Codex: `~/.codex/config.toml`, `auth.json`, 로그인, 기능 켜고 끄기, 샌드박스 설정, `~/.codex/generated_images/`의 파일. 복사만 한다.
- 번호: 021. 결정 번호는 183부터다(계획 020 절이 182로 끝난다. 그 뒤의 "사용자 답" 줄들에는 번호가 없다).

## 3단계를 나누는 법 (결정 183. 020의 결정 176을 고친다)

| 계획 | 하는 것 | 끝나는 때 |
|---|---|---|
| 020 (끝) | 다리 견본 셋 | 답: B, 짙은 무대, 지금 크기, 야외 |
| **021 (이 계획)** | 야외 무대 셋(SVG). 바르톨로의 파츠(SVG). Codex 생성의 시험 한 장과 묶음(바르톨로 전신·파츠 시트, 의뢰인 둘, 무대 하나). 생성 인물을 파츠로 나눠 신호를 얹기. 의뢰인 둘(클라라·비토리오, SVG와 생성) | 사용자가 **기준 이미지**(무대·상대·의뢰인)와 4단계에서 **그림을 만드는 길**(생성 / SVG / 섞기)을 고른다 |
| 022 (예정) | 고른 기준 이미지를 `docs/style/basis/`로 올리기. 팔레트 확정(고른 그림에서 뽑는다). 한글 글꼴 후보(파일과 라이선스). UI 패널·버튼. 1280×720 크기 기준 | 사용자가 글꼴·UI를 고른다 |
| 023 (예정) | `docs/STYLE_BIBLE.md`, `assets/MANIFEST.md`의 꼴, CLAUDE.md 7장 갱신 | 3단계 완료 기준 충족 → 사용자 판정 |

022·023은 021의 답으로 다시 정하고, 합칠 수 있다.

## 목표와 범위

**확인할 결과**. 메인은 파일 읽기·Grep·Glob·git·손 계산, 구운 PNG와 생성 그림의 Read, `System.Drawing`의 화소 재기로 확인한다. 고르는 것은 사용자다.

1. 사용자가 **야외 무대 셋**(뒷골목·안뜰·광장)을 020의 결투 장면과 같은 구도로 보고 고를 수 있다. 셋 모두 극장으로 읽히는 것이 없고, HUD를 얹은 채로 어느 곳인지 읽힌다. 신호가 쓰는 구역(상대 둘레·고리·두 줄 글자)은 짙고 조용하다(L ≤ 0.20을 숫자로 적는다).
2. **Codex로 그림을 만드는 절차**가 시험 한 장으로 정해져 `docs/style/GENERATION.md`에 있다. 적는 것: 결과의 자리, 크기, 한 번의 장 수, 붙인 그림을 참조 그림으로 넘겼는지와 자세를 따랐는지, 실제로 걸린 모델·추론(`gpt-6.2-sol`·`high`), 덮어쓰기마다 효과가 있었는지(세션 기록으로), 걸린 시간과 토큰, 저장소와 사용자 설정이 그대로인지. 생성이 안 되면 그 까닭이 적혀 있고, 021은 SVG만으로 끝난다.
3. **바르톨로**를 세 갈래로 견줄 수 있다: SVG(다리 B), 생성 전신을 자른 것(G1), 생성 파츠 시트(G2). 셋 모두:
   - 결정 12의 파츠로 나뉜다.
   - 지금 코드의 상태 넷, 큰 베기의 예비 동작(두 줄 글자·고리·조준), 멀리의 방심이 얹힌다.
   - 칠(그림자 톤 포함)만 물들고 선이 남는다(결정 181).
   - 두 줄 글자 상자를 가리지 않는다.
   - 머리 높이가 사용자가 고른 104(±5%)이고, 팔(어깨~손목)이 105에 맞는다. 화풍만 다르고 비례는 같게 견준다.
   - 상태마다 얼굴이 바뀐다. SVG는 020의 얼굴들이고, 생성은 G2 시트의 머리 셋(거만함·당황·어지러움)이다. G1은 얼굴 하나이고 그렇게 적는다.
4. **의뢰인 둘**을 SVG와 생성으로 카운터 자리에 놓고 견줄 수 있다.
5. 생성 그림의 색이 신호 구역과 큰 면의 채도 규칙을 지키는지, 생성 무대의 가운데 밝기가 기준 안인지 숫자로 적혀 있다.
6. 생성은 상한과 사용자가 승인한 장 수 안에서만, `gpt-6.2-sol`·`high`로만 돌았다. 참고 스크린샷은 생성에 들어가지 않았다. 저장소와 사용자의 Codex 설정(`config.toml`의 해시)이 그대로다.
7. 끝에 사용자가 기준 이미지와 그림을 만드는 길을 고를 수 있다(보고서 4번).

**범위 밖**: 팔레트 확정·글꼴·UI·1280×720 크기 기준(022), `docs/STYLE_BIBLE.md`·`MANIFEST.md`(023), `assets/`, 고른 그림을 저장소에 올리기(022), 카운터 배경의 생성(020의 B 그대로 쓴다), 상대 둘째·셋째(4단계), 감정 상태 셋(게임에 없다), 참고 색인 채우기(Q1 답 "나").

## 생성의 틀

### 막는 장치 (결정 184)

Codex가 저장소·사용자의 데스크톱과 브라우저·사용자의 Codex 설정을 건드리지 않게 다섯 겹을 둔다. Windows에서 Codex의 샌드박스가 실제로 무엇을 막는지는 메인이 확인하지 못하므로 한 겹에 기대지 않는다. 겹마다 "걸렸는지"를 세션 기록이나 해시로 본다(v3, T1·T2).

1. **저장소 밖의 빈 작업 폴더**: 호출마다 새 폴더 `<scratchpad>\codex\<G번호>-<시도>\`를 만든다. 넣는 것은 `prompt.txt`와 `-i`로 줄 우리 그림의 복사본뿐이다. 저장소 경로는 명령줄과 프롬프트 어디에도 쓰지 않는다.
2. **읽기 전용 샌드박스**: `-s read-only`. 에이전트에게는 그림 도구를 한 번 부르는 것만 시키고, 셸·파일·다른 도구는 쓰지 않게 한다. 그림 파일은 Codex 자신이 `generated_images/<세션 id>/`에 둔다. read-only로 그림이 남는 것은 같은 버전의 기록에서 확인되었다(검토자). F9는 예비로만 둔다.
   - F9가 나면 한 번만 `-s workspace-write`로 바꾼다. 쓰기는 작업 폴더 안이다.
   - `danger-full-access`와 `--dangerously-bypass-approvals-and-sandbox`는 쓰지 않는다.
3. **이 호출에만 듣는 끄기** `-c`. 설정 파일은 고치지 않는다(v3, T1).
   - 끄는 것: `notify`(`notify=[]`), MCP 서버 `node_repl`, 그리고 `config.toml`에서 `enabled = true`인 **플러그인 열 전부**(근거의 목록). 남기는 것은 없다. 그림 도구는 플러그인이 아니라 기능(`image_generation`)이라 끄지 않는다.
   - **따옴표를 쓰지 않는다**: 플러그인 키의 큰따옴표는 `Start-Process` → `codex.cmd`(`%*`) → node를 지나며 벗겨지거나 망가진다. 그래서 작업 4에서 따옴표 없는 꼴의 후보를 차례로 시험한다.
     1. `codex features list`에 플러그인·앱을 끄는 기능이 있으면 `--disable <기능>` 같은 그 호출만의 옵션.
     2. `-c plugins.<이름>.enabled=false`(따옴표 없이. `<이름>`은 `computer-use@openai-bundled` 등).
     3. `-c mcp_servers.node_repl.enabled=false`.
   - **`-c`는 키가 틀려도 오류 없이 무시한다**. 그래서 "오류가 안 났다"를 "걸렸다"로 치지 않는다. 걸렸는지는 둘로 본다.
     - MCP: 작업 4에서 같은 덮어쓰기로 `codex mcp list`를 돌려 본다(사용량 없음).
     - 플러그인과 MCP: 호출마다 그 세션의 기록을 Grep한다(5겹째).
     - `notify`의 효과는 볼 길이 없어 "확인 못 함"으로 적는다.
   - 덮어쓰기마다 효과(걸림 / 안 걸림 / 확인 못 함)를 `GENERATION.md`에 적는다.
   - G1에서 효과가 없던 덮어쓰기가 있으면 "걸렸다"로 치지 않는다. 승인 B에서 사용자에게 알리고, 그대로 묶음을 돌릴지는 묶음 전에 사용자가 정한다.
   - **모델과 추론**은 끄기가 아니라 사용자 지시다(결정 192). 호출마다 `-m gpt-6.2-sol -c model_reasoning_effort=high`를 따옴표 없이 쓴다. 걸린 값은 세션 기록 `turn_context`의 `"model":"gpt-6.2-sol"`과 `"effort":"high"`로 확인해 기록 표에 적는다. 다르면 그 호출의 그림은 쓰지 않고 멈춰서 보고한다.
4. **프롬프트의 금지**: 그림 도구를 부르는 데 필요한 감싸는 코드 도구만 허용한다. 셸 명령, 파일 읽기·쓰기, 브라우저·웹 검색·컴퓨터 조작·앱·다른 도구, 다시 하기는 금한다(아래 프롬프트의 "지시" 블록).
5. **호출마다 전후 대조와 세션 기록**. 호출 바로 전과 바로 뒤에 아래가 같아야 한다.
   - `git -C C:\godot\bravi status --short`와 `git -C C:\godot\bravi diff --stat`.
   - `Get-FileHash ~/.codex/config.toml`(v3, T2). 다르면 F7처럼 멈춘다.
   - `~/.codex/generated_images/` 아래에서 시작 시각 전에 있던 파일의 수.
   - 작업 폴더에는 넣은 것과 `events.jsonl`·`err.txt`·`last.txt`만 있다.
   - **대조에서 빼는 것**(Codex가 늘 바꾸므로 잘못 멈추지 않게): `auth.json`(토큰 갱신), `sessions/`, `generated_images/`의 새 폴더, 로그·캐시(`log/`, `.tmp/` 등).
   - **세션 기록**(v3, T1): `events.jsonl`의 `thread.started`에서 thread_id를 얻고, `~/.codex/sessions/**/rollout-*-<thread_id>.jsonl`을 Grep한다. 파일 전체는 Read하지 않는다.
     - 노출된 도구 목록에 `mcp__cua_repl|"name":"js"|codex_apps|browser`가 없다.
     - 부른 도구가 그림 도구(`image_gen__imagegen`)와 그것을 감싸는 코드 도구(`exec`)뿐이다. `exec_command`, `web__run`, 셸, 파일 쓰기 같은 다른 도구를 부르지 않았다.
     - `turn_context`의 모델·추론(3겹째).
     - 그림 도구에 넘긴 인자: `referenced_image_paths`, `num_last_images_to_include`, `transparent_background`.
     - 어긋나면 그 결과를 `GENERATION.md`에 적고 승인 B(또는 다음 승인 지점)에서 알린다. 다른 도구를 실제로 불렀으면 F7처럼 멈춘다.

**명령의 꼴**. 옵션 이름은 작업 4의 `codex exec --help`로 맞추고, 실제 명령은 `GENERATION.md`에 적는다.

```
codex exec --skip-git-repo-check -C <작업 폴더> -s read-only --json -o <작업 폴더>\last.txt
           -m gpt-6.2-sol -c model_reasoning_effort=high
           -c notify=[] -c mcp_servers.node_repl.enabled=false -c plugins.<이름>.enabled=false (열)
           --image=<작업 폴더>\in-1.png [--image=<작업 폴더>\in-2.png]  -
```

- 명령줄 어디에도 큰따옴표를 쓰지 않는다(위 3겹째). 끄기의 꼴은 작업 4에서 고른 것으로 바꾼다.
- 프롬프트는 `prompt.txt`로 써서 표준 입력으로 준다(끝의 `-`). 영어, ASCII만, 큰따옴표 없이 쓴다(PowerShell의 인자 나누기와 인코딩 문제를 피한다).
- `--image=` 꼴을 쓰는 까닭: `-i`가 여러 값을 받으면 뒤의 `-`를 그림으로 읽을 수 있다. 도움말에 따라 바꾼다.
- 작업 폴더가 git 저장소가 아니라서 `--skip-git-repo-check`가 필요하다고 본다.

**띄우고 기다리기**.

- `Start-Process -FilePath "$env:APPDATA\npm\codex.cmd" -ArgumentList … -RedirectStandardInput prompt.txt -RedirectStandardOutput events.jsonl -RedirectStandardError err.txt -NoNewWindow -PassThru`로 띄운다.
- `Wait-Process -Timeout 900`으로 기다린다.
- 시간을 넘기면 그 PID의 나무만 끈다(`taskkill /PID <id> /T /F`). Codex를 이름으로 끄지 않는다(사용자의 Codex 앱이 있다).

**결과 찾기**. 아래 차례로 찾는다.

1. `events.jsonl`의 `thread.started`에서 얻은 thread_id의 폴더 `~/.codex/generated_images/<thread_id>/`(v3, T3).
2. 그 세션 기록(`rollout-*-<thread_id>.jsonl`)과 `events.jsonl`을 Grep한다(`generated_images`, `.png`). 파일 전체를 Read하지 않는다(그림이 base64로 들어 있으면 크다). base64로만 있으면 `[Convert]::FromBase64String`으로 풀어 PNG로 쓴다.
3. 작업 폴더.
4. 마지막으로만 시각으로 찾는다: 시작 시각 뒤에 생긴 `generated_images/` 아래의 폴더. 같은 자리에 사용자의 Desktop 세션 그림도 쌓이므로, 그 폴더 이름이 이 호출의 세션 기록에 나올 때만 받는다.

찾은 그림은 **복사**해서 `docs/style/generated/021-<G번호>-<이름>.png`로 둔다. 원래 자리의 파일은 건드리지 않는다.

### 장 수와 승인 (결정 185)

- **세는 법**:
  - 장 = 만들어진 그림. 한 호출에 한 장만 시키고, 두 장 이상 나오면 모두 센다.
  - 호출 = 모델까지 간 `codex exec`. 그림이 없어도 사용량을 쓰므로 센다. 옵션 오류로 바로 끝난 것은 세지 않는다.
  - **장과 호출 모두 상한 8**(Q2 답 "가").
- **승인 지점 셋**. 메인은 지점마다 장 수·주제·남은 상한을 사용자에게 알리고 답을 기다린다.

  | 지점 | 때 | 무엇 | 알리는 것 |
  |---|---|---|---|
  | A | 실행 전에 받았다(Q2 답: 실행 중 바로 돌려도 된다) | 시험 G1 한 장. 실패하면 같은 몫으로 한 번 더(호출 최대 2) | 돌리기 직전에 "시험 1장(실패하면 1장 더)을 돌린다"고 한 줄 알린다. 답은 기다리지 않는다 |
  | B | 작업 5 뒤, 실행 중 | 묶음 G2~G5 넷과 생성할 무대 하나 | 시험 결과(자리, 크기, 걸린 시간). 사용량은 가늠할 수 있는 꼴로 알린다: 토큰, 그리고 이벤트나 세션 기록에 계정 한도 대비 비율이 있으면 그것. 걸린 모델·추론, 덮어쓰기마다의 효과(효과 없던 것이 있으면 그대로 묶음을 돌릴지 묻는다), 붙인 그림을 참조로 넘겼는지, G1의 굳은 확인. 무대 셋의 견본(`021-detail.html`의 `stage-*`). 묶음은 **끝에서부터 줄일 수 있게 차례로** 놓아 묻는다: G2 → G5 → G3 → G4. 남은 상한도 알린다. G1이 굳은 확인에 걸렸으면 G1을 다시 뽑을지(다시 뽑기 몫)도 묻는다. **사용자가 무대 셋이 다 극장 같다고 하면 G5는 돌리지 않는다**(보고서에 적고 무대는 다음 계획에서 다시 그린다) |
  | C | 작업 7 중, 실행 중(있을 때만) | 굳은 확인(작업 6의 H표)에 걸린 그림의 다시 뽑기. 주제마다 한 번, 합 2 이하 | 주제, 걸린 확인, 바꾼 프롬프트 줄 |

- 사용자가 줄이면 그만큼만 돌린다. 상한에 닿거나 사용자가 그만이라고 하면 더 돌리지 않고, 있는 그림으로 작업 7~9를 한다.
- 승인을 기다리는 동안 `docs/HANDOFF.md` 1번을 그 자리("승인 B를 기다린다" 등)로 적어 둔다(세션이 바뀌어도 이어 가게).
- 8의 셈: 시험 1 + 시험의 예비 1 + 묶음 4 + 다시 뽑기 2. 고르지 않은 안(4, 12)은 "실행 전에 물을 것"의 기록에 있다.

### 프롬프트의 틀 (결정 187. STYLE_BIBLE 13번의 초안)

- **쓰는 법**:
  - 영어, ASCII만, 큰따옴표 없이.
  - 두 게임·제작사·작가의 이름을 쓰지 않는다(결정 179).
  - 화풍은 다리 B를 말로만 적는다.
  - 참고 색인 없이 쓴다(Q1 답 "나"). 화풍의 말은 `REFERENCES.md`의 "말로 받은 방향"과 020의 답(B)에서만 온다.
- **블록 일곱**:
  1. 지시: Codex 에이전트에게. 한 장, 금지들, 답은 한 줄.
  2. 그림: 쓰임과 크기.
  3. 주제: 누구인지. 성격 한 줄과 옷. 의뢰 데이터의 사연에서 말로만 뽑는다.
  4. 구도와 자세: 상대는 파츠로 나눌 수 있는 정면, 의뢰인은 허리 위, 무대는 가운데를 비운다. 넣은 그림(`-i`)을 따르라는 줄도 여기에 둔다.
  5. 화풍.
  6. 색: 신호 구역을 피하는 말.
  7. 바탕.
- **G1 전문** (`docs/style/prompts/021-G1-bartolo-front.txt`. 넣는 그림은 `in-front` 하나):

  ```
  Task: call your image generation tool exactly once to create exactly one image. You may use the code tool only to make that one call. Pass the attached sketch to the image generation tool as a referenced image by its path: {WORKDIR}\in-1.png. Do not run shell commands. Do not read, create, change or delete any file. Do not use a browser, web search, computer use, apps or any other tool. Do not retry. When the image is done, reply with one line: done.

  Image: one full-body character for a 2D duel game. Portrait, 1024x1536 pixels.

  Subject: Bartolo, a vain and quarrelsome gentleman duelist from a Renaissance-era Italian town. Doublet with buttons and a small ruff collar, breeches, stockings, plain shoes, a small low-crowned hat with one long feather. He holds a rapier.

  Pose and layout (the figure will be cut into separate parts, so keep the parts apart):
  - Follow the attached sketch for the pose, the proportions and the place of every part. Keep the same large head size.
  - Strictly front view, facing the viewer, standing upright, head straight, feet apart.
  - His sword arm is on the viewer's left. It hangs down beside the body with a clear gap between the arm and the torso. The arm is short, as in the sketch: the hand is at waist height, just above the belt and higher than the hips. The hand holds the rapier with the blade pointing up and leaning outward, away from the body, so the blade crosses neither the body nor the head.
  - His other hand is hidden behind his back.
  - The feather lies sideways toward the viewer's right, not upward.
  - Nothing covers the face. The whole figure is inside the image with a margin. Nothing is cropped.

  Style:
  - Big head, simple face: dot eyes, simple eyebrows, a small mouth. His character shows in the expression: smug and touchy.
  - Hand-inked outlines in very dark warm brown. The line weight varies: thicker on the outer contour, thinner inside, tapered ends, slightly rough edges.
  - Flat fills from a muted, faded earthy palette: parchment beige, faded brick red, olive green, dusty grey-blue, ochre, wood brown, warm skin tones.
  - Exactly one flat shadow tone per color. No gradients, no soft shading, no highlights, no texture inside the fills.
  - The outlines are the darkest color in the image. Every fill is clearly lighter than the outlines, and the shadow tones are also clearly lighter than the outlines.

  Colors to avoid on the figure: bright saturated yellow, orange, red, blue, purple or green, and pure white. Large areas such as the doublet, sleeves and breeches are greyish and low in saturation.

  Background: one plain flat light grey color, about #D8D8D8, everywhere around the figure. No floor, no cast shadow, no scenery, no frame, no text, no letters, no signature, no watermark.
  ```

  - `{WORKDIR}`는 메인이 작업 폴더의 절대 경로(scratchpad 아래, ASCII)로 바꿔 쓴다. 저장소의 프롬프트 파일에는 `{WORKDIR}`대로 둔다(v3, T3).
  - 그림 도구에 크기 인자가 없어 "1024x1536"은 바람일 뿐이다(근거). 나온 크기를 받아 쓴다.
  - 그림 도구에 `transparent_background`가 있다. 021은 한 색 바탕과 테두리 채우기로 하고, 이 인자는 4단계 컷아웃의 후보로 `GENERATION.md`에 적는다(검토자 제안).

  - 각 줄의 까닭:
    - 칼 팔과 몸통 사이의 틈, 다른 손을 등 뒤에: 상대의 팔 파츠가 하나이고 팔은 옮겨지기만 한다(결정 12).
    - 칼날이 위로 바깥으로: 대기 회전 −25°의 꼴.
    - 깃털을 옆으로: 두 줄 글자 상자.
    - 손이 허리띠 바로 위: 결정 12의 손목은 어깨 (−65, −180)에서 105 아래, 곧 골반 위 75다(v3, T4). 엉덩이 높이로 그리면 어깨~손목이 약 180이 되어 자른 팔이 맞지 않는다.
    - 선이 가장 어둡고 그림자 톤도 선보다 밝다: 상태 색을 칠에만 입히는 밝기 문턱(아래). 그림자가 문턱 아래면 예비 동작의 색이 큰 면에서 빠진다(v3, D2).
    - 참조 그림을 경로로 넘기라는 지시: 붙인 그림은 에이전트가 넘겨야만 그림 도구에 닿는다(v3, T3). 감싸는 코드 도구를 허용한 것은 그림 도구가 그 안에서 불리기 때문이다.
    - 피할 색과 큰 면의 낮은 채도: 결정 181.
    - 한 색 바탕: 테두리 채우기로 지운다.
- **G2~G5는 G1에서 바꾸는 블록만**. 지시 블록은 모두 같다. 화풍·색 블록은 G2~G4에서 같고 G5는 표 아래의 둘을 바꾼다.

  | G | 그림 | 주제 | 구도와 자세 | 바탕 (G5는 화풍) | 넣는 그림 |
  |---|---|---|---|---|---|
  | G2 바르톨로 파츠 시트 | Landscape, 1536x1024. One sheet of separate body parts of the same character for cutout animation | 같은 사람 | 지시 블록의 참조 그림은 둘이다: `{WORKDIR}\in-1.png`(G1 원본), `{WORKDIR}\in-2.png`(`in-parts`). The first referenced image is the character: draw exactly the same character, colors and style. The second referenced image shows where each part goes: follow it. 파츠(머리 셋을 포함해 열): **the same head drawn three times without hat, each with a short neck stub, with three expressions: smug and haughty, flustered and caught off guard, dizzy and dazed** (v3, D4), hat without feather, the feather alone, torso without arms and legs (shoulders and neck base complete), the sword arm from shoulder to wrist as one piece (rounded top, short as in the sketch), the fist alone as if gripping, the rapier alone (blade, guard and grip, pointing straight up), the legs from the waist down with shoes. Draw each part complete, including the areas that would be hidden behind other parts. Clear empty space between all parts. No labels, no numbers, no guide lines | G1과 같다 | G1 원본, `in-parts` |
  | G3·G4 의뢰인 | Portrait, 1024x1536. One shop customer from the waist up for a counter scene | G3 클라라, G4 비토리오(Q3 답). 메인이 사연(그 `.tres`의 `dialogue`)에서 직업·살림·기분을 말로 쓴다 | Front view or a slight three-quarter view, head straight, both hands visible at waist level (they stand behind a shop counter that is not drawn). Follow the attached sketch for proportions and framing | G1과 같다 | `in-client-1` 또는 `in-client-2` |
  | G5 무대 | Landscape, 1536x1024. Background for a duel scene in a 2D game. The top and bottom 80 pixels may be cropped, so keep important things inside the middle band | 승인 B에서 고른 곳(뒷골목·안뜰·광장)의 해 질 녘. No people, no animals | Follow the attached sketch for the composition. The area right behind the duelist, the middle 35 percent of the width from top to bottom, has no linework and no small details. Large dark shapes of the place may continue into it as flat tones (the ground, a far wall, a strip of night sky). Everywhere else the place is clearly recognizable even if the top and bottom bands are covered. The edge between the detailed parts and the calm middle is not a straight vertical line, and the left and right sides are not mirror images. No arches, no curtains, no stage, no audience, no railings or balustrades, no spotlights, no floor lines that meet in the center, no frame around the center, no glowing lights | 화풍 블록 대신: old hand-colored engraving look, dark brown ink linework, hatching and cross-hatching near the edges, faded parchment and umber tones, dark evening light overall. No text, no signature | `in-stage` |

  - 무대의 35%는 조용한 구역의 폭(작업 3, 어림 x 440~840 = 400px)에 여유를 더한 448px ÷ 1280이다(v3, D1. v2의 55%는 020 아치의 폭이었다).
  - G3·G4는 지시 블록의 참조 그림이 `{WORKDIR}\in-1.png` 하나(그 사람의 `in-client-*`)다. G5도 하나(`in-stage`)다.
  - G5만 다른 블록이 둘 더 있다.
    - 화풍 블록은 표의 다섯째 칸 글로 바꾸고, 인물의 바탕 블록(한 색 회색)은 뺀다.
    - 색 블록은 "on the figure"를 "in the image"로 바꾼다. 큰 면 줄은 "The central dark area has no bright or saturated color"로 바꾼다.
  - G3·G4의 화풍 블록에서 표정 줄은 그 사람의 성격으로 바꾼다.

### 생성 인물을 파츠로 나누는 법 (결정 188. STYLE_BIBLE 5·13번의 초안)

두 길을 같은 사람으로 시험해 견준다: **가. 전신 한 장을 자른다(G1)**, **나. 파츠 시트를 따로 그리게 한다(G2)**.

1. **바탕 지우기** (G1~G4):
   - 그림의 테두리에서 시작해, 바탕색(테두리 화소의 가운데 값)과 가까운(채널 차 ≤ 28) 이어진 화소만 투명하게 한다(테두리 채우기). 인물 안의 같은 색은 잉크 윤곽이 막아 남는다.
   - 가장자리 1px 고리를 한 번 깎는다.
   - 손질본은 `docs/style/generated/cut/`에 둔다.
   - 도구: 메인이 scratchpad에 쓰는 PowerShell 한 파일(`Add-Type`의 C# 한 토막. 테두리 채우기, 화소 재기). 저장소에는 넣지 않는다. 방법은 `GENERATION.md`에 적는다.
   - 확인: 네 귀퉁이의 알파가 0이다. 어두운 바탕에 얹어 구운 것을 Read로 봐서, 인물 안으로 새 나간 곳과 회색 후광이 없다. 새면 허용 차를 한 번 바꿔 보고, 그래도 새면 굳은 확인 H3에 걸린 것으로 친다.
2. **관절 맞추기** (G1·G2):
   - `g1-raw--grid`·`g2-raw--grid`(그림 위에 50px 격자와 좌표 글자)를 구워 Read로 본다. 그림 좌표로 읽는 점: 목, 골반, 어깨, 손목, 칼자루, 모자 챙의 가운데(±5px).
   - 크기 k = 200 ÷ (골반 y − 목 y)(파츠 단위/화소).
   - 파츠마다 제 관절 점이 결정 12의 자리에 오게 놓는다.
   - **머리는 104에 맞춘다**(v3, D3). 머리 높이(목~정수리) × k를 재고, `g*-states`·`g-duel`·`g-far`·`g-stage`에서 머리 파츠(모자 포함)를 목 관절을 중심으로 키우거나 줄여 104(±5%)로 만든다. 사용자가 고른 얼굴 크기로 SVG와 견주려는 것이다.
     - 그다음 교전 꼭대기 y = 446 − (200 + 머리 + 모자) × 0.85 ≥ 142인지 셈한다. 넘으면 **모자만** 줄인다(머리 104 + 모자 ≤ 157이니 모자는 53 이하). 깃털 끝이 상자 밖인지도 적는다.
     - 생성 원래의 머리 비(× k)와 맞춘 배율은 자료로 `palette`와 `GENERATION.md`에 적는다.
   - **팔은 105에 맞춘다**(v3, T4). 어깨~손목 × k를 105와 견줘 적는다. ±15%를 넘으면 Arm 파츠를 어깨를 중심으로 세로로만 줄이거나 늘여 105로 맞추고, 그 비를 적는다. 손과 칼은 손목의 새 자리를 따라간다. G1·G2에 같은 규칙을 쓴다.
3. **자르기**:
   - 가(G1): 파츠마다 그림 좌표의 다각형 `clipPath`로 자른다. 파일은 나누지 않는다.
     - 팔은 몸통과의 틈을 따라 자른다. 손은 주먹 둘레, 칼은 주먹 밖의 칼날·코등이다.
     - 머리는 목 밑을 경계로, 다리는 허리띠 밑을 경계로 자른다. 모자와 깃털도 따로다.
     - 팔이 옮겨 가면 원래 자리는 빈다. 몸통의 옆선이 그대로면 괜찮다.
     - 가려졌던 곳(주먹 밑의 칼자루, 챙 밑의 머리)은 그림에 없다. 보이는 구멍·유령은 결과로 적는다.
   - 나(G2): 파츠마다 둘레 상자로 자르고, 관절 점은 격자로 읽는다. 가려질 곳까지 그려져 있으면 구멍이 없다.
     - 머리 셋은 상태마다 고른다(v3, D4): 대기·찌르기 예비 동작·큰 베기·방심은 거만한 머리, 빈틈은 당황한 머리, 무너짐은 어지러운 머리다. 세 머리에 같은 k와 같은 104 맞춤을 쓴다.
     - 머리가 하나만 나오면 그 하나를 모든 상태에 쓰고 그렇게 적는다.
   - G1은 머리가 하나라 모든 상태에 같은 얼굴이다. `g1-states`의 캡션에 "G1은 얼굴 하나다(표정 바꾸기는 G2에서 본다)"를 적는다.
   - 칼의 각도: 그림 속 칼날의 각 θ0를 잰다. 코드의 회전 r을 그릴 때는 칼자루를 중심으로 (r − θ0)만큼 돌린다. 팔은 코드처럼 옮기기만 하고 돌리지 않는다.
4. **상태 색은 칠에만** (결정 181을 래스터로 옮긴 것). 파츠의 그림에 SVG 필터 하나를 씌운다(`color-interpolation-filters="sRGB"`).
   1. 밝기 문턱으로 선 가림을 만든다. sRGB 값의 Y = 0.2126R + 0.7152G + 0.0722B가 약 0.22 아래면 선, 0.30 위면 칠, 그 사이는 비례다.
   2. 신호색을 80% 불투명으로 그림의 알파 안에 덮는다. 이것이 `lerp(바탕, 신호, 0.8)`이다.
   3. 선 가림 안의 원래 화소를 다시 위에 놓는다.
   - 물들이는 파츠와 머리를 지키는 규칙은 020과 같다: 다리·몸통·머리·팔·손은 물들이고, 모자·칼은 제 색이다. 빈틈 칸의 머리는 바탕 칠이다.
   - SVG 쪽은 그림자 톤까지 물든다(020 `opp()`의 그림자가 칠 층에 있다). 생성 쪽도 몸통·다리·팔의 칠과 **그림자 톤이 모두 문턱 위**여야 같은 조건으로 견줄 수 있다. 이것을 굳은 확인 H8로 본다(v3, D2).
   - 작은 어두운 칠(머리카락, 구두)이 선으로 읽혀 물들지 않는 것은 결과로 적는다(위험 7).
   - 이 필터는 견본에서 보이기 위한 것이다. 4단계의 Godot 셰이더 후보로 적는다. 021에서 코드는 고치지 않는다.

### 저장 (결정 189)

| 무엇 | 자리 | 저장소 |
|---|---|---|
| 생성 원본 | `docs/style/generated/021-G<n>-<이름>.png` | 올리지 않는다(`.gitignore`) |
| 손질본(바탕을 지운 것) | `docs/style/generated/cut/` | 올리지 않는다 |
| `-i`로 넣은 우리 그림(SVG를 구운 PNG) | `docs/style/generated/in/` | 올리지 않는다(HTML에서 다시 굽는다) |
| 프롬프트 | `docs/style/prompts/021-G<n>-<이름>.txt` | 올린다 |
| 기록(절차, 틀, 호출마다 한 줄) | `docs/style/GENERATION.md` | 올린다 |
| 견본 페이지 | `docs/style/samples/021-detail.html` | 올린다 |

- 생성 원본은 한 장에 1~3MB로 짐작한다(시험에서 바이트를 적는다).
- 사용자가 기준 이미지로 **고른 것만** 022의 첫 작업에서 `docs/style/basis/`로 복사해 올린다. 한 장이 5MB를 넘으면 그때 줄일지 묻는다.
- 고르지 않은 것은 로컬에 남는다. 다른 컴퓨터로 옮기려면 사용자가 따로 옮긴다(`HANDOFF.md`).
- 저장소에 그림이 없으면 다른 컴퓨터에서는 페이지의 생성 섹션이 빈 그림으로 보인다.
- `docs/style/.gdignore`가 `docs/style/` 아래 전체를 Godot에서 뺀다(하위 폴더 포함). 참고 그림이 이번에도 들어오지 않으므로(Q1 답) `docs/style/` 아래의 첫 PNG는 작업 5에서 복사한 G1이다. 확인은 작업 9와 "사용자 결정 필요" 5.

## 작업 목록

**공통 규칙**

- 근거의 "넘지 않는 선"을 지킨다.
- 만드는 것:
  - `docs/style/` 아래의 새 파일(위 저장 표).
  - `.gitignore`의 두 줄.
  - 작업 0·9의 문서 기록.
- 차례는 **결투 먼저**다(원칙 4): 무대 셋 → 바르톨로 → 의뢰인. 의뢰인을 다 못 하면 그 섹션을 빈 채로 두고 보고서 1번에 적는다.
- 대조가 어긋나면 값을 맞추지 말고 멈춰서 보고한다.
- 구운 PNG는 scratchpad에 둔다. `-i`로 넣는 것만 `docs/style/generated/in/`에 복사한다.

### 작업 0. 시작 전의 기록과 CLAUDE.md 7장의 두 줄

- 시작 상태를 적는다:
  - `git log -1 --oneline`이 `7069984`(3단계 시작: 화풍의 다리 견본)다.
  - `git status --short`에 이 계획 파일(`?? docs/plans/021-style-detail-and-generation.md`)과 `M docs/DECISIONS.md`만 있다. 다른 변경이 있으면 멈추고 사용자에게 묻는다.
  - `M docs/DECISIONS.md`는 메인이 검토 중에 적은 사용자 지시 한 줄(모델·추론, 끝의 907줄쯤)이다(v3). `git diff -- docs/DECISIONS.md`가 그 한 줄뿐인지 보고, 그 diff를 적어 둔다. 작업 9의 대조에서 이 줄을 따로 센다.
- 기준을 적는다: Glob `docs/style/reference/*.{png,jpg,jpeg,webp}`의 수(Q1 답 "나"라 0이어야 한다. 있으면 사용자가 넣은 것이니 읽지도 쓰지도 않고 보고서에 적는다), Glob `docs/style/**/*.import`의 수(0이어야 한다).
- **생성보다 먼저** CLAUDE.md 7장을 고친다(사용자 지시 2026-11-21):
  - 154줄 → "화풍과 프롬프트 기준은 3단계에서 `docs/STYLE_BIBLE.md`로 고정한다. 이미지 생성은 3단계의 견본(계획 021)부터 메인이 Codex CLI로 하고, 돌리기 전에 장 수를 사용자에게 알린다. 그림을 만드는 Codex 호출은 모델 `gpt-6.2-sol`, 추론 `high`로만 하고, 사용자의 Codex 설정은 바꾸지 않고 호출마다 명시한다(사용자 지시 2026-11-21). 생성 그림은 `docs/style/generated/`에 로컬로 두고 고른 것만 올린다."
  - 155줄의 "이미지 생성에 이미지로 넣지 않고" → "이미지 생성에 참고 이미지를 넣지 않고(우리 그림은 넣어도 된다. 결정 186)".
- 완료 확인: `git diff -- CLAUDE.md`가 7장의 이 두 줄뿐이다.

### 작업 1. 저장 자리

- `.gitignore` 끝에 두 줄을 더한다:

  ```
  # 생성 그림의 원본·손질본·넣은 그림은 로컬에만 둔다. 고른 것만 docs/style/basis/로 올린다 (계획 021, 결정 189)
  /docs/style/generated/
  ```

- `docs/style/GENERATION.md`(새 파일)를 만든다.
  - 머리: 쓰임, 결정 184~189를 가리키는 한 줄.
  - "절차": 작업 4·5에서 채운다.
  - "프롬프트의 틀": 위 블록 일곱. 작업 5 뒤에 고친 것을 반영한다.
  - "기록" 표의 칸: `G | 날 | 승인 | 프롬프트 파일 | 넣은 그림 | 옵션 | 모델·추론(세션 기록) | 참조 그림 인자 | 덮어쓰기 효과 | 결과(파일, 크기 px, 바이트) | 걸린 시간 · 토큰 · 한도 비율 | 찾은 자리(thread_id) | 굳은 확인 | 쓴 섹션`.
  - "4단계 후보": 그림 도구의 `transparent_background` 인자(검토자 제안).
- `docs/style/prompts/` 폴더는 작업 5·6에서 채운다.
- 완료 확인:
  - `git check-ignore -v docs/style/generated/021-G1-bartolo-front.png`가 새 줄을 가리킨다.
  - `git check-ignore docs/style/GENERATION.md docs/style/prompts/021-G1-bartolo-front.txt`는 아무것도 내지 않는다.
  - `git status --short -uall -- docs/style`에 `GENERATION.md`가 보인다.

### 작업 2. 참고 색인 — 하지 않는다 (Q1 답 "나")

- 참고 스크린샷을 받지 않았다. `docs/style/REFERENCES.md`는 고치지 않는다(빈 표와 "계획 021에서 채운다" 줄이 그대로 남는다. 색인을 언제 채울지는 022 이후에 다시 묻는다).
- 작업 번호는 그대로 둔다(다른 작업이 번호로 가리킨다).
- v1에서 이 작업에 있던 확인 가운데 "Grep `reference`가 `docs/style/prompts/`에서 0건"은 참고 그림과 상관없이 지킬 선이라 작업 6의 완료 확인으로 옮겼다.

### 작업 3. SVG 견본 — `docs/style/samples/021-detail.html`

- **대상**: 새 파일 하나. 020 작업 3의 규칙을 따른다:
  - `<head>` 맨 앞에 `<meta charset="utf-8">`.
  - 스크립트는 문서를 읽는 동안 한 번에 그린다.
  - 섹션과 `<style>`의 색 변수는 HTML 글로 쓴다.
  - 바깥 자원은 없다. 상대는 `data-part` 무리로 그린다.
- 020과 다른 점 하나: 생성 섹션은 `<image href="../generated/…">`로 생성 그림을 가리킨다. 이 꼴만 쓴다.
- `020-bridge.html`은 고치지 않는다. 필요한 함수를 옮겨 쓰고, 다리 B의 class와 변수만 남긴다. 무대 전환 단추(밝은 무대)는 두지 않는다(짙은 무대로 정해졌다).
- **섹션 24**. 생성 섹션도 늘 두고, 그림이 없으면 "만들지 않았다(까닭)" 한 줄을 보인다. 페이지의 차례는 표의 차례다.

  | id | 무엇 | 크기 |
  |---|---|---|
  | `stage-alley`, `stage-court`, `stage-piazza` | 야외 무대 셋. 020 `b-duel`과 같은 장면이고 배경만 다르다: 큰 베기의 예비 동작 진행 0.25, 두 줄 글자 `큰 베기!!` / `받아낼 준비`, 고리, 가운데·중단의 조준, 갓 올린 막기의 내 칼, HUD | 1280×720 |
  | `s-parts` | SVG 바르톨로의 파츠 시트: 여덟 파츠를 떨어뜨려 놓고 관절 점(작은 원)과 이름을 붙인다. 머리는 셋(020의 `smug`·`oops`·`dizzy` 얼굴)으로 둔다(v3, D4. G2와 같은 짜임). 파츠는 `data-sheet-part`다(`data-part`로 세지 않는다) | 1280×720 |
  | `s-states` | SVG 바르톨로의 상태 넷(020 `b-states`의 칸·포즈·글자 그대로) | 1280×720 |
  | `g1-raw` | G1 원본을 그대로(맞춰 줄임). 해시 `--grid`면 50px 격자와 좌표 글자를 얹는다 | 1280×720 |
  | `g1-states` | G1을 잘라 만든 상태 넷. 캡션에 "G1은 얼굴 하나다(표정 바꾸기는 G2에서 본다)" | 1280×720 |
  | `g2-raw` | G2 원본. `--grid`도 같다 | 1280×720 |
  | `g2-states` | G2로 만든 상태 넷. 머리는 상태마다 시트의 셋에서 고른다(대기·찌르기는 거만함, 빈틈은 당황, 무너짐은 어지러움) | 1280×720 |
  | `g-duel` | 생성 바르톨로(G2를 쓸 수 있으면 G2, 아니면 G1)의 큰 베기 예비 동작. 장면은 `stage-*`와 같다. 무대는 승인 B에서 고른 곳의 SVG | 1280×720 |
  | `g-far` | 같은 생성 바르톨로의 멀리·방심(020 `b-far`의 포즈, 모자 없음) | 1280×720 |
  | `g-stage` | 생성 무대 G5 위에 `g-duel`의 장면 | 1280×720 |
  | `s-client-1`, `g-client-1`, `s-client-2`, `g-client-2` | 카운터(020 `b-counter`의 자리와 배경)에 의뢰인. `-1`은 클라라, `-2`는 비토리오(Q3 답). SVG와 생성 | 1280×720 |
  | `palette` | 아래 "palette에 적을 것" | 1280×720 |
  | `s-states-gray`, `g-states-gray` | `s-states`와 `g-duel`에 쓴 생성 쪽 상태 넷의 흑백(`grayscale(1)`) | 1280×720 |
  | `in-front` | 생성에 넣는 바르톨로 대기 자세(모자 씀). 바탕 `#D8D8D8` 한 색, 글자·신호·HUD 없음 | 1024×1536 |
  | `in-parts` | `s-parts`의 배치(머리 셋 포함)에서 이름과 관절 점을 뺀 것. 바탕 `#D8D8D8` | 1536×1024 |
  | `in-client-1`, `in-client-2` | 클라라, 비토리오의 허리 위. 바탕 `#D8D8D8` | 1024×1536 |
  | `in-stage` | 승인 B에서 고른 무대(그 전에는 뒷골목). HUD·상대·신호 없이 1280×720을 1536×864로 키워 가운데에 두고 위아래 80px는 `#D8D8D8` | 1536×1024 |

- **야외 무대 셋** (결정 190, v3에서 D1로 고쳤다). 셋이 같은 것:
  - **조용한 구역 = 신호가 쓰는 곳**. 선과 작은 무늬를 두지 않는다. 큰 톤 덩이(L ≤ 0.20)는 경계가 색의 차이로만 읽히면 들어와도 된다(땅, 먼 벽, 하늘 띠).
    - 교전(크기 0.85)과 밀착(크기 1.1)에서 상대 몸(머리·모자·몸통·팔·손·다리)의 둘레에 여유 20px을 더한다. 상대가 그 간격에서 취하는 포즈 모두(대기, 예비 동작, 타격, 빈틈, 무너짐)를 쓴다.
    - 고리(x 442~838, y 108~504)와 두 줄 글자 상자(x 540~740, y 62~142).
    - 합의 어림은 x 440~840, y 62~670이다. 메인이 020의 포즈 값으로 다시 셈해 `palette`에 적는다.
  - **x 290~990 가운데 조용한 구역 밖**: L ≤ 0.20을 지키는 큰 톤 덩이와 그 형태의 잉크 선을 허용한다(처마·지붕선, 물러나는 벽, 하늘 틈, 상대 발 뒤로 이어지는 땅). 밀착의 빈틈·타격에서 칼끝은 x 약 320까지 나가므로, 이 띠도 짙게 두어 칼의 실루엣이 보이게 한다.
  - **가장자리**(x < 290, x > 990)와 바닥 띠에는 판화 선(해칭, 테두리)과 양피지 톤을 둔다. 바닥은 불규칙한 돌 테두리이고, 가운데로 모이는 선은 쓰지 않는다.
  - **경계가 곧은 세로선으로 읽히지 않게 한다**: 좌우가 비대칭이다(한쪽은 가까운 벽, 다른 쪽은 물러나는 벽이나 트인 곳). 처마·계단·지붕선이 들쭉날쭉하다. x 290·990에 세로선을 긋지 않는다.
  - **HUD를 얹어도 곳이 읽혀야 한다**: 무대가 보이는 곳은 대략 y 64~550이다(근거의 HUD 자리). 곳을 알리는 큰 형태는 이 높이에 둔다(아래 표).
  - **극장으로 읽히는 것은 쓰지 않는다**: 가운데를 감싸는 아치나 틀, 커튼과 주름, 구경꾼(사람), 난간, 무대 조명, 가운데로 모이는 바닥선, 좌우가 거울처럼 같은 날개. 사람과 동물은 셋 모두 없다.
  - HUD 패널(양피지)과 신호는 020 그대로다.
- **곳마다 다른 것**:

  | 곳 | 가장자리 | HUD를 얹어도 곳이 읽히는 큰 형태 (y 64~550, x 290~990에 걸친다) | 조용한 구역의 톤 |
  |---|---|---|---|
  | 뒷골목 | 양옆 집 벽(회벽과 나무 들보, 닫힌 덧창, 불 꺼진 벽등) | 왼쪽 가까운 집이 위층을 내밀어 x 약 440까지 들어오고, 그 밑에 쇠 간판이 걸린다. 오른쪽은 물러나는 집 벽 셋이 원근으로 작아진다(비대칭) | 골목 안쪽의 깊은 그늘, 그 위의 좁은 밤하늘 띠, 돌바닥 |
  | 안뜰 | 왼쪽에 돌우물과 두레박, 화분 | 오른쪽 뒤 벽의 큰 나무 대문 두 짝(쇠 장식. x 840~990에 걸친다). 왼쪽 위로 담 너머 큰 나무의 잎 덩이가 넘어온다(x 290~440) | 그늘진 회벽과 판석 땅의 두 톤 |
  | 광장 | 왼쪽에 분수 가장자리, 오른쪽에 차양을 접은 장터 좌판과 나무 상자 | 해 진 뒤 먼 집들의 지붕선과 종탑 실루엣이 화면을 가로지른다(지금대로) | 하늘과 실루엣의 두 톤(모두 L ≤ 0.20) |

- **SVG 바르톨로**:
  - 020 B의 상대 그대로다: 머리 104, 모자 45, 깃털은 옆으로, 관절 자리와 포즈 상수는 코드 그대로.
  - 파츠마다 **겹침 여유**를 더한다(STYLE_BIBLE 5번): 몸통에 목 밑동(목 위로 약 12)과 팔이 붙는 자리, 팔 윗끝의 둥근 머리(어깨 위로 약 14), 주먹 밑까지 이어진 칼자루, 챙 밑까지 그린 머리 꼭대기. 값은 메인이 정해 `palette`에 적는다.
  - `s-states`의 칸 무대는 승인 B에서 고른 곳이다(그 전에는 뒷골목).
- **SVG 의뢰인**:
  - 020의 `client()`를 바꿔 두 사람을 다리 B로 그린다(머리 모양, 옷, 몸집, 표정): 모자 장인 클라라(`data/commissions/feather_cut.tres`), 대금업자 비토리오(`data/commissions/variants/first_blood_usurer.tres`). 의뢰인은 상대의 머리 크기 제한이 없다.
  - 자리는 020 `b-counter` 그대로다: 의뢰인 (120, 164)·220×390, 카운터 띠 y 540, 사연 패널, 버튼.
  - 사연 패널의 글은 그 의뢰 `.tres`의 `client_name`과 `dialogue` 첫 문장이다.
- **palette에 적을 것**:
  - 다리 B의 팔레트(020 값).
  - 무대 셋의 조용한 구역(다시 셈한 자리)과 그 톤, x 290~990의 다른 톤, 가장자리 색(값, HSV, L).
  - 겹침 여유의 값.
  - 생성 그림을 잰 값(작업 7).
  - **대비 표**: 무대 넷(SVG 셋과 생성 하나)마다 여섯 줄이다. 흰 고리, 노란 조준 테두리, 초록 띠, 예비 동작 셋으로 물든 칠(SVG 몸통과 생성 몸통의 바탕으로). 020 작업 3의 식을 쓴다.
  - 교전 꼭대기의 셈(SVG, G1, G2).
- **완료 확인** (HTML 글에서):
  - Grep `<section id="` → 24건이고 위 표의 id와 같다.
  - 신호색: Grep `--sig-|--sw-`의 줄이 `020-bridge.html`과 같은 값이다. Grep `80%`가 섞는 식에 있다.
  - 바깥 자원: 020 작업 3의 Grep 여덟(`(src|href)\s*=\s*["']?https?:`, `url\(\s*["']?https?:`, `<img`, `<link`, `@import`, `fetch\(`, `data:image`, `reference/`) → 모두 0건.
  - Grep `href=`의 줄을 모두 보고, 값이 `../generated/`, `#`(페이지 안의 조각), SVG·XLink 이름공간뿐인지 본다.
  - 극장의 함수: Grep `spectators|balustrade|folds` → 0건.
  - 무대 셋에서 x 290~990에 쓴 톤(조용한 구역 안과 밖)의 L이 `palette`에서 모두 ≤ 0.20이다.
  - 조용한 구역 안에 선(`stroke`)을 그린 요소가 없다. 무대 함수에서 그 구역에 걸치는 요소를 읽어 확인한다.
  - 신호 구역: `palette`의 바탕·인물 색 가운데 S ≥ 55%이면서 V ≥ 85%인 것이 없다.
- 여기까지를 한 번 굽는다(작업 8의 첫 굽기): SVG 섹션, `in-front`, `in-parts`, `in-client-1`, `in-client-2`.

### 작업 4. Codex 준비 (사용량을 쓰지 않는 것만)

- 돌리는 것:
  - `Get-Command codex -All`.
  - `codex --version`(0.169.0인지).
  - `codex exec --help`. 출력은 scratchpad에 저장해서 읽는다.
  - `codex login status`.
  - `codex features list`.
  - `codex debug models`: `gpt-6.2-sol`과 추론 `high`가 있는지 다시 본다(결정 192).
  - `codex mcp list`를 덮어쓰기 없이 한 번, `-c mcp_servers.node_repl.enabled=false`와 함께 한 번 돌린다(v3, T1). `node_repl`이 꺼져 보이면 MCP 끄기가 걸린 것이다. 이 명령이 없으면 G1의 세션 기록으로 본다.
  - 플러그인 목록을 보는 명령이 있으면, 같은 꼴로 덮어쓰기 없이 한 번, 끄기와 함께 한 번 돌린다(사용량 없음).
  - `Get-FileHash ~/.codex/config.toml`의 처음 값을 적는다(v3, T2).
- 정하는 것(`GENERATION.md` "절차"에 적는다):
  - 옵션의 실제 이름: 저장소 밖에서 돌리기(`--skip-git-repo-check`), 작업 폴더(`-C`/`--cd`), 모델(`-m`), 샌드박스(`-s`), 그림 넣기(`-i`/`--image`의 값 꼴과 여러 장), JSON 이벤트(`--json`), 마지막 답(`-o`/`--output-last-message`), 표준 입력의 프롬프트(`-`).
  - 끄기의 꼴("막는 장치" 3겹째의 후보 셋, 따옴표 없이): `notify`, MCP, 플러그인 열.
  - 기능 목록에 플러그인·앱·컴퓨터 조작을 끄는 기능 이름이 있으면, 그 호출에서만 끄는 옵션(`--disable` 등)이 있는지도 본다.
  - 사용량 없이 효과를 본 끄기와, G1의 세션 기록으로만 볼 수 있는 끄기를 나눠 적는다.
- 로그인이 안 되어 있으면(F1) 생성을 멈추고 사용자에게 `codex login`을 부탁한다. 메인은 로그인하지 않는다. SVG 작업과 작업 8·9는 계속한다.
- 완료 확인: `GENERATION.md` "절차"에 아래가 있다.
  - 버전, 옵션 이름, 로그인 상태.
  - `gpt-6.2-sol`·`high`가 목록에 있는지.
  - `codex mcp list`의 두 결과(또는 "명령 없음").
  - `config.toml`의 해시.

### 작업 5. 시험 한 장 — G1 바르톨로 전신 (승인 A: Q2 답으로 받았다)

- 사용자가 실행 중에 바로 돌려도 된다고 했다(Q2 답). 돌리기 직전에 "시험 1장(실패하면 1장 더)을 돌린다"고 한 줄 알리고, 답을 기다리지 않고 돌린다.
- 넣는 그림: `in-front`를 구운 PNG(1024×1536)의 복사본 하나.
- 프롬프트: 위의 G1 전문을 `docs/style/prompts/021-G1-bartolo-front.txt`에 저장한다. 작업 폴더의 `prompt.txt`는 그 복사본이다.
- "막는 장치"대로 `-m gpt-6.2-sol -c model_reasoning_effort=high`로 한 번 돌린다. 끝나면 적는다:
  - 결과를 찾은 자리(thread_id의 폴더인지), 크기(`System.Drawing`의 `Width`·`Height`), 바이트, 걸린 시간.
  - 토큰(이벤트의 사용량 줄), 그리고 계정 한도 대비 비율이 이벤트나 세션 기록에 있으면 그 값.
  - 세션 기록에서 본 것(5겹째): 모델·추론, 노출된 도구, 부른 도구, 그림 도구에 넘긴 인자, 덮어쓰기마다의 효과.
  - 전후 대조의 결과(`config.toml` 해시 포함).
- **시험의 실패와 할 일**:

  | # | 보이는 것 | 할 일 | 셈 |
  |---|---|---|---|
  | F1 | 로그인이 안 되어 있다 | 작업 4와 같다 | 0 |
  | F2 | 옵션 오류로 바로 끝난다(모르는 옵션, 덮어쓰기 거절) | 도움말로 고치거나 그 덮어쓰기를 빼고 다시 한다 | 세지 않는다 |
  | F3 | 사용량 한도, 요금제, 모델이 그림 도구를 쓸 수 없다는 오류 | 생성을 멈추고 보고한다. 021은 SVG만으로 끝낸다(아래) | 호출 1 |
  | F4 | 에이전트가 글만 내고 그림 도구를 부르지 않는다 | 세션 기록에서 까닭을 본다(도구가 목록에 없는지, 감싸는 도구를 막는다고 읽었는지). **프롬프트만** 고친다: 지시 블록의 첫 두 문장을 더 분명히 쓴다(예: 그림 도구의 이름 `image_gen` 그대로, 감싸는 코드 도구로 한 번 부르라고). 모델·추론은 바꾸지 않는다(결정 192). 시험의 둘째 몫으로 한 번 더. 또 그러면 F3처럼 | 호출 1 |
  | F5 | 그림을 만들었다는데 파일을 못 찾는다 | "결과 찾기"의 넷을 차례로 본다. 못 찾으면 멈추고 보고한다 | 장 1 |
  | F6 | 15분 안에 끝나지 않는다. 또는 샌드박스 설정이나 권한 창을 기다린다는 글이 나온다 | 그 PID의 나무만 끄고 멈춘다. 사용자에게 묻는다. 샌드박스 설정(`codex-windows-sandbox-setup.exe` 등)은 메인이 돌리지 않는다 | 호출 1 |
  | F7 | 호출 뒤 저장소의 `git status`나 `diff --stat`이 달라졌다. 또는 `config.toml`의 해시가 달라졌다. 또는 세션 기록에 그림 도구와 감싸는 도구 밖의 도구를 부른 줄이 있다 | 즉시 멈추고, 달라진 것(파일과 diff, 부른 도구)을 사용자에게 보인다. 메인이 되돌리지 않는다(사용자가 정한다) | 호출 1 |
  | F10 | 세션 기록의 모델·추론이 `gpt-6.2-sol`·`high`가 아니다 | 그 그림은 쓰지 않는다. 멈추고 보고한다(결정 192) | 호출 1 |
  | F8 | 넣은 그림 때문에 실패한다(그림을 읽지 못함 등) | `-i` 없이 시험의 둘째 몫으로 한 번 더 | 호출 1 |
  | F9 | read-only라 그림이 남지 않는다는 글이 나온다 | `-s workspace-write`로 시험의 둘째 몫으로 한 번 더(결정 184) | 호출 1 |

- **SVG만으로 끝내기**(F3, 또는 시험 두 몫이 다 실패):
  - 생성 섹션은 "만들지 않았다(까닭)"로 둔다.
  - 작업 3·8·9는 그대로 한다.
  - 보고서 4번의 "만드는 길"은 SVG와 "사람이 그린다"(020의 마) 가운데서 고르게 된다. 023의 STYLE_BIBLE 13번은 SVG를 쓰는 규칙이 된다.
- **시험이 정하는 것**(`GENERATION.md` "절차"에 적는다. 묶음은 이 절차로 돈다):
  - 결과의 자리(thread_id의 폴더인지).
  - read-only로 되는지.
  - 프롬프트의 크기 말이 듣는지(1024×1536을 청했다. 크기 인자는 없다).
  - 한 번의 장 수.
  - **붙인 그림이 그림 도구에 닿았는지**(v3, T3): 세션 기록에서 그림 도구의 인자 `referenced_image_paths`와 `num_last_images_to_include`를 썼는지 Grep해 적는다. 넘기지 않은 실패와, 넘겼는데 따르지 않은 실패를 가른다.
  - 넘겼다면 자세를 따랐는지. 메인이 `in-front`와 견준다: 칼 팔의 쪽, 칼의 각, 손의 높이, 머리 크기, 깃털의 방향.
  - 걸린 모델·추론, 시간과 토큰.
  - 덮어쓰기마다의 효과(걸림 / 안 걸림 / 확인 못 함).
- 크기를 정할 수 없으면 나온 크기를 받아 쓴다(작업 7에서 맞춰 줄인다). 참조 그림을 넘기지 않았으면 묶음의 지시 블록을 고칠지 승인 B에서 알린다. 넘겼는데 자세를 따르지 않으면 관절은 재어서 맞춘다(위험 5).
- G1에 작업 6의 굳은 확인을 한다.
- 그다음 **승인 B**를 묻는다("장 수와 승인"의 표).
- 완료 확인:
  - `GENERATION.md`의 기록 표에 G1의 줄이 있고, 호출 수가 2 이하다.
  - 전후 대조가 같다(`config.toml`의 해시 포함).
  - 기록 표의 모델·추론 칸이 `gpt-6.2-sol`·`high`이고, 세션 기록에서 확인한 것이다.
  - `docs/style/generated/021-G1-bartolo-front.png`가 있고 `System.Drawing`으로 열린다.

### 작업 6. 묶음 — G2~G5 (승인 B)

- 사용자가 승인한 것만 돌린다. 차례는 G2 → G5 → G3 → G4다(결투 먼저). 승인 B에서도 이 차례로 놓고 물어, 사용자가 끝에서부터 줄일 수 있게 한다.
- 사용자가 무대 셋이 다 극장 같다고 했으면 G5는 돌리지 않는다(승인 B).

  | G | 파일 이름 | 넣는 그림 |
  |---|---|---|
  | G2 | `021-G2-bartolo-parts` | G1 원본(`in-1.png`), `in-parts`(`in-2.png`) |
  | G5 | `021-G5-stage-<곳>` | `in-stage`(승인 B에서 고른 곳으로 다시 구운 것) |
  | G3 | `021-G3-client-clara` | `in-client-1` |
  | G4 | `021-G4-client-vittorio` | `in-client-2` |

- 호출마다 작업 5의 절차(`-m gpt-6.2-sol -c model_reasoning_effort=high`, 전후 대조, 세션 기록)를 따른다. 프롬프트는 `docs/style/prompts/`에 저장한다.
- **굳은 확인**: 걸리면 승인 C의 다시 뽑기 후보다.

  | # | 무엇 | 대상 | 걸리면 |
  |---|---|---|---|
  | H1 | 정면이다(두 눈이 보이고 고개가 곧다). 의뢰인은 살짝 비낀 것도 된다 | G1, G2의 머리, G3, G4 | 다시 뽑기 후보 |
  | H2 | 파츠로 나눌 수 있다. G1: 칼 팔과 몸통 사이에 틈이 있고 칼날이 몸·머리를 가로지르지 않는다. G2: 파츠끼리 닿지 않고, 열(머리 셋 포함) 가운데 빠진 것이 둘 이하이며 머리가 하나 이상이다 | G1, G2 | 다시 뽑기 후보 |
  | H3 | 바탕이 한 색이라 테두리 채우기로 지워지고 인물 안으로 새지 않는다 | G1~G4 | 허용 차를 한 번 바꾼다. 그래도 새면 다시 뽑기 후보 |
  | H4 | 글자·서명·워터마크·테두리가 없다. 인물 그림에는 바닥 그림자도 없다 | 전부 | 다시 뽑기 후보. 작은 것이 가장자리에 있으면 그 자리를 잘라 낸다(손질) |
  | H5 | 신호 구역의 화소가 인물 화소의 1% 이하다. 몸통·다리·팔 칠의 S ≤ 50%(세 점씩의 가운데 값) | G1, G2 | 다시 뽑기 후보 |
  | H6 | 사람·동물이 없고 극장으로 읽히는 것(아치, 커튼, 구경꾼, 난간, 무대 조명, 가운데를 감싸는 틀, 좌우가 거울 같은 날개)이 없다 | G5 | 다시 뽑기 후보 |
  | H7 | 1280×720로 맞춘 뒤 조용한 구역(작업 3에서 다시 셈한 자리)의 L 평균 ≤ 0.20이고 95번째 값 ≤ 0.30이다. 그림 전체에서 신호 구역의 화소가 0.5% 이하다. x 290~990 전체의 L 평균도 자료로 적는다 | G5 | 다시 뽑기 아님. 페이지에서 `brightness()`로 낮추고 그 값을 적는다(손질) |
  | H8 | 상태 색이 큰 면을 덮는다(v3, D2): 몸통·다리·팔마다 칠 세 점과 그림자 톤 세 점(모두 18점)의 Y(sRGB 값의 0.2126R + 0.7152G + 0.0722B)가 모두 0.30 이상이다(선 문턱 위) | G1, G2 | 다시 뽑기 후보 |

- **부드러운 확인**(다시 뽑기의 까닭이 아니다. 보고서에 적는다): 다리 B의 말(선·칠·그림자)에 맞는지, 생성 원래의 머리 크기(맞추기 전), 표정과 성격, G2의 세 얼굴이 같은 사람으로 읽히는지(v3, D4), SVG 쪽과 같은 집안으로 보이는지.
- 완료 확인:
  - 기록 표의 줄 수 = 호출 수.
  - 장과 호출이 모두 상한과 승인한 수 이하다.
  - 프롬프트 파일이 호출마다 있다.
  - 프롬프트 폴더에서 Grep `-i "pizza|potion|tapblaze|niceplay|tinybuild"` → 0건, `[^\x00-\x7F]` → 0건, `"` → 0건.
  - 기록 표의 "넣은 그림" 칸에 `reference`가 0건이다. Grep `reference`가 `docs/style/prompts/`에서 0건이다(v1의 작업 2에서 옮겼다).

### 작업 7. 생성 그림의 손질과 얹기

- **바탕 지우기, 관절 맞추기, 자르기, 상태 색**: "생성 인물을 파츠로 나누는 법"의 1~4대로 한다.
  - 관절과 자르는 다각형, θ0, k, 머리·모자·팔을 맞춘 배율, G2의 상태별 머리는 페이지 스크립트의 표 하나에 둔다.
  - 생성 상대도 `data-part` 여덟 무리로 그리고, 관절 자리는 `transform`으로 결정 12와 같은 값이다. `Hat`(> `Feather`) 무리는 모자를 쓰지 않는 그림에서도 두고 숨긴다(020과 같다).
- **무대 G5**:
  - 가운데 1536×864를 잘라(위아래 80) 1280×720에 맞춘다(`preserveAspectRatio="xMidYMid slice"`).
  - H7을 잰다.
- **재기**: 메인의 C# 토막으로 잰다. 값은 `palette`와 `GENERATION.md`에 적는다.
  - 인물(G1, G2): 몸통·다리·팔·살·모자 칠의 세 점씩의 값과 HSV, 몸통·다리·팔 그림자 톤의 세 점씩과 그 Y(H8), 신호 구역 화소의 비율, 생성 원래의 머리·팔 길이(× k).
  - 무대(G5): 조용한 구역 L의 평균과 95번째 값, x 290~990의 L 평균, 신호 구역 화소의 비율.
  - 대비 표의 생성 줄.
- **물든 칠 확인**: `g1-states`·`g2-states`의 빈틈 칸에서 몸통의 두 점을 잰다. 하나는 칠(선과 그림자 밖), 하나는 그림자 톤이다(v3, D2). 같은 칸 자리의 대기 칸 점을 바탕으로 `lerp(바탕, #4D80F2, 0.8)`와 ±4 안인지 본다(줄여 그리는 동안 화소가 섞여 020의 ±3보다 넓게 둔다).
- 굳은 확인에 걸린 그림이 있고 상한이 남았으면 **승인 C**를 묻는다. 다시 뽑은 그림도 같은 손질을 한다.
- 완료 확인:
  - 생성 섹션마다 그림이 보이거나 "만들지 않았다(까닭)"가 있다.
  - 잰 값과 손질 값(허용 차, `brightness()`, 머리·모자·팔을 맞춘 배율)이 `palette`와 `GENERATION.md`에 있다.
  - `g*-states`·`g-duel`·`g-far`·`g-stage`의 머리 높이가 104(±5%), 팔(어깨~손목)이 105(±15% 안이거나 맞춘 것)다.
  - 물든 칠 확인의 결과(G1·G2마다 칠 한 점과 그림자 한 점)가 있다.

### 작업 8. 굽기와 눈 확인

- **굽는 법은 020 작업 4의 명령 그대로다**:
  - 버전 폴더의 `msedge.exe`를 쓰고, 따로 된 `--user-data-dir`로 한 장씩 띄워 끝을 기다린다.
  - 60초를 넘기면 그 PID 나무와 우리 프로필의 프로세스만 끈다. 이름으로 끄지 않는다.
  - 1280×720인지 `System.Drawing`으로 본다.
  - 다른 점 둘:
    - `in-*`는 그 크기의 `--window-size`로 굽는다(1024,1536 또는 1536,1024).
    - 생성 그림을 쓰는 섹션은 구운 뒤 그림이 빠졌는지 본다. 빠졌으면 `--virtual-time-budget=10000`을 더해 한 번 더 굽는다. 그래도 빠지면 실패 목록에 적는다(사용자는 브라우저로 본다).
- **굽는 때**(필요할 때마다 한 장씩):
  1. 작업 3 뒤: SVG 섹션과 `in-front`·`in-parts`·`in-client-*`.
  2. 승인 B 뒤: `in-stage`(고른 곳), `s-states`.
  3. 작업 7 중: `g1-raw--grid`, `g2-raw--grid`.
  4. 작업 7 뒤: **24 섹션 모두를 한 번 더**(최종본).
- **그린 뒤의 문서**(`--dump-dom`, 020과 같은 꼴)에서 센다:
  - 섹션 24.
  - `data-part`의 여덟 값(`Legs`·`Torso`·`Head`·`Hat`·`Feather`·`Arm`·`Hand`·`Sword`)이 각각 **SVG 12 + 생성 n**이다.
    - SVG 12 = `stage-*` 3 + `s-states` 4 + `s-states-gray` 4 + `in-front` 1.
    - 생성 n = `g1-states` 4 + `g2-states` 4 + `g-duel` 1 + `g-far` 1 + `g-stage` 1 + `g-states-gray` 4 가운데 그린 것이다. 다 그리면 15, 합 27이다.
    - 페이지 스크립트 안의 틀이 따로 걸리면 그 수를 빼고 적는다(020에서 1건).
  - `data-sheet-part`: `s-parts`와 `in-parts` 둘에 머리가 셋씩이라 `Head`는 6이고, 나머지 일곱 값(`Legs`·`Torso`·`Hat`·`Feather`·`Arm`·`Hand`·`Sword`)은 각각 2다(v3, D4).
  - `--dump-dom`이 빈 파일을 내면 020처럼 그리는 함수를 따라가 세고, 그렇게 적는다.
- **눈으로 볼 것**. 메인의 눈은 참고이고 고르는 것은 사용자다. 어긋난 것은 고쳐 다시 굽는다.

  | # | 볼 것 | 섹션 |
  |---|---|---|
  | 1 | 극장으로 읽히는 것이 없다. "가운데 짙은 판 + 양옆 날개"로 읽히지 않는다(경계가 곧은 세로선이 아니고 좌우가 다르다). **HUD를 얹은 채로 야외의 어느 곳인지 읽힌다**(v3, D1). 셋이 옆 소품만이 아니라 큰 형태로 서로 갈린다. 조용한 구역이 짙고, 상대와 신호(주황 칠, 두 줄 글자, 고리·띠·가운데 점, 조준 테두리)가 또렷하다 | `stage-*` |
  | 2 | 상대 전체(모자·깃털 포함)가 화면 안이고 두 줄 글자 상자와 겹치지 않는다 | `stage-*`, `g-duel`, `g-stage` |
  | 3 | 생성 상대의 큰 베기 예비 동작: 칠이 물들고 선이 남는다. 고리·조준 테두리가 생성 그림 위에서도 보인다 | `g-duel` |
  | 4 | 상태 넷이 칠 색으로 갈린다. 몸통·다리·팔의 그림자까지 물들어 얼룩이 없다(v3, D2). 빈틈 칸의 머리는 물들지 않았다. 상태마다 얼굴이 바뀐다(G1은 하나뿐이라는 캡션이 있다). 팔이 옮겨 간 자리의 구멍·유령, 관절의 틈, 칼자루의 구멍을 적는다 | `s-states`, `g1-states`, `g2-states` |
  | 5 | 흑백에서도 넷이 자세로 갈린다 | `*-states-gray` |
  | 6 | 멀리(0.55)에서 얼굴과 내려간 칼끝이 보인다. 생성 그림의 가장 가는 선이 화면에서 몇 px인지 적는다(022의 크기 기준 자료) | `g-far` |
  | 7 | 생성 무대: 극장으로 읽히지 않고, HUD를 얹은 채로 곳이 읽히고, 조용한 구역이 어둡고, 상대가 떠 보이지 않고 또렷하다 | `g-stage` |
  | 8 | 의뢰인이 카운터에 붙어 보인다. 성격이 표정과 옷으로 읽힌다. SVG와 생성의 차이 | `s-client-*`, `g-client-*` |
  | 9 | 생성 그림이 다리 B의 말(굵기가 변하는 고동 잉크 선, 바랜 평평한 칠, 그림자 한 단계)에 맞는지, SVG 쪽과 같은 집안으로 보이는지 | 전부 |

- 완료 확인:
  - 최종본 24장. 실패한 장이 있으면 그 목록과 까닭이 보고서 2번에 있다.
  - `--dump-dom`의 수와 위 표의 결과가 보고서 2번에 있다.
  - 굽기를 마친 뒤 명령줄에 우리 프로필이 든 `msedge.exe`가 0개다.

### 작업 9. 기록과 보고

- **`docs/DECISIONS.md`**: "2026-11-21 — 계획 021" 절.
  - 근거: 020 절 끝의 "사용자 답"을 가리킨다.
  - 결정 183~192를 한 줄씩 적는다(아래 "설계 결정").
  - 실행 중에 정한 것: 덮어쓰기마다의 효과, 바꾼 프롬프트 줄, 손질 값(머리·모자·팔의 배율 포함), 장과 호출의 수, 걸린 모델·추론, 승인 B·C의 답, 겹침 여유의 값, 조용한 구역의 자리.
  - 메인이 검토 중에 적은 사용자 지시 한 줄(모델·추론, 작업 0에서 diff를 적어 둔 것)은 그대로 두고, 021 절에서는 그 줄을 가리키기만 한다.
- **`CLAUDE.md`** (7장은 작업 0에서 고쳤다):
  - 8장 폴더 구조의 `docs/` 줄 `style/ (samples/, REFERENCES.md, 로컬만인 reference/)`에 `prompts/`, `GENERATION.md`, 로컬만인 `generated/`를 더한다.
  - 9장 현재 위치의 "계획 020(화풍의 다리 견본)까지 실행했다. 3단계는 020~022로 나눈다(결정 176)."를 "계획 021(세부 견본과 그림 생성 시험)까지 실행했다. 3단계는 020~023으로 나눈다(결정 183)."로 바꾼다. 나머지 문장은 그대로다.
  - 완료 확인: `git diff -- CLAUDE.md`에서 이 계획이 바꾼 줄이 7장 둘, 8장 하나, 9장 하나뿐이다.
- **`docs/style/GENERATION.md`**를 마무리한다: 절차, 틀(시험 뒤 고친 것), 기록 표.
- **`docs/reports/021-style-detail-and-generation.md`**와 사용자 보고(CLAUDE.md 10장 형식):
  1. 한 일과 바꾼 파일.
  2. 확인한 것: 작업 1~8의 완료 확인, 잰 값, 눈으로 본 표, 장과 호출의 수, 전후 대조.
     확인 못 한 것:
     - `.gdignore`가 듣는지. `docs/style/` 아래의 첫 PNG(작업 5의 G1)가 들어왔지만 Godot을 돌리지 않았다. Glob `docs/style/**/*.import`가 0인 것은 증명이 아니다.
     - Windows에서 Codex의 샌드박스가 실제로 막는지.
     - `notify` 끄기의 효과(볼 길이 없다).
     - 밝기 문턱 필터가 Godot 셰이더로 같게 되는지(4단계).
     - 다른 브라우저에서의 모습.
  3. 설계와 다른 것:
     - 3단계를 넷으로 나눴다(결정 183).
     - 상태 색을 래스터의 밝기 문턱으로 칠에만 입혔다(지금 코드는 파츠 전체의 색을 바꾼다).
     - 그림 생성은 사용자 지시대로 `gpt-6.2-sol`·`high`로 돌렸다(사용자 설정의 모델 `gpt-6.2-astra`와 다르다. 설정 파일은 그대로다).
     - 생성 그림의 머리·모자·팔을 사용자가 고른 비례(머리 104, 팔 105)에 맞춰 키우거나 줄였다. 원래의 비는 `GENERATION.md`에 있다.
     - 그 밖에 손질한 것.
  4. 사용자 결정: 아래 "보고서 4번의 물음"과 "사용자 결정 필요".
  5. 다음: 답을 받아 계획 022.
- **보고서 4번의 물음**:
  1. **무대**: 뒷골목 / 안뜰 / 광장. 그리고 SVG / 생성(G5).
  2. **바르톨로의 기준**: SVG / 생성 전신을 자른 것(G1) / 생성 파츠 시트(G2).
  3. **의뢰인의 기준**: 사람마다 SVG / 생성.
  4. **4단계에서 그림을 만드는 길**: 가 생성 + 파츠 시트 + 손질 / 나 메인이 SVG로 / 다 섞기(예: 의뢰인·무대는 생성, 상대는 SVG) / 라 사람이 그린다. 물음 옆에 적는다: 생성 길의 표정 바꾸기는 G2의 머리 셋으로만 봤다(G1은 얼굴 하나다). G2가 머리 셋을 그리지 못했으면 "생성 길의 표정 바꾸기는 시험하지 못했다"고 적는다(v3, D4). 생성 그림은 머리·팔을 맞춘 뒤 견준 것이다.
  5. **싫은 것**이 있으면 한 줄로.
  6. 고른 그림을 `docs/style/basis/`로 올리는 것(022의 첫 작업).
- **`docs/HANDOFF.md`**를 지금 상태로 고친다:
  - 1번: 021의 답을 기다린다. 다음은 022. 생성 절차는 `docs/style/GENERATION.md`를 본다.
  - 새 줄: 생성 그림(`docs/style/generated/`)은 로컬에만 있다. 다른 컴퓨터에서 이어 받으면 사용자가 따로 옮긴다.
  - 2번: 020이 적은 "`.gdignore`는 021에서 참고 그림이 처음 들어온 뒤…" 줄을 고친다. 참고 그림은 들어오지 않았고 첫 PNG는 생성 그림(`docs/style/generated/`)이다. 확인은 그 뒤 Godot이 처음 돌 때(playtester 또는 사용자의 `play.ps1`)이고, `docs/style/**/*.import` 0건과 `.godot/imported/`에 `021-`로 시작하는 이름 0건으로 본다.
  - 3번: 021 보고서 4번의 항목 한 줄.
- `docs/BACKLOG.md`는 건드리지 않는다. 021은 게임 코드의 고칠 거리를 새로 만들지 않는다.
- playtester에게 맡길 확인: 없다(게임이 바뀌지 않는다). `.gdignore`의 확인은 "사용자 결정 필요" 5다.
- 완료 확인:
  - 보고서 파일이 있고, 2번에 "확인 못 한 것"이 있다.
  - `CLAUDE.md`·`DECISIONS.md`·`HANDOFF.md`에서 이 계획이 바꾼 줄이 위에 적은 것뿐이다. `DECISIONS.md`는 작업 0에서 적어 둔 메인의 한 줄을 따로 센다.
  - `config.toml`의 해시가 작업 4에서 적은 처음 값과 같다.
  - 끝의 `git status --short`에 새로 바뀐 것이 작업 0·1·3·9에 적은 파일과 `docs/style/` 아래의 올리는 파일뿐이다(작업 2는 하지 않아 `REFERENCES.md`는 그대로다). `docs/style/generated/`는 보이지 않는다.

## `docs/STYLE_BIBLE.md` 목차의 바뀐 칸 (020의 표에서. 쓰는 것은 023)

| # | 항목 | 021이 정하거나 모으는 것 | 정하는 계획 (020 → 021) |
|---|---|---|---|
| 2 | 기준 이미지 | 후보와 사용자의 선택(보고서 4번) | 021 → 021(고름) · 022(올림) |
| 4 | 인물 | 다리 B의 말, 상대 머리 104, 의뢰인 둘의 꼴 | 020·021 → 그대로 |
| 5 | 파츠 분리 | 겹침 여유의 값, 생성 그림을 나누는 두 길의 결과, 칠 층의 밝기 문턱 | 020·021 → 그대로 |
| 6 | 배경·UI | 야외 무대 셋과 극장 금지의 목록 | 020·021 → 021(배경) · 022(UI) |
| 8 | 색 | 생성 그림을 잰 값 | 021(확정) → 022(확정) |
| 9 | 글꼴 | — | 021 → 022 |
| 10 | 1280×720 크기 기준 | 멀리에서 생성 그림의 가장 가는 선(작업 8의 6) | 021 → 022 |
| 13 | 만드는 길 | Codex 절차, 모델·추론(`gpt-6.2-sol`·`high`), 막는 장치와 그 확인(세션 기록, 해시), 장 수와 승인, 프롬프트의 틀, 파츠로 나누는 법과 비례 맞추기(`GENERATION.md`) | 021 → 그대로 |
| 14 | `MANIFEST.md`의 꼴 | — | 022 → 023 |
| 1·3·7·11·12·15 | | — | 022 → 023 |

## 설계 결정

번호는 183부터다. 185의 상한·시험 승인과 191은 사용자 답이고(Q2·Q3), 192는 사용자 지시다. 나머지는 planner가 위임으로 정했고 모두 임시다.

| # | 결정 | 이유 | 되돌리기 |
|---|---|---|---|
| 183 | 3단계를 넷으로 다시 나눈다: 020 다리(끝), 021 무대·상대·의뢰인의 기준 이미지와 만드는 길, 022 고른 그림 올리기·팔레트 확정·글꼴·UI·크기 기준, 023 STYLE_BIBLE·MANIFEST의 꼴. STYLE_BIBLE은 021과 합치지 않는다 | 021에 생성 시험과 실행 중 승인 둘이 들어가 이미 크다. 글꼴·UI는 생성과 상관없고, 글꼴 파일을 받을지와 라이선스라는 따로 된 물음이 있다. 팔레트 확정과 STYLE_BIBLE은 021에서 고른 그림을 입력으로 쓴다 | 쉬움. 022·023을 합치거나 글꼴·UI를 021로 되돌린다 |
| 184 | 생성은 `codex exec`를 저장소 밖의 빈 작업 폴더에서 `-s read-only`로 돌린다. 에이전트에게는 그림 도구를 한 번 부르게 하고(감싸는 코드 도구만 허용), 셸·파일·다른 도구를 금한다. 이 호출에만 따옴표 없는 `-c`로 `notify`, MCP `node_repl`, 켜진 플러그인 열 전부를 끈다. 끄기가 걸렸는지는 `codex mcp list`와 세션 기록으로 보고, 오류가 없었다는 것만으로는 치지 않는다. 결과는 thread_id의 폴더에서 메인이 복사한다. 호출마다 git·`config.toml` 해시·작업 폴더를 대조하고, 이름으로 끄지 않는다. 사용자의 Codex 설정·로그인·샌드박스는 바꾸지 않는다 | 사용자의 설정에는 컴퓨터 조작·브라우저·앱 플러그인과 데스크톱 앱을 부르는 `notify`가 켜져 있다. Windows 샌드박스가 무엇을 막는지 확인할 수 없고, `-c`는 틀린 키를 조용히 버린다(v3, T1). 겹을 쌓고, 겹마다 걸렸는지를 본다 | 쉬움. 옵션만 바뀐다 |
| 185 | 장과 호출 모두 상한 8(Q2 답 "가"). 승인 지점은 셋이다: 시험(실행 전에 받았다. 돌리기 직전에 한 줄 알린다), 묶음(시험 뒤), 다시 뽑기(굳은 확인에 걸린 것만, 합 2) | 사용자가 장 수를 먼저 알기로 했다. 묶음의 크기는 시험의 결과(쓸 만한지, 비용)를 보고 정하는 것이 아끼는 길이다 | 쉬움 |
| 186 | `-i`에 넣는 것은 우리 그림뿐이다: 021 견본을 구운 PNG와 021에서 생성한 그림. 참고 스크린샷은 넣지 않는다. 작업 폴더에는 넣을 그림의 복사본만 둔다 | 결정 179의 3이 막는 것은 참고 이미지다. 우리 견본을 넣으면 정면·관절 자리·머리 크기를 생성 그림에 옮길 수 있다 | 쉬움. 넣지 않으면 관절은 재어서 맞춘다 |
| 187 | 프롬프트는 영어·ASCII·큰따옴표 없이, 블록 일곱(지시·그림·주제·구도와 자세·화풍·색·바탕)으로 쓴다. 이름은 쓰지 않는다. 인물은 파츠로 나눌 수 있는 정면과 한 색 바탕, 무대는 어둡고 조용한 가운데와 극장 금지를 적는다 | 신호를 얹을 수 있는 꼴(원칙 4, 결정 181)과 자르기 쉬운 꼴을 말로 고정한다. ASCII는 PowerShell의 표준 입력에서 깨지지 않는다 | 쉬움 |
| 188 | 생성 인물을 파츠로 나누는 두 길(전신 자르기 G1, 파츠 시트 G2)을 같은 사람으로 견준다. 바탕은 테두리 채우기로 지우고, 크기는 목~골반 = 200으로 맞춘다. 머리는 104(±5%)로, 팔(어깨~손목)은 ±15%를 넘으면 105로 맞춘다. 모자가 상자를 넘으면 모자만 줄인다. G2는 머리를 표정 셋으로 그리게 해 상태마다 바꾼다. 상태 색은 밝기 문턱으로 선을 가린 뒤 칠에만 80% 섞고, 큰 면의 칠과 그림자 톤이 모두 문턱 위인지 H8로 본다 | 4단계의 Skeleton2D 컷아웃에 맞는 길을 한 번에 견준다. 사용자가 고른 비례와 표정이 바뀌는 조건을 SVG와 같게 두어, 만드는 길을 화풍으로 고르게 한다(v3, D2·D3·D4·T4). 밝기 문턱은 래스터 그림에서 결정 181(선은 그대로)을 지키는 가장 단순한 길이다 | 쉬움. 견본의 방법이다. 게임 코드는 그대로다 |
| 189 | 생성 그림(원본·손질본·넣은 그림)은 `docs/style/generated/`에 로컬로만 둔다. 저장소에는 프롬프트, `GENERATION.md`, 견본 HTML을 올린다. 고른 그림만 022에서 `docs/style/basis/`로 올린다 | 고르지 않은 시험 그림을 저장소 역사에 영영 남기지 않는다(장마다 수 MB). 프롬프트와 기록이 있으면 절차를 되풀이할 수 있다 | 쉬움. `.gitignore`의 한 줄 |
| 190 | 야외 무대 셋(뒷골목·안뜰·광장)을 SVG로, 020 `b-duel`과 같은 장면에 배경만 바꿔 그린다. 선 없는 조용한 구역은 신호가 쓰는 곳(교전·밀착 상대의 둘레, 고리, 두 줄 글자)이다. x 290~990의 나머지에는 L ≤ 0.20의 큰 톤 덩이와 그 형태를 허용한다. 경계는 곧은 세로선이 아니고 좌우가 다르다. 곳마다 HUD를 얹어도 읽히는 큰 형태를 하나씩 둔다. 극장으로 읽히는 것(아치·틀, 커튼, 구경꾼, 난간, 무대 조명, 모이는 바닥선, 거울 같은 날개)은 쓰지 않는다. 생성 무대는 승인 B에서 사용자가 고른 하나이고, 셋 다 극장 같다고 하면 돌리지 않는다 | 사용자의 "극장 같다"를 020의 무엇이 일으켰는지 목록으로 막는다. v2의 가운데 x 290~990은 020 아치의 발자국과 같아 "가운데 판 + 양옆 날개"를 남길 수 있었다(v3, D1). 결정 182의 기준은 "상대 둘레"다. 무대를 생성 하나로 줄여 사용량을 아낀다 | 쉬움 |
| 191 | 의뢰인 둘은 모자 장인 클라라와 대금업자 비토리오다(Q3 답 "가") | 사용자가 정했다. 옷·몸집·표정이 크게 갈리고 020의 에밀리오와 겹치지 않는다 | 쉬움 |
| 192 | 그림을 만드는 모든 Codex 호출은 `-m gpt-6.2-sol`과 `-c model_reasoning_effort=high`로만 한다. 사용자의 `config.toml`은 바꾸지 않고 호출마다 명시한다. 걸린 값은 세션 기록의 `turn_context`로 확인하고, 다르면 그 그림은 쓰지 않는다. CLAUDE.md 7장에 둔다(작업 0) | 사용자 지시(2026-11-21, 근거의 원문). v2의 "추론 `low`로 아낀다"를 대신한다 | 사용자가 바꾼다 |

## 위험

1. **Codex의 절차를 모른다.** `gpt-6.2-sol`이 그림 도구를 쓰는지도 시험에서 처음 본다(같은 계열 `gpt-6.1-sol`은 썼다). 대비: 시험 한 장, 실패 표(F1~F10), 결과 찾기의 차례(thread_id 먼저). 같은 버전의 세션 기록으로 그림 도구의 꼴과 자리를 미리 알았다. 시험이 끝내 안 되면 SVG만으로 끝낸다(작업 5).
2. **Codex가 사용자의 저장소·데스크톱·브라우저를 건드린다.** 사용자의 설정에 컴퓨터 조작·브라우저·앱 플러그인 열, MCP `node_repl`, 데스크톱 앱을 부르는 `notify`가 있다. Windows 샌드박스가 무엇을 막는지는 모르고, `-c`는 틀린 키를 조용히 버린다. 대비: "막는 장치"의 다섯 겹, 끄기의 효과를 `codex mcp list`와 세션 기록으로 확인, 효과 없는 끄기는 승인 B에서 사용자가 정함, F6·F7에서 멈춤, 이름으로 끄지 않기.
3. **사용량.** 한 장이 얼마를 쓰는지 모른다. 추론 `high`는 사용자 지시라 낮추지 않는다(결정 192). 같은 계열 `medium` 한 장의 기록이 토큰 46,264였으니 `high`는 더 든다고 본다(그림 값은 토큰에 들지 않는다). 대비: 상한, 승인 셋, 한 호출에 한 장, 토큰과 한도 비율의 기록, 승인 B에서 가늠할 꼴로 알리기, 묶음은 끝에서부터 줄일 수 있게 묻기. 무대는 하나만 생성하고, 다시 뽑기는 굳은 확인에 걸린 것만 한다.
4. **생성이 조건을 어긴다**(옆을 봄, 팔이 몸에 붙음, 바탕에 배경, 글자, 맑은 색, 어두운 그림자). 대비: 블록의 까닭이 있는 줄들, 굳은 확인 H1~H8, 다시 뽑기의 한도, 손질(자르기, `brightness()`, 머리·모자·팔 맞추기).
5. **붙인 그림이 그림 도구에 닿지 않거나, 닿아도 자세를 따르지 않을 수 있다.** 그림 도구는 `referenced_image_paths`로 받은 그림만 본다. 대비: 지시 블록에서 경로로 넘기게 하고, 세션 기록으로 넘겼는지 가른다(작업 5). 따르지 않으면 관절을 재어서 맞추고 머리·팔을 비례에 맞춘다. 그래도 파츠가 겹치면 그 결과가 "생성 + 자르기는 어렵다"는 자료가 된다.
6. **자른 파츠의 구멍·유령, 관절의 틈.** 대비: 두 길(G1·G2)을 견주고, 상태 넷에서 팔이 옮겨 간 모습을 본다(작업 8의 4). 결과가 보고서 4번의 "만드는 길"의 자료다.
7. **밝기 문턱이 어두운 칠(머리카락, 구두)을 선으로 읽는다.** 그 부분은 물들지 않는다. 대비: 결과로 적는다. 4단계에서는 선 가림을 따로 그린 그림으로 두는 길이 있다.
8. **생성 그림이 두 게임을 닮아 보일 수 있다.** 대비: 이름과 참고 그림을 넣지 않았다(Grep으로 확인). 닮았는지는 사용자가 보고 판단한다(물음 5).
9. **저장소가 커진다.** 대비: 생성 그림은 로컬만, 고른 것만 올린다(결정 189).
10. **`.gdignore`를 이번에도 증명하지 못한다.** 참고 그림은 이번에도 들어오지 않고(Q1 답), 처음으로 PNG(생성 그림)가 `docs/style/generated/`에 들어온다. 대비: 안 들으면 Godot이 그 PNG를 가져와 `.import`가 생기는 정도다(게임은 그대로다). 확인은 "사용자 결정 필요" 5다.
11. **굽기가 그림을 다 읽기 전에 찍힐 수 있다.** 대비: 생성 섹션마다 Read로 보고 `--virtual-time-budget`로 다시 굽는다(작업 8).
12. **실행 중에 사용자를 기다린다**(승인 B·C). 대비: SVG 작업을 먼저 끝내고 기다린다. 기다리는 동안 `HANDOFF.md`를 그 자리로 적는다.
13. **계획이 크다**(섹션 24, 호출 최대 8, 손질). 대비: 결투 먼저, 의뢰인은 뒤. 다 못 하면 의뢰인 섹션을 빈 채로 보고한다. 글꼴·UI는 022로 뺐다.

## 실행 전에 물을 것

**답을 받았다(2026-11-21). 남은 물음은 없다.**

- **Q1 답: 나**(이번에도 없이). 작업 2는 하지 않는다. `docs/style/` 아래의 첫 PNG는 생성 그림이고, `.gdignore`의 확인은 그 뒤로 옮겼다(작업 9, "사용자 결정 필요" 5).
- **Q2 답: 가(8장)**. 시험 한 장(실패하면 한 번 더, 호출 최대 2)은 실행 중 바로 돌려도 된다(승인 A). 묶음·다시 뽑기는 실행 중에 승인을 받는다. v1이 물은 "추론 `low`"는 검토 중의 사용자 지시로 없어졌다(그림 생성은 `gpt-6.2-sol`·`high`로만. 결정 192).
- **Q3 답: 가(클라라·비토리오)**.

아래는 v1에서 물은 글의 기록이다.

**Q1. 참고 스크린샷을 이번에 주시겠어요?** (020 때 "021에서 준다"고 하셨습니다)
- 가. 실행 전에 준다 **(권함)**:
  - 「좋은 피자, 위대한 피자」의 손님 2~3장, 「Potion Craft」의 가게·UI 2~3장이면 충분합니다.
  - `docs/style/reference/`에 넣고(저장소에 올라가지 않습니다) 파일마다 한 줄 메모를 알려 주세요.
  - 메인이 읽고 색인에 성질을 말로 적습니다. 그 말이 SVG와 프롬프트의 화풍에 들어갑니다. 그림 자체는 생성에 넣지 않습니다.
- 나. 이번에도 없이 — 021은 말로 받은 방향과 020의 답(B)만 따릅니다. 색인은 비워 둡니다.
- 다. 주지 않는다 — 색인을 "받지 않기로 했다"로 닫습니다.
- 답에 따라: 가면 작업 2를 하고 프롬프트의 화풍 블록에 색인의 말이 더해집니다. 나·다면 작업 2를 하지 않습니다.

**Q2. 그림 생성의 장 수 상한과 시험 한 장**

Codex 호출은 사용자의 ChatGPT 계정 사용량을 씁니다. 한 장이 얼마를 쓰는지는 시험에서 토큰으로 알려 드립니다.
- 가. **8장 (권함)**: 시험 1(실패하면 한 번 더) + 묶음 4(바르톨로 파츠 시트, 의뢰인 둘, 무대 하나) + 다시 뽑기 2(조건에 걸린 그림만).
- 나. 4장: 시험 1(+1) + 바르톨로 파츠 시트 + 무대 하나. 의뢰인은 SVG만입니다.
- 다. 12장: 가에 무대 둘(야외 셋 모두 생성)과 의뢰인마다 한 장씩 더해, 갈래를 놓고 고르실 수 있습니다.
- 그리고: **시험 한 장(실패하면 한 번 더, 호출 최대 2번)을 실행 중에 바로 돌려도 될까요?** 예 / 시험 전에 다시 물어 달라.
- 묶음과 다시 뽑기는 어느 쪽이든 실행 중에 장 수를 알리고 승인을 받습니다.
- Codex를 돌릴 때만 추론을 `low`로 낮춥니다(설정은 `high`). 사용량을 아끼려는 것입니다. 그대로 쓰기를 원하시면 말씀해 주세요. (v3: 이 줄은 사용자 지시로 없어졌다. 결정 192)
- 답에 따라: 작업 6의 묶음과 생성 섹션의 수가 달라집니다. "아니오(생성하지 않는다)"면 021은 SVG만으로 끝납니다.

**Q3. 의뢰인 둘을 누구로 할까요?**

데이터의 일곱: 포목상 에밀리오(020에서 그렸다), 모자 장인 클라라, 바르톨로의 누이 이네스, 품팔이 토마소, 무용 교사 오르솔라, 노름꾼 가스파로, 대금업자 비토리오.
- 가. **클라라·비토리오 (권함)**: 여자 장인과 넉넉한 대금업자입니다. 옷·몸집·표정이 크게 갈려 "표정으로 읽히는 성격"을 보기 좋고, 020의 에밀리오와 겹치지 않습니다.
- 나. 토마소·비토리오: 가난과 넉넉함이 옷차림으로 읽히는지 봅니다(평판의 가난한 손님과 궂은일).
- 다. 이네스·오르솔라: 여자 둘입니다. 이네스로 바르톨로와 닮은 집안 얼굴을 시험합니다.
- 라. 다른 둘(이름을 알려 주세요).
- 답에 따라: 작업 3의 SVG 의뢰인과 G3·G4의 주제가 달라집니다.

## 사용자 결정 필요 (실행을 막지 않는다. 보고서 4번에 올린다)

| # | 무엇 | 이 계획이 정한 것 | 답이 다르면 |
|---|---|---|---|
| 1 | **기준 이미지와 만드는 길** | 실행 뒤 보고서 4번의 물음 여섯 | 022의 입력(올릴 그림, 팔레트를 뽑을 그림)과 023의 STYLE_BIBLE 13번(생성 규칙 / SVG 규칙)이 그 답을 따른다 |
| 2 | 3단계를 넷으로 나눈 것 | 020~023(결정 183) | 셋으로 되돌리려면 022·023을 합친다. 글꼴·UI를 021에 원하시면 021에 작업을 더한다(검토를 다시 받는다) |
| 3 | 생성 그림을 로컬에만 두고 고른 것만 올리는 것 | 결정 189 | 다 올리기를 원하시면 `.gitignore`의 한 줄을 지운다(수십 MB가 역사에 남는다) |
| 4 | Codex를 돌릴 때만 끄는 것 | `notify`, MCP `node_repl`, 켜진 플러그인 열 전부를 끈다(결정 184). 모델·추론은 사용자 지시대로 `gpt-6.2-sol`·`high`다(결정 192) | 끄기를 빼기를 원하시면 뺀다(플러그인이 켜진 채 돌아, 에이전트가 브라우저·컴퓨터 조작 도구를 볼 수 있다) |
| 5 | `.gdignore`의 확인을 playtester에게 맡길지 | 정하지 않는다(메인은 Godot을 돌리지 않는다). 참고 그림이 이번에도 없어(Q1 답), 확인할 때는 생성 그림(작업 5의 G1부터)이 `docs/style/generated/`에 들어온 뒤다 | 맡기시면 021 실행 뒤 playtester가 `tests/run_tests.ps1`을 한 번 돌리고 `docs/style/**/*.import` 0건, `.godot/imported/`에 `021-`로 시작하는 이름 0건, 가져오기의 `ERROR:` 줄 0건을 본다. 맡기지 않으면 다음에 Godot이 돌 때(playtester나 사용자의 `play.ps1`)까지 미룬다(`HANDOFF.md` 2번) |
| 6 | 021의 커밋 | 정하지 않는다(사용자가 지시한다) | — |

보류 중인 것(그대로 둔다): 2단계의 값과 결정(`docs/HANDOFF.md` 3번), `docs/BACKLOG.md`의 항목, `docs/plans/013-playtester.md`의 번호 겹침.

## 수정 기록

v1 → v2 (검토 전. "실행 전에 물을 것"의 답을 반영했다. 검토 횟수에 들지 않는다). 플레이 규칙·작업 내용·완료 기준은 그대로다. 아래는 답 때문에 사실이 달라진 곳뿐이다.

- 근거: Q1 "나", Q2 "가"와 시험 승인, Q3 "가"(클라라·비토리오와 그 `.tres`)를 적었다. 020이 넘긴 것의 줄에서 "색인"을 빼고, `.gdignore`의 첫 PNG가 생성 그림이 된다고 적었다.
- 3단계 표(021 줄)와 범위 밖: "참고 색인(받으면)"을 빼고 범위 밖에 "참고 색인 채우기"를 넣었다.
- 장 수와 승인: 상한 8을 Q2 답으로 적었다. 승인 A는 "실행 전에 받았다, 돌리기 직전에 한 줄 알린다(답은 기다리지 않는다)"로 바꿨다. 고르지 않은 안(4, 12)의 셈은 지우고 기록을 가리킨다.
- 프롬프트의 틀: "Q1이 가면 색인의 말을 더한다"를 "색인 없이, 말로 받은 방향과 B에서만"으로 바꿨다. G3·G4의 주제를 클라라·비토리오로 적었다.
- 저장: `docs/style/` 아래의 첫 PNG는 작업 5의 G1이라고 적었다.
- 작업 0: 참고 그림의 Glob은 0이어야 하고, 있으면 읽지 않고 보고한다.
- 작업 2: "하지 않는다"로 바꿨다(번호는 남긴다). v1의 확인 "Grep `reference`가 `docs/style/prompts/`에서 0건"은 참고 그림과 상관없는 선이라 작업 6의 완료 확인으로 옮겼다(확인의 내용은 같다).
- 작업 3: `s-client-*`·`in-client-*`·SVG 의뢰인을 클라라(`-1`)·비토리오(`-2`)와 그 `.tres`로 적었다.
- 작업 5: 승인 A의 조건부 줄("다시 물어 달라고 했으면")을 바로 돌린다는 줄로 바꿨다.
- 작업 6: G3·G4의 파일 이름을 `021-G3-client-clara`·`021-G4-client-vittorio`로 정했다.
- 작업 9: 보고서 2번의 `.gdignore` 줄, `HANDOFF.md` 2번(020이 적은 "참고 그림이 처음 들어온 뒤"를 "생성 그림이 들어온 뒤"로 고친다), 끝의 `git status` 대조(작업 2의 파일이 없다)를 맞췄다.
- 설계 결정 185·191, 위험 10, 사용자 결정 필요 5: 답에 맞췄다. 5번은 맡기지 않으면 다음 Godot 실행까지 미룬다고 적었다.
- 실행 전에 물을 것: 답을 받았다고 적고 v1의 물음은 기록으로 남겼다.

v2 → v3 (1회차 검토: design-reviewer REVISE D1~D4, tech-reviewer REVISE T1~T4. 같은 때 받은 사용자 지시도 반영했다). 검토자가 짚은 세션 기록(2026-11-18 `…01a1ea1f…`, 2026-11-14 `…01a1d872…`)은 planner가 Grep으로 다시 봤다: 도구 꼴, `tools.image_gen__imagegen(` 호출, `originator`, 모델·추론, 노출된 도구.

- **사용자 지시(모델·추론)**: 그림 생성은 `-m gpt-6.2-sol -c model_reasoning_effort=high`로만 한다.
  - 고친 곳: 근거에 원문과 메인의 확인을 넣었다. 목표 2·6, 막는 장치 3겹째(끄기와 따로 적었다), 명령의 꼴, 작업 4(`codex debug models`), 작업 5(명령, 기록), 작업 6.
  - F4: "추론 덮어쓰기를 뺀다" → 프롬프트만 고친다.
  - 새 F10: 세션 기록의 모델·추론이 다르면 그 그림을 쓰지 않는다.
  - 결정 184(추론 낮춤을 지웠다), 새 결정 192, 위험 3, 사용자 결정 4, 보고서 3번, Q2의 답 줄과 기록 줄.
  - 작업 0: CLAUDE.md 7장 새 글(154줄 자리)에 이 규칙을 넣었다. 시작 상태에 `M docs/DECISIONS.md`(메인의 한 줄, 커밋 전)를 받아들이고 그 diff를 적어 둔다.
  - 작업 9: `DECISIONS.md` 대조에서 그 줄을 따로 세고, 결정 183~192를 적는다.
- **D1 (수용)**: 작업 3 "야외 무대 셋"을 다시 썼다.
  - (1) 조용한 구역 = 교전·밀착 상대의 둘레 + 20px, 고리, 두 줄 글자(어림 x 440~840, y 62~670. 메인이 다시 셈한다). 그 밖의 x 290~990에는 L ≤ 0.20의 큰 톤 덩이와 그 형태를 허용했다.
  - (2) 경계는 곧은 세로선이 아니고 좌우가 비대칭이다.
  - (3) 곳마다 표에 "HUD를 얹어도 읽히는 큰 형태" 칸을 더했다: 뒷골목은 내민 위층과 쇠 간판, 물러나는 벽. 안뜰은 큰 나무 대문과 넘어온 잎 덩이. 광장은 지금대로. 근거에 HUD 자리를 적었다.
  - (4) 작업 8 눈 확인 1(과 7)에 "HUD를 얹은 채로 곳이 읽힌다"와 "가운데 판 + 양옆 날개로 읽히지 않는다"를 더했다.
  - (5) G5 프롬프트의 가운데 줄을 같은 규칙으로 바꿨다(가운데 35%, 큰 톤 덩이 허용, 곧은 경계와 거울 날개 금지). 승인 B·작업 6: 셋 다 극장 같다면 G5를 돌리지 않는다.
  - 그 밖에: 목표 1, 완료 확인(290~990의 톤 L ≤ 0.20, 조용한 구역 안에 선 없음), H6·H7, 결정 190.
- **D2 (수용)**:
  - 새 굳은 확인 H8: 몸통·다리·팔의 칠과 그림자 톤 18점의 Y ≥ 0.30. 걸리면 다시 뽑기 후보다.
  - G1 프롬프트에 "the shadow tones are also clearly lighter than the outlines"를 넣었고, 줄의 까닭에도 적었다.
  - 물든 칠 확인에 그림자 한 점을 더했다(작업 7).
  - 파츠로 나누는 법 4, 작업 7 재기, 작업 8 눈 확인 4, 목표 3, 결정 188.
- **D3 (수용)**:
  - 관절 맞추기: 생성 쪽 섹션에서 머리를 목 관절 중심으로 104(±5%)에 맞춘다. 모자가 상자를 넘기면 모자만 줄인다. 원래의 비는 `palette`·`GENERATION.md`에 적는다.
  - 작업 7 완료 확인에 머리 104를 더했다.
  - 목표 3, 보고서 3번, 결정 188.
- **D4 (수용, 통과 조건의 본안)**:
  - G2 프롬프트: 같은 머리를 표정 셋(거만함·당황·어지러움)으로 그리게 했다(파츠 열, 장 수는 같다).
  - 파츠로 나누는 법: 상태마다 머리를 고른다. `g2-states`가 그 얼굴을 쓴다.
  - H2(열 가운데 빠진 것 둘 이하, 머리 하나 이상), 부드러운 확인("세 얼굴이 같은 사람인가").
  - `s-parts`·`in-parts`도 머리 셋으로 두었다. `--dump-dom`의 `data-sheet-part` 수가 `Head` 6, 나머지 2다.
  - `g1-states` 캡션과 보고서 4번의 물음 4에 표정 바꾸기를 어디까지 봤는지 적는다.
- **T1 (수용)**:
  - (가) 끌 목록: `config.toml`에서 `enabled = true`인 플러그인 열 전부와 `node_repl`. 남기는 것은 없다. 근거에 열을 적었다.
  - 따옴표 없는 꼴의 후보 셋(`--disable` 기능, `plugins.<이름>.enabled=false`, `mcp_servers.node_repl.enabled=false`)을 작업 4에서 정한다.
  - (나) 작업 4에서 `codex mcp list`를 끄기 없이 한 번, 끄기와 함께 한 번 돌린다.
  - (다) 막는 장치 5겹째에 세션 기록의 Grep을 더했다: 노출된 도구에 `mcp__cua_repl|"name":"js"|codex_apps|browser` 0, 부른 도구는 그림 도구와 감싸는 `exec`뿐. 덮어쓰기마다 효과를 적는다. 다른 도구를 불렀으면 F7.
  - (라) G1에서 효과 없던 끄기는 "걸렸다"로 치지 않고 승인 B에서 사용자가 정한다. `notify`는 "확인 못 함"(보고서 2번).
  - 결정 184, 위험 2.
- **T2 (수용)**:
  - 5겹째에 `Get-FileHash ~/.codex/config.toml`을 더했다. 다르면 F7이다.
  - 대조에서 빼는 것(`auth.json`, `sessions/`, `generated_images/`의 새 폴더, 로그·캐시)을 적었다.
  - 작업 4는 처음 해시를 적고, 작업 5 완료 확인과 작업 9 완료 확인에서 그 해시와 대조한다.
- **T3 (수용)**:
  - (가) G1 지시 블록: 그림 도구를 한 번 부르고, 감싸는 코드 도구는 그 한 번에만 쓴다. 붙인 그림은 `{WORKDIR}\in-1.png` 경로로 참조 그림에 넘긴다. G2는 둘, G3~G5는 하나다.
  - (나) 시험이 정하는 것에 세션 기록의 `referenced_image_paths`·`num_last_images_to_include` Grep을 더했다. 넘기지 않은 실패와 따르지 않은 실패를 가른다.
  - (다) 결과 찾기의 첫 순서를 `thread.started`의 thread_id 폴더로 바꿨다. 시각으로 찾는 것은 마지막이고, 세션 기록에 그 폴더가 나올 때만 받는다.
  - 근거 28줄의 짐작을 고쳤다: Desktop 세션 그림도 쌓이고, 폴더 이름은 세션 id다.
  - 크기 인자가 없다는 것과 `transparent_background`를 4단계 후보로 적는다는 것(작업 1)을 더했다. 위험 1·5.
- **T4 (수용)**:
  - G1 프롬프트의 "The hand is at hip height"를 "the arm is short …, the hand is at waist height, just above the belt and higher than the hips"로 바꿨다. 까닭도 적었다.
  - G2 프롬프트의 팔에 "short as in the sketch"를 더했다.
  - 관절 맞추기에 팔 규칙을 더했다: 어깨~손목 × k를 105와 견주고, ±15%를 넘으면 Arm을 세로로 맞추고 비를 적는다(G1·G2 같게).
  - 목표 3, 작업 7 완료 확인, 결정 188.
- **비차단 의견 (수용)**:
  - 승인 B에서 사용량을 가늠할 수 있는 꼴(토큰, 있으면 계정 한도 대비 비율)로 알린다.
  - 묶음은 G2 → G5 → G3 → G4 차례로 놓아 끝에서부터 줄일 수 있게 묻는다(승인 B, 작업 6).
  - 승인 A는 다시 묻지 않는다.
  - `-c`는 따옴표 없이 쓴다.
  - 모델·추론은 `turn_context`로 확인해 기록 표에 적는다.
  - `transparent_background`를 `GENERATION.md`의 4단계 후보로 적는다.
  - read-only로 그림이 남는 것이 확인되어 F9는 예비로만 남긴다.
  - `medium` 한 장 46,264토큰을 위험 3에 적었다.
- **차단과 별개로 바꾼 것**: `GENERATION.md` 기록 표에 칸 넷을 더했다(모델·추론, 참조 그림 인자, 덮어쓰기 효과, 한도 비율). 사용자 결정 2의 "021 v2에"를 "021에"로 고쳤다.
