extends Node

# TODO: change map gen algo to eliminate some of the connections, but make sure they still have minimum of 1? Maybe 2 to prevent unreachable planets.
# TODO: Make the planet that spawns random, with a random seed
var SPAWN_RANDOM = 1

var astar = AStar2D.new() # Pathfinding
@export_category("AStar")
@export var astar_points : Dictionary

# Map generation variables
var isLoadingSave : bool = false

var x = []
var y = []
var R = 2000 # RADIUS
var points = []

var rng = RandomNumberGenerator.new()

var delaunay = Delaunay.new()

const GEN_AMOUNT = 30

var theta
var r

# Called when the node enters the scene tree for the first time.
func _ready():
	# We only need to spawn players on the server.
	if not multiplayer.is_server():
		return

	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(del_player)

	# Spawn already connected players.
	for id in multiplayer.get_peers():
		add_player(id)

	# Spawn the local player unless this is a dedicated server export.
	if not OS.has_feature("dedicated_server"):
		add_player(1)
	
	#rng.seed = 500
	rng.randomize()
	
	# MAP GENERATION
	points = generate_map()
	print("After RemovalHyperlanes count: " + str($Hyperlanes.get_child_count()))


# What happens when you close the game
func _exit_tree():
	if not multiplayer.is_server():
		return
	multiplayer.peer_connected.disconnect(add_player)
	multiplayer.peer_disconnected.disconnect(del_player)

# Add a player to the game
func add_player(id: int):
	var character = preload("res://player_controller.tscn").instantiate()
	# Set player id.
	character.player = id
	character.name = str(id)
	$Players.add_child(character, true)

# Remove a player from the game
func del_player(id: int):
	if not $Players.has_node(str(id)):
		return
	$Players.get_node(str(id)).queue_free()

# Currently unused, will fix later
func add_name_to_list(id):
	var list = $PlayerList/ListOfPlayers
	var label = load("res://NameLabel.tscn").instantiate()
	label.text = str(id)
	
	list.visible = true
	
	list.add_child(label, true)

@rpc("any_peer", "call_local")
func get_path_from_astar(currentId, newId):
	var path = []
	path =  astar.get_point_path(currentId, newId)
	print(path)
	return path

# Creates a battle between 2 ships
func create_battle(ship1 , ship2):
	var battle = preload("res://battle.tscn").instantiate()
	$Battles.add_child(battle, true)
	battle.add_to_battle(ship1)
	ship1.currentBattleId = battle.BATTLE_ID
	battle.add_to_battle(ship2)
	ship2.currentBattleId = battle.BATTLE_ID
	

# MAP GENERATION FUNCTIONS

func generate_map():
	# Generate random points
	for i in range(GEN_AMOUNT):
		var a = rng.randf_range(0, 1) * 2 * PI
		var r = R * sqrt(rng.randf_range(0, 1))
		x.append(r * cos(a))
		y.append(r * sin(a))
		add_point(Vector2(x[i], y[i]))
		
		# Choose random planet type
		var dot
		match randi_range(0, 3):
			0:
				dot = preload("res://Planets/Rivers/Rivers.tscn").instantiate()
			1:
				dot = preload("res://Planets/Gas Planet/gas_planet.tscn").instantiate()
			2:
				dot = preload("res://Planets/LandMasses/LandMasses.tscn").instantiate()
			3:
				dot = preload("res://Planets/Star/Star.tscn").instantiate()
#		# Give our node a name based on its position so we can find it later
#		dot.name = str(snappedf(x[i] + 500, 0.001)) + "-" + str(snappedf(y[i] + 250, 0.001))
		get_node("Planets").add_child(dot, true)
		dot.set_seed(rng.randi())
		dot.PlanetID = i
		dot.position = Vector2(x[i], y[i])
		astar.add_point(dot.PlanetID, dot.position, 1) # Setup the point in the pathfinder
		
	# Apply Delaunay triangulation to them
	var triangles = delaunay.triangulate()
	for triangle in triangles:
		# Instance all our locations
		var dota #= preload("res://dot.tscn").instantiate()
		var dotb #= preload("res://dot.tscn").instantiate()
		var dotc #= preload("res://dot.tscn").instantiate()
		if !delaunay.is_border_triangle(triangle):
		# Check to make sure location doesn't already exist
			for dot in get_node("Planets").get_children():
				if dot is Planet:
					if dot.position == triangle.a:
						triangle.nodea = dot
					if dot.position == triangle.b:
						triangle.nodeb = dot
					if dot.position == triangle.c:
						triangle.nodec = dot
			# Associate them with the triangle if they aren't already
			if triangle.nodea == null || triangle.nodeb == null || triangle.nodec == null:
				print("One of these didn't match")
			if triangle.nodea == null:
				print("A WAS NULL")
				triangle.nodea = dota
			if triangle.nodeb == null:
				triangle.nodeb = dotb
				print("B WAS NULL")
			if triangle.nodec == null:
				triangle.nodec = dotc
				print("C WAS NULL")
		# Add them to the scene and set their positions

			if (!triangle.nodea.Connections.has(triangle.nodeb)):
				triangle.nodea.Connections.append(triangle.nodeb)
			if (!triangle.nodea.Connections.has(triangle.nodec)):
				triangle.nodea.Connections.append(triangle.nodec)
			if (!triangle.nodeb.Connections.has(triangle.nodea)):
				triangle.nodeb.Connections.append(triangle.nodea)
			if (!triangle.nodeb.Connections.has(triangle.nodec)):
				triangle.nodeb.Connections.append(triangle.nodec)
			if (!triangle.nodec.Connections.has(triangle.nodea)):
				triangle.nodec.Connections.append(triangle.nodea)
			if (!triangle.nodec.Connections.has(triangle.nodeb)):
				triangle.nodec.Connections.append(triangle.nodeb)
#		dot.position = Vector2(x[i] + 500, y[i] + 250)
		if !delaunay.is_border_triangle(triangle): # do not render border triangles
			show_triangle.rpc(triangle)
			pass
	
	print("Before Removal Hyperlanes count: " + str($Hyperlanes.get_child_count()))
	remove_random_connections(50)#rng.randi_range(3, 10))
	generate_astar_connections()
	
	# Make Voronoi tiles from Delaunay triangulation
	var sites = delaunay.make_voronoi(triangles)
	for site in sites:
		if !delaunay.is_border_site(site): # do not render border sites
			show_site.rpc(site)
			if site.neighbours.size() == site.source_triangles.size(): # sites on edges will have incomplete neighbours information
				for neighbour_edge in site.neighbours:
					pass#show_neighbour(neighbour_edge)
	
	return delaunay.points
	
	#print(delaunay.points)
	
	# After this, we should apply Lloyd's algo to converge 
	# these and run it again until we like what we see

func remove_random_connections(amount : int):
	# Grab random connection
	print("Removing " + str(amount) + " hyperlanes")
	for i in range(amount + 1):
		var lane = $Hyperlanes.get_child(rng.randi_range(0, $Hyperlanes.get_child_count() - 1))
		
		var erased = false
		
		# Remove connection from connected planets
		for dot in get_node("Planets").get_children():
			if lane.connections.has(dot):
				print(dot.name)
				print(dot.Connections.size())
				if dot.Connections.size() > 1 && lane.canDelete:
					print("ERASED")
					# TO FIX THIS ISSUE
					# OTHER SIDE OF CONNECTION IS PROBABLY DELETING IT, MAYBE MAKE A FLAG IF IT SHOULDNT BE DELETED AND CHECK THAT FIRST
					dot.Connections.erase(lane.connections[0])
					dot.Connections.erase(lane.connections[1])
					erased = true
				else:
					lane.canDelete = false
		# Delete the hyperlane
		if erased:
			lane.delete()
	pass


func generate_astar_connections():
	for dot in get_node("Planets").get_children():
		for connection in dot.Connections:
			astar.connect_points(dot.PlanetID, connection.PlanetID)
	# Populate our own dictionary containing a list of all points
	for point in astar.get_point_ids():
		astar_points[point] = astar.get_point_position(point)

# Check to make sure we don't double up on hyperlanes
# Returns true if it is overlapping, false if it is not
func overlapping_hyperlane(hyperlane : Line2D):
	for lane in $Hyperlanes.get_children():
		if hyperlane.points.has(lane.points[0]) && hyperlane.points.has(lane.points[1]):
			return true
	return false


@rpc("authority", "call_local")
func add_point(point: Vector2):
#	var polygon = Polygon2D.new()
#	var p = PackedVector2Array()
#	var s = 5
#	p.append(Vector2(-s,s))
#	p.append(Vector2(s,s))
#	p.append(Vector2(s,-s))
	#p.append(Vector2(-s,-s))
	#polygon.polygon = p
	#polygon.color = Color.BURLYWOOD
	#polygon.position = point
	#add_child(polygon)
	delaunay.add_point(point)

@rpc("authority", "call_local")
func show_triangle(triangle: Delaunay.Triangle):
	var line1 = preload("res://Hyperlane.tscn").instantiate()
	var line2 = preload("res://Hyperlane.tscn").instantiate()
	var line3 = preload("res://Hyperlane.tscn").instantiate()
	var p1 = PackedVector2Array()
	var p2 = PackedVector2Array()
	var p3 = PackedVector2Array()
	p1.append(triangle.a)
	p1.append(triangle.b)
	p2.append(triangle.a)
	p2.append(triangle.c)
	p3.append(triangle.b)
	p3.append(triangle.c)
	line1.points = p1
	line1.width = 3
	line1.antialiased
	line2.points = p2
	line2.width = 3
	line2.antialiased
	line3.points = p3
	line3.width = 3
	line3.antialiased
	
	if !overlapping_hyperlane(line1):
		for dot in get_node("Planets").get_children():
			if line1.points.has(dot.position):
				line1.connections.append(dot)
		get_node("Hyperlanes").add_child(line1, true)
	if !overlapping_hyperlane(line2):
		for dot in get_node("Planets").get_children():
			if line2.points.has(dot.position):
				line2.connections.append(dot)
		get_node("Hyperlanes").add_child(line2, true)
	if !overlapping_hyperlane(line3):
		for dot in get_node("Planets").get_children():
			if line3.points.has(dot.position):
				line3.connections.append(dot)
		get_node("Hyperlanes").add_child(line3, true)

@rpc("authority", "call_local")
func show_site(site: Delaunay.VoronoiSite):
####As Lines
#	var line = Line2D.new()
#	var p = site.polygon
#	p.append(p[0])
#	line.points = p
#	line.width = 1
#	line.default_color = Color.GREEN_YELLOW
#	add_child(line)

####As Polygons
	var polygon = Polygon2D.new()
	var p = site.polygon
	p.append(p[0])
	polygon.polygon = p
	polygon.color = Color(randf_range(0,1),randf_range(0,1),randf_range(0,1),0.5)
	polygon.z_index = -1
	add_child(polygon, true)
	
@rpc("authority", "call_local")
func show_neighbour(edge: Delaunay.VoronoiEdge):
	var line = Line2D.new()
	var points: PackedVector2Array
	var l = 6
	var s = lerp(edge.a, edge.b, 0.6)
	var dir = edge.a.direction_to(edge.b).orthogonal()
	points.append(s + dir * l)
	points.append(s - dir * l)
	line.points = points
	line.width = 1
	line.default_color = Color.CYAN
	add_child(line, true)

#func find_centroid(vertices):
#	var area = 0
#	var centroid_x = 0
#	var centroid_y = 0
#	for i in range(len(vertices)-1):
#		var step = (vertices[i, 0] * vertices[i+1, 1]) - (vertices[i+1, 0] * vertices[i, 1])
#		area += step
#		centroid_x += (vertices[i, 0] + vertices[i+1, 0]) * step
#		centroid_y += (vertices[i, 1] + vertices[i+1, 1]) * step
#	area /= 2
#	centroid_x = (1.0/(6.0*area)) * centroid_x
#	centroid_y = (1.0/(6.0*area)) * centroid_y
#	return np.array([[centroid_x, centroid_y]])
