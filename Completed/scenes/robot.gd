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
