class_name UpdatedQodotLight
extends QodotEntity
tool

func update_properties():
	for child in get_children():
		remove_child(child)
		child.queue_free()

	var light_node = null

	if 'mangle' in properties:
		light_node = SpotLight.new()

		var yaw = properties['mangle'].x
		var pitch = properties['mangle'].y
		light_node.rotate(Vector3.DOWN, deg2rad(yaw))
		light_node.rotate(light_node.global_transform.basis.x, deg2rad(180 + pitch))

		if 'angle' in properties:
			light_node.set_param(Light.PARAM_SPOT_ANGLE, properties['angle'])
		else:
			light_node.set_param(Light.PARAM_SPOT_ANGLE, 40)
	else:
		light_node = OmniLight.new()

	var light_brightness = 300
	if 'light' in properties:
		light_brightness = properties['light']
		
	var dist_scale = 1.0
	if 'wait' in properties:
		dist_scale = properties['wait']
	
	var radius = 3*light_brightness / dist_scale / 32.0
	var scaled_brightness = 3*light_brightness / 128.0

	var light_attenuation = 0
	if 'delay' in properties:
		light_attenuation = properties['delay']

	var attenuation = 0
	match light_attenuation:
		0:
			attenuation = 1.0
		1:
			# In ericw-tools, this is set up so that the brightness halves every
			# 128 units away from the light (and the brightness is as-listed exactly
			# 128 units away).  Technically the brightness at 0 in ericw-tools is
			# a gazillion, but doubling it and having brightness approximately half
			# every 8 meters is probably as good as this will get
			scaled_brightness *= 10
			radius = 2000/dist_scale
			attenuation = 140.0
		2:
			# Like above, but quadrupling/quartering
			radius = 2000/dist_scale
			attenuation = 350.0
			scaled_brightness *= 20
		3:
			radius = 2000
			attenuation = 0
		4:
			# In ericw-tools, 4 is supposed to apply non-additively to the
			# lightmap (that is, it will raise any pixel in LOS with lower 
			# luminosity to the level indicated by this light's color
			# 
			# There's no clear way of doing that in godot, luckily everyone hates
			# this setting anyway
			radius = 2000
			attenuation = 0
		5:
			# In ericw-tools, this is a special delay setting that works as 2
			# but it skips the first 128 units of distance so that at 0 dist
			# it is the listed brightness and falls off from there.  That's
			# how godot is SUPPOSED to work so we just do less janky stuff
			radius = 2000/dist_scale
			attenuation = 250.0
		_:
			attenuation = 1

	light_node.set_param(Light.PARAM_ENERGY, scaled_brightness)
	light_node.set_param(Light.PARAM_INDIRECT_ENERGY, scaled_brightness)
	light_node.set_param(Light.PARAM_RANGE, radius)
	light_node.set_param(Light.PARAM_ATTENUATION, attenuation)
	light_node.set_shadow(true)
	light_node.set_bake_mode(Light.BAKE_ALL)

	var light_color = Color.white
	if '_color' in properties:
		light_color = properties['_color']

	light_node.set_color(light_color)

	add_child(light_node)

	if is_inside_tree():
		var tree = get_tree()
		if tree:
			var edited_scene_root = tree.get_edited_scene_root()
			if edited_scene_root:
				light_node.set_owner(edited_scene_root)
