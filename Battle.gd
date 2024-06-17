extends Node

# This node contains all the details and methods for a
# battle that is currently taken place
#
# It is typically spawned whenever two opposing ships
# collide

class fleet :
	var playerID = 0
	var ships = [] # contains all ships in this fleet
	var total_damage = 0

@export var BATTLE_TICK_IN_SECONDS = 5 # How often a battle tick occurs
var BATTLE_ID

var rng = RandomNumberGenerator.new()

var fleets = [] # Array of all fleets in combat

# Called when the node enters the scene tree for the first time.
func _ready():
	rng.seed = 100;
	
	# Set the battle ID to a random number
	BATTLE_ID = rng.randi()
	$Timer.wait_time = BATTLE_TICK_IN_SECONDS


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# Add ships to the battle
func add_to_battle(shipToAdd : ship):
	# Ignore this if the ship is already in the battle
	for c in fleets:
		if c.ships.has(shipToAdd):
			return
	
	# Add the ship to a fleet in battle
	for f in fleets:
		if f.playerID == shipToAdd.ownerId:
			f.ships.append(shipToAdd)
			return
	
	# If the ship doesn't belong to any current fleet, create a new one
	var fleetToAdd = fleet.new()
	fleetToAdd.ships.append(shipToAdd)
	fleetToAdd.playerID = shipToAdd.ownerId
	fleets.append(fleetToAdd)

# What happens every battle tick
func battle_tick():
	# Shuffle around the attack order - Maybe base order off total speed of fleet?
	fleets.shuffle()
	# For each fleet, calculate the total damage it does
	for f in fleets:
		f.total_damage = 0 # Reset it every tick and calculate again
		# For each ship in the fleet
		for s in f.ships:
			f.total_damage += s.damage
		
		f.total_damage = f.total_damage / (fleets.size() - 1) # Deal equal damage to all fleets, could change based on some other variable later
		
		# Deal the damage to other fleets, equally among all their ships.
		for nf in fleets:
			if nf != f: # We don't hurt ourselves
				for ns in nf.ships:
					ns.hull_points -= nf.total_damage / nf.ships.size()
					if ns.hull_points <= 0:
						nf.ships.erase(ns)
	
	pass

func _on_timer_timeout():
	print(str(BATTLE_ID) + ": Battle Tick")
	battle_tick()
