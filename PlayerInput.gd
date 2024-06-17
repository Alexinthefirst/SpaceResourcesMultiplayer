extends MultiplayerSynchronizer

# All player controls go here

var mouse # reference to the RayCast2D that follows the mouse

var selected = [] # Maybe I dont want an array, only select one unit :)

var camera # reference to the camera
var level # reference to the level

# Synchronized property.
@export var direction := Vector2()

# Called when the node enters the scene tree for the first time.
func _ready():
	# Only process for the local player.
	mouse = get_parent().get_node("RayCast2D")
	camera = get_parent().get_node("Camera2D")
	level = get_parent().get_parent().get_parent()
	set_process(get_multiplayer_authority() == multiplayer.get_unique_id())

		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	mouse.position = get_parent().get_local_mouse_position()
	
	# Select click
	if Input.is_action_just_pressed("left_click"):
		selected.clear() # Clear the selection
		if mouse.is_colliding(): # If we are hovering over something
			selected.append(mouse.get_collider().get_parent()) # Select the unit
			if selected [0] is ship: # If this is a ship CHANGE LATER TO SELECT PLANETS TOO
				print(selected)
	
	# Command click
	if Input.is_action_just_pressed("right_click"):
		if !selected.is_empty():
			if selected[0] is ship:
				# Check if we are on a valid destination (planet)
				if mouse.is_colliding():
					if mouse.get_collider().get_parent() is Planet:
						print("PlanetID: " + str(mouse.get_collider().get_parent().PlanetID))
						selected[0].set_ship_dest.rpc(mouse.get_collider().get_parent().PlanetID)
						print(mouse.get_collider().get_parent() is Planet)
						
				# This is how to call an rpc locally
				
				#selected[0] = get_parent().get_global_mouse_position()
				print("Moving ship")
			print("RIGHT")
	
	# Controls camera zoom
	if Input.is_action_just_pressed("scroll_up"):
		if camera.zoom.x <= 4:
			print(camera.zoom)
			camera.zoom.x += .1
			camera.zoom.y += .1
	
	# Controls camera zoom
	if Input.is_action_just_pressed("scroll_down"):
		if camera.zoom.x > 0.4:
			print(camera.zoom)
			camera.zoom.x -= .1
			camera.zoom.y -= .1
			#print("CALLING FROM " + str(get_multiplayer_authority()))
			#print(str(mouse.get_collider().get_parent().name))
	
	# Used for various testing scenarios
	# CURRENT
	#    Planet Selected: Spawn a ship
	#    No Selection: Print num of planets
	if Input.is_action_just_pressed("test_button"):
		if !selected.is_empty():
			if selected[0] is Planet:
				get_parent().spawn_ship.rpc([get_multiplayer_authority(), "Base", selected[0].position, selected[0].position])
				
		else:
			print(get_node("../../../Planets").get_child_count())


