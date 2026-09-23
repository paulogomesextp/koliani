extends Node
## Regressão dos ficheiros aprovados: conteúdo e mapping do catálogo runtime.

const ESPERADOS := {
	"bau_abrir": ["chest_coin_drop.mp3", "AF8A9EC4D8B718703980C28B58C851AACF515DA9FC1E2D90AC592D1295D0EF76"],
	"transicao": ["level_complete_soft_landing.mp3", "944B9714D0AB60D390B07E3B8CF476FD3F818B3414EB35D89277484C5F09630A"],
	"selo": ["checkpoint_sword_cut.mp3", "70003AD6CFA77AA5D196CC5A22116150189723A395CDEECB645E4A231F4D7262"],
	"portal": ["portal_jump.mp3", "CCAE72774EE44C47C574E027FA99132A8D689FEF742C1C0C0675F1B1E9EF6541"],
	"desbloqueio": ["ability_unlock_stinger.mp3", "C45B33205B8D2FDA6827935787FEAC83FE34B24E1C98DA3D6727897A5AAB9E0B"],
	"apanhar": ["pickup_normal.mp3", "0F810918805CDC6E858193B5AB21845B7358FFBD61F4EE1BF38A86FDAE0C6973"],
	"apanhar_raro": ["pickup_rare.mp3", "8A2FA2FED13D979ECAB59F52B884DEB535CC818377E33ACBD183DBA07903E5F8"],
	"portao_abre": ["unlock_door.mp3", "38D70921F6C437752C414F6502544956CEA0AC245164B73BA97F67EA27C60D76"],
	"curar": ["heal_magic.mp3", "2285C7BE860FC2F563298E3CD930ACF24D0533DCEC528D4881CB3735C1D898FB"],
	"guardar": ["save_success.mp3", "F8065731BE76B83A80E930A6820AD5ACD1C667CD0F95F21A4C293C92584A41A2"],
	"respawn": ["respawn.mp3", "E5F6FF41544FD13F2D53610A8602516F0B62772705490698D3E36FB3960AC599"],
	"menu_painel": ["menu_panel.mp3", "652781E63832BA514A4DE67F0C7C5BF3F35B8CBA1CD5B47CD214A83A590B23A5"],
	"ui_confirmar": ["ui_confirm.mp3", "C2112CA664842E5BCB60CC93239998A1AADB507F82F9A4DDAF75F978D8469C7D"],
	"ui_mover": ["ui_hover.mp3", "5123D1AB02DDF38EA860606F783F31C241172DD6B551872C8531404DEAF5A49A"],
	"ui_voltar": ["ui_back.mp3", "C8477769BE097535C94DFB14F1D0F4B8E02271D0289766215E9EAAB1A08C6612"],
	"ui_negado": ["ui_error.mp3", "2754C5B2353B20D5573C17B2E5511FBBCF5DAD4B61BA6C60CAF6038C0612742E"],
}


func _ready() -> void:
	var falhas: Array[String] = []
	for evento: String in ESPERADOS:
		var caminho: String = Som.CAMINHOS.get(evento, "")
		var nome: String = ESPERADOS[evento][0]
		if caminho.get_file() != nome:
			falhas.append("%s aponta para %s" % [evento, caminho])
			continue
		var stream := load(caminho) as AudioStreamMP3
		if stream == null or stream.get_length() <= 0.0:
			falhas.append("stream invalido: " + caminho)
		if FileAccess.get_sha256(caminho).to_upper() != ESPERADOS[evento][1]:
			falhas.append("conteudo inesperado: " + caminho)
	for falha in falhas:
		printerr("APPROVED SFX FAIL: ", falha)
	print("APPROVED PROGRESSION SFX: %d falhas" % falhas.size())
	get_tree().quit(0 if falhas.is_empty() else 1)
