extends MultiplayerSpawner

#func _init():
#	spawn_function = spawn_ship


# Could change this to autoset ownerId based on get_remote_sender_id(),
# but would make saving/loading more complicated
#func spawn_ship(data):
#	if data[1] == "Base":
#		var spawnShip = preload("res://ship.tscn").instantiate()
#		spawnShip.ownerId = data[0]
#		spawnShip.position = data[2]
#		return spawnShip
