# 화풍 판정 도구

`docs/STYLE_BIBLE.md` 13.5·13.6이 쓰는 PowerShell 도구다(계획 028에서 저장소로 올렸다. 결정 249·250). Godot은 이 폴더를 가져오지 않는다(`docs/style/.gdignore`).

| 도구 | 하는 일 | 바이블의 판정 | 주요 인자 |
|---|---|---|---|
| `paths.ps1` | 저장소 뿌리·작업 폴더·견본 URL을 정한다. 다른 도구가 읽는다 | — | 환경 변수 `BRAVI_STYLE_WORK` |
| `run-codex.ps1` | Codex CLI로 그림 한 장을 만들고 막는 장치를 확인한다 | 생성의 막는 장치(13.5) | `-Plan -G -Name -Images -Phrases`, `-DryRun`(명령만 만든다), `-Try` |
| `bake025.ps1` · `bake026.ps1` | 견본 HTML을 Edge headless로 굽는다(026은 `-Size`) | 견본의 장 | `-Page -OutDir -Budget 5000 -Shots '<id>+<키>=<값>'`, `-DumpDom` |
| `measure.ps1` | 바탕 지우기(허용 차 28), 칠·그림자의 Y | H3·H5·H8, A-1a·A-3 | `-Src -Cut`, `-Cut -Regions 'name,x0,y0,x1,y1;…'` |
| `scan.ps1` | 가로줄·세로줄의 경계(관절, 폭) | H9·H10, A-4 | `-Img -Rows -Cols` |
| `kmeasure.ps1` | K1·K2·K3′·K5의 셈(다른 도구가 읽는다) | K1·K2′·K3′·K5·H11 | — |
| `calib024.ps1` · `calib026.ps1` | 파츠 시트·팔 시트의 화풍 판정, `-Calib` 기준 맞추기 | K1·K2′s·K3′, A-2 | `-SheetPath -Ppu -J -R`, `-Sleeves` |
| `lum.ps1` | 무대 가운데의 밝기 | H7 | — |
| `tintpair.ps1` | 상태 색을 켠 장과 끈 장을 견준다 | T1·T2 | — |
| `sil026.ps1` · `r026.ps1` | 한 색 실루엣을 세고 R1·R2·R4를 낸다 | R1·R2·R4 | `-Col -Curve -Bake -Tag` |
| `blobs026.ps1` | 이어진 덩이를 센다 | A-1b, HP1 | `-Img -Min` |
| `check027.ps1` | 바이블에 옮긴 값이 원문과 같은지 대조한다 | 바이블 1절 | `-Target -Sources -Only` |
| `cutparts.ps1` | 기준 시트에서 파츠를 잘라 `assets/art/opponents/<상대>/`에 둔다 | — | `-Grow 'name=l,t,r,b;…'` |

## 쓰는 법

- **작업 폴더**: 굽기·자르기·호출의 중간 파일은 `BRAVI_STYLE_WORK`(없으면 `%TEMP%\bravi-style`)에 생긴다. 저장소 안을 가리키면 도구가 멈춘다.
- **생성 그림**은 `docs/style/generated/`(로컬만, git이 무시한다. 결정 189)에 생긴다. 고른 것만 `docs/style/basis/`로 올린다.
- 한글이 든 `.ps1`은 UTF-8 BOM이 있어야 PowerShell 5.1이 읽는다. 고친 뒤 첫 세 바이트(`EF BB BF`)를 본다.
- 배열 인자는 `-File`이 아니라 `-Command "& '…\bake026.ps1' -Shots 'a','b'"`로 넘긴다. 큰따옴표로 싼 `-Command`에 `$`를 쓰면 부르는 셸이 먼저 펼친다. 복잡한 명령은 작은 감싸개 `.ps1`에 적고 `-File`로 띄운다.
- 파일 인자는 절대 경로로 쓴다(도구 안의 `new Bitmap(...)`은 .NET의 현재 폴더를 따른다).
- 같은 PowerShell 프로세스에서 `Add-Type`의 형 이름이 같은 다른 사본(예: 로컬의 옛 도구)과 섞지 않는다.
