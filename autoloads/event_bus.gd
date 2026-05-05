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
