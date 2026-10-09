class_name Ambiente3D
extends RefCounted
## Ar de cada nivel 3D da Regiao I: ceu, lua, nevoeiro, brilho e grading.
## Cada nivel tem a sua cor (5 niveis visualmente distintos) dentro da paleta
## LOCKED da Floresta Corrompida.

const SH_CEU := preload("res://assets/r3d/shaders/ceu.gdshader")

## 0 Floresta Putrefata (esmeralda/luar) - 1 Pantano dos Sussurros (verde-acido,
## nevoa baixa) - 2 Ninho da Viuva Negra (roxo frio, teias) - 3 Arvore que Chora
## (azul-petroleo, luar forte) - 4 Coracao da Floresta (carmim/magenta).
const PERFIS := [
	{"zenite": Color(0.015, 0.04, 0.05), "horizonte": Color(0.07, 0.13, 0.12), "brilho": Color(0.12, 0.3, 0.22),
	 "nevoa": Color(0.08, 0.16, 0.14), "dens": 0.022, "lua": Color(0.75, 0.95, 0.88), "energia": 1.25,
	 "ambiente": Color(0.35, 0.55, 0.5), "amb_e": 0.55, "alt_nevoa": 1.2},
	{"zenite": Color(0.02, 0.035, 0.025), "horizonte": Color(0.12, 0.15, 0.07), "brilho": Color(0.25, 0.3, 0.08),
	 "nevoa": Color(0.12, 0.15, 0.08), "dens": 0.03, "lua": Color(0.85, 0.95, 0.7), "energia": 1.15,
	 "ambiente": Color(0.45, 0.5, 0.35), "amb_e": 0.55, "alt_nevoa": 0.6},
	{"zenite": Color(0.02, 0.015, 0.05), "horizonte": Color(0.1, 0.06, 0.15), "brilho": Color(0.25, 0.1, 0.35),
	 "nevoa": Color(0.09, 0.07, 0.14), "dens": 0.026, "lua": Color(0.75, 0.8, 1.0), "energia": 1.2,
	 "ambiente": Color(0.4, 0.38, 0.6), "amb_e": 0.55, "alt_nevoa": 1.5},
	{"zenite": Color(0.01, 0.035, 0.06), "horizonte": Color(0.05, 0.12, 0.16), "brilho": Color(0.1, 0.25, 0.3),
	 "nevoa": Color(0.06, 0.13, 0.17), "dens": 0.02, "lua": Color(0.7, 0.9, 1.0), "energia": 1.45,
	 "ambiente": Color(0.32, 0.5, 0.6), "amb_e": 0.55, "alt_nevoa": 1.0},
	{"zenite": Color(0.03, 0.012, 0.03), "horizonte": Color(0.12, 0.04, 0.07), "brilho": Color(0.3, 0.05, 0.16),
	 "nevoa": Color(0.11, 0.05, 0.08), "dens": 0.02, "lua": Color(1.0, 0.82, 0.86), "energia": 1.25,
	 "ambiente": Color(0.5, 0.4, 0.48), "amb_e": 0.5, "alt_nevoa": 1.4},
]


static func montar(pai: Node, perfil_i: int) -> DirectionalLight3D:
	var p: Dictionary = PERFIS[clampi(perfil_i, 0, PERFIS.size() - 1)]
	var ceu_mat := ShaderMaterial.new()
	ceu_mat.shader = SH_CEU
	ceu_mat.set_shader_parameter("cor_zenite", p["zenite"])
	ceu_mat.set_shader_parameter("cor_horizonte", p["horizonte"])
	ceu_mat.set_shader_parameter("cor_brilho", p["brilho"])
	ceu_mat.set_shader_parameter("cor_lua", p["lua"])
	var ceu := Sky.new()
	ceu.sky_material = ceu_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = ceu
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = p["ambiente"]
	env.ambient_light_energy = p["amb_e"]
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.05
	env.tonemap_white = 6.0
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_strength = 1.0
	env.glow_bloom = 0.08
	env.glow_hdr_threshold = 0.9
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	env.fog_light_color = p["nevoa"]
	env.fog_light_energy = 1.0
	env.fog_density = p["dens"]
	env.fog_sky_affect = 0.35
	env.fog_height = p["alt_nevoa"]
	env.fog_height_density = 0.12
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.08
	env.adjustment_saturation = 1.1
	var we := WorldEnvironment.new()
	we.name = "WorldEnvironment"
	we.environment = env
	pai.add_child(we)
	var lua := DirectionalLight3D.new()
	lua.name = "Lua"
	lua.light_color = p["lua"]
	lua.light_energy = p["energia"]
	lua.shadow_enabled = true
	lua.shadow_blur = 1.5
	lua.directional_shadow_max_distance = 60.0
	lua.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	lua.rotation = Vector3(deg_to_rad(-48), deg_to_rad(-28), 0)
	pai.add_child(lua)
	# luz de contorno (contra-luz magenta fraca, sem sombra) -- rim colorido
	var contra := DirectionalLight3D.new()
	contra.name = "Contraluz"
	contra.light_color = Color(0.85, 0.35, 0.8) if perfil_i != 3 else Color(0.4, 0.75, 1.0)
	contra.light_energy = 0.22
	contra.rotation = Vector3(deg_to_rad(-20), deg_to_rad(150), 0)
	pai.add_child(contra)
	return lua
