# 계획 028 보고서 — 판정 도구를 저장소로, 바르톨로 파츠를 애셋으로

- 계획: `docs/plans/028-tools-in-repo-and-bartolo-parts.md` v2 (4단계의 첫 계획)
- 검토: 2회(상한). 1회차 디자인 APPROVE · 기술 REVISE(T1~T5) → 2회차 기술 APPROVE, 디자인 이전 승인 유지. 최종 판정: 두 관점 승인.
- 실행: 2026-11-22. 작업 1~10. 게임 코드·씬·데이터·테스트는 고치지 않았다. 그림을 만들지 않았다(Codex 호출 0).

## 1. 한 일

- **판정 도구를 저장소로**: `docs/style/tools/`에 도구 열넷을 바이트째 옮기고 `paths.ps1`(저장소 뿌리·작업 폴더·견본 URL을 한 곳에서)을 더했다. 일곱 도구의 경로 줄만 고쳤다(`check027`, `run-codex`, `bake025`, `bake026`, `r026`, `calib024`(8행의 `measure` 부르기 포함), `calib026`). `run-codex`에 `-DryRun`을 더했다. 쓰는 법은 `docs/style/tools/README.md`.
- **바르톨로 파츠 열 장**: 새 도구 `cutparts.ps1`로 `docs/style/basis/bartolo-parts.png`에서 잘라 `assets/art/opponents/bartolo/`에 두었다(`head`, `head_oops`, `head_dizzy`, `hat`, `feather`, `torso`, `legs`, `arm`, `hand`, `sword`). 화소를 줄이지 않고 잘라만 두었다.
- **`assets/MANIFEST.md`**: 바이블 14절의 일곱 열로 열 줄(크기, 관절, 단위/화소, 출처).
- **문서**: 바이블 1·11·13.5·13.6·16절(도구 자리, 작업 폴더, `-DryRun`, 16절 머리 문장, 도구 줄), `GENERATION.md` "절차" 머리의 한 줄, `basis/README.md` 3행, CLAUDE.md 8장(`tools/`)과 9장("4단계 진행 중"), `DECISIONS.md`(결정 249~253), `HANDOFF.md`.
- **옛 자리**: 로컬 `docs/style/generated/tools/`를 `tools-before-028/`로 이름만 바꿨다(지우지 않았다).
- **새 파일**: `docs/style/tools/`(열일곱: 도구 열여섯과 `README.md`), `assets/art/opponents/bartolo/*.png`(열), `assets/MANIFEST.md`, 계획 파일, 이 보고서.

## 2. 확인한 것 / 확인 못 한 것

확인한 것:

| 무엇 | 결과 |
|---|---|
| 두 자리의 도구 | 함께 있는 이름은 해시가 모두 같다(`kmeasure.ps1` 포함. 위험 R1 없음) |
| 옮김 | 열넷의 해시가 옛 자리와 같다. `git check-ignore` 없음, `?? docs/style/tools/`. `docs/style/.gdignore`가 덮는다 |
| `paths.ps1` | 세 값이 `C:\godot\bravi`, `%TEMP%\bravi-style`의 전체 경로, `file:///C:/godot/bravi/docs/style/samples/`. 저장소 안을 가리키면 `THREW`이고 폴더를 만들지 않는다(`False`). 부른 셸에 환경 변수가 남지 않는다 |
| 경로 줄 | 일곱 파일의 다른 줄이 결정 250의 줄과 넣은 줄뿐이다. BOM·CRLF 그대로. `\tools\`를 부르는 줄 0. 경로 글자열 검색에 걸린 것은 `run-codex`의 `$env:APPDATA`(환경 변수) 하나. 열다섯 파일의 파서 오류 0 |
| 옛·새 맞대기 | `check027`·`measure -Regions`·`r026`·`calib026`·`calib024`·`calib024 -Calib`의 출력이 글자째 같다. `-Calib`가 새로 만든 `mix-parts.png`가 옛 것과 해시가 같다(8행의 `measure` 부르기가 됨). 굽기: 옛 도구로 두 번 구운 짝이 같고(`font-body` `974f9074…`, 실루엣 `65e7e12b…`), 새 도구의 것도 같은 해시. 빈 장면이 아니다(바탕과 다른 화소 99.8%·4.8%). `run-codex -DryRun`: 작업 폴더 세 곳만 다르고 같다(`same: True`), 그림 생성 없음(54 → 54, `events.jsonl` 없음) |
| 파츠 열 장 | 크기·관절·단위/화소가 계획의 손 계산과 모두 같다. 가장자리 불투명 화소 0, 옮긴 화소의 다름 0, 덩이 1(열 장 모두). 상자를 넓히지 않았다. 바탕을 지운 시트가 024 손질본과 해시가 같다(`f63e9a37…`) |
| MANIFEST | 몸 줄 열, 줄마다 일곱 칸, 경로 열이 모두 있다 |
| 바이블 대조 | 고친 뒤 새 자리의 `check027`: 못 찾은 것 0, V3 23/23, V8 ok. 검사한 개수는 V7만 43 → 45(고친 줄에서 `docs/` 경로가 셋 빠지고 다섯 늘었다), 나머지는 같다. 바이블 줄 수 그대로(635) |
| 옛 자리 | `docs/style/generated/tools/`가 없고, 물린 뒤 `check027`의 출력이 같다. `git status`에 `generated` 아래 것이 없다 |
| 끝 상태 | 게임 쪽(`scripts/`·`scenes/`·`data/`·`tests/`·`project.godot`)·명세·견본·프롬프트·기준 그림의 변경 0 |

확인 못 한 것(playtester에게 맡길 것. 사용자가 요청할 때만):

1. 테스트 `ALL PASS 65/65`와 스모크(게임 코드를 고치지 않았으므로 전과 같아야 한다).
2. Godot이 `assets/art/opponents/bartolo/`의 열 장을 오류 없이 가져오는지(`.png.import` 열 개). `docs/style/` 아래에는 `.import`가 생기지 않는지(`docs/style/tools/` 포함). 생긴 `.import`는 다음 커밋에 넣는다.
3. 게임 창의 카운터 → 결투 → 정산이 전과 같은지(그림은 아직 화면에 나오지 않는다).

- 029가 그림을 씬에 걸기 전에 2가 한 번 있으면 좋다.

## 3. 계획과 다르게 한 것

| 무엇 | 계획 | 한 것 · 까닭 |
|---|---|---|
| 경로 글자열 검색 | 0줄 | `run-codex.ps1`의 `$env:APPDATA`(코덱스 실행 파일의 자리를 찾는 환경 변수)가 `AppData`에 걸린다. 박힌 경로가 아니라 그대로 두었다 |
| 경계의 밝은 화소 | 재고 적는다 | 0이었다. 짙은 바탕의 확인용 그림에서는 윤곽선 바깥에 반투명한 어두운 번짐이 살짝 보인다(029에서 셰이더나 자르기로 볼 거리. 위험 R2) |
| `measure -Regions`와 GENERATION 419행 | 참고로 견준다 | 여섯 상자의 가운데 값이 GENERATION의 값과 같다(`#697680`, `#515E65`, `#926D4B`, `#7A5838`, `#F4C195`, `#B3583E`) |
| 작업 중의 손질 | — | `calib024`의 두 줄을 sed가 잘못 바꿔 Edit로 바로잡았고, 바이블 487행에 들어간 백스페이스 한 글자를 바로잡았다. `cutparts.ps1`은 PowerShell이 변수 이름의 대소문자를 가리지 않아 `-Grow` 인자와 표 이름이 겹친 것을 고쳤다. 고친 뒤의 확인은 위 표 그대로다 |

## 4. 사용자가 결정해야 할 것

1. **028의 커밋**(도구 열일곱, 파츠 열 장, MANIFEST, 문서).
2. **029를 시작할지**, 그리고 그 전에 둘(한 선택 창):
   - **포즈와 곡선을 게임에 옮길지**: 지금 게임은 팔을 돌리지 않고 옮기기만 해서 그림 팔이 어깨에서 떨어져 보인다. 지금 게임의 큰 베기는 머리를 0.317 가린다(문턱 0.10).
   - **그림의 원본 해상도**: 1920×1080까지면 파츠는 지금 그림 그대로(밀착 0.98)이고 무대만 031에서 맞춘다. 2560×1440까지 보면 파츠 시트를 029 전에 다시 그린다.
3. playtester 확인(위 셋)을 맡길지.

## 5. 다음 작업 제안

- 029(바르톨로를 결투에): 위 물음의 답을 받아 planner가 계획을 쓴다. 4단계 나눔은 계획 028의 "4단계 나눔"(029 결투 → 030 움직임 → 031 무대 → 032 내 손·칼 → 033 글꼴·UI → 034 카운터·의뢰인 → 035~036 상대 둘째·셋째 → 037 점검).
