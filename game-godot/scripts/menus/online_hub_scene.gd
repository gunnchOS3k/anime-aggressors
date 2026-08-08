extends "res://scripts/ui/console_menu_base.gd"

## Online hub: private / unranked / ranked (private/dev architecture only).

const _OnlineMM = preload("res://scripts/net/online_matchmaking_architecture.gd")
const _Private = preload("res://scripts/net/private_netplay_stack.gd")

var _status: Label
var _mm


func _ready() -> void:
	super._ready()
	if title_label:
		title_label.text = "Online (Dev)"
	_mm = _OnlineMM.new()
	_build()


func _build() -> void:
	var vbox := get_node_or_null("VBox") as VBoxContainer
	if vbox == null:
		return
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size = Vector2(480, 100)
	_status.text = "Private/dev only — not public deploy.\nQueues: Private · Unranked · Ranked"
	vbox.add_child(_status)
	for item in [
		["PrivateBtn", "Private Netplay Lobby", _on_private],
		["UnrankedBtn", "Unranked Queue (DEV)", _on_unranked],
		["RankedBtn", "Ranked Ladder (DEV)", _on_ranked],
		["SelfTestBtn", "Architecture Self-Test", _on_self_test],
		["BackBtn", "Back", on_back],
	]:
		var b := Button.new()
		b.name = item[0]
		b.text = item[1]
		b.custom_minimum_size = Vector2(420, 52)
		b.pressed.connect(item[2])
		vbox.add_child(b)


func _on_private() -> void:
	GameState.begin_online_queue("private")
	SceneRouter.go_online_private()


func _on_unranked() -> void:
	GameState.begin_online_queue("unranked")
	var a := _mm.enqueue_unranked("LocalA")
	var b := _mm.enqueue_unranked("LocalB")
	_status.text = "Unranked: %s" % str(b if bool(b.get("paired")) else a)


func _on_ranked() -> void:
	GameState.begin_online_queue("ranked")
	var a := _mm.enqueue_ranked("RankA")
	var b := _mm.enqueue_ranked("RankB")
	_status.text = "Ranked: %s" % str(b if bool(b.get("paired")) else a)


func _on_self_test() -> void:
	var mm := _OnlineMM.digital_self_test()
	var net := _Private.digital_pass_self_test()
	_status.text = "MM ok=%s  Netplay ok=%s  public_deploy=false" % [
		str(mm.get("ok")), str(net.get("ok")),
	]


func on_back() -> void:
	SceneRouter.go("mode_select")
