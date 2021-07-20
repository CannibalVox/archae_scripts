class_name BakedData

var bounds: AABB
var cell_space_transform: Transform
var cell_subdivision: int
var energy: float
var interior: bool

var octree: PoolByteArray

var userNodePaths: Array
var userTexNames: PoolStringArray
var userLightmapSlices: PoolIntArray
var userLightmapUVStart: PoolVector2Array
var userLightmapUVSize: PoolVector2Array
var userLightmapInstances: PoolIntArray

func save(f: File):
	f.store_var(bounds)
	f.store_var(cell_space_transform)
	f.store_32(cell_subdivision)
	f.store_real(energy)
	f.store_8(interior)
	f.store_var(octree)
	f.store_var(userNodePaths)
	f.store_var(userTexNames)
	f.store_var(userLightmapSlices)
	f.store_var(userLightmapUVStart)
	f.store_var(userLightmapUVSize)
	f.store_var(userLightmapInstances)

func populate_bake_lightmap_data(lightFilePath: String, data: BakedLightmapData):
	self.bounds = data.bounds
	self.cell_space_transform = data.cell_space_transform
	self.cell_subdivision = data.cell_subdiv
	self.energy = data.energy
	self.interior = data.interior
	self.octree = data.octree
	
	var userData = data._get_user_data()
	var mapName = lightFilePath.get_file().get_basename()
	for i in range(0, len(userData), 5):
		userNodePaths.append(userData[i])
		var texFileName = userData[i+1].resource_path.get_file()
		if texFileName.substr(0, len(mapName)) != mapName:
			texFileName = "%s-%s" % [mapName, texFileName]
		if texFileName.get_extension() == "exr":
			texFileName = "%s.hdr" % texFileName.get_basename()
		userTexNames.append(texFileName)
		userLightmapSlices.append(userData[i+2])
		var uvRect : Rect2 = userData[i+3]
		userLightmapUVStart.append(uvRect.position)
		userLightmapUVSize.append(uvRect.size)
		userLightmapInstances.append(userData[i+4])

