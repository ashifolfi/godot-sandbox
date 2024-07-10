extends Node
# Main class that handles a large chunk of gamestate related operations.

enum GameState {
	Loading,
	MainMenu,
	InGame,
	Paused
}

const PLAYER_CLASS = "BasePlayer"
const LOADING_SCREEN_PREFAB = preload("res://scenes/prefabs/loading_screen.tscn")

var CurrentState: GameState = GameState.InGame
var loadingScreen: Control
var loadThread: Thread
var mapName: String = ""

var worldRoot: Node

func _ready():
	# always allow us to process no matter what
	process_mode = Node.PROCESS_MODE_ALWAYS
	var CL = CanvasLayer.new()
	CL.name = "GameUILayer"
	add_child(CL)
	
	loadingScreen = LOADING_SCREEN_PREFAB.instantiate()
	CL.add_child(loadingScreen)
	loadingScreen.visible = false

# attempt to spawn the player at a spawn point within the level
func _spawn_player():
	var spawn_pos: Vector3 = Vector3.ZERO
	var spawn_angle: float # we only modify left and right
	
	# find the first instance of player start
	var found_spawn = false
	for child in get_tree().current_scene.get_children():
		if child is InfoPlayerStart:
			spawn_pos = child.global_position
			spawn_angle = child.global_rotation.y
			found_spawn = true
			break
	
	if (!found_spawn):
		push_warning("No info_player_start within the map! Spawning at origin!")
	
	var found_class = ""
	for class_inf in ProjectSettings.get_global_class_list():
		if (class_inf.class == PLAYER_CLASS):
			found_class = class_inf.path
	
	if (found_class == ""):
		push_error("PLAYER_CLASS is invalid!")
	else:
		var player = (load(found_class) as Script).new()
		worldRoot.add_child(player)
		player.global_position = spawn_pos
		player.global_rotation.y = spawn_angle

func change_map(mapName: String):
	if (!FileAccess.file_exists("res://maps/" + mapName)):
		push_error("Couldn't find map by name '" + mapName + "'")
		return
	
	loadingScreen.visible = true
	CurrentState = GameState.Loading
	get_tree().paused = true
	
	self.mapName = mapName
	
	loadThread = Thread.new()
	loadThread.start(_change_map_func)

# spawns in all entities and player on the main thread to finish up
func _finish_load(bspMap: BSP):
	loadThread.wait_to_finish()
	
	for bspEnt in bspMap.entities:
		var ent: Node3D
		
		# todo: setup a method to register these through other methods
		match bspEnt.classname:
			"info_player_start":
				ent = InfoPlayerStart.new()
			"light":
				ent = OmniLight3D.new()
				
				var sepValues = bspEnt.properties["_light"].split(" ")
				if (sepValues.size() > 3):
					ent.light_color = Color(
						float(sepValues[0]) / 255.0,
						float(sepValues[1]) / 255.0,
						float(sepValues[2]) / 255.0,
						float(sepValues[3]) / 255.0
					)
				else:
					ent.light_color = Color(
						float(sepValues[0]) / 255.0,
						float(sepValues[1]) / 255.0,
						float(sepValues[2]) / 255.0,
						1.0
					)
			"prop_physics":
				ent = RigidBody3D.new()
				var mi3d = MeshInstance3D.new()
				var col = CollisionShape3D.new()
				ent.add_child(mi3d)
				ent.add_child(col)
				
				var pathNoExt = bspEnt.properties["model"].get_basename()
				var mdlConf = KeyValues.new()
				mdlConf.parse(FileAccess.get_file_as_string("res://" + pathNoExt + "_mdlconf.txt"))
				
				for child in mdlConf.children[0].children:
					match child.key:
						"ReferenceModel":
							mi3d.mesh = load("res://models/" + child.value)
						"PhysicsModel":
							col.shape = load("res://models/" + child.value).create_convex_shape()
						"Mass":
							ent.mass = float(child.value)
						"CenterOfMass":
							var split = child.value.split(" ")
							
							ent.center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
							ent.center_of_mass = Vector3(
								float(split[0]),
								float(split[2]),
								float(split[1])
							)
				
				if (mi3d.mesh == null):
					push_error("Invalid model file!!!!")
					return
				if (col.shape == null):
					col.shape = mi3d.mesh.create_convex_shape()
			"worldspawn":
				# nothing for now
				pass
			_:
				push_warning("Unknown entity class " + bspEnt.classname + "! Ignoring.")
		
		if (ent != null):
			# add to the world so we can move it around
			worldRoot.add_child(ent)
			
			# set entity rotation and position
			ent.global_position = Vector3(
				Global.src_to_gd(bspEnt.origin.x),
				Global.src_to_gd(bspEnt.origin.z),
				Global.src_to_gd(bspEnt.origin.y)
			)
			ent.global_rotation_degrees = bspEnt.angles

	# mark world root as the current scene
	get_tree().current_scene.free()
	get_tree().current_scene = null
	get_tree().current_scene = worldRoot
	
	# spawn in the player and unpause the game
	print("Spawning player in world")
	_spawn_player()
	
	CurrentState = GameState.InGame
	get_tree().paused = false
	loadingScreen.visible = false

func _change_map_func():
	var bspMap = BSP.new()
	bspMap.read_file("res://maps/" + mapName)
	
	# world spawn also acts as our scene root.
	worldRoot = WorldSpawn.new()
	
	#region Create World Geo
	for face in bspMap.faces:
		var mi3d = MeshInstance3D.new()
		mi3d.mesh = ArrayMesh.new()
		
		var arrays = []
		arrays.resize(Mesh.ARRAY_MAX)

		var faceTexInf = bspMap.texinfo[face.texinfo]
		var faceTexData = bspMap.texdata[faceTexInf.texdata]

		var usedVertices: PackedInt32Array = []
		var faceVerts: PackedVector3Array = []
		var faceIndices: PackedInt32Array = []
		var faceUVs: PackedVector2Array = []
		var faceNormals: PackedVector3Array = []
		var lightmapUVs: PackedVector2Array = []
		
		for i in range(face.firstedge, face.firstedge + face.numedges):
			var surfEdge = bspMap.surfedges[i]
			var edge = bspMap.edges[abs(surfEdge)]

			if (surfEdge < 0):
				if (!usedVertices.has(edge.p2)):
					faceVerts.push_back(Vector3(
						Global.src_to_gd(bspMap.verts[edge.p2].x),
						Global.src_to_gd(bspMap.verts[edge.p2].z),
						Global.src_to_gd(bspMap.verts[edge.p2].y)
					))
					usedVertices.push_back(edge.p2)
				
				if (!usedVertices.has(edge.p1)):
					faceVerts.push_back(Vector3(
						Global.src_to_gd(bspMap.verts[edge.p1].x),
						Global.src_to_gd(bspMap.verts[edge.p1].z),
						Global.src_to_gd(bspMap.verts[edge.p1].y)
					))
					usedVertices.push_back(edge.p1)
			else:
				if (!usedVertices.has(edge.p1)):
					faceVerts.push_back(Vector3(
						Global.src_to_gd(bspMap.verts[edge.p1].x),
						Global.src_to_gd(bspMap.verts[edge.p1].z),
						Global.src_to_gd(bspMap.verts[edge.p1].y)
					))
					usedVertices.push_back(edge.p1)
				
				if (!usedVertices.has(edge.p2)):
					faceVerts.push_back(Vector3(
						Global.src_to_gd(bspMap.verts[edge.p2].x),
						Global.src_to_gd(bspMap.verts[edge.p2].z),
						Global.src_to_gd(bspMap.verts[edge.p2].y)
					))
					usedVertices.push_back(edge.p2)
		
		var i = 1
		while (i + 1 < faceVerts.size()):
			faceIndices.push_back(i + 1)
			faceIndices.push_back(i)
			faceIndices.push_back(0)
			
			i += 1
		
		for vert in faceVerts:
			faceNormals.push_back(Vector3(
				Global.gd_to_src(bspMap.planes[face.planenum].normal.x),
				Global.gd_to_src(bspMap.planes[face.planenum].normal.z),
				Global.gd_to_src(bspMap.planes[face.planenum].normal.y)
			))
			
			var tv = faceTexInf.textureVecs
			var lv = faceTexInf.lightmapVecs
			var srcVert = Vector3(
				Global.gd_to_src(vert.x),
				Global.gd_to_src(vert.z),
				Global.gd_to_src(vert.y)
			)
			
			faceUVs.push_back(Vector2(
				(tv[0].x * srcVert.x + tv[0].y * srcVert.y + tv[0].z * srcVert.z + tv[0].w) \
				/ faceTexData.width,
				
				(tv[1].x * srcVert.x + tv[1].y * srcVert.y + tv[1].z * srcVert.z + tv[1].w) \
				/ faceTexData.height
			))
			
			lightmapUVs.push_back(Vector2(
				(lv[0].x * srcVert.x + lv[0].y * srcVert.y + lv[0].z * srcVert.z + lv[0].w) \
				- face.LightmapTextureMinsInLuxels[0],
				
				(lv[1].x * srcVert.x + lv[1].y * srcVert.y + lv[1].z * srcVert.z + lv[1].w) \
				- face.LightmapTextureMinsInLuxels[1]
			))
		
		arrays[Mesh.ARRAY_VERTEX] = faceVerts
		arrays[Mesh.ARRAY_INDEX] = faceIndices
		arrays[Mesh.ARRAY_TEX_UV] = faceUVs
		arrays[Mesh.ARRAY_TEX_UV2] = lightmapUVs
		arrays[Mesh.ARRAY_NORMAL] = faceNormals
		mi3d.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		mi3d.create_convex_collision.call_deferred()
		
		var texName = bspMap.get_texture_name(faceTexData.nameStringTableID).to_lower()
		mi3d.mesh.surface_set_material(
			mi3d.mesh.get_surface_count() - 1,
			load("res://materials/" + texName + ".material")
		)
		
		worldRoot.call_deferred("add_child", mi3d)
	#endregion
	
	get_tree().root.call_deferred("add_child", worldRoot)
	_finish_load.call_deferred(bspMap)
