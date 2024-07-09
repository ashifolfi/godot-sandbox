extends Node3D

var bspMap := BSP.new()
var world: Node3D

func _ready():
	world = get_node("BSPWorld")
	bspMap.read_file("res://maps/src/testmap.bsp")
	
	var mi3d = MeshInstance3D.new()
	mi3d.mesh = ArrayMesh.new()
	
	for face in bspMap.faces:
		var arrays = []
		arrays.resize(Mesh.ARRAY_MAX)

		var faceTexInf = bspMap.texinfo[face.texinfo]
		var faceTexData = bspMap.texdata[faceTexInf.texdata]

		var usedVertices: PackedInt32Array = []
		var faceVerts: PackedVector3Array = []
		var faceIndices: PackedInt32Array = []
		var faceUVs: PackedVector2Array = []
		
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
			var tv = faceTexInf.textureVecs
			var srcVert = Vector3(
				Global.gd_to_src(vert.x),
				Global.gd_to_src(vert.z),
				Global.gd_to_src(vert.y)
			)
			
			var u = (tv[0].x * srcVert.x + tv[0].y * srcVert.y + tv[0].z * srcVert.z + tv[0].w)
			var v = (tv[1].x * srcVert.x + tv[1].y * srcVert.y + tv[1].z * srcVert.z + tv[1].w)
			
			var uv = Vector2(
				u / faceTexData.width,
				v / faceTexData.height
			)
			faceUVs.push_back(uv)
		
		arrays[Mesh.ARRAY_VERTEX] = faceVerts
		arrays[Mesh.ARRAY_INDEX] = faceIndices
		arrays[Mesh.ARRAY_TEX_UV] = faceUVs
		mi3d.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		
		var texName = bspMap.get_texture_name(faceTexData.nameStringTableID).to_lower()
		mi3d.mesh.surface_set_material(
			mi3d.mesh.get_surface_count() - 1,
			load("res://materials/" + texName + ".material")
		)
	
	world.add_child(mi3d)
	
