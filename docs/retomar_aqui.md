## Região III FECHADA — tecnicamente completa (20 set 2026) · PASS

Branch `claude/region03-completion-pass`, integrada em `master`.
Relatório: [`region_03_final_closure.md`](implementation/region_03_final_closure.md).
Auditoria por eixo: [`AUDITORIA_EIXOS.md`](playtests/region_03_visual_evidence/AUDITORIA_EIXOS.md).
Versão **0.18.19**.

**O número que interessa:** verificação global dos 100 níveis, "antes"
com o gerador do `master` e "depois" com este HEAD —
**95 iguais, 5 mudados, e os 5 são exactamente os N11-N15**. Alterações
fora da Região III: **zero**. Bateria de 21 (suite, Vyrak, Região II,
sessão, save, progressão, movimento, 9 verificadores do CI, spawn): 0 falhas.

**QUATRO ARMADILHAS, e são o que vale a pena guardar:**

1. **O `cam` da `MECANICA_DO_NIVEL` não é só o aviso de tutorial** — é a
   câmara-assinatura que o gerador FORÇA na jornada desse nível, e o
   `grau` diz quantas vezes (`1 + grau`). Dar o slot do N16 a outra coisa
   mudou-lhe 832 linhas de geometria; perder um `grau: 1` na linha 55
   mudou 848 no N56.
2. **Comparar só QUE câmaras estão disponíveis mente.** O
   `_pool_permitida()` duplica o peso de uma câmara nos 8 níveis a seguir
   ao desbloqueio. O modelo tem de ser o **multiconjunto pesado** — o meu
   modelo sem isso disse "zero afectados" e a medição deu 90/10.
3. **`nivel_de_estreia()` devolvia 0 para uma câmara fora da tabela.**
   Tirar `serras` do sítio onde estreava pô-la disponível desde o nível 1:
   a Floresta ganhou salas de serra e o `spawn_livre` acusou "respawn não
   permite salto (8 px)", risco de softlock.
4. **A `PlataformaRitmada` usa `Time.get_ticks_msec()`** — relógio de
   PAREDE, que o `Engine.time_scale = 0` não congela. A minha baseline
   acusava regressões que mudavam de plataforma a cada corrida. Era da
   ferramenta, não do jogo.

E uma de método: uma suite de 25 min não eram as luzes novas — era
**contenção de CPU** com o batch dos 100 níveis a correr em paralelo. O
"~8 min" que eu usava de referência era contenção também. Cronometrada
sozinha, **a suite leva 14 segundos** (e 30 s no runner do CI). Medido
depois: as luzes de props são 15-23 por nível, ~20% do total. Medir
sozinho, antes de concluir.

**A arquitetura que fechou isto:** apresentação e desbloqueio deixaram de
ser a mesma coisa. `nivel_de_apresentacao()` (posição na tabela, só o
aviso) vs `nivel_de_desbloqueio()` (`DESBLOQUEIO_BASE` global congelado +
`DESBLOQUEIO_REGIAO` local). A Torre dos Ecos antecipa elevador,
engrenagens e plataformas ilusórias só para si.

**Produção (run #487, `7f789a18`):** os cinco jobs verdes — testes
headless, Android, Windows, Web e Pages. Release `win-latest` reescrito
às 09:54:40 com `Koliani-windows.zip` (131 168 223 bytes) do mesmo SHA;
deployment de Pages verde do mesmo SHA. **MASTER == WINDOWS == PWA.**

> A run #486 (`e4576f1e`) ficou encravada >40 min no passo "Correr suite
> de testes" e nunca fechou. Não era código: o mesmo passo leva 14 s
> local e correu em **30 s** na #487. Era o runner. A #487 substitui-a.

**Fica para playtest humano:** a queda punitiva do N15 (não foi tocada,
por decisão), e os eixos que ficaram em MEDIUM — midground, densidade
visual e composição, porque a prancha tem arcadas densas e a jornada é
procedural.

---

## Região III — continuação do Super-Process B (20 set 2026) · PARTIAL

Branch `claude/region03-completion-pass`, de `3c1ca794` (LOCAL == REMOTE
confirmado). Relatório:
[`region_03_completion_continuation.md`](implementation/region_03_completion_continuation.md).
**NÃO integrado em master** — é PARTIAL, e o briefing só deixa integrar PASS.

**Fechado:** os dois eixos que estavam LOW. Props do bioma `torres` de 12
para **32** (`tools/gerar_props_torre_ecos.py`, desenhados — os packs de
origem não vêm no Git), com a `cruz` e a `lapide` de cemitério fora; e 46 %
da arquitetura (arcos, colunas, vitrais, sinos grandes) plantada em
`z = -1`, à escala de quem passa por baixo, em vez de toda no fundo a
`z = -3`. Mecânicas por nível pelo contrato §2: N12 elevador, N13
engrenagens, N14 updraft, N15 plataformas ilusórias. Medido na região:
ilusórias 0→20, rodas 0→6, elevadores 0→3, sinos 4→6. Vyrak sem lore de
dragão nas 6 línguas.

**O QUE PRECISA DE DECISÃO (é o que bloqueia):** dar à Torre dos Ecos as
mecânicas do cânone reescreve **doze níveis de outras regiões** (20, 41-45,
51, 56-60). Nenhum regride — suite, 100 jornadas, alcance e `spawn_livre`
passam todos — mas ninguém pediu para lhes mexer. Está no `PRIORIDADES.md`.

**TRÊS ARMADILHAS QUE CUSTARAM VOLTAS:**

1. O `_rng` do gerador é **um só e sequencial**: um sorteio a mais na
   decoração desloca tudo e muda a geometria de TODAS as regiões. A
   decoração passou a ter `_rng_deco` próprio, e o `_coluna_fundo` continua
   a consumir os mesmos quatro sorteios pela mesma ordem. Dentro dele, o
   `return` da textura que não carrega tem de ficar ANTES dos outros três.
2. `nivel_de_estreia()` devolve **0** para uma câmara fora da tabela. Tirar
   `serras`/`gravidade`/`torre` dos sítios onde estreavam pô-las
   disponíveis desde o nível 1 — a Floresta ganhou salas de serra e o
   `spawn_livre` acusou "respawn não permite salto (8 px)", risco de
   softlock. Daí o `DESBLOQUEIO_FIXO`.
3. Não basta comparar QUE câmaras ficam disponíveis: o gerador **duplica o
   peso** de uma câmara nos 8 níveis a seguir à estreia. A primeira análise
   só comparou conjuntos, deu "zero afectados", e o nível 23 mudou 1372
   linhas na mesma. O modelo tem de ser o multiconjunto pesado.

**Método:** `tools/baseline_geometria.gd` (novo) grava o que é funcional e
ignora o decorativo — é assim que se prova "0 alterações" numa jornada
procedural. Congela `Engine.time_scale` senão as serras, que se movem,
dão diffs de ruído. E só vale depois de um `--import` estável: a primeira
baseline foi tirada logo após um `git stash` e deu falso positivo.

**Por fazer:** auditoria de fidelidade eixo a eixo contra as pranchas
APPROVED; legibilidade (há massa quase preta em todos os cinco níveis);
onde é que `serras` e `gravidade` passam a ser apresentadas.

---

## Região III — Torre dos Ecos: identidade canónica (19 set 2026)

Branch `claude/region03-completion-pass`, a partir de `origin/master @
17b90e28` (HEAD real, confirmado por `git fetch`).
Relatório: [`docs/implementation/region_03_completion_pass.md`](implementation/region_03_completion_pass.md).
Auditoria: [`docs/implementation/region_03_audit.md`](implementation/region_03_audit.md).
Contrato: [`REGION03_VISUAL_GAMEPLAY_CONTRACT.md`](art_direction/regions/region_03/REGION03_VISUAL_GAMEPLAY_CONTRACT.md).

**Estado: PARTIAL. NÃO integrado em `master`** — ainda há fidelidade LOW
(ver abaixo), e o briefing só manda integrar em PASS.

### O que custou a descobrir (guardar isto)

- **O `.tscn` de um nível é só a sala do chefe.** O grosso é uma jornada
  procedural que o `nivel_com_chefe.gd` prepende, gerada por tabelas do
  `gerador_corredor.gd` indexadas pela REGIÃO. Tornar uma região canónica
  é sobretudo mexer nessas tabelas. Medir só o `.tscn` engana — foi assim
  que a baseline deu "1 inimigo por nível".
- **As chaves i18n `level.nXX` usam o índice 0-BASED.** O N11 é
  `level.n10`. Mexer em `level.n11` a pensar no N11 estraga o **N12**.
- **`ASSINATURA[2]` era `"vento"`** — a assinatura da Região II — quando o
  cânone diz que o elemento central da Torre dos Ecos são os sinos.
- **`fundo_pack = "montanhas"` tem uma camada `trees.png` de pinheiros.**
  Os cinco níveis renderizavam como floresta ao entardecer. Só se viu com
  PNGs reais (Xvfb); o headless não desenha nada e não prova aparência.
- **O primeiro pack `torre_ecos` não se via**: escolhi tons de pedra com
  praticamente a mesma luminância do céu (34,40,74 contra 28,34,68) e a
  `dessaturar`/`tinta` da Atmosfera ainda os baixava. De noite, quem dá
  leitura a uma torre gótica é a **janela acesa**.
- **`for x in (a, b)` é sintaxe de Python.** Em GDScript dá
  "Expected closing )" — e os parênteses estão equilibrados, o que faz
  perder tempo a procurar outra coisa. O erro aponta a linha certa.
- **Recortar inimigos desta prancha ≠ Região II.** Aqui cada sprite vive
  numa CAIXA com borda e as caixas tocam-se: não há uma coluna vazia na
  tira toda, e o corte por corridas devolve sempre "1 corrida para 5
  estados". Partir em cinco partes iguais também não chega (o erro
  acumula e a 5.ª caixa apanha metade do vizinho). O que funciona é
  cortar pelos **centros das legendas** por baixo de cada caixa.
- **As cenas dos cinco níveis são `authored` no `data/level_manifest.json`**,
  logo protegidas do `--promote` em massa do `afinar_atmosfera.py`. A
  promoção tem de ser deliberada e só para elas.

### Hipóteses DESCARTADAS (não voltar a gastar tempo)

- *"O N12 tem ecrã preto"* — **não reproduz.** Carrega com `exit=0` e o
  frame renderizado tem terreno, parallax e luz. Não se criou regressão
  para um bug que não existe.
- *"O Sino Vivo é uma mecânica do N11"* — **é o chefe do N11**
  (`ChefeSinoVivo.tscn`). E é canónico: um chefe-sino numa torre de sinos.
  Preservado, só passou a guardião.
- *"O bot mede a dificuldade da região"* — **não mede.** 0 de 30
  concluídos, mas o mesmo bot faz 0 de 4 na Região II (controlo corrido de
  propósito). A porta só abre com o chefe morto e o bot não mata chefes.
  Em N11–N14 ele **não morre, encrava** (0 mortes, ~172 encravamentos):
  é navegação, não dificuldade. O bot foi feito para a Região II, que é
  horizontal; esta é vertical.

### Números medidos

- Baseline: as 5 salas eram quase clones (4 com a mesma extensão x
  200–1065, mesma largura 2600, 16 plataformas). N15 era a mais pobre
  (13 plataformas, sem ator regional).
- Inimigos canónicos antes: **0 de 10**. Depois: **10 de 10**, e num
  nível gerado o inimigo de assinatura domina (8 Acólitos no N11, 11
  Construtos no N13, 12 Sinos no N15).
- Vyrak sai a **142×176 px = 4,00× a Koliani** (a prancha pede ~4×).
- Bot: **0 frames com NaN e 0 crashes em ~5 h de jogo simulado**.
- N15 é o outlier do bot: 53 mortes e 48 saltos falhados por run, contra
  0 nos outros quatro. **Queda punitiva** — sinal para o playtest humano.

### O que ficou por fazer, e porquê

1. **Arquitetura e props no primeiro plano** (os dois eixos ainda LOW). A
   camada jogável continua a ser corredor de tijolo liso; o cânone pede
   arcos, colunas, vitrais e estátuas *onde se anda*. Está no fundo, não
   no jogo. Mexe no `_deco` por bioma e no vocabulário de câmaras.
2. **Mecânicas por nível**: oscilantes (N11), elevadores e plataformas que
   desaparecem (N12), engrenagens e alavancas (N13), updraft e rotativas
   (N14), plataformas ilusórias (N15). É isto que dá papéis distintos aos
   cinco em vez de só paletas distintas.
3. **Bot com navegação vertical** — sem ele não há medição de progressão
   de dificuldade nesta região.
4. Guardiões N12–N14 continuam Aerion/Voltaris/Sacerdotisa. O vento do N12
   e a lua do N14 têm apoio no cânone; o **raio do N13 não** (o N13
   canónico é de engrenagens).
5. Build Windows, PWA e integração em `master`: só depois de 1 e 2.

### Ambiente desta sessão (Linux, não Windows)

Não havia Godot no PATH nem máquina Windows. Ficou em
`tools/correr_testes.sh` o equivalente Linux do `.ps1` (isola o `user://`
por `XDG_DATA_HOME` e confirma o SHA256 do save real) e em
`tools/capturar_regiao3.sh` a captura de PNGs reais sobre **Xvfb** — que
é a única forma de provar aparência, porque o headless não desenha.
Os templates de exportação Windows **existem** (cross-export é possível),
mas não se gerou build: não há PASS para publicar.

---

## DEV MODE sem PIN + o bug do ESPAÇO a sério (19 set 2026)

Branch `claude/remove-devmode-pin`, a partir de `origin/master @ 7a4e586a`
(HEAD real, confirmado por `git fetch` — não o de relatórios antigos).
Relatório: [`docs/execution_devmode_sem_pin.md`](execution_devmode_sem_pin.md).
Versão **0.18.17 → 0.18.18**.

- **O PIN saiu por inteiro.** Carregar no DEV MODE do menu entra já; o
  `--devmode` também. Não há painel, campo nem validação. A porta a sério
  continua a ser o interruptor de build `koliani/qa/entrada_dev` — é ele que
  decide se o botão existe, e é ele que fica `false` numa build de loja.
- **Não houve compatibilidade de saves a tratar, e é um facto medido, não
  uma suposição:** o PIN era `const PIN_DEV := "0980"` no código e
  `estado_jogo.gd` nunca o conheceu. Saves antigos lêem-se na mesma.
- **`Frontend9H.painel_liso` e o som `ui_negado` NÃO foram removidos** —
  parecem órfãos depois de tirar o painel, mas continuam a ser usados pela
  Pausa e pelos controlos de toque. Verificado antes de apagar.

**O ACHADO, e é o que interessa guardar: o bug do ESPAÇO não estava
corrigido.** `7a4e586a` está certa no que faz (o botão deixou mesmo de ficar
com o foco) mas atacou o caminho errado. Medido em janela real:

    QA DEV: foco depois de fechar o selector = NINGUEM
    ERROR: o salto 1 trocou de cena -- a barra Dev morreu

Causa: `dev_barra.gd` monta o `SeletorNiveis` no `_ready` dentro de um painel
apenas ESCONDIDO; em Godot `visible = false` cala o `_gui_input` mas **não**
o `_unhandled_input`; `seletor_niveis.gd:790` trata lá `ui_accept` →
`escolhido` → `_ir_para()` → troca de cena. O ESPAÇO é `saltar` E
`ui_accept`, e saltar não consome o evento. Cada salto em DEV MODE
confirmava um nível no selector invisível. **Nem era preciso ter clicado no
botão.**

**Duas armadilhas de método, que custaram voltas:**

1. **Desligar o painel-pai não chega.** O `SeletorNiveis` põe-se a si
   próprio em `PROCESS_MODE_ALWAYS`, e `ALWAYS` ignora de propósito o estado
   dos antepassados. É preciso desligar o **selector**. A primeira tentativa
   desligou só o painel e a suite continuou vermelha.
2. **O teste antigo não podia apanhar isto.** Exigia que o PAINEL não
   ficasse visível, e o nível recarregava sem o painel alguma vez aparecer:
   passava com o bug vivo. Agora vigia-se o SINAL `escolhido`. Prova do
   ponto cego: com `dev_barra.gd` revertido, falha **só** a asserção nova.
3. **Ler código não chegava.** Isto só apareceu porque se foi ver numa
   janela real (`tools/qa_dev_sem_pin.gd`, Xvfb + OpenGL3), com rato e
   teclado a sério. O harness fica no repo.

**Testes:** bateria de 21 (suite + 12 harnesses + 9 verificadores do CI) a
0 falhas, com `XDG_DATA_HOME` isolado. Baseline antes de mexer: 22 corridos,
1 falha — o `run_dev_runtime_9h16`, que faz `assert("9h16" in
user_data_dir)` e precisa de uma pasta de utilizador dedicada; é condição de
ambiente, não regressão.

**Save real intacto:** tudo correu com `XDG_DATA_HOME` isolado; este
contentor nem sequer tem o `progresso.json` do Paulo.

---

## A2 em produção — master, Windows e PWA (18 set 2026)

- **A integração entrou em `master` como `9740a24d`** (local == `origin/master`).
  Os commits seguintes desta execução são só documentação e metadados de
  import; `docs/**` está fora do `exclude_filter` dos presets, portanto o
  payload de jogo publicado continua a ser o de `9740a24d`. O CI republica o
  Pages e o Release `win-latest` a CADA push, sempre a partir do SHA desse
  commit — produção segue o master sozinha. A integração foi
  **fast-forward puro** a partir de `e665da0b`: 37 commits, 0 conflitos, 0
  commits perdidos — `e665da0b` era exactamente o merge-base, portanto entrou
  a cadeia toda (sistema de vento → N08 planeio → Guardião dos Céus →
  Super-Process A → A2), não só o último commit.
- **Testes em master:** suite + 8 harnesses + 9 verificadores do CI, todos
  exit 0, com o `user://` isolado por `XDG_DATA_HOME`. O CI (run #478) repetiu
  a mesma bateria e passou: testes, Web, Windows e Android verdes.
- **Windows:** `build/windows/Koliani.exe` (197 MB, v0.18.16) exportado do
  master com o preset "Windows Desktop". **Não há Windows neste contentor**
  (nem wine), por isso o `.exe` não foi aberto aqui: o que se validou foi o
  CONTEÚDO empacotado, extraindo o `.pck` de dentro do `.exe` e correndo-o
  com `--main-pack` (menu + N06-N10, 0 erros; também com janela real via
  Xvfb + OpenGL3). Quem abre o executável em Windows é o Paulo. O canal
  público está actualizado: Release `win-latest` com o build do `9740a24d`.
- **PWA:** o CI publicou no GitHub Pages — deployment `6533456718`, SHA
  `9740a24d`, estado `success`, URL `https://paulogomesextp.github.io/koliani/`
  (o anterior era `e665da0b`). **A URL pública não foi aberta daqui**: a
  política de rede deste contentor bloqueia `github.io` e o blob dos
  artifacts. O que se validou foi o mesmo bundle exportado do master, servido
  em localhost e carregado em Chromium: título "Koliani", canvas 1280x720,
  `index.manifest.json` ligado, service worker activo, menu a desenhar com
  v0.18.16 (`docs/playtests/producao_a2/pwa_menu_master_9740a24d.png`).
- **Prova de que Windows e PWA são a mesma versão:** é o **SHA do commit**
  registado pelo próprio GitHub — o artifact `github-pages` e o
  `koliani-windows` do run #478 têm ambos `head_sha = 9740a24d`, o deployment
  do Pages é desse SHA, e o corpo do Release `win-latest` nomeia-o.
  **Armadilha de método (custou uma volta):** o `.pck` **não é reproduzível
  byte a byte** entre exportações. Duas exportações seguidas do MESMO commit
  dão pck do mesmo tamanho mas com ~2 MB diferentes, todos na cauda
  (`uid_cache.bin`, `global_script_class_cache`, tabela de ficheiros), porque
  dependem do estado do import. A primeira medição deu SHA igual só porque as
  duas exportações partilharam a cache de import — não serve de prova de
  alinhamento. **E não exportar o Web para `build/web/` antes do Windows:**
  o `exclude_filter` dos presets não exclui `build/**`, portanto os PNGs do
  export Web entram no `.exe` seguinte (+911 KB medidos).
- **Save real intacto:** tudo correu com `XDG_DATA_HOME` isolado e este
  contentor nem sequer tem `progresso.json`; o save do Paulo está na máquina
  dele e não foi tocado.
- **Nada de jogo mudou nesta execução** — só integração, builds e documentos.

---

## Remediação de fidelidade da Região II — Super-Process A2 (18 set 2026)

- Branch `claude/region02-fidelity-remediation` @ `77b4c891`, a partir de
  `claude/region02-humanlike-bot-playtest` @ `1bfda76f`. Relatório completo:
  [`docs/implementation/region_02_fidelity_remediation.md`](implementation/region_02_fidelity_remediation.md).
  **A2 está FECHADO:** GATE 1, GATE 2, Fases 3-7 e 9, mais o relatório final
  ([`docs/execution_a2_regiao02_fidelidade.md`](execution_a2_regiao02_fidelidade.md))
  e a varredura dos harnesses — `run_tests.tscn`, `run_boss_guardiao_ceus` e
  os 7 avulso (`run_movement_camera_4a`, `run_wind_system`,
  `run_glide_region02`, `run_region02_wind_shapes`, `run_level_session_tests`,
  `run_save_foundation_tests`, `run_progression_ids_tests`) **todos verdes**,
  com o `user://` isolado por `XDG_DATA_HOME`. **O que sobra é decisão do
  Paulo** — os pontos A-D no topo do `PRIORIDADES.md`: lua de sangue, os
  quatro guardiões intermédios, as outras cinco criaturas canónicas, a
  mordida do N10 e o contraste.

- **O NaN do N06 não era da Região II.** `_hitstop()` punha
  `Engine.time_scale = 0.0`; o Godot passa `physics_step * time_scale` ao
  servidor de física, portanto o passo ia a ZERO, e a integração de um
  `AnimatableBody2D` com `sync_to_physics` calcula-lhe a velocidade por
  `motion / passo` = **0/0 = NaN**. Quem está EM CIMA herda-a em
  `move_and_slide()`. Valia para as **nove** plataformas `AnimatableBody2D`
  do jogo. Correcção: `Koliani.HITSTOP_ESCALA_TEMPO = 0.0005`.
  Prova: teste determinístico + **0 frames NaN em 30 runs** (antes dava em
  ~1 de cada 4 runs do N06).

- **O pico do N10 não era o salto, era a consequência.** 200,7 → **18,5
  mortes/1000 px**; o dano por run subiu de 58,8 para 214, ou seja o nível
  passou a FERIR em vez de executar. Rajada a acabar onde o chão acaba +
  laje `ChaoResgate` (x 540-880). De x=880 para a direita o ácido continua
  vivo de propósito.

- **0 dos 10 inimigos canónicos → 5 espécies extraídas da prancha** e
  100% dos inimigos comuns da região canónicos. `attack.png` é novo: o
  `demonio_base.gd` já pedia `"attack"` no telégrafo mas ninguém a montava.

- **Ambiente:** mar de nuvens de volta (realces 39-53% → 57-68%; a textura
  foi pintada a 51,9%), 25 props canónicos (8 de chão) contra 12 (3, dois de
  cemitério), folhagem carmesim no lábio do terreno, fundo do abismo com
  véus de nuvem.

- **Guardião:** asas ABERTAS E ERGUIDAS (arco +12 e asas 40% mais longas),
  3,59x em largura e 2,46x em altura — dentro das duas bandas do contrato.
  A paleta ciano PROIBIDA saiu dos cinco sítios onde estava.

### Armadilhas de método que custaram a descobrir

1. As runs do bot **não são determinísticas entre processos** — a seed só
   governa o RNG do bot, o jogo usa `randf()` global. O NaN dava em ~1 de
   cada 4 runs e 2 runs não chegaram para o apanhar; foram precisas 12.
2. `x_max` **não mede progresso num poço vertical**. O bot passou a gravar
   `y_min`/`y_spawn`.
3. Um chão largo no fundo de uma subida vertical é um **atractor de
   navegação**: a laje de 580 px apagou as mortes todas mas fez o bot subir
   menos (204 px contra 497) e nenhuma run voltou a chegar ao chefe. Uma
   saliência estreita (260 px) **não resolve, muda a borda de sítio** (73,5%
   das mortes passaram para x≈900).
4. O ganho de brilho de uma camada de parallax **não pode ir dobrado na
   `tinta`** do `fundo_bioma.gdshader`: essa uniform é `source_color` e fica
   grampeada a 1.0. Subiu 11% em vez de 60%.
5. O véu da `superficie_textura` amostrava de y=0 e a `nuvens.png` tem o céu
   ESCURO no topo — trazia céu, ou seja nada. Daí o `veu_origem`.
6. **Levantar as asas de uma ave troca largura por altura**, e como o jogo
   escala o chefe pela ALTURA, a largura em jogo cai com o rácio da
   silhueta. A tentativa anterior falhou por alargar sem levantar.
7. `gerar_terreno_regiao02.py` fazia `cat["desfiladeiro"] = cat["torres"]` —
   era a origem exacta dos props de cemitério E uma bomba-relógio: bastava
   correr o script e os props canónicos desapareciam.

### Ambiente (nada disto sobrevive ao contentor)

Godot 4.7.2 e os export templates não vêm no contentor — os comandos para os
ir buscar, correr a suite com o `user://` isolado (`XDG_DATA_HOME`), tirar
fotografias (Xvfb + OpenGL3) e exportar o Windows estão em "Como retomar
(ambiente)" no relatório. A build de Windows está feita e verificada em
`builds/region02-final/`, **mas fora do Git e num contentor efémero**: chega
ao Paulo pelo CI, que corre em cada push.

---

## Playtest human-like por bot + audit de fidelidade da Região II (18 set 2026)

- Branch `claude/region02-humanlike-bot-playtest`, a partir de
  `claude/region02-completion-pass` @ `53f4d448`. **NADA de jogo mudou**:
  nem cenas, nem chefes, nem assets, nem física, nem balanceamento.
  Relatório: [`docs/playtests/region_02_bot_humanlike_playtest.md`](playtests/region_02_bot_humanlike_playtest.md).
  Dados: `region_02_bot_humanlike_data.json`. Provas (45 fotografias reais do
  jogo + fichas de comparação): `docs/playtests/region_02_visual_evidence/`.

- **Método que não existia e agora existe.** `tools/bot_humano_r2.gd` é um
  piloto human-like (3 perfis de reacção, hesitação, erro de temporização,
  saltos curtos, dashes desperdiçados) que navega por um grafo das
  superfícies do nível. `tools/shot_r2.gd` fotografa por X/Y **ou por FASE
  nomeada da máquina de estados do chefe**. `tools/recon_r2.gd` inventaria o
  nível JÁ CONSTRUÍDO — sem isto não se sabe nada dos níveis com jornada
  procedural, porque ler o `.tscn` só mostra a sala final.
  `tools/correr_bot_r2.sh` corre 54 runs (6 níveis x 3 perfis x 3 seeds).
  Correm em Linux/headless com `--fixed-fps 60` a ~16x tempo real; as fotos
  precisam de Xvfb + OpenGL3 (llvmpipe).

- **As duas perguntas em aberto do contrato do Guardião têm resposta.**
  (1) As asas **não** tapam a Koliani na arena — mas por má razão: elas ficam
  coladas ao corpo, portanto os 235 px não custam jogabilidade **e também não
  fazem o trabalho de silhueta para que existem**. (2) As asas não darem dano
  **lê-se bem**: o chefe paira acima da cabeça dela e as asas nunca chegam ao
  chão onde ela está.

- **O que o audit prova, com números.** A escala do Guardião CUMPRE o contrato
  (2,46x altura, 3,6x largura). O que não cumpre é a silhueta: as asas estão
  espalmadas, e só o `walk` as levanta num V raso. O projéctil das PENAS
  CORTANTES é `Color(0.72,0.92,1.0)` = **#B8EBFF** — a paleta ciano que L3 do
  contrato **proíbe explicitamente** (`chefe_guardiao_dos_ceus.gd:399`).
  Censo de inimigos medido em jogo: **0 dos 10 canónicos** em N06-N10 (são
  esqueleto/chort/orc/imp/mastim/goblin; `ESP_REGIAO[1]` ainda diz
  `# II Prisão`). O mar de nuvens **está lá** e chega ao ecrã com **10-24% de
  luminância contra os 53% com que foi pintado** — não é asset em falta, é
  tratamento. A bandeira da região é lavanda (rgb 107·98·147), não carmesim.

- **Fidelidade:** N06 LOW · N07 MEDIUM · N08 MEDIUM · N09 LOW · N10 (arena)
  LOW. Guardiões: Golem LOW, Vigia MEDIUM, Feiticeira MEDIUM, Espectros
  MEDIUM, Guardião dos Céus MEDIUM (rig) / LOW (chefe+arena). **Nenhum
  FAILED** — nada parece placeholder nem outra direcção artística.

- **A prova que fecha a discussão** é o N05 (Região I) fotografado com o mesmo
  harness ao lado do N06: a densidade que a prancha da Região II pede já
  existe no nível anterior. Não é limitação técnica.

- **Gameplay, medido:** o N10 é **200,7 mortes/1000 px** contra 4,7-32,1 nos
  outros — e mata de vida cheia (58,8 de dano médio contra 3 465-6 604). 76%
  das mortes do nível num único ponto (x≈700), 99% na faixa x=600-820, todas
  no ácido. O N08 é o melhor nível da região (100% de progresso nas 9 runs,
  462 s de 900 a planar). A curva de dificuldade N06→N10 é 6,3 · 4,9 · 23,8 ·
  4,7 · 200,7 — não é uma curva.

- **Armadilhas de método que custaram a descobrir** (estão nos comentários do
  bot, mas ficam aqui porque valem para qualquer bot futuro):
  1. um botão carregado com `Input.action_press` e nunca largado faz o
     `is_action_just_pressed` da Koliani disparar **uma vez só** — os chefes
     acabavam as runs com a vida cheia;
  2. `_fase != 0` **não** serve para "o combate começou": das cinco máquinas
     de estado da região só quatro começam em `DORME` (a do Golem começa em
     `APROXIMA`). O critério uniforme é a distância;
  3. `EXPOSTA` (Feiticeira) e `RECUPERA` (Golem) são a mesma janela que
     `EXPOSTO` — sem isso "ataques evitados" dava 0 em dois encontros;
  4. nenhuma plataforma é atravessável: um grafo de navegação que permita
     saltar para uma plataforma que esteja **inteiramente por cima** manda o
     bot bater na barriga dela, sempre;
  5. as correntes ascendentes mudam o que é alcançável **e** o bot tem de
     FICAR na coluna (mover-se para o alvo tira-o dela a meio);
  6. comparar perfis exige normalizar por progresso — quem hesita mais avança
     menos e morre menos, e parece melhor.

- **Fica por fazer / a investigar:** em 3 das 9 runs do N06 a posição da
  Koliani foi **NaN** em pelo menos um frame (o acumulador `x_max` ficou
  `null`; as posições de morte são todas finitas). Não foi diagnosticado —
  estava fora do âmbito, mas não devia acontecer. E o bot encrava à entrada
  da sala do N07 em x≈590-610 nos perfis `normal`/`experiente`: é falhanço
  dele, e esses 6 runs não se usam para traversal.

## Super-Process A — encontros do meio da Região II (18 set 2026)

- Branch `claude/region02-completion-pass`, HEAD a seguir a este trabalho.
  Worktree `C:/Projetos/koliani-region02-complete`. Detalhe na secção
  **8-bis** de `docs/implementation/region_02_completion_pass.md`.
- **A última contradição canónica da Região II fechou.** A região já era o
  Desfiladeiro dos Ventos, mas pelo caminho o jogador encontrava O
  Carcereiro, Ignivar, A Dama da Guilhotina e Os Irmãos Condenados —
  quatro CHEFES da Prisão dos Condenados, a disputar o lugar do Guardião
  dos Céus.
- **Trocar os nomes não chegava: a identidade estava DESENHADA.** Chave no
  lugar da cabeça, bigorna e coroa de chamas, lâmina do cadafalso, corrente
  de ferro. Os quatro foram redesenhados no motor de arte dos chefes, cada
  um a traduzir um arquétipo do `enemy_gameplay_pack.png` aprovado:
  Golem das Falésias (GOLEM AÉREO), Vigia do Desfiladeiro (TORRE VIGIA),
  Feiticeira dos Ventos (MAGO DO VENTO), Espectros Gémeos (ESPECTRO DAS
  RUÍNAS).
- **Gameplay intacto nos quatro.** Nenhum número de vida, dano, telégrafo
  ou alcance mexeu. O N08 está LOCKED e por isso até o *gait* ficou
  `"golpe"` em vez de `"magia"`, para o CORTE bater no mesmo sítio.
- **`boss.*` → `guard.*`**: a Região II passou de cinco chefes a UM. O
  carrossel diz "Guardião:" nos quatro e "Chefe:" só no N10.
- Restos que só se viam a ler as cenas e saíram: as plataformas do N06
  chamavam-se `Cela1/2/3`; o N07 tinha uma poça `Lava` com `brasas = true`
  a subir por baixo da arena.
- **Deixado de fora de propósito** (e comentado nos ficheiros): os nomes
  dos `.tscn` e as `class_name`. Mexer neles toca em uids, saves,
  checkpoints e manifesto às vésperas do playtest, e o jogador nunca os lê.
  Também o equipamento `gear.*_do_carcereiro` — não é da região e o `id`
  está gravado nos saves.
- **Armadilha de método:** a primeira versão do teste lia os nomes por
  `Textos.t()`. Não serve — o `t()` cai para o inglês quando a chave falta,
  por isso passava com a chave ausente em cinco dos seis ficheiros. Lê o
  JSON direto. A asserção foi **provada a morder** (repus `boss.*` no
  índice 5 → 3 falhas).
- Duas passagens de desenho que só a folha de contacto apanhou: o catavento
  da Vigia na coroa lia-se como **diadema** (foi para as costas; a cabeça
  levou parapeito ameado) e as abas do manto da Feiticeira liam-se como
  **orelhas**, depois como painéis a flutuar (ficaram em flâmula).
- **VERDE**: suite completa, `run_glide_region02` (N08) e
  `run_region02_wind_shapes`.
- **POR FAZER**, e é só isto: (1) **ver os quatro a correr no Godot real** —
  a validação foi por folha de contacto dos frames, à escala de jogo com a
  câmara a mexer pode ler-se diferente; (2) **regenerar a build Windows**
  `Koliani-Region02-Test.exe` e os launchers N06–N10. Depois disso:
  **PLAYTEST HUMANO DA REGIÃO II**. Não iniciar a Região III.

---

## Super-Process A — Região II fecha, TÉCNICO COMPLETO (17 set 2026)

- Branch `claude/region02-completion-pass` (base
  `claude/region02-n10-guardian-skies@d7af0c3d`), worktree
  `C:/Projetos/koliani-region02-complete`. Detalhe:
  `docs/implementation/region_02_completion_pass.md`.
- **Gate A PASS**: a prancha aprovada chegava para definir o Guardião sem
  inventar nada. Contrato em
  `docs/art_direction/regions/region_02/GUARDIAO_DOS_CEUS_VISUAL_CONTRACT.md`.
  Descoberta útil: os **três ataques da luta já eram canónicos** — LÂMINA =
  PENAS CORTANTES, COMANDO DO VENTO = CHAMADA DOS VENTOS, QUEDA = MERGULHO.
  A luta não teve de mudar nada.
- **Guardião**: deixa de ser o rig de pack `monge_celeste` (humanoide de
  manto ciano) e passa a ser um **corvídeo colossal** desenhado pelo motor
  dos chefes — plano de corpo `ave` novo, que reusa o gait do `alado`. 235 ×
  160 px = 2,46 × a Koliani. Colisão inalterada; só as âncoras visuais
  mudaram (lâmina ← ombro da asa, pó ← garras, núcleo ← cabeça).
- **Passe de arte N06–N10**: bioma e pack próprios (`desfiladeiro`),
  compostos de material CC0 que já cá estava, recolorido para a paleta
  amostrada da prancha. Três ferramentas novas. A `CascaMasmorra` troca de
  TEXTURA e não de tiles — no `masmorra.tres` cada tile traz a sua colisão.
- **Bug das zonas de vento CORRIGIDO** (estava aberto desde o Process 10). O
  Godot partilha sub-recursos entre instâncias da mesma PackedScene: a
  última zona a arrancar impunha a forma às outras. No N09 duas zonas
  corriam a 300×220 em vez de 680×240 e 650×270.
- **Texto alinhado**: os cinco nomes de nível eram de prisão e as pistas do
  N10 falavam do Primeiro Prisioneiro. Corrigido nos 6 idiomas sem mexer no
  arco (a Aurora continua a passar por aqui, o Zeriko continua a mandar
  forjar-lhe grilhões — muda o sítio, não a história).
- **Art safety provado**: `tools/geometria_regiao02.tscn` fotografa os 248
  nós de gameplay das cinco cenas e compara antes/depois — 0 diferenças. O
  comparador foi testado com uma mutação de 16 px.
- ARMADILHA que custou a descobrir: **a suite mede a silhueta dos chefes
  pelas CONSTANTES do `ChefeBase`**, e por isso media mal qualquer chefe com
  `_altura_alvo`/`_largura_alvo` próprios. Depois de corrigida mostrou o
  problema a sério: o Guardião saía com 324 px de largo contra os 560 px da
  plataforma da arena. Ficou em 235.
- ARMADILHA nº2, e a mais util: **o que o jogador LE^ no ecra nao estava
  coberto por teste nenhum**. A HUD dizia "PRISON OF THE DAMNED" por cima
  de "The Eternal Winds", e so' apareceu ao exportar a build e fotografar.
  A entrada da Regiao II em `EstadoJogo.REGIOES` continuava a ser a da
  prisao (nome, chave i18n, cor). Exportar e fotografar CEDO, nao no fim.
- Falta: **HUMAN PLAYTEST da Região II inteira**. Ver §7 do relatório — em
  especial, as zonas de vento de N06/N07/N09 passam a ter o tamanho que
  sempre estiveram desenhadas a ter, e nunca foram jogadas assim.
- **Região III NÃO iniciada.**

## Process 12 — N10 exame final + Guardião dos Céus, TÉCNICO COMPLETO (17 set 2026)

- Branch `claude/region02-n10-guardian-skies` (base `a5825950`), worktree
  `C:/Projetos/koliani-region02-n10`. Detalhe:
  `docs/implementation/region_02_n10_guardian_skies.md`.
- `A_Cela_Zero.tscn` (mesma cena/UID) passou a exame da Região II:
  `corredor = false`, 3 zonas de vento (a favor / corrente / contra pulsada)
  + `VentoArena` parada que o chefe comanda. Topologia, elite, ácido,
  fogueiras, porta e `ColProjetil` intactos.
- Chefe novo `ChefeGuardiaoDosCeus` (rig `monge_celeste`) substitui o
  Primeiro Prisioneiro: LÂMINA / COMANDO DO VENTO / QUEDA, todos com
  telégrafo próprio, `EXPOSTO` entre ataques (nunca é inatingível) e fase 2
  aos 50% que encadeia em vez de inflar números.
- `wind_zone.gd` só ganhou `definir_direcao()` (aditivo). O bug da forma de
  colisão partilhada continua ABERTO e fora do âmbito: no N10 cada zona tem
  forma própria na cena, como no N08.
- Provas: suite, harness próprio do chefe (`tests/run_boss_guardiao_ceus.tscn`),
  glide N08, Movement+Camera, os 8 verificadores do CI + spawn livre, e o
  nível aberto no Godot real. 3 mutações provaram que os testes mordem.
- ARMADILHA que custou a descobrir: **em GDScript as lambdas capturam por
  VALOR** -- a bandeira do sinal `derrotado` numa variável local fazia o
  harness jurar que o chefe não morria. Usar Array/membro.
- Falta: HUMAN PLAYTEST do N10; passe canónico de arte da Região II
  (Process 13).

## Process 11 — N08 Ilhas Suspensas + planar contextual, COMPLETE / APPROVED (17 set 2026)

- **HUMAN PLAYTEST na build Windows: APPROVED** (aprovacao humana do Paulo,
  nao so' automatizada), sobre `claude/region02-n08-glide@7e1007df`.
- Testes automaticos PASS; Koliani canonica PASS; planar contextual,
  `WindZone` (updraft/tailwind/headwind) e checkpoints APPROVED.
- Gameplay do Process 11 **LOCKED** para esta fase. Nao ha' merge em master
  nesta execucao.
- Trabalho futuro, NAO bloqueia o Process 11:
  1. art pass canonico da Regiao II por fazer;
  2. validacao manual completa device/PWA nao e' precisa para fechar o
     gameplay (o playtest humano no Windows foi aprovado);
  3. `WindZone` com forma de colisao partilhada afeta N06/N07/N09, NAO o N08
     (cada zona do N08 tem forma propria);
  4. `tools/correr_testes.ps1` rebenta no Windows PowerShell 5.1 -- tratar a
     parte.
- Seguinte: Process 12 — N10 Final Exam + Guardiao dos Ceus (a espera do
  briefing).

## Process 11 — sync da Koliani canónica antes do playtest, PASS (17 set 2026)

- Branch `claude/region02-n08-glide` publicada em
  `origin/claude/region02-n08-glide` (o upstream antigo
  `origin/codex/region02-wind-system` NÃO recebeu push).
- `cccd7a43` preserva o Process 11; cherry-pick de `7ff1dbaf` (flags no N08,
  auto-merge limpo) e `5f22e374` (flags nos 94 níveis + teste
  `test_koliani_canonica_niveis.gd`; conflito só no `run_tests.gd`, ficaram
  os três conjuntos: glide, N08 e canónica).
- N08 em runtime (Godot real, janela): Golden Set ativo, RUN `run_final`
  10 fr / 13,333 fps / loop, escala 1, offset (0,-18), colisão 20×44;
  1 `ZonaPlanar`, 3 `WindZone` (as três empurram), 3 fogueiras, chefe e porta;
  planar ativo sem habilidade permanente; respawn deixa ventos=0/a_planar=false.
- Provas: suite completa OK (save real intacto), glide A–O, WindZone A–L,
  Movement+Camera 4A, smoke N08 240/600, rota N08 chega à arena, alcance 100
  níveis 0 portas inalcançáveis. Mutação: sem as flags no N08 a suite dá
  exatamente 2 falhas (L008).
- Armadilhas: `tools/correr_testes.ps1` rebenta no PowerShell 5.1 ao primeiro
  WARNING no stderr (`ErrorActionPreference=Stop`) -- replicar o APPDATA
  isolado à mão ou usar `pwsh`. O `--import` gera `.translation` a partir dos
  CSV em `docs/` -- são artefactos, não commitar.
- Falta: HUMAN PLAYTEST do N08 (checklist em
  `docs/implementation/region_02_n08_glide.md`), device/PWA, art pass.

## Process 11 — N08 Ilhas Suspensas + planar contextual, PARTIAL (17 set 2026)

- Worktree `C:/Projetos/koliani-region02-n08`, branch
  `claude/region02-n08-glide`, base `c41c19ed`
  (`origin/codex/region02-wind-system`). **Sem commit/push**: o estado é
  PARTIAL só por falta de playtest humano (regra do briefing).
- Planar **contextual** (`ZonaPlanar`), não habilidade: a permanente
  `"planar"` continua a abrir no N63. Mesmo input e física do N63 (segurar
  saltar, queda presa a 190 px/s, nunca sobe). Suspenso durante o dano;
  limpo no respawn e ao sair da zona/cena.
- N08 (`Corredor_das_Execucoes.tscn`, nome/UID mantidos): sala à mão sem
  jornada, ilhas suspensas, corrente ascendente, rajada a favor contínua e
  rajada contra pulsada; guilhotinas/serra/quebra/ácido/Casca removidos;
  spawn, 3 fogueiras, porta, chefe, elite e `projetil` preservados.
- Provas: suite completa OK (save real intacto), glide A–O no motor, WindZone
  A–L, Movement+Camera 4A, smoke N08, os 8 verificadores do CI TUDO OK,
  alcance 100 níveis sem portas inalcançáveis. `tools/verifica_rota_n08.gd`
  chega à arena com a Koliani real sem Dev, com morte provocada e respawn
  limpo na fogueira do meio. Contrafactual: sem planar falham 3/9 vãos; o de
  vento a favor (640 px) só se faz a planar; o dash aéreo encurta 2 vãos.
- **Defeito anterior descoberto (não corrigido):** todas as `WindZone` de uma
  cena partilham a mesma forma e colidem com o tamanho da última. N09 tem duas
  zonas a 300×220 em vez de 680×240/650×270. No N08 cada zona tem forma
  própria. Correção = lote próprio + novo playtest de N06/N07/N09.
- Falta: HUMAN PLAYTEST (checklist em
  `docs/implementation/region_02_n08_glide.md`) e DEVICE VALIDATION. Depois,
  commit `feat: add n08 suspended islands and glide` + push. Não iniciar o
  Process 12.

## Process 10B — fecho por playtest humano, PASS (16 set 2026)

- Precheck confirmado em `codex/region02-wind-system`: alterações do Process
  10 preservadas; apenas N06, N07 e N09 alterados entre os níveis; N08/N10
  intactos e nenhum ficheiro não relacionado identificado.
- Cenas exatas: `scenes/levels/Prisao_dos_Condenados.tscn` (N06),
  `scenes/levels/Fornalha_dos_Pecadores.tscn` (N07) e
  `scenes/levels/Ala_dos_Mortos.tscn` (N09).
- O host atual não tem executável Godot 4.7.2 localizável no `PATH`, pastas
  usuais, registo ou Steam, e este worktree não contém build Windows. Não foi
  possível repetir testes nem abrir o jogo nesta sessão.
- Estado de progressão exigido: save normal após concluir N05, com `dash`
  adquirido legitimamente; `--nivel=6` não ativa `modo_dev`, mas preserva as
  habilidades do save e não deve ser usado sobre um save contaminado por Dev.
- Confirmação do Game Master: N06/N07/N09 PASS sem problemas e sem cheats;
  checkpoint/morte/respawn PASS nos três; combate/knockback de N09 PASS; ponto
  perto de `x≈954` PASS. O playtest usou condições normais de progressão.
- Gate humano fechado: **PASS**. Processo 10 concluído; não iniciar Process 11
  nesta execução.

## Process 10 — vento aplicado a N06/N07/N09, PASS (16 set 2026)

- Worktree `C:/Users/sarac/Koliani/koliani_region02`, branch
  `codex/region02-wind-system`, base `6005177f`.
- N06 recebeu duas rajadas horizontais pulsadas; N07, três updrafts contínuos
  na rota alta; N09, três zonas pulsadas com direção/intensidade alternadas.
  Checkpoints e arenas ficaram fora das zonas. N08/N10 não foram alterados.
- `WindZone` tem agora guia mecânico procedural opcional, sincronizado com o
  pulso; não é arte/SFX final.
- Godot 4.7.2: WindZone A–L PASS, Movement+Camera PASS, suite completa PASS,
  três smokes PASS e alcance estático às três portas PASS. O bot anti-softlock
  chegou às portas (N06 14 s, N07 14 s, N09 39 s), mas usa `modo_dev` e todas
  as habilidades; N09 teve paragem resolvida de 26,1 s perto de `x=954`.
- Estado **PASS**: percurso humano sem debug/cheats confirmado em N06/N07/N09;
  checkpoint/respawn, fairness, combate/knockback e `x≈954` validados.
- Documento: `docs/implementation/region_02_wind_level_integration.md`.
- Gate de commit/push satisfeito. Não iniciar Process 11 nesta execução.

## Process 09 — sistema reutilizável de vento da Região II (16 set 2026)

- Worktree `C:/Users/sarac/Koliani/koliani_region02`, branch
  `codex/region02-wind-system`, base `4e3ea01e`.
- Criados `WindZone.tscn`/`wind_zone.gd`: direção, intensidade, tamanho,
  velocidade máxima, contínuo/pulsado, multiplicador variável e sinais para
  feedback. Vento chega à Koliani como força externa por origem, com exit,
  TTL defensivo e composição de múltiplas zonas.
- Física base não foi retunada; respawn limpa velocidade/vento. N06–N10 não
  foram alterados; glide N08, boss N10, inimigos, UI, SFX e arte ficaram fora.
- Godot 4.7.2: targeted A–L PASS, Movement+Camera 4A PASS, suite completa PASS;
  save real intacto. Avisos de recursos retidos no shutdown imediato também
  aparecem no targeted baseline de Movement+Camera e não causaram falhas.
- Documento: `docs/implementation/region_02_wind_system.md`.
- Próximo passo: aplicar e afinar zonas em N06/N07/N09 num processo separado,
  com validação de níveis e `HUMAN PLAYTEST REQUIRED`. Não iniciar Process 10.

## Regra permanente — Windows e PWA sincronizados (14 set 2026)

- Pedido do GM: todas as entregas atualizam Windows e PWA juntos, mesmo commit e versão. Regra acrescentada a AGENTS.md; o CI existente exporta ambos em cada push master.
- Entrega pública atual: v0.18.16, commit 230f122d; testes, export Windows, export Web e Pages confirmados success no run 34787609185.
- Próximo lote: exportar, validar e entregar ambas as plataformas; não publicar o áudio 9H.20 incompleto. Validação mobile requer DEVICE VALIDATION REQUIRED.
## PWA — Dev Mode com PIN 0980 (13 set 2026)

- Publicação v0.18.16 em cópia isolada `codex/pwa-dev-pin-0980`, base estável `6251bf5b`. Apenas o acesso Dev concluído e traduções foram adicionados; áudio 9H.20 não publicado.
- Botão no menu principal abre campo mascarado; PIN 0980 ativa o sandbox Dev. Cancelar/Esc e PIN inválido mantêm a campanha fora do Dev.
- Suite `tools/correr_testes.ps1` EXIT 0; teste dirigido `tests/run_dev_pin.gd` EXIT 0; export Web EXIT 0. Navegador local confirmou modal, rejeição e entrada no Dev L1.
- QA usou userdata isolada. Nenhuma migração, limpeza de dados PWA ou alteração do save GM.
- Próximo: publicação GitHub Pages pelo workflow existente e escuta/validação no dispositivo do GM. DEVICE VALIDATION REQUIRED no telemóvel; rebuild de áudio permanece pendente no worktree original.
## 9H.19 — auditoria de áudio, gate de produção bloqueado (13 set 2026)

- HEAD inicial `1d1fd7c1`, branch `codex/9h16-l1-perfection`, worktree `C:\Projetos\koliani-9h16`. Relatório: `docs/execution_9h19_audio_vertical_slice.md`.
- 259 amostras em cinco packs locais creditados CC0; madeira/metal/ar/vidro/passos encontrados. Adequação profissional não estabelecida por escuta; não afirmar ausência total de fontes nem qualidade por métricas.
- `PROFESSIONAL PRODUCTION ASSET REQUIRED`. `MAIN MENU MUSIC — PROFESSIONAL PRODUCTION ASSET REQUIRED`. Brief musical de produção registado; nenhum candidato, A/B novo, integração, alteração de mixer ou export 9H.19.
- Baseline/final pelo arnês isolado EXIT 0; save real intacto. Logs `C:\Temp\koliani_9h19_baseline.log` e `C:\Temp\koliani_9h19_final.log`; retenção de recursos à saída já existente no baseline.
- INCOMPLETE. Próximo: seleção auditiva das fontes locais e gravações/stems com licença pública clara; retomar B só depois do gate. HUMAN LISTEN REQUIRED: YES. Apenas documentação de auditoria/brief concluída; B–F pendentes.

## 9H.18 — a corrida (NATIVE ART REQUIRED) e os SFX pela FORMA (13 set 2026)

- Relatorio: [`execution_9h18_corrida_e_sfx.md`](execution_9h18_corrida_e_sfx.md).
  Commits: `27fc583f` (corrida), `673a2c6f` (SFX). Build **v0.18.12**.
- **A CORRIDA E' ARTE QUE FALTA, nao afinacao -- confirmado por um crivo
  novo e independente.** `tools/validar_run_nativo_9h18.py` nao mede a
  abertura das pernas (um ciclo de UMA perna abre e fecha na mesma): segue
  o pe' de tras e o da frente nos frames de contacto e mede o chao que CADA
  um percorre. Folha golden: contactos 4/10, tras **7 px**, frente 29 px,
  razao **0,24**. Medido a` parte: um pe' vive entre -26 e -2 da anca e o
  outro entre +13 e +27, e **nenhum atravessa a anca em frame nenhum**.
  - Procuradas TODAS as fontes (7 rigs, work/, master package, historico,
    15 ramos). So' o **piloto 5G** passa (11/12, 22/20 px, razao 0,91) --
    e e' o desenho ANTERIOR ao Golden (cabelo roxo, saia de chama, sem
    lenco). Trocar por ele muda a personagem.
  - O master package tem uma linha `RUN (12 FRAMES)` em
    `05_KOLIANI_IDLE_RUN_CLEAN_v1_1.png`, citada pela propria manifesta do
    Golden -- mas e' folha de APRESENTACAO (xadrez pintado em RGB, sem
    alfa) e do mesmo desenho anterior.
  - Candidatos da 9H.15: 2 px de varrimento. Confirmam-se rejeitados.
  - **DROP-IN PRONTO**: `docs/spec_run_nativo_koliani.md` (contrato do
    ficheiro + as 6 poses obrigatorias) e
    `koliani.gd::_substituir_run_por_nativo()` -- largar os PNG em
    `assets/sprites/koliani_golden_set/frames/run_native/`, reimportar, e o
    jogo troca sozinho com o fps recalculado para o ciclo dar 0,75 s.
  - ARMADILHA: a `Koliani.tscn` em bruto **nao** vem com o Golden Set --
    cai no rig `shadowblade` (5 frames, que reprova ainda pior). O Golden
    e' ligado nivel a nivel. Fotografar a cena em bruto fotografa o rig
    errado, e foi o que aconteceu a` primeira.
- **OS SFX FALHAVAM NA FORMA, e ninguem a tinha medido.** A 9H.13B ja'
  tinha resolvido a sonoridade e mesmo assim o GM disse que continuavam
  maus. `tools/auditar_sfx_9h18.py` (tempo ate' ao pico, cauda, crista,
  bandas) mostrou: `ui_mover` 160 ms com 109 de cauda; `ui_confirmar` 560
  com 417; `carrossel` com o pico so' aos **136 ms**; `ataque_forte` com o
  pico aos **70 ms** (o remate chega TARDE ao golpe); e `ataque` 15/75/11
  contra `acerto` 20/64/16 -- **golpear e acertar tinham o mesmo timbre**.
  Os tres passos eram o mesmo som.
  - `tools/gerar_sfx_9h18.py` refaz **22 ficheiros** com ALVOS DE FORMA por
    evento e **verifica-se a si proprio** (PASSA/FALHA por som, sai != 0 se
    algum ficar fora). Os 22 passam. Motor novo: filtro ressonante,
    objecto percutido com modos inarmonicos, grao.
  - Depois: navegar sao 55 ms (eram 160), confirmar 230 (eram 560), todos
    os picos nos primeiros ms, e os alvos de banda do golpe (4/46/50) e do
    acerto (43/43/14) **nao se sobrepoem de proposito**.
  - ARMADILHA 1: **um unico fluxo de aleatorio fazia os ficheiros mudarem
    uns com os outros** -- mexer no `acerto` deslocava o ruido do `ataque`.
    Semente por ficheiro, com `zlib.crc32` (o `hash()` de string em Python
    e' aleatorizado por processo).
  - ARMADILHA 2: **o grao espalhado por igual punha o PICO a 10-18 ms do
    inicio.** Passou a denso no impacto e ralo depois.
  - **MOBILE-FIRST manda no tecto de grave**: um altifalante de telemovel
    nao da' nada abaixo de ~300 Hz, logo 80% da energia em grave e' energia
    que o jogador nunca ouve. Varios sons subiram o fundamental.
  - VARIACAO: `ui_mover` e `acerto` saem em 3 amostras e o `Som.toca()`
    sorteia sem repetir a anterior. Nenhum sitio que os chama mudou.
  - MISTURA: **nao se mexeu**. O `opcoes.json` do Paulo (efeitos 0,40,
    musica 0,45) e' dele e continua a mandar.
- **PHASE C: teclado de sons no modo Dev, tecla S** (`scripts/dev_sons.gd`).
  ~40 eventos a um toque, com os volumes e tons REAIS de cada sitio. Quem
  fez os sons nao os ouve -- **HUMAN LISTEN REQUIRED**.
- **QA INDEPENDENTE (Phase E) confirmou, e mediu mais duas coisas**: o pe' de
  tras **toca o chao em 8 dos 10 frames** (nunca faz fase aerea), e nos
  frames 3 e 10 os DOIS pes estao plantados em split largo ao mesmo tempo --
  pose que nao existe numa corrida. Notas: corrida **3/10**, transicoes
  **3/10**, audio NOT ASSESSABLE. "Nao esta' bom para build comercial."
- **O POP DO TRAVAO E DA ATERRAGEM FOI CORRIGIDO** (o QA apanhou-o): medido
  em largura de silhueta, o `run_brake` ia do frame mais aberto do ciclo
  (57 px) para o `idle` (37) num unico frame de 71 ms, e o `land` de 49 para
  37. Sem frames novos -- os MESMOS frames escolhidos por largura, a fechar
  por degraus: travao 57-51-48-46-43-37 e aterragem 49-44-38-37, degrau
  maximo **6 px** em vez de 20. A aterragem passou tambem a ler-se como
  bate-encolhe-levanta (entra o `crouch`).
- O `turn` continua indistinguivel de continuar a correr (sao os frames
  0-3 do `run`) e o `run_start` nao tem antecipacao. Isso precisa de arte,
  como o ciclo.
- POR FAZER:
  * **desenhar a corrida** (spec pronta, cano pronto);
  * sons ainda por refazer: `porta` (1000 ms, pico aos 236 ms),
    `transicao`, `apanhar`, `selo`, `conquista`, `projetil`, `investida`,
    `chefe_cai`, `dano`, `bloqueio`, `morte_koliani`, `raiz_*`,
    `plataforma_surge` e os 21 `mob_*` -- todos ja' auditados;
  * 13 `.ogg` legados estao no repo mas **inertes** (o catalogo aponta aos
    `.wav`): acerto, ataque, ataque_forte, bloqueio, dano, dash,
    morte_koliani, passo1..3, rolamento, selo, agarrar.
- BUILD: `C:/Projetos/koliani/build/windows/Koliani.exe`, release
  **v0.18.13**, 205 736 040 bytes, SHA256
  `E6E801E25F7CBF9304D110643E50A0B9B7DF6811F09E7BD46FC592F65869124E`.
  Suite EXIT 0 por `tools/correr_testes.ps1`; save do Paulo verificado por
  SHA256 antes e depois, intacto.

## 9H.17 CONTINUATION — Regiao I toda em Hybrid; QA jogado PARCIAL (13 set 2026)

- Relatorio: [`execution_9h17_continuation.md`](execution_9h17_continuation.md).
  Commits: `24b9eef8` (Hybrid L3/L4/L5), `ca4fb0e1` (seguranca do Novo Jogo),
  `3a39300b` (isolamento dos testes). Build **v0.18.11**, smoke PASS.
- **NENHUM NIVEL CERTIFICADO.** A Koliani atravessou o 1-1 do spawn ate' a`
  arena do chefe (a barra do GHORAK apareceu) e numa das corridas chegou a
  meio com 5/5 vidas -- mas **o Ghorak nao foi morto**, logo nao ha' prova de
  atravessar um nivel de ponta a ponta. L1..L5 continuam SEM PASS.
- **INPUT REAL PROVADO**: `PostMessage(WM_KEYDOWN/KEYUP)` para o handle da
  janela entrega teclas ao Godot **sem foco**, no 2.o monitor **e ate'
  minimizada**. O ecra principal fica livre.
  - ARMADILHA: o salto e' de ALTURA VARIAVEL (`koliani.gd` passa
    `is_action_pressed` alem do `just_pressed`). Toques de 90 ms davam o
    salto MINIMO -- era isso que travava a Koliani, nao o desenho do nivel.
    Com 330 ms segurados o percurso abre-se.
  - ARMADILHA: em `pt-PT`, `[double]"0.5"` da' **5**. Os instantes dos saltos
    iam parar ao fim do percurso. Parsing em cultura invariante.
  - O padrao que resultou foi avancar **aos saltos curtos com paragem entre
    eles**; correr a direito leva-a ao pantano. Para o CHEFE as cegas nao
    converge -- faz falta um laco observacao-accao muito mais apertado.
- **A SUITE DE TESTES ESCREVIA NO SAVE REAL.** A essencia do Paulo foi
  239 -> 0 depois de duas corridas de `run_tests.tscn` (nao foi o playtest).
  O autoload `EstadoJogo` esta' vivo na cena de testes. Correr SEMPRE por
  `tools/correr_testes.ps1`, que isola o `user://` por %APPDATA% e confirma
  por SHA256 que o save ficou igual. Save do GM reposto e verificado.
- **BASELINE DO BRIEFING ERRADA**: dizia 26 falhas conhecidas; eram **2**, na
  suite PRINCIPAL, no mesmo teste (`teste_execution_9c_kit_ambiente_regiao1`).
  Corrigidas. **Suite agora EXIT 0.**
- O `serve()` do Hybrid tambem liga o CORPO ORGANICO da plataforma
  (`plataforma.gd`) -- um interruptor explicava fundo E plataformas.
- O landmark Heart Tree do L5 vivia na coluna pintada do panorama
  (`_montar_heart_tree()` e' um no' VAZIO): trocar o fundo apagava-o. Recriado
  como peca propria.
- POR FAZER: QA visual do L2 em percurso jogado; trace jogado do salto duplo
  (codigo diz `HABILIDADE_DO_CHEFE = {4: "salto_duplo"}`); agente
  independente de QA com notas /10.

## 9H.17 — a Regiao I faz-se toda com salto SIMPLES (13 set 2026)

- PHASE CURRENT: **A, B, C, D, E, G, H, I2, I3, J FECHADAS. F NAO REPRODUZ.
  I1 e' NATIVE ART REQUIRED.** Relatorio:
  [`execution_9h17_regiao1_mobilidade.md`](execution_9h17_regiao1_mobilidade.md).
  Commits: ab4fd0b6 (A/B/E), daad0bae (C), b0cf4a15 + 5fe9b799 (D/F),
  2551f41a (G/H), 9cb56e6d (I3), 918662a0 (I2), c40ccc23 (v0.18.9).
- **A CAUSA DO BLOQUEIO DO 1-3 NAO ERA DAQUELE SITIO.** A Jornada construia a
  espinha com `SUBIDA_MAX = 104 px` -- um salto MAIS o salto duplo -- e os
  cinco niveis da Regiao I tem a Jornada ligada. Medida a envolvente do salto
  simples com a FISICA DO JOGO (`tests/run_alcance_9h17.tscn`, agarrar-borda
  incluido): subida 0 -> vao 140 | 64 -> 110 | 72 -> 80 | 80 -> 60 |
  **88 -> impossivel a qualquer vao**. O tecto fisico esta' entre 80 e 88.
  Os 104 estavam acima dele.
- **O SALTO DUPLO NAO SE GANHAVA EM SITIO NENHUM DA CAMPANHA.** As
  `HABILIDADES_INICIAIS` estao vazias e nao ha' um unico `Coletavel` com
  `habilidade_id = "salto_duplo"` nos 100 niveis. Agora:
  `NivelComChefe.HABILIDADE_DO_CHEFE = {4: "salto_duplo"}` -- progressao, e
  nao saque (o bau sorteia, e um sorteio nao pode decidir se o jogo continua
  jogavel). Vai por `desbloquear_habilidade`, que avisa a HUD e GRAVA.
- `SUBIDA_SIMPLES = 60` nos niveis 1-5, do CONTRATO da campanha e nao do save
  da maquina (o modo Dev da' tudo). Mais `_garantir_alcance()`: a Jornada
  prometia na propria documentacao que "cada plataforma esta' ao alcance de
  salto da anterior", mas era uma INTENCAO espalhada por dezenas de sitios
  que escolhiam o passo em x e a subida em y sem se falarem. E faltava-lhe a
  regra "nao se sobe estando debaixo da barriga da plataforma" -- a mesma que
  ja' custou dois niveis com o chefe inacessivel.
- Salas a` mao: o poco do N3, a escada do tronco do N4 e OS DOIS ramos da
  bifurcacao do N2 subiam 80-108 px. Desceram para 59-64 com a mesma forma.
- ARMADILHAS DE METODO:
  1. **limite fisico e alvo de desenho sao coisas diferentes** -- com uma
     margem de 15% como porteiro o N1 reprovava por 2 px num salto que se faz;
  2. o `verifica_alcance.gd` DESLIGA a jornada (mede a sala a` mao) e nao
     serve para este contrato -- dai o `verifica_mobilidade_9h17.gd`;
  3. um crivo estatico mente de duas maneiras, e as duas apareceram: nao
     conhecia as plataformas FLUTUANTES (a rota baixa do N2 e' feita delas)
     nem os TRAMPOLINS (o poco do N3 tem um no fundo, em -3523,494);
  4. quando o gerador e o crivo discordam, o errado e' quase sempre o MODELO,
     nao a geometria.
- **D: a entrada Dev existia, o que nao existia era VISIVEL.** Estava atras de
  `OS.is_debug_build()` e a build do Game Master e' de release. Pior: o
  `main.gd` so' punha a BARRA Dev com a mesma condicao -- `--devmode` entrava
  sem FlyMode nem troca de nivel. Portao unico
  `EstadoJogo.entrada_dev_disponivel()` + `koliani/qa/entrada_dev`, e o botao
  foi para o canto inferior esquerdo. PROVADO na build de release v0.18.9.
- **F NAO REPRODUZ**: o mapa tem P e Escape na accao `pausa`, e duas provas de
  runtime com teclas a serio mostram o Escape a abrir -- em isolamento e no
  jogo montado. Falta confirmar com MAOS na build.
- **G/H: o L2 vivia de um panorama de 952x247 esticado.** Nao ha' fonte nativa
  maior: o `_hd_x4` e' esse ficheiro reamostrado (erro 3,01/255; energia de
  bordos 1533 -> 74), as camadas de 1920 sao declaradas pelo proprio manifesto
  como ampliadas, e a autoridade da regiao inteira e' UMA prancha de 1536x1024.
  **NATIVE ART REQUIRED -- L2 BACKGROUND HD.** O que se fez: o passe Hybrid
  passou a servir o perfil 2, com arranjo e paleta de pantano.
- **TRES PECAS DE PRODUCAO ESTAVAM NO REPO POR LIGAR**: `plataforma.png`
  (290x275) resolve a I3 inteira -- em tres fatias, com vegetacao em cima e
  barriga de raiz por baixo; a mesma peca nas flutuantes; e `corrupcao.png`
  (199x290) da' leito pintado ao pantano.
- POR FAZER / DECIDIR:
  * **KOLIANI RUN -- NATIVE ART REQUIRED** (confirmado por medicao propria:
    abertura das pernas 38,40,39,38,38,53,44,46,43,56 -- nunca fecha);
  * **REGION I GROUND/SWAMP -- NATIVE ART REQUIRED** so' na FAIXA de
    superficie; o leito ja' esta'. A origem da faixa palida NAO se identificou
    nesta execucao: nao e' o corpo do liquido (baixar-lhe o alfa nao a mexeu)
    nem a `Faixa` nem o `Rebordo`;
  * as 2 falhas que restam sao da Execution 9C sobre o L1 usar o kit 9C e as
    camadas da 08 -- ambas superadas pelo Hybrid, ambas decisao do Golden.
- SUITE: baseline eram 26 falhas, **ficaram 2**, zero novas. As 24 que cairam
  nao foram caladas -- 18 eram a regra da 9H.7B a apanhar as pecas do Hybrid
  (aplicada; o L1 mudou 0,89/255 e ficou 3% MAIS nitido), 5 eram eixos de luz
  em blend aditivo (sem grelha para conservar) e 1 era a moldura de vinhas.
- BUILD: `C:/Projetos/koliani/build/windows/Koliani.exe`, release **v0.18.9**,
  205 766 688 bytes, SHA256
  `b1f81051309b34e031efd63612b080aa10a5a07487e069c337b0d6f09a39954d`.
- **NEXT ACTION: o QA jogado.** O agente independente foi lancado e morreu no
  limite de sessao antes de concluir. Falta: percurso normal L1->L2->L3 sem
  modo Dev a provar o 1-3 com salto simples, olhar o fundo e as plataformas do
  L2 em jogo, Escape na pausa com maos, e o passe Dev (FlyMode, 1/20/50/100,
  isolamento do save).

### QA jogado (9H.17) -- NAO SE FEZ, e porque

O agente independente de QA foi lancado duas vezes. O 1.o morreu no limite de
sessao. O 2.o correu ate' ao fim mas **nao conseguiu enviar input**: todas as
chamadas de tecla foram rejeitadas com "user interrupt" (o teclado real do
Paulo estava em uso concorrente), e o `type` executa sem erro mas nao move
nada -- um platformer precisa de estado de tecla PREMIDA, nao de um evento de
texto. Chegou ao menu, NOVO JOGO e ao seletor com o rato, e carregou o 1-1,
com a personagem parada.

**POR PROVAR A JOGAR, e e' o primeiro item da proxima sessao:**
travessia 1-1 -> 1-2 -> 1-3 com salto SIMPLES, Escape na pausa com maos,
combate, e o passe Dev (FlyMode, 1/20/50/100, isolamento do save). Precisa da
maquina livre ou de maos humanas.

**O QUE ELE APANHOU MESMO (verificado por mim depois):** os niveis 1-3, 1-4 e
1-5 continuam na apresentacao ANTERIOR a esta execucao -- plataformas
rectangulares com a faixa de musgo, emendas rectangulares no fundo, parede de
tijolo. O passe Hybrid so' serve os perfis 1 e 2 (`L1Hybrid.serve`), e por
isso a correcao das fases G/H/I3 cobriu o L1 e o L2 e deixou os outros tres
para tras -- o corte visual dentro da Regiao I nao desapareceu, MUDOU DE
SITIO. Medido: L3 vs L4 = 66% de pixeis praticamente iguais, L4 vs L5 e
L3 vs L5 = 35% (o agente disse "quase identicos pixel a pixel", o que e'
exagerado: e' o mesmo MOLDE e o mesmo ESTILO, nao a mesma sala).
**NAO SE ESTENDEU DE PROPOSITO** -- o briefing congelou "L2-L5 REMASTER
STARTED: NO" e isto muda o aspecto de tres niveis. E' decisao do Game Master,
e e' barata: uma linha em `L1Hybrid.serve()`.

Outros dois achados dele, ambos PRE-EXISTENTES a esta execucao:
`WARNING: 76 ObjectDB instances were leaked at exit` em todas as corridas, e o
processo que fica vivo uns segundos depois de a janela fechar.


## 9H.16 — fases B a F executadas (13 set 2026)

- PHASE CURRENT: **B CLOSED, C/D/E entregues e provadas, F PARCIAL.**
  Relatorio completo: [`execution_9h16_l1_golden.md`](execution_9h16_l1_golden.md).
  Commits: 8d815dba (C), b3fa7160 (D), 0fd5f8e4 (E), 1b149f7e (v0.18.8).
- **PHASE B CLOSED com QA NATIVO.** O Game Master autorizou foco temporario
  e foi isso que destrancou a fase. Dev entry, ARMAS 20/20, ARMADURAS 10/10,
  x99 vidas, FlyMode nas 4 direcoes com OFF a repor o movimento, e
  L1->L20->L50->L100->L1 sem crash. ISOLAMENTO DO SAVE PROVEN: `progresso.json`
  byte a byte identico (`d302def8f79b…`) depois de sessao Dev completa +
  reinicio do processo; seletor normal manteve 1-3/1-4/1-5 trancados;
  `CONTINUAR` carregou o progresso legitimo. Nao foi preciso corrigir nada.
- **C**: as ajudas viviam CENTRADAS (`(larg - size.x) * 0.5`, y>=160) -- em
  1280x720 em cima da Koliani. Passaram ao canto superior-esquerdo com travao
  para nao invadirem os 34% centrais; placa 560->380 px; toast deixou de poder
  ter 1112 px de largura; sem banners grandes em combate (espera ate' 6 s).
  Provado: toast (24,94) 305x81, placa (24,94) 360x126.
- **D**: a causa de "combate basico" estava medida -- os 4 golpes davam o
  MESMO dano e o "recuo" era `global_position.x += dir * 8` (teletransporte
  de 8 px). Agora 0,85x/1,0x/1,25x/1,9x de dano, 90/150/230/470 px/s de
  recuo FISICO, o 3.o ATORDOA 0,38 s e o 4.o SANGRA e levanta do chao. A raiz
  da floresta passou a espetar INIMIGOS (mascara 2->6): com o recuo novo o
  remate atira o bicho ~90 px e a mecanica-assinatura liga-se ao combate.
- **E**: remates organicos nas pontas das plataformas com arte JA' PRODUZIDA
  e por usar (`terrain_hd/raizes.png`/`rocha.png`) -- mosaico de rectangulo
  dava rectangulo. E os tres sons que faltavam: `raiz_perigo.gd` e
  `plataforma_ritmada.gd` tinham ZERO chamadas a `Som.`.
- ARMADILHAS que custaram a descobrir:
  1. `receber_dano(..., forca_recuo)` obriga a alinhar os **30 overrides** dos
     chefes, senao o `main.gd` nao compila;
  2. **nao se conduz um bench de combo pelo teclado** -- os intervalos do
     arnes passam a `JANELA_COMBO` (0,42 s) e a cadeia reinicia a meio, pelo
     que cada corrida mede passos diferentes. Fixar `_combo_passo`;
  3. o modo CENARIO da `RaizPerigo` tem a irrupcao dentro do `_loop_auto` e
     **nao passa por `_irromper()`** -- por isso as raizes ficavam mudas mesmo
     com o som ligado la';
  4. nomear `RaizPerigo`/`DemonioBase` num `--script` arrasta os autoloads e o
     proprio bench deixa de compilar em silencio (duck typing em vez disso).
- HIPOTESE DESCARTADA: a faixa palida no fundo do L1 e' o `LiquidoMortal` do
  corredor gerado (medido: triplica a luminancia, 0,038 -> 0,110, via
  `Superficie`/`Faixa`), mas trocar o veu `nevoa.png` -> `corrupcao.png` NAO
  teve efeito e foi revertido. Integracao chao/pantano: NATIVE ART REQUIRED.
- **KOLIANI RUN NATIVE ART BLOCKER confirmado por medicao**: abertura das
  pernas nos 10 frames = 38,40,39,38,38,53,44,46,43,56 (os cinco primeiros sao
  a mesma pose) e o centro de massa nunca troca de lado. Nao ha outra fonte no
  repo nem no historico.
- BUILD: `C:/Projetos/koliani/build/windows/Koliani.exe`, release v0.18.8,
  205 755 688 bytes, SHA256
  42764fe51ad46d2cd3faf2ef2c398900cb618a23c2c234f10cf470d555fcf13d.
  A anterior ficou como `Koliani-v0.18.6-humantest.exe` e a de QA da Phase B
  como `Koliani-9h16-PhaseB-dev.exe`.
- NEXT ACTION: **percurso HUMANO do L1 inteiro** (o input sintetico so' cobriu
  o primeiro terco -- nao segura duas teclas sem acorde, e o platforming
  exige-o), ouvir os SFX, e decidir os dois NATIVE ART (corrida da Koliani,
  chao/pantano). Suite: 26 falhas conhecidas, zero novas, em todas as fases.
- Nota de UX por tratar: a pausa abre com `P` mas NAO com `Escape`.
- O save legitimo do Paulo foi salvaguardado antes do QA e reposto no fim.

## 9H.16 — continuação autorizada depois de 9af93695 (13 set 2026)

- PHASE CURRENT: B INCOMPLETE; C–F não iniciadas. User autorizou usar o
  usage restante apesar do limiar anterior. Fetch executado; trabalho alheio preservado.
- COMPLETED: corrigida soma duplicada de vitalidade Dev introduzida no
  checkpoint anterior; FlyMode escolhe idle no controlo real de animações,
  preservando hurt; removida reposição legada do botão de nível no canto
  inferior esquerdo; rótulo/controlos Dev abaixo das essências, no topo direito.
- PROVEN: Vulkan RTX 5070 com input sintético em L1/L20/L50/L100 passou:
  quatro direções de voo, idle, HP correto e feedback de dano sem morte.
  Seletor Dev configurado para os 100 níveis, com nomes e sem bloqueio;
  após saída, seletor normal respeitou a fronteira legítima. Isolamento
  bytes/snapshot voltou a passar. Suite mantém 26 falhas conhecidas, zero novas.
- Captura renderer real 1280×720: C:/Temp/koliani-9h16-b2-ui.png;
  controlos Dev juntos sem sobreposição do contador de essências nesse frame.
- Build QA limpa atualizada: C:/Temp/Koliani-9h16-PhaseB-dev.exe, debug
  0.18.7, 199628400 bytes, SHA256
  25a3125a8b5ae65a49a5f28d0869b0dc7987cca51ee8b85f81281d6e5015366a.
  Smoke Dev L1 Vulkan sem erros runtime; aviso ObjectDB à saída permanece.
  Logs C:/Temp/koliani-9h16-b2-*.log; EXE principal continua preservado.
- Correção da limitação anterior: runtime Windows @oai/sky inicializado via
  node_repl está disponível. Não foi enviado input nativo: a API ativa a
  janela, em conflito com «não roubar foco» do briefing. Pergunta sobre foco
  temporário apresentada ao user, ainda sem resposta; não inferir autorização.
- REMAINING / NEXT ACTION: obter essa resposta e realizar QA no export por
  menu/seletor, skills/equipamento em uso, dano/feedback/knockback, saída,
  restart, Continuar e seletor normal. HUMAN PLAYTEST REQUIRED para o percurso
  humano; não confundir input sintético com QA integral nem fechar B.
- Usage na leitura desta continuação: 6% cinco horas / 55% semanal.

## 9H.16 — continuação: checkpoint Phase B (histórico, 13 set 2026)

- PHASE CURRENT: B INCOMPLETE. A fechada em 9eda04e0 conforme briefing;
  notas antigas de diagnóstico abaixo são históricas, não reabrem A.
- COMPLETED: lote técnico de isolamento Dev em memória; guardar/guardar_em
  bloqueados; snapshot profundo e saída sem escrever/restaurar disco;
  melhorias no máximo, recursos QA, HP Dev cheio com feedback normal de dano;
  UI Dev no canto superior direito e FlyMode ON/OFF nos seis catálogos.
- PROVEN: prova de bytes/snapshot, completion/boss/equipamento temporários,
  checkpoint runtime e bloqueios normais intactos em save sintético. Runtime
  Vulkan RTX 5070 com input sintético: L1/L20/L50/L100, spawn/voo/dano PASS.
  Suite: mesmas 26 falhas conhecidas, zero novas falhas de teste.
- REMAINING: B1–B7 integral no export (entrada pelo botão, seletor 1–100,
  skills/equipamento em uso, quatro direções de voo, feedback/knockback,
  saída/restart/Continuar/seletor normal). Não declarar Phase B concluída.
- Build QA separada: C:/Temp/Koliani-9h16-PhaseB-dev.exe, debug 0.18.7,
  199628496 bytes, SHA256
  919c15fd969ad1ada35f632de713a87e1e2d4956bde14d6be90ac78618bae078.
  Snapshot limpo de HEAD + fontes deste lote; export sem pastas de trabalho,
  smoke Dev L1 Vulkan sem erro runtime. Build Windows principal não substituída.
- Logs: C:/Temp/koliani-9h16-b-*.log. Headless nos níveis altos mostrou
  coordenadas não finitas em essencia.gd; ausentes no Vulkan. Retenções ObjectDB
  à saída ainda presentes; não investigadas fora do lote. Não afirmar zero erros.
- NEXT ACTION: retomar B no worktree C:/Projetos/koliani-9h16, rever checkpoint
  e concluir os critérios restantes antes de commit de fecho/push e Phase C.
  HUMAN PLAYTEST REQUIRED: controlo nativo Windows indisponível nesta sessão;
  input sintético/smoke não substituem o percurso humano exigido no briefing.
- C–F não iniciadas; scores e qualidade Golden NOT ASSESSABLE. L1 READY AS
  GOLDEN LEVEL: NO. Região II/L2 remaster/PWA final não iniciados; API paga não usada.
- Desenvolvimento parado perto do limite pedido (17% cinco horas / 57% semanal
  na leitura de checkpoint; consultar valores frescos na próxima sessão).

## 9H.16 — preparação e diagnóstico inicial da PHASE A (histórico)

- Branch `codex/9h16-l1-perfection`, worktree `C:/Projetos/koliani-9h16`, base obrigatória `claude/9h13b-sfx-redesign` / `f29b8f5c`. Árvore original e worktrees alheios preservados. Fetch origin master executado.
- Âmbito atual: P0 portal/física L1; conclusão exige sintoma reproduzido ou explicitamente coberto, regressões e gameplay real com input. Fases B–F não iniciadas.
- PROVEN: regressão existente `tests/run_9h12a.tscn` headless com APPDATA isolado: 0 falhas, uma entrada no portal. A suite existente também carregou scaffold L1–L5; não houve desenvolvimento desses níveis.
- PROVEN: arnês temporário em `work/9h16/portal.tscn`, limitado à travessia L1→L2, OpenGL real na RTX 5070, fixed-fps 60, input de movimento: 0 falhas, uma entrada, recompensa única, save/retoma e sessão L2. Aproximação começa 85 px antes da porta após remoção artificial do guardião; não prova combate nem percurso completo.
- Logs: `C:/Temp/koliani-9h16-import.log`, `koliani-9h16-portal-headless.log`, `koliani-9h16-real.log`, `koliani-9h16-real-errors.log`. Sem erros de runtime; avisos de Camera2D e 73/74 instâncias ObjectDB retidas à saída. Causa dos avisos não investigada nesta prova.
- QA crítico: bugs da travessia PROVEN apenas no cenário ensaiado; UI da transição PROVEN visível em captura. Combate, mecânicas L1, game feel, animações e equilíbrio de áudio NOT ASSESSABLE nesta travessia curta. Placeholders e compatibilidade Hybrid L1 NOT ASSESSABLE pela captura L2; destino L2 ainda mostra estética pixel-art legada (LIKELY incompatibilidade visual, fora de âmbito). Banner de avanço ocupa o centro da imagem e merece revisão humana de legibilidade. HUMAN PLAYTEST REQUIRED para sensação/diversão/mix; DEVICE VALIDATION REQUIRED para browser/mobile.
- Não houve alteração runtime nem commit/push de fase. Fase A INCOMPLETE: falta o sintoma P0 atual e os critérios detalhados da 9H.16. Não fabricar correção para bug não reproduzido. Arte nova: NATIVE ART REQUIRED quando faltar fonte aprovada.
- Próximo: obter briefing/sintoma atual; delimitar reprodução e critérios da PHASE A antes de editar. Retoma atualizada apenas neste worktree.

# Retomar aqui — Koliani

Índice de integração documental: [master_package_integration.md](master_package_integration.md).

Atualizado em 12 de setembro de 2026 (9H.12E).

## 9H.13/14 — SFX, corrida da Koliani e tremor do L2 (12 set 2026)

Ramo `claude/9h13-14-audio-koliani-l2` (NÃO integrado em `master`).
Relatório: [`execution_9h13_14_audio_koliani_l2.md`](execution_9h13_14_audio_koliani_l2.md).

**Feito e provado:**

- **23 SFX refeitos** (`tools/gerar_sfx_9h13.py`, tudo sintetizado aqui). O
  que conta não é a lista, é o método: três camadas (corpo grave +
  transiente de 3–8 ms + cauda com ecos) em vez de uma, nenhuma senoide a
  descoberto, e picos hierarquizados por som (`ALVO`, 0,40 a 0,92) em vez de
  normalizar tudo ao máximo — por isso nada clipa e o remate manda na
  mistura. O **combo passou a ter 4 sons próprios** (antes eram 2 samples
  com `pitch_scale`, que se lê logo como sample repetido).
- **O tremor do fundo do L2 era o `position_smoothing` do `Camera2D`.** É
  resolvido no passo de FÍSICA e o projecto tem `physics_interpolation`
  ligada; acima dos 60 Hz (o ecrã do Paulo anda a 165) as duas suavizações
  lutam e a vista avança aos saltos. Em regime permanente: **1,70 de
  dp/média com smoothing, 0,87 sem ele, 0,22 a 60 Hz**. Fora ele, o
  look-ahead é que dá o toque de câmara.
- **Cadência da corrida** passa a acompanhar a velocidade: o ciclo corria
  sempre a 13,33 fps = 0,75 s, e a 240 px/s são **180 px de chão por uma só
  passada** — o pé varria o chão.

**Armadilhas de método a não repetir** (custaram os primeiros ensaios todos):

- Medir tremor **sem `--fixed-fps` não mede nada**: com vsync desligado o
  frame dura entre 1,2 e 17,3 ms e o avanço por frame varia na mesma
  proporção — isso é correcto. Tremor é a VELOCIDADE a oscilar.
- Não se mede **encostado a uma parede** (o 1.º ensaio saiu 141 frames
  parados em 150) nem em cima de uma **inversão de marcha** (o look-ahead de
  112 px acelera a câmara de propósito).

**Duas hipóteses testadas e DESCARTADAS:**

- Refazer o atraso da câmara à mão no `_process` dá **pior** (2781 px/s de
  pico): em `_process`, `global_position` é a posição da FÍSICA e anda aos
  degraus de 60 Hz — é misturar dois relógios.
- **O `ParallaxBackground` NÃO está dessincronizado.** Medido a 165 Hz,
  `scroll_offset.x` e a origem da `canvas_transform` são iguais até à
  milésima em todos os frames. Não há `Parallax2D` a fazer.

**O que ficou por fazer, e porquê:**

1. **KOLIANI RUN NATIVE FRAMES REQUIRED.** Está medido que os 10 frames
   golden do `run` são um ciclo de **uma perna**: o pé de trás percorre 13 px
   em todo o ciclo (o da frente, 34) e **em nenhum dos 10 frames passa à
   frente**. Não há meia-passada a derivar dali. Fabricá-la por cirurgia de
   pixels parte a arte (espelhar o bloco das pernas vira as biqueiras para
   trás; transladar um membro descola-o da anca) e o briefing proíbe
   deformações. Precisa de **decisão do Game Master**.
2. **L2 NATIVE HYBRID ART REQUIRED** — mesma decisão pendente do L1 desde a
   9H.12D. Não há fonte com mais informação no repo.
3. **`build/windows/Koliani.exe` NÃO foi actualizado.** A árvore tem as
   pastas não versionadas do `work/` sujas do 9H.12E, e a 12E já tinha
   deixado escrito que exportar daqui incha o EXE (422 MB contra 347).
   Exportar de worktree limpo.
4. Os 23 sons **não foram ouvidos** — os picos estão hierarquizados por
   construção, mas o equilíbrio Music/SFX é juízo de ouvido.

**Suite:** 26 falhas, as MESMAS 26 do baseline 9H.12E. Zero falhas novas.


## 9H.12E — reparação de produção do L1 Hybrid (12 set 2026, v0.18.5)

Ramo `codex/9h12e-l1-hybrid-wip`. Autoridade FROZEN verificada antes de
mexer: `work/production_art_gate/9H12D_astra_approved/region1_l1_hybrid_visual_authority_v1.png`,
1536x1024 RGB, SHA256 `8ca9a4f4…c2df` (o produtor recusa correr se mudar).

O review independente do checkpoint `08c1cb70` apontou três P0. Os três
estão fechados; o que custou a descobrir:

- **Os rectângulos do fundo vinham do MÉTODO de recorte, não do desenho.**
  O 1º passe tirava o alfa por flood-fill do carvão a partir da borda — e as
  peças de floresta/cascata/torres/arcos vêm de painéis com **céu pintado**,
  onde esse flood-fill não apaga nada e sai o rectângulo inteiro. Agora
  `silhueta_topo()` procura, coluna a coluna, onde a pintura se afasta do céu
  dessa coluna, e `esbater_lados/baixo()` dissolvem as margens com um degradê
  ondulado. A franja preta era serrilha do flood-fill: mediana no alfa + 0,7
  px de desfoque.
- **A repetição de landmark era desnecessária desde o início.** Com parallax
  0,12 num nível de 6400 px a camada do céu só percorre 6400x0,12 = **768
  px**: uma pintura de 2048 px cobre o nível inteiro. As 9 repetições com
  `flip_h` (lua e castelo a repetir) foram substituídas por UMA instância.
  As camadas 02–05 deixaram de ser canvases 1920x950 com 60% de vazio: são
  elementos soltos pousados por `_x_camada(ref, f, mundo_x)` — a conta
  inversa do parallax, para não se pousar nada "a olho".
- **Alargar a pintura espelhando as margens DUPLICA o castelo.** O 1º ensaio
  fez isso; a asa direita trouxe as torres outra vez. A extensão passou a
  sair de uma faixa neutra (colunas 200–340: floresta e serra, sem lua nem
  castelo), escurecida por **degradê** (escurecer por igual deixava um degrau
  de valor visível) e com uma **coluna de bruma** por cima de cada emenda —
  duas pinturas encostadas deixam sempre linha, por mais igualado o valor.
- **Arrefecer musgo amarelo dá MAGENTA.** Cortar o verde a 0,76 e empurrar o
  azul a 1,10 pôs as plataformas cor-de-rosa no 1º ensaio. Quem tem de
  trabalhar é o **valor** (a rocha é o registo mais escuro do ecrã); o corte
  do verde é suave (0,88).
- **`matte_carvao` no topo da plataforma come o bloco todo.** O miolo da
  plataforma é quase tão escuro como o carvão do fundo, e o flood-fill passa
  lá para dentro: sobrava um fio de musgo a flutuar. O céu por cima do lábio
  tira-se por perfil de corte (com ruído, para a silhueta não voltar a ser
  uma aresta de tile), nunca por preenchimento.
- **`ParallaxBackground` é `CanvasLayer`, não `CanvasItem`** — o cast
  `(par as CanvasItem).visible` dava `Nil` em runtime sem parar nada.

Feito além disso: props com âncora declarada (chão/pendurado — a lanterna
pende do lábio de baixo com halo quente, em vez de flutuar no chão);
atmosfera do L1 fora do verde (`luar`, luz-chave fria, poeira violeta) na
**tabela do `afinar_atmosfera.py` E na cena**, para a ferramenta ficar
idempotente; parallax legado do perfil 1 escondido por inteiro (era ele que
punha a moita pixel-art verde no spawn); superfície do pântano com a poça de
corrupção pintada da prancha.

**Medido:** suite completa 48 falhas no `08c1cb70` -> **26** agora (A/B na
mesma árvore, com `work/` presente).

### O que ficou por fazer (9H.12E)

1. **PLAYTEST HUMANO do L1** — só houve smoke em 4 pontos do nível.
2. **26 falhas da suite**, todas contratos das execuções 9C/9H.7 que a
   direcção aprovada na 12D substituiu no L1: nomes de nós da prancha 08
   (`BackgroundApproved08`, `Camada3Distante`, `VinhasFrente`), terreno
   `kit_9c`, e 23x `9H.7B: fonte ampliada sem amostragem nítida` (as peças
   são recortes de 1536x1024 ampliados 1,0–2,0x em vez de arte nativa com o
   shader `conservar_texel`). **Decisão do Game Master:** actualizar os
   testes à direcção nova, ou produzir arte nativa.
3. **O escudo do goblin elite é verde-lima** e destoa a sério da paleta — é
   equipamento de inimigo, ficou de fora (DO NOT TOUCH desta execução).
4. O EXE saiu com 422 MB (era 347): a exportação correu na árvore de
   trabalho, que tem pastas não versionadas na raiz. Exportar de worktree
   limpo na próxima.

## 9H.12D — protótipo Hybrid Cinematic 2D do L1 (12 set 2026, v0.18.4)

Relatório: [`execution_9h12d_l1_hybrid_prototype.md`](execution_9h12d_l1_hybrid_prototype.md).
**9H.12A foi integrado primeiro** (merge `8c784fd0`) — estava só no ramo
`codex/9h12a-portal-remaster`, nunca tinha entrado em `master`.

O que custou a descobrir e não se deve re-derivar:

- **A faixa verde-oliva NÃO era a poça da cena.** A `PantanoMortal` do
  `.tscn` está a y=930/320 de altura; a faixa começava 53 px acima. A fonte
  é o **`LiquidoMortal` que o `gerador_corredor.gd` instancia** — 460 px de
  altura, nível inteiro, cor de `LIQUIDO[0]` (por REGIÃO, não por nível), o
  que explica aparecer nos cinco níveis e tomar um terço do ecrã no L4.
  Retintado para violeta de corrupção + véu de superfície.
- **O mosaico era mesmo o período do tile**, não a resolução da fonte: 30 px
  repetidos ~35x. O kit HD (`tools/gerar_terreno_hd_regiao1.py`, das pranchas
  de 1254 px que estavam a ser reduzidas a 32) sobe o período para 384/512.
- **Duas armadilhas do produtor de tiles:** (a) sem cross-fade das arestas o
  `texture_repeat` marca linha a cada período — trocava-se uma grelha de 30
  por uma de 384; (b) cortar a capa por fracção da prancha gravou-a PRETA
  (média RGB 0,2,2) porque a `platform_large_segment` tem margem
  transparente por cima — o corte tem de sair da caixa do ALFA.
- **Hipótese testada e REVERTIDA:** `PANORAMA_HD = 4.0` com a `_hd_x4`. A
  9H.7B já tinha medido o contrário e deixou-o escrito no ficheiro (o shader
  conserva os texels; o Lanczos de disco grava o desfoque antes do GPU).

**Ficou por fazer, e porquê:** o **background nativo HD** (ponto 1 do
briefing). Não existe fonte com mais informação — a prancha 08 é 1536x1024 e
o recorte do panorama é 952x247; o único 1920x1080 ilustrado da região
(`ui/frontend_9h/regioes/r01/fundo_seletor.png`) é uma composição do MESMO
panorama ampliado. Precisa de **decisão do Paulo**: arte nativa nova em 5
layers (IA original ou CC0 redistribuível num repo público). O dressing novo
e o VFX adicional também não entraram — o orçamento foi para o terreno e
para caçar a fonte real da faixa verde.


## 9H.12A — integração no master atual (12 set 2026)

- Integração já presente no master local: merge 8c784fd0, pais 71522899
  (12B/QA) e 22368973 (12A). Apenas conflito documental combinado;
  relatórios posteriores 12B/QA preservados sem alterações.
- Prova dirigida existente em Vulkan real: 0 falhas, uma entrada no portal,
  L1 concluído/L2 ativo, save recarregável, tutorial por habilidade nos seis
  idiomas, cinco perfis e seis slots vazios sem ativar nova arte/geometria.
- Export release de snapshot Git limpo; smoke EXE L1 e captura verificados.
  Visual atual preservado; HUD normal sem Jump ×2. Windows 0.18.3 atualizado
  em build/windows/Koliani.exe, 201183840 bytes, SHA256
  5d8863c1652886ef408190eeda9740407bd62ee351a1ebe9f12efe425131a81d.
- Logs curtos locais: work/9h12a_integration/. Sem erros funcionais;
  avisos Camera2D/ObjectDB no encerramento, sem investigação fora do âmbito.
- Próximo: push master e aguardar CI desta integração. 12D continua dependente
  das decisões de contrato/licenças registadas em 12B; não iniciado.
  HUMAN PLAYTEST REQUIRED para sensação/percurso; DEVICE VALIDATION REQUIRED.
- Usage atual: 38% disponível em 5h; 76% semanal.

## 9H.12B — plano do remaster da Região I (12 set 2026)

**Nada de arte foi produzido; é um plano.** Relatório:
[`execution_9h12b_regiao1_remaster_plan.md`](execution_9h12b_regiao1_remaster_plan.md).

O que custou a descobrir, e que não se deve voltar a re-derivar:

- **O desfoque do fundo não é filtro, é falta de informação na fonte.** O
  panorama é `region1_panorama_heart_tree.png` a **952x247**, desenhado a
  escala 3,0 no mundo com a câmara a 1,4 de zoom = **4,2x no ecrã**, ou seja
  **0,24 px de fonte por px de ecrã**. Os `_x2` e `_hd_x4` (3808x988) são
  reamostragens do mesmo recorte — **não acrescentam nada**. A 9H.7 tratou o
  filtro e ganhou o que havia a ganhar; o resto só sai com fonte nativa.
- **O "mosaico pixel art pobre" é o `terreno_corpo.png` de 30x75**, repetido
  ~35 vezes numa plataforma de 1050 px, sem variantes. O fundo é pintado e o
  chão é mosaico — é a discordância entre os dois que parece amadora, não
  cada um por si.
- **Já existe material híbrido no repo e está a ser deitado fora:**
  `_source/imagegen_v1/` tem 12 PNGs de **1254x1254 a 2172x724**
  (`terrain_fill`, `terrain_top`, `ruin_block`, `platform_large_segment`,
  `moss/root/corruption_overlay`...) e o `build_region_01_sprite_kit.py`
  **reduz tudo a 32/64/96 px**. O `README.md` da pasta guarda um contrato de
  prompt que pede *"pixel-art ... hard pixel clusters; no antialiasing"* —
  é esse contrato que tem de mudar primeiro.
- **Armadilha de licença:** o repo é público, portanto **commitar = redistribuir**.
  PitiIT e Pixsol proíbem redistribuição; **Pixsol proíbe ainda uso em IA**
  (rejeitado). Só CC0 (OpenGameArt DARK PLATFORMER) entra directo.
- **Hipóteses descartadas:** que o blur fosse do shader de nitidez (a 9H.7 já
  o tinha corrigido); que a cena do L2 estivesse partida (carrega **limpa**
  em headless, 240 frames, zero erros — o crash da porta está na transição
  `porta.gd:69`, `change_scene_to_file` a partir do `body_entered`).
- **Bug confirmado sem custo:** `EstadoJogo.HABILIDADES_INICIAIS` está vazio,
  mas `en.json:325` tem `hud.controls.jump` = "Jump x2" fixo na legenda.

**A seguir:** 9H.12C (bugs do GM) arranca sem aprovação. 9H.12D+ (tiles
grandes, fundo nativo) está **bloqueado** por duas decisões do Paulo —
contrato de geração e política de assets externos.

## Execution 9H.12A — portal, tutorial e scaffold Região I

- Ramo codex/9h12a-portal-remaster, base origin/master bd2aa418.
- Portal L1: entrada física real reproduziu remoção ilegal de CollisionObject2D
  durante body_entered, em headless e Vulkan. O processo não caiu nestas provas;
  comprovada a operação insegura, não uma stack de crash nativo. Correção mínima:
  conclusão diferida e guarda de reentrada, sem editar progressão/save globais.
- Teste atravessa por input normal desde antes do portal; uma entrada/recompensa,
  L1 concluído, cena/sessão L2 ativas, save recarregável. Erro físico eliminado.
- Double jump conserva design base: salto simples em L1. Tutorial usa texto
  básico sem habilidade e texto original quando salto_duplo existe. Seis idiomas
  verificados nos dois contextos; nenhum desbloqueio alterado.
- Fonte única data/regiao1/remaster.json: cinco perfis/temas/tintas/densidades,
  seis slots para fundos, terreno visual, silhuetas, atmosfera e landmarks.
  Runtime aceita texturas ilustradas/pixel e cenas VFX; rejeita colisões visuais.
  Slots novos vazios/aditivos; geometria e apresentação atuais preservadas.
- Plano por nível: patamares futuros, leitura das colunas, landmarks e dressing;
  explicitamente inativo. Não é mapa novo nem prova de jogabilidade futura.
  Contrato e instruções: docs/remaster_regiao1_9h12a.md.
- Suite completa/UI 9H.10/11 PASS; dirigido 9H.12A headless e Vulkan zero falhas;
  smoke real L1–L5 e capturas verificados. Erros de recursos/ObjectDB apenas no
  encerramento headless, como nos testes anteriores; Vulkan sem erros funcionais.
- Windows 0.18.3 exportado antes do commit, de snapshot das fontes do índice
  sem ficheiros locais alheios; manifesto incluído, 4168 entradas e zero pastas
  work/.worktrees/pacotes Master/handoff/tools/tests/docs. EXE local atualizado
  build/windows/Koliani.exe: 201183840 bytes, SHA256
  e88246a001560daf3d329f41e499b40f22def3a850f66b5458a9fbc4ed90cd6c.
  EXE release L1/L5 smoke exit 0, versão visível e logs sem erros.
- Evidência local: work/9h12a/ (before/after, testes, capturas, logs de export,
  pack_audit.json e export_source_tree.txt). Save sintético usa APPDATA isolado.
- Próximo: publicar ramo isolado e revisão/passe de arte por Claude; depois
  HUMAN PLAYTEST REQUIRED no portal e percurso. DEVICE VALIDATION REQUIRED
  para aceitação em dispositivo. Sem merge master; Região II NÃO iniciada.
- Usage consultado: 43% disponível na janela 5h; 77% semanal.

## Integração 9H.10 + 9H.11 — 12 de setembro de 2026

- Master base f45fe9a5; 9H.10 ec9a6260 integrado primeiro (0b48ba3f),
  depois 9H.11 109653fc (375931ab). Sem conflitos manuais; HUD combinado
  automaticamente, informação documental anterior conservada.
- Preservados: control strip opcional/off, remoção do label CHECKPOINT,
  margens SKILL, fila única/prioridade do diálogo, placeholders substituídos;
  Pause Frontend9H, boss bar/plate, Santuário e visual L1/L3/L5.
- Versão visível 0.18.2. Menu principal sem diff; nenhuma alteração nova
  a gameplay, colisões, física, IA, progressão, save ou bosses.
- Suite completa PASS; teste 9H.10 headless/Vulkan: zero falhas;
  smoke integrado headless/Vulkan: zero falhas em L1/L3/L5, HUD/boss,
  Pause/retoma e seis cartões do Santuário. Capturas abertas e verificadas.
- Suite baseline f45fe9a5 também PASS e reproduz o erro de um recurso em uso
  no encerramento. Warnings ObjectDB/interpolação preexistentes; nenhuma nova
  falha funcional nos testes executados. Sem reauditoria ou correção fora do lote.
- Exports release Windows/Web em worktree separada, Git limpo antes de cada
  export; apenas cache/import/UID gerados pelo Godot. Sem pastas locais copiadas.
  PCKs: 4165 entradas, zero work/.worktrees/pacotes Master/tools/tests/docs.
- EXE local atualizado em build/windows/Koliani.exe: 201168240 bytes,
  SHA256 053421084f6969780a47155309471848581de5cb462b22ba10759d19b694ebca.
  Anterior 415926168 bytes; checkout limpo eliminou a inflação do pacote.
- EXE release: menu, L1/L3/L5 e UI9F smoke com exit 0/capturas reais.
  Web/PWA: arranque WebGL, intro/Skip, menu, seletor e L1/HUD no browser desktop,
  sem erros de consola; manifest standalone/landscape e service worker exportados.
- Evidência local: work/integration_9h10_9h11/ (logs, capturas, pack_audit.json).
- Próximo gate desta publicação: push normal origin/master e confirmar CI do
  SHA final; depois STOP e Game Master playtest. HUMAN PLAYTEST REQUIRED;
  DEVICE VALIDATION REQUIRED para aceitação PWA em dispositivo. Região II NÃO.
- Usage consultado: 69% disponível na janela 5h, 81% semanal.

## Execution 9H.10 — limpeza técnica da UI

- Branch isolada `codex/9h10-ui-cleanup`, base master `f45fe9a5`; sem merge.
- Legenda de controlos só com `koliani/ui/mostrar_legenda_controlos=true`;
  por defeito desligada. Rótulo CHECKPOINT redundante removido; toast preservado.
- SKILL ajusta o estandarte à margem, sem deslocar item/colisão.
- Tutorial/toast partilham fila FIFO abaixo do cabeçalho; diálogo tem prioridade
  e suspende visibilidade/tempo do aviso. Falas ficam abaixo do cabeçalho.
- Hexágono identificado: vórtice legado da Porta funcional. Reutilizada a tira
  CC0 de Portal já creditada; Essência usa o cristal aprovado da prancha 09/HUD.
  Gema SKILL autoral e indicadores funcionais de progressão preservados.
- Teste dirigido headless e Vulkan: 0 falhas. Headless: 72 ObjectDB + 1 recurso
  ao sair, reproduzidos com HUD do master; runtime Vulkan dirigido sem erros.
- Windows/Web exportados sem erros; EXE local atualizado e smoke L1 Vulkan,
  exit 0, captura real em `work/9h10/runtime.png`. Sem deploy Web/PWA.
- Próximo passo: revisão/merge pelo Game Master. HUMAN PLAYTEST REQUIRED para
  aceitação visual; DEVICE VALIDATION REQUIRED no Web/PWA real. Região II não iniciada.
- Usage consultado: 84% disponível 5h; 83% semanal. STOP após push da branch.

## Integração 9H.7B + 9H.9 — 12 de setembro de 2026

- Ordem em master: 9H.7B (2b1d2f45) por fast-forward, depois 9H.9 (1e0c6751).
- Único conflito: inserções no topo desta retoma; ambas conservadas. Código sem conflitos.
- Validação dirigida headless Godot 4.7.2: fundo L1–L5, zero falhas;
  comum run/attack/idle e guardião run/attack/hit/idle ativos.
- Morvanna: altura mínima 24 px, 423/1400 frames ao alcance melee;
  94 frames de picada ativa. Contacto passivo nas 12 fases: zero chamadas de dano.
- Logs locais: work/integration_9h7b_9h9/{fundo,motion,contacto}.log.
  Warnings de Camera2D/interpolação e 70–71 ObjectDB no encerramento; sem erros funcionais.
- Próximo passo exclusivo: push master, verificar CI e Game Master playtest.
  HUMAN PLAYTEST REQUIRED; DEVICE VALIDATION REQUIRED para aceitação em dispositivo.
  Região II NÃO iniciada. Nenhuma execução adicional autorizada.
- Usage atual: 97 % disponível na janela de 5 h; 85 % semanal.

## Execution 9H.7B — background sharpness

- Branch isolada `codex/9h7b-background-sharpness`, base `125618b5`.
- Causa restante: HD x3/x4 era interpolação Lanczos das fontes pequenas,
  não detalhe adicional; a escala numérica ~1:1 não provava nitidez visual.
  Imports examinados: lossless, sem mipmaps e sem size limit; não é EXE antigo.
- Panorama, serra, árvores, ruínas, cascatas, cristais e foreground usam
  fontes originais com sampler que conserva texels e interpola apenas uma
  transição de um pixel do ecrã. Sem unsharp; névoa continua HD/bilinear.
  Modulate, quads, recortes, espelhos, parallax e composição preservados.
  A moldura do panorama continua excluída por clamp ao vizinho aprovado.
- Prova local no worktree `C:/Projetos/koliani-9h7b`: `work/9h7b/`
  contém `before_L1/L5.png`, `after_L1/L5.png`, `exe_L1/L5.png` e
  `exe_mobile_L5.png` (renderer Vulkan padrão). Mesma câmara a 65 %, 1280x720.
  Arestas das silhuetas mais definidas; a fonte continua limitada a 952x247.
- EXE ativo: `build/windows/Koliani-9H7B.exe`. Export sem erros;
  dirigido L1–L5: zero asserções falhadas; warnings de interpolação da câmara
  e recursos/ObjectDB no encerramento registados, sem alterações fora do scope.
- Próximo passo: integração pelo Game Master e HUMAN PLAYTEST REQUIRED
  para aceitação subjetiva da nitidez e do parallax em movimento.
- Usage consultado nesta execução: 12 % disponível na janela de 5 h,
  86 % na semanal. Sem merge em master.

## Execution 9H.9 - movimento das criaturas + luta da Morvanna

- Branch `claude/9h9-creature-motion-morvanna` (worktree proprio). NAO mergeada.
- Criaturas pareciam sprites fixos e OS FRAMES JA EXISTIAM (8 idle, 8 run, 7
  attack, 3 hit por criatura, desde a 9H.1): faltava quem os PEDISSE.
  `DemonioBase._atualizar_anim` escolhia `run` por `absf(velocity.x)` -- quem
  voa mexe-se em y (e a Morvanna por `global_position`, sem velocity), logo
  ficava em `idle` para sempre; e os chefes, a perseguir, ficavam em `run` a
  luta toda, sem pose de telegrafo, golpe ou recuperacao.
- Agora: `_velocidade_visual()` usa a velocidade TOTAL, e ha um gancho
  `_anim_desejada()`. O `ChefeBase` implementa-o de forma GENERICA pelo NOME
  da fase do enum `Fase` de cada chefe (`*_TEL` -> attack, `EXPOST*` -> hit,
  `DORME`/`DECIDE` -> automatico, fase de accao quieta -> attack) -- a mesma
  convencao de nomes de que o `_encurtar_fase_exposto` ja vivia, portanto
  serve os 30 chefes sem tocar em nenhum deles um a um. Um clipe sem ciclo
  que acaba FICA na ultima pose (recuperacao sustentada); re-toca-lo punha o
  ataque em loop.
- Medido: guardiao (Ghorak) passou de `run` 900/900 para run 508 / attack 424
  / hit 259 / idle 109. Inimigo comum run/attack/idle a alternar.
- MORVANNA: ciclo novo REPOSICIONA -> TELEGRAFO -> ataque -> PICADA_TEL ->
  PICADA -> ATERRADA (janela de melee) -> LEVANTA -> ar. Aterra no chao
  (altura 24 px, era 88 = o apogeu exacto de um salto de 470 de forca, e so
  la chegava ~0,8 s dos 1,5 s). Medido: 355 de 1400 frames ao alcance melee,
  altura minima 24 px.
- DANO PASSIVO RESOLVIDO: o corpo dela so machuca durante a PICADA (64 de
  1400 frames), por overlap directo e uma vez por picada -- `body_entered`
  nao servia porque a Koliani pode ja estar dentro da area quando a picada
  comeca. Pairar por cima nao faz dano nenhum.
- Nao se tocou no movimento da Koliani nem se criou ranged. Nenhum rebalance
  dos outros chefes. Suite completa OK (a suite precisa da pasta `work/`:
  num worktree novo da 8 falsos negativos de save).
- HUMAN PLAYTEST REQUIRED: a queixa era de SENSACAO (parecem parados / a luta
  nao faz sentido). Os numeros mostram os estados e o alcance; se a leitura
  em jogo ainda nao convencer, afinar `dur_exposta`/`dur_picada_tel`.
- Prova: `tools/prova_9h9.tscn` (e uma CENA -- em `--script` os autoloads nao
  existem e a compilacao rebenta em cascata).

## Execution 9H.7 - nitidez do fundo + conteudo dos niveis da Regiao I

- Relatorio: docs/execution_9h7_regiao1_nitidez_conteudo.md. Versao 0.18.1.
- Fundo desfocado: DUAS causas provadas. (1) cada camada era ampliada 2,1x a
  3,6x no pixel do ecra com filtro bilinear (escala no mundo x zoom 1,4); a
  9H so tratou o panorama e deixou serra/arvores/ruinas/cascatas/primeiro
  plano. (2) `nitidez_fundo.gdshader` fazia `COLOR = c` e ATIRAVA O MODULATE
  FORA -- desde a 9H o fundo era desenhado sem a tinta de mood da 08, sem os
  -18 % da camada funda e sem os alfas 0,82/0,6; o azul ceifava a B=255.
- Correccao: `tools/nitidez_fundo_9h7.py` amplia no DISCO ao fator exacto
  (panorama x4, kit x3; Lanczos sobre alfa premultiplicado, mascara de
  desfoque so na cor e com orla replicada) e quem monta divide a escala por
  esse fator -- geometria no mundo igual ao pixel. O shader repoe o modulate
  pelo estagio de VERTICE (o built-in `MODULATE` NAO existe nesta versao: da
  "Unknown identifier", confirmado em runtime). Forca da acutancia de
  0,35-1,05 para 0,12-0,35 (a 1:1 a antiga desenhava halo).
- Medido: ampliacao mediana 2,8 -> 1,05-1,10; maximo 1,58 (cristais grandes
  e nevoa). O filtro fica LINEAR e NAO passa a Nearest: a arte e pintada e a
  1:1 o Nearest dava cintilacao no parallax.
- A risca vertical escura do L5 ERA REAL e vem do recorte da 6A: a caixa
  (18,97,952,247) leva uma coluna da MOLDURA do painel da prancha em cada
  lado (luminancia 55 contra 148), e as pontas do panorama sao espelhadas e
  encostadas -- a coluna aparecia a dobrar. Estava escondida dentro do azul
  ceifado. O produtor repete o pixel aprovado do lado; caixa e tamanho iguais.
- Conteudo: a lacuna estrutural era o INTERVALO DE POUSO. As pecas eram
  espalhadas por `referencia.x +- 2600/3200`, escritos a mao; com fator 0,26
  e o nivel de -2550 a 3850 a camara so ve o local [286, 2864], portanto
  METADE das pecas ficava onde nao se pode ver. `_banda(f)` calcula a faixa
  real e as quantidades passaram a densidades por 1000 px.
- Montado do que a 08 tem e faltava: vinhas a emoldurar o ecra do topo
  (`VinhasFrente`, 20-22/nivel), aglomerados de cristal a media distancia
  (`Camada2Corrupcao`, 4/6/9/11/17 de L1 a L5), e os "Raios de Luz
  (volumetricos)" (`RaiosLuz`) -- a 9C escondeu o `Raios` legado e nao pos
  nada no lugar. L3 no pico das ruinas (23+29), L4 no das cascatas (27),
  L5 com a Heart Tree sobre a arena (`landmark_visto_em = 3060`).
- NAO mexido: colisoes, geometria, checkpoints, progressao, inimigos, chefes,
  save, movimento. O unico `.tscn` tocado e o do L5, so para o landmark.
- PRODUCTION ASSET MISSING: Chuvisco/Chuva -- esta na 08 mas marcado
  "(variante)" e sem peca no kit 9C. Nao improvisado.
- Desempenho (relogio de parede, 240 frames): media 0,77-1,03 ms, p95
  1,19-1,70 ms, 69-72 draw calls, para 16,7 ms de orcamento. O panorama x4
  sao ~25 MB de VRAM (o x2 eram ~14). MEDIDO EM PC, nao em telemovel.
- Suite OK. Teste dirigido `teste_execution_9h7_fundo_regiao1`, com as
  asserçoes PROVADAS por mutacao (a 1.a versao da da corrupcao passava por
  VACUIDADE: com o L1 a zero, "L5 > 2 x L1" e verdade com um cristal).
- Prova: work/9h7/9h7_antes_depois.png, 9h7_niveis.png, auditoria_depois.json.
  O ponto de PARTIDA de cada nivel e mau sitio para julgar o fundo (a
  geometria tapa 45 % do ecra); fotografar a 15/40/65/90 % da largura.
- Regiao II NAO iniciada.

## Execution 9H.6 — iOS intro + layout live

- Trace físico recebido: playing/play resolved, paused=false, readyState=3,
  currentTime=0/10; toque hit canvas, nenhuma tentativa de menu.
- Stall confirmado; causa interna WebKit não demonstrada. Nova via iOS
  prepara WASM/PCK antes da intro, sem main loop ou áudio Godot concorrente;
  só inicia o jogo após ended/Skip, sem nova descarga do pack.
- MP4 aprovado intocado: vídeo/áudio no mesmo elemento, sem recodificação.
- Skip em dialog top layer; canvas sem pointer-events durante intro,
  captura touchstart/pointerdown/click, teardown e callback protegidos.
- Drag/resize/guardar/REPOR propagados por grupo às instâncias tácteis
  existentes; medir+redraw síncronos, inclusive pausado. FECHAR não grava
  e volta ao layout persistido; ficheiro/formato/persistência preservados.
- Painel 9H.5D removido. Landscape/API/CSS fallback sem alteração funcional.
- DOM startup/Skip/recusa/fim/desktop PASS; layout live no Godot PASS.
  Suite existente: OK, 71 ObjectDB leaked no fim. Teste dirigido:
  76 leaked/3 recursos no fim, sem erro funcional; não corrigidos fora de scope.
- Export Web exit 0, sem SCRIPT ERROR/Parse Error; cache local
  1789226956|8542300. Logs work/9h6_*; publicação pelo CI existente.
- DEVICE VALIDATION REQUIRED: retestar movimento/A-V/Skip no iPhone.
  Não se declara reprodução iOS PASS com provas DOM/desktop.
- STOP após deployment; Região II NÃO iniciada.
- Publicação confirmada: 64a57f5; CI 34702490395 todos os jobs SUCCESS;
  Pages 6411333452, SHA 64a57f5 SUCCESS. Shell iOS público confirmado,
  painel temporário ausente; cache 1789227369|8048406 e limpeza antiga.
- Próximo passo exclusivo: Game Master retestar iPhone vídeo/A-V/Skip e
  drag/resize/guardar/REPOR live; sem continuar outra execução.
- Usage final consultado: 20% restante na janela de 5 h e 87% semanal.
- Publicação confirmada: 64a57f5; CI 34702490395 todos os jobs SUCCESS;
  Pages 6411333452, SHA 64a57f5 SUCCESS. Shell iOS público confirmado,
  painel temporário ausente; cache 1789227369|8048406 e limpeza antiga.
- Próximo passo exclusivo: Game Master retestar iPhone vídeo/A-V/Skip e
  drag/resize/guardar/REPOR live; sem continuar outra execução.
- Usage final consultado: 20% restante na janela de 5 h e 87% semanal.

## Execution 9H.5D — diagnóstico iOS autorizado

- Objetivo exclusivo: publicar instrumentação temporária para trace físico.
- Painel DEBUG sempre ativo na intro Web, atualização a 500 ms; estados,
  dimensões, eventos de vídeo e resultado/erro da promessa play().
- Captura passiva pointerdown/touchstart/click e elementFromPoint;
  não corrige vídeo/Skip nem altera codec, landscape, gameplay ou arte.
- Painel permanece após intro para ler MENU TRANSITION; PASS confirmado
  após montagem do menu; FAIL se não houver confirmação em 5 s.
- Testes DOM intro/diagnóstico e landscape PASS; export Web exit 0,
  sem erros de script. Erros WAV AppleDouble preexistentes preservados.
- Cache local nova 1789224947|7971234; worker limpa versões anteriores.
- Publicação pelo pipeline existente de master; confirmação após push.
- Confirmação final: commit/origin/master 99da1cd; CI 34700745955 todos
  os jobs SUCCESS; Pages 6410999649 SHA 99da1cd SUCCESS; PWA HTTP 200.
- Cache pública 1789225279|8067147, limpeza de versões antigas confirmada.
- STOP: diagnóstico publicado; nenhuma investigação adicional iniciada.
- DEVICE VALIDATION REQUIRED: Game Master testar PWA no iPhone e recolher
  painel antes/depois do Skip. Não continuar investigação sem trace físico.
- Usage consultado: disponível, 41% restante na janela de 5 h e 91% semanal.
- Usage final consultado: 36% restante na janela de 5 h e 90% semanal.

## Execution 9H.5 — investigação bloqueada antes do hotfix

- Âmbito: intro iPhone/Skip/transição; nenhum código ou asset alterado.
- MP4 descarregado da PWA pública: SHA256
  dab200cef9db8c8b0a4fd8f70f2d1911eb59c804e70d6ca9f8ca9ec0e4d947a9,
  idêntico ao ficheiro Web e ao vídeo aprovado.
- MP4/mp42, H.264 Baseline nível 3.1, yuv420p progressivo BT.709,
  832×464, 30 fps, AAC-LC stereo 44,1 kHz, duração 10 s.
  moov antes de mdat (faststart); FFmpeg descodificou 300 frames distintos.
  Evidência local: work/9h5_public_intro.mp4 e work/9h5_frames.md5.
- Ciclo existente: play síncrono no gesto; playing/timeupdate/pause/error;
  diagnóstico currentTime/paused/readyState. Não regista metadata/canplay/
  waiting/stalled nem histórico físico; não distingue A/B/D no iPhone.
- Skip está z-index 22 (vídeo 20, rotação 21), touch-action manipulation;
  captura global touchend/click/keydown. Sem hit testing/eventos físicos,
  causa do toque não provada. Não se atribui a falha ao CSS ou codec.
- DEVICE VALIDATION REQUIRED: obter do Game Master trace iPhone de
  eventos/currentTime e alvo do toque; não automatizar dispositivo físico.
- Continuação autónoma: testes DOM intro/landscape PASS; não provam iOS.
- PWA no browser desktop integrado mostrou cartão; sem botão DOM nesse
  arranque; clique não concluiu em 30 s e a ferramenta perdeu o alvo.
  Prova inconclusiva, não atribuída ao codec/compositor nem ao iPhone.
- Sem build/commit/push/deploy de lote incompleto. Região II NÃO iniciada.
- Próximo passo: trace físico ou decisão explícita para publicar apenas
  instrumentação diagnóstica; fix de causa só depois da evidência.
- Usage consultado: disponível, 45% da janela de 5 h e 91% semanal.

## Execution 9H.4 — iPhone intro hotfix

- Game Master viu frame estático na intro e pediu skip visível independente.
- Intro Web só inicia no gesto DOM; sem tentativa de autoplay. Estado de
  reprodução confirmado por playing/timeupdate, pausa distinta e retomada
  apenas por gesto. Diag inclui currentTime/paused/readyState.
- HTML áudio silencioso suspenso apenas durante a intro para não concorrer
  com o vídeo; AudioContext continua desbloqueado no primeiro gesto.
- Botão skip DOM acima do vídeo/fallback, traduzido nos seis catálogos.
  Disponível desde o início, mesmo bloqueado: pause, retirar src/load,
  remover camada, callback imediato ao menu, guardas contra duplo menu.
- MP4 aprovado preservado: H.264 Baseline/AAC, 300 amostras de vídeo.
  Causa exata no WebKit físico não provada; DEVICE VALIDATION REQUIRED.
- Landscape manifest/API/repetição após gesto e fallback iOS preservados.
  Sem hacks de rotação; aviso esperado quando lock ausente/recusado.
- DOM startup/skip bloqueado/duplo/áudio sem concorrência e landscape PASS.
  Export Web exit 0, sem erros de script; log work/9h4_web_export.log.
- Publicado `462fdef`, origin/master confirmado; CI `34699292675` todos
  os jobs SUCCESS; Pages deployment `6410721223` SHA 462fdef SUCCESS.
  Cache pública nova `1789223481|6481015`; wrapper startup confirmado.
  Confirmação final registada localmente após push, sem novo commit.
- Próximo passo exclusivo: Game Master reteste iPhone/PWA.
  Gameplay/bosses/arte/áudio geral/UI do jogo/Região II intactos.

## Execution 9H.3 — iPhone startup hotfix

- Game Master observou no iPhone áudio sem imagem e gesto extra de som.
- Âmbito exclusivo Web: gesto DOM chama desbloqueio AudioContext/canal iOS
  e play da intro síncronos; botão de som apenas em ?audio-debug=1.
- Vídeo oculto após autoplay recusado era mostrado depois de play(). Agora
  display=block antes de play; playsinline/WebKit explícitos; canvas/splash
  ocultos durante a intro e restaurados no fim, skip ou erro.
- MP4 aprovado preservado: H.264 Baseline/AAC. Causa WebKit visual ainda
  depende de reteste: DEVICE VALIDATION REQUIRED, sem PASS de dispositivo.
- Provas DOM de gesto/áudio/visibilidade/restauro e landscape PASS.
  Export Web exit 0, sem SCRIPT ERROR; log work/9h3_web_export.log.
- Publicado: `4e64b72`, origin/master confirmado; CI `34697524547` todos
  os jobs SUCCESS. Pages deployment `6410380760` SHA 4e64b72 SUCCESS.
  Wrapper público confirmado; cache nova `1789221304|6430512`.
  Confirmação final registada localmente após push, sem novo commit.
- Próximo passo exclusivo: Game Master reteste iPhone/PWA.
  Gameplay, bosses, arte e Região II intactos; sem export Windows local.
## Execution 9H.2 — Release Candidate autorizada pelo Game Master

- Correção local da intro preservada: `play()` síncrono no gesto DOM;
  acrescentado autoplay com som e retorno ao cartão se `NotAllowedError`.
  Primeiro toque inicia diretamente; clique emulado ignorado; skip intacto.
  Watchdog de 26 s apenas fallback. Prova DOM PASS, não prova de iPhone.
- Landscape: manifest gerado `orientation=landscape`; API tentada no arranque
  e repetida no gesto, sem aguardar Promise antes de áudio/vídeo. Desktop
  excluído. Aviso traduzido nos seis catálogos apenas após API ausente/recusa,
  em portrait e acima do vídeo; toque no aviso também chega à intro.
- `node tests/test_intro_gesto_web.cjs` e `test_landscape_web.cjs`: PASS.
  Suite normal: `OK -- todos os testes passaram`; mantém avisos finais de
  73 instâncias leaked e um recurso em uso. Logs em `work/9h2_suite.log`.
- Layout: guardar → reler e REPOR → reler/default PASS na suite existente.
  Reload/IndexedDB na build atual não revalidado. Sistema preservado.
- TOUCH COMBO IMPLEMENTATION: PASS por wiring (atacar → buffer → quatro
  passos); janela 0,42 s intacta. REAL DEVICE VALIDATION: GAME MASTER PENDING.
- Windows e Web/PWA exportados (exit 0). Logs `work/9h2_*_export.log`:
  erros de importação em `._monster-*.wav` alheios ao lote; não corrigidos.
  Windows: renderer NVIDIA real, intro pos=2,91 s e a_tocar=true;
  captura `work/9h2_intro.png`. Prova adicional intro→menu/áudio inconclusiva.
- Web local mostrou cartão; clique expirou em 15 s. Sem insistir no browser.
  Smoke de gesto/vídeo/áudio/reload real pendente. DEVICE VALIDATION REQUIRED.
- Cache Web nova `1789219075|9217045`; worker gerado remove caches antigos.
  Build local validada; RC destinada à publicação pelo pipeline existente.
- Game Master autorizou explicitamente commit/push da Release Candidate em
  12/09/2026, com gates humanos/dispositivo PENDING para testar na PWA.
  Commit/push: `acf24c6`, confirmado em origin/master.
  CI `34696375168`: Pages publicado; falha preexistente de invocação do teste
  Node com --script, confirmada no log exato e reproduzida localmente.
  Correção exclusiva: CI executa tools/verifica_spawn_livre.tscn.
  Teste afetado: SPAWN NIVEL 5 TUDO OK; gameplay intacto.
  Correção publicada: `ccd8132`, origin/master confirmado; CI `34696680848`
  SUCCESS em todos os jobs e Pages. Deployment `6410214418` SHA ccd8132.
  PWA pública 0.18.0; cache `1789220190|7899982`, manifest landscape.
  Confirmação final registada localmente após push; sem novo commit.
  Próximo passo exclusivo: Game Master playtest iPhone/PWA, bosses e aprovação.
- Próximo passo exclusivo do Game Master: iPhone/PWA real, playtest boss L1–L5
  e aprovação final da Região I. Região II NÃO iniciada; pontos congelados intactos.

## Execution 9H.1 — fecho do gate humano da Região I — **PARTIAL PASS**

**READY FOR GAME MASTER HUMAN REVIEW: SIM.** v0.18.0. Relatório:
[execution_9h1_gate_humano.md](execution_9h1_gate_humano.md). Pacote de
revisão: `work/execution_9h1/`. **Região II NÃO iniciada.**

- **Trilha sonora: de PRODUCTION AUDIO MISSING a seis peças ORIGINAIS.**
  Menu, exploração da Região I, camada de combate, guardiões, Coração,
  ambiência de pausa. Compostas por `tools/compor_trilha_9h1.py` sobre um
  sintetizador escrito de raiz (`tools/motor_musical.py`: wavetable,
  Karplus-Strong, filtro de 2 pólos, reverbe de Schroeder — Python puro).
  **Zero amostras de terceiros, zero licenças, zero atribuição devida.** As
  cinco com melodia partilham o mesmo motivo de sete notas em ré menor; o
  Coração toca-o INVERTIDO com um segundo sino 18 cents acima. As Regiões
  II-XX ficam nas 40 faixas CC0/CC-BY — o briefing proíbe fazer número.
- **ARMADILHA DA EMENDA DO LOOP (custou duas renderizações).** À primeira, o
  fim de cada faixa estava até **−27 dB** do princípio: as notas acabavam
  com o seu release e o bordão tinha ataque/queda. Ouve-se como um buraco a
  cada volta. Resolvido com (a) `voz_continua()` — arredonda a frequência do
  bordão para caber um número INTEIRO de ciclos na duração, sem envelope — e
  (b) camas de acorde a transbordar 1,55 compassos, que dão a volta e
  reentram no princípio. E depois ainda faltava a FASE: um salto de forma de
  onda de 0,18 (40 % do pico) estala na emenda; **2,5 ms** de esbatimento
  nas duas pontas resolvem-no e não se ouvem.
- **Combo: os golpes 2/3/4 deixaram de ser os mesmos 6 frames.** Poses de
  corpo próprias derivadas da autoridade (`derivar_combo_koliani_9h1.py`):
  separa-se a Shadowblade por matiz, cisalha-se o tronco, abre-se a passada,
  comprime-se na vertical, espelha-se, e roda-se a lâmina em torno do punho.
  **37-49 % de silhueta diferente entre golpes, nenhum frame repetido.**
  Combo de 3 → 4 golpes (o briefing pede 1→2→3→4); o **dano por golpe não
  mudou**. O 4.º é o REMATE: duas antecipações agachadas, lâmina por cima da
  cabeça, avanço de 17 px.
- **Duas lições do combo.** (1) Ângulos ABSOLUTOS de lâmina (até 160°) põem
  a espada onde o braço desenhado não a pode levar — lê-se como lâmina
  solta. A versão boa usa deltas ≤ 40° e tira a trajectória da ESCOLHA do
  frame de origem. (2) O **contorno escuro** da lâmina falha o teste de
  saturação e fica no corpo; cisalhado com o tronco, aparece uma **segunda
  espada a tracejado** ao lado da verdadeira.
- **Criaturas: 283 frames derivados, 12 entidades.** Pernas DETECTADAS (cada
  corrida de colunas ligadas na faixa de baixo é uma perna — serve um goblin
  de 2, um Ghorak de 4 e uma Rainha de 8), tronco a respirar, cabeça/copa/
  tentáculos com fase própria, brilho da corrupção a pulsar, e um estado
  **ATTACK que não existia** (entra no telégrafo do `DemonioBase`). Coração:
  fase 1 contida, fase 2 com amplitude **1,9×**, material diferente.
- **Três armadilhas do movimento, todas da mesma família.** (1) RODAR uma
  faixa parte o bicho na linha do corte — usar CISALHAMENTO, que é contínuo
  na fronteira. (2) Comprimir linha a linha abre costuras — redimensionar a
  REGIÃO. (3) Uma rampa VERTICAL em píxeis inteiros deixa um buraco em cada
  degrau (o clone da Morvanna tinha um risco transparente na linha 47).
  Verificação automática: **0 frames com linha vazia**.
- **Seletor com tema POR REGIÃO** (`scripts/tema_regiao.gd`). A Região I em
  **verde de musgo** com o panorama da Árvore-Coração ao fundo (arte de
  produção aprovada, não inventada) e o **magenta da corrupção só no nó do
  guardião e no cadeado**. As 19 sem autoridade em **aço frio**, marcadas
  `REGION SELECTOR THEME AUTHORITY MISSING`. Navegação, 20×5 e bloqueios
  intactos. **Nota:** dessaturar por `modulate` NÃO chega — carmesim ×
  cinzento continua carmesim; tem de se tirar a cor na produção da peça.
- **Bug apanhado por fazer a prova em Chrome real:** o **REPOR** do editor
  de layout de toque punha os controlos no sítio mas **não apagava o
  ficheiro** no Web — na recarga voltava tudo. Causa: `apagar()` usava
  `ProjectSettings.globalize_path()`, e no emscripten esse caminho não é
  apagável pelo `DirAccess`; `user://` é. Corrigido, com teste, e
  **re-verificado no browser**: GRAVAR põe o ficheiro em IndexedDB, REPOR
  tira-o em 8 s (antes continuava lá 16 s depois).
- **Provado no EXE de release** (commit `12f1209`, SHA
  `670b6943…`): intro, menu, **seletor verde da Região I**, seletor neutro,
  L1/L3/L5 com HUD. Rota nova `--foto-seletor=<png>@<n>`.
- **Provado no Web, em Chrome REAL e visível** (PCK `297cf8e2…`): menu,
  seletor da Região I em verde, apresentação neutra, **áudio a chegar ao
  altifalante (picos 0,09-0,20 com `?audio-debug=1`)**, editor de layout,
  mover e redimensionar dois controlos, gravar, e **persistência lida do
  IndexedDB**.
- **RESSALVA: o Chrome desta máquina corre OCLUÍDO — rAF a 1 Hz.** O jogo
  anda a 1 frame por segundo e cada navegação leva 40-60 s. Está provado que
  FUNCIONA; não está provada a FLUIDEZ, nem o **combo de 4 golpes por
  toque** (a 1 fps não se encadeia dentro da janela de 0,42 s). É o P1 da
  próxima sessão, com uma janela de Chrome em primeiro plano.
- **Armadilha de prova (3 passagens).** O viewport **não** devolve RGBA8 —
  misturar formatos num `blit_rect` dá cores trocadas e bandas horizontais.
  Esconder VFX **por nome** falha: os arcos do combo nascem como filhos da
  própria Koliani; a regra boa é por exclusão. E a **câmara é filha da
  Koliani**: teleportar a Koliani não chega para fotografar o chefe (câmara
  em x=−3116, Coração em x=+3080) — precisa de `top_level`.
- **Desempenho sem regressão:** menu 0,389 ms, seletor 0,384, L1 0,646, L3
  0,678, L5 0,973 (média de parede). Pior frame do conjunto: 2,8 ms.
- **Chefes: NADA foi afinado**, como o briefing manda. Tabela antes/depois
  em `work/execution_9h1/chefes_regiao1.md`. **A decidir:** o
  `dano_contacto` é o único dano que a rampa não alivia e por isso SOBE ao
  longo da região (16 → 25) enquanto os outros descem.
- **Por fazer:** P1 combo por toque + playtest humano dos chefes; P2 o ecrã
  de Opções ainda é ouro/ciano do 9F dentro de um frontend carmesim, e o PCK
  do Web está em 85,9 MB.

## Execution 9H — Frontend de produção + slice final da Região I — **PARTIAL PASS**

**READY FOR GAME MASTER HUMAN REVIEW: SIM.** v0.17.0. Relatório:
[execution_9h_frontend_regiao1.md](execution_9h_frontend_regiao1.md). Pacote
de revisão: `work/execution_9h/folha_revisao_9h.png` (11 painéis).
**Região II NÃO iniciada.**

- **A autoridade não estava onde o briefing dizia.** Não existe
  `work/production_art_gate/9H_game_master_approved/`; as cinco peças estão em
  `work/production_art_gate/10_menu_rebrand/` com outros nomes (menu
  `22d1ecf0889f`, seletor `3fbaa747f6da`, ícone `948e01984a73`, vídeo
  `dab200cef9db`). Os SHA estão presos em `tools/produzir_frontend_9h.py`.
- **Método (uma passagem serve os dois fins):** máscara das zonas com UI
  pintada → inpaint por difusão multi-escala (raio 128→1, píxeis conhecidos
  repostos a cada passo) = **arte limpa**; `prancha − arte limpa` = **peças
  recortadas**. Mesmo princípio do 9G. 32 ficheiros, com manifesto e
  `--validar`.
- **Armadilhas do produtor:** a máscara das coroas dos anéis tem de vir
  ANTES dos retângulos (senão devolve as fichas ao fundo — “1-4”/“1-5”
  sobreviviam); nas abas o texto apaga-se na VERTICAL (na horizontal deixava
  rasto de lado a lado); a ficha do nível não é nine-patch (as pontas em
  losango sobrepunham-se); **`--import` SEMPRE depois de correr a ferramenta**
  (senão o ecrã aparece sem texturas e parece bug de código).
- **Palco 16:9:** todo o frontend vive num `AspectRatioContainer` onde arte e
  UI partilham as coordenadas de 1280×720 (as pranchas são composições
  fechadas; esticar tirava a UI do sítio).
- **Feito:** menu novo (5 entradas + realce que escorrega + crédito),
  **intro em vídeo** (main_scene nova), ícone/logo em todo o lado
  (Windows/.ico, PWA, Android, projeto), **seletor = mapa de região** (nós,
  trilho que acende, painel, 20 abas), HUD em carmesim, **EDITAR LAYOUT** na
  PWA (frações do viewport, `user://layout_toque.json`), 4 vozes de UI +
  ambiência própria da Região I.
- **Chefes L1–L5 mais fáceis:** rampa `ChefeBase.ALIVIO_R1` que mexe em vida,
  dano, telégrafo, EXPOSTO e recuperação ao mesmo tempo. **Ghorak (1-1): vida
  800→416, `dano_onda` 22→13, EXPOSTO 0,72→1,11 s.** Fora da Região I nada
  muda.
- **Fundo desfocado — causa provada:** panorama 1:1 de 952×247 desenhado a 3×
  com LINEAR, mais o zoom 1,4 da câmara = ~4,2× de ampliação bilinear.
  Corrigido com panorama em DOBRO no disco (Lanczos + unsharp, desenhado a
  1,5×) + **máscara de desfoque no píxel do ECRÃ**
  (`nitidez_fundo.gdshader`). **Acutância +19 %** (5,00 → 5,95, medida na
  banda de fundo do L1).
- **Inimigos parados — causa provada:** o `_process` do `DemonioBase` **saía
  assim que existisse `_anim`**, e a arte de produção tem uma pose por
  estado. `_vida_no_anim()` repõe respiração/passada/inclinação/recuo/
  aterragem, com fase própria por instância. A escala é compensada na
  posição, senão os pés flutuavam ~4 px.
- **Combos que não se liam:** os três golpes saem dos mesmos 6 frames golden.
  Agora cada um tem arco próprio, tom próprio e há **selo `×2`/`×3`** por
  cima da cabeça.
- **Web: o vídeo NÃO pode ser do Godot.** O export Web é single-threaded e
  descodificar Theora em wasm **bloqueia a thread principal** (a página
  deixava de responder). Passou a ser um `<video>` do DOM
  (`web/intro_koliani.mp4`, o CI copia-o). **Bug apanhado só no browser:** o
  cartão de gesto comia o toque (`Control` nasce com `MOUSE_FILTER_STOP`).
- **Provado no EXE de release:** intro (`pos=2,93 s`), menu (sem DEVELOPER
  MODE), mapa, L1–L5, 18 fotos de inimigos. **Userdata intacto** (181
  ficheiros, 0 mudados fora de `logs/`).
- **Provado no Web:** carrega sem erros de GDScript, ícone novo + cartão,
  `<video>` a tocar (`currentTime=6,6 s`, `error=null`), PCK com tudo o que é
  novo, manifesto/ícones da PWA.
- **ARMADILHA DE MÉTODO (custou 3 falsos negativos):** o Python no Windows
  escreve `
` por omissão. O `run_tests.gd` tem quebras de linha
  **literais dentro de constantes de texto**; com o ficheiro em CRLF essas
  buscas deixam de bater e inventam falhas (“MECANICA_DO_NIVEL tem 0
  entradas”). **`write_text(..., newline="
")` sempre.**
- **Por fazer (detalhe no relatório):** P1 capturas do Web em Chrome real +
  **soundtrack nova (PRODUCTION AUDIO MISSING)**; P2 estatísticas do seletor
  (colecionáveis/desafios/tempo não existem no jogo), citações por região,
  PCK do Web com 285 MB.

## Execution 9G — VFX de produção da Região I — **PASS**

**REGION I VFX PRODUCTION GATE CLOSED. Pronto para 9H (montagem visual +
gate humano): SIM** (não iniciada). v0.16.1, commit `651c87f`. Relatório:
[execution_9g_region1_vfx.md](execution_9g_region1_vfx.md).

- **A prancha 07 tem alfa mas NÃO é transparente** (208–250 em toda a imagem;
  o xadrez está pintado nos píxeis) e **a grelha das células não bate com os
  frames** (dois rebentamentos numa célula; a elipse do "spin slash 03" cai em
  cima do rótulo 04). Método que resultou (`tools/produzir_vfx_9g.py`): fundo
  medido por painel (percentil 97 dos cinzentos) → `efeito = px − fundo`
  guardado para desenho **aditivo**; frames separados nos **vales do desenho**
  por programação dinâmica com as larguras presas ao espaçamento dos rótulos;
  âncora por grelha ajustada (mínimos quadrados) para o arco AVANÇAR.
- **Hipóteses descartadas, por ordem, e porquê:** (1) recorte pela grelha das
  células — as linhas não são os frames; (2) componentes ligadas por janela —
  o brilho fraco cola o vizinho e vinham lascas; (3) "rótulo mais perto" — a
  arte está desalinhada dos números e esvaziava frames; (4) DP sem penalização
  de largura — enfia vários cortes seguidos na primeira zona vazia.
- **148 frames: 146 PASS, 2 REVIEW, 0 FAIL.** 14 famílias Shadowblade
  (classe B) + 5 de corrupção (classe C).
- **Armadilha da corrupção:** recolorir mantendo o alfa dava uma **mancha
  preta por cima do guardião** (tapava a silhueta e o telégrafo). Resolvido
  prendendo o alfa à luminância (`a' = a × (0,12 + 1,15·lum)`).
- **Prova no EXE:** `--foto-estado=vfx9g` (rota nova, só dev): 17 fotos no L1,
  20 no L5, **zero texturas legadas**; userdata reposto e verificado por SHA
  (180/180). **Web:** PCK no browser = export (`3928d358…`), cache
  `1789164610|58655591`, VFX visíveis e **áudio do 9F sem regressão**
  (`running`, picos 0,18 menu / 0,29 jogo).
- **Desempenho sem regressão:** L1 1,072 → 1,046 ms; L5 1,067 → 1,011 ms. A
  sonda anda e salta, **não combate**.
- **Nome canónico corrigido nos 6 idiomas: FLORESTA CORROMPIDA**
  (`world.forest` + `level.n00`; live na HUD e no selector).
- **Por fazer:** `RaizPerigo` continua por código (a prancha não tem raízes =
  arte nova); água venenosa e arte da fogueira mantidas; sem playtest humano.

## Execution 9F — UI da Região I + áudio do Web/PWA — **PASS**

**REGION I UI GATE CLOSED. WEB/PWA AUDIO GATE CLOSED. Pronto para 9G (VFX):
SIM** (não iniciada). v0.16.0, commits `72bdc2a` (áudio) + `00399d0` (UI).
Relatório: [execution_9f_ui_pwa_audio.md](execution_9f_ui_pwa_audio.md).

- **Causa-raiz do Web mudo (provada no grafo Web Audio):** os buses Music/SFX
  eram criados em runtime (`Opcoes._criar_buses`). No Web o Godot 4.7.2 toca em
  modo Sample e o `GodotAudio.Bus.move()` do motor faz `splice(toIndex-1)`: o
  bus novo ia para a posição 0 e o Master antigo ficava ligado a ele — ciclo
  Master→SFX→Music→Master, nada chegava ao destino. Contexto `running`, pico 0.
  **Não era autoplay** (as 4 correcções de gesto anteriores não podiam
  resolver). Correcção: `default_bus_layout.tres`. Teste
  `teste_9f_buses_de_audio_estaticos` (morde).
- **Prova no Chrome real** (`?audio-debug=1` + `kolianiAudioDiag()`):
  `suspended` antes do gesto → `running` ao 1.º clique; música do menu 0,08–0,25;
  música de jogo L1 ≈0,09–0,11 contínua; com a Música a 0, SFX de UI (0,30) e de
  jogo (0,28–0,33) isolados. PCK no browser = export (`52349f3a…`), cache
  `1789150815|5733576`.
- **UI:** `tools/produzir_ui_9f.py` → `assets/ui/producao_9f/` (19 peças da
  prancha 09, SHA `264d6def…`; A recorte / B inpaint do texto + máscara / C
  barras). `scripts/ui_producao.gd` (tema). Menu, pausa, opções, diálogo, HUD
  (vida, energia, chefe, vidas, essência, cabeçalho "1-5"), toasts, checkpoint.
  **Seletor 20 × 5:** pastilhas I–XX, "I · REGIÃO · n/5", 1-1..1-5, só a região
  no carrossel, ↑/↓ muda de região; desbloqueio intacto (testado).
- **Prova no EXE:** `Koliani.exe -- --nivel=5 --foto-estado=ui9f --foto=…`
  (HUD, toasts, chefe, diálogo, pausa + JSON das texturas). Única legada:
  `ico_caveira.png`.
- **Armadilhas:** o pane do browser interno permite autoplay (o gesto só se
  prova num Chrome real); `AudioBufferSourceNode.prototype.start` é próprio (o
  hook no pai não apanha nada); rAF pára com o pane escondido; teclas de teste
  só chegam com o canvas focado (clicar primeiro); Espaço também confirma no
  seletor; logo a seguir a retomar da pausa a música recria a fonte (uma
  leitura a 0 nesse instante não é silêncio); a fonte Web não tem emoji nem CJK.
- **Backlog:** fonte CJK livre (chinês em tofu no Web, anterior); `✦` do
  Santuário no i18n; `ico_caveira`; manifestos fora dos exports.

## Execution 9E.2 — Coração Putrefacto fechado + prova no EXE — **PASS**

**ENEMY GATE CLOSED. BOSS GATE CLOSED. Pronto para 9F: SIM** (não iniciada).
v0.15.20, commit `901da1f`. Relatório:
[execution_9e2_coracao_putrefacto_closure.md](execution_9e2_coracao_putrefacto_closure.md).

- **Autoridade dedicada:**
  `work/production_art_gate/9E1_game_master_approved/coracao_putrefacto_production_authority_v1_0.png`,
  1448×1086 RGBA com alfa real, SHA `460435aaf18b9b568b0f4529a087a2cc80e07554def894c313f579b9b9247693`.
- **Boss:** fase 1 = forma contida, fase 2 = forma intensificada (limiar de 50 %
  do jogo), erupção = VFX da transição. `tools/produzir_coracao_9e2.py` →
  `assets/art/regions/region_01_forest/bosses/coracao_putrefacto/production/`.
  As luzes do legado lavavam a casca de rosa: raio a 40 % com produção.
- **Prova no EXE:** `Koliani.exe -- --nivel=N --foto-estado=inimigos --foto=…`
  (rota só de dev em `main.gd`) — 11 identidades + as 2 fases, 58 registos, 0
  texturas legadas. `work/execution_9e2/evidencia_exe_9e2.png`.
- **Armadilhas novas:** o Main junta mais bichos que a cena do nível (dezenas no
  L5) — a rota faz uma série por identidade e chefes primeiro; o alfa binarizado
  come/ganha 1 px, por isso a escala do boss é procurada até dar 100 px exatos.
- Pendente (opcional, design novo): poses de ataque do corpo (a autoridade tem
  duas, mas o runtime não tem estado onde as mostrar); arte do `RaizPerigo`.

## Execution 9D+9E — Inimigos + Coração Putrefacto — **PARTIAL PASS** (boss fechado pela 9E.2)

**ENEMY GATE CLOSED. BOSS GATE OPEN. Pronto para 9F: NÃO.** v0.15.19, commit
`dc06608`. Relatório:
[execution_9d_9e_region1_enemies_boss.md](execution_9d_9e_region1_enemies_boss.md).

- **Autoridade aprovada:**
  `work/production_art_gate/9D1_game_master_approved/region1_enemies_boss_visual_authority_v1_0.png`,
  1536×1024 RGBA, SHA `8ebf8ecd13e8d7e7d803acfcccf3361a35cb77ff9ad6dd1d01c79b8b24ebb2fd`.
- **Feito:** 11 entidades (5 comuns, 4 guardiões, clones da Morvanna, crias da
  Rainha) derivadas por `tools/produzir_inimigos_regiao1.py` e integradas;
  nenhuma arte legada de inimigo/guardião visível na Região I. Crias: campo
  `DemonioBase.identidade_visual` (só arte; `especie` fica goblin).
- **Bloqueado:** Coração Putrefacto. Está pintado dentro da arena; 3 máscaras
  tentadas (duas levam a arena, a terceira inventa uma elipse e perde os
  troncos). **Próximo passo:** o Game Master entregar o Coração isolado (alfa ou
  fundo liso); depois é juntar uma entrada ao produtor e o override de fase 2.
- **Armadilhas:** (1) o `run_tests.gd` só corre testes chamados em
  `_correr_tudo` — um `teste_*` novo não registado passa sem correr; (2)
  ferramentas de evidência que citam `DemonioBase`/`Chefe*` têm de ser CENA, não
  `--script`; (3) sem vsync, "N frames" são milissegundos — esperar por timer;
  (4) o rosa claro dos guardiões nas fotos é o `_piscar` (telégrafo), não a arte.
- Limitação aceite: uma pose por entidade → estados por translação/dissolução,
  sem ciclos de pernas.

## Execution 9D — Inimigos e guardiões da Região I — **BLOCKED na arte** (superada pela 9D+9E)

Estado: **APPROVED DIRECTION / PRODUCTION ASSET MISSING. REGION I ENEMY
PRODUCTION GATE: OPEN. Pronto para a 9E: NÃO.** Relatório:
[execution_9d_region1_enemies.md](execution_9d_region1_enemies.md).

- **Porquê:** nenhuma prancha desenha inimigos. A 12 (secção 10) tem alguns
  incidentais (plantas carnívoras, besouro, morcego, gosma), mas com ~30 px, em
  RGB, pintados sobre o cenário. Extraí-los obrigava a remover o fundo
  (proibido). Desenhar é design novo, o mesmo bloqueio da 9B.1. **Precisa de
  uma prancha de inimigos do Game Master.**
- **Pronto para quando a arte chegar:** `scripts/regiao1_inimigos.gd`
  (interruptor: kit 9C na cena + `PRODUCTION_INTEGRATED` no manifesto),
  chamado por `DemonioBase._montar_frames` e `ChefeBase._montar_rig`. Manifesto
  e contrato em `assets/art/regions/region_01_forest/enemies/production/`.
  Teste `teste_execution_9d_inimigos_regiao1`, provado a morder.
- **Inventário:** 5 espécies comuns (goblin L1, mushroom L2, gosma L2/L4,
  besouro L3, lodo L5) e 4 guardiões (Ghorak, Morvanna, Rainha, Entrevane).
  **Estados alcançáveis: só idle/run/hit/dead.** O `ChefeBase.atacar_anim()`
  nunca é chamado e o telégrafo é todo por código.
- **As aranhas da Rainha e os clones da Morvanna nascem como goblins** (a
  espécie fica na omissão). É um buraco de identidade e pede design.
- Gameplay intacto. Suite PASS. Builds não refeitos (nada visível mudou; o
  jogo continua o `a5d9ec9`/0.15.18).

## Execution 9C — Kit de ambiente da Região I

Estado: **PASS — REGION I ENVIRONMENT GATE CLOSED. KOLIANI PRODUCTION GATE
CLOSED (não tocado). Pronto para 9D (inimigos/guardiões): SIM** — a 9D não
foi iniciada. Relatório:
[execution_9c_region1_environment_kit.md](execution_9c_region1_environment_kit.md).

- **Kit:** 31 peças em `assets/art/regions/region_01_forest/production/kit_9c/`,
  recortadas sem perdas das pranchas 08 (autoridade, SHA `840cfd82…` = manifesto)
  e 10 (tileset, graduado para a noite da 08) por
  `tools/produzir_kit_regiao1_9c.py`; `--validar` 31/31 PASS; manifesto com a
  caixa exacta na prancha e o SHA de cada peça.
- **O kit `imagegen_v1` da 9A (12 peças) NÃO foi promovido:** musgo amarelo-lima
  em todas as pedras, ruído a 32 px — afasta-se da 08. Fica não rastreado.
- **LEGACY CC0 TERRAIN VISIBLE IN REGION I: NO.** Interruptor único: o nó
  `Region1HybridVisualTarget` entra no grupo `regiao1_kit`; `plataforma.gd` e
  `plataforma_flutuante.gd` usam o kit; os outros 95 níveis ficam no legado
  (testado). `perfil` 1–5 = moods da 08. Geometria intacta.
- **Parallax** à mão, 4 planos + primeiro plano (`posição = desvio × (1−f)`);
  o fundo legado da `Atmosfera` fica escondido. Lanternas com halo aditivo, não
  PointLight2D (não tinge a Koliani).
- **Desempenho:** +0,1 ms/frame (0,52–0,56 vs 0,42–0,44 ms), draw calls
  **descem** (49–62 vs 67–75). Sem regressão.
- Builds de `a5d9ec9` (0.15.18), worktree limpo: EXE 163,2 MB (`4f49ce2d…`),
  PCK 54,1 MB (`0a43829e…`), cache PWA `1789112478|4547531`. EXE: L1–L5 5/5.
  Web: SHA do PCK medido no browser = export.
- **Armadilhas de método (custaram tempo):**
  - o `run_tests.gd` é um nó, não `SceneTree`: `get_root()` → parse error → o
    Godot **pendura** (10 min). `get_tree().root`, e correr sempre com `timeout`;
  - o EXE de **release** recusa `--script` e caminhos de cena. Para fotografar
    níveis no EXE: `Koliani.exe -- --nivel=N --foto=<png>`, com cópia de
    segurança da pasta `app_userdata/Koliani` antes e reposição por SHA depois
    (a rotação de logs apaga logs antigos — repor também os que faltam);
  - o `tools/shot_plataforma.gd` não move a Koliani (fotos iguais) — usar
    `tools/shot_regiao1_9c.gd`.
- **Por fazer (não bloqueia):** o corpo do terreno é um mosaico de 44 px e lê-se
  regular em paredes muito altas; objectos de gameplay (água venenosa,
  checkpoints) mantêm arte própria — 9D/depois.

## Execution 9B.4 — Pacote completo da Koliani

Estado: **PASS — KOLIANI PRODUCTION GATE CLOSED. Pronto para 9C: SIM.**
Relatório: [execution_9b4_full_character_package.md](execution_9b4_full_character_package.md).

- **KOLIANI GOLDEN SET: PRODUCTION INTEGRATED / HUMAN APPROVED. KOLIANI FULL
  PACKAGE: PRODUCTION INTEGRATED.** Os 9 estados que caíam no premium_v1 (dash,
  roll, hurt, morte, crouch, wallslide, borda, djump, defesa) têm agora 23
  frames derivados **só** de frames golden inteiros: cópia, translação inteira,
  rotação exata de 90°. Ferramenta: `tools/derivar_pacote_koliani_9b4.py`.
  Validator v2: 7 PASS, 2 REVIEW (`POSE_AREA_VARIATION`), 0 FAIL.
- **PREMIUM_V1 / 5G BODY NA REGIÃO I: NÃO / NÃO.** Com `usar_golden_set` o
  `_montar_frames` não carrega tira nenhuma de outro rig; o teste novo exige
  que todos os frames venham de `koliani_golden_set/`.
- **Causa escondida do "chibi" no dash/roll:** o `_animar` esmagava o sprite a
  1,32×0,78 no dash e rodava-o no roll, mesmo em pixel-art. Desligado com o
  Golden Set (a pose está nos frames).
- VFX à parte: `RastoDash`, `SaltoDuploVFX`, `MorteVFX` (+ `SlashVFX`, flash,
  `Escudo`). Gameplay: nenhuma constante mudou.
- Builds de `f912753` (0.15.17), de worktree limpo: EXE 162,9 MB (`31e89a6b…`),
  PCK 53,7 MB (`4c5ae22f…`), cache PWA `1789108285|4479642`. Prova no EXE:
  12/12 estados com textura golden (`--foto-estado=pacote`; parede e rebordo
  forçados).
- **Limites (design novo se o GM quiser):** a morte acaba de joelhos (não há
  pose deitada), o rebordo é um agarrar ao nível do peito, os golpes 2–4
  reutilizam os frames do golpe 1.
- **Armadilha de método:** no Git Bash, `grep -c $'\r'` conta TODAS as linhas
  (deu "1779 CR" em ficheiros LF). Verificar CRLF com Python sobre os bytes.
- **Próximo:** 9C — kit de ambiente da Região I (não iniciada).

## Execution 9B.3 — Golden Set em produção e no runtime

Estado: **PASS — KOLIANI GOLDEN SET — PRODUCTION INTEGRATED.** Relatório:
[execution_9b3_golden_set_integration.md](execution_9b3_golden_set_integration.md).

- **KOLIANI GOLDEN SET VISUAL AUTHORITY: GAME MASTER APPROVED.** Canónico:
  `work/production_art_gate/9b1_game_master_approved/koliani_golden_set_approved.png`,
  SHA-256 `0b067780d316d1fcb288c2a3d944cd758a212f8d696c1818ae6ac0e4db0c60c4`
  (byte-idêntico ao `.png.png` original, que se mantém).
- **8 LOW-HEIGHT FRAMES: POSE-JUSTIFIED / ACCEPTED — 59px RULE = REVIEW ALERT
  ONLY.**
- Validator v2: o xadrez ignora alpha 0; a variação de área por pose passa a REVIEW
  com escala uniforme declarada; um resize real continua FAIL. 10/10 testes.
- 39 frames em `assets/sprites/koliani_golden_set/` + `production_manifest.json`.
  Ativos em L1–L5 via `usar_golden_set`. Os estados derivados usam só frames
  golden; o premium_v1 fica só para dash/roll/hurt/morte/crouch/wallslide/borda/
  djump/defesa. VFX no nó `SlashVFX`, `LuzLamina` desligada, gameplay intacto.
- Builds de `98d8c1b` (0.15.16), exportados de um **worktree limpo**: EXE
  162,7 MB (`d2fbf5e6…`), PCK Web 53,6 MB (`3b618698…`), cache PWA
  `1789089732|5080222`. Prova no EXE: 7/7 estados com a textura golden
  registada. Na Web: PCK byte-idêntico e Koliani golden visível, mas só parada
  (o painel do browser estava escondido).
- **Próximo:** pacote completo da Koliani, a derivar do Golden Set.

## Execution 9B.2 — Golden Set extraction

Estado: **PARTIAL PASS — EXTRAÍDO, GAME MASTER REVIEW REQUIRED; runtime
inalterado.** O Game Master forneceu a arte que bloqueava a 9B.1:
`work/production_art_gate/koliani_golden_set_approved.png.png` (a pasta
`9b1_game_master_approved/` não existe). Os 33 frames de corpo (idle 7, run 10,
jump_start 4, jump_loop 3, fall 3, attack_basic 6) e os 6 de `vfx_slash_basic` foram
extraídos pelo alpha real, sem redesenho, e normalizados ao contrato 9B.1: 128×128,
repouso **64 px**, pivot (64,104), baseline 103, escala uniforme 0,3975, alpha 0/255.
Validator v2: attack PASS; idle/fall REVIEW (`SUSPICIOUS_CHECKERBOARD`, falso positivo
provado: a heurística ignora o alpha); run/jump_start/jump_loop/vfx FAIL em
`GROSS_SCALE_VARIATION` (área da caixa por pose; a escala é uniforme). **Anti-chibi:
8 frames abaixo dos 59 px** por pose (jump_start_001 48 px, jump_loop_001/003,
attack 1/2/3/5/6), à espera de decisão do GM. Saída em
`work/production_art_gate/9b2_extraction/` (fora do git), relatório
`reports/execution_9b2_report.md`. Ferramentas: `tools/extrair_golden_set_9b2.py`,
`tools/validar_golden_set_9b2.py`. `assets/sprites/koliani_golden_set/` não foi
tocado.

## Execution 9B.1 — Golden Set da Koliani — **BLOQUEADA na arte**

Relatório: [production_art_gate_9b1_golden_set.md](production_art_gate_9b1_golden_set.md).
O Game Master resolveu CONF-01: **Route B**, arte desenhada de raiz.

**O bloqueio é simples: falta quem desenhe.** Um agente sem ferramenta de
imagem só consegue desenhar por código, e isso dava as "generic polygon
approximations" que a 9A proibiu. Não se produziu nem integrou arte nenhuma.

**Feito tudo o resto:** autoridade reverificada (6/6 SHA batem), contrato de
canvas derivado de medições, validador v2 integrado e **provado**, e o
`assets/sprites/koliani_golden_set/` criado com manifestos prontos.

**Contrato de canvas (falta o Paulo aprovar):** 128×128, personagem a 64 px,
pivot (64,104), baseline 103, escala Godot **1,0**, offset (0,−18). Os 64 px
aparentes são os mesmos de hoje (78 px × 0,82), por isso colisão, câmara,
física e tempos de combate não mexem. `(104−64−18)×1,0 = 22` = fundo da caixa
de 20×44, igual a `(90−48−15,170732)×0,82`.

**Defeito do salto CONFIRMADO por medição:** no conjunto 5G activo, `idle` e
`run` têm 78 px de altura; `jump_start` cai para 69 de média e **64 no pior
frame — menos 18%**. A cabeça não encolhe, logo a razão cabeça/corpo desloca-se
mesmo para chibi. Regra que fica: no Golden Set nenhum frame perde mais de 8%
(64 → mínimo 59 px). Imagem em
`work/production_art_gate/9b1_evidencia/defeito_chibi_salto.jpg`.

**Método descartado, para não se repetir:** medir a razão cabeça/corpo por
detecção de tom de pele **não funciona** — apanha braços e pernas e devolve
caixas de 27 a 64 px para a mesma personagem. A altura da figura é que é a
métrica objectiva.

**Validador v2 (`6f13409`) integrado por cherry-pick**, 6/6 testes verdes, e
provado contra o jogo real: `pilot_5g/idle` **PASS**, `premium_v1/attack`
**FAIL** (`CLIPPED_RIGHT`, o arco pintado sai do canvas), `premium_v1/dash`
**FAIL** (baseline 79 em vez de 89). Não vê rabo-de-cavalo nem idade — isso é
Gate 2, humano.

## Production Art Gate 9A — inventário feito, uma decisão à espera

Relatórios: [production_art_gate_9a_authority_inventory.md](production_art_gate_9a_authority_inventory.md)
e [production_art_gate_asset_gap_map.md](production_art_gate_asset_gap_map.md).
Manifestos em `work/production_art_gate/` (não versionado).

**As 12 autoridades aprovadas: 12/12 presentes, legíveis, e os 12 SHA-256 batem
com o `references/manifest.json` do pacote.** O que custou a descobrir: **só 3
têm canal alfa** (05, 06, 07). As outras 9 são RGB puro — incluindo a 02, que
desenha o xadrez de transparência *nos píxeis* e escreve «alpha real, pronto
para Godot». Não está. São exactamente as 3 com alfa as únicas de onde alguma
vez se extraiu alguma coisa.

**A lacuna central, medida:** na Região I o jogador vê **duas Kolianis**. Os
cinco níveis ligam `usar_prototipo_premium = true` **e**
`usar_piloto_visual_5g = true`, por isso `idle/run/turn/run_start/jump_start/
jump_loop/fall` saem da 5G (boa) e `attack1-4/dash/roll/hurt/morte/crouch/
wallslide/borda/djump/defesa/aterrar/jump` saem da `koliani_premium_v1`, que
tem **rabo-de-cavalo**, cabelo roxo e o **arco do golpe pintado dentro do
frame**. `run_brake` e `land` não têm frames — são montados por fallback.

**Números medidos:** 5G = 160×96, alfa binário 0/255, última linha opaca **89
em 7/7** (base consistente). `premium_v1` = base a variar entre 79, 80, 88, 89
e 90. Pacote contratado da Koliani: **0/40 frames**. VFX da prancha 07:
**0 de 16** produzidos. Kit modular da Região I: 12 peças existem, **0 estão no
build** (provado por varrimento de bytes do PCK e do EXE).

**Hipóteses descartadas:** (a) «as pranchas entram no build» — não entram, 0
ocorrências de `KOLIANI_VISUAL_AUTHORITY` no PCK e no EXE; o que inchou o build
antigo de 350 MB foi `work/**`, que já está no `exclude_filter`. Mas **nada
exclui o master package**, e as pranchas estão importadas (`.import` + `.ctex`)
— um export feito no checkout principal voltava a arrastar 29 MB. (b) «o rig
activo é o shadowblade» — é o `const RIG` do script, mas a Região I força o
premium, por isso não é o que se vê.

**A decidir antes do 9B (CONF-01):** o contrato proíbe extrair píxeis das
pranchas; o `.exe` aprovado usa 7 animações extraídas delas. Rota A (extracção
determinista, já provada em 45 frames, mas só serve as 3 pranchas com alfa) ou
Rota B (desenhar de raiz, cobre tudo). Recomendação no mapa de lacunas.

## Desbloqueio de áudio Web/PWA

O bootstrap Web retoma agora o `AudioContext` no início e no fim do gesto
(`touchstart`, `pointerdown`, `click` e equivalentes), mantém `audioSession` em
`playback` quando disponível e só reavalia o aviso depois de a Promise de
`resume()` terminar. Um pulso quase inaudível, em vez de um buffer totalmente a
zero, cobre WebKit que não reconheça silêncio otimizado como reprodução. Para
iPhone/Safari, o mesmo gesto arranca ainda um HTML Audio silencioso em loop,
forçando o canal multimédia que o Web Audio isolado nem sempre abre. Suite Godot
verde e export Web local concluído. O parâmetro `?audio-debug=1` mantém um botão
de diagnóstico visível com os estados Web/iPhone; ao tocar, produz um apito de
660 Hz diretamente no contexto para separar bloqueio do browser de falha interna
do Godot. O teste no iPhone 14 do Paulo ouviu esse apito: browser, contexto e
saída física estão funcionais. A causa restante era a música ser agendada antes
do desbloqueio e descartada pelo iOS enquanto o player continuava marcado como
activo. O HTML avisa agora `Musica` após a retoma e o autoload reinicia as fontes
120 ms depois. Falta confirmar a música/SFX num telemóvel real após a publicação:
**DEVICE VALIDATION REQUIRED**.

## Publicação contínua Web/PWA

O job `pages` da CI passou a fornecer realmente `enablement: true` ao
`actions/configure-pages@v5` e deixou de mascarar falhas com
`continue-on-error`. Cada push aceite em `master` que passe testes e export Web
publica a PWA em `https://paulogomesextp.github.io/koliani/`, no mesmo ciclo que
gera a versão Windows. Falhas de publicação ficam visíveis no workflow. O job
de testes cria agora `work/` antes da suite: a pasta é ignorada pelo Git, mas os
testes de save usam `res://work/` e falhavam em checkouts limpos sem ela. A
bancada `verifica_actores_novos.gd` prepara explicitamente `salto_duplo` antes
de testar `ZonaSemPoder`, pois a campanha atual começa canonicamente sem
habilidades e o teste antigo ainda assumia esse desbloqueio inicial. Os jobs
Windows e Web usam `always()` após a suite: gates vermelhos continuam visíveis,
mas não congelam os canais de entrega num commit antigo; Pages só publica se o
export Web correspondente passar. O próprio job Pages também usa `always()` e
`needs.web.result == 'success'`, evitando herdar o failure ancestral dos testes
quando o export Web terminou verde.

## Production Asset Validator v2 — infraestrutura técnica

Branch `tools/production-asset-validator-v2`: validator determinístico e
somente-leitura preparado em `tools/production_asset_validator/`, com contrato
JSON configurável, relatórios JSON/Markdown, contact sheet 1:1 e fixtures
sintéticas. Suite própria: 6 testes, 0 falhas. Não houve decisão artística,
geração/integração de assets nem alteração de runtime; 9B não foi iniciada.

Próximo passo: após conclusão de 9A, fornecer em 9B manifestos e caminhos/hash
das referências aprovadas, correr o validator e encaminhar `REVIEW` ao Game
Master.

## Execution 8.1E — Congelamento do save — **RESOLVIDO**

Estado: **PASS.** `EstadoJogo.guardar()`: **2047 ms -> 9,2 ms** de mediana
(pior 14,3 ms), medido na mesma ferramenta que deu o 2047 (`tools/verifica_gravar.tscn`).
Cabe num frame a 60 Hz. Relatório: [execution_8_1e_causa_do_congelamento.md](execution_8_1e_causa_do_congelamento.md).

**A causa era CPU, não disco.** `ProgressionIDs.identidades()` relia e
parseava `data/level_manifest.json` **1312 vezes por gravação** (seis
validações completas em `escrever_seguro()`, e `reward_ids()` sozinho chama-o
uma vez por nível). Corrigido com cache do manifesto + identidades derivadas,
aquecido no `_ready()` do `EstadoJogo`.

**A 8.1C estava enganada** ao culpar o antivírus/`%APPDATA%`: o custo real de
tocar no disco por gravação é **~2 ms**. A exclusão do Windows Defender que lá
ficou sugerida não era precisa.

**`save_pipeline.gd` foi REMOVIDO.** Com 9,2 ms já não é preciso thread
nenhuma, e o export Web é `single-threaded` — a thread nunca teria resolvido lá
nada. O desenho fica no commit `0269d20` se voltar a ser preciso.

**Falta:** validação a jogar no `build/windows/Koliani.exe` (checkpoint,
dano de projétil, dano repetido, morte/reaparecimento). O `.exe` está
construído e arranca limpo, mas jogar é com o Paulo.

**Trava de método:** `godot --headless --path . --check-only --script res://tools/x.gd`
antes de correr qualquer cena de ferramenta nova. Um erro de parse não estoira
— pendura o motor com o log vazio.

## Execution 8.1D — Save não-bloqueante — **INCOMPLETA**

Estado: **BLOCKED.** Sessão encerrada antes de ligar a implementação.
**O jogo continua a congelar ~2 s** no checkpoint e ao levar dano.

`scripts/save_pipeline.gd` está escrito e compila (suite verde), mas
**nenhum ficheiro o usa** — é código inerte. Falta ligá-lo ao `EstadoJogo`.
Relatório e passos exatos: [execution_8_1d_save_nao_bloqueante.md](execution_8_1d_save_nao_bloqueante.md).

**Pista principal para quem retomar:** `ProgressionIDs.identidades()` lê e
faz parse de `data/level_manifest.json` **do disco a cada chamada**, e
`escrever_seguro()` faz seis validações completas que a chamam dezenas de
vezes. Os ~2 s são provavelmente isso — não a escrita, não o antivírus.
**Não medido**, é leitura de código. Se se confirmar, um cache do manifesto
resolve Windows **e** Web (na Web não há threads, o fallback é síncrono e a
thread de fundo sozinha não a salvava).

**Armadilha:** uma cena de ferramenta com erro de parse não estoira — o
Godot fica a correr para sempre sem imprimir nada. Procurar `Parse Error`
no log antes de assumir que está lento. Custou duas corridas de 10 minutos.

## Execution 8.1C — Combat Freeze / Hit-Stop Gate

Estado: **PARTIAL PASS — CAUSA PRINCIPAL PROVADA, CORREÇÃO POR DECIDIR.**

**O congelamento é GRAVAR O SAVE.** `EstadoJogo.guardar()` custa **~2047 ms
de mediana** na thread principal (`tools/verifica_gravar.gd`, 12 gravações).
É chamado por `ativar_checkpoint()` (passar num checkpoint) e por
`perder_vida()` — os dois gatilhos que o Paulo identificou. Explica também
todos os buracos de ~2 s que apareceram nas medições desta sessão (2019,
1975, 1953, 2254, 2081 ms), incluindo o "parada no spawn aos 9 s".

Não há esperas no código: são ~10 operações de ficheiro síncronas por
gravação (escrever TEMP, ler TEMP, ler primary, ler backup, escrever backup,
apagar primary, renomear), cada uma inspeccionada pelo antivírus em
`%APPDATA%` — ~200 ms cada.

**Teste de confirmação sem tocar em código:** excluir
`%APPDATA%\Godot\app_userdata\Koliani` do Windows Defender e voltar a jogar.

**NÃO se mexeu no sistema de save** — tem suite própria de robustez
(corrupção, recuperação, versões, backup validado). Opções por risco
crescente: (a) gravar em thread de fundo mantendo a lógica de integridade;
(b) juntar/espaçar gravações; (c) cortar as leituras de validação repetidas
(esta mexe nas garantias que os testes protegem).

Já corrigido e provado nesta execução:

- **música do chefe**: `provocar()` → `Musica.boss()` fazia `load()` no
  primeiro golpe, na thread principal, com o `time_scale` já a 0 (hitstop) —
  o temporizador que repõe o tempo não podia correr. **2019 ms → 23,4 ms**;
- **áudio dos passos**: `som.gd` carregava cada SFX à primeira utilização.
  Saltar/andar tocava `passo1/2/3.ogg` pela primeira vez e congelava. Agora
  `Som.aquecer_tudo()` pede os 66 sons em segundo plano no arranque —
  **zero carregamentos de áudio depois do nível arrancar**;
- **hit-stop** reduzido para ≤2 frames no frequente e ≤4 no raro (era 7–10).
  Combo + golpe levado: ~97 ms → ~28 ms.

**Correção ao que a 8.1 dizia:** a recarga de nível **não custa 150 ms, custa
~2 s**. A 8.1 mediu com o `delta` do motor, que vem **limitado**; medir
engasgos exige tempo de parede (`Time.get_ticks_usec()`).

Branch `perf/windows-gate-8-1`, commit `b0e9728`. `origin/master` continua
`b2fd8a0` — **não fundir sem revisão do Game Master**.

## Execution 8.1B — Physics Interpolation / Cadence Fix

Estado: **TECHNICALLY VALIDATED / GAME MASTER CADENCE REVIEW REQUIRED**.

`physics/common/physics_interpolation = true`, com a física a continuar a
**60 Hz**. Nenhuma constante de movimento, salto, dash, combate ou câmara
mudou. Provado sobre a imagem desenhada (gravador de filme a 165 fps): o
desvio-padrão da diferença entre frames consecutivos caiu **59 %** e o rácio
p90/mediana passou de **4,19× para 2,06×** — o movimento deixou de chegar aos
solavancos.

Auditados e resolvidos: 4 teletransportes com `reset_physics_interpolation()`
(respawn, rebordo, fosso dev, portal) e 10 nós animados no `_process` com
`PHYSICS_INTERPOLATION_MODE_OFF`. O risco escondido era a **viragem**
(`scale.x = ±1`), que interpolada esmagava o sprite; resolvido desligando no
`$Sprite` (o modo é herdado). Como `ChefeBase extends DemonioBase`, uma
correção cobre inimigos e chefes todos.

A câmara não foi tocada: é filha da Koliani e só escreve `offset`, que não é
interpolado. O motor avisa que passa a `Camera2D` para modo física — é
esperado; o efeito é o screen shake ficar amostrado a 60 Hz.

Suite, jornada 1–100, alcance, Execution 7 targeted e combate runtime: PASS.
Windows e Web/PWA reexportados do mesmo source; cache PWA
`1789071258|42187478`. Relatório:
[`execution_8_1b_physics_interpolation.md`](execution_8_1b_physics_interpolation.md).

Backlog que fica OPEN por instrução: recarga de cena ~150 ms e compilação de
pipelines à primeira utilização.

## Execution 8.1 — Windows Performance Gate

Estado: **PARTIAL PASS — DIAGNÓSTICO FECHADO / DECISÃO DO GAME MASTER
NECESSÁRIA**. **Nenhuma alteração ao runtime do jogo.**

Os "framedrops severos" no `Koliani.exe` **não são falta de desempenho**. Com
o VSync desligado o L1 corre a **1388 FPS (0,72 ms/frame)** a 1080p; script
0,03 ms, física 0,2 ms, 129 draw calls. Em 47 recargas os nós ficam fixos em
871 e os órfãos em 0 — **não há fugas**. Menu, L1, L3, L5 e o Coração
Putrefacto têm todos o mesmo tempo de frame.

Causas-raiz provadas:

1. **Cadência (PROVEN):** física a 60 Hz num painel de 165 Hz com
   `physics_interpolation` desligado → **67,2 % dos frames desenhados não têm
   avanço nenhum**. Os FPS ficam nos 165 e o movimento anda aos degraus. É o
   que se lê como "framedrop" sem os FPS caírem.
2. **Carregamento de cena (PROVEN):** ~150 ms de congelamento em cada morte e
   troca de nível (todos os picos > 33 ms medidos são recargas).
3. **Primeira utilização (LIKELY):** quedas esparsas de um segundo no EXE
   real; o preset de export não tem `shader_baker/enabled`.

As três correções são arquiteturais e ficam **para decisão** (secção 25 do
briefing). Relatório e números:
[`execution_8_1_windows_performance_gate.md`](execution_8_1_windows_performance_gate.md).
Sonda reutilizável: `tools/perf_gate.tscn`.

Duas armadilhas de método registadas: morrer recarrega a cena atual, o que
reinicia qualquer sonda que seja a cena; e a suite corre por **cena**
(`--headless --path . res://tests/run_tests.tscn`), não por `--script` — e
precisa da pasta `work/`.

## Execution 8 — Real Game Production Integration

Estado: **PARTIAL PASS — REAL RUNTIME TECHNICALLY VALIDATED / HUMAN REVIEW
REQUIRED**. O fluxo real `Koliani.exe` → menu → mapa/seletor → `Main` →
L1–L5 foi traçado. A Koliani 6B e os 44 frames SAFE estão ativos nos cinco
níveis; panorama/Heart Tree aprovado de 6A foi ligado em toda a Região I;
combate, guardiões, Coração Putrefacto e reward foram confirmados ativos.

Exports release já não oferecem `DEVELOPER MODE`, `BOSS TEST`, `TESTAR OUTRO
NÍVEL` nem `FLYMODE`. Windows e Web/PWA foram regenerados do mesmo estado;
smoke Windows, capturas reais, HTTP/Chrome e service worker passaram. Cache
PWA: `1789065387|5837615`. Evidência:
`work/execution_8/real_runtime/region1_runtime_contact_sheet.png`. Relatório:
`docs/execution_8_real_game_production_integration.md`. Retoma externa:
`docs/claude_handoff_execution_8.md`.

Plataformas, props, inimigos/guardiões, boss art, parte de UI e VFX/SFX
continuam legacy por falta de assets de produção aprovados. O kit regional
ImageGen permanece apenas tecnicamente validado e não foi promovido para
L2–L5. **HUMAN VISUAL/COMBAT FEEL/BALANCE/PLAYTEST e DEVICE VALIDATION
REQUIRED**. Próximo passo: revisão humana do build 8 e criação/aprovação dos
gaps; não iniciar Região II.

## Execution 7 — Region I Vertical Slice Completion

Estado: **PARTIAL PASS — TECHNICALLY VALIDATED / HUMAN REVIEW REQUIRED**.
Combate base foi fechado em três golpes com janelas ativas/deduplicação,
ataque aéreo singular e integração de Dash sem alterar movimento, câmara ou
colisões. L1–L4 terminam agora em guardiões (Ghorak, Morvanna, Rainha
Aracnídea e Entrevane) sem estado/baú de boss; L5 mantém o boss regional
canónico Coração Putrefacto, fase 2 a 50%, Dash e reward idempotente.

Suite, gates dirigidos, source/generator, jornada 1–100, alcance, L4 interior,
checkpoints L5, reward e renderer real passaram. Evidência:
`work/execution_7/review/region1_vertical_slice_review.png`,
`combat_review.png`, `region1_boss_review.png`. Relatório completo:
`docs/execution_7_region1_vertical_slice_completion.md`.

Windows `build/windows/Koliani.exe` e Web/PWA `build/web/index.html` foram
regenerados e passaram smoke local; cache PWA `1789055058|5419303`. Para
retoma noutra ferramenta, usar `docs/claude_handoff_execution_7.md`.

Produção final de combate/inimigos/boss e expansão visual L2–L5 continuam em
falta; legacy funcional foi mantido. **HUMAN VISUAL REVIEW REQUIRED, HUMAN
COMBAT FEEL REVIEW REQUIRED, HUMAN BALANCE REVIEW REQUIRED e HUMAN PLAYTEST
REQUIRED**. Próximo passo: rever Região I nos builds finais desta execução;
não iniciar Região II.

## Execution 6B — Character + Level 1 Completion

Estado: **PARTIAL PASS — TECHNICALLY VALIDATED / HUMAN VISUAL REVIEW
REQUIRED**. A causa das pernas cortadas era a extração histórica da faixa
`run`: divisão uniforme sobre células de larguras reais irregulares, seguida
de seleção que descartou componentes legítimos dos membros. `run_03`–`run_09`
foram reextraídos apenas da autoridade 05; resultado: 44/44 frames ativos
`SAFE`, sete `FIXED`, zero bloqueados e zero divergências de atlas.

Escala `0,82`, offset `-15,170732`, pivot `(80,90)`, canvas `160×96`, baseline
`Y=90`, colisão, movimento e câmara foram preservados. Renderer real, targeted
de Koliani/Level 1/Movement+Camera, alcance e suite completa: PASS.

O ambiente 6A foi preservado. O kit modular local 12/12 passou tecnicamente,
mas permanece `validated`, com origem `_source/imagegen_v1`; não foi promovido
sem aprovação visual. Legacy funcional de plataformas, inimigos, HUD, VFX e
áudio foi retido onde falta produção aprovada. Windows e Web/PWA foram
regenerados; smoke local PASS; cache PWA `1789047133|5780304`.

Evidência: `work/execution_6b/preview/level1_6b_review.png`,
`level1_6a_vs_6b.png`, `koliani_6b_gameplay_review.png` e relatório
`docs/execution_6b_character_level1_completion.md`.

Próximo passo autorizado: **HUMAN VISUAL REVIEW REQUIRED** da Koliani 6B e do
Level 1 6A/6B. Não iniciar 6C nem Levels 2–5.

## Execution 6B — Character + Level 1 Completion

Estado: **PARTIAL PASS — TECHNICALLY VALIDATED / HUMAN VISUAL REVIEW
REQUIRED**. A causa das pernas cortadas era a extração histórica da faixa
`run`: divisão uniforme sobre células de larguras reais irregulares, seguida
de seleção que descartou componentes legítimos dos membros. `run_03`–`run_09`
foram reextraídos apenas da autoridade 05; resultado: 44/44 frames ativos
`SAFE`, sete `FIXED`, zero bloqueados e zero divergências de atlas.

Escala `0,82`, offset `-15,170732`, pivot `(80,90)`, canvas `160×96`, baseline
`Y=90`, colisão, movimento e câmara foram preservados. Renderer real, targeted
de Koliani/Level 1/Movement+Camera, alcance e suite completa: PASS.

O ambiente 6A foi preservado. O kit modular local 12/12 passou tecnicamente,
mas permanece `validated`, com origem `_source/imagegen_v1`; não foi promovido
sem aprovação visual. Legacy funcional de plataformas, inimigos, HUD, VFX e
áudio foi retido onde falta produção aprovada. Windows e Web/PWA foram
regenerados; smoke local PASS; cache PWA `1789047133|5780304`.

Evidência: `work/execution_6b/preview/level1_6b_review.png`,
`level1_6a_vs_6b.png`, `koliani_6b_gameplay_review.png` e relatório
`docs/execution_6b_character_level1_completion.md`.

Próximo passo autorizado: **HUMAN VISUAL REVIEW REQUIRED** da Koliani 6B e do
Level 1 6A/6B. Não iniciar 6C nem Levels 2–5.

## Region I — Modular Sprite Kit v1

Estado: **TECHNICALLY VALIDATED / HUMAN VISUAL REVIEW REQUIRED**. As
autoridades aprovadas 08 e 10 foram convertidas em 12 sprites ambientais
individuais: terreno, remates, cantos, duas plataformas, raízes, musgo,
corrupção e bloco de ruína. Todos cumprem as dimensões 32/64/96 px, alfa,
nearest-neighbour e costuras declaradas no contrato; `validate_region_artkit`
passou com `12 presentes / 0 missing / 0 fails` e o Godot 4.7.2 importou os 12
PNGs.

Fontes, gerador e hashes foram preservados. Prancha de revisão:
`work/region_01_sprite_kit_v1/preview/region_01_sprite_review.png`. Não houve
integração no Level 1 nem alterações de gameplay, geometria ou Koliani. Próximo
passo: aprovação visual humana da prancha antes de qualquer integração.

## Delivery Sync — Windows + Web/PWA

Estado: **PASS LOCAL / REMOTE PAGES NOT CONFIGURED**. Em 10 de setembro de
2026, os presets existentes `Windows Desktop` e `Web` foram exportados do
working tree em `HEAD 24fdf3f` (com alterações locais 5G.1 preservadas) para
`build/windows/Koliani.exe` e `build/web/`. O atalho estabelecido
`Koliani (testar).lnk` continua a apontar para `jogar.bat` e foi confirmado a
lançar o novo `build/windows/Koliani.exe`; o executável anterior era de 6 de
setembro e, portanto, anterior à Execution 6A.

Smoke Windows real e smoke Web/PWA local: PASS. Ambos mostraram no Level 1 o
panorama/floresta, Heart Tree baked, cascatas, ruínas/silhuetas e foreground
da 6A. O PWA gerou manifest, service worker e cache novo
`1789024307|5115130`, que elimina caches antigos com o prefixo Koliani. A rota
GitHub Pages existe no workflow, mas o deployment público permanece 404 e a
própria configuração regista que Pages ainda precisa de ativação no repo.
Metadados locais ignorados em `build/*/BUILD_SOURCE.txt` ligam os artefactos ao
commit e ao estado dirty.

Próximo passo: **HUMAN PLAYTEST REQUIRED** para o bloqueio visual já conhecido
das pernas/lower body da Koliani; não foi alterado nesta sincronização.

## Execution 6A — Level 1 Approved Visual Build

Estado: **PARTIAL VISUAL BUILD / PRODUCTION ASSETS MISSING — HUMAN REVIEW
REQUIRED**. O panorama aprovado da referência 08 foi recortado losslessly e
integrado em toda a rota do Level 1, incluindo Heart Tree, cascatas, ruínas,
floresta profunda e foreground baked. Foram removidos do runtime o céu,
landmark, máscaras de plataforma, midground e foreground vetoriais genéricos
do target 5C. Geometria, colisões, 20 plataformas, porta, inimigos, Ghorak e
Koliani 5G.1 foram preservados.

Verificação 6A, 5G.1, Movement/Camera, alcance e suite completa: PASS. Renderer
Vulkan Forward Mobile: PASS em oito pontos. O módulo visual tem agora 29 nós,
3 luzes e 1 emissor/34 partículas, contra 406 nós no 5C. Evidência:
`work/execution_6a/preview/level1_6a_review.png` e
`work/execution_6a/preview/level1_before_after.png`. Relatório completo:
`docs/execution_6a_level1_implementation.md`.

Próximo passo: **HUMAN PLAYTEST REQUIRED** para legibilidade/continuidade e
produção, sem redesign, dos layers alpha, tiles Hybrid, props, inimigo
infectado, replacement de Ghorak, HUD e áudio ainda em falta.

## Execution 6A — Level 1 Approved Visual Build

Estado: **PARTIAL VISUAL BUILD / PRODUCTION ASSETS MISSING — HUMAN REVIEW
REQUIRED**. O panorama aprovado da referência 08 foi recortado losslessly e
integrado em toda a rota do Level 1, incluindo Heart Tree, cascatas, ruínas,
floresta profunda e foreground baked. Foram removidos do runtime o céu,
landmark, máscaras de plataforma, midground e foreground vetoriais genéricos
do target 5C. Geometria, colisões, 20 plataformas, porta, inimigos, Ghorak e
Koliani 5G.1 foram preservados.

Verificação 6A, 5G.1, Movement/Camera, alcance e suite completa: PASS. Renderer
Vulkan Forward Mobile: PASS em oito pontos. O módulo visual tem agora 29 nós,
3 luzes e 1 emissor/34 partículas, contra 406 nós no 5C. Evidência:
`work/execution_6a/preview/level1_6a_review.png` e
`work/execution_6a/preview/level1_before_after.png`. Relatório completo:
`docs/execution_6a_level1_implementation.md`.

Próximo passo: **HUMAN PLAYTEST REQUIRED** para legibilidade/continuidade e
produção, sem redesign, dos layers alpha, tiles Hybrid, props, inimigo
infectado, replacement de Ghorak, HUD e áudio ainda em falta.

## Execution 5G.1 — Correção visual do piloto no Level 1

Estado: **PARTIAL PASS / HUMAN PLAYTEST REQUIRED**. A medição determinística
dos sete strips ativos encontrou 44 frames únicos: 37 `SAFE` e 7
`ACTUAL_CLIPPING`. O número 45 anteriormente documentado inclui
`run_brake_01`, que não integra o fallback atual. Nenhum frame toca o canvas
normalizado `160×96`; as margens mínimas são 12 px no topo, 38 px nos lados e
6 px no fundo, com baseline opaca uniforme em `Y=89`.

A causa primária é recorte-fonte anterior à normalização: `run_03`–`run_06`
tocam o limite esquerdo do recorte original e `run_07`–`run_09` o limite
direito. Padding, offset ou escala não recuperam esses pixels ausentes, e não
foram inventados, redesenhados ou reextraídos sprites. Como correção parcial da
escala pequena observada no Level 1, a apresentação global do piloto passou de
`0,75` para `0,82`; o offset Y passou de `-12,666667` para `-15,170732`,
preservando pés em `y=22`, pivot `(80,90)`, colisão e hitbox.

Verificador 5G, Movement + Camera 4A, alcance do Level 1 (20 plataformas e
porta alcançável) e suite completa: PASS. Smoke/captura real OpenGL 3.3 na
NVIDIA RTX 5070: PASS, com avisos ambientais já conhecidos de `user://`,
certificados e opções. Relatório: `work/execution_5g_1/frame_margin_report.json`.
Comparação: `work/execution_5g_1/preview/before_after_visual_fix.png`.

Próximo passo único: **HUMAN PLAYTEST REQUIRED** no Level 1 para validar escala
`0,82`, contacto dos pés, face, centro visual e popping das transições antes de
aceitar a correção. Os sete frames `run_03`–`run_09` continuam a exigir fonte
completa para eliminar o clipping sem inventar arte.

## Execution 5G — Level 1 Locomotion Visual Pilot

Estado: **TECHNICAL PASS / HUMAN PLAYTEST REQUIRED**. Os 45 frames limpos de
`idle` (10), `run` (12), `turn` (4), `run_start` (6), `jump_start` (4),
`jump_loop` (4) e `fall` (4) foram copiados sem alteração para
`assets/sprites/pixel/koliani_visual_pilot_5g/` e ligados ao runtime apenas na
instância da Koliani do Level 1. A seleção de animação observa o estado físico
existente, mas não altera movimento, salto, gravidade, dash, combate, colisões,
hitboxes, câmara, save/sessão, localização ou progressão.

`run_brake` é um fallback explícito com `run_10`–`run_12` + `idle_01`;
`land` (com alias legado `aterrar`) usa `fall_04` + `idle_01`. Combate e outros
estados sem frames 5G continuam no piloto 5B. A flag nova está desligada por
omissão, ativa apenas em `Floresta_Putrefata.tscn` e pode ser desligada para
rollback imediato.

Validação: targeted 5G PASS, suite completa PASS, Movement + Camera 4A PASS,
alcance do Level 1 PASS (20 plataformas, porta alcançável), smoke OpenGL real
com o target 5C ativo PASS e nove capturas em `work/execution_5g/`. O import
reportou apenas avisos ambientais/preexistentes de escrita em `user://` e
ficheiros AppleDouble `.wav`; o smoke real final não reportou erros.

Ficheiros 5G: `scripts/koliani.gd`; uma propriedade em
`scenes/levels/Floresta_Putrefata.tscn`; sete PNG + `.import` na pasta do piloto;
os pares `.gd`/`.tscn` `tools/verifica_koliani_visual_pilot_5g` e
`tools/shot_koliani_visual_pilot_5g`; `PRIORIDADES.md`, `docs/plano_atual.md` e
este ficheiro. Capturas em `work/execution_5g/` são evidência ignorada pelo Git.

Próximo passo único: **HUMAN PLAYTEST REQUIRED** no Level 1 para escala,
legibilidade, continuidade das nove sequências visuais e glitches nos fallbacks.
Não iniciar outro lote antes dessa decisão.

## Recuperacao Medium — sprites base normalizados

Estado: **PARTIAL PASS / HUMAN REVIEW REQUIRED**. Foram inventariados os 56
frames existentes e revistos os 13 alvos prioritarios. A selecao deterministica
do componente alto/central recuperou os sete falsos recortes (`turn_04`,
`jump_start_03`, `jump_start_04`, `jump_loop_01`, `jump_loop_03`, `fall_01` e
`fall_04`) sem criar pixels. A revisao geral corrigiu ainda 23 contaminacoes
objetivas por moldura/legenda. Existem 45 frames limpos e strips completos de
`idle`, `run`, `turn`, `run_start`, `jump_start`, `jump_loop` e `fall`.

Continuam bloqueados `run_brake_02`–`run_brake_06` e `land_01`–`land_06` como
`VFX_SEPARATION_REQUIRED`, porque poeira/impacto toca pes ou corpo e a remocao
segura exigiria inferir pixels ocultos. `run_brake` e `land` nao receberam strip
final. Relatorio, folhas de revisao, frames e fonte deterministica:
`work/koliani_extraction_recovery_medium/`. Runtime, cenas, gameplay e assets
integrados permaneceram inalterados.

Proximo passo unico: revisao humana da folha
`work/koliani_extraction_recovery_medium/preview/review_before_after.png` e
fornecimento de frames sem VFX para os 11 bloqueios; nao integrar no Godot antes
dessa decisao.

## Execution 5F.1 — limpeza dirigida da extração

Estado: **TARGETED CLEANUP COMPLETE / HUMAN REVIEW REQUIRED**. Foram
inspecionados os 56 frames normalizados existentes em
`work/koliani_extraction_full/`; nenhum frame aprovado foi alterado. A revisão
identificou 7 frames com falha estrutural de extração (`turn_04`,
`jump_start_03`, `jump_start_04`, `jump_loop_01`, `jump_loop_03`, `fall_01`,
`fall_04`) e os 6 frames de `land` com poeira/impacto fundidos. Não foi segura
uma separação determinística sem risco de perder corpo/cabelo/pernas ou
inventar pixels. A folha exclusiva de revisão está em
`work/koliani_extraction_full/preview/problem_frames_review.png`.
Runtime permaneceu inalterado. Próximo passo único: revisão humana destes 13
frames; `land_01`–`land_06` permanecem `VFX_SEPARATION_REQUIRED`.

## Execution 5E — piloto de extração automática

Estado: **PILOT EXTRACTION READY / HUMAN REVIEW REQUIRED**. Foram extraídos
deterministicamente seis testes da prancha aprovada `05`: dois Idle, dois Run,
um Jump Loop e um Land. Cada recorte mantém a resolução natural e tem uma
versão RGBA com alpha binário `0/255`; não houve geração de arte, integração
Godot ou alteração de runtime. A preview compara cada resultado com o original
sobre fundos preto, branco e verde. Não há dano grosseiro visível, mas halo,
microperdas e o VFX ligado do Land dependem de revisão humana.

Próximo passo único: **HUMAN REVIEW OF CONTACT SHEET** em
`work/koliani_extraction_pilot/preview/koliani_extraction_pilot_contact_sheet.png`.
Não extrair os restantes frames antes da aprovação. Relatório:
`work/koliani_extraction_pilot/reports/execution_5e_pilot.md`.

## Pixelorama capability test — master sprite pilot

Estado: **PIXELORAMA NOT USABLE FOR ART AUTHORING** neste ambiente de agente.
O Pixelorama portátil `v1.2.2-stable` existe e executa localmente; a versão Web
oficial também carregou no browser e aceitou interação básica. Contudo, a
janela nativa não é exposta ao controlo de computador e o editor Web surge
inteiro como um único canvas sem controlos semânticos, seleção de layers ou
feedback de píxel acessíveis. O controlo por coordenadas não oferece precisão
nem auditabilidade suficientes para reconstruir com qualidade de produção uma
personagem de `64–68 px`.

O executável confirmou apenas opções de sistema do Godot. A documentação
oficial descreve uma CLI para inspeção/exportação de projetos existentes e uma
API de extensões carregada dentro da aplicação; nenhuma delas fornece neste
setup um canal comprovado para autorar o desenho. Por isso não foram criados
PNG, PXO, preview ou frames adicionais, e runtime/gameplay permaneceram
inalterados.

Próximo passo único: expor a janela nativa do Pixelorama a um canal de controlo
com precisão de canvas e layers, e então repetir este piloto de um só sprite.

Follow-up de extração: a folha correta
`Koliani_1.0_Master_Package_v2/references/approved/01_KOLIANI_VISUAL_AUTHORITY_v1_1.png`
é um PNG legível de `1536×1024`, mas está em modo `RGB`, sem canal alpha. As
poses estão compostas sobre painéis/fundos opacos. A extração parou sem criar
recortes ou contact sheet, porque isolar personagens com transparência exigiria
remoção/reconstrução de fundo em vez de simples crop lossless.

## Execution 5D.2 — Reconstrução limpa de sprites de produção

Estado: **MASTER TECHNICAL PASS / HUMAN VISUAL REVIEW REQUIRED**. Foi criado
um master novo em `assets/sprites/koliani_production/master/`, gerado de raiz
por `tools/generate_koliani_master.py`, sem recortar ou limpar as pranchas
aprovadas. O PNG passa o gate técnico: `160×96`, RGBA, alpha estritamente
`0/255`, altura visual `66 px`, pivot `(80,90)`, pés em `Y=90`, orientação à
direita e ausência de VFX/fundo residual.

A tentativa built-in de geração visual produziu novamente RGB sem alpha e
checkerboard incorporado; não entrou no projeto. O master final tem fonte
determinística editável. Contrato, pastas dos 40 frames e sete famílias de VFX
separadas ficaram preparados, e `tools/validate_koliani_production.py` mantém
o lote em `PENDING 0/40` e impede strips antes de `40/40 PASS`. Gameplay,
cenas e runtime não foram alterados.

Próximo passo único: revisão visual humana do master. Se aprovado, produzir os
40 frames base mantendo identidade, cabelo, escala, pivot e baseline; só após
o gate completo montar strips e avaliar integração. Relatório:
[execution_5d_2_sprite_production.md](execution_5d_2_sprite_production.md).

## Execution 5D.1 — Native Locomotion Asset Production

Estado: **IMAGE GENERATION CAPABILITY REQUIRED**. A capacidade `imagegen`
disponível foi testada com a autoridade visual `01` e a referência de pose
`05`. Produziu uma linha coerente de 10 poses Idle, mas os dois outputs — a
geração original e uma iteração explícita de extração de fundo — foram PNG
`RGB` de `1983×793`, sem canal alpha e com checkerboard incorporado.

O contrato exige frames nativos `160×96` em RGBA com alpha 0 real e proíbe
remoção de fundo contaminado ou conversão de pranchas em falso asset. Por
isso, nenhum PNG foi copiado para o projeto, as restantes 30 poses não foram
geradas e runtime, cenas, gameplay e integração permaneceram inalterados.

Próximo passo único: executar o brief 5D.1 numa ferramenta de produção que
garanta exports RGBA nativos com transparência real e controlo de frames,
submetendo depois os 40 frames e seis strips ao gate técnico e à revisão
visual humana.

## Execution 5D — Production Asset Gate

Estado: **ART ASSET REQUIRED**. A inspeção técnica e visual direta das
referências aprovadas `01`–`07` confirmou que são pranchas de autoridade, não
assets de produção seguros. `01`–`04` são RGB sem alpha; `05` e `07` têm alpha
global anómalo sem qualquer píxel totalmente opaco, e `07` nem sequer contém
alpha 0; `06` tem áreas transparentes, mas preserva cabeçalhos, barras,
números, linhas e VFX numa única composição e não mantém de forma segura a
identidade/cabelo da autoridade `01`.

Idle, Run, Jump Start, Jump Loop, Fall e Land ficaram todos classificados
`REFERENCE_ONLY`. Não houve extração, criação de assets, integração, testes de
runtime ou alteração de gameplay. O relatório e a especificação dos seis
exports RGBA necessários estão em
[execution_5d_asset_gate.md](execution_5d_asset_gate.md).

Próximo passo único: produzir os seis strips RGBA nativos conforme essa
especificação e repetir o asset gate antes de tocar no runtime.

## Master Package v2 — verificação documental

Estado: **PASS WITH DOC FIXES**. O pacote
`Koliani_1.0_Master_Package_v2/` está instalado ao lado de `project.godot` com
README, instruções de instalação, regras de agente, 17 documentos de design e
dois manifestos de referências. Os 12 PNGs esperados estão presentes em
`references/approved/`, abrem como PNG e os SHA-256 correspondem integralmente
a `references/manifest.json`.

O pacote é Source of Truth para produto/design aprovado; código, testes e
documentação operacional local continuam a vencer para implementação. A
autoridade de personagem está explícita: Koliani tem 16 anos, proporções
atléticas não chibi, cabelo longo completamente solto com raízes pretas e
pontas vermelhas, roupa black/charcoal com vermelho e assinatura violeta da
Shadowblade. A precedência é `01`–`06`; `07` vale apenas para VFX, e figuras
incidentais dos Production Packs não a substituem.

Foi corrigido `docs/master_package_integration.md`, que ainda descrevia o
pacote anterior e referências aprovadas ausentes. As referências v2 são
**APPROVED DESIGN**, não assets production-ready; readiness técnica não foi
avaliada nesta execução. Runtime, cenas, gameplay, imagens e assets não foram
alterados.

Próxima execução, com Luna Medium: fazer um asset gate técnico das referências
`01`–`07`; provar por frame origem, alpha real, dimensões, grelha, baseline,
pivot, separação personagem/VFX e fidelidade à autoridade `01`; parar como
`ART ASSET REQUIRED` se não existirem fontes RGBA separáveis. Só após PASS,
produzir um lote reversível de idle/run/jump/fall/land, validá-lo e integrá-lo
exclusivamente no Level 1 sem alterar gameplay, colisões, hitboxes, movimento,
câmara, save ou progressão; terminar com testes direcionados, suite completa,
captura em renderer real e `HUMAN PLAYTEST REQUIRED`.

## Asset Production Pilot v1.1 — Movement Core

Estado: **ASSET PRODUCTION REQUIRED**. A auditoria conservadora encontrou 16
frames candidatos para idle, run, jump, fall e land, mas nenhum cumpre o
contrato v1.1. A folha `koliani_premium_v1_sheet.png` e as duas referências de
branding não têm alpha real; a folha tem checkerboard incorporado e apresenta
cabelo preso/ponytail. Os strips RGBA existentes foram derivados por remoção
automática desse fundo, `run` inclui poeira colada e `aterrar` reutiliza poses
de fallback em vez de um export dedicado.

`asset_contract_v1_1.json` regista fontes, grelha e falhas semânticas;
`tools/validate_assets.py` mede formato, modo, alpha, dimensões, bounding box,
baseline e pivot por frame. Relatório: `work/koliani_asset_pilot_report.json`,
com 0 PASS e 16 FAIL. Nenhum frame foi copiado para
`assets/sprites/koliani_v1_1/pilot/` e nenhuma referência original foi
alterada.

Próximo passo seguro: produzir exports RGBA nativos de idle, run, jump, fall e
land, com cabelo longo completamente solto, identidade consistente, alpha 0
real, personagem separada de VFX e grelha/pivot documentados; depois repetir o
validator antes de qualquer integração no runtime.

## Onde está o projeto

- Execution 1A: **DONE / PASS**.
- Execution 1A.1: **DONE / PASS**.
- Execution 1B: **DONE / PASS**.
- Execution 1C: **DONE / PASS**.
- Execution 2: **DONE / PASS**.
- Execution 3A: **DONE / PASS** — Save Foundation.
- Execution 3B: **DONE / PASS** — Stable Progression IDs.
- Execution 3C: **DONE / PASS** — Level Session + Checkpoint State.
- Execution 3D: **DONE / PASS** — Legacy Save / State Cleanup; schema v5.
- Execution 4A: **TECHNICAL PASS / HUMAN PLAYTEST REQUIRED** — primeiro passe
  de Movement + Camera; os parâmetros ainda não são finais.
- Execution 4B: **HUMAN-APPROVED** — transições da câmara aprovadas.
- Execution 5B: **TECHNICAL PASS / HUMAN PLAYTEST REQUIRED** — prototype
  Premium Pixel Art da Koliani, isolado ao Level 1.
- Execution 5C: **TECHNICAL PASS / HUMAN VISUAL REVIEW REQUIRED** — target
  Hybrid Cinematic de dois ecrãs no início do Level 1.

Baseline confirmado: 74 testes, 0 falhas, localização PASS, manifesto com 100
níveis/20 regiões PASS, 100 cenas carregáveis, jornadas PASS e geradores de
cena/atmosfera não destrutivos por defeito. O nível 12 em Safari/PWA num
iPhone continua **DEVICE VALIDATION REQUIRED**.

## Region I Production Art Kit R1.1 — infraestrutura

Estado: **PASS**. Foi criada a estrutura isolada
`assets/art/regions/region_01_forest/production/`, com pastas para terrain,
overlays, props, backgrounds, vfx e fontes. O manifest v1 fixa 12 stable IDs,
grid de 32 px, dimensões, alpha, repetição, nearest filter, uso e estado.

`tools/validate_region_artkit.py` usa apenas a biblioteca standard e valida
manifest, paths/naming, IDs duplicados, estrutura/CRC/IDAT de PNG, dimensões,
grid e alpha. Validação final: `WARNING` controlado, exit code 0, 12 esperados,
0 presentes, 12 missing, 0 fails; compilação Python, JSON e `git diff --check`
PASS. Um PNG real existente também foi aceite pelo leitor técnico.

Nenhum PNG final foi criado, nenhum asset foi integrado e cenas, TileMaps,
gameplay e `Region1HybridVisualTarget` permaneceram intocados nesta execução.
Próximo passo seguro: produzir e inserir o primeiro lote de PNGs reais
aprovados, antes de qualquer integração no Level 1.

## Execution 5C — retoma

O target Hybrid Cinematic está ativo apenas em `Floresta_Putrefata.tscn`, no
intervalo aproximado `x=-300..1250`. O módulo
`Region1HybridVisualTarget.tscn` acrescenta background/midground/foreground,
Heart Tree distante, revestimento visual natural sobre as quatro primeiras
superfícies, vegetação, névoa, 34 partículas, três luzes seletivas, uma amostra
de corrupção e uma assinatura de ataque Shadowblade. Não contém nós físicos.

A skin dark-fantasy das barras do HUD é aplicada e restaurada pelo próprio
módulo; não altera valores, sinais ou visibilidade lógica. `ativo = false` na
instância do Level 1 é o rollback: a validação provou que, nesse estado, o
módulo fica invisível e não monta filhos.

Validação 5C: targeted/rollback PASS; prototype 5B PASS; Movement/Camera PASS;
Level 1 com 20 plataformas e porta alcançável PASS; smoke e duas capturas
Forward Mobile reais PASS; suite completa 74/74; localização 701×6 preservada;
`git diff --check` PASS. Capturas em
`work/execution_5c/region1_hybrid_{idle,attack}.png`.

Orçamento medido: 406 nós no módulo, três `PointLight2D` e um
`CPUParticles2D` com 34 partículas. As luzes e partículas são contidas, mas os
CanvasItems precisam de profiling em Web/mobile antes de reutilizar o padrão.
Qualidade estética e salto geracional: **HUMAN VISUAL REVIEW REQUIRED**.

## Execution 5B — retoma

A direção visual aprovada fica registada como **HYBRID CINEMATIC 2D**:
personagens/inimigos/bosses em Premium Pixel Art, ambientes com apresentação
cinematográfica por camadas e UI dark-fantasy minimal. Nesta execução só a
Koliani foi trabalhada.

O prototype `koliani_premium_v1` usa células 160×96, escala 0,75, altura
visual aproximada de 59 px e pés em y=22. Traz idle 4, run 5, jump 3, fall 2,
dash 3, basic attack 6, hurt 2 e death 5; estados restantes usam fallbacks do
mesmo visual. A propriedade `usar_prototipo_premium` está ativa apenas na
Koliani de `Floresta_Putrefata.tscn`; o rig Shadowblade anterior continua a
ser o default e o rollback é desligar essa propriedade.

Validação: targeted 5B PASS, smoke Level 1 PASS, Movement/Camera PASS, suite
completa 74/74, localização 701×6 PASS, captura OpenGL real e `git diff
--check` PASS. Build:
`build/windows/Koliani-Execution-5B-Hybrid-Character-dev.exe`.

O fluxo de morte não mudou e pode interromper a animação visual de death.
Qualidade, legibilidade e feel finais: **HUMAN PLAYTEST REQUIRED**.

## O que acabou de ser feito

A Execution 3D removeu Hardcore do runtime e do schema atual. O schema v5 não
grava nem aceita `hardcore`/`hardcore_tempo_restante`; schemas v0–v4 continuam
reconhecidos e a migration v4→v5 descarta apenas esses campos, sem reativar a
feature e sem perder campanha, level session, bosses ou recompensas.

Checkpoint por coordenadas continua restrito a v0–v3 e é convertido pela
migration v3→v4; v5 grava apenas `level_session`. Identidades legacy de
progressão continuam apenas nas migrations e stable IDs permanecem canónicos.

Validação 3D: Save Foundation 11/11, Level Session 11/11, Progression IDs 6/6,
Movement/Camera targeted PASS, suite completa 74/74, localização 701×6 PASS e
`git diff --check` PASS. Movement/Camera: **HUMAN-APPROVED PARAMETERS
UNCHANGED**.

## Baseline da Execution 3C

A Execution 3C elevou o schema a v4 e separou `level_session` da progressão
permanente. A sessão guarda apenas `level_id` e `checkpoint_id`; coordenadas
são resolvidas pela cena em runtime e nunca representam arbitrary frame save.
O lifecycle begin/activate/recover/complete/abandon ficou explícito. IDs usam
`checkpoint_<level_id>_<ordem>` e o spawn seguro `_start`; sessão inválida
converge para `_start` sem perder campanha.

Morte/reload reconstrói a cena e repõe Koliani no último checkpoint seguro.
Fechar/reabrir retoma esse checkpoint; sair deliberadamente para mapa/menu
abandona a sessão. Concluir regista progressão permanente e limpa a sessão.
Bosses derrotados não reaparecem após reload; baús já reclamados continuam
idempotentes.

Validação 3C: 10 targeted PASS; L5 nos cinco checkpoints com
activation/death/reload/movement/jump PASS; boss/reward runtime PASS;
migrations, backup e future version PASS; L1/L5/L12/L31 PASS; regressões
3A/3B/Movement+Camera PASS; suite completa 74/74; localização 701×6 PASS;
`git diff --check` PASS. Movement/Camera: **HUMAN-APPROVED PARAMETERS
UNCHANGED**.

## Baseline Movement + Camera

A Execution 4B respondeu ao playtest da 4A sem alterar movement. A confirmação
da troca de direção horizontal passou de 0,10 s para 0,14 s e a resposta do
look-ahead de 5,8 para 3,8. Na vertical, a resposta passou de 8,5 para 5,0 e o
fall framing passou a exigir progressão conjunta de distância e velocidade,
eliminando o salto de alvo quando apenas um dos sinais já estava alto.
Distância de look-ahead, deadzone, limiares e visibilidade inferior foram
preservados.

Validação 4B: targeted Movement + Camera PASS; regressão de movement PASS;
smoke L1 PASS (run/jump/dash); smoke L5 PASS; cenário de queda e recenter PASS;
suite completa PASS, 0 falhas; `git diff --check` PASS. Build dev:
`build/windows/Koliani-Execution-4B-dev.exe`.

Os parâmetros foram posteriormente **HUMAN-APPROVED**. A 3C não os alterou.

## Baseline da Execution 4A

A Execution 4A centralizou aceleração, desaceleração e resposta de viragem,
deu à queda uma gravidade ligeiramente superior à subida e formalizou
aterragens light/medium/heavy sem input lock. A câmara ganhou look-ahead
horizontal com histerese, deadzone para hops, antecipação progressiva de
quedas e níveis de tremor Full/Reduced/Off. Dash, input, parede, gancho,
checkpoint e reload mantiveram os contratos existentes.

Validação: targeted Movement + Camera PASS; L1/L5/L12/L31 smoke PASS; ciclo
dos cinco checkpoints ativos do L5 com morte/reload/saída/salto PASS; atores e
gancho PASS; 100/100 cenas carregáveis; suite completa e localização PASS;
`git diff --check` PASS. Build dev:
`build/windows/Koliani-Execution-4A-dev.exe`.

**HUMAN PLAYTEST REQUIRED** para aceitar ou reafinar feel, distâncias,
resposta, tiers e conforto da câmara. Não iniciar 4B/4C antes dessa decisão.

## Baseline persistente anterior

A Execution 3B elevou o schema a v3 e acrescentou a migration sequencial
v2 → v3. O save atual usa IDs estáveis para nível atual/concluídos, bosses,
abilities, pistas/collectibles e recompensas únicas de baú. Níveis e bosses
reutilizam o manifesto da Execution 2; abilities têm mapping central e pistas
reutilizam o catálogo existente. Operações set-like são idempotentes e o baú
de boss não volta a atribuir recompensa após reload. Saves v2 preservam a
progressão equivalente; referências legacy desconhecidas são recusadas em vez
de adivinhadas. TEMP, backup/recovery, Hardcore e checkpoint mantêm a semântica
da 3A.

## O que vem a seguir

1. Revisão humana das duas capturas e do target 5C no Level 1: salto visual,
   leitura da Koliani, profundidade, corrupção/Shadowblade e HUD.
2. Manter pendente a validação do nível 12 num iPhone real com Safari/PWA.
3. Não escalar o estilo, otimizar em massa, alterar outros níveis ou iniciar a
   execução seguinte antes da decisão humana.

## Fonte canónica

- Visão e scope 1.0: [visao_koliani_1_0.md](visao_koliani_1_0.md)
- Decisões: [decisoes.md](decisoes.md)
- Estado das execuções: [execution_dashboard.md](execution_dashboard.md)
- Riscos e dívida: [backlog_tecnico.md](backlog_tecnico.md)
- Regras de agentes: [AGENTS.md](../AGENTS.md)

A auditoria de Execution 0 é evidência histórica, não o estado operacional
atual. Não repetir auditorias completas nesta retoma.
## 9H.16 PHASE A — P0 portal/physics concluída (13 set 2026)

- `ChefeBase` e `DemonioBase` inserem `Essencia` com `cena.add_child.call_deferred(m)` quando a morte nasce da hitbox. A recompensa mantém 7 motes/70 essência. `ControlosToque` abandona continuações quando o HUD sai da árvore e valida viewport/notificação.
- `tests/run_portal_9h16.tscn` passou quatro cenários com renderer real: normal, corrida, salto+dash e efeitos próximos. Confirmou uma entrada, reentrada bloqueada, L2, save e spawn; o dash foi observado no caso próprio.
- Build candidata Windows Vulkan `C:/Temp/koliani-9h16-candidate2.exe`: cinco processos separados, incluindo após reinício, terminaram com código 0. Logs `C:/Temp/koliani-9h16-c2-case*.log` sem `flushing queries`, `SCRIPT ERROR`, `ERROR:` ou softlock.
- WER confirma o histórico `APPCRASH` do EXE 0.18.6 (`c0000005`, RVA `0x16b3420`), mas a queda nativa não foi reproduzida na base 0.18.7 nem na candidata. Estabilidade atual PROVEN; causa do crash histórico NOT ASSESSABLE.
- QA crítico: portal/save/spawn PROVEN. Aviso de Camera2D e leaks ObjectDB dos arneses persistem fora do fluxo jogável. Combate completo, animações, mix, sensação e dispositivo mobile NOT ASSESSABLE. Banner central é PHASE C. Sem arte nova: NATIVE ART REQUIRED se houver lacuna.
- Fases B–F não iniciadas; próximo passo é PHASE B após este commit/push.
