extends AIController3D

@onready var player: Robot = get_parent()

@onready var raycast_sensor := $RayCastSensor3D
@onready var position_sensor := $PositionSensor3D
@onready var approach_goal_reward := $ApproachGoalReward


func _physics_process(delta):
	n_steps += 1
	
	# A time-out for the player
	# note that the parent class we're inheriting from also implements this check
	# but we changed the method to end episode and set a different
	# reward for timeout and for when needs_reset is set to true (see more below)
	if n_steps > reset_after:
		player.game_over(-1)

	# This will be set to true externally from Python sometimes to restart the env,
	# e.g. before the training begins, so we'll just reset the game 
	# with a neutral final reward in that case
	if needs_reset:
		player.game_over(0)


# Here we provide observations to the model, the data it uses to 
# observe the world and make actions (control the robot)

func get_obs() -> Dictionary:
	var obs: Array
	# This adds observations from the raycast sensor, it detects walls and other
	# obstacles that we add on physics layer 1.
	# Note: robot is on physics layer 2, so it will not also detect the robot itself
	obs.append_array(raycast_sensor.get_observation())
	
	# This adds observations from the position sensor, which gives
	# a relative position vector toward the goal object.
	obs.append_array(position_sensor.get_observation())
	return {"obs": obs}


# The method below will provide rewards to the model.
# Rewards are used only during training and the model needs them to learn
# which actions are best to take for a specific state (based on observations)

func get_reward() -> float:
	# Here we add the reward from our "approach goal reward" node,
	# which rewards when the robot reaches a "best/closest" distance to the goal,
	# but does not penalize moving away from the goal while exploring the environment
	reward += approach_goal_reward.get_reward()
	
	# Note: The reward variable is also set externally (e.g. from player script when
	# the goal is reached), and it is reset to 0 by the sync node
	# after being sent to the Python server (as the reward for that step is transferred)
	return reward



## Resets the AIController (e.g. when game is over)
func reset():
	super.reset()
	# We also reset the reward node when the episode is done.
	# This is needed when using `ApproachNodeReward` node,
	# as it resets the "closest position reached" data, so it can reward 
	# the robot for moving toward the goal in the next episode as well.
	approach_goal_reward.reset()


func get_action_space() -> Dictionary:
	return {
		"move": {"size": 2, "action_type": "continuous"},
		# Uncomment "jump" if you modified the env to need jumping
		#"jump": {"size": 1, "action_type": "continuous"} 
	}

## Here we apply the actions received from the model
## to control robot
func set_action(action) -> void:
	# action.move will be an array with 2 values as the size set in get_action_space is 2
	# we use them to move the robot in two different axes
	player.requested_movement = Vector2(action.move[0], action.move[1])
	
	# - We're using continuous actions only as we can't mix continuous/discrete
	# actions with the training method used in this tutorial,
	# we'll get a float value from -1 to 1 (if trained using SB3),
	# so we use 0 as a threshold to turn it into a discrete "yes or no" action.
	# - Continuous actions always give an array, but since size is 1 we only have
	# one value in the array.
	# Uncomment the line below if you modified the env to need jumping
	#player.requested_jump = bool(action.jump[0] > 0)
