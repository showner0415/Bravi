# 계획 054: 의뢰인 그림 셋 — 양봉가 체칠리아 · 젊은 백작 레안드로 · 세탁부 넬라 (옛 046b)

- 버전: v2 (2026-11-28. 1회차 디자인 REVISE(D1 · D2)와 비차단 하나, 기술 APPROVE의 비차단 넷 반영 — 끝의 "검토 대응 기록". v1: 2026-11-28)
- 개발 단계: CLAUDE.md 9장 **6단계(콘텐츠)**의 2주차 묶음(나눔 052 v2). 차례 표의 054 줄("체칠리아·레안드로·넬라, `client_portrait` 세 줄, `NO_PORTRAIT` 비우기", 그림 3 · 몫 5)이다. 옛 이름 046b를 이어받는다(052 결정 822). 의뢰 · 사연 · 일정은 건드리지 않는다(056~059).
- 시작점: **053b가 끝난 커밋**(HEAD는 작업 0이 읽는다. 지금 `c87c7dc` 위에서 053b가 도는 중이다). 기대: `ALL PASS 166/166`, 결정 862까지. 그림 생성은 한 번에 하나만 한다 — 053b의 마지막 Codex 호출과 커밋이 끝난 뒤에 이 계획의 작업 0을 시작한다.
- 이 계획의 번호: **결정 863~878, 테스트 T167**(H02는 920~926 · T210~T212, R02b는 900~908 · T200~T206을 잡아 두었다).
- 근거:
  - 052 결정 817(의뢰인 셋을 각 한 장 450×675로, 장 3 · 몫 5, 코드는 `client_portrait` 세 줄과 `counter_art_tests`의 목록 옮김)과 813-4(완료 기준 — `NO_PORTRAIT`가 빈 목록), 821(묶음의 위쪽 어림 12장 · 몫 20).
  - 실루엣의 씨앗: 046 결정 742 · BACKLOG 046-1(체칠리아 — 작고 등이 굽은 노파, 챙 넓은 양봉 모자와 얼굴 앞의 망사, 손에 연기 깡통 / 레안드로 — 머리보다 큰 분칠한 가발, 코에 댄 향수 손수건, 가는 몸), 049 결정 794 · BACKLOG 049-1(넬라 — 걷어 올린 소매의 굵은 팔, 머릿수건, 허리에 감은 젖은 앞치마, 빨래 방망이. 토마소 · 체칠리아 · 오르솔라와 갈리게).
  - 사연(데이터에서 읽음): 체칠리아는 레안드로 백작 댁에 벌통 언덕을 두고 소송 중인 양봉가(`court_beehive`, 상대 세라피나, 안뜰). 레안드로는 빵을 나눠 주는 굴리엘모를 치라는 젊은 백작(`noble_baker`, 뒷골목). 넬라는 염색장 찌꺼기로 빨래터를 잃은, 말이 빠르고 거친 세탁부(`washer_ledger`, 광장, 결정 793 — "-거든요" · "-다니까요").
  - 본보기(시험된 길): 034의 의뢰인 다섯(결정 348 · 349 — 그 사람의 섞은 SVG 스케치 한 장을 화풍의 참고로, 다섯 모두 첫 장에서 맞았다. `GENERATION.md` "계획 034"), 작업 4의 굳은 확인(H3 · H4 · H5 · K1 · K2′ · K3′ · K5 · K6 · G8, 머리 높이 ±15%, 옷 큰 면의 갈림 — 색조 차 ≥ 20° 또는 Y 차 ≥ 0.08, S ≤ 40%, Y ≥ 0.30), 그리고 044b · 045b의 의뢰인 C1a 단계(판 S5: 450×675 · 모서리 알파 0 · 위 4줄 불투명 0 · 좌우 4열 불투명 0, 작업 폴더 `%TEMP%\bravi-style\045b\`의 `genC` · `mC1` · `mC2` · `cutC` · `boardS5`). **045b의 배운 것**: 흰 앞치마가 아래 가장자리로 나가 바탕과 28 안이라 네 가장자리 지우기가 구멍을 냈다 — 위 · 왼 · 오른 가장자리에서만 지웠다(`cutC.ps1`, 바이블 13절 "흰 옷").
  - 034의 배운 것: 사연에 상처를 말하는 글이 있으면 그림 도구가 막을 수 있다 — 같은 프롬프트의 다음 호출은 지나갔다. 생성이 도는 동안 저장소를 고치지 않는다.
  - 바이블 4절: 둥근 모서리의 곧은 꼴(부풀거나 굽이치는 꼴 · 곱슬머리 없음), 홍조 · 땀방울 · 눈물 · 하이라이트 · 볼의 빗금 없음, 의뢰인은 허리 위 · **얼굴이 가려지지 않는다(G8)**, 성격은 표정과 옷 하나 · 소품 하나, 의뢰인에게는 상태 색이 얹히지 않는다. 8절 팔레트와 "새 색을 더할 때". 13절(막는 장치, 넣는 그림은 우리 그림뿐, 프롬프트에 게임 · 작가 이름 없음).
  - 코드와 테스트에서 읽은 사실(planner, 2026-11-28):
    - 그림을 거는 자리: 의뢰 `.tres`의 `[ext_resource type="Texture2D" path="res://assets/art/clients/<이름>.png" id="6_portrait"]`와 `client_portrait = ExtResource("6_portrait")`, `load_steps` +1(`variants/pair_baker.tres`의 꼴). 셋 모두 지금 `load_steps=7`이고 `stage` 줄이 있다.
    - `tests/counter_art_tests.gd`(T77) 9~17행: `PORTRAITS`(의뢰 파일 → 그림 파일, 열다섯 줄)와 `NO_PORTRAIT`(셋). 98행이 의뢰 수 = 둘의 합을 본다. 그림이 생기면 카운터에서 `Body` · `Head` 도형이 사라지고 `Portrait`가 `Ui.CLIENT_ART_RECT`에 선다(81~89행).
    - **그림이 없다고 기대하는 단언이 하나 더 있다**: `tests/week_tests.gd:380`(T159 `_check_washer_data`) `washer.client_portrait == null and not washer.opponent_wears_hat`. 이것을 고치지 않으면 T159가 깨진다(작업 7).
    - `tests/client_shots.gd` 9~17행은 034의 일곱만 찍고 `tests/run_client_shots.ps1` 27행이 `$count = 7`이다. `tests/ui_shots.gd:199`는 실제 의뢰의 그림을 옮겨 쓰므로 `counter-washer-ledger` 등의 장이 그림으로 바뀐다(기대).
    - 의뢰인 그림 열 장(`assets/art/clients/`): 클라라 · 비토리오 · 에밀리오 · 이네스 · 가스파로 · 오르솔라 · 토마소 · 아고스티노 · 베아트리체 · 굴리엘모. 053b가 `cornelia.png`를 더할 수 있다(그 계획의 R7 — 없으면 열).
    - 열의 큰 면과 표정(명세 "의뢰인 다섯의 줄" · 각 C1a 줄): 클라라 올리브 `#6F7F4F`(80°, Y 0.47, 근심) · 비토리오 `#7E4A4A`(0°, 0.33, 반쯤 감은 눈의 능글) · 에밀리오 조끼 `#8A7357`(33°, 0.46, 언짢음) · 이네스 숄 `#5C6F7E`(206°, 0.42, 근심) · 가스파로 조끼 `#5E5A6E`(252°, 0.36, 거만함) · 오르솔라 `#8A5A6E`(335°, 0.40, 언짢음) · 토마소 `#B8A88A`(39°, 0.66, 근심) · 아고스티노 `#B7AD9A`(40°, 0.68, 능청) · 베아트리체 `#5E7F72`(156°, 0.47, 떠보기) · 굴리엘모 `#9AA7AE`(201°, 0.65)와 흰 앞치마(0.93, 들뜸) · 코르넬리아 `#A59EBA`(255°, 0.63, 검사 — 053b가 그리면). "화남"을 쓰는 의뢰인은 없다 — 바이블의 화남 줄은 결투 상대의 표정이다(v2 — D1). 잰 색은 작업 0이 애셋에서 다시 잰다.

### 넘지 않는 선

- 메인은 Godot · 테스트 · 게임을 실행하지 않는다. 확인은 verifier가 **공용 차례표**(`tests/wait_turn.ps1 -MaxWaitSec 150`, 끝나면 실패해도 `-Release`)를 거쳐 한다. playtester는 부르지 않는다. **3분 넘는 명령이 끊긴다** — 테스트는 `run_tests.ps1 -Only` 묶음(대여섯 파일씩), `verify.ps1`은 `-Only <단계>` 하나씩, 찍기는 한 명령씩.
- 그림 생성은 메인이 Codex CLI로(`-m gpt-6.2-sol -c model_reasoning_effort=high`, read-only를 호출마다 명시, `docs/style/tools/run-codex.ps1 -TimeoutSec 170`, 바이블 13.5의 막는 장치). **몫 5장**(셋 + 다시 그리기 2 — 결정 863). 한 사람에 세 장까지(034). **돌리기 전에 장 수(이번 · 쓴 장 · 남은 몫)를 `docs/style/GENERATION.md` "계획 054"에 적는다.** 막힌 호출은 장으로 세지 않는다. 생성이 도는 동안 저장소를 고치지 않는다. 사용자의 Codex 설정은 바꾸지 않는다.
- 넣는 그림은 우리 그림뿐이고(그 사람의 스케치, 다시 그릴 때 직전 그림 또는 `basis/client-vittorio.png`), 프롬프트에 다른 게임 · 작가 이름이 없다(Grep).
- 데이터 · 테스트는 메인이 Sonnet 하위 에이전트에게 작업 하나씩 맡기고 diff로 확인한다.
- **고치지 않는 것**: `scripts/`의 모든 파일(코드 0줄), 의뢰의 사연 · 한마디 · 조건 · 평판 · 상대 · 무대(고치는 것은 `client_portrait`의 두 줄과 `load_steps`뿐), 다른 열 의뢰인의 그림 · 애셋 · 기준 그림, 상대의 데이터 · 그림, 그림 도구(`docs/style/tools/*` — 새 재기는 작업 폴더에), 하루 · 일정, 053b의 계획 · 테스트, `tests/golden/`, **다른 곳의 파일**(`.gitignore`, `docs/plans/H02-*`, `docs/plans/R02b-*`와 그것이 가리키는 변경).

## 목표와 범위

카운터의 마지막 색 도형 셋이 **제 그림**을 얻어, 열셋의 의뢰인이 모두 그림으로 선다(052 완료 기준 4 — `NO_PORTRAIT`가 빈 목록). 셋은 서로와 열(또는 코르넬리아까지 열하나)의 의뢰인과 **나란히 놓아 한눈에 갈린다**.

**확인할 결과**:

1. 판 D0(스케치, 생성 0장)이 결정 871의 굳은 확인을 모두 넘는다 — 그림 몫을 쓰기 전에. 열하나의 같은 자(작업 0)와 견주어 셋의 표지가 그들뿐이다.
2. 그림 셋(`docs/style/basis/client-cecilia.png` · `client-leandro.png` · `client-nella.png`, 1024×1536)이 판 D1~D3을 넘고, 손질본 `assets/art/clients/cecilia.png` · `leandro.png` · `nella.png`(450×675)가 있다.
3. 세 의뢰(`court_beehive` · `noble_baker` · `washer_ledger`)가 그 그림을 걸고, T77의 `NO_PORTRAIT`가 비고, T159 · T167이 통과해 나눈 테스트의 합이 `167/167`이다.
4. 판 D4: 게임의 카운터 찍기(새 셋)와 열넷의 나란히 판에서 셋이 갈린다 — 특히 체칠리아 ↔ 아고스티노 · 클라라 · 베아트리체 · **에밀리오**(대표 면의 색이 가장 빠듯하다), 레안드로 ↔ 가스파로 · 이네스 · 오르솔라, 넬라 ↔ 에밀리오 · 토마소 · 굴리엘모 · **코르넬리아**(053b가 `cornelia.png`를 만들었을 때). 그리고 넬라는 **따지러 온 손님이지 위협하는 사람이 아니다**(결정 867).
5. 몫이 모자라 못 그린 사람이 있으면 그 사람은 도형으로 남고 `NO_PORTRAIT`에 남는다 — 완료 기준 4의 미달을 보고서와 060에 적는다(결정 876).

## 인물 — 씨앗에서 그림이 정하는 것(결정 864~867)

**씨앗에서 바뀌는 넷**(결정 864 — 바이블과 걸린다): ① 체칠리아의 **얼굴 앞 망사** → 앞을 걷어 올려 챙 위에 접어 얹고 양옆과 뒤로만 어깨까지 드리운다(G8: 얼굴이 가려지지 않는다) ② 레안드로의 **코에 댄 손수건** → 코 옆에 가볍게 댄다, 두 눈 · 입이 다 보인다(G8) ③ **분칠한 가발** → 곱슬 · 부푼 덩이가 아니라 곧은 옆면과 둥근 윗면의 높은 덩이, 양옆에 가로로 쌓인 캡슐 말이 셋(바이블 4절 "곱슬머리 · 부푼 꼴 없음") ④ 넬라의 **젖은 앞치마** → 앞치마 아랫부분이 한 단계 짙은 평평한 칠(곧은 윗경계) — 물방울 · 튀김 · 거품은 그리지 않는다(바이블 4절 "땀방울 없음"과 같은 결). 그리고 **벌 · 연기는 그리지 않는다**(사람 · 동물 없음, 부푼 꼴 없음 — 깡통과 풀무가 양봉을 말한다). 메인이 HANDOFF의 판 W2-D-2 줄에 옮긴다.

- **양봉가 체칠리아 — 넓은 챙 아래의 작은 노파**(결정 865): 몸 — 작고 좁은 둥근 어깨, 아주 조금 돌아선 3/4 view에서 굽은 등의 둥근 선이 한쪽 어깨 위로 보인다. **실루엣의 윗부분은 어깨보다 훨씬 넓은 납작한 밀짚 챙**(챙 ÷ 어깨 목표 1.65)이고, 챙에서 양옆 · 뒤로 어깨까지 드리운 민무늬 잿빛 망사가 **종(등갓) 꼴**을 만든다. 챙 아래 관자놀이에 짧은 흰 머리. 옷 — 바랜 장밋빛 흙색 드레스와 숄 깃. 소품 — **연기 깡통(훈연기)**: 세로로 선 작은 주석 원통 + 위의 원뿔 주둥이 + 옆의 작은 나무 풀무, 두 손으로 가슴 앞에 곧게 든다(높이 ÷ 폭 ≥ 1.15 — 베아트리체의 납작한 모자 상자와 갈린다). 표정 — **실눈**(새 줄). 조는 · 무표정한 얼굴이 아니라 **고집 센 노인**으로 읽혀야 한다(v2 — 디자인 비차단): 다문 입의 양 끝을 아주 조금 눌러 내린다. 턱을 살짝 드는 한 획(오르솔라의 "턱 듦"은 목을 길게 세운 꼴 — 그녀는 굽은 등 위에서 턱 끝만 앞으로 내민다)은 스케치에서 시안 둘(입 끝만 / 입 끝 + 턱)로 판 D0에 나란히 두고 메인이 고른다.
- **젊은 백작 레안드로 — 머리보다 큰 가발, 가장 가는 몸**(결정 866): 몸 — 열넷 가운데 가장 좁은 어깨, 긴 가는 목, 맨 얼굴(수염 없음 — 가스파로의 콧수염 · 염소수염과 갈린다). **가발은 얼굴 폭의 1.7배 넓고 얼굴 높이의 0.7만큼 솟는 곧은 옆면의 덩이**, 분칠한 옅은 잿빛(흰색이 아니다), 양옆 귀 위에 가로 캡슐 말이 셋씩. 옷 — 바랜 연보라 깃 높은 저고리와 민무늬 옅은 크라바트. 소품 — **긴 손수건**: 한 손을 들어 코 옆에 가볍게 대고(새끼손가락을 든다), 손수건의 뾰족한 끝이 가슴까지 늘어진다(이네스의 "두 손 가슴 앞의 작은 손수건"과 자리 · 길이 · 색으로 갈린다). 다른 손은 허리 높이. 표정 — **질색**(새 줄 — 가난한 이의 빵 냄새를 맡는 얼굴).
- **세탁부 넬라 — 넓은 어깨, 굵은 맨 팔뚝, 내민 손바닥, 어깨의 방망이**(결정 867): 사연에서 그녀는 염색장 찌꺼기에 빨래터를 잃은 피해자이고, 모은 돈을 들고 토마소를 따라왔다 — 그림이 말할 감정은 **억울함과 빠른 말**이지 위협이 아니다(v2 — D1). 몸 — 넓은 어깨, 팔꿈치 위로 걷어 올린 소매 아래 **굵은 맨 팔뚝**(에밀리오의 소매 끝만 걷은 팔보다 굵다). **다른 손은 손바닥을 위로 향해 앞으로 내민 따지는 손짓**("보세요, 이것 좀") — 열넷 가운데 이 손짓은 그녀뿐이다. 머리 — 머리에 바짝 붙은 바랜 꼭두서니빛 머릿수건, 정수리 매듭(솟지 않는다 — 레안드로의 가발 · 베아트리체의 틀어 올린 머리와 갈린다). 옷 — 바랜 풀빛 몸판, 옅은 셔츠, 허리에 감은 리넨 앞치마(아랫부분이 한 단계 짙은 젖은 칠). 소품 — **빨래 방망이**: 넓적한 나무 판에 짧은 둥근 손잡이, 한 손으로 어깨 위의 손잡이를 쥐고 **판은 어깨 너머 등 뒤로 늘어진다**(얼굴에서 먼 쪽 어깨, 판의 일부가 어깨 바깥으로 보인다 — 치켜든 몽둥이가 아니라 일하다 멘 도구. 굴리엘모의 가로 밀대 · 코르넬리아의 가는 송곳과 넓적한 판으로 갈린다). 표정 — **억울함**(새 줄 — 따지는 중의 열린 입, 이는 보이지 않는다). **공격의 표지는 한 장에 하나까지**: 멘 방망이 하나만 남기고, 허리에 짚은 주먹과 이를 드러낸 입은 쓰지 않는다.

### 열넷의 가름 표(결정 870 — 판 D0 · D4에서 나란히 본다)

| 의뢰인 | 실루엣의 윗부분 | 몸 | 소품(꼴 · 자리) | 대표 면(결정 868) | 표정 |
|---|---|---|---|---|---|
| **체칠리아** | 어깨보다 넓은 납작한 챙 + 어깨까지 드리운 망사(종 꼴) | 작고 좁은 둥근 어깨, 굽은 등(3/4) | 세로로 선 원통 + 원뿔 주둥이 + 풀무, 두 손 가슴 | 장밋빛 흙색 `#C48E80` 12° · Y 0.60 | 실눈(새) |
| **레안드로** | 얼굴 폭 1.7배 · 0.7 솟는 곧은 가발 덩이 | 가장 좁은 어깨, 긴 목, 맨 얼굴 | 한 손을 코 옆에 — 가슴까지 늘어진 긴 손수건 | 연보라 `#8E7493` 290° · 0.49 | 질색(새) |
| **넬라** | 머리에 붙은 머릿수건 · 정수리 매듭 | 넓은 어깨, 굵은 맨 팔뚝, 손바닥을 위로 내민 따지는 손짓 | 어깨에 멘, 판이 등 뒤로 늘어진 넓적한 방망이 | 풀빛 `#749073` 118° · 0.53 | 억울함(새) |
| 클라라 | 리본 모자 | 보통 | 핀 둘, 앞치마 | 올리브 80° · 0.47 | 근심 |
| 비토리오 | 짙은 모자, 털깃 | 넉넉함 | 돈주머니, 금 사슬 | 붉은 고동 0° · 0.33 | 반쯤 감은 눈의 미소 |
| 에밀리오 | 짧은 머리 · 턱수염 | 다부짐, 소매 끝을 걷음 | 옆구리의 천 한 필, 목의 줄자 | 고동 33° · 0.46 | 언짢음 |
| 이네스 | 낮게 묶은 머리 | 보통, 숄 | 두 손 가슴 앞의 작은 손수건 | 청회색 206° · 0.42 | 근심 |
| 가스파로 | 매끈한 짙은 머리, 콧수염 · 염소수염 | 마르고 큼 | 어깨 옆에 든 주사위 | 잿빛 제비꽃 252° · 0.36 | 거만함 |
| 오르솔라 | 높은 쪽머리 | 꼿꼿함, 숄 | 가슴을 가로지른 접은 부채 | 자두색 335° · 0.40 | 언짢음(턱 듦) |
| 토마소 | 헝클어진 짧은 머리 | 마르고 작음 | 두 손에 쥔 납작한 모자 | 잿빛 갈색 39° · 0.66 | 근심 |
| 아고스티노 | 대머리가 솟은 **대칭의 돔 어깨** 사이에, 흰 수염 | 작고 굽음 | 두 손을 포갠 세로 지팡이 | 리넨 잿빛 40° · 0.68 | 능청 |
| 베아트리체 | 틀어 올린 머리와 핀 다섯 | 가는 허리 | 두 손의 납작한 북 꼴 모자 상자 | 병초록 156° · 0.47 | 떠보기 |
| 굴리엘모 | 납작한 흰 천 모자 | 둥근 얼굴, 흰 앞치마 | 두 손의 가로 밀대 | 잿빛 하늘 201° · 0.65 | 들뜸 |
| 코르넬리아(053b) | 낮은 원통 모자, 둥근 안경 | 상자 같은 제복 | 비스듬한 가는 송곳 | 슬레이트 255° · 0.63 | 검사 |

가장 가까운 짝과 가르는 수(굳은 확인 — 결정 871): 체칠리아 ↔ 아고스티노는 **가장 넓은 줄이 챙인가 어깨인가**(챙 ÷ 어깨 ≥ 1.40)와 어깨의 꼴(좁고 처짐 대 솟은 돔 — 눈), ↔ 클라라는 머리 위 덩이 폭 ÷ 어깨가 클라라의 1.15배 이상, ↔ 베아트리체는 소품의 높이 ÷ 폭(≥ 1.15 대 < 1), ↔ **에밀리오**는 대표 면의 색(색조 21° · Y 0.14 — 열넷 가운데 가장 빠듯하다. 판 D1이 잰 색으로)과 머리 위 덩이(챙 대 짧은 머리) · 수염. 레안드로 ↔ 가스파로는 머리 위 덩이(가발이 얼굴 위로 ≥ 0.55 솟음 대 매끈한 머리)와 수염, ↔ 베아트리체 · 오르솔라는 머리 위 덩이 폭 ÷ 얼굴 폭(≥ 1.45이고 그 둘의 1.15배 이상), ↔ 이네스는 손수건의 자리(코 옆)와 길이(≥ 0.8 × 얼굴 높이). 넬라 ↔ 에밀리오는 팔뚝 굵기(그의 1.2배 이상 — 그의 팔뚝이 안 보이면 적기만)와 머릿수건, ↔ 굴리엘모는 소품의 판 폭 ÷ 길이(≥ 0.22)와 방향(가로 대 어깨 너머), ↔ **코르넬리아**(053b가 그렸을 때)는 같은 자(넓적한 판 대 가는 꼬챙이)와 머리 위 덩이(머리에 붙은 수건 대 원통 모자) · 대표 면(118° 대 255°).

## 설계 결정

모두 **메인이 대신 고름(사용자 위임 2026-11-27)**이고 값은 임시다.

863. **몫과 차례**: 셋 각 한 장 + 다시 그리기 2 = 몫 5(052 결정 821). 차례는 작업 0(열하나의 자) → 견본과 판 D0(0장) → 명세 · 바이블의 줄과 프롬프트 셋 → C1a(체칠리아) · 판 D1 → L1a(레안드로) · 판 D2 → N1a(넬라) · 판 D3 → 올리기 → 데이터 · 테스트 → 판 D4. 한 장을 받아야 다음 사람으로 간다. 다시 그리기 둘은 먼저 걸린 사람이 쓴다. **053b가 몫 6을 다 쓰지 않았으면 그 남은 몫에서 빌린다 — 053b는 몫 6 가운데 5장을 써서(커밋 `bfa96cb`, 053b 보고서) 빌릴 수 있는 것은 1장뿐이다**(작업 0이 읽음. 그래서 이 계획의 위쪽은 5 + 1 = 6장. 묶음의 위쪽 어림 12장 · 몫 20 안이고, 057 · 058c의 몫은 건드리지 않는다 — `GENERATION.md` "계획 054"에 "053b의 남은 몫에서"로 적는다). 그래도 모자라면 결정 876. 되돌리기 쉽다(몫의 셈일 뿐).
864. **씨앗에서 바뀌는 넷과 그리지 않는 둘**은 위 "인물" 절의 머리 줄이다. 까닭은 G8과 바이블 4절. 되돌리기: 바이블을 먼저 고쳐야 하는 일이다(판 W2-D-2).
865. **체칠리아의 꼴**은 "인물" 절. 굽은 등은 정면 그림에서 수로 재지 않는다(눈 확인 — 아고스티노와의 가름은 챙이 맡는다). 버린 길: 망사를 얼굴 앞에(G8), 연기 한 줄기(부푼 꼴), 벌 몇 마리(동물 · 덧붙임).
866. **레안드로의 꼴**은 "인물" 절. 가발은 분칠한 옅은 잿빛이고 선으로 두른다(아고스티노의 흰 머리 술과 같은 길 — 머리털 = 선 색의 예외). 손수건은 크라바트와 같은 옅은 청회색이다 — 가발 · 살색과 가장 가까운 팔레트 색으로 갈리게(채널 거리 40 넘게 — 재는 법의 분류). 버린 길: 손수건을 코 앞에(입이 가려진다), 양피지 손수건(가발 `#E2DCCF`와 거리 28 — 분류가 섞이고 이네스와 같은 색), 레이스 · 장신구(바이블).
867. **넬라의 꼴**은 "인물" 절. 걷은 소매는 의뢰인이라 팔 시트의 확인이 없다(045b 결정 726의 사정이 없다). 방망이는 얼굴에서 먼 쪽 어깨에 걸친다(G8). **공격의 표지는 한 장에 하나**(v2 — D1, 메인이 고름): 사연의 그녀는 피해자이고 의뢰인의 감성은 따뜻하다. 그래서 멘 방망이 하나만 남기고 — 판이 등 뒤로 늘어져 치켜든 꼴이 아니다 — 다른 손은 손바닥을 위로 내민 따지는 손짓, 입은 이가 보이지 않는 말하는 중의 열린 네모, 프롬프트의 성격 말은 `indignant`다. 판 D0 · D3의 눈 확인이 "때리러 왔다"로 읽히는 장을 거른다. 걸리면 쓰는 `Change:` 한 줄(몫 안에서 다시 뽑는 1장 — 결정 876): `Change: she has come to complain, not to fight. Her mouth is open in mid-sentence with no teeth showing, her free hand is held out palm up as if saying look at this, and the beater lies on her shoulder with its paddle hanging down behind her back. Nothing about her looks threatening.` 버린 길: 허리에 짚은 주먹 · 이를 드러낸 화남(v1 — 셋이 겹쳐 위협으로 읽힌다), 방망이를 치켜세우기, 방망이를 몸 앞에 가로로(굴리엘모의 밀대와 겹친다), 두 손으로 빨래 바구니(이네스 · 토마소의 두 손 가슴 앞과 겹친다), 앞치마에 물방울.
868. **색 — 대표 면 하나씩과 딸린 면**(034 결정 348의 규칙: 대표 면이 열하나의 대표 면 · 셋끼리 색조 차 ≥ 20° 또는 Y 차 ≥ 0.08, S ≤ 40%, Y ≥ 0.30, 신호 구역 밖. 새 색은 명세의 팔레트에 먼저 더한다):

     | 사람 | 대표 면(칠 / 그림자) | 딸린 면 | 대표 면의 셈(가장 가까운 것) |
     |---|---|---|---|
     | 체칠리아 | 장밋빛 흙색 `#C48E80` / `#A6766A`(12°, S 35%, Y 0.60 / 0.50) | 밀짚 챙 `#A8895E` / `#8C7050`, 망사 `#B8B2A6` / `#9E988C`, 주석 `#7F7B74` / `#67635D`, 풀무 `#7A5232`, 머리 `#E2D3B4` | 에밀리오(33°, 0.46) 색조 21°, 비토리오(0°, 0.33) Y 0.27, 토마소(39°) 27°, 오르솔라(335°) 37° |
     | 레안드로 | 연보라 `#8E7493` / `#76607A`(290°, S 21%, Y 0.49 / 0.40) | 가발 `#E2DCCF` / `#C8C0B0`, 손수건 · 크라바트 `#B9C4CC` / `#9EAAB3` | 가스파로(252°) 38°, 코르넬리아(255°) 35°, 오르솔라(335°) 45° |
     | 넬라 | 풀빛 `#749073` / `#5E7A5E`(118°, S 20%, Y 0.53 / 0.45) | 머릿수건 `#9C7068` / `#80594F`, 셔츠 `#E2D3B4`, 앞치마 `#C8BFAE` / `#ADA391` · 젖은 아랫부분 `#958B78`, 방망이 `#A8895E` / `#8C7050`, 살 그림자 `#C98E66` | 클라라(80°) 38°, 베아트리체(156°) 38° |

     - 까닭: 열하나의 대표 면이 0 · 33~40 · 80 · 156 · 201~206 · 252~255 · 335°에 있어 비어 있는 띠는 100~136°(풀빛)와 275~315°(연보라)뿐이다. 셋째(체칠리아)는 붉은 쪽에서 밝기로 가른다(12° — 비토리오와 Y 0.27, 에밀리오와 색조 21°이고 Y 0.14).
     - 생성 그림은 색조 ±7° · Y ±0.07 흔들린다(044b). 체칠리아 ↔ 에밀리오가 가장 빠듯하다(둘 다 최악으로 흔들리면 걸린다) — 판 D1이 잰 색으로 다시 셈하고, 걸리면 `Change:` 한 줄로 색을 다시 준다(다시 그리기 1장).
     - 딸린 면은 적기만 한다(굳은 확인이 아니다 — 대표 면의 규칙을 열넷의 모든 면에 걸면 양피지 셔츠가 서로 걸려 넘을 수 없다). 셋끼리의 딸린 면(체칠리아의 드레스와 넬라의 머릿수건 — 9°, Y 0.13)은 같은 날(052 초안 10일차)에 설 수 있어 판 D4에서 눈으로 본다.
869. **표정**: 바이블 4절 표에 세 줄을 더한다(명세에 먼저). **실눈** — 눈썹 평평한 짧은 막대 둘 · 눈 짧은 곧은 가로선 둘(햇빛을 보는 실눈 — 두 눈 다) · 입 굳게 다문 작은 곧은 선, 양 끝이 아주 조금 눌려 내려감(v2 — 고집. 언짢음의 "아래로 굽은 선"보다 곧다). 집중(한 눈 감음) · 능청(위로 굽은 선) · 거만함(아래로 휜 반달)과 눈의 꼴로 갈린다. **질색** — 눈썹 둘 다 높이 든 곧은 막대 · 눈 점의 위 절반을 곧은 눈꺼풀 선이 덮는다 · 입 아래로 굽은 작게 오므린 호. 거만함(평평한 눈썹 · 반달 눈) · 언짢음(안쪽이 내려온 눈썹)과 눈썹 · 눈으로 갈린다. **억울함**(v2 — D1. 넬라) — 눈썹 안쪽 끝이 들린 곧은 막대 둘(바깥 끝은 수평) · 눈 점 · 입 말하는 중에 열린 둥근 모서리의 가로 네모, 안은 선 색, **이는 보이지 않는다**. 근심(작은 곧은 선 입)과는 열린 입으로, 들뜸(높이 든 호 · 반달 웃음)과는 곧은 눈썹 · 네모 입으로, 화남(안으로 내려온 눈썹 · 이를 드러낸 네모)과는 눈썹의 방향 · 이로 갈린다. 바이블의 화남 줄은 결투 상대의 표정이라 의뢰인에게 쓰지 않는다.
870. **열넷의 가름 표**는 위 표다. 판 D0(스케치)과 D4(게임)에서 열넷을 한 줄로 나란히 놓고 한 색 실루엣 줄도 둔다.
871. **판 D0~D4의 굳은 확인**은 아래 "그림" 절의 표와 재는 법이다. 넘을 수 없는 자를 두지 않는다 — 열하나에 견주는 문턱은 작업 0이 그들을 잰 뒤에 스케치 단계에서 맞추고(0장), 맞출 수 없으면 멈춘다(작업 0 ③).
872. **바탕 지우기**: 045b `cutC.ps1`을 옮겨 쓴다. 아래 가장자리에 닿는 칠 가운데 잰 바탕과 채널 차 28 안인 것이 있으면 아래 가장자리를 지우기의 시작에서 뺀다(045b). 셋의 아래 가장자리의 칠(드레스 · 저고리 · 앞치마)은 바탕(`#D2D1D1` 언저리)과 모두 28 넘게 떨어지므로 네 가장자리가 기본이다. 바탕과 가까운 칠(가발 `#E2DCCF` — 16, 손수건 `#B9C4CC` — 25)은 **닫힌 선 안**이어야 한다: 지운 뒤 **안쪽 구멍 0**(알파 0인 화소 가운데 그림의 바깥 테두리와 4-이웃으로 이어지지 않은 것 0)과 위 4줄 불투명 0(가발 · 챙 · 방망이가 틀 안)을 굳은 확인으로 본다.
873. **프롬프트**: 본보기는 `prompts/034-E1a-client-emilio.txt`의 차례(한 장 — 넣는 그림은 그 사람의 스케치 하나, 결정 349). 바꾸는 줄은 034와 같다(`Subject:`, 구도 첫째 · 둘째, 표정 문장, 셋째 · 다섯째 항목, 색). 화풍의 첫째 항목만 042 의뢰인 줄의 첫째 항목(곧은 변 · 둥근 모서리, 부풀거나 굽이치는 꼴 없음)을 그림 이름 `the attached image`로 옮겨 쓴다 — 가발 · 망사 · 앞치마가 부풀지 않게. 이 줄은 명세 "계획 054의 줄"에 먼저 적는다(결정 195). `Subject:`에는 직업 · 몸 · 옷 · 소품만 쓰고 **사연(소송 · 결투 · 다리를 치라는 부탁)을 쓰지 않는다**(034의 배운 것 — 막힘). 영어 · ASCII · 큰따옴표 없음. **없어야 할 말**(바꾸는 줄에서 Grep — 막는 구절 "No …" · "no …" · "with no …" 안의 말은 뺀다. 바꾸지 않는 블록의 "no curls" 등도 그대로): `curly` · `curled` · `ringlet` · `puffy` · `ruffle` · `frill` · `lace`(막는 말 "No lace" 밖) · `blush` · `rosy` · `beauty mark` · `bees` · `insect` · `smoke rising` · `cloud` · `drop` · `drip` · `splash` · `foam` · `sweat` · `club` · `bat` · `beat ` · `beating` · `weapon` · `sword` · `over her face` · `covering`, 그리고 넬라의 바꾸는 줄에서만 `angry` · `teeth` · `fist` · `hip` · `raised`(v2 — D1).
874. **데이터 · 테스트**: 의뢰 셋에 그림 두 줄씩(`load_steps` 7 → 8), T77의 표 옮김(`PORTRAITS`에 세 줄, `NO_PORTRAIT := []`과 주석 한 줄 "그림이 없는 의뢰. 054가 비웠다 — 새 의뢰인이 그림 없이 들어오면 여기에 적는다"), T159의 단언 한 줄(`nella.png`이고 모자를 쓰지 않는다), 새 T167, 카운터 찍기에 셋(`client_shots.gd` 세 줄, `run_client_shots.ps1`의 `$count` 7 → 10과 머리 주석), `ui_shots.gd`의 장 설명 글 둘(v2). `.png.import`는 미리 쓰지 않고 Godot이 가져오게 둔다(034 결정 353 — 밉맵 끔). `day_ui.gd` · `commission.gd`는 0줄.
875. **확인을 나눈다 — 차례표를 거친다**: 053b 결정 857 그대로. Codex 생성은 Godot이 아니라 차례표를 거치지 않는다.
876. **걸리면**: 굳은 확인에 걸린 그림은 한 번 다시 뽑는다(몫 안에서). 한 가지만 어긋나면 직전 그림과 `Change:` 한 줄(바이블 13.2 — 넬라가 위협으로 읽히면 결정 867의 줄), 화풍이 기준과 다르면(K2′ · K5가 클라라 · 비토리오의 받은 범위 밖, 둥글둥글 · 각짐) `basis/client-vittorio.png`를 둘째 그림으로 더해 새로(034 결정 349). 크기 · 자리만 걸리면 손질(`fitclient.ps1`)의 상자로 맞추지 않는다 — 자리는 그림의 일이다. **몫을 다 쓰고도 한 사람이 넘지 못하면**: 그 사람은 도형으로 남고 그의 의뢰는 `NO_PORTRAIT`에 남는다(T77 · T159는 그 사람의 줄을 고치지 않는다). 완료 기준 4의 미달을 보고서 · HANDOFF에 적고 060이 대조한다. 057 · 058c의 몫을 당겨 쓰지 않는다.
877. **다른 세션과의 겹침**: 아래 절.
878. **판 W2-D**: 아래 "나중에 사용자가 볼 판".

## 그림(결정 863 · 871)

**판정은 메인이 한다**(사용자 위임). "맞다"는 굳은 확인을 모두 넘고 눈 확인에 걸리는 것이 없다는 뜻이다. 넘은 그림을 `docs/style/basis/client-<이름>.png`(원본 그대로)로 올리고 `basis/README.md`에 "메인이 대신 판정(사용자 위임 2026-11-27) — 판 W2-D에서 사용자가 본다"고 적는다. 작업 폴더는 `%TEMP%\bravi-style\054\` — 045b의 `genC.ps1`(호출 전후 `git-before.txt` · `git-after.txt`, `-TimeoutSec 170`) · `mC1.ps1` · `mC2.ps1` · `cutC.ps1` · `boardS5.ps1`과 053b의 `genlib.ps1` · `mEye.ps1`을 옮겨 이름과 경로만 바꾸고, 새 자는 새 스크립트(`mFace` · `mTop` · `mProp` · `mArm` · `mHole` · `mCol` · `boardD*`)로 쓴다. 저장소의 그림 도구는 고치지 않는다. 모든 자는 **450×675 손질본**에서 잰다(열하나는 `assets/art/clients/`의 애셋, 새 셋은 지운 1024×1536을 `fitclient.ps1`로 줄인 장, 스케치도 같은 길로).

| 판 | 무엇을 나란히 | 굳은 확인(수) | 눈 확인 |
|---|---|---|---|
| **D0** 스케치(0장) | 열하나의 애셋과 셋의 스케치를 카운터 방(`assets/art/counter/room.png` · `front.png`, 게임의 자리 — 1920에서 (120, 180) 450×675)에 한 줄로. 둘째 줄은 같은 열넷의 한 색 실루엣. 셋째 줄은 가장 가까운 짝 — 체칠리아 · 아고스티노 · 클라라 · 베아트리체 · 에밀리오 / 레안드로 · 가스파로 · 이네스 · 오르솔라 / 넬라 · 에밀리오 · 토마소 · 굴리엘모 · 코르넬리아(`cornelia.png`가 있을 때). 넷째 줄은 시안 — 체칠리아의 입 끝만 / 입 끝 + 턱(결정 865의 비차단) | 셋 모두: ⓐ 얼굴 높이 Fh가 클라라 · 비토리오 평균의 ±15% ⓑ 대표 면의 규칙(결정 868, 스케치의 칠로) ⓒ 위 4줄 불투명 0, 위쪽 450행의 좌우 4열 불투명 0, 위 두 모서리 알파 0 ⓓ 안쪽 구멍 0 ⓔ 얼굴 상자 안의 소품 · 망사 · 가발 화소 0(재는 법 ③ — 레안드로의 손수건은 눈 · 입 상자 밖) ⓕ 사람마다의 표지(아래) | 셋이 열하나와 섞여도 누구인지 가려진다 — 특히 "가장 가까운 짝" 줄. 표정 셋이 표의 줄로 읽히고 열하나의 표정과 갈린다. 체칠리아가 조는 · 무표정한 얼굴이 아니라 고집 센 노인이다(시안 둘 가운데 고른다). 망사 · 가발이 부풀거나 굽이치지 않는다. 방망이가 무기(몽둥이)가 아니라 빨래 도구로, 깡통이 연기 깡통으로 읽힌다. **넬라는 따지는 손님이지 위협하는 사람이 아니다 — 입 · 방망이 · 손이 한 장에서 "때리러 왔다"로 읽히면 걸린다**(v2 — D1) |
| **D1** 체칠리아 | 스케치 · 생성 C1a · 지운 450 · 아고스티노 · 클라라 · 베아트리체 · 에밀리오(같은 배율) | 034 작업 4의 굳은 확인(H3 · H4 · H5 · K1 · K2′(부드러움) · K3′ · K5(스케치와의 비를 적는다) · K6 · G8) + D0의 ⓐ~ⓕ를 잰 색으로 + 체칠리아의 표지. 에밀리오와의 대표 면은 잰 색 둘로 다시 셈한다 | 망사가 얼굴을 덮지 않고 챙 위에 걷혀 있다 / 챙이 납작하고 넓다 / 굽은 등 / 실눈이 조는 얼굴이 아니라 고집으로 / 연기 · 벌이 없다 / 깡통의 주둥이와 풀무 / 에밀리오와 옷 색이 갈린다 |
| **D2** 레안드로 | 스케치 · 생성 L1a · 지운 450 · 가스파로 · 이네스 · 오르솔라 | 같은 034의 확인 + ⓐ~ⓕ + 레안드로의 표지 | 가발이 곱슬 · 부풂이 아니라 곧은 덩이와 가로 말이다 / 흰색이 아니라 분칠한 잿빛 / 손수건이 코 옆에 있고 입이 보인다 / 새끼손가락 / 질색 / 수염 없음 |
| **D3** 넬라 | 스케치 · 생성 N1a · 지운 450 · 에밀리오 · 토마소 · 굴리엘모 · 코르넬리아(있을 때) | 같은 034의 확인 + ⓐ~ⓕ + 넬라의 표지 | **넬라는 따지는 손님이지 위협하는 사람이 아니다 — 입 · 방망이 · 손이 한 장에서 "때리러 왔다"로 읽히면 걸린다**(결정 867의 `Change:` 한 줄로 다시 — v2 D1) / 팔꿈치 위로 걷은 소매와 굵은 맨 팔뚝 / 손바닥을 위로 내민 따지는 손짓 / 머릿수건이 머리에 붙어 있다 / 방망이가 얼굴에서 먼 어깨에 멘 채 판이 등 뒤로 늘어지고 빨래 도구로 읽힌다 / 앞치마의 젖은 칠이 그림자와 갈린다(못 갈려도 받는다 — 적기만) / 억울함(이가 보이지 않는다) / 물방울 · 얼룩이 없다 |
| **D4** 게임 | 카운터 찍기 세 장(`run_client_shots.ps1 -Shots`, 1280×720 — 새 셋)과 D0의 첫 두 줄을 생성 그림으로 다시 | `portrait,` 상자 셋이 (80, 120) 300×450 ± 2(찍기 도구가 판정), 찍은 장의 의뢰인 자리에서 얼굴 상자가 앞 띠(`COUNTER_FRONT_Y`) 위 | 열넷이 한눈에 갈린다(결정 870의 표 — 짝 목록은 D0의 셋째 줄과 같다: 체칠리아 ↔ 에밀리오, 넬라 ↔ 코르넬리아 포함). 넬라 · 체칠리아의 붉은 면이 같은 날에 나란히 서도 갈린다. 카운터의 넬라가 위협으로 읽히지 않는다(D3과 같은 줄). 패널 · 이름 글이 그림과 겹쳐 읽히지 않는 곳이 없다 |

**사람마다의 표지 — ⓕ**(D0 · D1~D3에서 굳은 확인. 스케치의 목표는 괄호):

- **체칠리아**: 챙 폭 ÷ 어깨 폭 ≥ 1.40(1.65)이고 열하나의 같은 비의 가장 큰 값 × 1.15 이상 · 챙 두께 ÷ 챙 폭 ≤ 0.12(0.07) · 망사 부류 화소가 얼굴 상자 안에 0 · 깡통 덩이(주석 + 풀무 부류)의 높이 ÷ 폭 ≥ 1.15(1.4)이고 그 위 끝이 턱보다 아래 · 깡통 상자가 얼굴 상자와 겹치지 않는다.
- **레안드로**: (얼굴 위 끝 − 가발 위 끝) ÷ Fh ≥ 0.55(0.70) · 가발 폭 ÷ 얼굴 폭 ≥ 1.45(1.70)이고 열하나의 "머리 위 덩이 폭 ÷ 얼굴 폭"의 가장 큰 값 × 1.15 이상(덩이 자 — 7×7로 연 가장 큰 덩이, 결정 871a: 토마소 1.418 × 1.15 = 1.631. 원래 자로는 베아트리체의 모자핀 2.496이라 넘을 수 없다) · 가발 덩이(가발 부류 + 4단위 안의 선)의 채움 ÷ 볼록 껍질 넓이 ≥ 0.85(0.93 — 곱슬 · 굽이치는 덩이는 오목이 많아 낮다) · 어깨 폭 ÷ 얼굴 폭 ≤ 열하나의 가장 작은 값(목표는 그 0.92배) · 어깨 폭 ÷ 가발 폭 ≤ 1.25 · 손수건 덩이의 높이 ≥ 0.8 Fh이고 그 상자가 얼굴 상자와 겹친다(코 옆) · 손수건 화소가 눈 상자(+3px) · 입 상자 안에 0 · 입 덩이가 있다.
- **넬라**: (얼굴 위 끝 − 머릿수건 위 끝) ÷ Fh ≤ 0.35(0.22) · 팔뚝 굵기(얼굴 밖의 가장 큰 살 덩이에서 그 덩이의 긴 축에 수직으로 잰 폭의 가운데 값) ÷ 얼굴 폭 ≥ 0.30(0.38)이고 에밀리오의 같은 값 × 1.2 이상(그의 팔뚝 덩이가 없으면 적기만) · 방망이 덩이(나무 부류 + 선 — 보이는 부분)의 긴 축 길이 ≥ 1.0 Fh(1.2), 판의 가장 넓은 폭 ÷ 길이 ≥ 0.22(0.30), 판 폭 ÷ 손잡이 폭(가운데 값) ≥ 2.0, 판 폭 ≥ 0.35 × 얼굴 폭(등 뒤로 늘어져도 어깨 바깥에 판이 보인다), **손잡이 쪽 끝이 어깨 줄 언저리(어깨 줄 ± 0.5 Fh)이고 판 쪽 끝이 그보다 아래**(늘어진다 — 치켜든 꼴이면 판 쪽 끝이 위다, v2 — D1), 긴 축이 세로에서 0~40° · 방망이 상자와 얼굴 상자 사이 ≥ 0.1 × 얼굴 폭 · **입 덩이 안의 밝은 화소(Y ≥ 0.70 — 이) ≤ 입 덩이 상자 넓이의 5%**(이가 보이지 않는다, v2 — D1).

**재는 법**(문턱은 053b와 같다: 불투명 = 알파 ≥ 128, 선 = Y < 0.22, 덩이는 8-이웃):

- ① **분류**(`mCol.ps1`): 선을 먼저 빼고, 남은 칠 화소마다 그 그림의 팔레트(결정 868의 hex — 생성 그림은 메인이 장에서 상자로 찍어 잰 색으로 바꾼다)에서 가장 가까운 색의 부류로 가른다. 가장 가까운 색과의 거리가 40을 넘으면 "기타". **분류의 확인**: 스케치에서 칠한 자리 밖에서 그 부류로 분류된 화소 0(053b의 길). 열하나는 명세의 그 사람 색 블록이 팔레트다.
- ② **얼굴**(`mFace.ps1`): `mEye`가 찾은 두 눈 덩이를 품는 살 부류 덩이의 상자 — 위 끝 Ft, 턱 Fb, 높이 Fh, 폭 Fw. 눈 상자 = 눈 덩이의 상자, 입 덩이 = 얼굴 상자 안에서 눈 줄 아래의 가장 큰 선 덩이. 실눈 · 질색의 눈은 선이라 `mEye`가 짧은 가로 선 덩이를 잡게 문턱을 그 사람에만 바꾸고 적는다.
- ③ **머리 위 덩이와 어깨**(`mTop.ps1`): 머리 위 덩이 = Ft 위의 불투명 화소(챙 · 가발 · 머릿수건 · 모자 · 머리털). 그 폭 = 줄마다 잰 가장 넓은 폭, 위 끝 = 첫 불투명 행. 어깨 줄 = Fb + 0.5 Fh, **어깨 폭** = 그 줄의 "몸 부류"(옷의 칠 · 그림자 · 셔츠 · 살 — 소품 · 머리털 · 가발 · 망사 부류를 뺀다) 화소의 가장 왼쪽 ~ 가장 오른쪽. 챙 두께 = 챙 양 끝의 안쪽 10% 열에서 잰 챙 부류의 세로 길이의 평균. 작업 0은 열하나에 같은 자(머리 위 덩이 폭 ÷ 어깨 폭, ÷ 얼굴 폭, 어깨 폭 ÷ 얼굴 폭, Fh)를 대고 표로 적는다.
- ④ **소품**(`mProp.ps1`): 소품 부류 덩이(+ 4단위 안의 선)의 상자 · 높이 ÷ 폭 · 긴 축(공분산의 첫 고유벡터)의 길이와 각 · 긴 축에 수직인 폭(가장 넓은 값과 가운데 값). 방망이의 손잡이 폭 = 긴 축의 손 쪽 30% 구간의 폭의 가운데 값, 판 폭 = 나머지 70% 구간의 가장 넓은 값.
- ⑤ **팔뚝**(`mArm.ps1`): 얼굴 덩이가 아닌 살 부류 덩이 가운데 가장 큰 것(손이 붙어 있으면 그대로)의 긴 축에 수직인 폭의 가운데 값. 열하나는 에밀리오만 잰다.
- ⑥ **구멍**(`mHole.ps1`): 지운 장에서 알파 0인 화소를 바깥 테두리에서 4-이웃으로 채운 뒤 남은 알파 0 화소의 수.
- ⑦ 034의 확인(H3 · H4 · H5 · K1 · K2′ · K3′ · K5)은 045b의 `mC1.ps1`(`measure.ps1 -Cut`, `kmeasure.ps1`, `fitclient.ps1`, 위 4줄 · 좌우 4열 · 모서리)을 옮겨 쓴다. 좌우 4열은 위쪽 450행만 본다(아래쪽의 옷 · 팔꿈치 · 넬라의 내민 손이 가장자리에 닿을 수 있다 — 그것은 받는다).

**프롬프트의 뼈대**(결정 873 — 사람마다 바꾸는 줄. 나머지는 034 E1a 그대로):

```
(Cecilia - Subject)
Subject: Cecilia, a beekeeper from a Renaissance-era Italian town, a small old woman with narrow rounded shoulders and a slightly bent back, seen in a slight three-quarter view. She wears a wide flat straw beekeeper's hat whose brim is much wider than her shoulders. A plain grey veil hangs from the brim at the sides and at the back down to her shoulders; at the front the veil is lifted and folded up onto the brim, so her whole face is uncovered. Short pale hair shows at her temples under the brim. She wears a plain faded rose-clay dress with a simple shawl collar. With both hands in front of her chest she holds a small bee smoker upright: a tin can with a cone-shaped spout on top and a small pair of wooden bellows on its side.
(expression) Her eyebrows are short flat bars. Her eyes are two short straight horizontal lines, squinting as if in bright sun. Her mouth is a small firmly closed line with its corners pressed slightly down. Her character shows in the expression: stubborn, patient and unafraid, wide awake.
(details) Add only a little detail inside the shapes: one band around the crown of the hat, the folded edge of the lifted veil on the brim, the seam of the tin can, two short lines on the bellows, one or two short fold lines on the dress. Nothing else is added. No mesh pattern, no smoke, no flowers, no wrinkles.
(colors) faded rose-clay C48E80 with shadow A6766A for the dress, ochre brown straw A8895E with shadow 8C7050 for the hat, plain grey B8B2A6 with shadow 9E988C for the veil, dull pewter 7F7B74 with shadow 67635D for the tin can, wood brown 7A5232 for the bellows, pale parchment E2D3B4 for the hair, skin EBC49F.

(Leandro - Subject)
Subject: Leandro, a young count from a Renaissance-era Italian town, a thin young man with very narrow shoulders and a long thin neck, clean-shaven. On his head sits a huge powdered wig, wider than his head and rising high above it: one tall block with straight sides and a rounded flat top, with three plain horizontal rolls stacked on each side over the ears. He wears a fitted faded mauve coat with a high collar and a plain pale cravat. One hand is raised to his face and holds a long pale handkerchief lightly against the side of his nose, with the little finger lifted; the handkerchief hangs down in a long point to his chest. His eyes and his mouth stay uncovered. His other hand rests at his waist.
(expression) Both of his eyebrows are straight bars raised high. His eyes are two dots, each half covered by a straight heavy eyelid line. His mouth is a small pursed curve turned down. His character shows in the expression: fastidious and disgusted.
(details) Add only a little detail inside the shapes: the three rolls on each side of the wig, two or three coat buttons, the fold of the cravat, one fold line on the handkerchief. Nothing else is added. No ruffles, no jewelry, no extra wrinkles.
(colors) faded mauve 8E7493 with shadow 76607A for the coat, pale powder grey E2DCCF with shadow C8C0B0 for the wig, pale blue-grey B9C4CC with shadow 9EAAB3 for the handkerchief and the cravat, skin EBC49F.

(Nella - Subject)
Subject: Nella, a washerwoman from a Renaissance-era Italian town, a strong young woman with broad shoulders and thick, strong forearms. Her sleeves are rolled up above the elbows, showing her bare forearms. Her hair is tied up under a plain headscarf that fits close to her head and is knotted at the top. She wears a faded leaf green bodice over a pale shirt, and a plain linen apron wrapped around her waist; the lower part of the apron is soaked and is one flat darker tone. A flat wooden laundry beater lies on her shoulder on the side away from her face: one hand holds its short round handle at the shoulder, and the broad flat paddle, a washing tool for linen, hangs down behind her back, with part of it showing beside her shoulder. Her other hand is held out in front of her, palm up, as if saying look at this.
(expression) The inner ends of her eyebrows are lifted, two straight bars. Her eyes are two dots. Her mouth is open in mid-sentence, a small rounded rectangle filled with the same dark brown as the outlines, with no teeth showing. Her character shows in the expression: indignant, quick and outspoken, a wronged customer who has come to complain.
(details) Add only a little detail inside the shapes: the rolled cuffs above the elbows, the knot of the headscarf, the tie of the apron at the waist, one or two straight grain lines on the beater, one or two short fold lines on the shirt. Nothing else is added. No water, no splashes, no stains, no extra wrinkles.
(colors) faded leaf green 749073 with shadow 5E7A5E for the bodice, faded madder red 9C7068 with shadow 80594F for the headscarf, pale parchment E2D3B4 for the shirt, linen C8BFAE with shadow ADA391 for the apron and darker linen 958B78 for its soaked lower part, wood A8895E with shadow 8C7050 for the beater, skin EBC49F with shadow C98E66 for the face and the forearms.
```

구도 둘째 항목은 034의 줄을 사람마다 바꾼다: 체칠리아 `both hands visible above waist level, holding the smoker in front of her chest`, 레안드로 `one hand raised to the side of his nose and the other hand at waist level`, 넬라 `one hand on the handle of the beater at her shoulder and the other hand held out palm up in front of her`. 체칠리아의 표정 문장의 입은 판 D0에서 고른 시안대로 `Her mouth is a small firmly closed line with its corners pressed slightly down.`(+ 턱 시안이면 `Her chin juts forward a little.`). 다섯째 항목(짙은 덩이): 체칠리아 "The crown band of the hat is the same very dark brown as the outlines. The veil is one flat plain grey.", 레안드로 "The wig is pale powder grey, not white, drawn with the dark outline.", 넬라 "The soaked lower part of the apron is one flat darker linen tone with a straight upper edge." 색 블록의 둘째 줄은 비토리오와 같다. 위 초안의 말은 작업 2가 명세에 먼저 적으면서 다듬어도 되고, "없어야 할 말"의 Grep은 다듬은 글에 건다.

## 테스트(결정 874)

| ID | 파일 | 이름 | 보는 것 |
|---|---|---|---|
| T77(고침) | `tests/counter_art_tests.gd` | — | `PORTRAITS`에 `"court_beehive.tres": "cecilia.png"`, `"noble_baker.tres": "leandro.png"`, `"washer_ledger.tres": "nella.png"`. `NO_PORTRAIT := []`(타입 그대로)과 주석 한 줄. 나머지 본문은 그대로 — 세 의뢰의 카운터 · 정산에서 `Portrait`가 서고 도형이 없다는 것을 기존 단언이 본다 |
| T159(고침) | `tests/week_tests.gd:380` | — | `washer.client_portrait != null and washer.client_portrait.resource_path.get_file() == "nella.png" and not washer.opponent_wears_hat`, 글 "[①] 그림이 nella.png가 아니거나 모자를 쓴다". 이 한 줄만 |
| **T167**(새) | `tests/counter_art_tests.gd`(`list()`에 한 줄, 함수 하나) | 의뢰인과 그림: 이름 하나에 그림 하나, 새 셋의 틀 | ① 모든 의뢰(바탕 + `variants/`)에서 `client_name` → 그림 파일이 한 값이고(그림이 없는 의뢰는 빈 값을 한 값으로 센다 — 같은 사람의 의뢰가 그림 있음 · 없음으로 갈리면 걸린다), 그림 파일 → `client_name`도 한 값이다 — **이 역방향 표에서는 `client_portrait == null`인 의뢰를 뺀다**(v2 — 기술 비차단: 결정 876으로 둘 이상이 도형으로 남으면 빈 값 하나에 이름 둘이 붙는 거짓 실패가 난다). 지금 열셋 ↔ 열셋. 베아트리체 · 굴리엘모 · 클라라 · 비토리오는 의뢰 둘 이상이 같은 그림 ② `assets/art/clients/`의 `.png` 가운데 어느 의뢰도 쓰지 않는 것은 `INFO T167` 줄로만 적는다(053b의 `cornelia.png`는 057이 건다) ③ `cecilia.png` · `leandro.png` · `nella.png`의 `get_image()`(T77의 꼴로 `is_compressed()`면 `decompress()` — v2 기술 비차단)에서 위 두 모서리 알파 0, 위 4줄의 알파 ≥ 128 화소 0, 위쪽 450행의 좌우 4열의 알파 ≥ 128 화소 0(결정 872 — 챙 · 가발 · 방망이가 틀 안). 세 파일 가운데 없는 것(결정 876)은 ③을 건너뛰고 `INFO` 줄 |
| (찍기) | `tests/client_shots.gd` · `tests/run_client_shots.ps1` | — | `SHOTS`에 `counter-cecilia` · `counter-leandro` · `counter-nella`(각 의뢰 경로), `$count = 10`과 머리 주석의 "7 shots" · "seven"을 10으로(ASCII). 결정 876으로 못 그린 사람이 있으면 그 줄은 넣지 않는다(도형은 `portrait,` 줄을 내지 않아 판정이 깨진다) |
| (장 설명) | `tests/ui_shots.gd` 599 · 608행 | — | 장 설명 글 "(체칠리아, 색 도형)" · "(레안드로, 색 도형)"의 "색 도형"을 "그림"으로(v2 — 기술 비차단. 낡은 말). 그 글을 기대값으로 맞추는 곳이 없는지 작업 0이 Grep한다 — 있으면 고치지 않고 적는다. 못 그린 사람의 줄은 그대로 |

합: 053b 끝의 166 + T167 = **167**.

## 작업 목록

차례대로 한다. 완료 확인은 메인의 diff · 파일 읽기와 재기 도구의 수이고, 실행 확인은 "확인" 절에 모은다.

| # | 작업 | 대상 | 의존 | 완료 확인 |
|---|---|---|---|---|
| 0 | **사전 읽기와 시작 상태**(고치지 않는다): ① HEAD가 053b의 끝 커밋이고 `ALL PASS 166/166`(053b 보고서), 결정 862까지, `git status`에 남은 것이 알려진 다른 곳의 파일(`.gitignore`)뿐 — 목록을 기록에(R8의 바탕). 053b가 쓴 장과 남은 몫(결정 863의 빌림), `cornelia.png`가 있는지 ② `~/.codex/config.toml`의 해시(바이블 13.5의 처음 값과 대조), 의뢰인 애셋 열(또는 열하나) · `basis/client-*` · 카운터 방 두 장의 SHA-256 ③ **열하나의 표**(재는 법 ①~③ · ⑤): Fh · Fw · 머리 위 덩이 폭 · 어깨 폭과 그 비 셋, 에밀리오의 팔뚝, 대표 면의 잰 색(색조 · S · Y). 이 표로 "사람마다의 표지"의 열하나에 견주는 문턱을 수로 적는다. **하나라도 스케치의 목표로 넘을 수 없으면**(예: 클라라의 머리 위 덩이 ÷ 어깨 × 1.15가 체칠리아의 챙이 틀(450 − 8)에 들 수 있는 폭을 넘는다, 열하나의 어깨 ÷ 얼굴의 가장 작은 값이 얼굴보다 좁다) 그 줄을 어떻게 바꿀지 적고 멈추고 보고한다 ④ **다른 세션**: `git worktree list`, 그리고 읽기만으로 `git diff --stat stage6-content...h02-hit-feel`과 R02b 가지에 같은 것 — 이 계획의 파일(R8의 목록)과 겹치는 줄을 적는다 ⑤ 053b 보고서 · verifier 정의의 테스트 묶음(`-Only` 조각)과 묶음마다의 수 — `counter_art` · `week` · `client_line`이 어느 묶음에 드는지 ⑥ `run_client_shots.ps1`의 지금 출력(헤드리스, 차례표를 거쳐 verifier — `CLIENT SHOTS OK 7`)을 기록에 | `%TEMP%\bravi-style\054`, Grep · Read · verifier | — | 여섯 답이 작업 폴더의 기록에 있다. ③의 표가 판 D0의 바탕이다 |
| 1 | **견본과 판 D0**(0장): 스케치 셋을 `docs/style/samples/054-clients.html`에(034 견본의 `clientClara`와 같은 손 — 같은 선 굵기 · 덩이 수 · 그림자 한 단계, 220×390 틀, `inClient`의 변환), `generated/in/054-in-client-cecilia.png` · `-leandro` · `-nella`(1024×1536, 바탕 `#D8D8D8` 한 색)로 굽고, 지워 450×675로. 새 재기 스크립트 일곱과 옮긴 감싸개 · 재기 · 판 스크립트(그림 절). 판 D0 | 견본, 로컬 `in/054-in-client-*.png`, `%TEMP%\bravi-style\054\board-D0*.png` · `measure-D0.txt` | 0 | 판 D0의 굳은 확인 ⓐ~ⓕ와 분류의 확인. 굽은 장이 1024×1536이고 `measure.ps1`의 A-1a(바탕 한 색), 장면에 `<text>` 없음(H4), 금지 이름 0. 넘지 못하면 스케치를 고쳐 다시 굽는다 — **그림 몫을 쓰기 전에 여기서 닫는다**. `genC`의 `-DryRun`이 `git-before.txt`를 남긴다 |
| 2 | **명세 · 바이블의 줄과 프롬프트 셋**: 명세의 팔레트에 새 색(결정 868), 표정 표에 실눈 · 질색 · 억울함, "계획 054의 줄"(화풍 첫째 항목 · 사람마다 바꾸는 줄), 바이블 4절(표정 표 세 줄, "의뢰인" 문단의 소품 목록에 셋), 8절 팔레트, 13.3 "바꾸는 줄" 칸 | `docs/style/STYLE_SPEC.md`, `docs/STYLE_BIBLE.md`, `docs/style/prompts/054-C1a-client-cecilia.txt` · `054-L1a-client-leandro.txt` · `054-N1a-client-nella.txt` | 1 | ASCII · 큰따옴표 없음 · 금지 이름 0 · 결정 873의 없어야 할 말 0(Grep). 바꾸지 않은 블록이 명세와 글자까지 같다(줄마다 `Select-String -SimpleMatch`). F11의 세 구절. `check027.ps1`의 못 찾은 수 0. `run-codex.ps1 -DryRun`의 명령에 모델 · 추론 · read-only. 새 색이 신호 구역 밖이고 대표 면 S ≤ 40% |
| 3 | **C1a 체칠리아** → 재기 → 지우기 → 450 → 판 D1(걸리면 C1b — 결정 876) | 로컬 `generated/054-C1a-client-cecilia.png` | 2 | 판 D1. `GENERATION.md` "계획 054"에 호출마다 한 줄(돌리기 전의 장 수 포함) |
| 4 | **L1a 레안드로** → 판 D2(걸리면 L1b) | 로컬 `generated/054-L1a-client-leandro.png` | 3 | 판 D2. 같은 기록 |
| 5 | **N1a 넬라** → 판 D3(걸리면 N1b) | 로컬 `generated/054-N1a-client-nella.png` | 4 | 판 D3. 같은 기록 |
| 6 | **올리기**: 맞다를 받은 원본을 `basis/client-<이름>.png`로(해시가 원본과 같다), 손질본을 `assets/art/clients/<이름>.png`로(판에서 본 장과 해시가 같다), `assets/MANIFEST.md`에 장마다 한 줄(상태 `generated`), `basis/README.md`에 새 줄과 손질 값(지우기의 시작 가장자리, 450×675) | 위 파일들 | 5 | 해시 대조. 작업 0 ②의 해시가 그대로다(다른 의뢰인 · 방). `docs/style` 아래 `.import` 0 |
| 7 | **데이터 · 테스트**(결정 874): 의뢰 셋의 두 줄과 `load_steps`, T77, T159, T167, 카운터 찍기 셋, `ui_shots.gd`의 장 설명 둘 | `data/commissions/variants/court_beehive.tres` · `noble_baker.tres` · `washer_ledger.tres`, `tests/counter_art_tests.gd`, `tests/week_tests.gd`, `tests/client_shots.gd`, `tests/run_client_shots.ps1`, `tests/ui_shots.gd` | 6 | 의뢰마다 diff가 `load_steps` 한 줄 · ext_resource 한 줄 · `client_portrait` 한 줄이다. `week_tests.gd`의 diff가 한 줄, `ui_shots.gd`의 diff가 글 두 줄. `run_client_shots.ps1`이 ASCII · BOM 없음 |
| 8 | **V1 · V2**(verifier) → 커밋 | — | 7 | "확인" 절. 통과하면 커밋(판 D4 전) |
| 9 | **판 D4**(메인): V2의 `-Shots` 장 셋과 열넷의 나란히 판(D0의 첫 두 줄을 생성 그림으로) | `%TEMP%\bravi-style\054\board-D4*.png` | 8 | 판 D4의 굳은 확인과 눈 확인. 걸리는 것이 있으면 그림을 바꾸지 않고(몫이 없다) 판 W2-D에 올린다 |
| 10 | **문서와 커밋**: `docs/DECISIONS.md` 863~878과 실행 중에 정한 것(작업 0의 문턱, 판의 값, 쓴 장 · 빌린 장), `GENERATION.md` "계획 054"(몫 · 표 · 재기 · 배운 것), CLAUDE.md 9장(054 줄), `docs/HANDOFF.md` 1번 · 3번(판 W2-D), `docs/BACKLOG.md`(046-1 · 049-1을 054로 닫는다, 새 줄이 있으면), 보고서 `docs/reports/054-client-portraits.md`(판 D0~D4의 굳은 확인과 잰 값 표, 쓴 장 · 몫, 가름 표) | 문서 | 9 | `check027.ps1`의 못 찾은 수 0. 10장 형식의 보고. `git status`에 남은 것이 작업 0 ①의 다른 곳의 파일뿐 |

## 확인(verifier — 결정 875)

모든 Godot 명령은 `tests/wait_turn.ps1`로 차례를 받고 끝나면 `-Release`. 한 호출은 3분 안.

- **V1**(작업 8): `tests/run_tests.ps1 -Only <묶음>`을 작업 0 ⑤가 적은 묶음대로 — 모든 줄이 `ALL PASS`이고 **합이 167**(묶음의 수는 작업 8 전에 적는다), T77 · T159 · T167이 든 묶음의 통과, T167의 `INFO` 줄(쓰지 않는 그림 — `cornelia.png`가 있으면 그것 하나)을 그대로 돌려준다. 가져오기 오류 0, `assets/art/clients/cecilia.png.import` · `leandro` · `nella`에 `uid`가 생기고 밉맵이 꺼져 있다. `verify.ps1 -Only smoke` · `-Only ui` OK(UI 찍기의 법정 · 귀족 · 빨래터 카운터 장은 그림으로 화소가 바뀐다 — 기대). `-Only counter`는 반격 실험 찍기라 이 계획과 상관없어 돌리지 않는다 — 의뢰인의 카운터 찍기는 V2의 `run_client_shots.ps1`이다(v2 — 기술 비차단).
- **V2**(작업 8): `tests/run_client_shots.ps1`(헤드리스, 인자 없이) → `RESULT: OK (CLIENT SHOTS OK 10 …)`, 그리고 `-Shots %TEMP%\bravi-style\054\shots`(창)로 한 번 더 — 열 장, `portrait,` 열 줄이 상자 안. 메인이 새 셋의 장을 판 D4에 쓴다.

## 위험

- **R1 망사가 얼굴을 덮는다**(양봉 모자의 흔한 꼴): → 결정 864, 프롬프트의 "lifted and folded up onto the brim, so her whole face is uncovered", ⓔ(망사 부류가 얼굴 상자 안에 0). 걸리면 `Change:` 한 줄로 다시.
- **R2 가발이 곱슬 · 부풂으로 나온다**(분칠 가발의 흔한 꼴, 바이블이 막는 꼴): → 곧은 옆면 · 가로 캡슐 말의 말, 화풍 첫째 항목(결정 873), 채움 ÷ 볼록 껍질 ≥ 0.85, 눈 확인. 가발이 흰색(`#F0ECE2` 언저리)으로 나오면 굴리엘모의 흰 천과 붙고 바탕과 가까워 구멍 위험이 커진다 — 잰 색이 Y 0.90 넘으면 걸린 것으로 본다.
- **R3 손수건이 입을 가리거나 이네스와 같아 보인다**: → 코 옆, "His eyes and his mouth stay uncovered", 손수건 화소가 눈 · 입 상자 안에 0, 길이 ≥ 0.8 Fh, 색을 옅은 청회색으로(이네스는 양피지).
- **R4 레안드로가 가스파로와 붙는다**(둘 다 마른 · 깔보는 사내): → 표정을 거만함이 아닌 질색으로, 수염 없음, 가발의 솟음 ≥ 0.55. 판 D2 · D4의 짝지은 줄.
- **R5 방망이가 몽둥이 · 무기로 읽히거나 그림 도구가 막는다**: → "a washing tool for linen"(때린다는 말을 쓰지 않는다), 넓적한 판(판 폭 ÷ 길이 ≥ 0.22), 없어야 할 말에 `club` · `bat` · `weapon`. 막힌 호출은 장으로 세지 않고 같은 프롬프트로 한 번 더(034 · 032b), 또 막히면 멈추고 보고.
- **R6 체칠리아가 아고스티노와 붙는다**(둘 다 작고 굽은 노인): → 가장 넓은 줄이 챙(≥ 1.40, 그의 어깨 돔과 반대 꼴), 좁고 처진 어깨, 실눈 대 능청. 굽은 등은 수로 재지 않는다 — 판 D4와 W2-D-1.
- **R7 바탕 지우기의 구멍**(045b의 흰 앞치마): → 결정 872, `mHole` 0을 굳은 확인으로. 구멍이 나면 아래 가장자리를 빼는 `cutC`의 길, 그래도 나면 그 그림의 바탕을 지우는 허용 차를 줄이지 않고 걸린 것으로 본다(바탕과 가까운 칠이 열린 선에 닿은 것 — 그림의 일).
- **R8 다른 곳의 변경이 생성의 막는 장치에 걸린다**: 045b R8의 판단 그대로(감싸개의 `git-before.txt` · `git-after.txt`를 줄 단위로 견준다). **이 계획의 파일**: `docs/style/`(로컬 `generated/` 포함) · `docs/STYLE_BIBLE.md` · `assets/art/clients/cecilia.png*` · `leandro.png*` · `nella.png*` · `assets/MANIFEST.md` · `data/commissions/variants/court_beehive.tres` · `noble_baker.tres` · `washer_ledger.tres` · `tests/counter_art_tests.gd` · `tests/week_tests.gd` · `tests/client_shots.gd` · `tests/run_client_shots.ps1` · `tests/ui_shots.gd` · `docs/plans/054-*` · 작업 10의 문서. 다른 줄의 경로가 모두 그 밖이면 그림을 받고 그 호출 줄에 적는다. 하나라도 이 계획의 파일이면 그 그림을 쓰지 않고 멈춘다(장으로는 센다).
- **R9 몫 5가 모자라다**: → 결정 863의 빌림(053b의 남은 몫에서 1장뿐 — 053b가 5/6장을 썼다), 그래도 모자라면 결정 876(그 사람은 도형으로, 완료 기준 4의 미달을 060에).
- **R10 3분 끊김과 차례 기다림**: → `-TimeoutSec 170`, `-Only` 묶음, 한 명령씩, 차례표 `-MaxWaitSec 150`(기다림이 넘치면 그 명령을 다시 맡긴다 — 값을 고치지 않는다).
- **R12 넬라가 위협으로 읽힌다**(v2 — D1): 멘 방망이 · 열린 입 · 내민 손이 그림 도구에서 다시 공격적으로(치켜든 방망이, 이를 드러낸 입, 주먹) 나올 수 있다. → 공격의 표지를 스케치에서 하나로 줄이고(결정 867), 프롬프트는 `indignant` · "a wronged customer who has come to complain", 없어야 할 말 `angry` · `teeth` · `fist` · `hip` · `raised`, 굳은 확인 둘(이의 밝은 화소 ≤ 5%, 판 쪽 끝이 손잡이보다 아래)과 D0 · D3 · D4의 눈 확인. 걸리면 결정 867의 `Change:` 한 줄로 한 번 다시(몫 안). 그래도 걸리면 그 장을 올리지 않고 결정 876.
- **R11 053b가 끝나지 않았다**: 053b가 멈추거나 길어지면 이 계획도 시작하지 않는다(그림 생성은 한 번에 하나, 명세 · 바이블 · `GENERATION.md` · `MANIFEST`를 함께 고친다). 053b의 끝 커밋과 그 보고서의 수(테스트 합, 결정 번호, 남은 몫)를 작업 0이 다시 읽고, 다르면 수만 옮긴다.

## 다른 세션과의 겹침(결정 877)

| 세션 | 작업 트리 · 가지 | 고치는 것 | 054와 |
|---|---|---|---|
| 053b 코르넬리아의 그림 | 이 트리 · `stage6-content` | 명세 · 바이블 · `GENERATION.md` · `MANIFEST` · `basis/README`, `assets/art/clients/cornelia.png`, 결정 846~862, T166 | **차례로 한다**(R11). 같은 문서를 고치지만 053b의 커밋 뒤에 시작하므로 겹치지 않는다. 작업 폴더는 따로(`054\`). 053b의 의뢰인 그림은 판 D0 · D4의 열하나째로만 쓴다 |
| H02 타격감 | `C:\godot\bravi-h02` · `h02-hit-feel` | `scripts/duel/`(beeper · opponent_view · duel_scene · 새 hit_feel), 테스트의 이벤트 손질, CLAUDE.md 3 · 7 · 9장, DECISIONS 920~926, HANDOFF, H01 계획 머리, 보고서 | **코드 · 데이터 · 애셋은 겹치지 않는다**(054는 `scripts/` 0줄, 상대 · 결투를 건드리지 않는다). 테스트 파일: 054가 고치는 다섯(`counter_art_tests` · `week_tests` · `client_shots` · `run_client_shots` · `ui_shots`의 글 두 줄)을 H02가 고쳤는지 작업 0 ④가 읽기만으로 본다 — 고쳤으면 줄 단위로 적고, 같은 줄이면 뒤에 합치는 쪽이 둘 다 남긴다. 문서는 덧붙임 자리(CLAUDE.md 9장의 줄, DECISIONS의 끝, HANDOFF, BACKLOG)뿐이고 번호 덩이가 다르다(863~878 대 920~926). 합칠 때 뒤에 들어가는 쪽이 문서의 덧붙임을 둘 다 남긴다(053 결정 844의 차례 — `stage6-content`가 먼저) |
| R02b 규칙 갈래 | `C:\godot\bravi-r02b` | 계획 파일이 이 트리에 없다. 잡아 둔 번호 900~908 · T200~T206 | BACKLOG 046-2 · 049-2("R02b가 실행되면 법정 · 귀족 · 넬라의 V2를 다시")대로 R02b는 세 의뢰의 **판**을 다시 재지만 054는 그 의뢰의 그림 두 줄 · `load_steps`만 고친다. R02b가 같은 `.tres`를 고쳤다면 `load_steps` 줄이 겹칠 수 있다 — 작업 0 ④가 적고, 합칠 때 ext_resource 수로 다시 센다 |
| 공용 차례표 | `C:\godot\.bravi-test-queue` | 번호표 | 054의 verifier 호출은 모두 차례표를 거친다. Codex 호출은 거치지 않는다 |

`.gitignore`, `docs/plans/H02-*`, `docs/plans/R02b-*`는 건드리지 않는다.

## 나중에 사용자가 볼 판(판 W2-D — HANDOFF 3번으로. 계획을 막지 않는다)

카운터와 정산(5 · 7 · 6일차의 세 손님 — 연습 화면의 의뢰 카드는 `client_portrait`를 쓰지 않는다, v2 기술 비차단)과 판 D0~D4의 그림으로 본다. 뒤집는 길을 한 줄씩 적는다.

- W2-D-1 **셋의 그림**: 넓은 챙과 걷은 망사의 작은 노파 · 머리보다 큰 가발의 가는 백작 · 굵은 팔에 방망이를 멘 세탁부. 열넷 가운데 한눈에 기억되는가, 아고스티노 · 가스파로 · 에밀리오와 갈리는가. 판 D0의 실루엣에서 레안드로의 곧은 가발 덩이가 코르넬리아의 원통 모자 · 굴리엘모의 천 모자 덩이와 가깝다(결정 871a) — 가로 말 셋과 가장 좁은 어깨가 가르는지 본다. 체칠리아의 망사 판이 양옆으로 통처럼 넓게 나왔다(판 D1 — 결정 871b) — 양봉 망사로 읽히는지, 무거워 보이지 않는지 본다. 레안드로는 다른 손을 허리에 짚어 가스파로와 같은 몸짓이다(판 D2 — 결정 871c) — 가발 · 손수건 · 연보라가 가르는지 본다. 그림 셋은 메인이 대신 "맞다"로 올렸다. 뒤집기: 그 사람만 다시 그리기(몫 1~2, 의뢰의 `client_portrait`는 그대로).
- W2-D-2 **씨앗에서 바뀐 넷과 그리지 않은 둘**(결정 864): 망사를 걷음, 손수건을 코 옆에, 가발을 곧은 덩이로, 젖은 앞치마를 짙은 칠로 / 벌 · 연기 없음. 양봉가 · 분칠 가발 · 세탁부답게 보이는가. 뒤집기: 바이블 4절을 먼저 고치고 그 사람을 다시.
- W2-D-3 **표정 — 실눈 · 질색 · 억울함**(결정 869): 체칠리아가 조는 얼굴이 아니라 고집 센 노인으로(고른 시안), 레안드로가 질색하는 귀족으로, 넬라가 억울해 따지는 손님으로 읽히는가. 메인의 판(D0 · D3)이 "때리러 온 사람"으로 읽히는 장은 이미 걸렀다(v2 — D1) — 사용자가 보는 것은 그 선이 맞았는가다. 뒤집기: 표정 줄을 바꾸면 그 사람 다시.
- W2-D-4 **색**(결정 868): 장밋빛 흙색 · 연보라 · 풀빛. 체칠리아의 드레스와 넬라의 머릿수건이 같은 날에 서도 갈리는가. 뒤집기: 그 사람 다시.
- W2-D-5 **소품**: 연기 깡통이 무엇인지 읽히는가(연기 없이), 방망이가 빨래 도구로 읽히는가, 손수건이 이네스의 것과 다른 몸짓으로 읽히는가.
- W2-D-6 **몫의 빌림**(결정 863): 053b의 남은 몫을 빌렸으면 그 장 수. 묶음의 위쪽 어림(20) 안이다.

## 넘기는 것

- **056 · 057**(속편): 체칠리아 · 넬라 · 레안드로가 2주차에 다시 설 때 같은 그림을 쓴다(의뢰의 `client_portrait`에 같은 경로). T167 ①이 "이름 하나에 그림 하나"를 지킨다 — 같은 사람의 속편 의뢰도 같은 파일을 건다.
- **057**: `cornelia.png`를 그녀가 의뢰인인 의뢰에 걸면 T167 ②의 `INFO` 줄이 사라진다.
- **060**: 완료 기준 4의 대조(`NO_PORTRAIT`가 비었는가 — 결정 876으로 남은 사람이 있으면 미달).

## 사용자 결정 필요

없다 — 메인이 대신 고름(사용자 위임 2026-11-27): 몫과 차례(사람마다 한 장, 다시 그리기 둘을 먼저 걸린 사람에게, 053b의 남은 몫에서 빌림 — 남은 것은 1장뿐), **씨앗에서 바뀐 넷과 그리지 않은 둘**(G8과 바이블 4절), 셋의 꼴과 소품, 색(대표 면 셋 — 남은 색조의 띠 둘과 밝기로 가른 하나), 새 표정 세 줄(실눈 · 질색 · 억울함 — 넬라의 공격 표지를 하나로 줄인 것과 손바닥 손짓, v2), 체칠리아의 입 · 턱 시안, 판 D0~D4의 굳은 확인과 열하나에 견주는 문턱(작업 0이 재서 수로 적는다), 바탕 지우기와 구멍의 확인, 프롬프트에 사연을 쓰지 않는 것, 카운터 찍기에 셋을 더하는 것, T167, 몫이 모자랄 때 그 사람을 도형으로 남기는 길. 손 · 눈이 있어야 아는 것은 판 W2-D(W2-D-1~W2-D-6)에 모았다.

## 검토 대응 기록(1회차 → v2)

1회차: 디자인 REVISE(D1 · D2) · 기술 APPROVE(비차단 넷).

- **D1**(넬라의 공격 표지 셋 — 이를 드러낸 입 · 멘 몽둥이 · 허리의 주먹, 거르는 확인이 없다): (1) 판 D0 · D3 · D4의 눈 확인에 "따지는 손님이지 위협하는 사람이 아니다 — 입 · 방망이 · 손이 '때리러 왔다'로 읽히면 걸린다". (2) 공격 표지를 하나로(메인이 고름): 허리의 주먹 → 손바닥을 위로 내민 따지는 손짓, 입 → 이가 보이지 않는 말하는 중의 열린 네모, 성격 말 `indignant`, 방망이는 어깨에 메되 판이 등 뒤로 늘어진다. 표정은 화남 대신 새 줄 **억울함**. 굳은 확인 둘을 더했다(입 안의 밝은 화소 ≤ 5%, 판 쪽 끝이 손잡이보다 아래). 없어야 할 말에 넬라의 `angry` · `teeth` · `fist` · `hip` · `raised`. (3) 걸렸을 때의 `Change:` 한 줄을 결정 867에 두었고 결정 876이 가리킨다. 바꾼 곳: "인물" 절의 넬라, 가름 표, 결정 867 · 869 · 873 · 876, 판 D0 · D3 · D4, 넬라의 표지, 프롬프트 뼈대, R12, W2-D-3.
- **D2**(가까운 짝 둘이 나란히 보는 줄에 없다): 체칠리아 ↔ 에밀리오(대표 면 21°)와 넬라 ↔ 코르넬리아(053b가 `cornelia.png`를 만들었을 때)를 판 D0의 셋째 줄, D1 · D3의 나란히, D4의 짝 목록, "확인할 결과" 4, 가름 표 아래의 "가르는 수"에 더했다.
- 디자인 비차단(받음): 체칠리아의 실눈이 조는 얼굴로 읽히지 않게 — 입 끝을 눌러 내리고(결정 869의 실눈 줄, 프롬프트), 턱 끝을 내미는 시안을 판 D0의 넷째 줄에 두어 메인이 고른다(결정 865).
- 기술 비차단(받음): T167 ①의 역방향 표에서 그림이 없는 의뢰를 뺀다(순방향은 빈 값도 한 값). T167 ③은 `is_compressed()`면 푼다. 판 W2-D의 "연습 화면의 의뢰 카드"를 카운터 · 정산으로. `ui_shots.gd` 599 · 608행의 "색 도형"을 고칠 줄로(테스트 표 · 결정 874 · 작업 7 · R8 · 겹침 절). V1에서 `verify.ps1 -Only counter`를 빼고 의뢰인 카운터 찍기는 V2라고 밝혔다.
- 검토와 별개로 바꾼 것: 결정 873의 "없어야 할 말"을 막는 구절("No …" · "with no …") 안에서는 세지 않게 밝혔다(레안드로의 "No ruffles", 넬라의 "no splashes"가 걸리던 것). 재는 법 ⑦의 좌우 4열 설명에서 "허리에 짚은 팔꿈치"를 "내민 손"으로.

**디자인 쪽 기준의 변경**: 넬라의 표지가 바뀌었다(주먹 → 내민 손바닥, 이를 드러낸 화남 → 이가 보이지 않는 억울함, 세운 방망이 → 등 뒤로 늘어진 방망이). 방망이의 자는 "위 끝이 어깨 줄보다 위 · 세로에서 10~45°"에서 "손잡이 쪽 끝이 어깨 줄 ± 0.5 Fh, 판 쪽 끝이 그보다 아래 · 세로에서 0~40° · 판 폭 ≥ 0.35 × 얼굴 폭"으로, 보이는 길이는 1.3 Fh에서 1.0 Fh로 바뀌었다(판의 일부가 등 뒤로 숨는다). 위협으로 읽히지 않는다는 눈 확인과 이의 굳은 확인이 더해졌다. 체칠리아의 실눈 줄은 입 끝이 눌린 곧은 선으로 바뀌었다.

**9장 단계**: 이 계획은 6단계 안이다. 054가 끝나도 6단계 완료 기준이나 다음 단계를 묻지 않는다(052의 차례 056 · 057 · 058~058c · 055 · 059 · 060이 남았다).
