extends RefCounted
class_name NetworkSim

## Deterministic latency / jitter / loss simulator for online scaffold tests.
## Delivers queued protocol envelopes after simulated delay — no sockets.

const _OnlineProtocol = preload("res://scripts/net/online_protocol.gd")

const ALPHA_CLAIM := "PRIVATE_LOOPBACK_ONLY — network sim"

var latency_ms: float = 50.0
var jitter_ms: float = 10.0
var loss_rate: float = 0.0
var _rng := RandomNumberGenerator.new()
var _queue: Array = []  # [{deliver_at_ms, msg}]
var _clock_ms: float = 0.0
var _sent: int = 0
var _dropped: int = 0
var _delivered: int = 0


func configure(seed_value: int, latency: float = 50.0, jitter: float = 10.0, loss: float = 0.0) -> void:
	_rng.seed = seed_value
	latency_ms = maxf(0.0, latency)
	jitter_ms = maxf(0.0, jitter)
	loss_rate = clampf(loss, 0.0, 0.95)
	_queue.clear()
	_clock_ms = 0.0
	_sent = 0
	_dropped = 0
	_delivered = 0


func send(msg: Dictionary) -> bool:
	_sent += 1
	if _rng.randf() < loss_rate:
		_dropped += 1
		return false
	var jitter: float = _rng.randf_range(-jitter_ms, jitter_ms)
	var delay: float = maxf(0.0, latency_ms + jitter)
	_queue.append({
		"deliver_at_ms": _clock_ms + delay,
		"msg": msg.duplicate(true),
	})
	return true


func advance(ms: float) -> Array:
	_clock_ms += maxf(0.0, ms)
	var out: Array = []
	var remain: Array = []
	for item in _queue:
		if float(item.get("deliver_at_ms", 0.0)) <= _clock_ms:
			out.append(item.get("msg", {}))
			_delivered += 1
		else:
			remain.append(item)
	_queue = remain
	return out


func stats() -> Dictionary:
	return {
		"sent": _sent,
		"dropped": _dropped,
		"delivered": _delivered,
		"queued": _queue.size(),
		"clock_ms": _clock_ms,
		"latency_ms": latency_ms,
		"jitter_ms": jitter_ms,
		"loss_rate": loss_rate,
		"alpha_claim": ALPHA_CLAIM,
	}


static func run_loopback_test(seed_value: int = 11, frames: int = 60) -> Dictionary:
	## Two sims with asymmetric latency; exchange inputs; require eventual delivery under no-loss.
	var ScriptRef = load("res://scripts/net/network_sim.gd")
	var a = ScriptRef.new()
	var b = ScriptRef.new()
	a.configure(seed_value, 40.0, 5.0, 0.0)
	b.configure(seed_value + 1, 70.0, 8.0, 0.0)
	var a_got := 0
	var b_got := 0
	for f in range(frames):
		var msg_a: Dictionary = _OnlineProtocol.encode_input(f, 0, {"attack": f % 3 == 0})
		var msg_b: Dictionary = _OnlineProtocol.encode_input(f, 1, {"special": f % 4 == 0})
		a.send(msg_a)
		b.send(msg_b)
		# Cross-deliver: A's outbound arrives at B's inbox after B advances, etc.
		# Model: each peer has an outbound sim toward the other.
		var delivered_to_b: Array = a.advance(16.67)
		var delivered_to_a: Array = b.advance(16.67)
		b_got += delivered_to_b.size()
		a_got += delivered_to_a.size()
		for m in delivered_to_b:
			var v: Dictionary = _OnlineProtocol.validate(m)
			if not bool(v.get("ok", false)):
				return {"ok": false, "error": "invalid_msg_to_b", "stats_a": a.stats(), "stats_b": b.stats()}
		for m in delivered_to_a:
			var v2: Dictionary = _OnlineProtocol.validate(m)
			if not bool(v2.get("ok", false)):
				return {"ok": false, "error": "invalid_msg_to_a", "stats_a": a.stats(), "stats_b": b.stats()}
	# Drain remaining
	for _i in range(20):
		b_got += a.advance(16.67).size()
		a_got += b.advance(16.67).size()
	var ok: bool = a_got == frames and b_got == frames and int(a.stats().get("dropped", 1)) == 0
	return {
		"ok": ok,
		"frames": frames,
		"a_received": a_got,
		"b_received": b_got,
		"stats_a": a.stats(),
		"stats_b": b.stats(),
		"alpha_claim": ALPHA_CLAIM,
	}


static func run_loss_test(seed_value: int = 99) -> Dictionary:
	var ScriptRef = load("res://scripts/net/network_sim.gd")
	var sim = ScriptRef.new()
	sim.configure(seed_value, 30.0, 0.0, 0.25)
	var attempts := 80
	for i in range(attempts):
		sim.send(_OnlineProtocol.encode_input(i, 0, {"left": true}))
		sim.advance(16.67)
	# Drain
	for _j in range(10):
		sim.advance(50.0)
	var st: Dictionary = sim.stats()
	var dropped: int = int(st.get("dropped", 0))
	var delivered: int = int(st.get("delivered", 0))
	var ok: bool = dropped > 0 and delivered > 0 and dropped + delivered == attempts
	return {
		"ok": ok,
		"dropped": dropped,
		"delivered": delivered,
		"attempts": attempts,
		"alpha_claim": ALPHA_CLAIM,
	}


static func self_test() -> Dictionary:
	var loop: Dictionary = run_loopback_test(11, 48)
	var loss: Dictionary = run_loss_test(99)
	return {
		"ok": bool(loop.get("ok", false)) and bool(loss.get("ok", false)),
		"loopback": loop,
		"loss": loss,
		"alpha_claim": ALPHA_CLAIM,
	}
