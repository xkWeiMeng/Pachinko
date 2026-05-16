extends Node

# Ball events
signal ball_launched(ball: RigidBody2D)
signal ball_captured(reward: int, is_crit: bool, ball: RigidBody2D)
signal ball_lost(ball: RigidBody2D)

# Peg events
signal peg_hit(peg: StaticBody2D, ball: RigidBody2D)

# Tulip events
signal tulip_triggered

# Slots events
signal spin_started
signal jackpot_hit

# Game state events
signal score_changed(new_score: int)
signal balls_changed(remaining: int)
signal game_over

# Roguelike events
signal run_started
signal floor_started(floor_num: int, config: Dictionary)
signal floor_cleared(floor_num: int)
signal floor_objective_updated(current: int, target: int, desc: String)
signal run_ended(won: bool, stats: Dictionary)
signal relic_acquired(relic: Dictionary)
signal relic_removed(relic: Dictionary)
signal combo_updated(count: int)
signal map_node_selected(layer_idx: int, node_idx: int)
