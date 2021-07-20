extends Spatial

func _ready():
	$QodotMap.remove_children()

func _load_mesh_from_dictionary(node, meshDict):
	if node.is_class("MeshInstance"):
		var mesh = node.get_mesh()
		if mesh.is_class("ArrayMesh"):
			var name = mesh.resource_path
			var meshArrays = meshDict[name]
			if meshArrays and len(meshArrays) > 0:
				var surfaceMaterials = Array()
				for i in mesh.get_surface_count():					
					if len(meshArrays) <= i:
						print("Skipping surface %d: No Mesh Arrays" % i)
					else:
						surfaceMaterials.append(mesh.surface_get_material(i))
				
				while mesh.get_surface_count() > 0:
					mesh.surface_remove(0)

				for surfaceIdx in len(surfaceMaterials):
					mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, meshArrays[surfaceIdx])
					mesh.surface_set_material(surfaceIdx, surfaceMaterials[surfaceIdx])
	
	for child in node.get_children():
		_load_mesh_from_dictionary(child, meshDict)

func load_and_bake(path):	
	$QodotMap.map_file = path 
	$QodotMap.verify_and_build()
	yield($QodotMap, "build_complete")
	
	var loadFile = File.new()
	var meshFileName = "%s.mesh" % $QodotMap.map_file.get_basename()
	var err = loadFile.open_compressed(meshFileName, File.READ, File.COMPRESSION_GZIP)
	if err != OK:
		print("Failed to open mesh file '%s': %d" % [meshFileName, err])
		return 
		
	var meshDict : Dictionary = loadFile.get_var(true)
	_load_mesh_from_dictionary($QodotMap, meshDict)
	loadFile.close()
	
	var lmbakeFile = "%s.lmbakex" % $QodotMap.map_file.get_basename()
	err = loadFile.open(lmbakeFile, File.READ)
	if err != OK:
		print("Failed to open LMBakeX file '%s': %d" % [lmbakeFile, err])
		return 
	
	var data = BakedData.new()
	data.load(loadFile)
	loadFile.close()
	
	$BakedLightmap.light_data = data.create_bake_lightmap_data($QodotMap.map_file.get_base_dir())
	print("LIGHT DATA LOADED")

func _on_QodotMap_build_failed():
	pass # Replace with function body.
