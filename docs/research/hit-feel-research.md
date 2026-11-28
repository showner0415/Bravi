# 타격감 조사 — 1인칭 2D 결투(펀치아웃 꼴)에서 코드만으로 손맛을 올리는 법

조사일 2026-11-28. 웹 검색과 원문 읽기로 모았다.

**읽는 법**
- 수치 뒤에 출처가 붙은 것만 확인한 값이다. `(기억)`은 이번 조사에서 원문을 확인하지 못하고 기억에 기댄 것, `(2차)`는 원문이 아니라 남이 옮긴 글·팬 위키·포럼에서 본 것이다.
- `제안값`은 출처가 있는 수치가 아니라, 출처의 범위를 이 게임(60fps, 1280×720)에 옮겨 본 출발점이다. 재 보고 고쳐야 한다.
- 기법마다 꼬리표를 붙였다: **[읽기·보상]** = 일어난 일을 또렷하게 하고 잘한 것을 갚는다 / **[과장]** = 화려함·세기를 늘린다. 둘 다면 둘 다.
- 1프레임 = 16.7ms(60fps).

---

## 0. 먼저 — 근거가 가리키는 방향

1. **타격감을 가르는 것은 셋이다: 히트스톱, 소리의 맞물림, 카메라.** Lin 외(2022)는 Steam 인기 액션 게임의 이용자 평을 언어 모델로 줄 세우고 위 8개·아래 8개 게임의 피드백 요소 19가지를 대조했다. 결론: "hit stop, sound coherence, and camera control may strongly influence players' impact feel", 그리고 이 셋 가운데 하나라도 따로 공들이지 않으면 타격감이 무너질 수 있다. 상관 연구이지 통제 실험은 아니다. <https://arxiv.org/abs/2208.06155>
   → 지금 이 게임은 히트스톱은 있고, **소리는 사인파 비프음**이고, 카메라는 없다. 가장 크게 빈 곳은 소리다.
2. **주스는 많을수록 좋지 않다.** Kao(2020, N=3018)는 같은 액션 RPG를 주스 없음·중간·높음·극단 네 판으로 견줬고, 없음과 극단이 둘 다 경험을 떨어뜨렸다(2차: Lin 외와 Pichlmair·Johansen의 요약으로 확인, 원문 표는 못 봤다). DOI 10.1016/j.entcom.2020.100359
3. **잘했을 때만 주는 피드백이 동기를 올리고, 무조건 키운 피드백은 오히려 깎았다.** Kao의 2024 CHI 후속 연구: "success dependence enhanced all motives, while amplification unexpectedly reduced them"(2차: 검색 요약). <https://spiral.imperial.ac.uk/entities/publication/253c32f5-d124-4a23-88b5-9aaaf114608d>
   → 이 게임의 원칙("이기는 것이 아니라 정확히 수행", "관찰로 이긴다")과 같은 쪽이다. **세기를 고루 올리지 말고, 읽고 맞춘 순간에 몰아준다.**
4. **God of War(2018)는 화면 흔들림을 일부러 줄였다.** "Camera shake is also significantly reduced … While this can hurt impact perception, it greatly improves legibility of targets and aids gameplay"(Christian Wohlwend). 대신 히트스톱과 피격 포즈, 큰 소리로 채웠다. <https://blog.playstation.com/?p=370399>
   → 예비 동작과 고리를 읽어야 하는 게임에서는 화면 전체를 흔드는 것이 가장 비싼 주스다.
5. **Pichlmair·Johansen의 조사(자료 200여 건)**는 다듬기를 셋으로 나눈다: 물리(조율), 증폭(주스), 지원(입력을 돕기). 타격감이 아쉽다는 말은 흔히 증폭만 가리키지만 지원(입력 버퍼)도 손맛의 한 축이다. <https://arxiv.org/abs/2011.09201>

---

## 1. 타격감의 기법

### 1.1 히트스톱(히트 포즈) — [읽기·보상][과장]

**무엇** 맞는 순간 공격자와 피격자를 몇 프레임 멈춘다.

**왜 통하나** 세기를 눈에 새기고("emphasizing the power of impact" — 사쿠라이), 맞았는지 확인할 시간과 다음 입력을 넣을 틈을 준다. 스트리트 파이터에서는 이 멈춤이 캔슬 타이밍을 고르게 하고 그동안의 입력을 받아 두는 구실을 한다. <https://sonichurricane.com/?p=1043>

**대표 수치**

| 게임 | 수치 | 출처 |
|---|---|---|
| 격투 게임 일반 | 약 9 / 11 / 13프레임(약·중·강) = 150 / 183 / 217ms | sonichurricane (2차, 글쓴이의 어림) |
| SF2 계열 | 세기와 무관하게 약 14프레임(233ms) | 같은 글 |
| SF4 | c.HP 12프레임, 장풍 8프레임 | 같은 글과 댓글 (2차) |
| 스매시 64(해외판) | ⌊d/3 + 5⌋ | <https://ssbwiki.com/Hitlag> |
| 스매시 멜리 | ⌊d/3 + 3⌋, 상한 20프레임 | 같은 곳 |
| 스매시 브롤·4 | ⌊(d×0.3846 + 5)×h⌋, 상한 30프레임 | 같은 곳 |
| 스매시 얼티밋 | ⌊(d×0.65 + 6)×h⌋, 상한 30프레임 | 같은 곳 |
| 같은 15% 공격 | 멜리 8프레임(133ms), 브롤·4 10프레임(167ms), 얼티밋 15프레임(250ms) | 같은 곳 |
| 전기 속성 | ×1.5 | 같은 곳 |
| 몬스터 헌터(한 해머 공격) | GU 9프레임(30fps, 약 0.3초), 월드 13프레임, 라이즈 15프레임(60fps) | PC Gamer가 옮긴 팬의 대조 (2차) <https://pcgamer.com/games/rpg/capcom-if-youre-listening-monster-hunter-wilds-needs-its-hitstop-back> |

- 몬스터 헌터 와일즈 베타는 히트스톱을 줄였다가 "가볍다"는 반발로 되돌렸다. 히트스톱을 빼면 곧바로 "타격감이 없다"는 말이 나온다는 실례다(같은 기사).
- **공격자와 피격자를 따로**: 스매시는 요소마다 곱이 따로 걸린다(웅크림 0.67배는 피격자만, 멜리의 전기는 피격자만). 장풍은 쏜 쪽이 멈추지 않고 맞은 쪽만 멈춘다(약 12프레임, sonichurricane). 즉 "둘 다 같은 길이"가 기본이고, 연출로 한쪽만 늘리는 것이 변주다.
- **지금 이 게임의 50~120ms(3~7프레임)는 격투 게임의 약공격보다도 짧다.** 격투 게임의 기본 타격은 150~230ms 대다.

**이 게임에 옮기기**
- 결과별로 길이를 갈라 **세기가 아니라 뜻을 싣는다**. 제안값: 스침 4~5프레임(70~80ms), 막힘 3프레임, 패리 8~10프레임(130~170ms), 무너뜨림 12프레임(200ms), 유효타 15~18프레임(250~300ms). 마지막 둘은 한 판에 몇 번뿐이라 길어도 흐름을 해치지 않는다.
- 이어 베기처럼 박자가 있는 패턴에서는 **판의 시계까지 함께 멈춰야** 다음 타격까지의 0.55초가 줄지 않는다(시각 효과만 멈추고 판정 시계가 가면 패리할수록 다음 박이 빨라진다).

### 1.2 멈춘 동안의 떨림(hit shake) — [읽기·보상]

**무엇** 히트스톱 동안 맞은 쪽만 제자리에서 떤다.

**왜 통하나** 완전한 정지는 게임이 멈춘 것처럼 보인다. 떨림이 "멈춘 것이 아니라 맞은 것"임을 알린다. 사쿠라이의 설명(파미통 칼럼 490호, 팬 번역): <https://sourcegaming.info/2015/11/11/thoughts-on-hitstop-sakurais-famitsu-column-vol-490-1/>

**대표 규칙(수치는 칼럼에 없다)**
- 보통은 맞은 쪽만 떤다. 스매시는 친 쪽도 조금 떤다.
- **판정 상자는 떨지 않는다** — 그림만 떤다.
- 땅에 선 캐릭터는 **좌우로**, 공중은 위아래로(땅에서 위아래로 떨면 발이 바닥을 파고든다).
- **처음에 크고 끝으로 갈수록 줄어든다** — 멈춤 길이를 미리 알고 감쇠를 맞춘다.
- 카메라가 멀수록 진폭을 키운다(작게 보일 때 묻히지 않게).
- 움찔에서 아픈 자세로 넘어갈 때 **히트스톱의 4프레임을 써서 섞는다**(뚝 끊기지 않게).
- 친 쪽은 멈춘 동안 눈에 안 띄는 아주 느린 속도로 계속 민다(멈춤이 죽은 정지가 되지 않게).
- 사쿠라이의 유튜브 강의 "Stop for Big Moments!"가 같은 여덟 가지를 다룬다(2차: 요약 기사만 확인, 영상은 못 봤다).

**이 게임에 옮기기** 상대의 뿌리 노드가 아니라 **그림 노드만** 좌우로 떤다. 제안값: 첫 프레임 ±6px(간격 "멀리"에서는 ±8px, "밀착"에서는 ±5px — 화면에 보이는 크기에 맞춰), 프레임마다 부호를 뒤집고 진폭을 직선으로 0까지. 지금의 "몸 전체가 10~28px 밀렸다 돌아오는 움찔"은 넉백이지 떨림이 아니다. 둘은 겹쳐 쓴다.

### 1.3 맞은 자세로 튀기(pop to pose) — [읽기·보상][과장] ★ 가장 빠진 것

**무엇** 맞는 프레임에 중간 과정 없이 피격 자세로 바꾸고, 그 자세를 히트스톱 동안 붙든 뒤 천천히 돌아온다.

**왜 통하나** God of War: "on hit actually pops the target to the hit pose and holds both Kratos and the target in that first frame for a short duration." 현실적이지 않지만 휘두름이 닿았음을 강조하고 팔로스루의 저항을 흉내 낸다. "Enemy reactions are allowed to break reality with huge pose changes"(Wohlwend). Techland도 "the feedback loop of hitting your enemy and him reacting to that powerful hit"을 핵심으로 꼽는다. <https://blog.playstation.com/?p=370399>
프로레슬링 말로 상대가 타격을 "판다(sell)". 맞은 쪽이 비틀거려야 공격이 세 보인다. <https://canmom.art/crit/mechanisms-of-action-games>

**대표 수치** 튀는 데 0~1프레임, 붙드는 길이 = 히트스톱. 복귀 길이의 출처 있는 수치는 찾지 못했다.

**이 게임에 옮기기** 파츠 분리 컷아웃이라 **그림 없이 관절 각도만으로** 된다.
- 맞은 부위와 방향마다 피격 자세 한 벌(각 파츠의 회전·이동 값)을 데이터로 둔다. 예: 왼쪽 베기가 몸통에 닿음 → 몸통이 오른쪽으로 8~12° 꺾이고 머리는 반대로 늦게 따라오며 칼 든 팔이 벌어진다. 찌르기가 몸통에 닿음 → 몸통이 뒤로(작게·위로) 접히고 머리가 앞으로 숙는다. 다리에 닿음 → 맞은 쪽으로 주저앉는다.
- 0프레임에 그 자세로 뛰고, 히트스톱 동안 붙들고, 복귀는 느리게(제안값 0.25~0.4초, 끝이 느린 이징, 한 번 살짝 넘쳤다 돌아옴).
- **몸 전체를 한 덩어리로 미는 지금의 움찔이 아쉬운 까닭이 여기 있다**: 실루엣이 바뀌지 않으면 눈은 "밀렸다"로 읽지 "맞았다"로 읽지 않는다.
- 머리·모자·칼은 한두 프레임 늦게 따라가게(겹쳐 움직임) 하면 값싸게 무게가 생긴다.

### 1.4 예비–타격–팔로스루의 프레임 배분 — [읽기·보상]

**무엇** 공격을 예비(길다) / 판정(아주 짧다) / 회수(길다)로 나눈다.

**대표 수치** 다크 소울 3의 적 공격 분석: 신호+공격이 합쳐 **340ms 이상**, 판정이 켜진 것은 **2~4프레임**, 끝 자세는 미끼로 쓸 때 240ms 이상. 반응 모델은 지각 100ms + 판단 70ms + 동작 70ms에 게임의 입력 응답 60~100ms. <https://www.gamedeveloper.com/game-platforms/anatomy-of-an-enemy-attack-in-dark-souls-3>
플레이어 쪽 예: 예비 6~7프레임 뒤 판정(Aztez 개발자의 아말러 분석, 2차). <https://aztez.com/blog/2012/05/24/the-amalur-problem/>

**왜 통하나** "anticipation and follow-through are vital for 'selling' an animation"(canmom). 판정이 짧아야 닿는 순간이 한 점으로 읽히고, 그 한 점에 히트스톱·소리·섬광을 모을 수 있다.

**이 게임에 옮기기**
- **내 공격**: 누른 뒤 예비는 2~3프레임만(입력이 굼뜨면 안 된다), 닿는 데까지는 중간 그림 없이 1~2프레임에 가고(§1.5의 잔상이 그 사이를 메운다), 닿은 자리에서 히트스톱만큼 멈춘 뒤 넘쳤다 돌아온다. 제안값: 회수 0.18~0.25초, 끝이 느린 이징.
- **상대의 타격**: 예비 동작은 이미 길고 일관되다(원칙 4). 타격 순간만 1~2프레임에 끝 자세로 뛰게 하면 예비–타격의 대비가 커진다. 예비 동작의 길이는 건드리지 않는다.

### 1.5 스미어·잔상 — [읽기·보상][과장]

**무엇** 빠른 움직임의 사이를 늘어난 꼴이나 궤적의 띠로 채운다.

**근거** 이번 조사에서 스미어의 프레임 수를 적은 출처는 찾지 못했다. 손그림 애니메이션의 관례로는 1~2프레임(기억). Pichlmair·Johansen은 궤적·자국·파편을 "지난 일을 기억하지 않아도 되게 밖으로 꺼내 주는 것"으로 지원 쪽에 넣었다. <https://arxiv.org/abs/2011.09201>

**이 게임에 옮기기** 내 칼끝의 지난 3~5프레임 위치를 이어 **가늘어지는 띠(Line2D나 다각형)** 로 그린다. 제안값: 2~3프레임 동안 밝고 0.1초에 사라짐. 베기는 호, 찌르기는 곧은 줄. 그림 애셋이 필요 없고, **내 칼이 어느 칸으로 갔는지**를 또렷하게 하므로 읽기에 든다. 상대의 큰 베기에도 같은 띠를 쓸 수 있으나 번호 고리를 가리지 않게 고리보다 아래 층에 둔다.

### 1.6 스쿼시 & 스트레치 — [과장]

**무엇** 닿을 때 누르고(납작) 튕길 때 늘린다.

**근거** "Juice it or lose it"(Jonasson·Purho, GDC Europe 2012)이 벽돌깨기에 트윈·늘리기·누르기를 하나씩 더해 보였다(2차: 강연 소개 글만 확인, 수치 없음). <https://gdcvault.com/play/1016487/Juice-It-or-Lose> · <https://gamedeveloper.com/design/video-is-your-game-juicy-enough->
반론도 있다: Folmer Kelly "Don't Juice It or Lose It"(2014) — 지나친 다듬기는 몰입을 깎는다. <https://gamedeveloper.com/design/video-indies-resist-the-urge-to-juice-it-or-lose-it->

**이 게임에 옮기기** 상대 그림 노드의 크기를 맞는 프레임에 가로 1.06·세로 0.94로 뛰게 했다가 0.2초에 돌아오게(제안값). 값싼 대신 효과는 §1.3보다 작다. 화풍(바랜 색의 차분한 필사본)과 맞는지 보고 정한다.

### 1.7 넉백과 리코일 — [읽기·보상]

**무엇** 맞은 쪽이 밀리고(넉백) 친 쪽·무기가 되튄다(리코일).

**근거** Pichlmair·Johansen의 증폭 항목. Vlambeer의 "The Art of Screenshake"는 밋밋한 슈터에 손질 30개를 하나씩 얹는데 그 안에 플레이어 넉백·무기 리코일·히트 포즈·카메라 러프가 있다(2차: 팬의 재현 목록. 강연의 밀리초 값은 확인 못 했다). <https://gamedeveloper.com/design/vlambeer-co-founder-shares-advice-on-building-better-action-games>

**이 게임에 옮기기** 상대의 넉백은 이미 있다(10~28px). 빠진 것은 **내 쪽의 리코일**이다(§5.1).

### 1.8 화면 흔들림 — 방향 있는 킥 대 무작위 — [과장] (절제)

**무엇** 카메라를 민다.

**근거와 수치**
- Vlambeer: 흔들림은 **쏘는 방향의 반대로**(방향이 있다). 예: 조준 방향에서 카메라를 6px 뒤로 차고 흔들림 값에 4를 더한다(2차: 인터뷰를 옮긴 블로그). <https://infovore.org/?p=5275>
- Squirrel Eiserloh(GDC "Juicing Your Cameras With Math"): 0~1의 "트라우마" 값을 두고 시간에 따라 줄이며, 실제 흔들림은 **트라우마의 제곱(또는 세제곱)**, 난수가 아니라 **부드러운 잡음**(펄린)에서 뽑는다. 강연 원문은 못 봤고 이를 따른 구현으로 확인했다: Godot 레시피(감쇠 0.8/초, 지수 2, 최대 이동 100×75px, 최대 기울임 0.1rad — "아껴 써라") <https://kidscancode.org/godot_recipes/3.x/2d/screen_shake/>, Bevy 예제 <https://bevy.org/examples/camera/2d-screen-shake/>
- God of War는 흔들림을 줄여 표적의 읽힘을 지켰다(§0-4).

**이 게임에 옮기기** 1인칭에서는 "내가 맞았다"에 가장 잘 맞는다. 제안값: 내가 맞으면 타격 방향으로 8~12px 한 번 차고 0.15초에 돌아옴 + 트라우마 0.3. 내가 친 것에는 **흔들지 않거나** 유효타·무너뜨림에만 2~4px. 스침·막힘·패리에는 쓰지 않는다 — 다음 고리를 읽어야 하는 순간이다. HUD와 번호 고리는 흔들리는 층에서 뺀다.

### 1.9 임팩트 프레임과 섬광 — [읽기·보상]

**무엇** 닿는 순간 맞은 것을 한두 프레임 흰색으로 덮거나 닿은 자리에 불꽃을 낸다.

**수치** 스프라이트를 "a frame or two" 흰색으로(Pichlmair·Johansen). 타격의 방향·종류·세기를 알리는 "임팩트 마커"도 같은 조사의 항목이다.

**이 게임에 옮기기**
- 맞은 **파츠만** 1~2프레임 희게(셰이더의 섞기 값 하나). 몸 전체가 아니라 부위만 번쩍이면 "어디를 쳤는지"가 그대로 읽힌다 — 부위를 맞히는 것이 의뢰인 이 게임에 꼭 맞는다.
- 닿은 자리에 **방향 있는 불꽃**: 내 칼이 지나간 방향으로 뻗는 선 5~8개(제안값 길이 20~60px, 0.12초, 코드로 그린다). 스침은 짧고 적게, 유효타는 길고 많게. 패리는 두 칼이 만난 점에서 사방으로.
- 색은 이미 뜻이 있는 색(타격 빨강, 빈틈 파랑, 무너짐 보라, 초록)과 겹치지 않게 흰색·옅은 노랑으로.

### 1.10 카메라 줌 펀치 — [과장]

**근거** 타격 순간 시야각을 잠깐 조였다 푸는 것은 1인칭 근접전의 흔한 손질이다(2차: 실무자 글. 출처 있는 수치는 찾지 못했다).

**이 게임에 옮기기** 2D이므로 무대+상대 층의 크기를 1.02~1.03배로 3프레임에 올렸다 0.2초에 내린다(제안값). 유효타·무너뜨림에만. 16:9 고정이라 가장자리가 비지 않게 무대 그림의 여백을 확인해야 한다.

### 1.11 타임 스케일(슬로모션) — [읽기·보상][과장]

**근거** Pichlmair·Johansen: 슬로모션은 사건을 보여 주거나 정밀한 행동에 힘을 실어 준다. Metal Gear Rising은 패리로 적을 무력화한 뒤 블레이드 모드를 슬로모션으로 연다(감독 사이토: 방어가 공격의 기회를 연다). <https://www.platinumgames.com/official-blog/article/4717> 고스트 오브 쓰시마의 퍼펙트 패리도 상대를 멈칫하게 하고 특별한 반격을 연다. <https://blog.playstation.com/?p=332432>

**이 게임에 옮기기** 상대가 **무너지는 순간**에 0.3배속 0.25~0.35초(제안값). 무너짐은 "이제 유효타를 넣을 차례"라는 가장 중요한 읽을거리이므로 느려지는 것이 그대로 귀띔이 된다. 대련에서는 "치지 마라"를 읽을 시간도 된다. 흔한 패리에는 쓰지 않는다(이어 베기의 박자가 깨진다).

### 1.12 관대한 입력(버퍼·코요테 타임) — [읽기·보상]

**수치** 마리오는 점프를 1~2프레임, Braid는 0.23초 받아 둔다(Pichlmair·Johansen). 셀레스트의 코요테 타임 5프레임(2차). <https://maddymakesgames.com/articles/celeste_and_forgiveness/> 격투 게임은 히트스톱 동안의 입력을 받아 둔다(sonichurricane).

**왜 타격감인가** 누른 것이 먹지 않으면 손맛 이전에 "씹혔다"가 된다. 히트스톱을 늘리면 그 동안의 클릭이 버려질 위험이 커진다.

**이 게임에 옮기기**
- **히트스톱 동안의 좌클릭은 버리지 않고** 멈춤이 풀리는 프레임에 낸다.
- 패리로 빈틈이 열리기 직전(제안값 100~130ms)에 누른 공격은 빈틈의 첫 프레임에 낸다 — 섣부른 공격으로 치지 않는다(안 열린 막기 뒤 0.6초의 유예와 같은 결).
- 이것은 판정을 건드리므로 규칙 변경이다. 실행 전에 계획과 검토를 거친다.

### 1.13 진동이 없을 때의 대체 — [읽기·보상]

**근거** 진동을 넣으면 낮은 주스든 높은 주스든 경험이 좋아졌다(벽돌깨기, 38명). <https://uwaterloo.ca/haptic-experience-lab/node/48> 마우스에는 진동이 없다. VR 검술 Until You Fall은 힘의 되먹임이 없는 것을 **또렷한 공방의 박자**로 메웠다(Road to VR 평). <https://www.roadtovr.com/beat-saber-instructed-motion-until-you-fall-inside-xr-design/2/>

**이 게임에 옮기기** 손에 오는 것이 없으니 (1) 소리의 낮은 성분(§3.2의 몸통), (2) 내 칼 그림의 되튐(§5.1), (3) 짧은 방향 킥으로 대신한다. 마우스 커서(조준)를 게임이 움직이는 것은 하지 않는다 — 조준이 흐트러진다.

---

## 2. 패리의 쾌감 — 게임마다 성공 순간에 하는 일

| 게임 | 성공 순간에 하는 일 | 확인 |
|---|---|---|
| **Sekiro** | 튕겨내기는 날카롭고 높은 금속음 + 접점의 큰 주황 불꽃, 일반 가드는 둔한 소리와 작은 효과. 칼끼리는 밝고 높은 소리, 주먹·발은 둔한 소리. 체간 게이지가 눈에 보이게 찬다. 튕겨내기 창은 기본 30프레임, 가드를 막 뗐다 누르면 7프레임으로 줄어 연타를 막는다 | 소리·불꽃은 이용자 글과 공략 (2차) <https://www.ludo.guide/guide/sekiro-shadows-die-twice/core-mechanics/deflection>, 창은 팬 위키 <https://sekiroshadowsdietwice.wiki.fextralife.com/Deflection>. 개발사의 설명은 찾지 못했다 |
| **Street Fighter III 3rd Strike** | 긴 정지. 패리한 쪽은 16프레임의 정지 동안 다음 막기·패리로 넘어갈 수 있고, 맞은 쪽은 더 길게 묶인다(세기별로 +4/+3/+2프레임). 입력 창은 보통 기술 3프레임, 필살기 2프레임(포럼 글) | 위키 요약 (2차). 원문 페이지는 봇 차단으로 못 읽었다. 파란 섬광은 **확인 못 함**(기억) |
| **Punch-Out!!(Wii)** | 상대의 예비 동작이 크게 과장되고 일관된다(색이 번쩍임, 외침). 표정과 포즈의 과장이 손맛의 큰 몫 | 평·소개 글 (2차) <https://www.neatorama.com/2020/05/14/Examining-The-Animation-of-Punch-Out-Wii>. 카운터의 별·기절 포즈의 프레임은 **확인 못 함** |
| **Ghost of Tsushima** | 막기를 누르고 있다가 닿기 직전에 누르면 패리, 퍼펙트 패리는 상대를 멈칫하게 하고 특별한 반격을 연다. 공격의 종류는 번쩍임(글린트)으로 미리 알린다 — God of War의 고리에서 왔다(Ted Fishman). 전투에 "자연스러운 박자와 음악성" | <https://blog.playstation.com/?p=332432> · <https://blog.playstation.com/?p=370399> · <https://www.asoundeffect.com/ghost-of-yotei-game-audio/>. 슬로모션의 길이와 패리 소리의 설계는 **확인 못 함** |
| **For Honor** | 패리가 시작될 때의 시각 효과를 **더 세게** 해서 반격 창이 더 길다는 것을 알린다(시즌 5) | <https://www.ubisoft.com/en-us/game/for-honor/news-updates/1ZO1qG5mqCaURiMFVgwlJl/season-5-core-fight-update> |
| **Kingdom Come: Deliverance** | 퍼펙트 블록은 스태미나를 쓰지 않고, 그 뒤의 반격이 리포스트다(상대는 퍼펙트 블록으로만 막는다). 창의 맨 앞에서 누르면 마스터 스트라이크(자동으로 이어지는 막을 수 없는 반격). 늦으면 퍼펙트 블록으로 떨어진다 | <https://kingdomcomedeliverance.wiki.gg/wiki/Master_Strike>. 슬로모션·초록 방패는 **확인 못 함** |
| **Infinity Blade** | 공격이 오는 방향으로 쓸어 패리. **연속 공격의 마지막을 패리하면** 거인이 기절해 반격 창이 길어진다 | <https://infinityblade.fandom.com/wiki/Combat> (2차) |
| **Metal Gear Rising** | "공격은 공격으로 막는다, 방어가 공격의 기회를 연다"(사이토). 패리 뒤 적이 무력화되면 슬로모션의 블레이드 모드 | <https://www.platinumgames.com/official-blog/article/4717>. 섬광·소리의 세부는 **확인 못 함** |
| **Until You Fall(VR)** | 적의 공격 단계가 또렷하고 막을 자리를 화면이 가리킨다. 힘의 되먹임이 없는 것을 공방의 박자로 메운다. 소리의 목표도 "강하게 느끼게, 그리고 일어난 일을 또렷하게" | <https://developers.meta.com/horizon/blog/schell-games-shares-the-developer-process-behind-until-you-fall-now-available-on-oculus-quest/> |
| **Hellish Quart** | 칼이 물리로 실제 부딪힌다. 휙 소리를 애니메이션에 맞추는 손질이 패치에 있다 | <https://www.hellishquart.com/presskit>. 소리 설계의 설명은 못 찾았다 |
| **Sifu** | 반례: 막기·피하기·패리가 한 버튼이고 "피드백이 모자라" 무엇이 됐는지 모르겠다는 평 | <https://www.slantmagazine.com/games/sifu-review/> |
| Nidhogg, Mordhau/Chivalry, Furi, Blade & Sorcery | 이번 조사에서 쓸 만한 출처를 찾지 못했다 | **확인 못 함** |

### 여기서 뽑은 규칙

1. **패리와 막기는 소리부터 다르다.** Sekiro의 핵심은 두 결과가 눈을 떼고도 갈린다는 것이다(높고 맑고 길게 대 둔하고 짧게). 지금 이 게임은 패리와 막기가 같은 비프음의 갈래다. → §3.3.
2. **패리는 맞히는 것보다 길게 멈춘다.** 3rd Strike의 패리 정지 16프레임(267ms)은 그 게임의 보통 타격보다 길다. 패리가 가장 어려운 입력이므로 가장 긴 멈춤으로 갚는다.
3. **반격 창이 열렸는지, 얼마나 큰지를 패리 순간의 효과로 알린다**(For Honor). 이 게임은 "열리면 파란색 / 안 열리면 낮은 소리와 '틈을 안 준다'"가 이미 있다. 여기에 **창의 크기**(큰 공격·마지막 박의 패리로 크게 열림)를 섬광의 세기·소리의 꼬리 길이로 한 단 더 싣는다.
4. **연속 공격의 마지막 패리에 가장 큰 상**(Infinity Blade). 이 게임의 이어 베기·엇박의 마지막 박과 같은 구조다. 박마다 소리의 음높이를 올리다가 마지막에 가장 높고 길게 → §3.4.
5. **피드백이 모자란 한 버튼 방어는 욕을 먹는다**(Sifu). 우클릭 하나로 막기·패리를 하는 이 게임에서 두 결과가 한 프레임 안에 갈려 보여야 하는 까닭이다.
6. **1인칭·정면에서 "내 칼이 닿았다"를 전하는 법**: (a) 내 칼 그림이 닿은 자리에서 멈춘다, (b) 상대의 그 부위만 번쩍이고 자세가 바뀐다, (c) 닿은 점의 방향 불꽃, (d) 소리. Until You Fall과 God of War 모두 화면을 흔드는 것보다 **표적의 반응**에 기댄다.

---

## 3. 소리

### 3.1 소리의 몫

- Lin 외: 타격감의 세 기둥 가운데 하나가 "sound coherence"(화면에서 일어난 일과 소리가 맞물리는가). <https://arxiv.org/abs/2208.06155>
- "That Sound's Juicy!"(TU/e): 같은 게임의 주스 소리 있는 판과 없는 판을 견줬더니 있는 판에서 현존감(몰입, 감각의 충실도)이 유의하게 높았다. <https://research.tue.nl/en/publications/that-sounds-juicy-exploring-juicy-audio-effects-in-video-games/>
- God of War: "Hit impact sounds are huge" — 도끼는 낮은 성분이 많은 힘의 타격으로 시작해 높은 주파수의 베는 소리로 끝난다(Wohlwend). <https://blog.playstation.com/?p=370399>
- 흔히 도는 "타격감의 절반 이상이 소리"라는 말의 출처는 찾지 못했다(기억, 인용하지 않는다).

**결론** 지금의 사인파 비프음은 금속도 타격도 아니다. 사인파에는 배음도 잡음도 없어서 "닿았다"가 아니라 "알림이 울렸다"로 들린다. **녹음 없이 코드로 합성해도** 아래 세 층만 갖추면 차이가 크다.

### 3.2 임팩트 소리의 세 층

실무의 통설(2차: 실무자 글과 음향 안내서. 학술 출처는 아님)은 **날카로운 첫 타격 + 무거운 몸통 + 짧은 꼬리**로 쌓는 것이다. 칼 소리 안내서도 "맨 처음의 접촉(attack)"과 "울림(ring)"을 가르고, 센 타격에는 낮은 웅 소리를 깔며, 울림은 실제보다 길고 밝게 해도 된다고 한다. <https://pixflow.net/blog/?p=90160>

| 층 | 구실 | 합성 (제안값) |
|---|---|---|
| 트랜지언트 | "닿았다"의 순간. 타이밍이 이것으로 읽힌다 | 흰 잡음 3~8ms, 감쇠가 아주 빠름, 고역 통과 |
| 몸통 | 무게. 진동을 대신한다 | 80~160Hz 사인이 60~90ms 동안 음높이가 떨어지며 사라짐 |
| 꼬리(울림) | 재질. 금속인지, 잘 받았는지 | 비조화 부분음 4~6개, 150~600ms의 지수 감쇠 |

### 3.3 금속 소리의 합성

- **모달 합성(가장 근거가 단단하다)**: 물체의 고유 진동수마다 감쇠하는 사인파를 더한다. Mengual·Moffat·Reiss(AES 2016, "Modal Synthesis of Weapon Sounds")는 무기 소리의 주파수 봉우리를 뽑아 덧셈 합성과 진폭 엔벌로프로 실시간 변주를 만들었고, 청취 평가의 7개 가운데 4개에서 녹음과 맞먹었다. <https://qmro.qmul.ac.uk/xmlui/handle/123456789/13348> Microsoft Research의 방법은 녹음 한 개에서 모달 모델을 뽑아 변주를 만들며 Crackdown 2에 실렸다. <https://microsoft.com/en-us/research/?p=309038>
- **FM 합성**: 금속 소리는 배음이 정수배가 아니라서 덧셈 합성으로는 맞추기 어렵고 FM이 낫다는 것은 실무자의 의견이다(포럼, 2차). 정수가 아닌 반송파:변조파 비율(예 1:1.4, 1:2.76)에 변조 깊이를 빠르게 줄이면 "팅"이 난다(기억).
- **칼 소리의 주파수 대역**: 측정값을 실은 출처를 **찾지 못했다**. "2~6kHz에 '팅'이 있다"는 것은 (기억)이다. 합성한 뒤 귀로 맞추는 수밖에 없다.
- 합성 소리는 녹음보다 "너무 합성 같다"고 들리기 쉽다는 평가 연구가 있다. <https://www.smc2019.uma.es/articles/P1/P1_05_SMC2019_paper.pdf> 잡음 트랜지언트와 판마다의 작은 변주가 그것을 덜어 준다.

**이 게임에 옮기기 — 결과마다 다른 재료로**

| 결과 | 소리의 꼴 (제안값) |
|---|---|
| 패리 | 트랜지언트 + 부분음 높게(기음 1.8~2.4kHz, 비율 1 : 1.5 : 2.3 : 3.1 : 4.2쯤), 꼬리 450~600ms. 맑고 길다 |
| 크게 열린 패리(큰 공격·마지막 박) | 위에 한 옥타브 위의 부분음 하나와 꼬리 +200ms |
| 막기(쥐고 막음) | 트랜지언트 + 낮고 적은 부분음(기음 600~900Hz, 2~3개), 꼬리 80~120ms. 둔하고 짧다 |
| 안 열린 막기 | 막기 소리에서 꼬리를 자르고 낮은 몸통만(지금의 "낮은 소리"를 잇는다) |
| 내 칼이 스침 | 잡음 띠(밴드패스 1.5~3kHz, 40ms) + 짧은 몸통. 금속 울림 없음(살과 옷) |
| 유효타 | 스침 + 몸통을 크고 길게(120ms) + 낮은 금속 울림 한 번 |
| 내가 맞음 | 몸통 위주(60~100Hz), 저역 통과된 잡음. 어둡다 |
| 송곳에 걸림·피함 | 지금의 구분을 유지하되 같은 세 층으로 다시 짠다 |

Godot에서는 시작할 때 코드로 표본을 계산해 `AudioStreamWAV`에 담아 두거나 `AudioStreamGenerator`로 낸다. 애셋 파일이 생기지 않는다. 나중에 녹음된 효과음이 와도 **어느 결과에 어떤 성격의 소리가 붙는지**는 그대로 주문서가 된다.

### 3.4 음높이의 변주와 오르는 음

- 되풀이되는 소리는 재생 속도를 0.95~1.05배쯤(약 ±0.85반음)으로 무작위로 흔든다. 한 반음 = 2^(1/12) ≈ 1.06배. <https://www.oreilly.com/library/view/web-audio-api/9781449332679/ch04.html> · <https://babel.speldesign.uu.se/2018/03/01/2018-03-01-maximizing-your-audio-budget-using-pitch-variation/>
- 다만 "알아보는 안전함"이 필요한 소리는 무작위로 흔들지 않는다(같은 계열 글). → **패리와 막기를 가르는 음높이 차이보다 변주가 작아야 한다.** 제안값: 변주 ±3%, 패리와 막기의 차이는 한 옥타브 이상.
- **이어지는 패리에 음을 올린다**: 출처 있는 수치는 찾지 못했다(기억: 콤보에 따라 음이 오르는 것은 흔한 손질). 고스트 오브 쓰시마의 음향 팀이 전투의 "박자와 음악성"을 말한 것이 가장 가까운 근거다. 제안값: 한 패턴 안에서 패리를 이을 때마다 +2반음, 마지막 박은 +5반음과 긴 꼬리. 이어 베기 세 박을 다 패리하면 올라가는 세 음이 들린다. 엇박 찌르기는 박자가 곧 가락이 된다.

### 3.5 휙 소리(whoosh)와 타이밍

- **합성**: 잡음에 밴드패스(또는 로패스)를 걸고 **차단 주파수와 음량을 함께 쓸어 올렸다 내린다**. 음량만 줄어드는 잡음은 휙 소리가 아니다. 짧은 것은 0.25~0.5초. <https://violetrecording.com/how-to-make-whoosh-sounds/> · <https://www.musicradar.com/tuition/tech/how-to-create-custom-sweeps-and-fx-using-noise-611502> (Andy Farnell의 "Designing Sound"가 표준 참고서이나 해당 장은 확인 못 했다.)
- **임팩트보다 앞선 휙**: 몇 ms 앞서야 하는지 적은 출처는 **찾지 못했다**. Hellish Quart가 휙 소리와 애니메이션의 맞물림을 패치로 손본 것이 중요성의 방증이다. 원리: 휙은 움직임과 함께 시작해 **닿는 프레임에 끊기고**, 그 자리에 트랜지언트가 온다.
- **이 게임에 옮기기**: 내 공격은 클릭 프레임에 80~120ms의 짧은 휙(찌르기는 높고 좁게, 베기는 넓게 쓸기). 상대의 예비 동작에는 길게 오르는 휙을 깔아 **타격의 시각을 귀로도** 읽게 한다 — 헛손질의 "짧은 바람 소리"와 뛰어드는 찌르기의 "낮고 긴 소리"가 이미 이 길을 쓴다. 예비 동작의 소리는 타격 시각까지의 남은 시간에 맞춰 음높이가 오르게 하면 박자를 읽는 데 도움이 된다(원칙 4와 같은 쪽).

### 3.6 침묵과 덕킹

출처 있는 수치는 **찾지 못했다**(기억: 큰 타격 직전에 다른 소리를 잠깐 낮추면 타격이 커 들린다). 히트스톱 동안 휙·환경 소리를 끊고 울림 꼬리만 남기는 것이 가장 값싼 꼴이다. 지금은 깔린 소리가 없어 효과가 작고, 음악과 환경음이 들어오는 5단계에서 다시 볼 일이다.

---

## 4. 역사적 검술에서 가져올 것

### 4.1 템포

- **dui tempi(두 템포)**: 막고, 그다음에 친다. 가장 느리지만 곧은 공격에 가장 안전하다.
- **stesso tempo(한 템포)**: 막기와 반격이 한 동작이다(상대의 칼을 누르며 그대로 찌른다). 가장 빠르다.
- **contratempo**: 상대가 내 템포를 노려 들어오는 것을 되받아친다. **mezzo tempo**: 큰 동작의 중간에 짧게 친다.
- 출처: <https://www.ejmas.com/jwma/articles/2000/jwmaart_hand_0500.html> · <https://marozzo.com/so-what-is-a-tempo> · <https://fool-of-swords.beehiiv.com/p/problem-contratempo>. 저자마다 말뜻이 다르고, 레이피어 사범들이 막고–치기를 실제로 얼마나 썼는지는 글마다 엇갈린다.

**옮기기** 이 게임의 "막기 → 빈틈 → 반격"은 두 템포다. 패리는 한 템포에 가깝다. **패리한 뒤 곧바로(제안값 0.35초 안) 넣은 반격**을 "한 템포의 리포스트"로 알아보고 소리(패리의 울림이 채 끝나기 전에 겹치는 타격음 — "탁-탁")와 글 한 줄로만 갚는 것은 규칙을 건드리지 않는 표현이다. 자세를 더 깎는 식의 실제 보상은 규칙 변경이므로 제안으로만 남긴다.

### 4.2 forte와 debole

칼날의 손잡이 쪽 절반이 forte(강한 곳), 끝 쪽 절반이 debole(약한 곳)이다. forte는 지렛대가 커서 막는 데 쓰고 느리며, debole는 빠르고 공격에 쓴다. 내 forte를 상대의 debole에 대면 유리한 지렛대가 된다(Capo Ferro는 둘로, Fabris는 넷으로 나눴다). <https://en.wikipedia.org/wiki/Forte_(fencing)> · <https://thearma.org/rapierglossary.htm> · <https://davidbiggs.substack.com/p/gaining-the-opponents-blade-part>

**옮기기** 화면 아래 내 칼 그림에서 **상대의 칼이 닿는 자리**를 결과로 가른다: 패리는 가드 가까이(forte)에서 받고 소리가 단단하고 맑으며 내 칼이 거의 안 밀린다. 쥐고 막은 것은 날 가운데에서 받고 둔하며 조금 밀린다. 높이·방향이 틀린 막기는 칼끝(debole)이 밀려나며 뚫린다. 불꽃이 튀는 점과 내 칼의 되튐 크기 둘만 바꾸면 된다. "잘 받았다"가 그림으로 읽힌다.

### 4.3 비트(battuta)와 바인드

비트는 상대의 칼을 쳐서 길을 여는 준비 동작이고(attaque au fer), 비트 패리는 들어오는 칼을 쳐내 반격의 길을 연다. <https://en.wikipedia.org/wiki/Glossary_of_fencing> battuta라는 말 자체의 풀이는 이번에 찾지 못했다. 바인드는 롱소드와 함께 미정 사항이다.

**옮기기** 새로 누르는 패리가 곧 비트 패리다. 패리 순간 내 칼이 상대의 칼 쪽으로 **짧게 쳐 나갔다 돌아오는**(받는 것이 아니라 치는) 움직임을 주면 "내가 했다"는 주체감이 생긴다. 쥐고 막는 것은 칼이 제자리에서 받고 밀린다.

### 4.4 sentiment du fer(칼의 감각)

프랑스 펜싱 연맹의 용어집: 상대의 칼이 내 칼에 닿은 것을 내 칼로 느끼는 지각. <https://www.ffescrime.fr/wp-content/uploads/2023/08/GLOSSAIRE-ESCRIME-SPORTIVE-octobre-2022.pdf>

**옮기기** 손에 오는 감각이 없으니 **내 칼 그림의 떨림**으로 옮긴다. 막기를 쥐고 있을 때 상대의 예비 동작이 내 칼 쪽으로 올수록 칼끝이 아주 작게 긴장하고(1~2px), 닿으면 닿은 방향으로 밀렸다 스프링으로 돌아온다. 엉킴 게이지의 경고와도 한 계통이다.

### 4.5 "tac"과 리포스트 du tac au tac

"riposte du tac au tac"이 같은 용어집에 리포스트의 한 갈래로 실려 있는 것까지는 확인했다. 그 뜻(패리의 소리에 곧바로 이어지는 리포스트)과 "칼 부딪는 소리로 박자를 가르친다"는 전통은 **출처로 확인하지 못했다**(기억). 다만 스포츠 펜싱에서 리포스트가 늦으면 우선권을 잃는다는 것은 확인된다. <https://en.wikipedia.org/wiki/Riposte>

### 4.6 런지

뻗고–발–회수의 순서를 적은 출처는 이번에 모으지 못했다(기억: 팔이 먼저 뻗고 발이 따라가며, 회수는 뒷다리로 당긴다). 옮기기: 내 런지의 그림에서 칼이 먼저 2~3프레임 뻗고, 그 뒤에 화면(상대)이 다가오게 하면 "팔 먼저"가 된다.

---

## 5. 1인칭·펀치아웃 꼴에서 특히 통하는 것

### 5.1 내 칼의 뷰모델 — [읽기·보상] ★

화면 아래의 손과 칼은 **플레이어의 몸**이다. 진동이 없는 게임에서 반작용을 보여 줄 수 있는 유일한 곳이다. 1인칭 게임의 실무 지침: 타격이 닿았는지에 따라 휘두름의 그림을 가르고(닿음/헛침), 닿으면 시점을 짧게 찬다. <https://docs.facepunch.com/s/sbox-dev/doc/first-person-weapons-OFv2GIW4Jf> 무기의 힘은 "표적의 반응과, 되튀는 내 팔"로 판다(2차). 흔들림과 되튐은 스프링으로 부드럽게 한다(2차: 총기 뷰모델의 관례).

**이 게임에 옮기기 (제안값)**
- **닿았을 때**: 칼이 표적에서 멈춘다(히트스톱) → 반대 방향으로 12~20px, 3~6° 되튄다 → 0.2초의 감쇠 스프링으로 제자리.
- **막혔을 때(섣부른 공격)**: 칼이 가다가 **상대의 칼에 걸려** 중간에서 튕겨 나온다. 되튐이 더 크고 0.3초 동안 떤다. "막혔다"가 글보다 먼저 읽힌다.
- **헛쳤을 때**: 멈춤 없이 지나쳐 넘친다. 닿았을 때와의 대비가 닿은 맛을 만든다.
- **패리**: 칼이 상대 쪽으로 짧게 쳐 나간다(§4.3) → 단단히 멈춘다 → 거의 안 밀린다.
- **쥐고 막음**: 받은 방향으로 8~14px 밀렸다 돌아온다. 밀착에서는 더 크게.
- **내가 맞음**: 손과 칼이 화면 아래로 20~30px 떨어졌다 올라온다(0.3초).
- 조준을 따라가는 칼에 아주 작은 늦음(스웨이)을 주면 정지 화면이 살아 보인다. 조준 칸의 판정은 건드리지 않고 그림만.

### 5.2 상대의 피격 자세 — §1.3

펀치아웃의 손맛은 큰 예비 동작과 큰 리액션 포즈의 쌍에서 온다. 예비 동작은 이미 크다. **리액션이 그만큼 크지 않은 것**이 지금의 불균형이다.

### 5.3 타격 지점의 방향 있는 효과 — §1.9

### 5.4 피격을 알리는 가장자리 — [읽기·보상]

Pichlmair·Johansen의 "색 번쩍임"과 "임팩트 마커"(들어온 타격의 방향·세기를 가리킨다). 1인칭에서는 내 몸이 안 보이므로 화면 가장자리가 그 자리다.

**옮기기** 내가 맞으면 **맞은 쪽 가장자리**(왼쪽 베기면 왼쪽)에 붉은 비네트가 2프레임에 차올랐다 0.35초에 빠진다. 방향 킥(§1.8)과 같은 쪽으로. 자세가 0에 가까우면 옅은 비네트가 남아 "다음에 맞으면 끝"을 알린다(지금의 자세 칸 표시를 돕는다). 타격의 빨강과 겹치니 채도를 낮추거나 가장자리에만 둔다.

### 5.5 간격을 쓴다

상대의 크기가 간격을 나타내므로, 유효타에 상대가 한 걸음 물러나듯 **잠깐 작아졌다**(0.97배) 돌아오면 2D 정면 시점에서 넉백이 "뒤로"로 읽힌다. 간격 표현과 헷갈리지 않게 0.2초 안에 돌아와야 한다.

---

## 6. 효과 대비 비용이 큰 순서

꼬리표: **[읽]** = 읽기를 돕고 보상을 또렷하게 한다 / **[과]** = 화려함·세기를 늘린다. 비용은 코드만 쓰는 것을 전제로 한 어림이다.

| # | 할 일 | 꼬리표 | 비용 | 까닭 |
|---|---|---|---|---|
| 1 | **소리를 세 층으로 합성하고 결과마다 재료를 가른다** — 패리는 높고 맑고 길게, 막기는 둔하고 짧게, 스침은 금속 울림 없이 (§3.2~3.3) | 읽 | 중 | 근거가 가장 단단하고(세 기둥의 하나, 현존감 실험) 지금 가장 빈 곳이다. 사인파 비프음을 그대로 두고는 다른 손질의 효과가 반감된다. 패리와 막기가 귀로 갈리는 것은 Sekiro의 핵심이기도 하다 |
| 2 | **맞은 자세로 튀기** — 부위·방향별 파츠 각도 한 벌, 히트스톱 동안 붙들고 천천히 복귀 (§1.3) | 읽 + 과 | 중 | "몸 전체가 밀리는 움찔"이 아쉬운 직접 원인. 실루엣이 바뀌어야 맞은 것으로 읽힌다. 어느 부위를 쳤는지가 그대로 보여 의뢰 수행을 돕는다. 컷아웃이라 그림 없이 된다 |
| 3 | **내 칼의 반작용** — 닿으면 멈췄다 되튐, 막히면 튕겨 나옴, 헛치면 지나침, 패리는 쳐 나감 (§5.1, §4.2~4.3) | 읽 | 저~중 | 진동이 없는 게임에서 반작용을 보일 유일한 곳. 닿음·막힘·헛침이 글보다 먼저 손 쪽에서 읽힌다 |
| 4 | **히트스톱을 결과별로 다시 나누고 떨림을 더한다** — 패리·무너뜨림·유효타를 길게(130~300ms), 그림만 좌우로 감쇠하며 떨기, 판의 시계도 함께 멈춤 (§1.1~1.2) | 읽 + 과 | 저 | 지금의 50~120ms는 격투 게임의 약공격보다 짧다. 가장 어려운 입력에 가장 긴 멈춤을 주는 것은 3rd Strike의 방식. 값만 바꾸면 된다 |
| 5 | **히트스톱·빈틈 직전의 입력을 받아 둔다** (§1.12) | 읽 | 저 | 4번으로 멈춤이 길어지면 씹히는 클릭이 생긴다. 씹힘은 타격감 이전의 문제다. 규칙에 닿으니 계획·검토를 거친다 |
| 6 | **맞은 파츠만 1~2프레임 희게 + 닿은 점의 방향 불꽃** (§1.9) | 읽 | 저 | 어디를 어느 방향으로 쳤는지가 한 프레임에 읽힌다. 화면 전체를 건드리지 않아 고리 읽기를 방해하지 않는다 |
| 7 | **이어지는 패리에 오르는 음, 마지막 박은 가장 높고 길게** (§3.4) | 읽 | 저 (1번 뒤) | 이어 베기·엇박·층층의 "다 받아냈다"를 가락으로 갚는다. 박자를 귀로 세게 돕는다. 빈틈의 크기도 꼬리 길이로 알린다(For Honor의 방식을 소리로) |
| 8 | **칼끝의 잔상 띠와 휙 소리** — 휙은 닿는 프레임에 끊긴다 (§1.5, §3.5) | 읽 + 과 | 저 | 내 칼이 어느 칸으로 갔는지 보이고, 휙이 끊기며 트랜지언트가 오는 대비가 닿은 순간을 세운다 |
| 9 | **내가 맞았을 때의 방향 킥과 가장자리 비네트** (§1.8, §5.4) | 읽 | 저 | 1인칭에서 내 몸이 안 보이는 것을 메운다. 어느 쪽에서 맞았는지 알면 다음에 어디를 막을지 배운다 |
| 10 | **무너지는 순간의 짧은 슬로모션** (§1.11) | 읽 + 과 | 저 | 한 판에 한두 번뿐인 가장 중요한 읽을거리("이제 유효타"/"치지 마라")에 시간을 준다 |
| 11 | 유효타의 줌 펀치와 작은 화면 흔들림 (§1.10, §1.8) | 과 | 저 | 판을 끝내는 한 방에만. 스침·막힘·패리에는 쓰지 않는다 — God of War가 흔들림을 줄인 까닭과 같다 |
| 12 | 스쿼시 & 스트레치 (§1.6) | 과 | 저 | 2번이 있으면 덤은 작다. 화풍과 맞는지 보고 정한다 |

**차례의 까닭** 1~3은 "닿았다"의 세 통로(귀, 상대, 내 손)를 각각 채우고, 셋 다 지금 비어 있거나 약하다. 4~7은 값·작은 코드로 되고 읽기를 돕는다. 10~12는 과장 쪽이라 가장 뒤에, 드문 순간에만 둔다. Kao의 결과(극단의 주스는 없는 것만큼 나쁘다, 성공에 달린 피드백이 동기를 올린다)에 따라 **스침·막기에는 아끼고 패리·무너뜨림·유효타에 몰아준다.**

**하지 말 것**
- 스침·막기마다 화면을 흔들기 — 다음 고리를 읽어야 한다.
- 패리마다 슬로모션 — 이어 베기의 박자가 깨진다.
- 패리와 막기의 소리 차이를 넘는 무작위 음높이 변주.
- 조준 커서를 게임이 움직이는 것.
- 예비 동작을 짧게 하거나 반응 창을 줄여 "타이트하게" 만드는 것 — 타격감이 아니라 난이도가 바뀌고 원칙 4에 어긋난다.

---

## 7. 확인하지 못한 것

- **Steve Swink, "Game Feel"**: 책의 본문은 보지 못했다. 이 문서의 어떤 수치도 그 책에 기대지 않았다.
- **Vlambeer "The Art of Screenshake"**: 영상은 못 봤다. 손질 30개의 온전한 목록과 밀리초 값은 2차 자료로도 다 확인하지 못했다.
- **"Juice it or lose it"**: 영상은 못 봤다. 소개 글만.
- **사쿠라이의 유튜브 강의**: 영상은 못 봤다. 같은 내용의 파미통 칼럼(팬 번역)으로 갈음했다.
- **God of War·Monster Hunter의 GDC 강연**: GDC Vault는 회원 전용이라 본문을 못 봤다. God of War는 PlayStation 블로그의 개발자 발언으로, 몬스터 헌터는 기사가 옮긴 팬의 프레임 대조로 갈음했다.
- **3rd Strike의 패리**: 원문 위키는 봇 차단으로 못 읽었고 검색 요약의 수치만 있다. 파란 섬광은 확인 못 했다.
- **Sekiro**: 개발사의 음향 설명은 못 찾았다. 소리·불꽃의 묘사는 이용자 글이고, "퍼펙트"가 따로 있는지조차 이용자들 사이에 엇갈린다. 튕겨내기 창의 값도 출처마다 다르다(30프레임 대 12프레임).
- **Ghost of Tsushima의 패리 소리·슬로모션 길이, Metal Gear Rising의 섬광·소리, Kingdom Come의 슬로모션**: 확인 못 했다.
- **Nidhogg, Mordhau/Chivalry, Furi, Blade & Sorcery, Punch Club**: 쓸 만한 출처를 못 찾았다.
- **Punch-Out!!의 별·기절 포즈의 프레임**: 확인 못 했다(New Frame Plus의 영상은 못 봤다).
- **칼 소리의 주파수 측정값, 휙이 임팩트보다 앞서는 ms, 덕킹의 수치, 콤보에 따라 음을 올리는 반음 수**: 출처를 못 찾았다. 본문의 값은 제안값이거나 (기억)이다.
- **"tac"으로 박자를 가르치는 전통, tac-au-tac의 뜻, 런지의 몸 쓰임, battuta의 풀이**: 출처로 확인 못 했다.
- **Lin 외의 19가지 요소 목록과 "sound coherence"의 정의**: 초록만 읽었다(PDF 본문은 글이 뽑히지 않았다).
- **Kao(2020)의 원문 표**: 2차 요약만.
- 본문의 **제안값은 전부 재 보지 않은 출발점**이다. 화면 찍기와 봇 통계, 그리고 사용자의 손으로 맞춰야 한다.

---

## 8. 출처 모음

**연구**
- Lin, Duan, Wen, Cai (2022) What Features Influence Impact Feel? — <https://arxiv.org/abs/2208.06155>
- Pichlmair, Johansen (2020) Designing Game Feel: A Survey — <https://arxiv.org/abs/2011.09201>
- Kao (2020) The effects of juiciness in an action RPG — DOI 10.1016/j.entcom.2020.100359
- Kao 외 (2024) How does juicy game feedback motivate? — <https://spiral.imperial.ac.uk/entities/publication/253c32f5-d124-4a23-88b5-9aaaf114608d>
- That Sound's Juicy! Exploring Juicy Audio Effects in Video Games — <https://research.tue.nl/en/publications/that-sounds-juicy-exploring-juicy-audio-effects-in-video-games/>
- 진동과 주스(워털루 대학) — <https://uwaterloo.ca/haptic-experience-lab/node/48>
- Mengual, Moffat, Reiss (2016) Modal Synthesis of Weapon Sounds — <https://qmro.qmul.ac.uk/xmlui/handle/123456789/13348>
- Microsoft Research, Sound Synthesis for Impact Sounds in Video Games — <https://microsoft.com/en-us/research/?p=309038>
- Perceptual Evaluation of Modal Synthesis for Impact-Based Sounds — <https://www.smc2019.uma.es/articles/P1/P1_05_SMC2019_paper.pdf>

**개발자의 말과 분석**
- God of War(2018)의 전투를 다른 개발자들이 풀이 — <https://blog.playstation.com/?p=370399>
- 사쿠라이의 히트스톱 칼럼(팬 번역) — <https://sourcegaming.info/2015/11/11/thoughts-on-hitstop-sakurais-famitsu-column-vol-490-1/>
- 스매시의 hitlag 공식 — <https://ssbwiki.com/Hitlag>
- Impact Freeze(스트리트 파이터) — <https://sonichurricane.com/?p=1043>
- Anatomy of an Enemy Attack in Dark Souls 3 — <https://www.gamedeveloper.com/game-platforms/anatomy-of-an-enemy-attack-in-dark-souls-3>
- Vlambeer의 강연 소개 — <https://gamedeveloper.com/design/vlambeer-co-founder-shares-advice-on-building-better-action-games>
- Juice It or Lose It — <https://gdcvault.com/play/1016487/Juice-It-or-Lose>
- 화면 흔들림(트라우마) 구현 — <https://kidscancode.org/godot_recipes/3.x/2d/screen_shake/> · <https://bevy.org/examples/camera/2d-screen-shake/>
- 몬스터 헌터 와일즈의 히트스톱 — <https://pcgamer.com/games/rpg/capcom-if-youre-listening-monster-hunter-wilds-needs-its-hitstop-back>
- 액션 게임의 얼개 — <https://canmom.art/crit/mechanisms-of-action-games>
- Celeste & Forgiveness — <https://maddymakesgames.com/articles/celeste_and_forgiveness/>
- 1인칭 무기의 뷰모델 — <https://docs.facepunch.com/s/sbox-dev/doc/first-person-weapons-OFv2GIW4Jf>

**패리·검술 게임**
- Sekiro — <https://sekiroshadowsdietwice.wiki.fextralife.com/Deflection> · <https://www.ludo.guide/guide/sekiro-shadows-die-twice/core-mechanics/deflection>
- Ghost of Tsushima — <https://blog.playstation.com/?p=332432> · <https://www.asoundeffect.com/ghost-of-tsushima-sound/>
- For Honor — <https://www.ubisoft.com/en-us/game/for-honor/news-updates/1ZO1qG5mqCaURiMFVgwlJl/season-5-core-fight-update>
- Kingdom Come: Deliverance — <https://kingdomcomedeliverance.wiki.gg/wiki/Master_Strike>
- Infinity Blade — <https://infinityblade.fandom.com/wiki/Combat>
- Metal Gear Rising — <https://www.platinumgames.com/official-blog/article/4717>
- Until You Fall — <https://developers.meta.com/horizon/blog/schell-games-shares-the-developer-process-behind-until-you-fall-now-available-on-oculus-quest/> · <https://www.roadtovr.com/beat-saber-instructed-motion-until-you-fall-inside-xr-design/2/>
- Hellish Quart — <https://www.hellishquart.com/presskit>
- Punch-Out!!(Wii) — <https://www.neatorama.com/2020/05/14/Examining-The-Animation-of-Punch-Out-Wii>
- Sifu 평 — <https://www.slantmagazine.com/games/sifu-review/>

**소리**
- 음높이 변주 — <https://www.oreilly.com/library/view/web-audio-api/9781449332679/ch04.html> · <https://babel.speldesign.uu.se/2018/03/01/2018-03-01-maximizing-your-audio-budget-using-pitch-variation/>
- 휙 소리 — <https://violetrecording.com/how-to-make-whoosh-sounds/> · <https://www.musicradar.com/tuition/tech/how-to-create-custom-sweeps-and-fx-using-noise-611502>
- 칼 소리의 층 — <https://pixflow.net/blog/?p=90160>

**역사적 검술**
- 템포 — <https://www.ejmas.com/jwma/articles/2000/jwmaart_hand_0500.html> · <https://marozzo.com/so-what-is-a-tempo> · <https://fool-of-swords.beehiiv.com/p/problem-contratempo>
- forte와 debole — <https://en.wikipedia.org/wiki/Forte_(fencing)> · <https://thearma.org/rapierglossary.htm> · <https://davidbiggs.substack.com/p/gaining-the-opponents-blade-part>
- 용어(sentiment du fer, 리포스트의 갈래) — <https://www.ffescrime.fr/wp-content/uploads/2023/08/GLOSSAIRE-ESCRIME-SPORTIVE-octobre-2022.pdf> · <https://en.wikipedia.org/wiki/Glossary_of_fencing> · <https://en.wikipedia.org/wiki/Riposte>
