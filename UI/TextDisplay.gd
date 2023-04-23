extends CanvasLayer

signal no_facts_are_displayed()

var all_facts = []
var displayed_facts = {}

func node_for_fact(fact):
	match fact:
		State.FACT.SPACEBAR:
			return $Spacebar
		State.FACT.PARACHUTE:
			return $Parachute
		State.FACT.SLINGSHOT:
			return $Slingshot

func was_hidden(fact):
	displayed_facts[fact] = false
	State.fact_was_displayed(fact)
	for still_displayed in displayed_facts.values():
		if still_displayed: return
	print("No more facts are displayed")
	emit_signal("no_facts_are_displayed")

func maybe_display_facts():
	for fact in State.fact_state:
		var state = State.fact_state[fact]
		var node = node_for_fact(fact)
		if state == State.FACT_STATE.SHOULD_DISPLAY:
			print("displaying a fact %s" % fact)
			node.show()
			displayed_facts[fact] = true
			node.connect("fade_complete", self, "was_hidden", [fact])
		else:
			node.hide()

	if len(displayed_facts) == 0:
		print("No facts are displayed")
		emit_signal("no_facts_are_displayed")

func _ready():
	for fact in State.FACT.values():
		node_for_fact(fact).hide()
