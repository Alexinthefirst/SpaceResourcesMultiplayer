extends Node2D

class_name ship

@export_category("Ship Stats")
@export var hull_points = 5
@export var shield_points = 2
@export var damage = 1 # potentially move this to weapons later
@export var weapons = [] # Array of all weapons on the ship, unused for now
@export var speed = 500 # For now how fast it moves from planet to planet in pixels/second
# Maybe, we just take all the weapons and add them together to get damage?? Would work with battle tick system...

@export_category("Pathfinding")
@export var path : Array = [] # path in vector2s
@export var idPath = [] # path in point id's (PlanetID)
@export var currentPlanet : Planet = null # reference to current planet
@export var currentPlanetID : int # reference to current planet with id, used because MS cant sync objects, so we use this to fetch it for it instead
@export var destination := Vector2(0, 0) :
	set(dest):
		destination = dest

@export_category("Misc")
@export var player := 1 :
	set(id):
		player = id

@export var ownerId = 1 :
	set(id):
		ownerId = id

@export var inBattle : bool = false
@export var currentBattleId : int

# Called when the node enters the scene tree for the first time.
func _ready():
	# Make sure the ship doesn't leave from where its spawned until ordered to
	destination = position
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if hull_points <= 0:
		print("IM DEAD")
		queue_free()
	
	if !inBattle:
		# Destination always equal to the next point in the path
		if !path.is_empty():
			if destination != path[0]: # dont update position every frame
				destination = path[0]
				for planet in get_node("../../Planets").get_children():
					if planet.PlanetID == idPath[0]:
						currentPlanet = planet
			if position == path[0]:
				path.remove_at(0)
				idPath.remove_at(0)
				
		
		# If the ship is at the destination, remove it from the path
		
		look_at(destination)
		#print(position)
		#destination = get_global_mouse_position()
		#position = lerp(position, destination, delta * speed) Try something different here
		position = position.move_toward(destination, delta * speed)

# Updated the ship destination, causing it to move
@rpc("any_peer", "call_local", "unreliable_ordered")
func set_ship_dest(newPlanetID : int):
	var newPlanet : Planet
	for dot in get_node("../../Planets").get_children():
		if dot.PlanetID == newPlanetID:
			newPlanet = dot
	# Only move this ship if the sender owns it
	if ownerId == multiplayer.get_remote_sender_id():
		path = get_node("../..").get_path_from_astar(currentPlanetID, newPlanet.PlanetID)
		idPath = get_node("../..").astar.get_id_path(currentPlanetID, newPlanet.PlanetID)


func _on_area_2d_area_entered(area):
	var hit = area.get_parent()
	
	# If we collide with another ship
	if hit is ship:
		# If the ship ISN'T ours, we battle
		if hit.ownerId != ownerId:
			inBattle = true
			if !hit.inBattle: # if there isn't already a battle here
				get_node("../..").create_battle(self, hit)
			else:
				var battleId = hit.currentBattleId
				for b in get_node("../../Battles").get_children():
					if b.BATTLE_ID == battleId:
						b.add_to_battle(self)
		
