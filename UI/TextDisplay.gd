extends CanvasLayer

signal no_facts_are_displayed()

var all_facts = []
var displayed_facts = {}

func nodes_for_fact(fact):
	match fact:
		State.FACT.INTRO:
			return [$Spacebar, $Spacebar2]
		State.FACT.PARACHUTE:
			return [$Parachute]
		State.FACT.SLINGSHOT:
			return [$Slingshot]
		State.FACT.GRIFFIN:
			return [$Griffin]

func maybe_display_facts():
	for fact in State.fact_state:
		var state = State.fact_state[fact]
		var nodes = nodes_for_fact(fact)
		if state == State.FACT_STATE.SHOULD_DISPLAY:
			print("displaying a fact %s" % fact)
			for node in nodes:
				node.show()
				yield(node, "fade_complete")
				yield(get_tree().create_timer(.1), "timeout")
				node.hide()
			State.fact_was_displayed(fact)
		
	emit_signal("no_facts_are_displayed")

func _ready():
	for fact in State.FACT.values():
		for node in nodes_for_fact(fact):
			node.hide()
