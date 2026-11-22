# 계획 028: 판정 도구를 저장소로, 바르톨로 파츠를 애셋으로

- 버전: v2 (1회차 검토 대응: 기술 T1~T5와 비차단 제안 하나, 디자인 비차단 제안 하나. 끝의 "검토 대응 기록")
- 개발 단계: CLAUDE.md 9장 **4단계(아트 교체)의 첫 계획**. 게임 코드·씬·데이터·테스트는 고치지 않는다. 새로 생기는 게임 쪽 파일은 `assets/`의 그림 열 장과 `assets/MANIFEST.md`뿐이다. 그림을 만들지 않는다(Codex 호출 0).
- 근거:
  - 사용자 지시(2026-11-22, 원문): "3단계 완료로 판정. 27 커밋. 판정도구 저장소에 올린다. 계속 진행". "계속 진행" = 4단계. 4단계의 목표는 "상대 2~3명, 카운터 배경, UI", 완료 기준은 "placeholder 대체, 컷아웃 애니메이션"(9장 단계표).
  - 바이블 16절 "판정 도구가 로컬에만 있다": 올리면 scratchpad 경로를 빼고 저장소 안의 도구 폴더로. 바이블 1절: 바이블을 고친 뒤 `check027.ps1`을 돌린다.
  - 결정 189(생성 그림은 로컬만, 고른 것만 `basis/`), 결정 12(파츠 이름·계층·원점), 결정 248(`assets/MANIFEST.md`는 첫 애셋 때 만들고 꼴은 바이블 14절).
  - 손질 값(관절·배율·자르는 상자): `docs/style/basis/README.md` "손질 값"의 `bartolo-parts` 표. k 0.5935.
  - 해상도: 바이블 10절 — 파츠 시트는 1920×1080 창의 밀착에서 몸통·다리·칼 0.98, 머리 0.90, 팔 0.76(1 이하, "겨우 걸친다"). 무대는 1920에서 1.25로 늘어난다.
  - 앞선 지시: "내가 꼭 결정해야되는게 있으면 선택할 수 있는 창 띄워." → 꼭 필요한 것만 선택지로(최대 넷), 고칠 거리는 글로, 방향은 그림 두 안으로(바이블 13.7).
  - 결정 번호는 249부터다.

### 넘지 않는 선

- 메인은 Godot·테스트·게임을 실행하지 않는다(`tests/run_tests.ps1`, `tests/run_smoke.ps1`, 헤드리스 Godot, `play.ps1`). PowerShell 도구, Edge headless 굽기, 화소 재기, `git`은 이 규칙 밖이다. 실행 확인은 사용자가 요청할 때만 playtester가 한다(끝의 "playtester에게 맡길 확인").
- 고치지 않는 것: `scripts/`, `scenes/`, `data/`, `tests/`, `project.godot`, `docs/style/basis/`의 그림, `docs/style/prompts/`, 견본 020~027, `docs/style/STYLE_SPEC.md`, 사용자의 파일(`tools/`, `.claude/agents/playtester.md`, `docs/plans/013-playtester.md`, `.codex/`, `AGENTS.md`).
- `docs/style/generated/`는 계속 로컬만이다(`.gitignore` 8행 그대로).
- **편집은 작게 한다**: Write 한 번과 Edit 한 번은 80줄 안쪽, 문서는 절 하나씩. 큰 편집 도중 응답이 끊긴 적이 있다.
- 한글이 든 `.ps1`은 UTF-8 BOM이 있어야 PowerShell 5.1이 읽는다. 도구를 고친 뒤 첫 세 바이트를 본다(작업 3·5).
- 옛 도구와 새 도구를 같은 PowerShell 프로세스에서 부르지 않는다(`kmeasure.ps1`·`measure.ps1`의 `Add-Type`이 같은 형 이름을 쓴다). 비교는 따로 띄운 `powershell -NoProfile -File`로 한다.
- **명령은 감싸개 파일로 띄운다**(T5): 이 계획의 도구 명령은 모두 작은 `.ps1`(옛 scratchpad의 `028-old/run-*.ps1`, ASCII만)에 적고 `powershell -NoProfile -File <감싸개>`로 띄운다. 큰따옴표로 싼 `-Command`에 `$`를 쓰지 않는다(부르는 셸이 먼저 펼친다). 환경 변수는 감싸개 안에서만 건다(그 프로세스가 끝나면 사라진다). 감싸개 안의 파일 인자는 모두 **절대 경로**로 쓴다(도구의 `new Bitmap(...)`은 .NET의 현재 폴더를 따르고 `Set-Location`을 따르지 않는다). 인자에 한글을 쓰지 않는다.

## 4단계 나눔 (제안. 028의 범위만 확정한다)

계획마다 사용자가 진행을 정한다(결정 253). 재미에 가까운 것(결투에서 상대가 읽히는가)을 앞에 둔다. 번호는 예정이다.

| 계획 | 하는 것 | 그 계획을 시작하기 전에 물을 것 |
|---|---|---|
| **028** | 판정 도구를 저장소로. 바르톨로 파츠 열 장을 잘라 `assets/`에, `MANIFEST.md`. 게임은 그대로 | 없음 |
| 029 | 바르톨로를 결투에: 파츠 그림(Sprite2D, 결정 12의 노드 그대로), 상태 색 셰이더(바이블 5절의 문턱 0.22·0.30, 칠에만 80%), 조준 테두리, 머리 셋(미소·당황·어지러움), 상대 그림을 데이터로(원칙 5). 포즈를 옮기기로 하면 **팔은 어깨 회전**과 15절 포즈 표 | **포즈를 게임에 옮길지**(바이블 16절의 사용자 결정). 지금 게임은 팔을 돌리지 않고 옮기기만 해서(`scripts/duel/opponent_view.gd` 208·222·232행의 `arm_target`, 239·242행의 `_arm.position`) 그림 팔이 어깨에서 떨어져 보인다. 안 옮기면 029의 팔이 달라진다. **그림의 원본 해상도**도 같은 선택 창에서 묻는다(029~030에서 바르톨로를 넣은 뒤 2560을 고르면 시트를 다시 그리고 관절·배율·상자와 029의 배치를 다시 맞춰야 한다). 포즈는 026 견본의 "지금 게임"과 "어깨 회전 · `hold`"를 그림으로 나란히 보이고 바이블 11절의 R2(지금 게임 큰 베기 0.317, 문턱 0.10)를 곁들인다 |
| 030 | 움직임: `hold` 곡선, 따로 그린 팔 둘(큰 베기 예비 동작, 찌르기 타격)의 잘라 넣기와 바꿔 끼우기, 든 팔 주먹 그림자 고치기(한 장, 결정 245), 반응 싸움인지 플레이 확인(바이블 16절) | 그림 한 장의 몫 |
| 031 | 결투 무대 셋(뒷골목·안뜰·광장) 넣기, 어느 판에 어느 무대인지. 029 전에 받은 해상도의 답대로(무대는 지금 1920에서 1.25) | 무대를 고르는 규칙 |
| 032 | 내 손·칼 그리기(기준 그림이 없다. 섞은 SVG가 기준)와 넣기 | 그림의 몫 |
| 033 | 글꼴(서브셋·라이선스)과 UI의 꼴 "필사본"(Theme), 글자 크기의 아홉 단계, HUD 손보기, 밀착의 모자-경고 글자 겹침(BACKLOG 020-1) | **그린 질감**(양피지·장식 테두리를 그림으로 만들지) |
| 034 | 카운터 배경 그리기(SVG만 있다)와 의뢰인 그림(클라라·비토리오 + 나머지 의뢰인) | 그림의 몫, 의뢰인 몇 명 |
| 035~036 | 상대 둘째·셋째: 전신 → 파츠 시트 → 팔(바이블 13.3의 시험된 길) | 새 상대의 행동 데이터를 새로 둘지 그림만 바꿀지(6단계 콘텐츠와의 경계), 그림의 몫 |
| 037 | 4단계 점검: placeholder가 남지 않았는지, MANIFEST의 `final` 판정, 컷아웃 애니메이션 | "4단계 완료 기준 충족 — 다음 단계 진행 여부" |

- 028을 도구·애셋 준비로 따로 둔 까닭: 029는 Godot 쪽 일(셰이더, 노드, 데이터)만으로 크다. 자르기와 그 판정을 028에서 끝내 두면 029는 잘린 그림을 믿고 시작한다.
- 028이 16절의 사용자 결정 셋(해상도·질감·포즈)에 걸리지 않는 까닭: 해상도 — 파츠는 화소를 줄이지 않고 잘라만 두고(결정 251) 1920의 기준을 넘기지 않는다. 더 크게 그리기로 하면(029 전의 답) 같은 이름으로 바꿔 끼우고 자르기를 다시 돌린다(`cutparts.ps1`). 028은 아직 게임에 배치하지 않으므로 다시 할 것이 자르기뿐이다. 질감 — UI를 건드리지 않는다. 포즈 — 따로 그린 팔은 자르지 않고(030), 파츠 열 장은 포즈와 상관없다.

## 목표와 범위

**확인할 결과**. 메인은 PowerShell 도구의 출력, 파일 해시·바이트, Grep·Glob·`git`, 구운 PNG의 Read로 확인한다.

1. 판정 도구 열넷과 새 도구 둘(`paths.ps1`, `cutparts.ps1`)이 `docs/style/tools/`에 있고 `git status`에 새 파일로 보인다(무시되지 않는다). 그 폴더에 scratchpad·세션·`C:\godot` 경로가 없다.
2. 새 자리의 도구가 옛 자리의 도구와 **같은 입력에 같은 출력**을 낸다(작업 4의 표). `check027.ps1`은 바이블을 고치기 전과 뒤에 모두 못 찾은 것 0이다.
3. 바르톨로 파츠 열 장이 `assets/art/opponents/bartolo/`에 있고, 크기·관절·배율이 작업 6의 표와 같고, 바탕이 지워졌고, 잘린 데가 없고, 칠·선의 화소가 기준 그림과 같다.
4. `assets/MANIFEST.md`가 바이블 14절의 일곱 열로 열 줄이다.
5. 바이블(1·11·13.5·13.6·16절)·HANDOFF·CLAUDE.md(8·9장)·GENERATION.md·`basis/README.md`가 새 자리를 가리키고, 옛 자리(`docs/style/generated/tools/`)를 가리키는 말이 이 다섯 파일의 지금 상태를 적는 줄에 없다(지난 기록의 줄은 그대로 둔다).

**범위 밖**: 게임에 그림을 띄우기(029), 따로 그린 팔 자르기(030), 무대·의뢰인·글꼴을 `assets/`에 넣기, 도구의 동작 고치기(경로 말고. 결정 250), `measure.ps1` 머리 주석의 깨진 글자(021 때부터. 동작과 상관없다) 고치기, 옛 도구 일곱 올리기.

## 설계 결정

249. **도구의 자리**: `docs/style/tools/`. `docs/style/.gdignore`가 이미 있어 Godot이 가져오지 않고, `.gitignore`(5~8행)에 걸리지 않는다. 저장소 뿌리의 `tools/`는 사용자의 파일이 있어 쓰지 않는다. 올리는 것은 바이블 13.6·1절·11절과 HANDOFF 1번이 쓰는 열넷: `check027` · `run-codex` · `bake025` · `bake026` · `r026` · `sil026` · `blobs026` · `calib024` · `calib026` · `measure` · `scan` · `kmeasure` · `lum` · `tintpair`(`.ps1`). 022~024에만 쓴 옛 도구 일곱(`bake022`·`bake023`·`bake024`·`calib`·`calib023`·`run-batch`·`tintcheck`)은 올리지 않는다(다른 세션의 경로가 박혀 있고 지금 판정이 쓰지 않는다). 생성 그림 `docs/style/generated/`는 로컬만 그대로다(결정 189).
250. **경로는 `paths.ps1` 한 파일이 정한다.** 도구는 `. (Join-Path $PSScriptRoot 'paths.ps1')`로 읽고 세 값을 쓴다.
    - `$BraviRepo` = `$PSScriptRoot`에서 세 단계 위(`docs/style/tools` → 저장소 뿌리)의 전체 경로.
    - `$BraviWork` = 환경 변수 `BRAVI_STYLE_WORK`, 없으면 `%TEMP%\bravi-style`. 전체 경로로 바꾼 뒤 **저장소 안이면 만들기 전에 멈춘다**(`throw`. 바이블 13.5 "작업 폴더는 저장소 밖"). 그 뒤에 없으면 만든다.
    - `$BraviSamplesUrl` = `file:///` + 저장소 뿌리(`\`를 `/`로) + `/docs/style/samples/`.
    - 이름에 `Bravi`를 붙이는 까닭: `run-codex.ps1`이 이미 `$work`(호출마다의 폴더)를 쓴다.
    - 도구 안의 고치는 줄은 경로 줄뿐이다: `$scratch`·`$s` = `$BraviWork`, `$repo`·`$root` = `$BraviRepo`, `file:///C:/godot/bravi/docs/style/samples/` = `$BraviSamplesUrl`, `. "$s\tools\kmeasure.ps1"` = `. (Join-Path $PSScriptRoot 'kmeasure.ps1')`, `& "$s\tools\measure.ps1"`(calib024 8행의 `CutOf` 안) = `& (Join-Path $PSScriptRoot 'measure.ps1')`, `$gen` = `Join-Path $BraviRepo 'docs\style\generated'`. 다른 도구를 부르는 줄은 모두 `$PSScriptRoot`(r026은 이미 `$tools`)로 부른다: 작업 공간 아래의 `tools\`는 없다.
    - 더하는 동작은 둘뿐이다: `run-codex.ps1`의 `-DryRun`(작업 폴더·`prompt.txt`·`cmd.txt`를 만들고 `Start-Process` 전에 끝난다. 그림 없이 명령을 대조하려고), `docs/style/generated/`가 없으면 만들기(새로 받은 저장소에는 없다).
251. **게임 애셋은 기준 그림의 화소를 줄이지 않고 잘라만 둔다.** 파츠 단위로의 배율과 관절은 `MANIFEST.md`의 출처 칸에 적고 Godot이 준다(029). 임시 결정이고 되돌리기 쉽다: 더 크게 그리거나 줄여 두기로 하면 같은 파일 이름으로 바꾸고 배율만 고친다.
252. **상대 그림의 자리와 이름**: `assets/art/opponents/<상대>/`, 파일 이름은 파츠 이름의 snake_case(`head.png`, `head_oops.png`, `head_dizzy.png`, `hat.png`, `feather.png`, `torso.png`, `legs.png`, `arm.png`, `hand.png`, `sword.png`). 따로 그린 팔은 030에서 같은 폴더에 넣는다.
253. 4단계 나눔은 제안이고(위 표) 계획마다 사용자가 진행을 정한다.

## 작업 목록

작업 1~4는 도구, 5~7은 애셋, 8~10은 문서와 마무리다. 차례대로 한다(4가 통과하기 전에 5를 하지 않는다).

### 작업 1. 옛 도구의 기준 출력을 남긴다

- 대상: 로컬 `docs/style/generated/tools/`(옛 자리), 옛 scratchpad의 `tools/`(calib가 읽는 `kmeasure.ps1`의 자리). 아래에서 `<R>` = `C:\godot\bravi`, `<O>` = 옛 scratchpad(`C:\Users\shown\AppData\Local\Temp\claude\C--godot-bravi\a4d9d3a4-2b6c-4d71-8002-1a3b648d2bd4\scratchpad`), `<T>` = `<R>\docs\style\generated\tools`. 감싸개와 출력은 `<O>\028-old\`에 둔다. 명령은 모두 감싸개 파일로 띄운다("넘지 않는 선").
- 할 일:
  1. 두 자리의 `.ps1`마다 SHA256을 적는다. 두 자리에 다 있는 이름(`measure`·`scan`·`lum`·`kmeasure`·`tintpair`·`bake025` 등)은 해시가 같은지 본다. **다르면** 올리는 원본은 옛 자리(`generated/tools/`)의 것으로 하고(`kmeasure.ps1`만은 위험 R1을 따른다), 다른 이름과 두 해시를 보고서 3번에 적는다. 이때 작업 2의 "해시가 같다"는 고른 원본과 견준다.
  2. `& '<T>\check027.ps1'`(인자 없음) → `028-old\check027.txt`.
  3. `& '<T>\measure.ps1' -Cut '<R>\docs\style\generated\cut\024-P1a-bartolo-parts.png' -Regions 'jacket,150,580,330,780;jacket_sh,300,560,345,780;pants,500,535,700,640;pants_sh,640,535,700,640;skin,120,180,230,250;hat,990,205,1110,240'` → `028-old\measure.txt`. **`-Src`를 주지 않는다**(T2): `-Regions`는 `-Cut`의 파일만 읽고(`measure.ps1` 72행), `-Src`와 `-Cut`을 함께 주면 70행이 그 파일을 다시 지워 덮어쓴다. 상자 여섯은 GENERATION.md 419행(저고리 · 저고리 그림자 · 바지 · 바지 그림자 · 살 · 모자)이다.
  4. 굽기(T3). 같은 shot을 옛 도구로 **두 번** 굽는다. 출력은 `<O>\<OutDir>\`에 생긴다.
     - `& '<T>\bake025.ps1' -Page 025-type-ui-size.html -Budget 5000 -OutDir 028-old-025a -Shots 'font-body'`, 같은 것을 `-OutDir 028-old-025b`로. 파일은 `<O>\028-old-025a\font-body.png`·`<O>\028-old-025b\font-body.png`.
     - `& '<T>\bake026.ps1' -Page 026-pose-motion.html -Budget 5000 -OutDir 028-old-026a -Shots 'sil+col=game+curve=hold+atk=big+ph=idle+dist=mid'`, 같은 것을 `-OutDir 028-old-026b`로. 파일은 `<O>\028-old-026a\sil-col-game-curve-hold-atk-big-ph-idle-dist-mid.png`와 `…026b\…`.
  5. `& '<T>\r026.ps1' -Col game`(`-Bake` 없이. `<O>\026\`의 그림을 읽는다) → `028-old\r026.txt`.
  6. `& '<T>\calib026.ps1' -SheetPath '<R>\docs\style\basis\bartolo-arms.png' -Ppu 3.16 -Sleeves '390,566,532,982;985,188,1215,816'` → `028-old\calib026.txt`.
  7. `& '<T>\calib024.ps1' -SheetPath '<R>\docs\style\generated\cut\024-P1a-bartolo-parts.png' -Label sheet -Ppu 1.685 -J 'torso=236,853;legs=594,524;arm=888,559;head=172,345' -R 'torso=109,365;legs=452,738;arm=840,936;head=60,284'` → `028-old\calib024.txt`. (6·7의 인자는 `basis/README.md`의 관절·상자에서 고른 고정 값이다. 판정이 아니라 옛·새의 같음을 보려는 것이다.)
  8. `& '<T>\calib024.ps1' -Calib` → `028-old\calib024-calib.txt`(T1. 바이블 13.6의 "기준 맞추기"). 옛 쪽은 `<O>\024\cut\mix-parts.png`가 이미 있어 `measure`를 부르지 않는다.
  9. `<O>\codex\A1g-bartolo-arms-1\cmd.txt`를 `028-old\cmd-A1g.txt`로 복사한다.
- 완료 확인:
  - `028-old\`에 txt 일곱(`check027` · `measure` · `r026` · `calib026` · `calib024` · `calib024-calib` · 해시 목록)과 `cmd-A1g.txt`. 각 txt가 비어 있지 않고 `Exception`·`error`가 든 줄이 없다. `check027.txt`의 V마다 못 찾은 수가 0이다(바이블은 아직 그대로다). `measure.txt`에 줄이 여섯(`jacket:` … `hat:`)이다.
  - 굽기의 PNG 넷이 위 자리에 있고 모두 1280×720이며 **빈 장면이 아니다**: 왼쪽 위 모서리 화소와 RGB가 다른 화소가 전체의 1% 이상이고(`System.Drawing`으로 센다), Read로 보아 `font-body`는 글꼴 넷의 글자가, 026 shot은 한 색 실루엣이 보인다.
  - 두 번 구운 짝(025a·025b, 026a·026b)마다 SHA256이 같은지 적는다. 이 결과가 작업 4의 굽기 판정을 정한다.

### 작업 2. `docs/style/tools/`를 만들고 열넷을 바이트째 옮긴다

- 대상: 새 폴더 `docs/style/tools/`, 결정 249의 열넷.
- 할 일: `Copy-Item`으로 복사한다(다시 저장하지 않는다. 인코딩·BOM·줄 끝이 그대로여야 한다). `paths.ps1`을 결정 250대로 새로 쓴다(ASCII만. 주석이 한글이면 UTF-8 BOM으로 쓴다).
- 완료 확인:
  - `docs/style/tools/`의 `.ps1`이 열다섯(열넷 + `paths.ps1`)이고, 열넷의 SHA256이 작업 1의 옛 자리 해시와 같다.
  - `git check-ignore -v docs/style/tools/check027.ps1`이 아무것도 내지 않는다. `git status --short`에 `?? docs/style/tools/`가 있다.
  - `docs/style/.gdignore`가 있다(Glob). `docs/style/tools/` 아래에 `.gdignore`를 따로 두지 않는다(위의 것이 덮는다).
  - `paths.ps1`의 세 값(T5). 감싸개 둘을 `<O>\028-old\`에 쓰고 `powershell -NoProfile -File`로 띄운다.
    - `run-paths.ps1`: `. '<R>\docs\style\tools\paths.ps1'; $BraviRepo; $BraviWork; $BraviSamplesUrl` → 세 줄이 `C:\godot\bravi`, `[IO.Path]::GetFullPath((Join-Path $env:TEMP 'bravi-style'))`와 같은 값, `file:///C:/godot/bravi/docs/style/samples/`이다.
    - `run-paths-throw.ps1`: `$env:BRAVI_STYLE_WORK = '<R>\docs\x'; try { . '<R>\docs\style\tools\paths.ps1'; 'NO-THROW' } catch { 'THREW' }; Test-Path '<R>\docs\x'` → `THREW`와 `False` 두 줄이다. 환경 변수는 이 자식 프로세스에만 걸리므로 뒤의 도구에 남지 않는다. 띄운 뒤 부르는 셸에서 `$env:BRAVI_STYLE_WORK`가 비어 있는지 한 번 본다.

### 작업 3. 경로 줄을 고친다

- 대상(일곱): `check027`(4행), `run-codex`(1·4·5행과 끝의 `$outDir`), `bake025`(4·10행), `bake026`(5·11행), `r026`(6행), `calib024`(4~6행과 8행의 `CutOf` 안 `& "$s\tools\measure.ps1"`. T1), `calib026`(5·6행). 줄 번호는 옛 자리의 파일 기준이다. 고친 뒤 열다섯 파일에서 글자열 `\tools\`를 Grep해 0줄이어야 한다(작업 공간 아래의 `tools\`를 부르는 줄이 남지 않았다. `$s\024\cut`처럼 작업 공간의 결과 폴더를 가리키는 줄은 그대로 둔다. `run-codex` 81행의 정규식 `tools\.(`는 `\tools\`에 걸리지 않는다).
- 할 일: 결정 250의 바꿈만 한다. 파일마다 첫 경로 줄 바로 위(`param` 블록이 있으면 그 뒤)에 `. (Join-Path $PSScriptRoot 'paths.ps1')` 한 줄을 넣고 경로 줄을 바꾼다. `run-codex.ps1`에는 `[switch]$DryRun`을 `param`에 더하고, `cmd.txt`를 쓴 바로 뒤(옛 34행 뒤)에 `if ($DryRun) { Get-Content (Join-Path $work 'cmd.txt'); exit 0 }`를 넣고, `$outDir` 다음에 `New-Item -ItemType Directory -Force -Path $outDir | Out-Null`을 넣는다.
- 완료 확인:
  - 일곱 파일마다 옛 파일과 줄 단위로 견준다(`Compare-Object`). 다른 줄은 위에서 정한 줄과 넣은 줄뿐이다. 줄 수의 차가 넣은 줄 수와 같다.
  - 일곱 파일의 첫 세 바이트가 옛 파일과 같다(BOM이 있었으면 `EF BB BF` 그대로).
  - `docs/style/tools/`의 모든 파일에서 글자열 `AppData`, `scratchpad`, `C:\godot`, `C:/godot`, `890590ef`, `a4d9d3a4`를 찾아(대소문자 무시) 0줄이다.
  - 열다섯 파일 모두 PowerShell 파서의 오류가 0이다(감싸개 `<O>\028-old\run-parse.ps1` 안에서 파일마다): `$t = $null; $e = $null; [void][System.Management.Automation.Language.Parser]::ParseFile('<파일>', [ref]$t, [ref]$e); $e.Count`.

### 작업 4. 새 자리의 도구가 같은 출력을 내는지 본다

- 대상: 새 자리의 도구(`<N>` = `<R>\docs\style\tools`). 작업 폴더는 기본값(`<W0>` = `%TEMP%\bravi-style`)이고, `r026`만 감싸개 안에서 `$env:BRAVI_STYLE_WORK = '<O>'`를 걸어 옛 그림을 읽힌다. 바이블은 아직 고치지 않는다. 작업 1과 같은 날 잇달아 돌린다.
- 명령: 작업 1의 명령에서 `<T>`를 `<N>`으로, 굽기의 `-OutDir`를 `028-new-025`·`028-new-026`으로 바꾼 것(출력은 `<W0>\028-new-025\font-body.png`, `<W0>\028-new-026\sil-col-game-curve-hold-atk-big-ph-idle-dist-mid.png`). `calib024 -Calib`는 띄우기 전에 `<W0>\024\cut\`이 없거나 비어 있는지 보고, 있으면 지운다(그래야 새 `CutOf`가 실제로 `measure.ps1`을 부른다. T1). 출력은 `<O>\028-old\new-*.txt`로 받는다.
- 완료 확인(모두 따로 띄운 프로세스에서):

| 도구 | 새 자리의 출력 | 통과 |
|---|---|---|
| `paths` | 작업 2의 감싸개 둘 | 작업 2의 기대 값 |
| `check027` | 출력 전체 | `028-old/check027.txt`와 글자째 같다 |
| `measure -Regions` | 출력 전체 | `028-old/measure.txt`와 글자째 같다. 참고로 GENERATION.md 419행과도 견준다: `jacket`의 fill `#697680`, `jacket_sh`의 shadow `#515E65`, `pants`의 fill `#926D4B`, `pants_sh`의 shadow `#7A5838`, `skin`의 fill `#F4C195`, `hat`의 fill `#B3583E`(이 견줌은 판정이 아니다. 옛 출력과 같으면 옮김은 통과이고, GENERATION과의 차이는 보고서 3번에 적는다) |
| `bake025` · `bake026` | 위 두 PNG | **판정 하나**(R3과 같은 말): 작업 1의 두 번 구운 짝이 같았으면 새 PNG가 그 해시와 같아야 통과, 다르면 멈춘다. 짝이 서로 달랐으면(Edge의 흔들림) 해시로 판정하지 않고, 새 PNG가 1280×720이고 빈 장면이 아니며(작업 1의 1% 규칙) Read로 같은 장면이면 통과, 아니면 멈춘다. 어느 쪽이든 결과를 보고서 2번에 적는다 |
| `r026 -Col game` | 출력 전체 | `028-old/r026.txt`와 글자째 같다 |
| `calib026` · `calib024` | 출력 전체 | `028-old/calib026.txt`·`calib024.txt`와 글자째 같다(새 것은 `<N>\kmeasure.ps1`을 읽는다) |
| `calib024 -Calib` | 출력 전체와 `<W0>\024\cut\mix-parts.png` | 출력이 `028-old/calib024-calib.txt`와 글자째 같고, 새로 생긴 `mix-parts.png`가 `<O>\024\cut\mix-parts.png`와 SHA256이 같다(다르면 alpha의 다른 화소 수가 0이어야 한다). 이것으로 8행의 `measure.ps1` 부르기가 검증된다(T1) |
| `run-codex -DryRun` | `& '<N>\run-codex.ps1' -G A1g -Name bartolo-arms -Plan 027 -Images '<R>\docs\style\basis\bartolo-arms.png' -DryRun`이 쓴 `<W0>\codex\A1g-bartolo-arms-1\cmd.txt` | 두 `cmd.txt`에서 각자의 작업 폴더 경로(옛 `<O>\codex\A1g-bartolo-arms-1`, 새 `<W0>\codex\A1g-bartolo-arms-1`)를 `<W>`로 바꾸면 글자째 같다. 그림 생성이 일어나지 않았다(`%USERPROFILE%\.codex\generated_images\`의 파일 수가 앞뒤로 같다, 새 작업 폴더에 `events.jsonl`이 없다). 다시 돌려야 하면 그 폴더가 있어 멈추므로 `-Try 2`를 주고 `-2` 폴더와 견준다 |
| `sil026` · `blobs026` · `scan` · `lum` · `tintpair` · `kmeasure` · `measure` | — | 작업 2의 해시 같음으로 갈음한다(경로가 없어 고치지 않았다) |

- 하나라도 다르면 작업 5로 가지 않는다. 다른 줄을 보고서에 적고, 경로 바꿈 밖의 원인(예: 옛 자리와 scratchpad의 `kmeasure.ps1`이 다르다)이면 그 원인과 고른 원본을 3번에 적는다. 원인이 경로 바꿈이면 고쳐 다시 견준다.

### 작업 5. 자르는 도구 `cutparts.ps1`을 쓴다

- 대상: 새 파일 `docs/style/tools/cutparts.ps1`(UTF-8 BOM). 읽는 것 `docs/style/basis/bartolo-parts.png`, 쓰는 것 `assets/art/opponents/bartolo/`의 PNG 열 장과 `$BraviWork\028-cut\`의 중간 그림.
- 동작:
  1. `& (Join-Path $PSScriptRoot 'measure.ps1') -Src <시트의 절대 경로> -Cut <$BraviWork\028-cut\sheet-cut.png>`로 시트 전체의 바탕을 지운다(시트 자체는 `-Cut`에 주지 않는다. 기준 그림을 덮어쓰지 않게)(허용 차 28. 바이블 5절 "바탕 지우기"). 지우는 법을 새로 짓지 않는다.
  2. 작업 6 표의 상자대로 자른다. 상자는 `basis/README.md`의 값이고 **양 끝을 넣는다**(x 60~284는 폭 225). 늘리거나 줄이지 않는다(결정 251). 32비트 ARGB PNG로 쓴다. 인자는 `-Grow`(문자열 하나, 기본 빈 값, `head=0,0,0,2;feather=0,1,0,3`처럼 파츠마다 왼·위·오른·아래로 넓힐 화소. 작업 6의 4) 하나뿐이고, 넓힌 파츠는 넓힌 상자로 크기와 관절을 센다.
  3. 파츠마다 한 줄을 낸다: `part,<이름>,<폭>,<높이>,<관절 x>,<관절 y>,<단위/화소 x>,<단위/화소 y>,<가장자리 불투명 화소>,<옮긴 화소의 다름>,<경계의 밝은 화소>`.
     - 관절 = 시트의 관절 − 상자의 왼쪽 위. 단위/화소 = 0.5935 × 배율(소수 넷째 자리).
     - 가장자리 불투명 화소: 자른 그림의 바깥 한 줄에서 alpha > 0인 화소 수(파츠가 상자에 잘렸는지).
     - 옮긴 화소의 다름: alpha > 0인 화소의 RGB가 원본 시트의 같은 화소와 다른 수.
     - 경계의 밝은 화소: 투명 화소와 4방향으로 닿은 불투명 화소 가운데 Y ≥ 0.6인 수와 그 비율(바탕 회색이 테두리에 남았는지. 적기만 한다).
  4. 어두운 무대 `#3A3027`과 양피지 `#E9D8B4` 위에 열 장을 늘어놓은 확인용 그림 둘을 `$BraviWork\028-cut\`에 쓴다(눈으로 테두리를 본다).
- 완료 확인: 파서 오류 0(작업 3의 식), 첫 세 바이트 `EF BB BF`, 경로 글자열 Grep 0(작업 3의 목록).

### 작업 6. 바르톨로 파츠 열 장을 잘라 확인한다

- 대상: `assets/art/opponents/bartolo/`의 열 장(결정 252의 이름).
- 기대 값(손 계산. 상자·관절·배율은 `docs/style/basis/README.md` 27~34행, k 0.5935는 23행):

| 파일 | 파츠 | 상자 x · y | 크기 | 관절(자른 그림의 화소) | 단위/화소 |
|---|---|---|---|---|---|
| `head.png` | Head | 60~284 · 122~376 | 225×255 | (112, 223) | 0.5442 |
| `head_oops.png` | HeadOops | 340~567 · 122~376 | 228×255 | (113.5, 224) | 0.5442 |
| `head_dizzy.png` | HeadDizzy | 623~850 · 122~376 | 228×255 | (113.5, 225) | 0.5442 |
| `hat.png` | Hat | 909~1190 · 188~314 | 282×127 | (140, 102) | 0.5579 |
| `feather.png` | Feather | 1237~1483 · 222~292 | 247×71 | (−43, 81). Feather 노드는 Hat 원점에 오프셋 없이 두고 이 관절을 피벗으로 준다. 그러면 밑동이 모자 좌표 (30, −23)에 저절로 온다(견본 `024-widen.html` 214~215행) | 0.5579 |
| `torso.png` | Torso | 109~365 · 493~861 | 257×369 | (127, 360) | 0.5935 |
| `legs.png` | Legs | 452~738 · 513~850 | 287×338 | (142, 11) | 0.5935 |
| `arm.png` | Arm | 840~936 · 519~793 | 97×275 | (48, 40) | x 0.4451 · y 0.4611 |
| `hand.png` | Hand | 1061~1160 · 585~693 | 100×109 | (49, 12) | 0.4511 |
| `sword.png` | Sword | 1263~1409 · 469~867 | 147×399 | (73, 343) | 0.5935 |

- 완료 확인:
  1. `sheet-cut.png`가 로컬의 `docs/style/generated/cut/024-P1a-bartolo-parts.png`(024에서 같은 도구로 지운 것)와 SHA256이 같다. 다르면 alpha의 다른 화소 수를 내고 0이어야 한다.
  2. 열 줄의 크기·관절·단위/화소가 위 표와 같다. **4에서 상자를 넓힌 파츠는** 넓힌 상자로 같은 식을 다시 센 값(크기 = x1 − x0 + 1 · y1 − y0 + 1, 관절 = 시트의 관절 − 새 상자의 왼쪽 위)과 견주고, 단위/화소는 표 그대로다(T4). 넓힌 상자와 다시 센 크기·관절을 MANIFEST의 출처와 보고서 3번에 적는다.
  3. 열 장 모두: 네 모서리 alpha 0, **가장자리 불투명 화소 0**, **옮긴 화소의 다름 0**, `& '<N>\blobs026.ps1' -Img '<R>\assets\art\opponents\bartolo\<파일>' -Min 500`(감싸개 안)이 `blobs,1`.
  4. 가장자리 불투명 화소가 0이 아닌 파츠는 불투명 화소가 걸린 변만 1화소씩 넓혀(한 변에 8화소까지) 그 변의 불투명 화소가 0이 될 때까지 다시 자른다. `cutparts.ps1`은 파츠마다 네 변의 넓힘(`-Grow name=l,t,r,b;…`)을 인자로 받고 넓힌 상자로 관절을 다시 센다. 다른 덩이가 들어오면(3의 `blobs,1`이 깨지면) 또는 8화소로 모자라면 멈추고 보고한다. 넓힌 뒤에는 2·3을 그 파츠에 다시 본다.
  5. 확인용 그림 둘을 Read로 본다: 어두운 바탕에서 테두리 밖에 밝은 회색 띠가 보이는지. 경계의 밝은 화소 비율과 함께 보고서에 적는다(적기만 한다. 띠가 보이면 029에서 셰이더나 자르기로 다룰 거리로 넘긴다. 위험 R2).

### 작업 7. `assets/MANIFEST.md`를 만든다

- 대상: 새 파일 `assets/MANIFEST.md`(결정 248, 바이블 14절).
- 꼴: 머리 한 줄("CLAUDE.md 7장의 애셋 목록. 꼴은 `docs/STYLE_BIBLE.md` 14절")과 일곱 열의 표. 열의 이름과 차례는 14절 그대로(파일 · 용도 · 크기 · 상태 · 출처 · 따른 기준 · 라이선스). 파일 하나에 한 줄.
  - 파일: `art/opponents/bartolo/head.png`처럼 `assets/` 아래 경로. 용도: 파츠 이름과 쓰는 때(예: "Head — 대기·예비 동작·회수", "HeadOops — 당황", "HeadDizzy — 무너짐"은 029가 정하므로 지금은 파츠 이름과 "결투 상대 바르톨로"만). 크기: 작업 6의 px. 상태: `generated`.
  - 출처: `docs/style/prompts/024-P1a-bartolo-parts.txt`, thread `01a1ff6a-93f9-7972-bbae-cfb4857d32f1`, 손질 "`docs/style/basis/bartolo-parts.png`의 상자 x … · y …를 잘라 바탕을 지움(허용 차 28, `docs/style/tools/cutparts.ps1`), 줄이지 않음, 관절 (…), 단위/화소 …".
  - 깃털 줄의 관절은 "Hat 원점에 오프셋 없이, 피벗 (−43, 81). 그러면 밑동이 모자 좌표 (30, −23)"로 적는다(029에서 오프셋을 두 번 주지 않게).
  - 따른 기준: `bartolo-parts`. 라이선스: `—`(우리 그림. 14절: 글꼴과 바깥 자원만 적는다).
- 완료 확인: 표의 몸 줄이 열이고(구분 줄 제외), 줄마다 칸이 일곱이다(`|`로 나눈 수). 파일 칸의 열 경로가 모두 있다(Test-Path). 크기·관절·단위/화소가 작업 6의 출력과 같다.

### 작업 8. 도구의 안내와 문서를 새 자리로 고친다

절 하나씩 Edit한다.

| 파일 | 고칠 곳 | 바꿈 |
|---|---|---|
| `docs/style/tools/README.md`(새 파일) | 전체 | 도구 열여섯의 표(이름 · 하는 일 · 바이블의 판정 이름 · 주요 인자), 쓰는 법 넷: 작업 폴더(`BRAVI_STYLE_WORK`, 없으면 `%TEMP%\bravi-style`, 저장소 안이면 멈춤), 한글이 든 `.ps1`은 BOM, 배열 인자는 `-Command "& '…' -Shots 'a','b'"`, 옛 도구와 한 프로세스에서 섞지 않기. 생성 그림은 `docs/style/generated/`(로컬만). 절대 경로를 쓰지 않는다(작업 3의 Grep) |
| `docs/STYLE_BIBLE.md` 1절 35행 | "로컬 도구 `docs/style/generated/tools/check027.ps1`" · "도구는 로컬에만 있다(16절)" | `docs/style/tools/check027.ps1` · "도구는 `docs/style/tools/`에 있다(결정 249)" |
| 바이블 11절 398행 | "로컬 도구 `sil026.ps1`" | "도구 `sil026.ps1`" |
| 바이블 13.5 484행 | "로컬 도구 `run-codex.ps1`이 만든다" | "`docs/style/tools/run-codex.ps1`이 만든다". 지킬 것의 둘째 항목 끝에 "작업 폴더의 뿌리는 `BRAVI_STYLE_WORK`(없으면 `%TEMP%\bravi-style`)이고 저장소 안이면 도구가 멈춘다. 명령만 보려면 `-DryRun`" |
| 바이블 13.6 497행 | "도구는 로컬 `docs/style/generated/tools/`에 있다(16절)" | "도구는 `docs/style/tools/`에 있다(쓰는 법은 그 폴더의 `README.md`)" |
| 바이블 16절 615행(머리 문장) | "\"사용자 결정\"이라 적힌 것은 4단계를 시작할 때 사용자에게 묻는다." | "\"사용자 결정\"이라 적힌 것은 그 일을 하는 계획을 시작할 때 사용자에게 묻는다(나눔은 계획 028의 \"4단계 나눔\")." 줄 수는 그대로다 |
| 바이블 16절 633행 | "판정 도구가 로컬에만 있다" 줄 | 셋째 칸을 "올렸다(계획 028, 결정 249·250): `docs/style/tools/`. 022~024의 옛 도구 일곱은 로컬에 남는다"로 |
| `docs/style/GENERATION.md` "절차" 머리(5행 아래) | 새 한 줄 | "도구는 계획 028부터 `docs/style/tools/`에 있다(결정 249). 아래 기록의 scratchpad·`generated/tools/`는 그때의 자리다." 지난 기록의 줄(30·137·343·438행)은 고치지 않는다 |
| `docs/style/basis/README.md` 3행 | "(`assets/`와 `MANIFEST.md`는 4단계)" | "(게임의 애셋은 `assets/`, 목록은 `assets/MANIFEST.md`)" |
| `CLAUDE.md` 8장 | `docs/` 줄의 `style/ (…)` | `basis/,` 뒤에 `tools/,`를 넣는다 |
| `CLAUDE.md` 9장 184행 | "3단계 완료 (…)" 뒤 | "4단계 진행 중 (2026-11-22 사용자 지시 \"계속 진행\"). 계획 028(도구를 저장소로, 바르톨로 파츠를 애셋으로)." 한 문장. 4단계 나눔의 제안은 이 계획을 가리키기만 한다 |
| `docs/DECISIONS.md` 끝 | 새 절 "2026-11-22 — 계획 028" | 결정 249~253 한 줄씩과 "실행 중에 정한 것" |

- 완료 확인:
  - 바이블을 고친 뒤 새 자리의 `check027.ps1`(인자 없음): V1·V2(면제 밖)·V3·V4·V5·V6·V7의 못 찾은 수가 모두 0, V3 23/23, V8 `ok True` 둘. 검사한 개수는 V7만 작업 4의 값과 달라도 되고, 그 차는 고친 줄에서 더하고 뺀 `docs/` 경로 수와 같다(손으로 센 값을 보고서에 적는다). V1·V2·V4·V5·V6·V8의 검사한 개수는 작업 4와 같다.
  - `docs/STYLE_BIBLE.md`, `CLAUDE.md`, `docs/style/basis/README.md`에서 `generated/tools` Grep이 0줄이다. `docs/style/GENERATION.md`에서는 새 한 줄과 지난 기록의 두 줄(137·438행)뿐이다. (HANDOFF는 작업 10.)
  - 바이블의 줄 수가 고치기 전과 같다(이 작업은 줄을 더하지 않는다. V5의 검사한 줄 수도 같아야 한다).

### 작업 9. 옛 자리를 물린다

- 대상: 로컬 `docs/style/generated/tools/`(git이 무시하는 곳).
- 할 일: 작업 4·8이 통과한 뒤 폴더 이름을 `docs/style/generated/tools-before-028/`로 바꾼다. 지우지 않는다(되돌리려면 이름을 되돌린다). 옛 도구 일곱도 여기 남는다.
- 완료 확인: `docs/style/generated/tools/`가 없다(Glob). 새 자리의 `check027.ps1`을 한 번 더 돌려 작업 8과 같은 출력이다(V7이 옛 자리를 가리키지 않는다). `git status --short`에 `docs/style/generated` 아래 것이 보이지 않는다.

### 작업 10. HANDOFF와 보고서

- 대상: `docs/HANDOFF.md`(1번의 "쓸 수 있는 것"의 도구 줄, 머리의 "로컬에만 있는 것"의 도구 항목, 1번의 다음에 할 일과 14행 "16절 … 사용자 결정 넷"의 줄을 "남은 셋은 그 일을 하는 계획 전에 묻는다. 029 전에 포즈와 해상도를 한 선택 창에서"로, 3번에 028 보고서 4번), `docs/reports/028-tools-in-repo-and-bartolo-parts.md`(CLAUDE.md 10장의 다섯 항목).
- 완료 확인:
  - HANDOFF에서 `generated/tools` Grep이 0줄이고, "스크립트 안의 scratchpad 경로는 … 고쳐 쓴다"는 줄이 없다. 도구 줄은 `docs/style/tools/`와 그 `README.md`를 가리킨다.
  - 보고서 2번에 작업 1~9의 확인마다 통과·값을 적고, 돌리지 않은 것(아래 playtester 목록)을 "확인 못 한 것"으로 적는다. 3번에 작업 1의 해시 차이, 작업 6의 넓힌 상자(있으면), 경계의 밝은 화소의 값을 적는다.

## playtester에게 맡길 확인 (사용자가 요청할 때만)

메인은 돌리지 않는다. 사용자가 요청하면 메인이 playtester에게 아래와 기대 결과를 넘긴다(게임·테스트를 띄우는 명령마다 `$env:BRAVI_SAVE_PATH = "user://bravi_playtest_save.json"`).

1. 테스트 `ALL PASS 65/65`와 스모크 OK(이 계획은 게임 코드를 고치지 않았으므로 전과 같아야 한다).
2. Godot이 `assets/art/opponents/bartolo/`의 열 장을 오류 없이 가져온다(`.png.import` 열 개가 생긴다). `docs/style/` 아래에는 `.import`가 하나도 생기지 않는다(`docs/style/tools/` 포함).
3. 게임 창의 카운터 → 결투 → 정산이 전과 같다(그림은 아직 화면에 나오지 않는다).

- 2에서 생긴 `.import` 파일은 다음 커밋에 넣는다(Godot 4는 `.import`를 저장소에 둔다). 029가 그림을 씬에 걸기 전에 이 확인이 한 번 있으면 좋다.

## 위험

- **R1 옛 자리와 scratchpad의 도구가 다르다**: `calib024`·`calib026`은 scratchpad의 `kmeasure.ps1`을 읽어 왔다. 두 사본이 다르면 새 `calib`의 출력이 옛 것과 달라진다. 작업 1의 해시와 작업 4의 비교가 잡는다. 그때는 계획 024·026의 잰 값을 낸 쪽(옛 `calib`가 읽은 scratchpad의 것)을 `kmeasure.ps1`로 올리고, 두 사본의 다른 줄을 보고서 3번에 적는다.
- **R2 테두리의 밝은 띠**: 테두리 채우기는 바탕과 선이 섞인 화소 가운데 허용 차 밖의 것을 남긴다. 짙은 무대 위에서 인물 둘레에 옅은 띠로 보일 수 있다. 028은 재고 보기만 하고(작업 6의 5), 고치는 것(셰이더에서 밝은 테두리를 깎기, 자를 때 한 화소 더 깎기, 그림 도구의 `transparent_background`)은 029가 정한다.
- **R3 Edge의 흔들림**: 같은 shot이어도 Edge가 갱신되거나 굽기가 흔들리면 화소가 달라질 수 있다. 작업 1과 4를 같은 날 잇달아 돌리고, 작업 1에서 옛 도구로 두 번 굽는다. 판정은 작업 4 표의 굽기 줄 하나다: 두 번 구운 짝이 같았으면 새 PNG가 그 해시와 같아야 통과, 다르면 멈춘다. 짝이 서로 달랐으면 해시로 판정하지 않고, 새 PNG가 1280×720이고 빈 장면이 아니며 Read로 같은 장면이면 통과, 아니면 멈춘다.
- **R4 `.import`가 없는 그림**: 메인이 Godot을 띄우지 않으므로 커밋 때 `.png.import`가 없다. 그림을 아무 데서도 쓰지 않아 게임과 테스트에는 영향이 없다. 029가 씬에 걸기 전에 가져오기가 한 번 돌아야 한다(playtester 확인 2).

## 사용자 결정 필요

**검토 전에 물을 것: 없다.** 028은 바이블 16절의 사용자 결정 셋(해상도, 그린 질감, 포즈 옮기기)에 걸리지 않는다(위 "4단계 나눔"의 마지막 항목). 판정 도구를 올리는 것은 사용자가 정했다(2026-11-22).

뒤로 미루는 것(그 계획을 시작할 때 묻는다):

| 결정 | 물을 때 | 답에 따라 달라지는 것 |
|---|---|---|
| 포즈와 곡선을 게임에 옮길지(16절) | 029 전(026 견본의 "지금 게임"과 "어깨 회전 · `hold`"를 그림으로 나란히, 바이블 11절의 R2 값을 곁들여) | 옮기면 029에서 팔을 어깨에서 돌리고 15절 표를 데이터로 둔다. 안 옮기면 지금처럼 팔을 옮기기만 하는데, 그림 팔이 어깨에서 떨어져 보이므로 그것을 감출 길(팔 그림을 어깨에 붙여 늘이기 등)이 029에 든다 |
| 그림의 원본 해상도(16절) | 029 전, 포즈와 한 선택 창에서 | 1920까지면 파츠는 지금 그림 그대로(0.98)이고 무대만 031에서 맞춰 다시 그리거나 나눠 그린다(지금 1.25). 2560까지 보면 파츠 시트도 029 전에 다시 그리고(지금 1.31) `cutparts.ps1`의 상자·관절을 다시 잰다 |
| 그린 질감(16절) | 033 전 | 양피지·장식 테두리를 그림으로 만들면 033에 그림 몇 장과 그 몫이 든다. 안 만들면 Godot의 StyleBox와 셰이더로 흉내 낸다 |

- 028을 마친 보고서의 4번에는 새 결정이 없을 것이다. "029의 시작 여부"와 위 첫 두 줄(포즈, 해상도)을 한 선택 창에서 함께 묻는다.

## 검토 대응 기록

1회차(디자인 APPROVE, 기술 REVISE T1~T5)에 대한 v2의 대응이다.

- **T1** (calib024 8행의 `measure` 부르기): 결정 250의 바꿈 목록과 작업 3의 대상 줄에 8행을 넣었고, 작업 3에 `\tools\` Grep 0을 더했다. 작업 1의 8과 작업 4의 표에 `calib024 -Calib`의 맞대기를 더했다(새 쪽은 `024\cut`을 비우고 돌려 `mix-parts.png`의 해시까지 견준다).
- **T2** (`measure -Regions`): 작업 1의 3을 `-Cut <손질본> -Regions '<ASCII 이름 여섯과 상자>'`로 고치고 `-Src`를 빼는 까닭(70·72행)을 적었다. 작업 4 표의 GENERATION 견줌은 판정이 아니라 참고로 두었다. 작업 5의 `cutparts`도 시트를 `-Cut`에 주지 않는다고 적었다.
- **T3** (굽기): bake025에 `-Budget 5000`을 넣었다. shot은 `font-body`와 `sil+col=game+curve=hold+atk=big+ph=idle+dist=mid`이다. PNG의 자리를 `<O>\028-old-025a`·`025b`·`026a`·`026b`와 `<W0>\028-new-025`·`026`으로 맞추고, 빈 장면이 아닌지 보는 규칙을 더했다. 옛 도구로 두 번 굽고, 판정 하나를 작업 4 표와 R3에 같은 말로 적었다.
- **T4** (넓혀 다시 자르기): 작업 6의 2에 "넓힌 파츠는 넓힌 상자로 다시 센 크기·관절과 견준다"를 넣었다. 4를 `-Grow` 인자로 1화소씩 넓히는 꼴로 고치고(작업 5에 인자를 더했다), 그 값을 MANIFEST와 보고서 3번에 남긴다.
- **T5** (`paths.ps1` 확인): 작업 2의 확인을 감싸개 파일 둘(`run-paths.ps1`, `run-paths-throw.ps1`)을 `-File`로 띄우는 꼴로 고쳤다. 환경 변수는 자식에만 걸고 뒤에서 비었는지 본다. "넘지 않는 선"에 감싸개 규칙(큰따옴표 `-Command`에 `$` 금지, 절대 경로, 한글 인자 금지)을 더하고, 작업 1·4의 명령을 `<R>`·`<O>`·`<T>`·`<N>`·`<W0>`의 절대 경로로 다시 적었다.
- 기술 비차단(깃털 관절): 작업 6 표와 작업 7에 "Hat 원점에 오프셋 없이, 피벗 (−43, 81)"로 적었다.
- 디자인 비차단(해상도를 029 전에): 4단계 나눔의 029·031 줄, 그 아래의 까닭, "사용자 결정 필요"의 표를 고쳤다. 작업 8에 바이블 16절 머리 문장(615행), 작업 10에 HANDOFF 14행 고치기를 더했다.
- 스스로 훑어 고친 것: `run-codex -DryRun`의 그림 인자를 절대 경로로 바꾸고, 다시 돌릴 때 `-Try 2`를 쓰게 했다. `blobs026`의 인자를 절대 경로로, 파서 확인을 감싸개 안으로 옮겼다. `paths.ps1`이 폴더를 만들기 전에 저장소 안인지 먼저 보게 했다(결정 250). 작업 1의 완료 확인에 `measure.txt`의 여섯 줄을 더했다.
