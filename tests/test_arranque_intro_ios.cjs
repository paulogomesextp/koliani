// Provas da sequência real do shell: preparar -> vídeo -> start, sem Godot concorrente.
const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict');
const shell=fs.readFileSync('web/shell_intro.html','utf8');
const script=shell.match(/<script>(\/\* 9H\.6:[\s\S]*?)<\/script>/)[1];
async function provar(tipo,ios=true,recusar=false){
  const ordem=[],eventos=new Map();let video,skip,modal,pausas=0,loads=0,gesto=false,timer;
  const canvas={style:{pointerEvents:'auto',visibility:'visible'}},status={style:{visibility:'visible'}};
  const rodar={style:{},parentNode:{appendChild(){ordem.push('rodar-restaurado');}}};
  function no(tag){return {tagName:tag.toUpperCase(),style:{},filhos:[],
    appendChild(n){this.filhos.push(n);},contains(n){return this.filhos.includes(n);},setAttribute(){},
    removeAttribute(){},remove(){this.removido=true;},addEventListener(e,f){this.eventos ||= {};this.eventos[e]=f;}};}
  const doc={body:no('body'),querySelector(){return no('span');},
    getElementById(id){return id==='canvas'?canvas:id==='status'?status:id==='rodar'?rodar:null;},
    createElement(tag){const n=no(tag);
      if(tag==='dialog'){modal=n;n.showModal=()=>{n.topLayer=true;};n.close=()=>{};}
      if(tag==='button')skip=n;
      if(tag==='video'){video=n;Object.assign(n,{paused:true,currentTime:0,readyState:3,
        pause(){pausas++;this.paused=true;},load(){loads++;},play(){assert.ok(gesto);ordem.push('play');
          this.paused=false;return recusar?Promise.reject(Object.assign(new Error('negado'),{name:'NotAllowedError'})):Promise.resolve();}});}
      return n;}};
  const janela={addEventListener(e,f){eventos.set(e,f);},removeEventListener(e){eventos.delete(e);}};
  const engine={config:{update(){ordem.push('config');}},
    init(){ordem.push('init');return Promise.resolve();},preloadFile(){ordem.push('pack');return Promise.resolve();},
    start(o){assert.equal(janela.kolianiIntroPreviaConcluida,true);assert.ok(video?.removido || tipo==='skip-idle');
      assert.ok(modal.removido);assert.equal(canvas.style.pointerEvents,'auto');ordem.push('start');
      assert.deepEqual(Array.from(o.args),['--main-pack','index.pck']);return Promise.resolve();},
    startGame(){ordem.push('desktop');return Promise.resolve();}};
  vm.runInNewContext(script,{window:janela,document:doc,navigator:{userAgent:ios?'iPhone':'desktop',platform:'',maxTouchPoints:0},
    localStorage:{getItem(){return 'pt';}},location:{href:'https://exemplo.test/koliani/'},URL,Date,console,
    setTimeout(f,ms){assert.equal(ms,26000);timer=f;}});
  const concluido=janela.kolianiArranqueIntro(engine,{executable:'index',args:[]},{});
  await new Promise(resolve=>setImmediate(resolve));
  if(!ios){await concluido;assert.deepEqual(ordem,['desktop']);return;}
  assert.ok(modal.topLayer);assert.equal(canvas.style.pointerEvents,'none');assert.ok(!ordem.includes('start'));
  function tocar(ev,alvo){gesto=true;eventos.get(ev)?.({type:ev,target:alvo,preventDefault(){},stopPropagation(){}});gesto=false;}
  if(tipo==='skip-idle')tocar('touchstart',skip);
  else{
    tocar('touchend',modal);await Promise.resolve();
    assert.equal(video.src,'https://exemplo.test/koliani/intro_koliani.mp4');
    assert.equal(video.muted,false);assert.equal(video.playsInline,true);
    assert.ok(!ordem.includes('start'),'main loop iniciou durante vídeo');
    if(recusar){assert.equal(janela.kolianiIntroEstado(),'idle');tocar('pointerdown',skip);}
    else if(tipo==='ended'){video.currentTime=10;video.eventos.ended();}
    else tocar(tipo,skip);
  }
  await concluido;assert.equal(ordem.at(-1),'start');assert.ok(skip.removido);
  assert.equal(pausas,tipo==='skip-idle'?0:1);assert.equal(loads,tipo==='skip-idle'?0:1);
  timer?.();assert.equal(ordem.filter(x=>x==='start').length,1);
}
(async()=>{for(const e of ['touchstart','pointerdown','click','ended','skip-idle'])await provar(e);
  await provar('touchstart',true,true);await provar('desktop',false);
  assert.ok(!shell.includes('koliani-ios-debug'));assert.ok(!shell.includes('$KOLIANI_INTRO'));
  console.log('PASS: iOS prepara sem main loop, MP4 A/V único, top layer, Skip imediato/duplo, fim, recusa, desktop preservado');})();
