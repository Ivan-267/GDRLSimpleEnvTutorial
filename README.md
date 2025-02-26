# Godot RL Agents Simple Env Tutorial
![tutorial_introduction](https://github.com/user-attachments/assets/4be8b521-9d6f-4a9f-8953-cb716b068fcf)

Welcome! In this tutorial, you'll learn how to train an agent to reach the treasure chest using GDRL’s sensor and reward nodes. 
You can optionally customize the environment, add obstacles and jumping (optional variants are not included in the "completed" project folder).

### Prerequisites:

- Read the [Godot RL Agents readme](https://github.com/edbeeching/godot_rl_agents?tab=readme-ov-file#godot-rl-agents) (we'll use a different command to install a specific version however),
- [Introduction to Godot RL Agents](https://huggingface.co/learn/deep-rl-course/unitbonus3/godotrl) (optional but recommended),
- Basic Godot/Gdscript knowledge (recommended but not required to get started with the tutorial),
- In your virtual Python env (conda/venv/etc.), use `pip install https://github.com/edbeeching/godot_rl_agents/archive/f4b53921f0f6602d930b7b174a3ba7b8aed361aa.zip` to install the version of Godot RL Agents used while writing this tutorial,
- Godot 4.3 (64 bit, mono version) - you can get it from [https://godotengine.org/download/windows/](https://godotengine.org/) (other 4.x versions might also work, especially newer ones, but the tutorial was made with 4.3).

## Getting started:

### Download the project from [link] and open the starter project in Godot Editor.

You might see some errors on initial load such as “Unable to load addon script…”, as Godot will need to rebuild some temporary files, this should only happen the first time you import the Godot project.

### Enable the Godot RL Agents plugin:

![Enable GDRL Plugin](https://github.com/user-attachments/assets/e10bba3c-13a9-4dd4-928e-f0655429dc4f)

Note that we have many GameScene instances in the training scene. “GameScene” is the game, and we run multiple instances of it in parallel in order to speed up training. We also have a different “TestingScene” with only a single GameScene instance which we’ll later use to test our trained model.

### Open the GameScene:

![open gamescene](https://github.com/user-attachments/assets/f5d886cd-0f99-4ab5-a6f9-e0842bbdb4de)

After opening the game scene, this is where you should design a basic environment layout by dragging and dropping elements from the modules folder:

![modules folder](https://github.com/user-attachments/assets/8a59e6dc-c803-48b5-8641-28a17dbfa2dd)

We’ll use the “wall”, “stone_floor” and “chest” scenes from the modules folder, and also the “robot” scene which we can search for by typing `robot` in the filter box above.

In case you see the viewport mode as “orthogonal”, you can switch it to perspective by clicking on it and choosing `perspective` (or use orthogonal per your preference).

![switch to perspective](https://github.com/user-attachments/assets/e99eec90-c40c-4e32-852e-3178e7b82753)

https://github.com/user-attachments/assets/34b47a19-b2ea-4346-aa94-f06f199eb8f2

Tips: 

- Keep the initial scene as simple as possible for the agent to complete, we'll add some obstacles later in the optional section.
- You can use “page down” to align the modules to the floor.
- You can duplicate existing elements with `CTRL + D` and move them.
- You can hold `CTRL` while repositioning the modules to align them to the grid, and `CTRL + SHIFT` for fine-tuning (e.g. for adjusting the walls as in the video, this is optional).

### Open the Robot scene:

![open the robot scene](https://github.com/user-attachments/assets/41d675d9-4981-484c-b8c3-9357a449a76b)

Note: You can also open all of these scenes by searching for their names in the FileSystem’s filter box.

### Add AIController3D and sensor/reward nodes:

![AddAIController](https://github.com/user-attachments/assets/73fe6f0c-c9da-4f70-be5a-0dafe428d488)

We'll add an AIController3D node, which is the node used to interface the RL agent with our Robot. It will handle the observations, rewards and actions.

Inside of the AIController3D node, we need to add:

- PositionSensor3D (we'll use this to give the RL agent the relative position from the robot to the treasure chest),
- RaycastSensor3D (used to give distances to nearby walls as observation),
- ApproachNodeReward3D (used to calculate a reward for the robot approaching a node, in this env, that will be the treasure chest node).

### Adjust the PositionSensor3D node:

Set the following:

- Max distance: 5 (this is used to adjust the observations to be in 0-1 range, if the actual distance is larger than 5 it will be clamped to 1, you can adjust this based on the size of the map but a very large value might perform worse so I recommend trying a small value, then increase as needed - if the max distance is very large, after division, the RL agent might sometimes receive very small values that are more difficult to learn from).

![Position Sensor 3D](https://github.com/user-attachments/assets/f833a88d-9265-46f5-8b18-1f275be64d02)

- Use separate direction: ON (this makes it so the RL model will receive a normalized direction vector + distance separately, this helps in some cases, e.g. when the distance is small the direction values will still be large enough for the RL model to use easily, vs when the setting is OFF, the model only receives relative position coordinates, so if the distance is small the values can be very small - but you can try both settings, sometimes OFF works just fine and makes the observation space slightly smaller).

### Adjust the RayCastSensor3D node:

![Raycast Sensor 3D](https://github.com/user-attachments/assets/4a070b75-4a2f-4ebd-8b8b-fea1a259f0d7)

Set the following:

- N Rays Width: 32 (how many rays we’ll use)
- N Rays Height: 1 (we won’t use any extra rays to look upward/downward)
- Ray Length: 3
- Cone Width: 360

Note that the Raycast sensor is set to observe only physics `Layer 1` (where we have walls, and other objects). Robot is pre-set in the starter project to be on `Layer 3` so the Raycast sensor will only observe other objects.

### Return to the GameScene

We’ll need to to finish adjusting the sensor/reward nodes from there (by connecting them to the Chest that’s placed there).

### Set Robot scene as editable:

![set robot scene as editable](https://github.com/user-attachments/assets/49aec7ba-c520-45f8-90d9-925cb01bc233)

### Adjust PositionSensor and ApproachNodeReward

For PositionSensor, we’ll add the “Chest” node to objects to observe, and for ApproachNodeReward we’ll set the target node to “Chest”.
We also set the reward scale to 0.1. 

![AdjustPositionSensorRewardNodes](https://github.com/user-attachments/assets/e8cd19df-1380-40d8-a533-88140be70d86)

### Return to the Robot scene

Now, we need to add the scripts for the Robot and AIController:

- Right click on `Robot`, click on “AttachScript”, then on “Create”.
- Replace the script content with the following (check the comments to better understand what each section of the code does):

```gdscript
extends CharacterBody3D
class_name Robot

# Code based on and built upon Godot's CharacterBody3D template

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const GRAVITY = 20.0

# Used to set rewards and restart the AIController
@onready var ai_controller = $AIController3D
# Used to switch between walking/idle animations
@onready var animation_player := $robot/AnimationPlayer
# We rotate the "visual" robot to make it appear as if the robot
# turns toward its movement direction
@onready var visual_robot := $robot
# We use this when reseting the robot to its initial transform
@onready var initial_transform := transform

# Requested movement (and jump, if enabled) is set by AIController
# based on the action produced by the model
var requested_movement: Vector2
var requested_jump: bool

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += Vector3.DOWN * GRAVITY * delta
	
	var input_dir: Vector2
	# If we set sync node to human, we get the controls directly from keyboard/gamepad
	if ai_controller.heuristic == "human":
		# Movement
		input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		# Jump
		if Input.is_action_just_pressed("ui_accept"):
			try_to_jump()
	# Otherwise, get controls from the model
	else:
		# Movement
		input_dir = requested_movement
		if requested_jump:
			try_to_jump()

#region Calculates movement direction and sets animation
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		# This makes the robot appear to turn toward its movement direction
		visual_robot.global_rotation.y = atan2(direction.x, direction.z)
		# Switch to the "walking" animation when the robot is moving
		animation_player.play("walking")
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		# Switch to "idle" animation when the robot is not moving
		animation_player.play("idle")
#endregion
	
	# Applies the movement requested and handles collision
	move_and_slide()
	
	# If the player fell down, this resets the game with a negative reward
	if global_position.y < -2.0:
		game_over(-1)

## Ends the episode and resets the game
func game_over(reward: float = 0):
	ai_controller.reward += reward
	ai_controller.done = true
	ai_controller.reset()
	transform = initial_transform

## Restarts the game with a positive reward if the chest is reached
func _on_chest_body_entered(body: Node3D) -> void:
	game_over(1)

## Will jump if possible (if robot is on ground)
func try_to_jump():
	if is_on_floor():
		velocity.y = JUMP_VELOCITY
```

- Right click on `AIController3D`, click on “Extend Script” (we need to extend the base script for AIController3D), then on “Create”.
- Replace the code with the following:

```gdscript
extends AIController3D

@onready var player: Robot = get_parent()

@onready var raycast_sensor := $RayCastSensor3D
@onready var position_sensor := $PositionSensor3D
@onready var approach_goal_reward := $ApproachNodeReward3D

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
```

On the first few lines, there are references to a few nodes, if there are some errors related to it, check that the nodes exist at that path, with that name (in the completed project, the reward node is named differently, and the script there is also adjusted for that).

### Return to the GameScene

Finally, we’ll need to connect the Chest area’s signal with the Robot, so it knows when it has reached the goal.

![ConnectChestSignalWithRobot](https://github.com/user-attachments/assets/88a06722-06f2-46a2-b72c-b89cac344161)

Note: Chest area is set to detect collision on Layer 2 only in the starter project, as we only have the Robot on `Layer 2` we know that the Robot has reached the goal when the signal is activated. The behavior then (resetting the game with a positive reward) is handled by the `_on_chest_body_entered` method that we already implemented in `robot.gd`.

### Training

Great, we've set the environment and are now ready to start training our robot to reach the treasure chest!

- Download a copy of the [SB3 training example](https://github.com/edbeeching/godot_rl_agents/blob/main/examples/stable_baselines3_example.py) script.
- Run training using the arguments:

```bash
stable_baselines3_example.py --onnx_export_path=model.onnx --timesteps=10_000_000
```

- This will start the Python training server, you will see a message to **press play in Godot editor**, which is what we should do next.
- Training should start and you should see `ep_reward_mean` start increasing in the console. Let it train for a little while, observe the behavior in Godot and when it seems to have learned well, you can stop Python training manually (`CTRL + C`)
- You should now have an onnx file called `model.onnx` in the same folder where you launched training from (likely in the same folder as the Python script), find it and copy or move it to your Godot project folder (likely the `Starter` folder)

Notes:

- The training scene has a sync node set to training mode. When you start the game in the editor, this connects the environment to the Python training server that you previously started. Sync node handles communication between Python and the game, it sends data such as observations and rewards to the server (and optionally additional info), and receives actions back.
- After training, we can use the exported `model.onnx` to run inference in Godot. This doesn’t require Python installation, it instead uses C# and onnxruntime. You can use this to export your projects with the model (currently not all export platforms support this).
- If you need to adjust the camera a bit to see the entire map or the most important parts, you can find it in `GameScene` and position it as needed, this step depends on the env layout.

### Testing the trained model

- Open the testing scene (you can search for it)
- Select the sync node
- Type “model.onnx” to onnx model path (may need to click on sync node first if not already selected)
- Press F6 or click on the start scene icon

If you see the agent reaching the goal successfully, congratulations! You’ve completed this tutorial.

![testing_trained_model](https://github.com/user-attachments/assets/74682b1b-ccbf-4160-9965-1d9093e96ab7)

If you’re experiencing some issues, please check the completed project for reference. Note that there might be slight differences in the level layout and the reward node name.

### [Optional] Adding obstacles and jumping

If you’d like go further than the completed project, you can add some obstacles and jumping.

For example, I’ve added some walls, barrels and crates, and another layer of floor from the `modules` folder. Now the chest is on a higher level, so the robot will need jumping in order to reach the chest position.

![gamescene with barrels, crates and another layer of floor](https://github.com/user-attachments/assets/df4bef90-a6dd-421e-b1b0-eb9101a22ac0)

We’ll need to enable jumping first, to do that, first search for and open our extended AIController 3d script in the filesystem (open the one from the scenes folder, the one above is the one included in the plugin that we’re extending from):

![open aicontroller](https://github.com/user-attachments/assets/619df375-7b14-4f44-941a-d560cf46d837)

Remove the `#` character to uncomment the two marked lines of code:

![uncomment code lines](https://github.com/user-attachments/assets/a53578c2-7376-41c2-92e4-c5f1a1989c8e)

This will add another action to the RL agent. Note that adding or removing actions will change the action space, so the previously trained model won’t work directly and trying to run onnx inference would result in an error, but we’ll need to train a new model anyway to tackle our new environment.

Training this model may take a little longer, but note that training too long might cause a performance degradation (this can be alleviated by changing the hyperparameters in the training script). It took around 144 seconds on an i5 desktop CPU. Remember to copy the newly exported onnx model before running the testing scene.

Also note that the Raycast sensor does not look down so it might not be possible to learn some layouts effectively. Check the next example on how to adjust that. 

Here’s the result:

https://github.com/user-attachments/assets/988341e1-0d3b-4c97-b272-c35d6c081ddd

The RL agent learned a slight shortcut that allows it to take a shorter path! This is useful information we could use to adjust the layout. In the `robot.gd` script you can also adjust jumping velocity and gravity.

### [Optional] Adding holes

We could add some holes for the robot to have to jump over, e.g. as in the layout below:

![adding holes](https://github.com/user-attachments/assets/82c2220e-3397-4d41-980f-7697cbf093a0)

However, the current raycasts do not look at the ground, so the agent has no information about where the holes are!

Let's adjust the Raycast sensor. Open the `robot` scene, click on the `RayCastSensor3D` node, adjust the ray parameters, then rotate the sensor:

![adjusted raycast sensor parameters](https://github.com/user-attachments/assets/83740cdc-c0b8-4fc3-be31-3218485145cc)

Note: You can experiment with the exact settings depending on the environment. It’s usually better not to set too many rays (unless needed) to make the observation size smaller. If the rays are too long, due to division by max distance it might be difficult for the model to use the data.

To make this case train more successfully, I removed the penalty (-1) reward for the agent falling down. What works best depends on the environment and other rewards, but there was a potential for the agent to avoid moving toward the edge which made it less likely to learn how to reach the goal.

In `player.gd`, I modified line 66, game over reward set to 0.0:

```gdscript
# If the player fell down, this resets the game with a negative reward
if global_position.y < -2.0:
	game_over(0.0)
```

In addition to that, to make training a bit more stable, in `stable_baselines_3_example.py` I modified ``n_steps`` from 32 to 512. This makes updates happen less frequently as it collects more data before an update (512 `RL steps` are collected from each environment instance). Note that steps here differ from GDRL steps, where we have an `action repeat` parameter on the sync node, which is set to 8 by default. Only once every 8 physics frames, the RL agent takes a step and gives us a new action, until then, we simply repeat the previous action in-game. The default value is a good starting point, but you can adjust this value based on the environment. 

After training for about 20 minutes, I got this result:

https://github.com/user-attachments/assets/8c288a4e-363f-4358-86d8-49a532546c39

Final notes on customizing:

Under the `assets` folder, you can find extra assets that can be used, but some of them might not have a collider attached (some do). You can add a collider and save them as a "module" as needed.
    
![assets in asset folder](https://github.com/user-attachments/assets/a6fe8787-2439-468e-aff8-aac99b2b8818)
    
If you want to create a very complex environment, you may need to adjust rewards and/or training settings. This often takes a bit of experimentation. If the environment layout is static, adding intermediate checkpoints and rewarding when the agent approaches them can help (you can use multiple `ApproachNodeReward3D` nodes for this - you'll need to also add them in the AIController3D script in the reward and reset methods). If the environment is dynamic, exploration becomes more complex and experimenting with additional methods might be useful, such as some form of exploration rewards, or using pathfinding such as Godot's A* to create intermediate checkpoints. Note that training times can also be much longer with more complex environments. As another approach, you can also explore the [imitation learning](https://huggingface.co/learn/deep-rl-course/unitbonus5/introduction) unit, in which you play the game and save expert demonstrations that the agent will learn to imitate.

### Conclusion:

Congratulations! You’ve learned how to successfully train a RL agent using Godot and Godot RL Agents!
