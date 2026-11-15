extends Node
## Duration to rewind in game time (in seconds).
@export var rewind_duration: float = 10.0
## Number of frames between keyframes.[br]
## [b]The number of frames to store (Time recorded * Physics ticks per seconds) must be divisible by keyframes_modulo.[/b]
@export var keyframes_modulo: int = 60
## Amount of quantization.
@export_enum("1e-6:6", "1e-5:5", "0.0001:4", "0.001:3", "0.01:2", "0.1:1", "1:0") var precision: int = 3
## Number of bytes allocated for delta encoding.
@export_enum("1:1", "2:2", "4:4") var bytes_per_delta: int = 2
## Nodes tracked by TimeRewinder.
@export var tracked_nodes : Array[RewindTrackedNode] = []
## Speed multiplier for the rewind effect.
@export_range(0.5, 4, 0.5) var speed_scale: float = 1.0
## Signal sent when TimeRewinder is no longer rewinding.
signal done_rewinding

var rewinding: bool = false
var total_time_to_rewind: float = 0.0  # Total real time to rewind (adjusted by speed_scale)
var game_time_accumulated: float = 0.0
var real_time_accumulated: float = 0.0  # Total real time passed in the rewind process
var rewind_accumulator: float = 0.0  # Real-time accumulator for rewind progression

var total_frames_saved: int = 0
var frames_popped: int = 0

func _ready() -> void:
	# Initialize values
	total_time_to_rewind = rewind_duration / speed_scale
	total_frames_saved = int(rewind_duration * Engine.physics_ticks_per_second)
	for tracked_node in tracked_nodes:
		tracked_node.setup(total_frames_saved, keyframes_modulo, precision, bytes_per_delta)

# We read or write values every frame depending on the rewinding boolean
func _physics_process(delta: float) -> void:
	if rewinding:
		compute_rewind(delta)
	else:
		update_rewind_values()

# If we are not rewinding, we save the values of the tracked properties of tracked nodes
func update_rewind_values() -> void:
	for tracked_node in tracked_nodes:
		var node = get_node_or_null(tracked_node.node_path)
		if node:
			tracked_node.record(node)


# If we are rewinding, we read the saved values of the tracked properties of tracked nodes
func compute_rewind(delta: float) -> void:
	# Accumulate the real time passed, accounting for the multiplier
	real_time_accumulated += delta

	# Increase the rewind accumulator based on the speed_scale multiplier
	rewind_accumulator += speed_scale

	game_time_accumulated = real_time_accumulated * speed_scale

	# If we need to rewind, calculate the number of frames to pop based on the accumulator
	if rewind_accumulator >= 1.0:
		var frames_to_pop = int(rewind_accumulator)
		
		# Make sure we don’t rewind too far (limit it to the desired rewind duration)
		if game_time_accumulated >= rewind_duration:
			stop_rewind()
			return

		# Pop values from the rewind resources
		for tracked_node in tracked_nodes:
			var node = get_node_or_null(tracked_node.node_path)
			if node:
				for i in range(frames_to_pop):
					if not tracked_node.rewind_frame(node, i + frames_popped):
						stop_rewind()
						return
		
		# Subtract the number of frames popped from the accumulator
		rewind_accumulator -= frames_to_pop
		frames_popped += frames_to_pop

## Start the rewind
func rewind() -> void:
	rewinding = true
	real_time_accumulated = 0.0  # Reset real time accumulator
	rewind_accumulator = 0.0  # Reset the rewind accumulator
	frames_popped = 0
	var total_size: float
	for tracked_node in tracked_nodes:
		disable_physics(get_node_or_null(tracked_node.node_path)) # We make sure to disable physics of rewinded nodes
		total_size += tracked_node.get_size()
	# Prints how much memory is used by TimeRewinder
	if total_size > 1000000:
		print("Memory saved for recording : ", total_size/1000000, " MB")
	elif total_size > 1000:
		print("Memory saved for recording : ", total_size/1000, " KB")
	else:
		print("Memory saved for recording : ", total_size, " bytes")
	print("Rewind started.")  # Debug print

## Stop the rewind
## This method is called automatically if there's no more values to read
func stop_rewind() -> void:
	rewinding = false
	done_rewinding.emit()
	for tracked_node in tracked_nodes:
		enable_physics(get_node_or_null(tracked_node.node_path))
		tracked_node.reset()
	print("Rewind stopped.")  # Debug print
	
## Add a new tracked node with tracked properties
## Parameters are redefinable, if left empty they will take the values set in the editor (adviced to prevent weird behavior)
func add_rewindable_node(node_path: NodePath, properties: Array[String], new_keyframes_modulo: int = keyframes_modulo, new_precision: int = precision, new_bytes_per_delta: int = bytes_per_delta) -> void:
	if not [1,2,4].has(new_bytes_per_delta):
		push_error("Bytes per delta must be 1, 2 or 4")
		return
	if not [0, 1, 2, 3, 4, 5, 6].has(new_precision):
		push_error("Precision must be in [1e-6:6, 1e-5:5, 0.0001:4, 0.001:3, 0.01:2, 0.1:1, 1:0]")
		return
		
	var new_tracked_node:= RewindTrackedNode.new()
	new_tracked_node.node_path = node_path
	new_tracked_node.properties = PackedStringArray(properties)
	new_tracked_node.setup(total_frames_saved, new_keyframes_modulo, new_precision, new_bytes_per_delta)
	
	tracked_nodes.append(new_tracked_node)

# Disable or enable physics interaction for CollisionObject
func disable_physics(node : Node) -> void:
	if node is CollisionObject3D or node is CollisionObject2D:
		node.process_mode = Node.PROCESS_MODE_DISABLED

func enable_physics(node : Node) -> void:
	if node is CollisionObject3D or node is CollisionObject2D:
		node.process_mode = Node.PROCESS_MODE_INHERIT
