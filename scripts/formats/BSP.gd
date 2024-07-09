class_name BSP extends Resource

# FORMAT USED: https://wiki.stratasource.org/shared/reference/general/bsp-v25
# https://developer.valvesoftware.com/wiki/BSP_(Source)

const HEADER_LUMPS = 64
const LUMP_T_SIZE = 16
const BSP_VERISON = 25 # strata

var version: int
var map_revision: int
var lump_inf: Array[LumpInfo]

var planes: Array[BSPPlane]
var verts: Array[Vector3]
var edges: Array[BSPEdge]
var surfedges: PackedInt32Array
var faces: Array[BSPFace]
var texinfo: Array[BSPTexInfo]
var texdata: Array[BSPTexData]
var texdatastringdata: PackedByteArray
var texdatastringtable: PackedInt32Array

enum {
	Lump_Entities,
	Lump_Planes,
	Lump_TexData,
	Lump_Vertexes,
	Lump_Visibility,
	Lump_Nodes,
	Lump_TexInfo,
	Lump_Faces,
	Lump_Lighting,
	Lump_Occlusion,
	Lump_Leafs,
	Lump_FaceIds,
	Lump_Edges,
	Lump_SurfEdges,
	Lump_Models,
	Lump_WorldLights,
	Lump_LeafFaces,
	Lump_LeafBrushes,
	Lump_Brushes,
	Lump_BrushSides,
	Lump_Areas,
	Lump_AreaPortals,
	Lump_PropCollision, # UNUSED0 (2007/9), PORTALS (2004)
	Lump_PropHulls, # UNUSED1 (2007/9), CLUSTERS (2004)
	Lump_PropHullVerts, # UNUSED2 (2007/9), PORTALVERTS (2004)
	Lump_PropTris, # UNUSED3 (2007/9), CLUSTERPORTALS (2004)
	Lump_DispInfo,
	Lump_OriginalFaces,
	Lump_PhysDisp,
	Lump_PhysCollide,
	Lump_VertNormals,
	Lump_VertNormalIndices,
	Lump_DispLightmapAlphas, # Unused/empty since 2006
	Lump_DispVerts,
	Lump_DispLightmapSamplePositions,
	Lump_GameLump, # Game Specific
	Lump_LeafWaterData,
	Lump_Primitives,
	Lump_PrimVerts,
	Lump_PrimIndices,
	Lump_PakFile,
	Lump_ClipPortalVerts,
	Lump_CubeMaps,
	Lump_TexDataStringData,
	Lump_TexDataStringTable,
	Lump_Overlays,
	Lump_LeafMinDistToWater,
	Lump_FaceMacroTextureInfo,
	Lump_DispTris,
	Lump_PropBlob, # Compressed win32-specific Havok terrain surface collision data (2004) deprecated and no longer used
	Lump_WaterOverlays,
	Lump_LeafAmbientIndexHdr, # Lightdata for Xbox (2006)
	Lump_LeafAmbientIndex,
	Lump_LightingHdr,
	Lump_WorldLightsHdr,
	Lump_LeafAmbientLightingHdr,
	Lump_LeafAmbientLighting, # LDR (unused)
	Lump_XZipPakFile, # Xbox pak file (2006) not used anymore
	Lump_FacesHdr,
	Lump_MapFlags,
	Lump_OverlayFades,
	Lump_OverlaySystemLevels,
	Lump_PhysLevel, # vdc says "todo:" so uhh idfk???
	Lump_DispMultiBlend
}

func read_file(path):
	if (!FileAccess.file_exists(path)):
		push_error("File " + path + " doesn't exist!")
		return
	
	var file = FileAccess.open(path, FileAccess.READ)
	
	# read the first 4 bytes
	var ident_bytes = file.get_buffer(4)
	if (ident_bytes.get_string_from_ascii() != "VBSP"):
		push_error("File " + path + " isn't a VBSP file!")
		return
	
	# read in the version
	version = file.get_32()
	if (version != BSP_VERISON):
		push_error("File " + path + " isn't a v25 VBSP file!")
		return
	
	# the next section is the list of lump structures within the file
	for i in range(0, HEADER_LUMPS):
		lump_inf.push_back(LumpInfo.new(file))
	
	map_revision = file.get_32()
	
	# read in a few lumps
	file.seek(lump_inf[Lump_Planes].file_ofs)
	while (file.get_position() < lump_inf[Lump_Planes].file_ofs + lump_inf[Lump_Planes].file_len):
		planes.push_back(BSPPlane.new(file))
	
	file.seek(lump_inf[Lump_Vertexes].file_ofs)
	while (file.get_position() < lump_inf[Lump_Vertexes].file_ofs + lump_inf[Lump_Vertexes].file_len):
		verts.push_back(Vector3(file.get_float(), file.get_float(), file.get_float()))
	
	file.seek(lump_inf[Lump_Edges].file_ofs)
	while (file.get_position() < lump_inf[Lump_Edges].file_ofs + lump_inf[Lump_Edges].file_len):
		edges.push_back(BSPEdge.new(file))
	
	file.seek(lump_inf[Lump_SurfEdges].file_ofs)
	while (file.get_position() < lump_inf[Lump_SurfEdges].file_ofs + lump_inf[Lump_SurfEdges].file_len):
		surfedges.push_back(Global.unsigned32_to_signed(file.get_32()))
	
	file.seek(lump_inf[Lump_Faces].file_ofs)
	while (file.get_position() < lump_inf[Lump_Faces].file_ofs + lump_inf[Lump_Faces].file_len):
		faces.push_back(BSPFace.new(file))
	
	file.seek(lump_inf[Lump_TexInfo].file_ofs)
	while (file.get_position() < lump_inf[Lump_TexInfo].file_ofs + lump_inf[Lump_TexInfo].file_len):
		texinfo.push_back(BSPTexInfo.new(file))
	
	file.seek(lump_inf[Lump_TexData].file_ofs)
	while (file.get_position() < lump_inf[Lump_TexData].file_ofs + lump_inf[Lump_TexData].file_len):
		texdata.push_back(BSPTexData.new(file))
	
	file.seek(lump_inf[Lump_TexDataStringData].file_ofs)
	texdatastringdata = file.get_buffer(lump_inf[Lump_TexDataStringData].file_len)
	
	file.seek(lump_inf[Lump_TexDataStringTable].file_ofs)
	while (file.get_position() < lump_inf[Lump_TexDataStringTable].file_ofs + lump_inf[Lump_TexDataStringTable].file_len):
		texdatastringtable.push_back(file.get_32())

func get_texture_name(index: int) -> String:
	var baOff = texdatastringtable[index]
	
	var extractedBytes: PackedByteArray = []
	var i = baOff
	while (texdatastringdata[i] != 0):
		extractedBytes.push_back(texdatastringdata[i])
		i += 1
	
	return extractedBytes.get_string_from_utf8()

class BSPEdge:
	var p1: int
	var p2: int
	
	func _init(file: FileAccess):
		p1 = file.get_32()
		p2 = file.get_32()

class BSPPlane:
	var normal: Vector3
	var dist: float
	var type: int
	
	func _init(file: FileAccess):
		normal = Vector3(
			file.get_float(),
			file.get_float(),
			file.get_float()
		)
		dist = file.get_float()
		type = file.get_32()
	
	func _to_string():
		return "PLANE(" \
		+ "normal: " + str(normal) + ", " \
		+ "dist: " + str(dist) + ", " \
		+ "type: " + str(type) \
		+ ")"

class BSPFace:
	var planenum: int # unsigned
	var side: int # byte
	var onNode: bool # true if on node, false if in leaf
	var firstedge: int
	var numedges: int
	var texinfo: int
	var dispinfo: int
	var surfaceFogVolumeID: int # ?
	
	var styles: PackedByteArray # switchable lighting info
	var lightofs: int # offset into lightmap lump
	
	var area: float # face area in units^2
	
	var LightmapTextureMinsInLuxels: Array[int] # tex light info
	var LightmapTextureSizeInLuxels: Array[int] # tex light info
	
	var origFace: int # original face this was split from
	
	var enableShadows: int # 1 bit (how do I even read this)
	var numPrims: int # 31 bits
	
	var firstPrimID: int # unsigned
	var smoothingGroups: int # unsigned - lightmap smoothing group
	
	func _init(file: FileAccess):
		planenum = file.get_32()
		side = file.get_8()
		onNode = (file.get_8() == 1)
		
		# JUNK
		file.get_16()
		
		firstedge = file.get_32()
		numedges = file.get_32()
		texinfo = file.get_32()
		dispinfo = file.get_32()
		surfaceFogVolumeID = file.get_32()
		
		styles = file.get_buffer(4)
		
		lightofs = file.get_32()
		area = file.get_float()
		LightmapTextureMinsInLuxels = [file.get_32(), file.get_32()]
		LightmapTextureSizeInLuxels = [file.get_32(), file.get_32()]
		origFace = file.get_32()
		
		file.get_32()
		
		firstPrimID = file.get_32()
		smoothingGroups = file.get_32()

class BSPTexInfo:
	var textureVecs: Array[Vector4]
	var lightmapVecs: Array[Vector4]
	var flags: int # miptex flags overrides
	var texdata: int # pointer to texture name, size, etc.
	
	func _init(file: FileAccess):
		textureVecs = [
			Vector4(file.get_float(), file.get_float(), file.get_float(), file.get_float()),
			Vector4(file.get_float(), file.get_float(), file.get_float(), file.get_float())
		]
		lightmapVecs = [
			Vector4(file.get_float(), file.get_float(), file.get_float(), file.get_float()),
			Vector4(file.get_float(), file.get_float(), file.get_float(), file.get_float())
		]
		flags = file.get_32()
		texdata = file.get_32()

class BSPTexData:
	var reflectivity: Vector3
	var nameStringTableID: int # index into texdatastringtable
	var width: int
	var height: int
	var view_width: int
	var view_height: int
	
	func _init(file: FileAccess):
		reflectivity = Vector3(
			file.get_float(),
			file.get_float(),
			file.get_float()
		)
		nameStringTableID = file.get_32()
		width = file.get_32()
		height = file.get_32()
		view_width = file.get_32()
		view_height = file.get_32()

class LumpInfo:
	var file_ofs: int
	var file_len: int
	var version: int
	var four_cc: PackedByteArray # may be int for compressed lumps?
	
	func _init(file: FileAccess):
		# read out each segment of the struct
		file_ofs = file.get_32()
		file_len = file.get_32()
		version = file.get_32()
		# ident code
		four_cc = file.get_buffer(4)
