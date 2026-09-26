class_name FxDamageNumber
extends FxFloatText
## A damage number that can grow: later hits in the same window add into it.

var total: float = 0.0
var base_size: int = 18
var pop_size: int = 6
var _pop: float = 0.0


func add(amount: float, highlight: Color) -> void:
	total += amount
	text = "%d" % int(round(total))
	color = highlight
	_pop = 1.0
	# Restart the fade so a number that keeps growing stays readable.
	t = minf(t, life * 0.3)


func tick(delta: float) -> void:
	super.tick(delta)
	_pop = maxf(0.0, _pop - delta * 6.0)
	size = base_size + int(round(pop_size * _pop))
