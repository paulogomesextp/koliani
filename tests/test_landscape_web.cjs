// Prova dos ramos de orientação sem fingir suporte de dispositivo real.
const fs = require('node:fs');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const head = fs.readFileSync('web/head_pwa.html', 'utf8');
const fonte = head.slice(head.indexOf('  var movel ='), head.lastIndexOf('})();'));
async function provar(agente, lock, esperado, ios = false) {
  const eventos = new Map();
  let chamadas = 0, fallback = false;
  const aviso = {classList:{toggle(k,v){fallback=v;}},setAttribute(){}};
  const contexto = {ios, navigator:{userAgent:agente}, innerHeight:900, innerWidth:400,
    screen:{orientation:lock ? {lock(valor){ assert.equal(valor,'landscape'); chamadas++; return lock(); }} : {}},
    window:{addEventListener(e,fn){eventos.set(e,fn);}},
    document:{getElementById(){return aviso;},addEventListener(){}}};
  vm.runInNewContext(fonte, contexto);
  await Promise.resolve();
  assert.equal(fallback, esperado);
  eventos.get('touchend')();
  await Promise.resolve();
  assert.equal(fallback, esperado);
  assert.equal(chamadas, lock && agente === 'Android' ? 2 : 0);
}
(async()=>{
  await provar('Android', ()=>Promise.resolve(), false);
  await provar('Android', ()=>Promise.reject(new Error('gesto/fullscreen exigido')), true);
  await provar('iPhone', null, true, true);
  await provar('Desktop', ()=>Promise.resolve(), false);
  console.log('PASS: landscape no arranque/gesto, recusa, Safari sem API, desktop intacto');
})();
