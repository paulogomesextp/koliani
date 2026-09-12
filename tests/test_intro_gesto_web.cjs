// Prova do gesto nativo: play síncrono, sem depender do input do Godot.
const { readFileSync } = require('node:fs');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const fonte = readFileSync('scripts/intro.gd', 'utf8').match(/const JS_INTRO := """([\s\S]*?)"""/)[1];
async function provar(rejeitar = false, tipo = 'touchend') {
  const eventos = new Map();
  let dentroGesto = false, chamadas = 0, removido = false, video;
  const janela = {
    addEventListener: (nome, fn) => eventos.set(nome, fn),
    removeEventListener: nome => eventos.delete(nome),
  };
  const contexto = {
    window: janela, location: { href: 'https://exemplo.test/koliani/?teste=1' }, URL, Date,
    document: {
      body: { appendChild() {} },
      createElement() {
        video = { style: {}, setAttribute() {}, addEventListener() {}, pause() {},
          remove() { removido = true; },
          play() { chamadas++;
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
  assert.equal(eventos.size, 0, 'eventos ficaram ativos no menu');
}
async function provarAutoplay() {
  let chamadas = 0;
  const eventos = new Map();
  const janela = {addEventListener:(e,f)=>eventos.set(e,f),removeEventListener:e=>eventos.delete(e)};
  const video = {style:{},setAttribute(){},addEventListener(){},pause(){},remove(){},
    play(){chamadas++;return Promise.resolve();}};
  vm.runInNewContext(fonte, {window:janela,location:{href:'https://exemplo.test/koliani/'},URL,Date,
    document:{body:{appendChild(){}},createElement(){return video;}}});
  await Promise.resolve();
  assert.equal(chamadas,1);
  assert.equal(janela.kolianiIntroEstado(),'a_tocar');
  janela.kolianiIntroSaltar();
  assert.equal(eventos.size,0);
}
(async () => {
  await provarAutoplay();
  await provar(); await provar(true); await provar(false, 'click'); await provar(false, 'keydown');
  console.log('PASS: toque, rato, teclado, URL, clique emulado, salto e erro');
})();
