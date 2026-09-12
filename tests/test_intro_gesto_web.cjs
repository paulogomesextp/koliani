// Provas DOM do startup: gesto, reprodução confirmada e saída independente do vídeo.
const {readFileSync}=require('node:fs');
const vm=require('node:vm');
const assert=require('node:assert/strict');
const fonte=readFileSync('scripts/intro.gd','utf8').match(/const JS_INTRO := """([\s\S]*?)"""/)[1];
function preparar(rejeitar=false){
  const eventos=new Map(), media=new Map();
  const canvas={style:{visibility:'visible'}}, splash={style:{visibility:'visible'}};
  let dentro=false,chamadas=0,audio=0,menus=0,parou=0,descarregou=0,video,skip;
  const janela={kolianiIntroTextoSkip:'SKIP TO MENU',
    kolianiAudioAcordar(){assert.ok(dentro);audio++;},kolianiIntroMenu(){menus++;},
    addEventListener(e,f){eventos.set(e,f);},removeEventListener(e){eventos.delete(e);}};
  const document={body:{appendChild(){}},getElementById(id){return id==='canvas'?canvas:splash;},
    createElement(tipo){
      if(tipo==='button'){skip={style:{},remove(){this.removido=true;}};return skip;}
      video={style:{},paused:true,currentTime:0,readyState:4,
        setAttribute(){},removeAttribute(){},load(){descarregou++;},
        addEventListener(e,f){media.set(e,f);},remove(){this.removido=true;},
        pause(){parou++;this.paused=true;media.get('pause')?.();},
        play(){assert.ok(dentro,'play fora do gesto');chamadas++;
          assert.equal(this.style.display,'block');assert.equal(canvas.style.visibility,'hidden');
          assert.equal(splash.style.visibility,'hidden');
          return rejeitar?Promise.reject(new Error('codec recusado')):Promise.resolve();}};
      return video;}};
  vm.runInNewContext(fonte,{window:janela,document,location:{href:'https://exemplo.test/koliani/?teste=1'},URL,Date});
  function gesto(tipo,alvo){dentro=true;eventos.get(tipo)?.({type:tipo,target:alvo,preventDefault(){},stopPropagation(){}});dentro=false;}
  return {janela,eventos,media,canvas,splash,gesto,get video(){return video;},get skip(){return skip;},
    contagens(){return {chamadas,audio,menus,parou,descarregou};}};
}
async function provar(rejeitar=false,tipo='touchend'){
  const t=preparar(rejeitar);
  assert.equal(t.contagens().chamadas,0,'autoplay indevido');assert.equal(t.skip.textContent,'SKIP TO MENU');
  t.gesto(tipo,{id:'canvas'});assert.equal(t.contagens().chamadas,1);assert.equal(t.contagens().audio,1);
  assert.equal(t.video.src,'https://exemplo.test/koliani/intro_koliani.mp4');
  assert.equal(t.video.playsInline,true);assert.equal(t.video.muted,false);
  if(rejeitar){await Promise.resolve();assert.equal(t.janela.kolianiIntroEstado(),'erro');}
  else{
    await Promise.resolve();assert.equal(t.janela.kolianiIntroEstado(),'a_tentar','Promise não prova vídeo a avançar');
    t.video.paused=false;t.media.get('playing')();
    t.video.currentTime=0.25;t.media.get('timeupdate')();
    assert.equal(t.janela.kolianiIntroDiag().currentTime,0.25);
    if(tipo==='touchend'){t.gesto('click',{id:'canvas'});assert.equal(t.janela.kolianiIntroEstado(),'a_tocar');}
    t.video.paused=true;t.media.get('pause')();assert.equal(t.janela.kolianiIntroEstado(),'pausado');
    t.gesto('keydown',{id:'canvas'});assert.equal(t.contagens().chamadas,2,'pausa não retomada no gesto');
    t.video.paused=false;t.media.get('playing')();t.media.get('ended')();
    assert.equal(t.janela.kolianiIntroEstado(),'fim');
  }
  assert.ok(t.video.removido);assert.ok(t.skip.removido);assert.equal(t.contagens().parou,1);
  assert.equal(t.contagens().descarregou,1);assert.equal(t.canvas.style.visibility,'visible');
  assert.equal(t.splash.style.visibility,'visible');assert.equal(t.eventos.size,0);
}
async function provarSkipBloqueado(){
  for(const iniciar of [false,true]){
    const t=preparar();if(iniciar)t.gesto('keydown',{id:'canvas'});
    t.gesto('touchend',t.skip);t.gesto('click',t.skip);t.janela.kolianiIntroSaltar(true);
    await Promise.resolve();assert.equal(t.contagens().menus,1,'menu carregado duas vezes');
    assert.equal(t.contagens().parou,iniciar?1:0);assert.equal(t.contagens().descarregou,iniciar?1:0);
    assert.ok(t.skip.removido);assert.equal(t.janela.kolianiIntroAtiva,false);
    assert.equal(t.eventos.size,0);assert.equal(t.canvas.style.visibility,'visible');
  }
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
  janela.kolianiIntroAtiva=true;
  gesto=true;janela.kolianiAudioAcordar();gesto=false;
  await Promise.resolve();
  assert.equal(retomadas,1,'primeiro gesto não resumiu o contexto');
  assert.equal(janela.kolianiAudioDiag().canalIOS,false,'HTML audio concorrente durante vídeo');
  janela.kolianiIntroAtiva=false;
  gesto=true;janela.kolianiAudioAcordar();gesto=false;
  await Promise.resolve();
  assert.equal(janela.kolianiAudioDiag().canalIOS,true);
}
(async () => {
  await provarAudioIntegrado();
  await provarSkipBloqueado();
  await provar(); await provar(true); await provar(false, 'click'); await provar(false, 'keydown');
  console.log('PASS: gesto, confirmação de reprodução, pausa, fim, skip bloqueado/duplo e áudio sem concorrência');
})();
