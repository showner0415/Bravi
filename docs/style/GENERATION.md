# 그림 생성 기록

3단계 견본의 그림을 Codex CLI로 만드는 절차와 호출마다의 기록이다. 규칙은 `docs/DECISIONS.md`의 결정 184~192(계획 021)에 있다. 프롬프트 원문은 `prompts/`, 생성 그림은 로컬만인 `generated/`에 있다.

## 절차

### 준비 (계획 021 작업 4, 2026-11-21. 사용량 없음)

- Codex CLI 0.169.0(`%APPDATA%\npm\codex.cmd`, 같은 자리에 `codex.ps1`). `codex login status` → `Logged in using ChatGPT`.
- `codex debug models`에 `gpt-6.2-sol`이 있고 추론 low·medium·high·xhigh·max·ultra를 지원한다(결정 192).
- 사용자의 `~/.codex/config.toml` 해시(SHA256, 처음 값): `AA004752B6A2D5A3BB1E3635A6F4DACFCB590B7CBCB2C9ECF70D7DC4D667186D`.
- `codex exec`의 옵션(도움말): `--skip-git-repo-check`, `-C/--cd`, `-m`, `-s read-only|workspace-write|danger-full-access`, `-i/--image <FILE>...`, `--json`, `-o/--output-last-message`, 프롬프트 자리의 `-`(표준 입력), `-c key=value`, `--enable/--disable <기능>`.
  - 쓰지 않는 것: `danger-full-access`, `--dangerously-bypass-approvals-and-sandbox`, `--ephemeral`(세션 기록이 남지 않아 확인을 못 한다), `--trust`(설정에 남는다).
  - `--ignore-user-config`(설정 파일을 읽지 않는다)도 있다. 021은 쓰지 않았다: 사용자의 Windows 샌드박스 설정까지 빠져 샌드박스가 어떻게 바뀔지 모른다.
- **끄기의 꼴과 효과** (`codex mcp list`에 같은 옵션을 주어 본 것):

  | 끄기 | 꼴 | 효과 |
  |---|---|---|
  | 플러그인 전체 | `--disable plugins` | 걸림: 플러그인이 가져온 MCP `codex_app`·`cua_repl`이 목록에서 사라진다 |
  | 플러그인 열(설정에서 켜진 것 전부) | `-c plugins.<이름>.enabled=false` (따옴표 없이. 예: `plugins.unified-computer-use@openai-bundled.enabled=false`) | 걸림: 그 하나만 줘도 `cua_repl`이 사라진다 |
  | MCP `node_repl` | `-c mcp_servers.node_repl.enabled=false` | 걸림: `node_repl`이 disabled |
  | 앱·컴퓨터 조작·브라우저 기능 | `--disable apps`, `--disable computer_use`, `--disable browser_use`, `--disable browser_use_external` | `mcp list`로는 볼 수 없다. 세션 기록의 도구 목록으로 본다 |
  | `notify` | `-c notify=[]` | 확인 못 함(볼 길이 없다) |

  - 모두 함께 주면 `mcp list`에 `node_repl`(disabled) 하나만 남는다.
  - `-c mcp_servers.cua_repl.enabled=false`는 오류로 끝난다(설정에 없는 서버라). 쓰지 않는다.

### 시험 G1이 정한 것 (계획 021 작업 5, 2026-11-21)

- **명령** (scratchpad의 `run-codex.ps1`이 만든다. 큰따옴표 없음): `codex.cmd exec - --skip-git-repo-check -C <작업 폴더> -s read-only --json -o <작업 폴더>\last.txt -m gpt-6.2-sol -c model_reasoning_effort=high -c notify=[] -c mcp_servers.node_repl.enabled=false --disable plugins --disable apps --disable computer_use --disable browser_use --disable browser_use_external -c plugins.<이름>.enabled=false(열) --image=<작업 폴더>\in-1.png`
  - 프롬프트는 표준 입력(`-`)이다. `-`를 `exec` 바로 뒤에 두고 `--image=`를 맨 뒤에 둔다(`--image`가 여러 값을 받아 `-`를 그림으로 읽지 않게).
  - `Start-Process`로 띄우고(`-RedirectStandardInput prompt.txt`, 표준 출력은 `events.jsonl`, 오류는 `err.txt`) `Wait-Process -Timeout 900`으로 기다린다.
- **결과의 자리**: `~/.codex/generated_images/<thread_id>/exec-*.png`. thread_id는 `events.jsonl`의 첫 줄(`thread.started`)에 있다. 메인이 `docs/style/generated/`로 복사한다.
- **read-only로 된다.** 작업 폴더에는 넣은 것과 `events.jsonl`·`err.txt`·`last.txt`(`done` 한 줄)만 남았다.
- **크기**: 그림 도구에 크기 인자는 없다. 에이전트가 그림 도구의 프롬프트에 "portrait 1024 × 1536"을 옮겨 적었고 1024×1536이 나왔다. 한 번에 한 장이다.
- **붙인 그림이 그림 도구에 닿았다**: 에이전트가 `exec` 안에서 `tools.image_gen__imagegen({ referenced_image_paths: [<작업 폴더>\in-1.png], transparent_background: false, prompt: … })`를 한 번 불렀다. `num_last_images_to_include`는 쓰지 않았다. 에이전트는 우리 프롬프트를 그림 도구에 맞게 다시 써서 넘긴다(블록의 뜻은 남았다).
- **자세를 따랐다**: 칼 팔은 보는 쪽 왼쪽, 칼날은 위·바깥, 손은 허리띠 바로 위, 머리는 크게, 깃털은 옆으로. 스케치와 같이 팔이 몸통에 붙어 틈은 없다(윤곽선으로 갈린다).
- **세션 기록으로 본 막는 장치**: 모델 `gpt-6.2-sol`, 추론 `high`, 샌드박스 `read-only`. 노출된 도구 이름(정의의 `"name"`만 셌다)에 `cua`·`browser`·`codex_apps`·`computer`·`js`가 없다. 부른 도구는 `exec` 하나이고 그 안에서 `image_gen__imagegen`만 불렀다. `notify`는 확인 못 함.
- **걸린 것**: 47초. 토큰 39,042(입력 38,423 가운데 캐시 31,488, 출력 619). 계정 한도(세션 기록의 `rate_limits`): 5시간 창 55%, 주간 0%. 호출 전후의 기록 모두 55%라 1% 단위에서 변하지 않았다.
- **전후 대조**: 저장소의 `git status`·`diff --stat` 같음, `config.toml` 해시 같음, 이전의 `generated_images` 파일 수 같음.
- 세션 기록을 Grep할 때 도구는 정의의 `"name"` 값으로만, 부른 도구는 호출 항목 줄(`function_call`·`custom_tool_call`)과 그 안의 `tools.<이름>(`으로만 센다(프롬프트 글과 도구 설명문에 잘못 걸리지 않게. 2회차 검토의 제안).

## 프롬프트의 틀

블록 일곱: 지시 · 그림 · 주제 · 구도와 자세 · 화풍 · 색 · 바탕. 영어, ASCII만, 큰따옴표 없이 쓴다. 게임·제작사·작가의 이름과 참고 스크린샷은 넣지 않는다(결정 179·186·187). 원문은 `prompts/021-G1-bartolo-front.txt`가 기준이고, G2~G5는 바꾸는 블록만 다르다(계획 021 "프롬프트의 틀").

## 기록

| G | 날 | 승인 | 프롬프트 파일 | 넣은 그림 | 옵션 | 모델·추론(세션 기록) | 참조 그림 인자 | 덮어쓰기 효과 | 결과(파일, 크기 px, 바이트) | 걸린 시간 · 토큰 · 한도 비율 | 찾은 자리(thread_id) | 굳은 확인 | 쓴 섹션 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| G1 | 2026-11-21 | A(시험, Q2 답) | `prompts/021-G1-bartolo-front.txt` | `in-front`(SVG를 구운 1024×1536) | read-only, 끄기 전부(위 명령) | `gpt-6.2-sol` · `high` (turn_context) | `referenced_image_paths` 1장, `transparent_background: false` | 플러그인·앱·컴퓨터·브라우저: 걸림(도구 목록에 없음) · `node_repl`: 걸림 · `notify`: 확인 못 함 | `021-G1-bartolo-front.png` 1024×1536, 1,237,514B | 47초 · 39,042(캐시 31,488) · 5시간 창 55% 그대로 | `01a1fc94-2064-70b2-8d31-3d7068bde4ea` | H1 통과 · H2 통과(팔과 몸통 사이 틈 10~18px, 칼날은 몸을 가로지르지 않음. 승인 B 때는 줄인 그림만 보고 "틈 없음"으로 적었다가 화소로 바로잡았다) · H3 통과(바탕 #D4D3D3, 테두리 퍼짐 2, 허용 차 28, 새는 곳 없음) · H4 통과 · H5 통과(신호 구역 0.13%, S 몸통 8% 팔 8% 바지 43%·그림자 47%) · H8 통과(18점 Y 0.31~0.45) | `g1-raw`, `g1-states` |
| G2 | 2026-11-21 | B | `prompts/021-G2-bartolo-parts.txt` | G1 원본(`in-1`), `in-parts`(`in-2`) | 같다 | `gpt-6.2-sol` · `high` | `referenced_image_paths` 2장 | 같다 | `021-G2-bartolo-parts.png` 1536×1024, 1,286,962B | 53초 · 43,466(캐시 33,280) · 55→56% | `01a1fc9d-43f2-7af0-ae52-5e07f4e39202` | H1 통과 · H2 통과(파츠 열 모두, 서로 닿지 않음, 머리 셋) · H3 통과(#D4D4D4, 퍼짐 3) · H4 통과 · H5 통과(신호 구역 0.82%, S 몸통 8% 팔 7% 바지 47%·그림자 50%) · H8 통과(18점 Y 0.35~0.47) | `g2-raw`, `g2-states`, `g-duel`, `g-far`, `g-stage-*`, `g-states-gray` |
| G5 뒷골목 | 2026-11-21 | B | `prompts/021-G5-stage-alley.txt` | `in-stage-alley` | 같다 | `gpt-6.2-sol` · `high` | 1장 | 같다 | `021-G5-stage-alley.png` 1536×1024, 2,635,495B | 55초 · 38,824 · 56% | `01a1fc9e-15ee-7701-b176-65b3ca98f836` | H4 통과 · H6 통과(사람·동물 없음. 왼쪽 문의 둥근 윗부분은 가장자리의 문이라 가운데를 감싸는 아치가 아니다) · H7 통과(가운데 L 평균 0.029, 95번째 0.055, 신호 구역 0%) | `g-stage-alley` |
| G5 안뜰 | 2026-11-21 | B | `prompts/021-G5-stage-court.txt` | `in-stage-court` | 같다 | `gpt-6.2-sol` · `high` | 1장 | 같다 | `021-G5-stage-court.png` 1536×1024, 2,542,427B | 57초 · 38,982 · 56% | `01a1fc9e-ef64-7ce0-ac37-1c160aed83dd` | H4 통과 · H6 통과 · H7 통과(0.025, 0.028, 0%) | `g-stage-court` |
| G5 광장 | 2026-11-21 | B | `prompts/021-G5-stage-piazza.txt` | `in-stage-piazza` | 같다 | `gpt-6.2-sol` · `high` | 1장 | 같다 | `021-G5-stage-piazza.png` 1536×1024, 2,550,452B | 72초 · 38,673 · 56% | `01a1fc9f-d2e7-7ec0-b3f8-ac37c0d41833` | H4 통과 · H6 통과(종탑 창의 둥근 꼴은 먼 실루엣의 창이다) · H7 통과(0.050, 0.082, 0%) | `g-stage-piazza` |
| G3 | 2026-11-21 | B | `prompts/021-G3-client-clara.txt` | `in-client-1` | 같다 | `gpt-6.2-sol` · `high` | 1장 | 같다 | `021-G3-client-clara.png` 1024×1536, 1,347,306B | 43초 · 38,757 · 56→57% | `01a1fca0-efb4-7192-8771-681a8871a23d` | H1 통과 · H3 통과(#D4D4D3, 퍼짐 2) · H4 통과 | `g-client-1` |
| G4 | 2026-11-21 | B | `prompts/021-G4-client-vittorio.txt` | `in-client-2` | 같다 | `gpt-6.2-sol` · `high` | 1장 | 같다 | `021-G4-client-vittorio.png` 1024×1536, 1,382,785B | 52초 · 39,111 · 57% | `01a1fca1-9a61-7890-8c7b-1e101447cc97` | H1 통과 · H3 통과(#D2D1D1, 퍼짐 2) · H4 통과 | `g-client-2` |

- 승인 B의 답(2026-11-21): 묶음 넷 모두. 생성 무대는 "배경을 여러개 만들 생각이고 뒷골목, 안뜰, 광장 3개 다 만들어줘"라 G5를 셋 돌렸다. G1은 다시 뽑지 않는다. 장·호출 합 7/8, 다시 뽑기는 없었다(굳은 확인에 걸린 그림이 없다).
- 모든 호출에서 세션 기록의 노출된 도구에 `cua`·`browser`·`codex_apps`·`computer`·`js`가 없었고, 부른 도구는 `exec` 안의 `image_gen__imagegen` 하나였다. 저장소·`config.toml` 해시·이전 그림 파일 수는 매번 같았다.
- 5시간 창은 일곱 장 동안 55%에서 57%로 올랐다(1% 단위). 한 장에 30~40초의 생성과 약 39,000 토큰(대부분 캐시)이 든다.

## 파츠로 나누기와 비례 맞추기 (계획 021 작업 7)

- 바탕 지우기: 테두리 화소의 가운데 값과 채널 차 28 안의 이어진 화소를 투명하게 하고 가장자리 1px을 깎는다(scratchpad의 `measure.ps1`). 네 장(G1~G4) 모두 새는 곳 없이 한 번에 지워졌다(무대 G5는 지우지 않는다).
- 관절은 세로줄·가로줄의 화소 경계로 읽었다(`scan.ps1`). k = 200 ÷ (골반 − 목).
  - G1(전신): k 0.466. 머리는 목~모자 원점이 120.8이라 ×0.861로 104에 맞췄다(모자·깃털도 같이). 팔은 109(+4%)라 그대로다. 칼날은 그림에서 −22°라 +22° 돌려 세웠다. 모자 밑의 머리는 그림에 없어, 모자를 벗은 상태에서는 정수리가 챙 자리에서 잘린다.
  - G2(파츠 시트): k 0.709. 머리털 꼭대기가 135.5라 ×0.864로 117(모자 원점 104)에 맞췄다. 모자는 그 배율로 56.3이 되어 ×0.941 더 줄여 53에 맞췄다(교전 꼭대기 142.6). 팔은 124.8(+19%)이라 세로만 ×0.841로 105에 맞췄다. 깃털은 밑동이 모자 좌표 (30, −23)에 오게 놓았다. 머리 셋은 상태마다 골랐다.
- 상태 색: 파츠 그림에 SVG 필터를 씌운다. sRGB의 Y가 0.22 아래면 선, 0.30 위면 칠이고, 칠에 신호색 80%를 덮은 뒤 선을 다시 얹는다. 빈틈 칸에서 칠·그림자 모두 `lerp(바탕, #4D80F2, 0.8)`와 ±1이었다.
- 프롬프트의 틀에서 시험 뒤 바꾼 것: G2는 참조 그림 둘을 경로로 넘기게 했다. G3·G4는 "on the figure"의 큰 면 줄을 옷으로 바꿨다. G5는 계획의 G5 행 그대로이고 곳마다 주제 줄만 다르다.

## 4단계 후보

- 그림 도구에 `transparent_background` 인자가 있다(같은 버전의 세션 기록). 021은 한 색 바탕과 테두리 채우기로 했다. 컷아웃 파츠를 만들 때 이 인자를 시험할 만하다.
