# Auditoria global — 03 LEVEL DESIGN (Agente 3)

Data: 25 set 2026 · base `master` `bcac9fde` · modo **só diagnóstico** (nada no jogo foi alterado).
Save real: SHA256 antes = depois = `9DC2E4A161C38D16CBA5F29A42F2771CF9ED8F00FB2C63FF31DA48397A764238` (**inalterado**).
Todo o Godot correu pelo wrapper de sandbox (`godot_sandbox.sh`, APPDATA isolado).

## 0. Método (o que foi medido e como)

| Medição | Ferramenta (scratchpad `a3/`) | Âmbito |
|---|---|---|
| Geometria **tal como construída em runtime** (jornada incluída): plataformas, atores por tipo, câmaras, checkpoints, spawn/porta/chefe | `a3_medir.gd` (headless, instancia cada nível, espera o `_construir` diferido) → `medir_a/b.jsonl`; análise `a3_analisar.py` | **N1–N100, 100/100** |
| Perfis de geometria (vista lateral de cada nível inteiro) | `a3_perfis.py` → `img/a3/perfil_runtime_*.png` | N1–N20 + amostra N31–N99 |
| Capturas em janela real (2.º monitor, 8 ao longo de cada nível, do spawn à porta) | `a3_shots.gd` → `img/a3/nNN_KK.png` | N1–N20 (+ N45, N90) |
| Bot human-like (`tools/bot_humano_r2.gd`, cópia `a3_bot.gd` com a âncora da jornada limpa e marcos de tempo a cada 500 px) | 3 baterias, 600 s de jogo cada run, `--fixed-fps 60` | N1–N20 × 3 perfis (sem habilidades) + N6–N20 × 2 perfis (com todas as habilidades) = 90 runs |

**Limites honestos.** O bot não é um humano: falha trampolins (lança na vertical e tem de se dirigir no ar) e subidas no limite do duplo salto (já documentado em `docs/relatorio_bot.md`). Por isso **nenhum ponto onde o bot parou é tratado como softlock**; é tratado como *zona de alta exigência/candidato*. A 1.ª bateria (sem limpar a âncora da jornada) foi descartada exceto N1/N2. A bateria com habilidades dá **todas** as habilidades a partir do N6 (limite superior do jogador, não o estado real da campanha).

---

## 1. Diagnóstico em uma frase

**O Koliani não tem 100 níveis desenhados: tem UM nível — a "Jornada" de `scripts/gerador_corredor.gd` — esticado por uma fórmula de comprimento e reskinado 97 vezes, com uma sala desenhada à mão colada no fim que encolhe de ~3 000 px (Região I) para 650 px (Região III) e 450 px (N31–N100).** Quase todos os sintomas de level design (vazio, repetição, ritmo plano, "parece gerado", mortes por queda longe do checkpoint, regiões sem estrutura Teach→Boss) derivam disto.

---

## 2. Causas-raiz

### CR1 — P0 · A jornada procedural É o nível; o design autoral é um apêndice (REBUILD do pipeline)

**Evidência runtime (N1–N100, `a3_medir.gd`):**

| Região | comprimento médio (spawn→porta) | % jornada | plataformas jornada / sala à mão |
|---|---:|---:|---:|
| I (N1–5) | 8 372 px | 60 % | 29 / 21 |
| II (N6–10) | 9 309 px | 47 % (N8, N10 sem jornada) | 41 / 14 |
| III (N11–15) | 18 232 px | **96 %** | 107 / **15** (sala = 650 px, só a arena) |
| IV (N16–20) | 26 336 px | 91 % | 136 / 11 |
| V–VI (N21–29) | 31–33 k px | 92 % | ~170 / 12 |
| VII–XX (N31–99) | 14,8 k → 40,4 k px | **97–99 %** | 83–251 / **1** (sala = 450 px) |

- `corredor = true` é o defeito (`scripts/nivel_com_chefe.gd:43`); só `Corredor_das_Execucoes` (N8), `A_Cela_Zero` (N10) e `O_Trono_de_Zeriko` (N30) o desligam; N100 não tem jornada só por ser o último (`nivel_com_chefe.gd:90`) — e fica com **850 px e 1 plataforma**.
- O comprimento **não é decidido por nível**: `_comprimento()` = `2600 + 1250·idx` (N1–N30) e `14000 → 40000` linear (N31–N100) (`gerador_corredor.gd:980–986`). Medido: N1 5 840 px, N10… N29 38 220 px; N31 cai para 14 770 px e volta a subir 377 px por nível até 40 393 px no N99. É uma rampa, não um desenho.
- A sala à mão da Região III (a região com contrato LOCKED e 7 pranchas) mede **650 px = a arena do chefe**. O N12 "reconstruído" (retomar_aqui, 25 set) foi implementado como **fila de câmaras forçadas dentro da jornada** (`_n12_fila`, `gerador_corredor.gd:1008–1010, 1301–1303`): as pranchas pedem salas ligadas (layout A/B/C/D em `docs/art_direction/regions/region_03/layout_usage.png`), o pipeline só sabe emitir câmaras de 4–7 plataformas numa fila horizontal.
- Perfis runtime: `img/a3/perfil_runtime_N01-N10.png`, `perfil_runtime_N11-N20.png`, `perfil_runtime_amostra_N31-N99.png` — cinza (jornada) domina; laranja (desenhado) é uma mancha no fim a partir do N11.

**Porque é a causa-raiz e não um defeito de tuning.** O gerador foi escrito para ser *anti-softlock por construção* (cabeçalho `gerador_corredor.gd:3–16`): espinha sempre contínua, "nada BLOQUEIA", tudo à direita, líquido mortal por baixo. Isso proíbe estruturalmente o que as pranchas aprovadas pedem (salas, elemento-chave que abre progressão, backtracking curto, verticalidade real, segredos com leitura). Cada tentativa de cumprir uma prancha vira uma exceção `if _idx == 11` e partilha o `_rng` de 100 níveis (o plano da R3 §12.3 teve de blindar a geometria dos outros 95 níveis) — o pipeline resiste ativamente a design por nível.

**Benchmark gap.** Celeste: cada ecrã é uma sala autoral de 5–20 s com uma ideia. Lost Crown: salas autorais ligadas, traversal com ferramentas, retorno. Koliani: uma fita de 15–40 mil px com ideias pontuais.

**ACTION: REBUILD (pipeline), P0.** Inverter a relação: o nível passa a ser uma **sequência autoral de salas curtas** (cena por sala ou módulos desenhados à mão com parâmetros), e o gerador desce a *ferramenta de preenchimento/variação dentro de uma sala*, nunca o esqueleto. Primeiro passo barato: `corredor = false` por omissão + as regiões com pranchas (I–IV) montadas a partir de salas; comprimento-alvo por nível numa tabela (não `idx·1250`).

### CR2 — P0 · Escala de nível errada para um platformer mobile por níveis (ritmo e duração)

- O contrato da R3 fixa a decisão "níveis de **1–3 minutos**" (`REGION03_VISUAL_GAMEPLAY_CONTRACT.md:357–362`); o plano da R3 já avisava que as jornadas têm 16–20 mil px (§12.7).
- Velocidade de corrida 240 px/s (`scripts/movimento.gd:20`); o bot em troços fluidos anda a 165–212 px/s (R1, perfis normal/experiente). **Só a correr, sem morrer nem combater**: N11 ≈ 75 s, N20 ≈ 130 s, N29 ≈ 185 s, N99 ≈ 200 s. Com o que o bot mediu de facto em troços com perigos (27–60 px/s em R3–R4), o **N11 leva 4,5–9 min só de jornada** (bot com todas as habilidades: 272–373 s até ao fim da jornada; N13: 451–490 s; N14–N15: 475–571 s).
- **Ritmo plano e igual em todos os níveis**: a mesma curva de 3 atos (`intens` 0.35→1.28→0.5, `gerador_corredor.gd:1182–1189`) em todos os 97 níveis; câmaras a cada ~1 700–2 000 px (medido: N11 2 246, N15 1 732, N20 2 030, N81 1 528 px/câmara); entre câmaras, 3–7 degraus genéricos de 100–160 px (`:1197–1202`).
- **36,3 % de todas as câmaras são `descanso`** (plataforma lisa de 330 px + checkpoint + 2 colunas, `:2255–2266`) — 562 de 1 548; o bigrama `descanso→descanso` aparece em **66 níveis** (medido). O "alívio" deixou de ser respiração e passou a ser metade do conteúdo.
- Checkpoints: espaçamento mediano **2 800–3 700 px em todos os níveis** (regra única `ESPACO_CHECKPOINT = 2600`, `nivel_com_chefe.gd:36`, e `DIST_CHECKPOINT = 3000`, `gerador_corredor.gd:843`). Com líquido mortal por baixo de tudo, cada queda devolve até ~3 000 px / 15–60 s. Celeste: retry de 1–10 s.

**ACTION: MAJOR REWORK, P0** (sai de graça com CR1): tabela de duração-alvo por nível (60–180 s), 4–8 salas por nível, checkpoint à entrada de cada sala de desafio, "descanso" só onde o ritmo o pede.

### CR3 — P0 · "Uma mecânica nova por nível" substituiu Teach→Test→Combine→Challenge→Boss

- `MECANICA_DO_NIVEL` dá **89 estreias diferentes em 96 níveis com jornada** (medido); só `trampolim, elevador, engrenagens, espectral, mare, grav_baixa` repetem. É a regra de `docs/mecanicas_por_nivel.md:24–30` ("cada nível ESTREIA uma mecânica").
- A estreia ocupa **14,5 % das câmaras** (medido): aparece 1–4 vezes por nível (`grau`), a primeira vez entre 4 % e 51 % do percurso, e no nível seguinte já é outra. O resto das câmaras vem de sorteio ponderado (`_pool_permitida`, foco, "nova", assinatura de região, sala especial; `:1244–1297`). Nada no gerador sabe a *função* do nível na região (TEACH/TEST/COMBINE/CHALLENGE/BOSS): a dificuldade é `_dif = idx/29` linear (`:972–978`), não um arco por região.
- **Região I medida** (runtime): N1 estreia `saltos`, N2 `gruta`, N3 `trampolim`, N4 `espinhos`, N5 `ritmo` (×3) — **cinco mecânicas diferentes, nenhuma testada nem combinada**; a mecânica canónica da região (raízes que irrompem) vive como "toque" de assinatura só no N1 (`ASSIN_NIVEL[0]`, `:642–650`) e nas salas à mão. Os guardiões obrigatórios N1–N4 continuam presentes em runtime (Ghorak, Morvanna, Rainha Aracnídea, Entrevane como `Guardiao` que sela a porta) — **contra a decisão do GM de 25 set** (`docs/auditoria_reestrutura_niveis_1_20.md`, decisão 2).
- **Região II**: estreias `alavanca`, `fogo`, (N8 planar à mão), `arena`, (N10 à mão) — alavanca/fogo são legado da Prisão, não o vento da prancha.
- **Região IV**: estreias `elevador`, `quebra`, `velas`, `pedras`, `poço` — Catacumbas legadas, zero Fornalha.
- Consequência de leitura: o jogador nunca domina nada; Celeste apresenta ~1 mecânica por capítulo (≈ 5 níveis aqui) e explora-a em 20–40 salas com variações e combinações.

**ACTION: REBUILD da tabela de progressão, P0.** Uma mecânica **por região** (2 no máximo), com os 5 níveis a desempenhar papéis explícitos: N1 ensina em segurança, N2 testa com consequência, N3 combina com a mecânica da região anterior, N4 desafia (sequências longas), N5 exame + boss. É exatamente o que as pranchas LOCKED da R2–R4 já descrevem.

### CR4 — P1 · Repetição sistémica: o "enchimento" é o mesmo em todas as regiões

- Nos 96 níveis com jornada, **~81 % dos atores da jornada** (excluindo plataformas/checkpoints/líquido) são sempre os mesmos 6 tipos: `DemonioBase`, `Serra`, `PenduloLamina`, `Fogo`, `Espinhos`, `PlataformaFlutuante` (medido: N11–N100 82 %). `Serra` está em 87 níveis (1 471 instâncias), `PenduloLamina` em 90 (1 437), `Fogo` em 85 (1 343).
- Causa exata: `_perigo_no_vao()` sorteia **pêndulo/serra/fogo** em todas as regiões (`gerador_corredor.gd:1503–1545`; a única exceção é `if _regiao == 2 and _idx == 11`). Também `_f_forquilha`, `_f_torre`, `_f_poco`, `_f_pilares`, `_f_saltos` chamam `_perigo_no_vao` — os mesmos três perigos entram por dentro das câmaras "de identidade".
- Semelhança medida: Jaccard médio dos **conjuntos de atores** da jornada entre quaisquer dois níveis N11–N100 = **0,46** (quase metade do vocabulário partilhado entre, p.ex., o Deserto e o Inferno). As câmaras em si variam mais (Jaccard de conjuntos de câmaras entre níveis consecutivos 0,23), mas as mais presentes são estruturais e sem tema: `descanso` 91 níveis, `forquilha` 33, `pilares` 30, `poco` 28, `torre` 28, `cripta` 28, `arena` 26, `segredo` 25.
- Visível: `img/a3/n01_01.png`, `n11_03.png`, `n045_01.png`, `n090_02.png` — a mesma fila de plataformas flutuantes equidistantes sobre um chão mortal, com pêndulo/serra no vão, na Floresta, na Torre, no Gelo e no Vazio. Na Torre dos Ecos (interior de um campanário) há um lago mortal por baixo de tudo (`n11_zona_morte_01.png`).

**ACTION: PARTIAL REWORK, P1.** Vocabulário de perigos **por região** (tabela, não sorteio global); `_perigo_no_vao` deixa de existir como fallback universal; se o gerador sobreviver como ferramenta de variação, cada região declara o seu kit de peças e só esse.

### CR5 — P1 · Exigência mal colocada: precisão máxima sobre morte instantânea logo no início, e "ritmo" sem ritmo

- **Envelope de salto**: o gerador desenha degraus até `SUBIDA_MAX = 104 px` a partir do N6 (salto+duplo, `:909–925`). Medido: das subidas entre plataformas vizinhas, **37 % (N6–N20) e 40 % (N21–N100) estão ≥ 96 px**, i.e. a ≤ 8 px do limite físico. Na R1 o contrato de salto simples funciona (60 px, `:914`): medido, o caminho crítico N1–N5 não tem nenhum degrau > 88 px fora de câmaras com trampolim (os que aparecem são o "2.º piso" opcional, `:1210–1212`). **Isto está bem feito e deve ser preservado.**
- **Níveis "a subir" (`v:+1`, toda a R3) começam a 90 px do líquido** (`:1159–1160`) e sobem logo em degraus de 104 px. Bot com todas as habilidades: as mortes da R3 concentram-se nos primeiros 300–1 500 px do nível — N11 x≈−14 500 (78–85 mortes), N13 x≈−17 000 (99), N14 x≈−18 500 (99), N15 x≈−19 000 (99–100). *Candidato a "muro de entrada"* (o bot é fraco em subidas máximas; confirmar com humano), mas o padrão é de design: pico de exigência no segundo 5 do nível, sobre morte instantânea, com respawn no início.
- **N5 (exame da R1) = 3 câmaras `ritmo`** (`MECANICA_DO_NIVEL[4]` grau 1). `_f_ritmo` dá a cada plataforma um **período aleatório** 2,0–2,8 s com fase 0,28·i (`:2427–2431`) — o padrão deriva e nunca se repete; não há ritmo a aprender. Bot (sem habilidades): 85–101 mortes em todas as runs, todas por queda no líquido nas câmaras de ritmo (x≈−6 000/−4 000). Celeste: blocos temporizados partilham um relógio global — é isso que os torna legíveis.
- **N4 `espinhos`**: a calha baixa (a que se vê primeiro, à altura da entrada+66 px) é um tapete de espinhos de largura 6 sobre cada plataforma (`:2092–2098`); a rota justa é a de cima, sem sinalização. Bot: 15–20 mortes em cada run ali (x≈−2 000). Não é softlock (a rota alta é alcançável com salto simples, medido: subidas 40–60 px), é uma armadilha de leitura.
- **N3 `trampolim`**: câmara obrigatória, trampolim lança na vertical e a aterragem está 150–180 px à direita e 150–210 px acima (`:2439–2455`). O bot fica aí 100 % das vezes (54–61 mortes). Provavelmente limitação do bot; **não confirmado em humano**.

**ACTION: TUNE, P1** (regras no pipeline, não 40 níveis): primeiro degrau de cada nível/sala ≤ 70 % do envelope; nunca envelope máximo sobre morte instantânea sem checkpoint a < 10 s; relógio partilhado para todas as plataformas temporizadas de uma sala; rota "armadilha" sempre telegrafada.

### CR6 — P2 · Exploração, segredos e backtracking não existem como sistema

- A jornada é estritamente esquerda→direita; a única ramificação é a `forquilha` (33 níveis), que volta a juntar-se após 3 plataformas (`:2269–2291`). Não há becos, chaves, portas de habilidade ou regresso.
- Segredos: câmara `segredo` (25 níveis) — sempre o mesmo gabarito (plataforma de 400 px + alcova atrás de `ParedeFragil` + Essência, `:2948–2973`); nas salas à mão, 1 `Coletavel` por nível (N5–N20) e a `ParedeFragil` só no N17. As pranchas da R3 pedem 2/3/3/3/4 segredos por nível com exploração 70 %→40 %.
- Habilidades (duplo salto, planar, escalar, partir paredes) não abrem caminhos antigos — Lost Crown vive disso.

**ACTION: PARTIAL REWORK, P2** (depende de CR1): cada sala desenhada com 1 rota crítica + 1 rota opcional; segredos por leitura do cenário; portas de habilidade leves por região.

---

## 3. Nível a nível — N1–N20 (RUNTIME)

Legenda veredicto: **A** = construído intencionalmente · **H** = híbrido (jornada gerada + sala desenhada) · **G** = montado pelo gerador (a sala à mão é só a arena).
"Bot" = resultado da bateria válida (N1–N5 sem habilidades; N6–N20 com todas as habilidades), 600 s de jogo.

| N | comp. (px) | % jornada | câmaras (runtime) | CPs | Bot | Veredicto / nota |
|---|---:|---:|---|---:|---|---|
| 1 | 5 840 | 46 | saltos | 3 | normal **103 s**, experiente 199 s concluem; casual 600 s (37 mortes no guardião) | **H**. Jornada 11–14 s (bot), sala golden set. Melhor nível do jogo; ainda assim um guardião obrigatório contra a decisão do GM. |
| 2 | 7 100 | 55 | gruta | 3 | jornada 22 s; normal/exp. presos 310 s no guardião Morvanna (8–10 mortes); casual conclui 141 s | **H**. Travessia boa; o nível é decidido pelo guardião. |
| 3 | 8 510 | 61 | trampolim, descanso | 4 | 3/3 perfis param na câmara de trampolim (54–61 mortes) | **H**. Ver CR5 — candidato, não confirmado. |
| 4 | 9 760 | 66 | gruta, espinhos | 4 | 3/3 perfis presos em `espinhos` (x≈−2 000), 32–42 mortes | **H**. Armadilha de leitura (calha baixa). |
| 5 | 10 650 | 72 | ritmo ×3 | 5 | 3/3 perfis presos no `ritmo`, 85–101 mortes | **H**. Exame da região = mecânica nova, sem ritmo real. |
| 6 | 11 880 | 75 | espinhos, alavanca, descanso, arena | 5 | normal chega ao chefe aos 95 s (13 mortes no chefe); experiente 523 s | **G/H**. Legado Prisão (alavanca, fogo). |
| 7 | 13 050 | 78 | espinhos, descanso, arena, fogo, alavanca | 5 | não conclui; 76–77 % | **G/H**. |
| 8 | 5 380 | 0 | — (sala à mão, GAMEPLAY LOCKED) | 3 | com habilidades: 44 %, 55 mortes em x≈2 000 (vão do planar); sem habilidades chega ao chefe (Dama, 490 s sem vencer) | **A**. O único nível da R2 desenhado de raiz; o vão do planar é a zona de morte do bot. |
| 9 | 15 530 | 81 | alavanca, pilares, descanso, arena, descanso, espinhos | 6 | jornada 210–229 s; chefe 334–343 s sem vencer | **G**. |
| 10 | 706 | 0 | — (poço vertical à mão) | 2 | chega ao topo em segundos | **A** (arena de boss). |
| 11 | 15 720 | 96 | cripta, poço, sinos, descanso, elevador, poço, descanso | 6 | 78–85 mortes na subida inicial; jornada 272–373 s | **G**. TEACH de sinos = 1 câmara de sinos. |
| 12 | 16 970 | 96 | alavanca, elevador, escadas, sinos_sync, vitral, quebra, vento_queda, sinos | 6 | não passa de 95–96 % em 600 s | **G** com fila forçada do contrato — a prancha é cumprida *em lista*, não em layout. |
| 13 | 18 220 | 96 | sinos, engrenagens, descanso, espectral, torre, descanso, elevador, torre, descanso | 6 | 99 mortes na subida inicial | **G**. |
| 14 | 19 470 | 97 | engrenagens, vento, descanso, elevador, poço, descanso, corredor, descanso, saltos, descanso | 6 | experiente: 99 mortes no início, jornada 487 s | **G**. 4 de 10 câmaras são descanso. |
| 15 | 20 780 | 96 | espectral ×4, pilares ×2, descanso ×3, forquilha, sinos, corredor | 6 | 99–100 mortes no início; jornada 475–571 s | **G**. Nível de boss com ~20 000 px de fila antes do Vyrak. |
| 16 | 23 940 | 89 | 14 câmaras (6 descanso) | 9 | preso em x≈−14 500 (35–39 mortes) | **G**. Catacumbas (tema legado). |
| 17 | 25 190 | 90 | 14 câmaras (7 descanso, `descanso→descanso→descanso` no fim) | 8 | jornada 163–248 s | **G**. |
| 18 | 26 440 | 90 | 13 câmaras (4 descanso) | 9 | preso em x≈−21 000 (46–51 mortes) | **G**. |
| 19 | 27 690 | 91 | 16 câmaras (6 descanso) | 10 | jornada 139–198 s | **G**. |
| 20 | 28 420 | 93 | 14 câmaras (4 descanso) | 9 | não conclui | **G**. Boss da R4 sem Guardião da Fornalha. |

Nenhum bot concluiu N3–N20 em 600 s de jogo (N6–N20 mesmo com todas as habilidades). Isto **não prova** que sejam impossíveis para um humano; prova que a exigência acumulada por nível (comprimento × densidade × morte instantânea × checkpoints espaçados) é muito superior à de N1–N2, onde o bot conclui em 1,5–3 min.

## 4. Por região — Teach → Test → Combine → Challenge → Boss

| Região | Estrutura prevista (pranchas/decisões) | Estrutura real (runtime) | Veredicto |
|---|---|---|---|
| I Floresta | N1 intro · N2 test · N3 combine · N4 challenge · N5 exame+boss (decisão GM) | 5 mecânicas diferentes (saltos/gruta/trampolim/espinhos/ritmo), guardião obrigatório em N1–N4, boss N5 correto | Função pedagógica **ausente**; salas golden set são o que há de mais autoral |
| II Desfiladeiro | vento → correntes → ilhas/planar → vento variável → torre | alavanca/fogo/(planar à mão)/arena/(poço à mão); jornadas com fogo, serra, guilhotinas | Só N8 e N10 seguem a prancha (ambos sem jornada) |
| III Torre dos Ecos | contrato LOCKED por sala (A/B/C/D) | jornadas de 15–20 k px com 1–4 câmaras temáticas; sala à mão = arena | Mecânicas nomeadas, estrutura não |
| IV Fornalha | calor/lava/pressão | Catacumbas legadas | CONTRADICTS (já conhecido) |
| VII–XX | 5 níveis por região com boss no 5.º | 97–99 % jornada, 1 plataforma à mão, `ChefeGenerico` | Placeholder procedural |

## 5. O que funciona (preservar)

1. **Contrato de mobilidade da R1** (`SUBIDA_SIMPLES = 60`, `NIVEL_SALTO_DUPLO = 5`, `gerador_corredor.gd:909–925`): medido, o caminho crítico N1–N5 respeita o salto simples. É o tipo de regra física que o novo pipeline deve herdar.
2. **N1 e N2 como experiência**: travessia de 11–22 s, sala golden set legível, bot normal conclui N1 em 103 s — é a escala certa (1–3 min).
3. **N8 (Ilhas Suspensas)**: prova que uma sala à mão com uma mecânica (planar) dá identidade real; é o modelo para as outras.
4. **Infraestrutura de medição**: `camaras_do_nivel.gd`, `verifica_alcance.gd`, `baseline_geometria.gd`, o bot, e a determinação por semente — permitem validar qualquer rebuild.
5. **Biblioteca de ~90 câmaras/mecânicas** já implementadas (`CAMARAS_FLAVOUR`): é um catálogo de peças reutilizável como *conteúdo de salas*, não como sorteio.

## 6. Oportunidade própria do KOLIANI

- **Ecos como estrutura de nível** (R3 já canónica: "cada nível é um eco do passado"): salas que se repetem com uma variação — o mesmo espaço visitado duas vezes (antes/depois do sino) é Teach→Test dentro de um nível e barato de produzir.
- **Líquido mortal por região como relógio** (maré/lava que sobe) em vez de chão mortal estático em todos os níveis: dá à Fornalha e ao Mar identidade de ritmo.
- **Mãe/Aurora como fio de exploração**: fragmentos de memória nos segredos, em vez de Essência genérica.

## 7. Ações por prioridade

| P | Ação | Tipo |
|---|---|---|
| P0 | Nível = sequência autoral de salas curtas; `corredor=false` por omissão; gerador passa a ferramenta de variação dentro de sala | REBUILD (pipeline) |
| P0 | Tabela de duração-alvo por nível (60–180 s) em vez de `2600+1250·idx`; checkpoint à entrada de cada sala de desafio | MAJOR REWORK |
| P0 | Uma mecânica por região com papéis Teach/Test/Combine/Challenge/Boss; retirar guardiões obrigatórios de N1–N4 | REBUILD (tabela de progressão) |
| P1 | Kit de perigos por região; eliminar `_perigo_no_vao` universal | PARTIAL REWORK |
| P1 | Regras de exigência: primeiro salto ≤ 70 % do envelope, relógio partilhado nas temporizadas, rota-armadilha telegrafada | TUNE |
| P1 | Playtest humano dos 4 candidatos: N3 trampolim, N4 espinhos, N5 ritmo, subida inicial da R3 | verificação |
| P2 | Rotas opcionais, segredos por leitura, portas de habilidade | PARTIAL REWORK |
| P3 | N100 (850 px, 1 plataforma) — definir como sala final real | — |

## 8. Capturas e dados

- Perfis runtime: `docs/qa/global_audit/img/a3/perfil_runtime_N01-N10.png`, `perfil_runtime_N11-N20.png`, `perfil_runtime_amostra_N31-N99.png`.
- 8 capturas por nível, do spawn à porta: `img/a3/nNN_00.png … nNN_07.png` (N01–N20); amostras `n045_*.png`, `n090_*.png`.
- Zonas de morte: `img/a3/n03_trampolim_00/01.png`, `img/a3/n11_zona_morte_00/01.png`.
- Dados brutos (scratchpad, não no repo): `a3/medir_a.jsonl`, `medir_b.jsonl`, `rows.json`, `bots2/`, `bots3/`, scripts `a3_*.gd|py`.

## 9. RUNTIME VERIFIED vs STATIC ONLY

**RUNTIME VERIFIED**
- Geometria construída, % jornada, comprimentos, câmaras, atores, checkpoints de **N1–N100** (headless, contagem real após o `_construir`).
- Capturas em janela real N1–N20, N45, N90.
- Bot em N1–N20 (90 runs): tempos de travessia, zonas de morte, conclusões N1/N2.
- Envelope de subidas (medido sobre a geometria construída).
- Presença de guardiões obrigatórios em N1–N4.

**STATIC ONLY — NOT RUNTIME VERIFIED**
- Que N3/N4/N5/R3-início sejam intransponíveis ou injustos para um **humano** (o bot tem limitações conhecidas).
- Causa exata de o bot não concluir N6–N20 (atribuição por zona, não por frame).
- Leitura/causa no código (linhas citadas de `gerador_corredor.gd`, `nivel_com_chefe.gd`).
- N21–N100 como experiência de jogo (só estrutura medida).
- Comparação com Celeste/Lost Crown (juízo de design).

SHA256 do save real no fim: `9DC2E4A161C38D16CBA5F29A42F2771CF9ED8F00FB2C63FF31DA48397A764238` — **inalterado**.
