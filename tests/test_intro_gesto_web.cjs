// Prova do gesto nativo: play síncrono, sem depender do input do Godot.
const { readFileSync } = require('node:fs');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const fonte = readFileSync('scripts/intro.gd', 'utf8').match(/const JS_INTRO := """([\s\S]*?)"""/)[1];
async function provar(rejeitar = false, tipo = 'touchend') {
  const eventos = new Map();
  let dentroGesto = false, chamadas = 0, removido = false, video, audio = 0;
  const canvas = {style:{visibility:'visible'}}, splash = {style:{visibility:'visible'}};
  const janela = {
    kolianiAudioAcordar(){assert.ok(dentroGesto);audio++;},
    addEventListener: (nome, fn) => eventos.set(nome, fn),
    removeEventListener: nome => eventos.delete(nome),
  };
  const contexto = {
    window: janela, location: { href: 'https://exemplo.test/koliani/?teste=1' }, URL, Date,
    document: {
      body: { appendChild() {} },
      getElementById(id){return id === 'canvas' ? canvas : splash;},
      createElement() {
        video = { style: {}, setAttribute() {}, addEventListener() {}, pause() {},
          remove() { removido = true; },
          play() { chamadas++;
            assert.equal(video.style.display, 'block', 'vídeo oculto no play');
            assert.equal(canvas.style.visibility, 'hidden');
            assert.equal(splash.style.visibility, 'hidden');
            if (!dentroGesto) return Promise.reject(Object.assign(new Error('gesto exigido'), {name:'NotAllowedError'}));
            assert.ok(dentroGesto, 'play perdeu o gesto');
            return rejeitar ? Promise.reject(new Error('codec recusado')) : Promise.resolve(); },
        };
        return video;
      },
    },
  };
  vm.runInNewContext(fonte, contexto);
  assert.equal(chamadas, 1, 'não tentou autoplay');
  await Promise.resolve();
  assert.equal(janela.kolianiIntroEstado(), 'idle', 'recusa de autoplay perdeu o cartão');
  function gesto(tipo, alvo) {
    dentroGesto = true;
    eventos.get(tipo)?.({ type: tipo, target: alvo, preventDefault() {}, stopPropagation() {} });
    dentroGesto = false;
  }
  gesto(tipo, { id: 'canvas' });
  assert.equal(chamadas, 2);
  assert.equal(audio, 1, 'áudio não partilhou o primeiro gesto');
  assert.equal(video.src, 'https://exemplo.test/koliani/intro_koliani.mp4');
  if (rejeitar) {
    await Promise.resolve();
    assert.equal(janela.kolianiIntroEstado(), 'erro');
  } else {
    if (tipo === 'touchend') {
      gesto('click', { id: 'canvas' });
      assert.equal(janela.kolianiIntroEstado(), 'a_tocar', 'clique emulado saltou a intro');
    }
    gesto('keydown', { id: 'canvas' });
    assert.equal(janela.kolianiIntroEstado(), 'fim');
  }
  assert.ok(removido);
  assert.equal(canvas.style.visibility, 'visible');
  assert.equal(splash.style.visibility, 'visible');
  assert.equal(eventos.size, 0, 'eventos ficaram ativos no menu');
}
async function provarAutoplay() {
  let chamadas = 0;
  const eventos = new Map();
  const janela = {
    kolianiAudioAcordar(){assert.ok(dentroGesto);audio++;},addEventListener:(e,f)=>eventos.set(e,f),removeEventListener:e=>eventos.delete(e)};
  const video = {style:{},setAttribute(){},addEventListener(){},pause(){},remove(){},
    play(){chamadas++;return Promise.resolve();}};
  vm.runInNewContext(fonte, {window:janela,location:{href:'https://exemplo.test/koliani/'},URL,Date,
    document:{body:{appendChild(){}},getElementById(){return null;},createElement(){return video;}}});
  await Promise.resolve();
  assert.equal(chamadas,1);
  assert.equal(janela.kolianiIntroEstado(),'a_tocar');
  janela.kolianiIntroSaltar();
  assert.equal(eventos.size,0);
}
async function provarAudioIntegrado() {
  const head = readFileSync('web/head_pwa.html', 'utf8');
  const eventos = new Map();
  let gesto = false, retomadas = 0, botoes = 0;
  class AudioContext {
    constructor(){this.state='suspended';this.currentTime=0;this.destination={};}
    resume(){assert.ok(gesto);retomadas++;this.state='running';return Promise.resolve();}
    createOscillator(){return {connect(){},start(){},stop(){}};}
    createGain(){return {gain:{},connect(){}};}
  }
  const janela = {AudioContext,btoa(s){return Buffer.from(s,'binary').toString('base64');},addEventListener(e,f){eventos.set(e,f);}};
  const documento = {body:{appendChild(){}},addEventListener(){},getElementById(){return null;},
    createElement(tipo){if(tipo==='button')botoes++;return {setAttribute(){},load(){},play(){assert.ok(gesto);return Promise.resolve();}};}};
  vm.runInNewContext(head.match(/<script>([\s\S]*?)<\/script>/)[1],
    {window:janela,document:documento,navigator:{userAgent:'iPhone',platform:'iPhone',maxTouchPoints:1},
     location:{search:''},screen:{},innerHeight:400,innerWidth:800,setTimeout(){},setInterval(){},Proxy,Date});
  new janela.AudioContext();
  assert.equal(botoes,0,'fluxo normal criou botão extra de áudio');
  gesto=true;janela.kolianiAudioAcordar();gesto=false;
  await Promise.resolve();
  assert.equal(retomadas,1,'primeiro gesto não resumiu o contexto');
  assert.equal(janela.kolianiAudioDiag().canalIOS,true);
}
(async () => {
  await provarAudioIntegrado();
  await provarAutoplay();
  await provar(); await provar(true); await provar(false, 'click'); await provar(false, 'keydown');
  console.log('PASS: toque, rato, teclado, URL, clique emulado, salto e erro');
})();
