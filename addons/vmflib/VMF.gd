extends "res://addons/vmflib/VMFRoot.gd"
class_name VMF


var versioninfo: VersionInfo
var visgroups: VisGroups
var viewsettings: ViewSettings
var world: VWorld
var cameras: Cameras
var cordons: Cordons

var game_path: String


enum GAMES {
	PORTAL_2
}

const DEFAULT_MATERIAL = "TOOLS/TOOLSNODRAW"

func _init(game: int = GAMES.PORTAL_2) -> void:
	super("")
	
	self.versioninfo = VersionInfo.new()
	self.visgroups = VisGroups.new()
	self.viewsettings = ViewSettings.new()
	self.cameras = Cameras.new()
	self.cordons = Cordons.new()
	
	self.children.append(self.versioninfo)
	self.children.append(self.visgroups)
	self.children.append(self.viewsettings)
	self.children.append(self.cameras)
	self.children.append(self.cordons)
	self.world = VWorld.new(self, game) # Automatically added to children

func read_file(path: String) -> VMF:
	if (!FileAccess.file_exists(path)):
		push_error("File does not exist!")
		return self

	var contents = FileAccess.get_file_as_string(path)
	
	var _read_entity = func():
		print("Read entity block!")
		pass
	
	for i in range(0, contents.length()):
		pass
	
	# lol. lmao even.
	return self

func add_solid(block: Block) -> VMF:
	self.world.children.append(block.brush)
	return self

func add_solids(blocks: Array[Block]) -> VMF:
	for b in blocks:
		self.add_solid(b)
	return self

func add_block(origin: Vector3 = Vector3(), dimensions: Vector3 = Vector3(64, 64, 64), material: String = DEFAULT_MATERIAL) -> VMF:
	return self.add_solid(Block.new(self, origin, dimensions, material))

var entity_count := 0
func allocEntityID() -> int:
	self.entity_count += 1
	return self.entity_count - 1

var world_count := 0
func allocWorldID() -> int:
	self.world_count += 1
	return self.world_count - 1

var solid_count := 0
func allocSolidID() -> int:
	self.solid_count += 1
	return self.solid_count - 1

var side_count := 0
func allocSideID() -> int:
	self.side_count += 1
	return self.side_count - 1

var group_count := 0
func allocGroupID() -> int:
	self.group_count += 1
	return self.group_count - 1

var visgroup_count := 0
func allocVisGroupID() -> int:
	self.visgroup_count += 1
	return self.visgroup_count - 1

func write_to_file(filename: String = "user://output.vmf") -> void:
	var f: FileAccess = FileAccess.open(filename, FileAccess.WRITE)
	f.store_string(self.getAsStr())
	f.close()

func _to_string() -> String:
	return self.getAsStr()


# -v- HELPER CLASSES -v- #

class Vertex:
	var x: int
	var y: int
	var z: int
	var parenthesis: bool
	
	func _init(x: int = 0, y: int = 0, z: int = 0, show_parenthesis: bool = true) -> void:
		self.x = x
		self.y = y
		self.z = z
		self.parenthesis = show_parenthesis
	
	func setParenthesis(enabled: bool):
		self.parenthesis = enabled
	
	func vec3() -> Vector3:
		return Vector3(self.x, self.y, self.z)
	
	func getAsStr() -> String:
		if parenthesis:
			return "(%d %d %d)" % [self.x, self.y, self.z]
		else:
			return "%d %d %d" % [self.x, self.y, self.z]
	
	func _to_string() -> String:
		return self.getAsStr()
	
	func add(other: Vertex):
		return Vertex.new(self.x + other.x, self.y + other.y, self.z + other.z)
	
	func subtract(other: Vertex) -> Vertex:
		return Vertex.new(self.x - other.x, self.y - other.y, self.z - other.z)
	
	func multiply(other: int) -> Vertex:
		return Vertex.new(self.x * other, self.y * other, self.z * other)


class Axis:
	var x: int
	var y: int
	var z: int
	var tex_shift: int
	var tex_scale: float
	
	func _init(origin: Vector3i, tex_shift: int = 0, tex_scale: float = 0.25) -> void:
		self.x = origin.x
		self.y = origin.y
		self.z = origin.z
		self.tex_shift = tex_shift
		self.tex_scale = tex_scale
	
	func getAsStr() -> String:
		return "[%d %d %d %d] %f" % [self.x, self.y, self.z, self.tex_shift, self.tex_scale]
	
	func _to_string() -> String:
		return self.getAsStr()


class VColor:
	var r: int
	var g: int
	var b: int
	var a: int
	
	func _init(r: int, g: int, b: int, a: int = -1) -> void:
		self.r = r
		self.g = g
		self.b = b
		self.a = a
	
	func getAsStr() -> String:
		if a < 0:
			return "%d %d %d" % [r, g, b]
		else:
			return "%d %d %d %d" % [r, g, b, a]
	
	func _to_string() -> String:
		return self.getAsStr()


class VPlane:
	var v0: Vertex:
		set(v):
			v0 = v
			v0.setParenthesis(true)
			self.recalculate_normal()
	var v1: Vertex:
		set(v):
			v1 = v
			v1.setParenthesis(true)
			self.recalculate_normal()
	var v2: Vertex:
		set(v):
			v2 = v
			v2.setParenthesis(true)
			self.recalculate_normal()
	var normal: Vector3
	
	func _init(v0: Vertex = Vertex.new(), v1: Vertex = Vertex.new(), v2: Vertex = Vertex.new()) -> void:
		self.v0 = v0
		self.v1 = v1
		self.v2 = v2
	
	func recalculate_normal() -> void:
		if v0 != null and v1 != null and v2 != null:
			self.normal = v1.vec3() - v0.vec3()
			self.normal = normal.cross(v2.vec3() - v0.vec3())
			self.normal = normal.normalized()
	
	func get_normal() -> Vector3:
		if (self.normal != Vector3.ZERO):
			return self.normal
		self.recalculate_normal()
		return self.normal
	
	# https://github.com/LogicAndTrick/sledge-formats/blob/master/Sledge.Formats/NumericsExtensions.cs#L113
	func get_best_axes() -> Array[Vector3i]:
		const baseaxis := [
			Vector3i(0, 0, 1), Vector3i(1, 0, 0), Vector3i(0, -1, 0),
			Vector3i(0, 0, -1), Vector3i(1, 0, 0), Vector3i(0, -1, 0),
			Vector3i(1, 0, 0), Vector3i(0, 1, 0), Vector3i(0, 0, -1),
			Vector3i(-1, 0, 0), Vector3i(0, 1, 0), Vector3i(0, 0, -1),
			Vector3i(0, 1, 0), Vector3i(1, 0, 0), Vector3i(0, 0, -1),
			Vector3i(0, -1, 0), Vector3i(1, 0, 0), Vector3i(0, 0, -1)
		]

		var best := 0.0;
		var bestaxis := 0;

		for i in range(6):
			var dot = self.get_normal().dot(baseaxis[i * 3]);
			if not(dot > best): continue;

			best = dot;
			bestaxis = i;

		return [baseaxis[bestaxis * 3 + 1], baseaxis[bestaxis * 3 + 2], baseaxis[bestaxis * 3]]
	
	func get_uaxis() -> Axis:
		return Axis.new(self.get_best_axes()[0])
	
	func get_vaxis() -> Axis:
		return Axis.new(self.get_best_axes()[1])
	
	func get_axes_normal() -> Vector3i:
		return self.get_best_axes()[2]
	
	func getAsStr() -> String:
		return "%s %s %s" % [str(v0), str(v1), str(v2)]
	
	func _to_string() -> String:
		return self.getAsStr()


class Output:
	var event: String
	var target: String
	var input: String
	var parameter: String
	var delay: int
	var times_to_fire: int
	
	func _init(event: String, target: String, input: String, parameter: String = "", delay: int = 0, times_to_fire: int = -1) -> void:
		self.event = event
		self.target = target
		self.input = input
		self.parameter = parameter
		self.delay = delay
		self.times_to_fire = times_to_fire
	
	func getAsStr() -> String:
		return "\"%s\" \"%s,%s,%s,%d,%d\"" % [self.event, self.target, self.input, self.parameter, self.delay, self.times_to_fire]
	
	func _to_string() -> String:
		return self.getAsStr()


class VersionInfo extends "res://addons/vmflib/VMFRoot.gd":
	var editorversion = 400
	var editorbuild = 8997
	var mapversion = 0
	var formatversion = 100
	var prefab = 0
	
	func _init() -> void:
		super("versioninfo")
		self.auto_properties.append("editorversion")
		self.auto_properties.append("editorbuild")
		self.auto_properties.append("mapversion")
		self.auto_properties.append("formatversion")
		self.auto_properties.append("prefab")


class VisGroups extends "res://addons/vmflib/VMFRoot.gd":
	func _init() -> void:
		super("visgroups")


class ViewSettings extends "res://addons/vmflib/VMFRoot.gd":
	var bSnapToGrid: bool
	var bShowGrid: bool
	var bShowLogicalGrid: bool
	var nGridSpacing: int
	var bShow3DGrid: bool
	
	func _init(grid_snap: bool = true, grid_visible: bool = true, grid_spacing: int = 64, grid_3d_visible: bool = false) -> void:
		super("viewsettings")
		self.bSnapToGrid = grid_snap
		self.bShowGrid = grid_visible
		self.bShowLogicalGrid = false
		self.nGridSpacing = grid_spacing
		self.bShow3DGrid = grid_3d_visible
		self.auto_properties.append("bSnapToGrid")
		self.auto_properties.append("bShowGrid")
		self.auto_properties.append("bShowLogicalGrid")
		self.auto_properties.append("nGridSpacing")
		self.auto_properties.append("bShow3DGrid")


class Cameras extends "res://addons/vmflib/VMFRoot.gd":
	var activecamera := -1
	
	func _init() -> void:
		super("cameras")
		self.auto_properties.append("activecamera")


class Cordons extends "res://addons/vmflib/VMFRoot.gd":
	var active := false
	
	func _init() -> void:
		super("cordons")
		self.auto_properties.append("active")


class Entity extends "res://addons/vmflib/VMFRoot.gd":
	var classname: String
	var connections: Connections
	
	func _init(vmf: VMF, className: String, super_name: String = "entity") -> void:
		super(super_name)
		self.classname = className
		self.connections = null
		self.properties['id'] = vmf.allocEntityID()
		self.properties['classname'] = self.classname
		vmf.children.append(self)
	
	func add_output(output: Output) -> void:
		if self.connections == null:
			self.connections = Connections.new()
			self.children.append(self.connections)
		self.connections.children.append(output)
	
	func add_outputs(outputs: Array[Output]) -> void:
		for o in outputs:
			self.add_output(o)


class Connections extends "res://addons/vmflib/VMFRoot.gd":
	func _init() -> void:
		super("connections")
	
	func getAsStr(tab_level: int = -1) -> String:
		var string: String = ""
		var tab_prefix: String = ""
		for i in range(tab_level):
			tab_prefix += "\t"
		var tab_prefix_inner: String = tab_prefix + "\t"
		if (self.vmf_class_name):
			string += tab_prefix + self.vmf_class_name + "\n"
			string += tab_prefix + "{\n"
		for output in self.children:
			string += tab_prefix_inner + output + "\n"
		if (self.vmf_class_name):
			string += tab_prefix + "}\n"
		return string
	
	func _to_string() -> String:
		return self.getAsStr()


class VWorld extends Entity:
	var skyname: String
	var detailmaterial: String
	var detailvbsp: String
	var maxblobcount: int
	var maxpropscreenwidth: int
	var mapversion := 0
	
	func _init(vmf: VMF, game: int) -> void:
		super(vmf, "worldspawn", "world")
		self.auto_properties.append("mapversion")
		match game:
			GAMES.PORTAL_2:
				self.skyname = "sky_black_nofog"
				self.detailmaterial = "detail/detailsprites"
				self.detailvbsp = "detail.vbsp"
				self.maxblobcount = 250
				self.maxpropscreenwidth = -1
				self.auto_properties.append("skyname")
				self.auto_properties.append("detailmaterial")
				self.auto_properties.append("detailvbsp")
				self.auto_properties.append("maxblobcount")
				self.auto_properties.append("maxpropscreenwidth")
			_:
				assert(false, "Must be a valid game")
		self.properties['id'] = vmf.allocWorldID()


class Solid extends "res://addons/vmflib/VMFRoot.gd":
	func _init(vmf: VMF) -> void:
		super("solid")
		self.properties['id'] = vmf.allocSolidID()


class Side extends "res://addons/vmflib/VMFRoot.gd":
	var plane: VPlane
	var material: String
	var rotation := 0
	var lightmapscale := 16
	var smoothing_groups := 0
	var uaxis: Axis:
		get:
			return self.plane.get_uaxis()
	var vaxis: Axis:
		get:
			return self.plane.get_vaxis()
	
	func _init(vmf: VMF, plane: VPlane = VPlane.new(), material: String = DEFAULT_MATERIAL) -> void:
		super("side")
		self.plane = plane
		self.material = material
		self.auto_properties.append("plane")
		self.auto_properties.append("material")
		self.auto_properties.append("uaxis")
		self.auto_properties.append("vaxis")
		self.auto_properties.append("rotation")
		self.auto_properties.append("lightmapscale")
		self.auto_properties.append("smoothing_groups")
		self.properties['id'] = vmf.allocSideID()


class Group extends "res://addons/vmflib/VMFRoot.gd":
	func _init(vmf: VMF) -> void:
		super("group")
		self.properties['id'] = vmf.allocGroupID()

# DispInfo ; Offsets ; OffestNormals ; TriangleTags ; AllowedVerts
# not included

class Normals extends "res://addons/vmflib/VMFRoot.gd":
	func _init(power, values) -> void:
		super("normals")
		for i in range(pow(2, power) + 1):
			var row_string = ""
			for vert in values[i]:
				row_string += str(vert.x) + " " + str(vert.y) + " " + str(vert.z)
			self.properties["row" + str(i)] = row_string


class Distances extends "res://addons/vmflib/VMFRoot.gd":
	var values: Array[int]
	
	func _init(power: int, values: Array[int]) -> void:
		super("distances")
		self.values = values
		for i in range(pow(2, power) + 1):
			var row_string = ""
			for distance in values[i]:
				row_string += str(distance) + " "
			self.properties["row" + str(i)] = row_string.strip_edges(false, true)


class Alphas extends "res://addons/vmflib/VMFRoot.gd":
	func _init(power: int, values: Array[int] = []) -> void:
		super("alphas")
		if len(values) > 0:
			for i in range(pow(2, power) + 1):
				var row_string = ""
				for distance in values[i]:
					row_string += str(distance) + " "
				self.properties["row" + str(i)] = row_string.strip_edges(false, true)


class Block:
	var origin: Vertex
	var dimensions: Array
	var brush: Solid
	
	func _init(vmf: VMF, origin: Vector3 = Vector3(), dimensions: Vector3 = Vector3(64, 64, 64), material: String = DEFAULT_MATERIAL) -> void:
		self.origin = Vertex.new(origin.x, origin.z, origin.y)
		self.dimensions = [dimensions.x, dimensions.z, dimensions.y]
		self.brush = Solid.new(vmf)
		for i in range(6):
			self.brush.children.append(Side.new(vmf, VPlane.new(), material))
		self.update_sides()
		self.set_material(material)
	
	func update_sides() -> void:
		var x = self.origin.x
		var y = self.origin.y
		var z = self.origin.z
		var w = self.dimensions[0]
		var l = self.dimensions[1]
		var h = self.dimensions[2]
		var a = w / 2
		var b = l / 2
		var c = h / 2
		self.brush.children[0].plane = VPlane.new(
			Vertex.new(x - a, y + b, z + c),
			Vertex.new(x + a, y + b, z + c),
			Vertex.new(x + a, y - b, z + c))
		self.brush.children[1].plane = VPlane.new(
			Vertex.new(x - a, y - b, z - c),
			Vertex.new(x + a, y - b, z - c),
			Vertex.new(x + a, y + b, z - c))
		self.brush.children[2].plane = VPlane.new(
			Vertex.new(x - a, y + b, z + c),
			Vertex.new(x - a, y - b, z + c),
			Vertex.new(x - a, y - b, z - c))
		self.brush.children[3].plane = VPlane.new(
			Vertex.new(x + a, y + b, z - c),
			Vertex.new(x + a, y - b, z - c),
			Vertex.new(x + a, y - b, z + c))
		self.brush.children[4].plane = VPlane.new(
			Vertex.new(x + a, y + b, z + c),
			Vertex.new(x - a, y + b, z + c),
			Vertex.new(x - a, y + b, z - c))
		self.brush.children[5].plane = VPlane.new(
			Vertex.new(x + a, y - b, z - c),
			Vertex.new(x - a, y - b, z - c),
			Vertex.new(x - a, y - b, z + c))
	
	func set_material(material: String) -> void:
		for side in self.brush.children:
			side.material = material
	
	func get_side(side: Vector3) -> Side:
		match side:
			Vector3.UP:
				return self.brush.children[0]
			Vector3.DOWN:
				return self.brush.children[1]
			Vector3.BACK:
				return self.brush.children[2]
			Vector3.FORWARD:
				return self.brush.children[3]
			Vector3.LEFT:
				return self.brush.children[4]
			Vector3.RIGHT:
				return self.brush.children[5]
			_:
				assert(false, "Vector3 passed must be Vector3.UP, Vector3.DOWN, etc.")
				return self.brush.children[0]
	
	func getAsStr(tab_level: int = -1) -> String:
		return self.brush.getAsStr(tab_level)
	
	func _to_string() -> String:
		return self.getAsStr()

# Other classes in tools.py excluded


# -v- ENTITIES -v- #

class InfoPlayerStartEntity extends Entity:
	var origin: Vertex
	var angles: Vertex
		
	func _init(vmf: VMF, origin: Vector3 = Vector3(), angles: Vector3 = Vector3()) -> void:
		super(vmf, "info_player_start")
		self.origin = Vertex.new(origin.x, origin.z, origin.y)
		self.origin.setParenthesis(false)
		self.angles = Vertex.new(angles.x, angles.z, angles.y)
		self.angles.setParenthesis(false)
		self.auto_properties.append("origin")
		self.auto_properties.append("angles")

class LightEntity extends Entity:
	var origin: Vertex
	var targetname: String
	var _light: VColor
	var _lightHDR: VColor
	var _lightscaleHDR: float
	var style: int
	var pattern: String
	var _constant_attn: bool
	var _linear_attn: bool
	var _quadratic_attn: bool
	var _fifty_percent_distance: bool
	var _zero_percent_distance: bool
	var _hardfalloff: int
	var target: String
	var _distance: int
	
	func _init(vmf: VMF, origin: Vector3 = Vector3(), \
				targetname: String = "", _light: VColor = VColor.new(255,255,255,200), \
				_lightHDR: VColor = VColor.new(-1,-1,-1,1), _lightscaleHDR: float = 1, \
				style: int = 0, pattern: String = "", _constant_attn: bool = false, \
				_linear_attn: bool = true, _quadratic_attn: bool = false, \
				_fifty_percent_distance: bool = false, _zero_percent_distance: bool = false, \
				_hardfalloff: int = 0, target: String = "", _distance: int = 0) -> void:
		super(vmf, "light")
		self.origin = Vertex.new(origin.x, origin.z, origin.y)
		self.origin.setParenthesis(false)
		self.targetname = targetname
		self._light = _light
		self._lightHDR = _lightHDR
		self._lightscaleHDR = _lightscaleHDR
		self.style = style
		self.pattern = pattern
		self._constant_attn = _constant_attn
		self._linear_attn = _linear_attn
		self._quadratic_attn = _quadratic_attn
		self._fifty_percent_distance = _fifty_percent_distance
		self._zero_percent_distance = _zero_percent_distance
		self._hardfalloff = _hardfalloff
		self.target = target
		self._distance = _distance
		for prop in [
			"origin", "targetname", \
			"_light", "_lightHDR", \
			"_lightscaleHDR", "style",\
			"pattern", "_constant_attn",\
			"_linear_attn", "_quadratic_attn",\
			"_fifty_percent_distance", "_zero_percent_distance",\
			"_hardfalloff", "target",\
			"spawnflags", "_distance"
		]:
			self.auto_properties.append(prop)
