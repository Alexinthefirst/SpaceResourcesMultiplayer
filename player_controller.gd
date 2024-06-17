extends Node2D

@export var population = 0
@export var score = 0
var rng = RandomNumberGenerator.new()

var SCROLL_SPEED = 20

# Set by the authority, synchronized on spawn.
@export var player := 1 :
	set(id):
		player = id
		# Give authority over the player input to the appropriate peer.))
		$PlayerInput.set_multiplayer_authority(id)

# Player synchronized input.
@onready var input = $PlayerInput

# Called when the node enters the scene tree for the first time.
func _ready():
	rng.seed = 100;
	
	# Set the camera as current if we are this player.
	if player == multiplayer.get_unique_id():
		$Camera2D.make_current()
		
	# We need our own reference to the astar points, this will do that
	# but only if we are NOT the server
	# Maybe I can just sync these with the server using the MS, but this works for now...
	if !multiplayer.is_server():
		var points = get_node("../..").astar_points
		for point in points:
			get_node("../..").astar.add_point(point, points[point], 1)
		#print(points)
		for dot in get_node("../../Planets").get_children():
			for connection in dot.Connections:
				get_node("../..").astar.connect_points(dot.PlanetID, connection.PlanetID)
	
# THIS IS AN EXAMPLE OF HOW TO SPAWN THINGS, USE IT
@rpc("any_peer", "call_local", "reliable")
func spawn_ship(data):
	if multiplayer.is_server(): # MAKE SURE ONLY SERVER SPAWNS THE SHIP, THE REST WILL BE HANDLED BY MULTIPLAYERSPAWNERS
		if data[1] == "Base":
			var spawnShip = preload("res://ship.tscn").instantiate()
			spawnShip.ownerId = data[0]
			spawnShip.position = data[2]
			spawnShip.player = player
			# This is to get the current planet based off the position, as you cant pass objects over rpc reliably
			for dot in get_node("../../Planets").get_children():
				if dot.position == data[3]:
					spawnShip.currentPlanet = dot
					spawnShip.currentPlanetID = dot.PlanetID
					#print(spawnShip.currentPlanet)
			print(spawnShip.name)
			get_node("../../Ships").add_child(spawnShip, true)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position += input.direction * SCROLL_SPEED

