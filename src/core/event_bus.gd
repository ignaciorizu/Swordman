extends Node

signal player_health_changed(current_health: int, max_health: int)
signal player_died(cause: StringName)
signal essence_collected(total_essences: int)
signal level_completed
signal score_changed(new_score: int)
signal time_updated(time_left: int)
signal time_expired
