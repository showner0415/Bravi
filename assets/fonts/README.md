# 게임 글꼴

계획 033(결정 313)이 넣었다. 세 파일 모두 **고치지 않은 원본**이다. 서브셋은 6단계 글이 다 정해진 뒤, 내보내기 전에 만든다. 그때 Reserved Font Name이 있는 글꼴은 이름을 바꾼다. 셋 모두 SIL Open Font License 1.1이고, 라이선스 글을 이 폴더에 함께 둔다. 글꼴만 따로 팔 수 없다.

| 파일 | 역할 | 배포처 | 저작권 줄 | Reserved Font Name | 라이선스 글 | SHA256 앞 16자리 |
|---|---|---|---|---|---|---|
| `NanumSquareRoundEB.ttf` | 본문(나눔스퀘어라운드 ExtraBold) | `hangeul.naver.com`의 `nanum-square-round.zip` | Copyright (c) 2010, NAVER Corporation (파일 안: Copyright 2017 NAVER Corporation, designed by Sandoll) | 있다(Nanum, Naver Nanum, …, NanumSquareRound) | `OFL-NanumSquareRound.txt`, `NAVER-FONT-LICENSE-NOTICE.txt` | `9E845FC35C5BC4A5` |
| `SongMyung-Regular.ttf` | 제목(송명). 2,350자라 `·`(U+00B7)·`→`(U+2192)가 없다. 그 글자는 `assets/ui/font_title.tres`의 받침(본문 글꼴)이 그린다 | `google/fonts` `ofl/songmyung` | Copyright 2018 The SongMyung Project Authors | 없다 | `OFL-SongMyung.txt` | `7F90AB2025091156` |
| `NotoSansKR-wght.ttf` | 결투의 상태 글자(Noto Sans KR 900, 가변 글꼴) | `google/fonts` `ofl/notosanskr` | Copyright 2014-2021 Adobe | 있다(Source) | `OFL-NotoSansKR.txt` | `194018E6B2B293A7` |

- `assets/ui/font_state.tres`의 `variation_opentype = {2003265652: 900}`에서 2003265652는 OpenType 태그 `wght`의 정수다(0x77676874 = `w` 0x77, `g` 0x67, `h` 0x68, `t` 0x74).
- 게임 글의 글자 대조(계획 033 작업 1): `scripts/`·`data/`·`scenes/`의 글 461자(한글 457)에서 빠진 글자는 본문 0, 상태 0, 송명 2(`·`, `→`)다.
