class_name ChefeLore
extends ChefeGenerico
## Bosses 51-100: identidade visual por sprite e padrao de arena por regiao.
@export var forma := "boss"
var _lore_t := 0.0
var _lore_cd := 0.0
var _lore_n := 0
func _ready() -> void:
	rig = _rig_da_forma()
	textura = null
	super._ready()


## Os bosses do segundo arco usam os mesmos cinco estados completos que a
## Koliani: repouso, marcha, ataque, dano e morte. A escolha é por silhueta
## e lore, não por recoloração de uma folha estática.
func _rig_da_forma() -> String:
	return {
		"boss_51_roseira_viva": "entrevane", "boss_52_jardineiro_perdido": "entrevane",
		"boss_53_alma_errante": "olho_voador", "boss_54_trepadeira": "serpente",
		"boss_55_rei_botanico": "entrevane", "boss_56_automato": "lamina_metal",
		"boss_57_foguista": "cavaleiro_fogo", "boss_58_homunculo": "mimico",
		"boss_59_bobina_viva": "voltaris", "boss_60_maquina_rei": "lamina_metal",
		"boss_61_guarda_nuvens": "aerion", "boss_62_servo_do_trovao": "voltaris",
		"boss_63_anjo_corrompido": "aerion", "boss_64_olho_lunar": "sacerdotisa_lunar",
		"boss_65_astronomo": "sacerdotisa_lunar", "boss_66_sonhador": "morvanna",
		"boss_67_reflexo": "cavaleiro_negro", "boss_68_boneca": "mimico",
		"boss_69_medo": "horror", "boss_70_outra_koliani": "cavaleiro_negro",
		"boss_71_colecionador": "rei_ossario", "boss_72_coveiro": "ceifeiro",
		"boss_73_santo_corrompido": "freira_negra", "boss_74_rei_morto": "rei_ossario",
		"boss_75_morte": "ceifeiro", "boss_76_afogado_vermelho": "rei_devorador",
		"boss_77_serpente_vermelha": "serpente", "boss_78_almirante_morto": "rei_devorador",
		"boss_79_tentaculo": "horror", "boss_80_o_mar": "demonio_lodo",
		"boss_81_sentinela_inferno": "cavaleiro_fogo", "boss_82_duque_infernal": "cavaleiro_fogo",
		"boss_83_barqueiro": "rei_devorador", "boss_84_princesa_demonio": "dama_guilhotina",
		"boss_85_rei_demonios": "cavaleiro_fogo", "boss_86_sombra": "cavaleiro_negro",
		"boss_87_nada": "olho_do_abismo", "boss_88_paradoxo": "irmaos_condenados",
		"boss_89_observador": "olho_do_abismo", "boss_90_entidade": "horror",
		"boss_91_general_caos": "colosso",
		# O "Dragao Primordial" usava o rig `vyrak`, e isso deixou de
		# fazer sentido quando o Vyrak foi refeito segundo a prancha
		# aprovada: era uma besta alada roxa e passou a ser um guardiao
		# HUMANOIDE de sinos ("A Voz dos Ecos"). O dragao do nivel 92
		# ficou, sem ninguem dar por isso, a aparecer como guardiao de
		# sinos. `serpente` e' o rig reptiliano que resta, e e' o que
		# ja' veste a Serpente Vermelha do 77.
		"boss_92_dragao_primordial": "serpente",
		"boss_93_ultimo_cavaleiro": "primeiro_prisioneiro", "boss_94_arauto_final": "arauto",
		"boss_95_campeao": "cavaleiro_fogo", "boss_96_zeriko_jovem": "cavaleiro_negro",
		"boss_97_primeiro_rei": "rei_ossario", "boss_98_zeriko_absoluto": "cavaleiro_fogo",
		"boss_99_entidade_purpura": "horror", "boss_100_zeriko_homem": "cavaleiro_negro",
	}.get(forma, "horror")
func _process(dt:float)->void:
	_lore_t+=dt; _lore_cd-=dt
	if _lore_cd<=0.0:
		_lore_cd=1.0+float(int(forma.hash())%9)/10.0; _lore_n+=1; _lore_attack()
	queue_redraw()
func _draw()->void:
	var col:=Color.from_hsv(float(abs(forma.hash())%360)/360.0,0.55,1.0)
	if fmod(_lore_t,1.3)<0.5: draw_arc(Vector2(0,42),44,PI,TAU,18,Color(col,0.35),2)
func _lore_attack()->void:
	var k:=get_tree().get_first_node_in_group("koliani"); if k==null:return
	var p:=get_parent(); if p==null:return
	var mode: int =abs(forma.hash())%4
	for i in (3 if mode==0 else 5 if mode==1 else 2 if mode==2 else 6):
		var pos:=global_position+Vector2((i-2)*34.0,-20.0 if mode==1 else 24.0)
		var vel:Vector2
		if mode==0: vel=Vector2(_dir_para_koliani()*260.0,(i-1)*42.0)
		elif mode==1: vel=Vector2(0,260.0)
		elif mode==2: vel=Vector2(_dir_para_koliani()*360.0,0)
		else: vel=(k.global_position-global_position).normalized()*250.0
		_projectile(p,pos,vel)
func _projectile(p:Node,pos:Vector2,vel:Vector2)->void:
	var a:=Area2D.new(); a.collision_layer=0; a.collision_mask=2; a.global_position=pos; p.add_child(a)
	var cs:=CollisionShape2D.new(); var sh:=CircleShape2D.new(); sh.radius=10; cs.shape=sh; a.add_child(cs)
	var q:=Polygon2D.new(); q.polygon=PackedVector2Array([Vector2(0,-12),Vector2(9,0),Vector2(0,12),Vector2(-9,0)]); q.color=Color.from_hsv(float(abs(forma.hash())%360)/360.0,0.5,1); a.add_child(q)
	a.body_entered.connect(func(b:Node)->void: if b.is_in_group("koliani"): b.receber_dano(18,0.0); a.queue_free())
	var tw:=a.create_tween(); tw.tween_property(a,"global_position",pos+vel,1.0); tw.tween_callback(a.queue_free)
