extends RefCounted
## 패턴·높이·빈틈의 확률을 끈 옛 규칙 사본. 하루의 상대로 다른 규칙을 보는 테스트가 난수 차례를 지키려고 쓴다(결정 416·426).


static func of(opponent: OpponentData) -> OpponentData:
	var copy := opponent.flat()
	copy.opening_chance = 1.0
	var singles: Array[AttackData] = []
	for atk in opponent.attacks:
		if atk.chain.is_empty():
			singles.append(atk)
	copy.attacks = singles
	return copy
