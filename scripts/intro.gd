extends Control
## INTRO EM VÍDEO (Execution 9H). É a `main_scene` do projeto: o jogo
## arranca aqui, toca o vídeo aprovado
## (`10_menu_rebrand/05_intro_video_approved`, convertido para Ogg Theora
## por ser o único formato que o `VideoStreamPlayer` do Godot lê) e passa
## ao menu.
##
## TRÊS COISAS QUE TÊM DE SER VERDADE, E PORQUÊ:
##
##  1. **O arranque nunca pode ficar preso aqui.** Se o ficheiro não estiver
##     importado, se o descodificador falhar, ou se o vídeo simplesmente não
##     começar a andar, `_desistir()` leva ao menu. O relógio de segurança
##     (`ESPERA_ARRANQUE`) é o que apanha o caso mau de verdade -- o vídeo
##     que diz que está a tocar e não avança um único frame.
##  2. No browser, o primeiro gesto DOM inicia vídeo, áudio e orientação.
##  3. **Salta-se sempre.** Qualquer tecla, botão do rato ou toque salta.
##     Ninguém quer ver a mesma abertura à décima vez.
##
## Os atalhos de dev (`--nivel=`, `--foto…`, `--jogar`, `--devmode`) e as
## provas de runtime passam ao lado da intro: quem os usa quer o jogo, não
## a abertura.

const CENA_MENU := "res://scenes/ui/MenuInicial.tscn"
const VIDEO := "res://assets/video/intro_koliani.ogv"
## No Web o vídeo é um `<video>` do DOM, servido ao lado do `index.html`
## (ver `web/README.md`). O caminho é relativo: a PWA pode estar em
## qualquer subpasta.
const VIDEO_WEB := "intro_koliani.mp4"

## Quanto tempo se espera até decidir que o vídeo não arrancou.
const ESPERA_ARRANQUE := 1.6
## Teto absoluto (o vídeo aprovado tem 10 s; a folga é para o Web lento).
const TETO := 26.0

var _video: VideoStreamPlayer
var _cartao: Control
var _saltar: Label
var _acabou := false
var _a_tocar := false
var _skip_web: JavaScriptObject


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# O clique TEM de chegar ao `_unhandled_input`. Um `Control` nasce com
	# `MOUSE_FILTER_STOP` e come o evento: no Web, o cartão "TOCAR PARA
	# JOGAR" ficava a piscar e o toque não fazia nada -- visto no Chrome
	# real com o build 0.17.0. No PC nunca se via, porque lá não há cartão.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _saltar_intro():
		_ir_menu(true)
		return

	var fundo := ColorRect.new()
	fundo.color = Color(0.02, 0.01, 0.02)
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fundo)

	_video = VideoStreamPlayer.new()
	_video.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_video.expand = true
	_video.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_video.autoplay = false
	_video.finished.connect(_ao_fim)
	add_child(_video)

	_saltar = Label.new()
	_saltar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_saltar.offset_top = -60.0
	_saltar.offset_bottom = -24.0
	_saltar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_saltar.modulate.a = 0.0
	_saltar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Frontend9H.capitular(_saltar, 13, Frontend9H.TEXTO_APAGADO)
	_saltar.text = Frontend9H.espacar(Textos.t("menu.press_enter"), 1)
	add_child(_saltar)

	# No Web o vídeo é do DOM (ver `_intro_web`): não se carrega o Theora,
	# que lá só ocuparia memória e nunca seria descodificado.
	if not OS.has_feature("web"):
		if ResourceLoader.exists(VIDEO):
			var fluxo := load(VIDEO)
			if fluxo is VideoStream:
				_video.stream = fluxo
		if _video.stream == null:
			push_warning("INTRO 9H: sem vídeo importado -- a saltar para o menu")
			_ir_menu(true)
			return

	# No Web o áudio só acorda com um gesto do utilizador; num telemóvel a
	# regra é a mesma. Sem cartão, a intro seria muda.
	if OS.has_feature("web") or DisplayServer.is_touchscreen_available():
		_mostrar_cartao()
		if OS.has_feature("web"):
			_intro_web()
	else:
		_arrancar()

	if not OS.has_feature("web"):
		get_tree().create_timer(TETO).timeout.connect(func() -> void:
			if not _acabou:
				_ao_fim())
	_prova_intro()


## Cartão mínimo de gesto: logótipo + "TOCAR PARA JOGAR".
func _mostrar_cartao() -> void:
	_cartao = Control.new()
	_cartao.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cartao.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_cartao)
	var logo := TextureRect.new()
	logo.texture = load("res://assets/branding/icone_9h_512.png") if \
		ResourceLoader.exists("res://assets/branding/icone_9h_512.png") else null
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	logo.offset_left = -150.0
	logo.offset_top = -180.0
	logo.offset_right = 150.0
	logo.offset_bottom = 120.0
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	logo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_cartao.add_child(logo)
	var l := Label.new()
	Frontend9H.capitular(l, 20, Frontend9H.OSSO)
	l.text = Frontend9H.espacar(Textos.t("menu.tap_play"), 1)
	l.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	l.offset_left = -400.0
	l.offset_right = 400.0
	l.offset_top = 150.0
	l.offset_bottom = 190.0
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cartao.add_child(l)
	var t := create_tween().set_loops()
	t.tween_property(l, "modulate:a", 0.42, 1.1).set_trans(Tween.TRANS_SINE)
	t.tween_property(l, "modulate:a", 1.0, 1.1).set_trans(Tween.TRANS_SINE)


## NO WEB O VÍDEO NÃO É DO GODOT. O export Web é single-threaded e
## descodificar Theora em wasm bloqueia a thread principal: com a intro a
## tocar, a página deixava de responder (medido -- nem um `screenshot` nem
## um `eval` voltavam). Um `<video>` do DOM é descodificado pelo browser,
## por hardware, sem tocar na thread do jogo; toca com som porque já houve o
## gesto do cartão; e se falhar (ficheiro em falta, codec recusado) o estado
## vem "erro" e vai-se para o menu na mesma.
const JS_INTRO := """
window.kolianiIntro = (function(){
  var estado = 'idle', v = null, ultimoToque = -Infinity, fechado = false;
  window.kolianiIntroAtiva = true;
  // Diagnóstico temporário 9H.5D: observação, sem consumir gestos.
  var ultimoEvento = 'NONE', promessa = 'NOT ATTEMPTED';
  var eventoSkip = 'NONE', hit = 'NONE', transicao = 'NOT ATTEMPTED';
  var amostra = {readyState:0, networkState:0, paused:true, ended:false,
    currentTime:0, duration:NaN, videoWidth:0, videoHeight:0};
  var painel = document.createElement('pre');
  painel.id = 'koliani-ios-debug';
  painel.style.cssText = 'position:fixed;left:max(8px,env(safe-area-inset-left));' +
    'top:max(8px,env(safe-area-inset-top));z-index:23;pointer-events:none;' +
    'margin:0;padding:6px;background:rgba(0,0,0,.78);color:#fff;' +
    'font:11px/1.25 monospace;max-width:75vw;white-space:pre-wrap';
  document.body.appendChild(painel);
  var pintarDebug = function(){
    if (v && !fechado) amostra = {readyState:v.readyState, networkState:v.networkState,
      paused:v.paused, ended:v.ended, currentTime:v.currentTime, duration:v.duration,
      videoWidth:v.videoWidth, videoHeight:v.videoHeight};
    var nl = String.fromCharCode(10);
    painel.textContent = 'DEBUG 9H.5D' + nl + 'VIDEO' + nl + 'readyState: ' + amostra.readyState +
      ' | networkState: ' + amostra.networkState + nl + 'paused: ' + amostra.paused +
      ' | ended: ' + amostra.ended + nl + 'currentTime / duration: ' +
      amostra.currentTime + ' / ' + amostra.duration + nl + 'videoWidth x videoHeight: ' +
      amostra.videoWidth + ' x ' + amostra.videoHeight + nl + 'LAST EVENT: ' + ultimoEvento +
      nl + 'play() promise: ' + promessa + nl + 'SKIP EVENT: ' + eventoSkip +
      nl + 'HIT ELEMENT: ' + hit + nl + 'MENU TRANSITION: ' + transicao;
  };
  window.kolianiIntroMenuResultado = function(passou){
    transicao = passou ? 'PASS' : 'FAIL'; pintarDebug();
  };
  window.kolianiIntroMenuTentativa = function(){
    // FAIL significa que o menu não confirmou chegada em 5 s; uma chegada tardia dá PASS.
    setTimeout(function(){ if (transicao !== 'PASS') window.kolianiIntroMenuResultado(false); }, 5000);
  };
  var observarToque = function(e){
    var ponto = e.touches && e.touches[0] || e;
    var el = document.elementFromPoint(ponto.clientX, ponto.clientY);
    hit = el ? '<' + el.tagName.toLowerCase() + (el.id ? '#' + el.id : '') + '>' : 'NONE';
    eventoSkip = e.type.toUpperCase(); pintarDebug();
  };
  var eventosDebug = ['pointerdown', 'touchstart', 'click'];
  eventosDebug.forEach(function(e){ window.addEventListener(e, observarToque, {capture:true, passive:true}); });
  pintarDebug();
  var relogioDebug = setInterval(pintarDebug, 500);
  var skip = document.createElement('button');
  skip.id = 'koliani-intro-skip'; skip.type = 'button';
  skip.textContent = window.kolianiIntroTextoSkip;
  skip.style.cssText = 'position:fixed;right:max(16px,env(safe-area-inset-right));' +
    'bottom:max(16px,env(safe-area-inset-bottom));z-index:22;display:block;' +
    'padding:12px 18px;color:#ece6f7;background:#0d0814;border:1px solid #ff5fd4;' +
    'border-radius:8px;font:600 16px system-ui;touch-action:manipulation';
  document.body.appendChild(skip);
  var cobertos = [];
  var mostrarVideo = function(){
    v.style.display = 'block';
    if (!cobertos.length) ['canvas', 'status'].forEach(function(id){
      var el = document.getElementById(id);
      if (el){ cobertos.push([el, el.style.visibility]); el.style.visibility = 'hidden'; }
    });
  };
  var restaurar = function(){
    cobertos.forEach(function(par){ par[0].style.visibility = par[1]; });
    cobertos = [];
  };
  var eventos = ['touchend', 'click', 'keydown'];
  var gesto = function(e){
	if (fechado) return;
	if (e.target === skip || e.target.closest?.('#koliani-intro-skip')){
      e.preventDefault(); e.stopPropagation(); window.kolianiIntroSaltar(true); return;
    }
	if (e.repeat || (e.type !== 'keydown' && e.target.id !== 'canvas' && e.target !== v && !e.target.closest?.('#rodar'))) return;
	if (e.type === 'click' && Date.now() - ultimoToque < 600) return;
	if (e.type === 'touchend') ultimoToque = Date.now();
	e.preventDefault();
	e.stopPropagation();
	if (estado === 'idle' || estado === 'pausado'){
      if (window.kolianiAudioAcordar) window.kolianiAudioAcordar();
      window.kolianiIntroTocar(new URL('intro_koliani.mp4', location.href).href);
    }
	else if (estado === 'a_tocar') window.kolianiIntroSaltar();
  };
  eventos.forEach(function(e){ window.addEventListener(e, gesto, {capture:true, passive:false}); });
  window.kolianiIntroTocar = function(url){
	if (fechado || (estado !== 'idle' && estado !== 'pausado')) return;
	estado = 'a_tentar';
	try{
	  if (!v){
	  v = document.createElement('video');
	  v.src = url; v.setAttribute('playsinline',''); v.setAttribute('webkit-playsinline','');
      v.playsInline = true; v.preload = 'auto';
      v.autoplay = false; v.muted = false; v.loop = false;
	  v.style.cssText = 'position:fixed;inset:0;width:100%;height:100%;' +
		'object-fit:contain;background:#0b0509;z-index:20;visibility:visible;opacity:1';
      ['loadedmetadata','canplay','playing','timeupdate','pause','waiting','stalled','error','ended'].forEach(function(ev){
        v.addEventListener(ev, function(){ if (!fechado){ ultimoEvento = ev; pintarDebug(); } });
      });
	  v.addEventListener('ended', function(){ window.kolianiIntroSaltar(); });
	  v.addEventListener('error', function(){ estado = 'erro'; window.kolianiIntroSaltar(); });
      v.addEventListener('playing', function(){ if (!fechado) estado = 'a_tocar'; });
      v.addEventListener('pause', function(){ if (!fechado) estado = 'pausado'; });
      v.addEventListener('timeupdate', function(){
        if (!fechado && !v.paused && v.currentTime > 0) estado = 'a_tocar';
      });
	  document.body.appendChild(v);
	  }
	  // WebKit: visível antes de play(), sempre dentro do gesto permitido.
      mostrarVideo();
      var p = v.play();
      promessa = 'PENDING'; pintarDebug();
      if (p && p.then) p.then(function(){ promessa = 'resolved'; pintarDebug(); }, function(e){
        promessa = 'rejected: ' + (e && e.name || 'Error') + ': ' + (e && e.message || ''); pintarDebug();
      });
	  if (p && p.catch) p.catch(function(e){
        if (fechado) return;
		if (e && e.name === 'NotAllowedError'){
          estado = 'idle'; v.style.display = 'none'; restaurar();
		  return;
		}
		estado = 'erro'; window.kolianiIntroSaltar();
	  });

	}catch(e){ promessa = 'rejected: ' + e.name + ': ' + e.message; pintarDebug(); estado = 'erro'; window.kolianiIntroSaltar(); }
  };
  window.kolianiIntroSaltar = function(imediato){
    if (fechado) return;
    pintarDebug();
    fechado = true; window.kolianiIntroAtiva = false;
    clearInterval(relogioDebug);
    eventosDebug.forEach(function(e){ window.removeEventListener(e, observarToque, true); });
	if (estado !== 'erro') estado = 'fim';
	eventos.forEach(function(e){ window.removeEventListener(e, gesto, true); });
	try{ if (v){ v.pause(); v.removeAttribute('src'); v.load(); v.remove(); v = null; } }catch(e){}
    skip.remove();
    restaurar();
    if (imediato && window.kolianiIntroMenu) window.kolianiIntroMenu();
  };
  window.kolianiIntroEstado = function(){ return estado; };
  window.kolianiIntroDiag = function(){ return {
    estado:estado, currentTime:v ? v.currentTime : 0,
    paused:v ? v.paused : true, readyState:v ? v.readyState : 0
  }; };
  return true;
})();
"""


## Arma o gesto DOM antes do toque. O Safari exige play() dentro do evento,
## não num frame posterior de input do Godot. Este ciclo só observa o estado.
func _intro_web() -> void:
	_skip_web = JavaScriptBridge.create_callback(func(_args: Array) -> void: _ao_fim(true))
	var janela := JavaScriptBridge.get_interface("window")
	janela.kolianiIntroMenu = _skip_web
	JavaScriptBridge.eval("window.kolianiIntroTextoSkip = %s" %
		JSON.stringify(Textos.t("menu.skip_to_menu")), true)
	JavaScriptBridge.eval("document.querySelector('#rodar span').textContent = %s" %
		JSON.stringify(Textos.t("menu.rotate_device")), true)
	JavaScriptBridge.eval(JS_INTRO, true)
	var fim := 0
	while not _acabou:
		await get_tree().create_timer(0.2).timeout
		if _acabou:
			return
		var e := str(JavaScriptBridge.eval("window.kolianiIntroEstado()", true))
		if e == "a_tocar" and not _a_tocar:
			_a_tocar = true
			fim = Time.get_ticks_msec() + int(TETO * 1000.0)
			if _cartao:
				_cartao.queue_free()
				_cartao = null
		if e == "fim" or e == "erro":
			if e == "erro":
				push_warning("INTRO 9H: o <video> do browser não tocou -- a saltar")
			break
		if fim > 0 and Time.get_ticks_msec() >= fim:
			push_warning("INTRO 9H.4: reprodução excedeu o teto; diagnóstico %s" %
				str(JavaScriptBridge.eval("JSON.stringify(window.kolianiIntroDiag())", true)))
			break
	JavaScriptBridge.eval("window.kolianiIntroSaltar()", true)
	_ao_fim()


func _arrancar() -> void:
	if _cartao:
		_cartao.queue_free()
		_cartao = null
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.kolianiIntroTocar(new URL('%s', location.href).href)" % VIDEO_WEB, true)
		return
	_video.play()
	_a_tocar = true
	var t := create_tween()
	t.tween_interval(1.2)
	t.tween_property(_saltar, "modulate:a", 0.85, 0.5)
	# Relógio de segurança: o `VideoStreamPlayer` pode aceitar o `play()` e
	# nunca avançar (descodificador em falta no export). Mede-se a POSIÇÃO,
	# não o `is_playing()` -- foi o `is_playing()` a dizer que sim com o
	# vídeo parado que motivou este relógio.
	await get_tree().create_timer(ESPERA_ARRANQUE).timeout
	if not _acabou and _video.stream_position <= 0.02:
		push_warning("INTRO 9H: o vídeo não avançou em %.1fs -- a saltar" % ESPERA_ARRANQUE)
		_ao_fim()


func _unhandled_input(evento: InputEvent) -> void:
	if _acabou:
		return
	# No Web, toque/rato/tecla pertencem ao DOM. O evento emulado pelo
	# Godot não pode saltar o vídeo que esse mesmo toque acabou de iniciar.
	if OS.has_feature("web") and not evento is InputEventJoypadButton:
		return
	var gesto := false
	if evento is InputEventKey:
		gesto = (evento as InputEventKey).pressed and not (evento as InputEventKey).echo
	elif evento is InputEventMouseButton:
		gesto = (evento as InputEventMouseButton).pressed
	elif evento is InputEventScreenTouch:
		gesto = (evento as InputEventScreenTouch).pressed
	elif evento is InputEventJoypadButton:
		gesto = (evento as InputEventJoypadButton).pressed
	if not gesto:
		return
	get_viewport().set_input_as_handled()
	if not _a_tocar:
		_arrancar()
	else:
		_ao_fim()


func _ao_fim(imediato: bool = false) -> void:
	if _acabou:
		return
	_acabou = true
	if _video and _video.is_playing():
		_video.stop()
	if OS.has_feature("web"):
		JavaScriptBridge.eval("if(window.kolianiIntroSaltar)window.kolianiIntroSaltar()", true)
	_ir_menu(imediato)


func _ir_menu(imediato: bool) -> void:
	# Observa a tentativa; o menu confirma a chegada após montar a UI.
	if OS.has_feature("web"):
		JavaScriptBridge.eval("if(window.kolianiIntroMenuTentativa)window.kolianiIntroMenuTentativa()", true)
	if imediato:
		get_tree().change_scene_to_file.call_deferred(CENA_MENU)
		return
	Transicao.fechar_e(func() -> void: get_tree().change_scene_to_file(CENA_MENU))


## A intro não se mete no caminho de quem pediu o jogo por linha de comando.
## A exceção é o `--foto-intro=`, que é precisamente para a fotografar.
func _saltar_intro() -> bool:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--foto-intro="):
			return false
	for a in OS.get_cmdline_user_args():
		if a == "--sem-intro" or a == "--jogar" or a == "--devmode" \
				or a.begins_with("--nivel=") or a.begins_with("--foto"):
			return true
	return false


## Prova da intro no EXE / no browser: `--foto-intro=<png>@<segundos>`
## arranca o vídeo sem esperar gesto e fotografa o ecrã ao fim desse tempo,
## imprimindo a POSIÇÃO do stream -- é a posição que prova que o vídeo anda
## mesmo (o `is_playing()` diz que sim com o vídeo parado; foi por isso que
## o relógio de segurança mede a posição e não o estado).
func _prova_intro() -> void:
	for a in OS.get_cmdline_user_args():
		if not a.begins_with("--foto-intro="):
			continue
		var valor := a.get_slice("=", 1)
		var caminho := valor
		var quando := 3.0
		if "@" in valor:
			caminho = valor.get_slice("@", 0)
			quando = float(valor.get_slice("@", 1))
		_arrancar()
		await get_tree().create_timer(quando).timeout
		var img := get_viewport().get_texture().get_image()
		img.save_png(caminho)
		print("PROVA RUNTIME INTRO: %s | pos=%.2fs | a_tocar=%s"
			% [caminho, _video.stream_position, str(_video.is_playing())])
		get_tree().quit(0)
		return
