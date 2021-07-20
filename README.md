# Archae Scripts

A project of [Trenchbroom](https://trenchbroom.github.io/) compilation scripts.  Built in [Godot](https://godotengine.org/) to be used with [Qodot](https://github.com/Shfty/qodot-plugin).

1. Lighting bake
2. ???

This project also includes my changes (improvements?) to the Qodot light-importing code.  Ideally this makes Qodot's light/wait/delay values act like they do in Quake, but godot's light attenuation model is completely different from quake's, on account of it being a real game engine made since the standardization of hardware acceleration, so your mileage may vary.  Feel free to blow that stuff up & go back to the qodot defaults, or invent your own!

 > An additional NB: This code does not properly handle cases where an atlased lightmap has a depth of >1.  This should only happen when QodotMap's "use trenchbroom group hierarchy" property is set, and there is a group consisting only of worldspawn brushes (or other statically-lit brushes). I have not been able to successfully load that case into Qodot.  If you can, these scripts will not work.

## How To Use Lighting Scripts

### Set up Trenchbroom Game

Install Trenchbroom.  Open the Godot project, configure, and export the "updated" Trenchbroom config folder in `trenchbroom/updated_qodot_config_folder.tres` to set up your trenchbroom game.  Then, click the checkbox to export the game folder.  You should have a .cfg file and .fgd file in the Trenchbroom/games/<Your Game> folder.

Be aware that the `updated_qodot_config_file` resources has a new property field in the inspector- "Compilation Tools".  From here, you can add "CompilationTool" resources and set name/description in order to add them to the generated Trenchbroom game config.  The config file resource comes preconfigured with two tools- `godot` and `runlighting`.

Start Trenchbroom, and from the New Map screen, "Open Preferences...".  From this menu, set up your game path, and the compilation tools.  `godot` should point to a Godot 3.3 executable.  `runlighting` should point to the `run_lighting.bat` file in this project.  I have not taken the time to make/test an equivalent shell script for Mac/Linux users, so if you are on one of those operating systems, you will need to do so.  The batch script is incredibly simple, though, so hopefully that won't be too much trouble.

### Set Up Trenchbroom Compile Stage

Create a new profile in the "Compile Map" menu.  The profile should use `${MAP_DIR_PATH}` as the working directory, and have a tool stage with the following properties:

Tool: `${runlighting}`
Parameters: `${godot} ${MAP_FULL_NAME} ${MAP_BASE_NAME}.lmbakex ${GAME_DIR_PATH}/textures`

You can make changes to these values (particularly, the textures path may need to be changed to match your game's own directory structure), but this should be considered the default.  One very important consideration is where to send the `.lmbakex` file.  If you are keeping two directories for maps- one "working directory" for trenchbroom and one "exported directory" for maps that are ready to be viewed in-game, your `.lmbakex` path should point to the latter directory rather than using `${MAP_BASE_NAME}`.  This may be a good idea, as the source of truth for level geometry is split between the `.mesh` file and the `.map` file, so loading versions of map files that haven't been baked yet will likely not produce desirable results.

### Configure Your Baking Environment

Open the Godot project and the `BakeEnv` scene.  Ensure that the QodotMap and BakedLightmap nodes have the configuration you are interested in.  This configuration will be used to bake all maps to files.  The QodotMap's texture directory should not be modified (we will cache your game's textures into res://texture as part of the lighting script), but the texture file extension *should* be changed to match your texture files.  

### Make And Compile Your Map

The lighting tool will produce three types of files when the compilation stage is run:

* A `.lmbakex` file, whose path is specified in the compilation parameters, will be generated.  This file contains all the same data as the `.lmbake` files produced by the Godot editor, but it is variant-encoded instead of being a resource, to allow it to load at runtime.  The LMBAKEX file is generated last, to allow your runtime code to hot-reload when it changes.
* A file named `${LMBAKEX_BASE_NAME}.mesh` will be generated, containing a compressed, variant-encoded dictionary of all worldspawn geometry, to be loaded at runtime.  It may be surprising that we are encoding the entire generated worldspawn at compile time, but we cannot produce a functioning lightmap texture without producing UVs, UV-unwrapping is not available at runtime, and the UV-unwrapping process permanently modifies the vertex count of the worldspawn geometry, so we cannot produce a set of UVs at compile time that will work against worldspawn geometry at runtime, unless we are also applying the entire vertex data.
* One or more `.hdr` or `.png` files.  HDR is used when your BakedLightmap is set to use HDR, and PNG when it is not.  If you select "Generate Atlas", a single texture file named `${LMBAKEX_BASE_NAME}.hdr/png` will be generated, otherwise one texture per mesh will be generated- these textures will all begin with `${LMBAKEX_BASE_NAME}-`.
  
  Once again, it might be surprising that the script outputs an `.hdr` file instead of `.exr`, which is the standard for Godot and what HDR lightmaps actually produce.  Unfortunately, Godot does not include a `.exr` loader at runtime, but does include a `.hdr` loader.  Code to convert `.exr` into `.hdr` is included in this project.

Note that if the set of generated files changes for some reason- you change the name of the LMBAKEX files in the compilation parameters, you change the BakeEnv properties, you have "Generate Atlas" unchecked and change the set of meshes in the scene- we will not clean up the old files, you will need to do that manually.

### Load Maps At Runtime

The resources in the `ingest` folder are example in-game scripts that can be used to load lit `.map` files at runtime.  This takes the form of a scene with a function that accepts a `.map` path which is expected to have a similarly named `.mesh`, `.lmbakex`, and related textures in the same folder, and generates a lit scene at runtime.  This will likely need to be edited for your own purposes, but you should feel free to copy/paste these scripts liberally into your own work.
