class_name SignalManager
extends RefCounted

signal done(which: Signal)

var _connections: Array[Dictionary] = []

## 等待多个信号中的任意一个触发，返回触发的那个 Signal
func any(signals: Array[Signal]) -> Signal:
	if signals.is_empty():
		done.emit(Signal())
		return await done

	for sig in signals:
		var cb = _on_triggered.bind(sig)
		sig.connect(cb, CONNECT_ONE_SHOT)
		_connections.append({"sig": sig, "cb": cb})

	return await done

func _on_triggered(sig: Signal) -> void:
	# 断开其他未触发的连接，防止泄漏
	for conn in _connections:
		if conn.sig != sig and conn.sig.is_connected(conn.cb):
			conn.sig.disconnect(conn.cb)
	_connections.clear()
	done.emit(sig)
