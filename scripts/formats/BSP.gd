class_name BSP extends Resource

const HEADER_LUMPS = 64
const LUMP_T_SIZE = 16

var version: int
var map_revision: int
var lump_inf: Array[LumpInfo]

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
	
	# the next section is the list of lump structures within the file
	for i in range(0, HEADER_LUMPS):
		lump_inf.push_back(LumpInfo.new(file))
	
	map_revision = file.get_32()

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
