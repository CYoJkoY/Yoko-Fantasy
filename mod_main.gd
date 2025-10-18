extends Node

const MYMODNAME_MOD_DIR: String = "Yoko-Fantasy/"
const MYMODNAME_LOG: String = "Yoko-Fantasy"

var dir: String = ""
var ext_dir: String = ""
var trans_dir: String = ""

# =========================== Extension =========================== #
func _init():
	ModLoaderLog.info("========== Add Translation ==========", MYMODNAME_LOG)
	dir = ModLoaderMod.get_unpacked_dir() + MYMODNAME_MOD_DIR
	trans_dir = dir + "translations/"
	ext_dir = dir + "extensions/"
	
	# NameSpace ~ Node: /root/ModLoader/Yoko-FantasyWoodland/Fantasy
	# progress_data.gd --> _ready --> ProgressData.Fantasy
	var Fantasy_instance = load(dir + "content_data/NameSpace.gd").new()
	Fantasy_instance.name = "Fantasy"
	add_child(Fantasy_instance)
	
	#######################################
	########## Add translations ##########
	#####################################
	ModLoaderMod.add_translation(trans_dir + "Fantasy.en.translation")
	ModLoaderMod.add_translation(trans_dir + "Fantasy.zh_Hans_CN.translation")
	
	ModLoaderLog.info("========== Add Translation Done ==========", MYMODNAME_LOG)

	var extensions: Array = [

		"progress_data.gd"
		# Mod's Contents

	]

	var extensions2: Array = [

		["player_run_data.gd","res://singletons/player_run_data.gd"],
		# EFFECTS' NAMES

	]
	

	for path in extensions:
		ModLoaderMod.install_script_extension(ext_dir + path)
	for path2 in extensions2:
		YZ_extend_script(path2, ext_dir)

func YZ_extend_script(script: Array, _ext_dir: String) -> void:
	# OriginalFunction -> apply_extension
	# For player_run_data.gd
	var child_script_path: String = _ext_dir + script[0]
	var parent_script_path: String = script[1]

	var child_script: Script = load(child_script_path)
	child_script.set_meta("extension_script_path", child_script_path)

	var parent_script: Script = load(parent_script_path)

	if not ModLoaderStore.saved_scripts.has(parent_script_path):
		ModLoaderStore.saved_scripts[parent_script_path] = []

		ModLoaderStore.saved_scripts[parent_script_path].append(parent_script)

	ModLoaderStore.saved_scripts[parent_script_path].append(child_script)
	
	ModLoaderLog.info("Installing script extension via Yztato: %s <- %s" % [ parent_script_path, child_script_path ], MYMODNAME_LOG)

	child_script.take_over_path(parent_script_path)
