1. Al hacer que el enemigo me golpee y yo salga expulsado y tenga invulnerabilidad 
	ante daños como hacer que cuando termine me pueda volver a hacer daño si estoy 
	dentro de su rango de ataque.
	
	Solucion:
		get_tree().create_timer(body.INVULNERABILITY_DURATION + 0.1).timeout.connect(_on_damage_zone_body_entered.bind(body))
		Que tan bien esta? hay alguna forma mejor? Quien deberia bloquear que ejercute la animacion de muerto?

2. Porque al crear una nueva escena en una me funciona el disparo del enemigo y en otra no

original:
	get_parent().add_child(new_fire_ball)
solucion: 
	var level_root: Node = get_tree().current_scene
	level_root.add_child(new_fire_ball) 
	
3. Que hacer con los enemigos muertos en lo que desaparecen para poder pasar por encima
