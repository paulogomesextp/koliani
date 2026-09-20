> **À espera do Paulo (SFX, 20 set 2026)** — o SFX Overhaul fechou a fase
> automática (`READY_FOR_HUMAN_TEST`). Duas coisas dependem de ti:
> 1. **Playtest de som** — checklist e percurso de 10–15 min em
>    `docs/audio/HUMAN_SFX_PLAYTEST.md`; build em
>    `build/qa/Koliani-SFX-QA.exe`.
> 2. **Decidir o `esmagar.ogg`** — distorce (+7,3 dBFS, 16 callsites), mas
>    corrigi-lo custa 1,4 dB do peso do som. Se distorcer ao ouvido:
>    `python tools/corrigir_clipping_p4.py --forcar esmagar.ogg`.
>
> Por confirmar também: **áudio do Web** (arranca, mas não consegui provar
> que sai som) e as **13 sobras de formato** em `assets/audio/` (143 KB de
> `.ogg`/`.mp3` que nada toca — apagar ou deixar?).

## RESOLVIDO — Região III, dano colateral das mecânicas (20 set 2026)

Estava aqui: dar à Torre dos Ecos as mecânicas do cânone reescrevia doze
níveis de outras regiões. **O Paulo decidiu: as mecânicas ficam, o dano
colateral não, e a solução tem de ser arquitetural.** Foi feito.

A `MECANICA_DO_NIVEL` fazia três coisas ao mesmo tempo, e só se percebeu
isso a medir:

1. dizia que mecânica cada nível **apresenta**;
2. por ser a primeira ocorrência, decidia quando cada câmara **desbloqueia
   em todas as regiões** — e o gerador duplica o peso dela nos 8 níveis
   seguintes;
3. o `cam` de cada linha é também a **câmara-assinatura que o gerador força
   na jornada desse nível**, e o `grau` diz quantas vezes.

Separou-se (1) de (2) com `DESBLOQUEIO_BASE` (calendário global congelado)
mais `DESBLOQUEIO_REGIAO` (antecipação local à Região III). Para (3), os
slots fora da Região III voltaram exactamente ao que eram.

Fica **uma** consequência, pequena e nomeada: `serras` e `gravidade` já não
têm nível onde sejam *apresentadas* (os slots delas eram o "Observatório
Lunar" e a "Torre da Tempestade", que o cânone renomeou). Continuam a
aparecer no jogo, no mesmo calendário de sempre; perderam o aviso de
estreia. E o `elevador` é agora assinatura do N12 e do N16 — quem joga
conhece-o no N12 e o N16 não o reapresenta, que é o comportamento certo.

## Pendente de DECISÃO — Região III, Torre dos Ecos (19 set 2026)

Branch `claude/region03-completion-pass` (**PARTIAL, não integrada**).
Relatório: `docs/implementation/region_03_completion_pass.md`.

A identidade da região está feita e testada: nomes canónicos, um só chefe,
sinos como assinatura, fundo próprio, os 10 inimigos da prancha e o Vyrak
refeito. A suite passa e a Região II não regride. O que falta é a
**arquitetura do primeiro plano** e as **mecânicas por nível** — e são
esses dois que mantêm fidelidade LOW.

Três coisas para o Paulo decidir:

A. **O Vyrak deixou de ser dragão.** A prancha APPROVED
   (`boss_pack.png`) mostra "A Voz dos Ecos", um guardião humanoide de
   sinos, 2 fases. O `docs/niveis.md` e o `docs/progresso_agente.md`
   chamavam-lhe "o Dragão das Sombras" e ficaram desatualizados de
   propósito — a prancha é a fonte de verdade, mas **confirma-se que o
   texto antigo é que estava errado, e não o contrário?**

B. **O N13 continua a ser de raios.** O nível chama-se agora "Mecanismos
   Antigos" e o cânone dele é engrenagens, alavancas e plataformas
   rotativas. A cena mantém `RaioTempestade`/`ParaRaios` e o guardião
   Voltaris. Trocar isso é refazer o nível — fica para decisão.

C. **O N15 tem queda punitiva.** O bot morre 53 vezes por run ali e 0 nos
   outros quatro. Pode ser do bot (não sabe subir), pode ser real. **Vale
   um playtest humano do N15 antes de se mexer na geometria.**

---

## Pendente de DECISÃO — DEV MODE sem PIN (19 set 2026)

Branch `claude/remove-devmode-pin`. Relatório:
`docs/execution_devmode_sem_pin.md`. O PIN saiu como pedido e o DEV MODE
ficou intacto. Duas coisas para o Paulo decidir:

A. **O DEV MODE fica visível em builds de loja?** Hoje quem manda é o
   interruptor `koliani/qa/entrada_dev` no `project.godot`, e ele está
   `true`. Enquanto o PIN existia, dava para argumentar que era uma segunda
   tranca; agora é a ÚNICA. Se alguma build pública não deve ter o botão,
   esse interruptor tem de ir a `false` no preset dessa build — não é uma
   decisão que eu deva tomar sozinho.

B. **O bug do ESPAÇO estava vivo, e não era o que se pensava.** A
   correcção de 18 set (`7a4e586a`) atacou o foco do botão; a causa era o
   `SeletorNiveis` escondido a continuar a ouvir `ui_accept`. Está
   corrigido e provado nos dois sentidos. **Vale a pena o Paulo confirmar
   no Windows dele**, porque a queixa original veio de lá: em DEV MODE,
   saltar repetidamente já não recarrega o nível.

## Pendente de DECISÃO — depois do Super-Process A2 (18 set 2026)

Branch `claude/region02-fidelity-remediation`. **Super-Process A2 fechado:**
relatório final em `docs/execution_a2_regiao02_fidelidade.md` (detalhe
técnico em `docs/implementation/region_02_fidelity_remediation.md`). A suite,
o harness do chefe e os 7 harnesses avulso estão **todos verdes**.

**Corrigido e provado:** o NaN do N06 (era o `Engine.time_scale = 0.0` do
hitstop, e afectava as **nove** plataformas `AnimatableBody2D` do jogo
inteiro); o pico de mortes do N10 (200,7 → 18,5 mortes/1000 px); o bestiário
(0/10 canónicos → 5 espécies recortadas da prancha, 100% dos inimigos comuns
da região); o ambiente (nuvens, props, folhagem carmesim, abismo); e o
Guardião (asas abertas + a paleta ciano que o contrato proíbe, que estava em
cinco sítios).

O que fica para o Paulo decidir:

A. **O N10 ficou fácil demais?** 200,7 → 18,5 mortes/1000 px. O alvo era a
   ordem do N08 (24,2) e cumpriu-se, mas quem decide se o exame final quer
   mais mordida é o playtest humano. A laje `ChaoResgate` cobre x 540-880 e
   o comentário na cena tem as três variantes medidas.
B. **Contraste.** O mar de nuvens foi clareado de propósito (realces 39-53%
   → 57-68%; a textura foi pintada a 51,9%). Se algum nível parecer LAVADO,
   o botão é o 5.º campo da tabela `PACKS` em `atmosfera.gd`.
C. **Os quatro guardiões intermédios não foram tocados** — Golem LOW, Vigia
   MEDIUM, Feiticeira MEDIUM, Espectros MEDIUM. O Vigia continua a CAMINHAR
   e a `TORRE VIGIA` da prancha é uma estrutura fixa. É o maior bloco de
   trabalho que sobra.
D. **A lua de sangue continua a não entrar no enquadramento.** Está na
   `ceu.png` mas essa camada é aplicada a 320 px de altura e o disco fica
   muito acima da câmara; tentou-se recortá-la por cor e não sai limpa (o
   `realcar_lua` tinge-a). O caminho é um elemento próprio na camada `Ceu`
   do `atmosfera.gd`, que tem `motion_scale = 0` e portanto fica fixa à
   câmara. Era prioridade BAIXA (#15) no audit.
E. **As outras cinco criaturas canónicas** (serpente eólica, espectro das
   ruínas, arqueiro eólico, torre vigia, mago do vento como inimigo comum).
F. **A build de Windows não está no Git** e o contentor onde foi feita é
   efémero. Chega ao Paulo pelo CI, que corre em cada push.

---

## Pendente de DECISÃO — depois do audit de fidelidade da Região II (18 set 2026)

Branch `claude/region02-humanlike-bot-playtest`. Relatório completo em
`docs/playtests/region_02_bot_humanlike_playtest.md`. **Nada foi corrigido**:
a execução era observação, prova e crítica. O que fica para o Paulo decidir:

1. **O bestiário da Região II.** Censo medido em jogo: **0 dos 10 inimigos
   canónicos** em N06-N10. `ESP_REGIAO[1]` em `gerador_corredor.gd` ainda diz
   `# II Prisão`. O jogo já tem `abutre` e `olho` com arte completa e já
   marcadas como voadoras — é uma linha de tabela. **Decisão:** apontar já a
   Região II a estas duas, ou esperar pelas criaturas desenhadas da prancha?
2. **O projéctil das PENAS CORTANTES viola o contrato do Guardião.** É
   `Color(0.72, 0.92, 1.0)` = `#B8EBFF` (`chefe_guardiao_dos_ceus.gd:399`),
   que é a paleta ciano/gelo do `monge_celeste` que L3 **proíbe**; e é um
   losango, não uma pena. Correcção de uma linha.
3. **O mar de nuvens chega ao ecrã com 10-24% da luminância com que foi
   pintado** (53% na origem). Não falta asset — é `neblina_fundo`,
   `dessaturar_fundo` e `cor_fundo` nas cinco cenas. **Decisão:** clarear,
   e quanto? É o que diz ALTITUDE.
4. **O ácido do N10.** 76% das mortes do nível num único ponto (x≈700), 99%
   na faixa x=600-820, e mata de vida cheia. **Decisão:** encurtar o ácido,
   pôr uma saliência de recuperação por baixo do ziguezague, ou deixar como
   exame final duro?
5. **A pose do Guardião dos Céus.** A escala CUMPRE o contrato (2,46x altura,
   3,6x largura); a silhueta não — as asas estão espalmadas, e a prancha
   define a leitura à distância pelas asas ABERTAS. Abri-las obriga a rever
   o tecto de 240 px de largura. **Decisão do Paulo, é arte.**
6. **Terreno sem vegetação.** O material `desfiladeiro` é tijolo liso e o
   catálogo de props da região tem 12 entradas (3 de chão, duas das quais
   são `cruz` e `lapide`, de cemitério). A Região I tem 17 props e 8 de chão,
   com folhagem carmesim em todas as bordas. É o item mais caro e o que mais
   fecha a distância à prancha.
7. **A jornada procedural.** Em N06/N07/N09 ela é ~75% do nível e não tem
   uma única zona de vento — a mecânica que dá nome à região vive só na sala
   final. **Decisão:** levar o vento à jornada, ou encurtar a jornada?

**Respondido, não precisa de decisão:** as asas do Guardião **não** tapam a
Koliani na arena (mas também não fazem trabalho de silhueta), e as asas não
darem dano **lê-se bem**.

**A investigar:** em 3 das 9 runs do N06 a posição da Koliani foi NaN em pelo
menos um frame. Não diagnosticado.

---

## Pendente — Super-Process A, Região II fechada (17 set 2026)

Branch `claude/region02-completion-pass`. Tudo o que estava em aberto do
Process 11 e 12 sobre arte, vento e lore está feito; o que sobra é humano.

1. **PLAYTEST HUMANO DA REGIÃO II INTEIRA (N06–N10).** É o único gate que
   falta. Build Windows isolada com launcher por nível em
   `builds/windows/` (save próprio, não toca no save real).
2. **A largura do Guardião** é a primeira coisa a julgar: 235 px numa
   plataforma de arena de 560. As asas tapam a Koliani? Elas não dão dano —
   isso lê-se, ou parece injusto?
3. **N06/N07/N09 vão jogar-se diferente.** As zonas de vento ficaram com o
   tamanho desenhado (o N09 passa de 300 px de largo para 680/650). Está
   certo em relação ao que foi authored, mas nunca foi jogado assim.
4. ~~**Os chefes intermédios ainda se chamam The Jailer / The Guillotine
   Lady / The Condemned Brothers / Ignivar the Cursed Smith.**~~ **FEITO**
   (18 set 2026, `8431d887`). Passaram a Golem das Falésias, Vigia do
   Desfiladeiro, Feiticeira dos Ventos e Espectros Gémeos — GUARDIÕES
   (`guard.*`), não chefes, cada um a traduzir um arquétipo da prancha
   aprovada da região. As quatro silhuetas foram redesenhadas; o gameplay
   não mudou. **Por julgar no playtest:** as criaturas novas leem-se à
   escala de jogo? O N07 perdeu o laranja todo — a arena ficou legível ou
   ficou monótona?
5. **Os inimigos não são da região** (esqueleto, chort, imp, mastim, orc; o
   cânone pede morcego dos ventos, sentinela flutuante, gaivota sombria,
   golem aéreo, mago do vento). Trocar só o aspeto parte a leitura
   silhueta→comportamento — precisa de lote próprio, com gameplay.
6. **N06/N07/N09 ainda têm jornada procedural** (`corredor = true`) e N08/N10
   não. Inconsistência de estrutura da região; é gameplay.
7. Quatro ataques canónicos do Guardião por implementar: RAJADA DE VENTO,
   CHOQUE AÉREO, METEOROS CELESTIAIS, INVOCAR GAIVOTAS SOMBRIAS.

## Pendente -- Process 12, N10 Guardião dos Céus (17 set 2026)

1. **PLAYTEST HUMANO do N10** (branch `claude/region02-n10-guardian-skies`).
   O que interessa: os tres telegrafos leem-se? o vento comandado na arena e'
   pressao ou estorvo? o EXPOSTO de 1,35 s chega para responder?
2. **Arte do Guardiao dos Ceus** e' rig de pack (`monge_celeste`) -- passe
   canonico da Regiao II fica para o Process 13.
3. A lore da Cela Zero ainda fala do Primeiro Prisioneiro (pistas dormentes);
   alinhar quando a Regiao II levar passe narrativo.

## Process 11, N08 Ilhas Suspensas -- FECHADO (17 set 2026)

Playtest humano no Windows **APPROVED**; Process 11 COMPLETE, gameplay LOCKED.
Fica pendente, sem bloquear:

1. **Art pass canonico da Regiao II** por fazer.
2. **Bug do `WindZone`: as zonas de uma cena partilham a forma de colisao.**
   Afeta N06/N07/N09 (N09 com duas zonas a 300x220 em vez de 680x240/650x270),
   NAO o N08. Corrigir = duplicar a forma no `wind_zone.gd` + repetir o
   playtest de N06/N07/N09. Lote proprio.
3. **`tools/correr_testes.ps1` rebenta no Windows PowerShell 5.1** -- tratar a
   parte.
4. Validacao manual device/PWA: ja' nao e' precisa para fechar o gameplay.
5. (Nota de design, sem decisao pendente depois da aprovacao) com salto duplo
   + dash dois vaos do N08 fazem-se sem planar.

## Pendente de decisao do Paulo -- 9H.18 (13 set 2026)

1. **A CORRIDA PRECISA DE ARTE DESENHADA -- nao ha' volta a dar.** Medido
   com um crivo novo e independente (`tools/validar_run_nativo_9h18.py`): nos
   10 frames golden o pe' de tras percorre **7 px** em todo o ciclo e o da
   frente 29, e nenhum dos dois atravessa a linha da anca. A pose do segundo
   contacto **nao esta' desenhada** -- nenhum `fps`, `speed_scale`, espelho
   ou particula a cria. Procuradas todas as fontes do repo, do master package
   e dos 15 ramos: so' o **piloto 5G** tem passada a serio, e e' outra
   Koliani (cabelo roxo, saia de chama, sem lenco vermelho).
   **Decisao:** encomenda-se o ciclo novo (a spec ja' esta' escrita em
   `docs/spec_run_nativo_koliani.md`, e o jogo ja' o aceita como drop-in), ou
   aceita-se mudar a personagem para a do piloto 5G?
2. **Os SFX do menu e do combate foram refeitos -- falta OUVIR.** 22
   ficheiros novos, todos dentro de alvos de forma medidos (navegar passou de
   160 ms para 55; o remate do combo deixou de chegar 70 ms atrasado; golpear
   e acertar deixaram de ter o mesmo timbre). Mas quem os fez **nao os ouve**.
   Teclado de sons no modo Dev, **tecla S** -- os ~40 eventos a um toque, com
   os volumes reais. **HUMAN LISTEN REQUIRED** antes de se dar isto por bom.
3. **Sons ainda por refazer (ja' auditados).** `porta` (1000 ms, com o pico
   aos 236 ms), `transicao`, `apanhar`, `selo`, `conquista`, `projetil`,
   `investida`, `chefe_cai`, `dano`, `bloqueio`, `morte_koliani`, `raiz_*`,
   `plataforma_surge` e os 21 `mob_*`. Ficaram de fora por prioridade -- o
   Game Master nomeou o menu e o combate. Seguem na proxima passagem?

## Pendente de decisao do Paulo -- 9H.17 CONTINUATION (13 set 2026)

1. **QA jogado nao certificou nenhum nivel.** A Koliani chega a` arena do
   chefe do 1-1 com input real, mas o Ghorak mata-a e a run reinicia.
   Conduzir um combate de chefe as cegas (rajada de teclas -> fotografia) nao
   converge. Decisao: aperta-se o laco observacao-accao (caro), joga-se o
   percurso a mao, ou aceita-se certificar so' a TRAVESSIA sem o chefe?
2. **"DEVELOPER MODE" aparece no menu da build de RELEASE.** A 9H.17 D pos a
   entrada Dev disponivel em release para o QA. Para uma build que va' para o
   playtester isto parece errado -- tirar, ou manter enquanto houver QA?
3. **NOVO JOGO destruiu a campanha do Paulo nesta sessao.** Corrigido o buraco
   (sair do botao desarma) e reposto o save por SHA256. Fica a pergunta maior:
   quer saves multiplos / um slot separado de QA, ou basta esta proteccao?

## Pendente de decisao do Paulo -- 9H.17 (13 set 2026)

1. **NATIVE ART REQUIRED -- corrida da Koliani.** Os 10 frames golden nao tem
   passada alternada: a abertura das pernas nunca fecha (38,40,39,38,38,53,
   44,46,43,56) e o centro de massa nao troca de lado. Nao ha' outra fonte no
   repo nem no historico, e nao se fabricam frames espelhados.
2. **NATIVE ART REQUIRED -- fundo HD do L2.** A autoridade de arte da Regiao I
   inteira e' uma prancha de 1536x1024; tudo o que no repo se chama "HD" e'
   reamostragem dela, incluindo o `_hd_x4` e as camadas de 1920 (declaradas
   como ampliadas pelo proprio manifesto). Entretanto o L2 passou a compor
   recortes nativos em vez de esticar uma tira -- melhora, mas nao e' nativo.
3. **NATIVE ART REQUIRED -- faixa de superficie do chao/pantano.** O leito ja'
   esta' feito com arte aprovada; a faixa palida na base do ecra permanece e a
   origem dela nao se identificou nesta execucao.
4. **Estender o passe Hybrid aos niveis 1-3/1-4/1-5?** Eles ficaram na
   apresentacao antiga (plataformas rectangulares, emendas no fundo) porque o
   `L1Hybrid.serve()` so' cobre os perfis 1 e 2. O corte visual dentro da
   Regiao I nao desapareceu, mudou de sitio. Nao se estendeu porque o briefing
   da 9H.17 congelou "L2-L5 REMASTER STARTED: NO" -- e' uma linha, e e'
   decisao tua.
5. **Export publico:** desligar `koliani/qa/entrada_dev` no `project.godot`
   antes de uma apresentacao final -- e' o que fecha a entrada "DEVELOPER
   MODE" do menu.
6. **As 2 falhas de teste que restam** (Execution 9C: o L1 usar o kit 9C e as
   camadas da 08) sao decisao do nivel Golden: o passe Hybrid superou as duas.
   Decidir se os testes se actualizam ou se o L1 volta atras.

# Prioridades — Koliani

## Agora

00000000000000000. **9H.16 FEITO -- L1 como Golden Level (fases B-F). TRES
   DECISOES DO PAULO.** Ramo `codex/9h16-l1-perfection`, v0.18.8. Relatorio:
   `docs/execution_9h16_l1_golden.md`. Feito: Phase B fechada com QA nativo
   (isolamento do save provado byte a byte), ajudas fora do centro do ecra,
   cadeia de espada com funcao por golpe (0,85x/1,0x/1,25x/1,9x de dano,
   90/150/230/470 px/s de recuo FISICO, o 3.o atordoa e o 4.o sangra), a raiz
   da floresta passou a espetar inimigos, remates organicos nas plataformas e
   som para as duas mecanicas-assinatura do L1 (estavam MUDAS).
   **DECISAO 1: PERCURSO HUMANO DO L1.** O input sintetico so' cobriu o
   primeiro terco -- falta o percurso ate' ao Ghorak e a travessia L1->L2, a
   sensacao do combate depois da mudanca, e ouvir os SFX novos.
   **DECISAO 2: KOLIANI RUN NATIVE FRAMES** (confirmado por medicao; e' o
   mesmo PENDENTE 1 da 9H.13/14).
   **DECISAO 3: CHAO/PANTANO NATIVE ART** -- a faixa palida no fundo do L1
   esta' medida (o `LiquidoMortal` do corredor triplica a luminancia da banda)
   mas nao se isolou correccao com prova; a hipotese do veu foi revertida.


0000000000000000. **9H.13/14 FEITO -- SFX, corrida e tremor do L2. DUAS
   DECISOES DO PAULO.** Ramo `claude/9h13-14-audio-koliani-l2`, por integrar.
   Relatorio: `docs/execution_9h13_14_audio_koliani_l2.md`. Feito: 23 SFX
   refeitos (combo com 4 sons proprios), tremor do fundo do L2 morto (era o
   `position_smoothing` da camara a lutar com a `physics_interpolation` --
   dp/media 1,70 -> 0,87 a 165 Hz), cadencia da corrida pela velocidade.
   **PENDENTE 1: KOLIANI RUN NATIVE FRAMES.** Esta' medido que os 10 frames
   golden do `run` sao um ciclo de UMA perna (o pe' de tras percorre 13 px em
   todo o ciclo e nunca passa a' frente). Fabricar a meia-passada por cirurgia
   de pixels parte a arte. Precisa de frames nativos na linguagem do Golden
   Set. **PENDENTE 2: L2 NATIVE HYBRID ART**, a mesma decisao que o L1 ja'
   espera desde a 9H.12D.


000000000000000. **9H.12D FEITO -- L1 em Hybrid Cinematic 2D. FALTA UMA
   DECISAO DO PAULO.** Relatorio:
   `docs/execution_9h12d_l1_hybrid_prototype.md`. Feito: terreno HD (periodo
   30 px -> 384/512, das pranchas de 1254 px que estavam a ser reduzidas a
   32), faixa verde-oliva morta (a fonte era o `LiquidoMortal` do
   `gerador_corredor.gd`, 460 px por REGIAO, nao a poca da cena) e veu de
   superficie na agua. **PENDENTE DE DECISAO: background nativo HD.** Nao ha'
   fonte com mais informacao no repo -- a prancha 08 e' 1536x1024 e o recorte
   do panorama 952x247; ampliar nao acrescenta nada (ja' medido 2x). Para
   fechar e' preciso o Paulo dizer se autoriza **arte nativa nova em 5 layers
   de 1920x1080+** (IA original especifica para Koliani, ou CC0 compativel com
   redistribuicao num repo publico). Sem isso o fundo fica desfocado.


00000000000000. **9H.12B PLANO FECHADO -- remaster da Regiao I. A ESPERA DE
   DUAS DECISOES DO PAULO.** Plano completo em
   `docs/execution_9h12b_regiao1_remaster_plan.md`. Quatro causas MEDIDAS:
   (1) o desfoque do fundo e' aritmetica -- a fonte e' um recorte de
   **952x247** ampliado **4,2x** (3,0 no mundo x 1,4 de zoom), ou seja 0,24 px
   de fonte por pixel de ecra; os `_hd_x4` sao upscales e nao acrescentam
   informacao; (2) o "mosaico pobre" e' o `terreno_corpo.png` de **30x75**
   repetido ~35x por plataforma, sem variantes; (3) **ja' existem 12 fontes
   de 1254x1254 a 2172x724** em `_source/imagegen_v1/` que o
   `build_region_01_sprite_kit.py` **reduz a 32/64/96 px** -- e' a alavanca
   mais barata que temos; (4) **o repo e' PUBLICO**, logo commitar um asset
   e' redistribui-lo: so' entra CC0 ou arte nossa. **BLOQUEADO ate' o Paulo
   decidir:** (a) mudar o contrato de geracao (hoje pede "pixel-art, hard
   pixel clusters, no antialiasing" -- o hibrido 2D exige o oposto) e (b) a
   politica de assets externos nao-CC0 num repo publico. **Pixsol REJEITADO**
   (16x16 px e proibe uso em IA). Segue sem aprovacao: **9H.12C** (bugs do
   GM). Bugs confirmados: a legenda do HUD promete "Jump x2" mas
   `HABILIDADES_INICIAIS` esta vazio; o crash da saida do L1 esta na
   TRANSICAO (`porta.gd:69`), nao na cena de destino -- o L2 carrega limpo em
   headless. **Regiao II NAO iniciada.**

0000000000000. **9H.7 PASS (v0.18.1) -- fundo da Regiao I nitido e niveis
   1-5 completos. PRONTO PARA REVISAO DO GAME MASTER.** Fechou os dois
   pontos que o Game Master deixou abertos. **Desfoque: duas causas
   provadas** -- cada camada era ampliada 2,1x a 3,6x no pixel do ecra com
   filtro bilinear (a 9H so tratou o panorama), e o shader de nitidez fazia
   `COLOR = c`, o que **atirava fora o modulate de toda a cadeia**: desde a
   9H o fundo era desenhado sem a tinta de mood da prancha 08, sem os -18 %
   da camada funda e sem os alfas das camadas, e o azul ceifava a B=255.
   Agora amplia-se no DISCO ao fator exacto (panorama x4, kit x3) e desenha-se
   a ~1:1 (mediana 2,8 -> 1,05-1,10). Corrigida tambem a risca escura do L5:
   o recorte da 6A levava uma coluna da moldura do painel da prancha, e as
   pontas espelhadas duplicavam-na. **Conteudo: metade do vestuario caia fora
   do ecra** -- as pecas eram espalhadas por intervalos escritos a mao que
   nao sabem onde o nivel comeca; `_banda()` calcula a faixa que a camara
   percorre e as quantidades passaram a densidades por 1000 px. Montado o que
   a 08 tem e faltava: vinhas a emoldurar o ecra, aglomerados de cristal a
   media distancia (4/6/9/11/17 de L1 a L5) e os raios de luz volumetricos
   (que a 9C escondeu sem substituir). L3 e o pico das ruinas, L4 o das
   cascatas, L5 tem a Heart Tree sobre a arena do chefe. Zero alteracoes a
   colisoes, geometria, checkpoints, inimigos, chefes, save ou movimento.
   Desempenho 0,77-1,03 ms de 16,7 (**medido em PC, nao em telemovel**).
   PRODUCTION ASSET MISSING: Chuvisco/Chuva (esta na 08 mas marcado
   "(variante)" e sem peca no kit 9C). **Regiao II NAO iniciada.**

000000000000. **9H.1 PARTIAL PASS (v0.18.0) -- fecho do gate humano da
   Regiao I. PRONTO PARA REVISAO HUMANA.** Fechou os cinco pontos que o
   Game Master deixou abertos na 9H: **trilha sonora de producao** (6 pecas
   ORIGINAIS do projecto -- menu, exploracao, combate, guardioes, Coracao,
   pausa -- sintetizador escrito de raiz, zero licencas, mesmo motivo de 7
   notas nas cinco com melodia); **combo da Koliani com poses de corpo
   proprias** nos golpes 2/3/4 (reves ascendente / rodopio com as COSTAS
   viradas / remate com avanco fundo -- 37-49 % de silhueta diferente entre
   golpes, nenhum frame repetido; o combo passou de 3 para 4 golpes como o
   briefing pedia, **sem mexer no dano por golpe**); **283 frames derivados
   de movimento** para as 11 especies e as 2 fases do Coracao (pernas
   detectadas por grupos, tronco a respirar, e um estado ATTACK que nao
   existia); **seletor com tema POR REGIAO** (Regiao I em verde de musgo com
   o panorama da Arvore-Coracao e o magenta da corrupcao so' no no' do
   guardiao; as 19 sem autoridade em aco frio, marcadas REGION SELECTOR
   THEME AUTHORITY MISSING). Desempenho sem regressao (pior frame 2,8 ms).
   Relatorio: `docs/execution_9h1_gate_humano.md`.

000000000001. **A DECIDIR (Game Master): o `dano_contacto` dos chefes SOBE
   ao longo da Regiao I** -- 16 no Ghorak, 25 no Coracao -- enquanto todos
   os outros danos descem com a rampa de alivio. Esta excluido do
   `_afinar_dificuldade` de proposito ou por descuido? Nao se mexeu.
   Tabela completa antes/depois em `work/execution_9h1/chefes_regiao1.md`.

000000000002. **P1 por fazer da 9H.1**: (a) **combo de 4 golpes por TOQUE**
   no browser -- o Chrome desta maquina corre ocluido, a 1 fps, e nao se
   encadeia dentro da janela de 0,42 s; (b) **playtest humano dos chefes**
   da Regiao I -- os numeros nao se mexem sem ele.

00000000000. **9H PARTIAL PASS (v0.17.0) -- frontend de producao + slice
   final da Regiao I. PRONTO PARA REVISAO HUMANA.** Menu novo, **intro em
   video**, icone/logo em todo o lado, **seletor = mapa de regiao** (nos,
   trilho, painel, 20 abas), HUD em carmesim, **EDITAR LAYOUT** na PWA,
   vozes de interface + ambiencia propria da Regiao I, **chefes L1-L5 mais
   faceis** (Ghorak: vida 800->416, EXPOSTO 0,72->1,11 s), **fundo mais
   nitido** (+19 % de acutancia medida), **inimigos e chefes com vida**
   (respiracao/passada/recuo -- o `_process` saia cedo e nao corria nada),
   **combos que se leem** (arco e tom proprios por golpe + selo x2/x3).
   Tudo sai das pranchas aprovadas em
   `work/production_art_gate/10_menu_rebrand/` -- **o caminho do briefing
   (`9H_game_master_approved`) nao existe**. Provado no EXE de release
   (intro pos=2,93 s, menu, mapa, L1-L5) e no Web (carrega, icone, cartao,
   `<video>` a tocar). Pacote de revisao:
   `work/execution_9h/folha_revisao_9h.png`. Relatorio:
   `docs/execution_9h_frontend_regiao1.md`.

   **PENDENTE DE DECISAO DO GAME MASTER:**

   a) **SOUNDTRACK NOVA (`PRODUCTION AUDIO MISSING`).** Pediste "mudar
      soundtrack completa". As 40 faixas atuais (20 de nivel + 20 de chefe)
      sao pecas compostas, com licenca; troca-las por sintese seria pior, nao
      melhor. **Preciso do pacote novo com a licenca** -- 20+20, ou um
      conjunto menor com a regra de qual toca onde. O resto do audio que se
      podia fazer sem licencas ja esta feito (vozes de interface, ambiencia
      da floresta, tom por golpe do combo).

   b) **ESTATISTICAS DO SELETOR (`APPROVED DESIGN / PRODUCTION ASSET
      MISSING`).** A prancha mostra *Colecionaveis 0/3*, *Desafios 0/1* e
      *Melhor Tempo*. O jogo nao tem nenhum dos tres. Ou decides o design (o
      que conta como colecionavel? o que e um desafio? guarda-se o tempo por
      nivel?) ou as tres linhas ficam como estao: guardiao / passo na regiao
      / estado.

   c) **CAPTURAS DO WEB EM CHROME REAL.** O pane de browser desta sessao
      esteve escondido, e um pane escondido para o `requestAnimationFrame`
      -- sem rAF o Godot Web fica parado e as capturas esgotam o tempo. O
      build esta provado por outras vias; falta a foto do menu/seletor/HUD
      no browser e os picos de audio.

   Backlog tecnico: citacoes por regiao (so a I tem a aprovada); PCK do Web
   com 285 MB; poses de ataque proprias para inimigos e para os golpes do
   combo; `RaizPerigo`/agua venenosa/fogueira sem autoridade (da 9G); fonte
   CJK livre para o chines no Web (da 9F).

0000000000. **9G PASS (v0.16.1) -- VFX de producao da Regiao I.** Os efeitos
   passaram a sair da prancha 07 aprovada: golpes 2/3 do combo, dash,
   rolamento, salto duplo, aterragem, dano, morte, escudo, tiro; faiscas no
   acerto e rebentamento no remate/critico; corrupcao (rampa escura, alfa
   preso a luminancia) na morte dos inimigos, no telegrafo dos guardioes, no
   tiro e na fase 2 do Coracao, e na sua queda; brilho de recolha nas
   essencias e no checkpoint. 148 frames (146 PASS, 2 REVIEW, 0 FAIL),
   produzidos por `tools/produzir_vfx_9g.py` -- a prancha tem o fundo pintado
   e a grelha nao bate com os frames, por isso o alfa e reconstruido e os
   cortes caem nos vales do desenho. Gameplay intacto. Nome canonico da regiao
   corrigido nos 6 idiomas: **FLORESTA CORROMPIDA**. Prova no EXE (37 fotos,
   zero legado) e no Web/PWA (PCK = export, audio do 9F sem regressao).
   **Seguinte: 9H -- montagem visual da Regiao I + gate humano** (nao
   iniciada). **Nada pendente de decisao do Game Master.** Fica em aberto, por
   falta de autoridade: a arte do `RaizPerigo` (a prancha nao desenha raizes),
   a agua venenosa e a arte base da fogueira. Relatorio:
   `docs/execution_9g_region1_vfx.md`.

0000000000. **9F PASS (v0.16.0) — UI da Região I em produção + som do Web/PWA
   corrigido na raiz.** O Web estava mudo porque os buses Music/SFX eram
   criados em runtime e o espelho JS do Godot (modo Sample) ligava o Master num
   ciclo sem saída para o altifalante; agora vêm do `default_bus_layout.tres`.
   Provado no Chrome real: contexto `suspended` → `running` ao 1.º clique,
   música do menu, música de jogo, SFX de UI e de jogo com pico medido. UI:
   kit da prancha 09 (botões, painéis, barras com gema, diálogo, toasts) e
   seletor 20 regiões × 5. **Seguinte: 9G — VFX** (não iniciada). Nada pendente
   de decisão do Game Master. **Backlog:** (1) fonte CJK livre para o chinês
   no Web (hoje tofu, anterior à 9F); (2) o `✦` do "Santuário" no i18n sai em
   tofu no Web; (3) `ico_caveira.png` (16 px) ainda é do kit antigo; (4)
   excluir `assets/**/manifest*.json` dos exports. Relatório:
   `docs/execution_9f_ui_pwa_audio.md`.

000000000. **9E.2 PASS (v0.15.20) — Região I fechada: inimigos E Coração em
   produção.** O Coração Putrefacto usa a autoridade dedicada (fase 1 contida,
   fase 2 intensificada, erupção na transição); os 11 inimigos/guardiões/crias e
   as 2 fases estão provados no EXE exportado. **Seguinte: 9F — UI / menu / HUD**
   (não iniciada). Nada pendente de decisão do Game Master. Opcional (design
   novo): mostrar as poses de alcance do Coração num estado de ataque; arte do
   `RaizPerigo`. Backlog técnico: excluir `assets/**/manifest.json` dos exports.
   Relatório: `docs/execution_9e2_coracao_putrefacto_closure.md`.

00000000. *(Resolvida pela 9E.2.)* **9D+9E PARTIAL PASS (v0.15.19) — inimigos feitos, falta o Coração.**
   Os 5 comuns, os 4 guardiões, os clones da Morvanna e as crias da Rainha já
   usam arte derivada da autoridade aprovada (SHA `8ebf8ecd…`). **Decisão do
   Game Master:** o **Coração Putrefacto** não se consegue tirar da prancha sem
   inventar o contorno — está pintado dentro da arena. Entregar o Coração
   isolado (alfa real ou fundo liso; idealmente fase 1 e fase 2). Opcional
   (design novo): poses de andar/golpe para os inimigos (hoje uma pose, mexida
   inteira). A 9F só depois do boss. Relatório:
   `docs/execution_9d_9e_region1_enemies_boss.md`.

0000000. *(Resolvida pela 9D+9E.)* **9D BLOQUEADA NA ARTE — falta uma prancha de inimigos da Região I.**
   Nenhuma das 12 pranchas desenha inimigos, e os da prancha 12 não se extraem
   (30 px, RGB, fundo pintado). **Decisão do Game Master:** (1) entregar uma
   prancha com os 9 inimigos (goblin, mushroom, gosma, besouro, lodo, Ghorak,
   Morvanna, Rainha, Entrevane), cada um com idle/run/hit/dead, ao contrato do
   manifesto (comum 96×96 a 48 px; guardião 192×192 a 100 px), ou (2) autorizar
   pixel-art por código como produção. **Decidir também** que aspeto têm as
   crias da Rainha e os clones da Morvanna, que hoje nascem como goblins.
   A integração já está pronta: basta preencher o manifesto. Relatório:
   `docs/execution_9d_region1_enemies.md`.

000000. **9C FEITA — REGION I ENVIRONMENT GATE CLOSED (v0.15.18).** L1–L5 usam
   o kit de produção derivado das pranchas 08/10 (terreno, props, corrupção,
   4 planos de parallax, névoa); o terreno CC0 já não aparece na Região I.
   **Seguinte: 9D — inimigos e guardiões da Região I** (não iniciada).
   Nada pendente de decisão do Game Master. Opcional (seria design novo ou
   outra execução): arte própria para os objectos de gameplay da região (água
   venenosa, checkpoints); um corpo de terreno maior que o mosaico de 44 px da
   prancha 10. Backlog técnico mantido: excluir `assets/**/manifest.json` dos
   exports. Relatório: `docs/execution_9c_region1_environment_kit.md`.

00000. **9B.4 FEITA — KOLIANI PRODUCTION GATE CLOSED (v0.15.17).** Todos os
   estados da Koliani na Região I saem do Golden Set; o premium_v1 e a 5G já não
   aparecem. **Pendente de decisão do Game Master (opcional, é design novo):**
   poses próprias para morte deitada, rebordo de braços por cima e golpes 2–4
   do combo. **Seguinte: 9C — kit de ambiente da Região I.** Backlog técnico:
   excluir `assets/**/manifest.json` dos exports; CI vermelha em "Nascer no
   checkpoint sem ficar preso" (anterior à 9B.3). Relatório:
   `docs/execution_9b4_full_character_package.md`.
   *(As entradas 0000/0000b/000/00a abaixo estão resolvidas pela 9B.1–9B.4.)*

0000. **9B.1 BLOQUEADA: o Golden Set da Koliani precisa de quem o desenhe.**
   O Paulo resolveu CONF-01 para **Route B** (arte de raiz). Um agente sem
   ferramenta de imagem não consegue produzir 33 frames de pixel-art premium
   com identidade consistente — desenhar por código dava as aproximações
   poligonais que a 9A proibiu. **Falta decidir quem desenha.**
   Está tudo o resto pronto: contrato de canvas, pastas, manifestos, validador
   provado. Ver `docs/production_art_gate_9b1_golden_set.md`.

0000b. **APROVAR O CONTRATO DE CANVAS antes de alguém desenhar.** 128×128,
   personagem a 64 px, pivot (64,104), baseline 103, escala Godot 1,0, offset
   (0,−18). Mantém o tamanho aparente de hoje, por isso não mexe em colisão,
   câmara, física nem tempos. Mudá-lo depois custa os 33 frames todos.

000. **DECISÃO DO GAME MASTER PENDENTE (CONF-01, Execution 9A): o 9B extrai
   das pranchas ou desenha de raiz?** O `production_contract.json` diz que
   «nenhum frame ou píxel é extraído ou reciclado» das pranchas, mas as 7
   animações que estão no `.exe` aprovado (`koliani_visual_pilot_5g`) foram
   extraídas das pranchas 05/06. Sem esta decisão o 9B não arranca. As duas
   rotas estão em `docs/production_art_gate_asset_gap_map.md`.

00a. **LACUNA CENTRAL MEDIDA (9A): na Região I vêem-se duas Kolianis.** Parada
   e a correr usa a 5G (cabelo solto, preto/vermelho, sem VFX colado); a
   atacar, dash e morte usa a `koliani_premium_v1`, que tem **rabo-de-cavalo**,
   cabelo roxo e **o arco do golpe pintado dentro do frame**. Viola três
   cláusulas congeladas. `tools/validate_assets.py` → PASS=0 FAIL=16. É a
   causa técnica do «ainda parece antigo».

00b. **WINDOWS PERFORMANCE GATE = FECHADO, APROVADO POR HUMANO.** `master`
   avançou por fast-forward para `6beb05b` e foi empurrado; `origin/master`
   está agora em `423fde7` (commits posteriores, `6beb05b` é antepassado).
   **Mas o `.exe` aprovado foi exportado de `05f050e` (8.1C)** — não traz a
   correção 8.1E. Reexportar antes de dar a 8.1E por validada no binário.
   A `master` do checkout principal ficou em `b2fd8a0` de propósito (tem
   `project.godot` sujo + arte de produção por versionar): `git pull
   --ff-only` só depois de arrumar isso.

00c. **RISCO: arte de produção só existe na máquina do Paulo.** O kit modular
   de 12 peças da Região I e os 449 ficheiros de
   `work/koliani_extraction_recovery_medium/` não estão versionados (e `work/`
   está no `.gitignore`). Um `git clean` apaga trabalho insubstituível. As 12
   pranchas aprovadas (~29 MB) também estão por versionar — comitá-las é
   praticável, mas exige acrescentar `Koliani_1.0_Master_Package_v2/**` ao
   `exclude_filter` dos presets no mesmo gesto.

0. **VALIDAR A JOGAR: o congelamento do save está corrigido (Execution 8.1E).**
   `guardar()` passou de **2047 ms para 9,2 ms** — cabe num frame. A causa era
   `ProgressionIDs.identidades()` a reler e parsear o `level_manifest.json`
   **1312 vezes por gravação**; agora tem cache. Não era o antivírus (a 8.1C
   enganou-se): o disco custa ~2 ms. `build/windows/Koliani.exe` está
   construído e arranca limpo. **Falta o Paulo jogar**: passar num checkpoint,
   levar projétil, levar dano repetido, morrer/reaparecer — e confirmar que os
   dois segundos desapareceram. Ver `docs/execution_8_1e_causa_do_congelamento.md`.

0b. **GAME MASTER CADENCE REVIEW REQUIRED (Execution 8.1B):** a interpolação
   de física está **ligada** e validada tecnicamente — a física continua a
   60 Hz e nenhuma constante de movimento/câmara mudou. Medido sobre a
   imagem desenhada: o desvio entre frames consecutivos caiu 59 % e o
   movimento deixou de chegar aos solavancos. Falta a **sua** validação
   visual no `build/windows/Koliani.exe`: corrida, saltos, mudanças rápidas
   de direção, Dash, combate, câmara, checkpoint, morte/reaparecimento, L3,
   L5, arena, Coração Putrefacto, projéteis. Olhar em especial para o
   **reaparecimento** e para a **textura do screen shake** (agora amostrado a
   60 Hz). Detalhe:
   [`docs/execution_8_1b_physics_interpolation.md`](docs/execution_8_1b_physics_interpolation.md).

1. **Execution 8 — PARTIAL PASS / HUMAN REVIEW REQUIRED:** jogar a Região I
   completa (L1→L5→Coração Putrefacto→reward) nos builds Windows e Web/PWA;
   confirmar o menu sem dev UI, Koliani atual, panorama partilhado e validar
   legibilidade visual, feel do combo/aéreo/Dash, curva de dificuldade,
   checkpoints e ritmo do boss. A validação técnica e o runtime exportado
   passaram; isto não constitui aprovação humana.

1b. **KOLIANI GOLDEN SET — PRODUCTION INTEGRATED (Execution 9B.3, v0.15.16).**
   Ativo em L1–L5 no Windows e na Web. Os 8 frames baixos foram aceites como
   pose; a regra dos 59 px é só alerta de revisão. **A seguir: pacote completo da
   Koliani** (dash, roll, hurt, morte, crouch, wallslide, borda, djump, defesa,
   combos próprios e land), derivado do Golden Set. Até lá esses estados ficam
   no premium_v1. Ver `docs/execution_9b3_golden_set_integration.md`.

## A seguir

2. **Produção visual aprovada em falta:** frames limpos de combate, plataformas,
   props, layers
   alpha/tiles Hybrid L2–L5, criaturas/guardiões, Coração Putrefacto, HUD,
   menu/seletor, VFX e áudio, sem reabrir design nem recortar pranchas
   arbitrariamente.
3. **Completar run_brake e land — PRODUÇÃO EM FALTA:** substituir os fallbacks
   aprovados apenas quando existirem os 11 frames limpos. Não inferir pixels.

## Validação externa pendente

- Nível 12 em iPhone, Safari/PWA: **DEVICE VALIDATION REQUIRED**. Desktop e
  OpenGL passaram, mas não encerram este ponto.

## Ordem técnica registada, não autorizada por si só

- Proteger o pipeline/geradores antes de remodelação em massa.
- Definir versionamento e migrações de save antes de mudar progressão.
- Definir IDs estáveis de progressão e persistência de recompensas.
- Validar safe areas e resolver a divergência de versão Android.
- Não iniciar Região II antes do gate humano da primeira Vertical Slice.

Detalhes e riscos em [docs/backlog_tecnico.md](docs/backlog_tecnico.md). O
dashboard de execução está em
[docs/execution_dashboard.md](docs/execution_dashboard.md).
