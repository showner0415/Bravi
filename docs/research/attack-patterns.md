# 공격 패턴 조사와 후보 (2026-11-24)

사용자 지시(2026-11-24): 상대의 공격이 "클릭 한 번으로 막는 단발"만 이어져 쉽게 지루해진다. 상대마다 자기만의 패턴을 갖게 하고 패턴이 다양했으면 좋겠다. 예: 클릭한 채 끌어 막는 긴 베기, 한 공격 차례에 여러 공격이 차례로 나와 순서대로 막기(osu와 비슷한 느낌). 실제 검술을 찾아 녹여 달라.

사용자가 고친 방향(같은 날):

- **지금의 느슨한 느낌을 지킨다.** osu처럼 빠른 반응으로 버티는 게임이 아니다. 관찰해서 읽고 막는 템포 그대로(설계 원칙 4).
- **재미가 먼저다.** 실제 검술은 재료일 뿐이다. 실제와 다르거나 지어낸 검술 같아도 해 보고 괜찮으면 쓴다.
- **한 판은 최대 180초까지** 늘려도 된다(원칙 1의 90초를 늘린다). 패턴을 파훼하는 재미로 길어지는 것은 괜찮다.
- 앞의 예시(끌어 막기, 순서대로 막기)는 메인의 판단으로 쓰거나 고치거나 뺀다.

이 문서는 계획을 쓰기 위한 재료다. 정한 것은 계획과 `docs/DECISIONS.md`에 적는다.

## 1. 지금 게임 (코드 읽기)

- 상대: `IDLE → TELL(예비 동작) → 타격 → RECOVERY(빈틈) → IDLE`, 자세 0이면 `STAGGER`(`scripts/ai/opponent_brain.gd`). 공격은 `AttackData` 하나가 한 번 친다(방향 셋, `tell_time`, `recovery_time`, 큰 공격, 올려 막기). 가방에서 하나씩 꺼내고, 버릇(`HabitData`, 지금은 "연속으로 막히면 큰 베기")이 끼어든다.
- 나: 우클릭을 누르고 있으면 마우스 가로 위치 쪽(왼·가운데·오른쪽)을 막는다. 타격 직전에 새로 누르면 패리. 좌클릭은 공격.
- 그래서 지금 한 차례의 공방은 "보고 → 한 방향을 막기(또는 패리) → 빈틈에 친다" 한 박이다. 상대가 바뀌어도 이 박이 같아서 단조롭다.

## 2. 비슷한 게임에서 가져올 것

- **osu!**: 원에 겹친 "다가오는 원"이 줄어드는 것으로 박자를 미리 보여 주고, 원에 붙은 번호로 순서를 보여 준다. 슬라이더는 머리를 누른 채 길을 따라 움직이는 공을 따라간다(되돌아오기 화살표도 있다). 다음에 누를 것은 조금 밝게 보인다. → **가져올 것: 순서·박자·길을 "미리" 보여 주는 표시**. 가져오지 않을 것: 빠른 밀도, 반응 속도.
- **펀치아웃!!**: 상대마다 일관된 "텔"(몸짓)이 있고, 패턴을 외우는 것과 반사 신경의 균형(미야모토). 강한 공격 직전에 치면 별을 얻는다. 뒤의 상대일수록 패턴이 많고 복잡하다. → **가져올 것: 상대마다 다른 텔과 패턴 묶음, 읽으면 보상(큰 빈틈)**.
- **세키로**: 튕겨내기가 자세를 깎고, 어떤 공격은 여러 번을 연달아 튕겨내야 반격할 수 있다. 위험 공격은 붉은 글자로 미리 알리고 공격 종류마다 다른 대응을 요구한다. 튕겨내기 판정은 넉넉하다. → **가져올 것: 연속기를 다 막으면 큰 보상, 종류마다 다른 대응을 "미리" 알리는 표시, 넉넉한 판정**.

## 3. 실제 검술에서 가져올 재료

- **볼로냐 유파(마로초, 델라고키)의 베기 이름**: 만드리토(오른쪽에서) · 리베르소(왼쪽에서), 그리고 위에서 아래로 곧게(펜덴테), 비스듬히(스괄렘브라토), 가로로(톤도), 아래에서 위로(리도피오), 바퀴처럼 크게 돌리는 베기(트라마초네). 찌르기는 임브로카타(위에서 내려 찌름) · 스토카타(아래에서 올려 찌름) · 푼타 리베르사. 마로초의 첫 아살토는 "만드리토 스괄렘브라토로 칼 팔을 넘어 → 리베르소 스괄렘브라토 → 만드리토 톤도로 다리" 처럼 베기를 잇는다.
- **카포 페로·파브리스(레이피어)**: 카바치오네(상대 칼 밑으로 돌아 반대쪽으로 빠지기), 핀타(속임수) 뒤에 빠져 찌르기, 템포의 개념 — 스테소 템포(막으며 동시에 찌름), 메초 템포(상대의 움직임 한가운데를 끊음), 콘트라템포(일부러 틈을 보여 끌어들인 뒤 받아치기).
- **리히테나워(롱소드, 나중 무기)**: 다섯 비밀 베기 — 초른하우(분노의 내려베기), 크룸프하우(휘어 베기), 츠베르히하우(가로 베기), 쉴하우(흘겨 베기), 샤이텔하우(정수리 베기). 각 베기가 특정 자세를 깬다.

## 4. 패턴 후보 (느린 템포, 미리 읽히게)

공통 규칙(제안):

- 패턴은 시작 전에 **전체 모양을 보여 준다**(osu의 번호·길처럼): 예비 동작 동안 방향 표시가 차례 번호와 함께 뜨고, 박자는 지금의 고리(어프로치 링)처럼 줄어드는 표시로 보인다.
- 박자는 지금 단발 공격의 템포 언저리(타격 사이 0.6~1.0초)로 느슨하게 둔다. 판정은 지금의 막기·패리와 같다(넉넉하게).
- 다 막으면 **큰 빈틈**(지금 회수보다 길다, 머리도 열린다 등), 하나라도 놓치면 그 타격만큼 맞고 패턴이 끝난다(벌이 쌓이지 않게).
- 상대마다 2~3개의 자기 패턴을 가진다. 데이터(`.tres`)로 더할 수 있어야 한다(원칙 5).

| # | 이름(가칭) | 하는 일 | 막는 법 | 재료 | 어울리는 상대 |
|---|---|---|---|---|---|
| A | 이어 베기(연속기) | 2~4타가 정해진 방향 순서로 박자에 맞춰 온다. 예: 오른쪽 위 → 왼쪽 위 → 오른쪽 아래 | 막기를 누른 채 마우스를 표시된 차례대로 옮긴다(새로 누르면 패리). 순서·박자가 미리 보인다 | 마로초 첫 아살토의 만드리토–리베르소–톤도 | 바르톨로(허세 섞인 화려한 연결) |
| B | 휩쓸기(긴 베기) | 칼이 한쪽에서 반대쪽으로 길게 지나간다(0.8~1.2초) | 막기를 누른 채 칼끝을 따라 끈다(osu 슬라이더). 길에서 벗어나거나 떼면 그 자리에서 뚫린다 | 트라마초네, 톤도, 츠베르히하우 | 브루노(무겁고 큰 베기) |
| C | 속임수(핀타) | 한쪽 예비 동작을 크게 보이다가 칼을 돌려(카바치오네) 반대쪽으로 친다. 바꿀 때 분명한 두 번째 표시와 넉넉한 시간 | 처음 표시에 성급히 패리하지 않고 바뀌는 것을 보고 막는다. 상대마다 "속일 때의 버릇"이 있다(예: 속일 때는 칼끝이 떨린다) | 핀타 + 카바치오네 | 바르톨로·노름꾼 같은 꾀 많은 상대 |
| D | 늦은 박자(템포 끊기) | 예비 동작을 길게 끌어 멈칫을 늘린 뒤 친다. 성급한 막기는 버티기만 되고 패리가 안 된다 | 표시된 박자(줄어드는 고리)를 끝까지 보고 막는다 | 메초 템포, 콘트라템포 | 노련한 상대 |
| E | 끌어들이기 | 일부러 빈틈처럼 보이는 자세(가짜 회수)를 보이다가 치면 받아친다. 진짜 회수와 다른 표시가 있다 | 가짜를 알아보고 치지 않는다 | 콘트라템포 | 후반 상대 |
| F | 무거운 두 번 | 큰 내려베기 뒤 바로 같은 쪽 찌르기. 첫 타가 무거워 막으면 밀린다(자세 −1) | 첫 타를 막고 바로 가운데로 옮긴다 | 초른하우 → 초른오르트(분노 베기에서 바로 찌르기) | 브루노 |

메인의 판단(사용자 지시대로 예시를 고르거나 고친다):

- **A(이어 베기)와 B(휩쓸기)는 쓴다.** 사용자의 두 예시이고, 둘 다 "미리 보이고 느린 템포"로 만들면 반응 싸움이 되지 않으면서 손맛이 다르다(A는 옮기기, B는 끌기).
- **C(속임수)도 첫 판에 넣을 만하다.** 원칙 4(관찰로 이긴다)를 가장 잘 살리는 꼴이고 CLAUDE.md 3장에 이미 계획된 "페인트"와 이어진다.
- D·E·F는 첫 판에서는 후보로 남긴다(바르톨로·브루노에 하나씩 시험해 볼 수 있다).

## 5. 정해야 할 것(계획에서 사용자에게)

- 첫 판에 넣을 패턴 종류(위 A·B·C 권함, D·F는 선택).
- 패턴의 입력: A는 "막기를 누른 채 옮기기"(새로 누르면 패리)로 할지, 박자마다 새로 누르게 할지. B는 우클릭을 누른 채 끌기로 할지.
- 다 막았을 때의 보상 크기와 놓쳤을 때의 벌.
- 상대마다의 배정(바르톨로: A·C, 브루노: B·F 같은 묶음).
- 원칙 1의 판 길이를 "30~180초"로 고친다(사용자 지시) — CLAUDE.md 2장과 DECISIONS.

## 출처

- [osu! wiki — Hit object](https://osu.ppy.sh/wiki/en/Gameplay/Hit_object), [Hit circle](https://osu.ppy.sh/wiki/en/Gameplay/Hit_object/Hit_circle), [osu!standard](https://osu.ppy.sh/wiki/Osu!standard)
- [Punch-Out!! — StrategyWiki 게임 방식](https://strategywiki.org/wiki/Punch-Out!!/Gameplay), [Iwata Asks: Punch-Out!!](https://www.nintendo.com/en-gb/Iwata-Asks/Iwata-Asks-PUNCH-OUT-/PUNCH-OUT-/5-Now-Featuring-a-Multiplayer-Mode/5-Now-Featuring-a-Multiplayer-Mode-230709.html), [Super Punch-Out! Patterns Made Fun](https://gamesbeat.com/super-punch-out-patterns-made-fun/)
- [Sekiro 게임 방식(Activision)](https://support.activision.com/sekiro/articles/sekiro-shadows-die-twice-game-mechanics), [The Art and Science of Sekiro's Combat](https://www.superjumpmagazine.com/the-art-and-science-of-sekiros-combat/), [Sekiro Deflection(fextralife)](https://sekiroshadowsdietwice.wiki.fextralife.com/Deflection)
- [Cuts of the Bolognese Tradition](https://marozzo.com/cuts-of-the-bolognese-tradition), [Marozzo glossary](https://marozzo.com/glossary), [Marozzo first assalto](https://www.academieduello.com/learn/resources/wiki/marozzo-first-assalto), [Dell'Agocchie 1572](https://jan.ucc.nau.edu/wew/fencing/agocchie.html)
- [Ridolfo Capo Ferro(위키백과)](https://Www.Wikipedia.org/wiki/Capo_Ferro), [The Arte of Defense](https://jan.ucc.nau.edu/wew/rapier.htm), [A Brief Glossary of Italian Rapier Concepts](https://thearma.org/rapierglossary.htm), [Salvator Fabris(위키백과)](https://Www.Wikipedia.org/wiki/Salvator_Fabris), [Fabris Chapter 10 요약](https://donovanshinnock.blogspot.com/2013/09/fabris-part-eight-chapter-10.html)
- [Johannes Liechtenauer(위키백과)](https://www.wikipedia.com/wiki/Johannes_Lichtenauer), [The Master Cuts(ARMA)](https://thearma.org/essays/mastercuts.html)
