tool
extends SceneTree

var bakeEnvironment = preload("res://BakeEnv.tscn")

var qodotSpatial
var qodotMap 
var lightmap
var mapFilePath
var lightFilePath
var texturePath

func _usage():
	print("Usage: godot -s bake_lighting.gd <map file> <target .lmbakex file> <game texture folder>")

func _clean_exit(exitCode):
	call_deferred("_deferred_cleanup", exitCode)

func _cleanup_tmp():
	var tmpDir = Directory.new()
	var err = tmpDir.open("tmp")
	if err == OK:
		tmpDir.list_dir_begin(true)
		var file_name = tmpDir.get_next()
		while file_name != "":
			err = tmpDir.remove(file_name)
			if err != OK:
				print("Could not remove file '%s': %d" % [file_name, err])
			file_name = tmpDir.get_next()
	else:
		print("Could not open temp directory for removal: %d" % err)

func _deferred_cleanup(exitCode):
	print("Cleaning up..")

	# Remove all files from /tmp
	# tmp is part of the project structure so we can't easily remove the folder from here
	# and anyway it doesn't hurt anything by sticking around
	_cleanup_tmp()

	# Wipe out bake environment scene & quit
	qodotSpatial.free()
	quit(exitCode)

func _build_failed():
	_clean_exit(1)

func _is_image_ext(extension: String) -> bool:
	return extension == "bmp" || extension == "dds" || extension == "exr" || \
		extension == "hdr" || extension == "jpg" || extension == "jpeg" || \
		extension == "png" || extension == "tga" || extension == "svg" || \
		extension == "svgz" || extension == "webp" || extension == "tres" || \
		extension == "res"

func _build_game_texture_dir(textureAccum: Dictionary, relativePath: String) -> int:
	var dir := Directory.new()
	var file := File.new()
	var dirPath := "%s/%s" % [texturePath,relativePath]
	var err := dir.open(dirPath)
	if err != OK:
		return err 
	
	err = dir.list_dir_begin(true)
	if err != OK:
		return err 
	
	var file_name := dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			err = _build_game_texture_dir(textureAccum, "%s/%s" % [relativePath, file_name])
			if err != OK:
				dir.list_dir_end()
				return err
		elif _is_image_ext(file_name.get_extension()):
			var fileRelativePath := "%s/%s" % [relativePath, file_name]
			var fileAbsolutePath := "%s/%s" % [dirPath, file_name]
			textureAccum[fileRelativePath] = file.get_modified_time(fileAbsolutePath)
		
		file_name = dir.get_next()
	
	return OK

func _apply_game_texture_dir(textureAccum: Dictionary, waitAccum: Array, relativePath: String) -> int:
	var dir := Directory.new()
	var file := File.new()
	var dirPath := "res://textures/%s" % relativePath
	var err := dir.open(dirPath)
	if err != OK:
		return err 
	
	err = dir.list_dir_begin(true)
	if err != OK:
		return err 
	
	var file_name := dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			err = _apply_game_texture_dir(textureAccum, waitAccum, "%s/%s" % [relativePath, file_name])
			if err != OK:
				dir.list_dir_end()
				return err 
		elif _is_image_ext(file_name.get_extension()):
			var fileRelativePath := "%s/%s" % [relativePath, file_name]
			var fileAbsolutePath := "%s/%s" % [dirPath, file_name]
			
			if !textureAccum.has(fileRelativePath):
				print("Removing texture '%s'" % fileRelativePath)
				err = dir.remove(fileAbsolutePath)
				if err != OK:
					dir.list_dir_end()
					return err 
			else:
				var gameModifiedTime = textureAccum[fileRelativePath]
				textureAccum.erase(fileRelativePath)
				var localModifiedTime = file.get_modified_time(fileAbsolutePath)
				if localModifiedTime < gameModifiedTime:
					print("Updating texture '%s'" % fileRelativePath)
					err = dir.copy("%s/%s" % [texturePath, fileRelativePath], fileAbsolutePath)
					if err != OK:
						dir.list_dir_end()
						return err 
					waitAccum.append(fileAbsolutePath)
		
		file_name = dir.get_next()
	
	return OK

func _cleanup_tex_folders(relativePath: String) -> Array:
	var dir := Directory.new()
	var dirPath := "res://textures/%s" % relativePath
	var err := dir.open(dirPath)
	if err != OK:
		return [false, err]
	
	err = dir.list_dir_begin(true)
	if err != OK:
		return [false, err]
	
	var file_path = dir.get_next()
	var delete_this_folder = true
	while file_path != "":
		if dir.current_is_dir():
			var cleanup_result = _cleanup_tex_folders("%s/%s" % [relativePath, file_path])
			if cleanup_result[1] != OK:
				return [false, cleanup_result[1]]
			
			if !cleanup_result[0]:
				delete_this_folder = false
		else:
			delete_this_folder = false
		
		file_path = dir.get_next()
	
	if delete_this_folder:
		err = dir.remove(dirPath)
		if err != OK:
			return [false, err]
	
	return [true, OK]

func _update_textures(waitAccum: Array) -> int:
	var textureAccum := {}
	
	# Get paths & modified times for all textures in the game directory
	var err = _build_game_texture_dir(textureAccum, "")
	if err != OK:
		return err 
	
	# Enum files in the local dir- delete any that aren't in the game directory
	# and update any out of date
	err = _apply_game_texture_dir(textureAccum, waitAccum, "")
	if err != OK:
		return err 
	
	# Enum files remaining in the game texture dictionary & move them over
	# to local dir
	var dir := Directory.new()
	for path in textureAccum.keys():
		var fromPath = "%s/%s" % [texturePath, path]
		var toPath = "res://textures/%s" % path
		var toDir = toPath.get_base_dir()
		if !dir.dir_exists(toDir):
			err = dir.make_dir_recursive(toDir)
			if err != OK:
				return err 
		
		print("Creating texture '%s'" % path)
		err = dir.copy(fromPath, toPath)
		if err != OK:
			return err 
		waitAccum.append(toPath)
	
	#Cleanup folders that have been left empty by texture removals
	var cleanup_result = _cleanup_tex_folders("")
	return cleanup_result[1]

func _write_mesh_to_dictionary(node, meshDict):
	if node.is_class("MeshInstance"):
		var mesh = node.get_mesh()
		var name = mesh.resource_path
		var surfaces = Array()
		if !meshDict.has(name):
			for i in mesh.get_surface_count():
				var surfaceArrays = mesh.surface_get_arrays(i)
				surfaces.append(surfaceArrays)
			
			meshDict[name] = surfaces
		
	for child in node.get_children():
		_write_mesh_to_dictionary(child, meshDict)

func _fix_map_owners(node):
	for child in node.get_children():
		child.set_owner(qodotSpatial)
		_fix_map_owners(child)

func _build_and_bake():
	print("Loading Bake Environment...")
	qodotSpatial = bakeEnvironment.instance()
	get_root().add_child(qodotSpatial)
	print("Loaded.  Preparing scene.")

	qodotMap = qodotSpatial.find_node("QodotMap")
	lightmap = qodotSpatial.find_node("BakedLightmap")

	qodotMap.map_file = mapFilePath
	print(mapFilePath)
	qodotMap.connect("build_failed", self, "_build_failed")

	print("Scene ready...")

	qodotMap.verify_and_build()
	yield(qodotMap, "build_complete")

	qodotMap.call_deferred("unwrap_uv2")
	yield(qodotMap, "unwrap_uv2_complete")

	var meshDict = Dictionary()
	_write_mesh_to_dictionary(qodotMap, meshDict)
	
	var meshFilePath = "%s.mesh" % lightFilePath.get_basename()

	var lightmapFile = Directory.new()
	if meshDict.size() > 0:
		var meshFile = File.new()
		meshFile.open_compressed("tmp/%s" % meshFilePath.get_file(), File.WRITE, File.COMPRESSION_GZIP)
		meshFile.store_var(meshDict)
		meshFile.close()
		print("MESHES WRITTEN TO FILE")

		var err = lightmapFile.rename("tmp/%s" % meshFilePath.get_file(), meshFilePath)
		if err == OK:
			print("MESHES MOVED TO OUTPUT PATH")
		else:
			print("Failed to move meshes to output path '%s': %d" % [meshFilePath, err])
	else:
		print("No meshes found to write to file")
		_clean_exit(1)
		return

	_fix_map_owners(qodotMap)

	yield(self, "idle_frame")
	var err = lightmap.bake(null, "tmp/%s.lmbake" % mapFilePath.get_file().get_basename())
	if err:
		print("Lightmap bake failed: %d" % err)
		_clean_exit(1)
		return 
	
	print("LIGHTMAP BAKED SUCCESFULLY")
	
	var tmpDir = Directory.new()
	err = tmpDir.open("tmp")
	if err == OK:
		var targetDir = lightFilePath.get_base_dir()
		var mapName = lightFilePath.get_file().get_basename()
		tmpDir.list_dir_begin(true)
		var file_name = tmpDir.get_next()
		while file_name != "":
			if file_name.get_extension() == "png" || file_name.get_extension() == "exr":
				var targetFileName = file_name.get_file()
				
				if file_name.get_extension() == "exr":
					targetFileName = "%s.hdr" % file_name.get_file().get_basename()
				
				if targetFileName.substr(0, len(mapName)) != mapName:
					targetFileName = "%s-%s" % [mapName, targetFileName]
					
				var targetPath = "%s/%s" % [targetDir, targetFileName]
				
				if file_name.get_extension() == "png":
					# PNGs can be loaded at runtime, so just copy it
					err = tmpDir.copy("res://tmp/%s" % file_name, targetPath)
					if err != OK:
						print("Could not copy light texture '%s' to '%s': %d" % [file_name, targetPath, err])
						_clean_exit(1)
						return
				else:
					#EXRs cannot be loaded at runtime, so convert to HDR
					var exrImg = Image.new()
					err = exrImg.load("res://tmp/%s" % file_name)
					if err != OK:
						print("Could not load EXR texture '%s': %d" % [file_name, err])
						_clean_exit(1)
						return
					err = HDRConverter.image_to_hdr(exrImg, targetPath)
					if err != OK:
						print("Could not convert EXR to HDR for file '%s': %d" % [targetPath, err])
						_clean_exit(1)
						return
				
				print("COPIED LIGHTMAP '%s'" % targetPath)
			file_name = tmpDir.get_next()
	else:
		print("Could not open temp directory to copy light textures: %d" % err)
		_clean_exit(1)
		return
	
	var lmbakex = File.new()
	err = lmbakex.open("%s.lmbakex" % lightFilePath.get_basename(), File.WRITE)
	if err != OK:
		print("Failed to open lmbakex file for writing: %d" % err)
		_clean_exit(1)
		return 
	
	var outputBake = BakedData.new()
	outputBake.populate_bake_lightmap_data(lightFilePath, lightmap.light_data)
	outputBake.save(lmbakex)
	lmbakex.flush()
	lmbakex.close()
	print("LMBAKEX WRITTEN")
	
	_clean_exit(0)

func _init():
	var args = OS.get_cmdline_args()
	if len(args) < 5:
		_usage()
		quit(1)
		return
	
	mapFilePath = args[2]
	lightFilePath = args[3]
	texturePath = args[4]

	if mapFilePath.get_extension() != "map":
		print("Map file '%s' is not a '.map' file" % mapFilePath)
		_usage()
		quit(1)
		return
	
	if lightFilePath.get_extension() != "lmbakex":
		print("Light file '%s' must be a file path ending in '.lmbakex'" % lightFilePath)
		_usage()
		quit(1)
		return
	
	var workingDir = Directory.new()
	if !workingDir.dir_exists(texturePath):
		print("Game texture directory '%s' does not exist" % texturePath)
		quit(1)
		return
	
	if !workingDir.dir_exists("res://tmp"):
		print("Creating tmp directory for output")
		workingDir.make_dir("res://tmp")
	
	_cleanup_tmp()
	
	print("Updating texture imports...")
	var filesToWaitOn = []
	var err = _update_textures(filesToWaitOn)
	if err != OK:
		print("Failed to update local textures: %d" % err)
		quit(1)
		return 
	
	var messagedAboutImport = false
	for filePath in filesToWaitOn:
		while !ResourceLoader.exists(filePath):
			if !messagedAboutImport:
				messagedAboutImport = true
				print("Waiting on texture import...")
			yield(self, "idle_frame")
		
	print("TEXTURES UPDATED")
	
	call_deferred("_build_and_bake")
