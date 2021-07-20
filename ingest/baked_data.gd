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

func load(f: File):
	bounds = f.get_var()
	cell_space_transform = f.get_var()
	cell_subdivision = f.get_32()
	energy = f.get_real()
	interior = f.get_8()
	octree = f.get_var()
	userNodePaths = f.get_var()
	userTexNames = f.get_var()
	userLightmapSlices = f.get_var()
	userLightmapUVStart = f.get_var()
	userLightmapUVSize = f.get_var()
	userLightmapInstances = f.get_var()

func create_bake_lightmap_data(dataPath: String) -> BakedLightmapData:
	var data = BakedLightmapData.new()
	data.bounds = self.bounds
	data.cell_space_transform = self.cell_space_transform
	data.cell_subdiv = self.cell_subdivision
	data.energy = self.energy
	data.interior = self.interior
	
	if len(self.octree) > 0:
		data.octree = self.octree
	
	var texDict = Dictionary()
	
	for i in len(userNodePaths):
		var uvStart = userLightmapUVStart[i]
		var uvSize = userLightmapUVSize[i]
		var texName = userTexNames[i]
		
		if !texDict.has(texName):
			var texImg := Image.new()
			var texPath = "%s/%s" % [dataPath, texName]
			
			var err = texImg.load(texPath)
			if err != OK:
				print("Could not load texture file '%s': %d" % [texPath, err])
				return null
			
			var tex = null
			
			if userLightmapSlices[i] >= 0:
				tex = TextureArray.new()
				tex.create(texImg.get_width(), texImg.get_height(), 1, texImg.get_format(), Texture.FLAG_FILTER)
				tex.set_layer_data(texImg, 0)
			else:
				tex = ImageTexture.new()
				tex.create_from_image(texImg, Texture.FLAG_FILTER)
			
			texDict[texName] = tex
		
		data.add_user(userNodePaths[i], texDict[texName], userLightmapSlices[i], Rect2(uvStart, uvSize), userLightmapInstances[i])
	
	return data
