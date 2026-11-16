extends Node

func play(nombre: String) -> void:
	var nodo = find_child(nombre, true, false)
	if nodo and nodo is AudioStreamPlayer:
		nodo.play()
	else:
		push_warning("no se encontro el nodo: " + nombre)

func stop(nombre: String) -> void:
	var nodo = find_child(nombre, true, false)
	if nodo:
		nodo.stop()
