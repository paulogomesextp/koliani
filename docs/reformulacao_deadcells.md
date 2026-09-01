# Reformulação "pegada Dead Cells" — plano faseado

> Decisão do Paulo (1 set 2026): **passe de feel + arte** — mantém-se a
> campanha de 30 níveis, história, 30 chefes e os saves. Não é pivot
> roguevania. Base de arte: eu escolho por região o que casar melhor com
> `assets/branding/key_art.png` e mostro screenshots antes de fixar.
> Sprite da Koliani: adotar um rig pronto (Magic Cliffs / Gothicvania) e
> recolorir (roxo/luar).
>
> Referência: speedrun WR de Dead Cells (fresh file 8:15). O que se tira:
> momentum sem paragens, roll-cancel, biomas altos e ramificados, salas
> montadas de "chunks" feitos à mão, sem dano de queda, agarrar borda,
> agressão = ritmo.

## Fase 1 — Feel do movimento (código, sem assets)

- [x] **Agarrar a borda / mantle** (`koliani.gd` `_detetar_borda` +
  `_borda*`): a cair rente a um rebordo, agarra-se; saltar/↑ sobe, ↓ larga.
  Perdoa saltos por um triz nas torres da jornada. **Falta playtest** dos
  números (`BORDA_*`, `BORDA_MANTLE`).
- [x] **Roll-cancel**: iniciar rolamento corta o recovery do ataque
  (`koliani.gd`, ramo do `rolar`). Encadeia ataque→rolar→ataque.
- [x] **Pogo em hazards**: a cair em cima de uma `Serra`/`Espinhos` (grupo
  `"pogavel"` + layer 6), a Koliani ressalta em vez de levar o golpe
  (raycast para baixo dos pés; i-frames apanham o toque). **Falta**
  estender a `Guilhotina`/`PenduloLamina` (geometria da lâmina fora do
  root — precisa detetar pela Area2D da lâmina). Líquido mortal nunca é
  `"pogavel"`.
- [x] **Wall-jump básico** (`koliani.gd`): no ar, encostada a uma parede e
  a segurar contra ela, `saltar` chuta para fora (`WALLJUMP`), sem gastar
  o salto do ar. Não precisa de `escalar_paredes`.
- [ ] Afinar aceleração/atrito para o "nunca pára" (rever `movimento.gd`
  `ACEL_AR`/`ACEL_CHAO`, corte de salto). **Falta playtest** dos números
  do agarrar-borda / wall-jump / pogo.

## Fase 2 — Jornada montada de peças (ritmo + ramificação)

Em vez de reescrever tudo para `.tscn` à mão, o `gerador_corredor.gd`
evoluiu para **encadear "câmaras" tipo peça** (funções `_f_*` com
entrada/saída declaradas em altura, regra de ouro `SUBIDA_MAX`).

- [x] **Ritmo tensão/alívio** (`_camaras`, `_pos_intenso`): a seguir a uma
  câmara puxada (vertical, guilhotinas, serras, fogo, quebra) entra sempre
  um `_f_descanso` — plataforma larga e LIMPA + checkpoint + vista. Também
  força descanso a cada 4.ª câmara.
- [x] **`_f_forquilha`**: o caminho abre em dois — rota ALTA curta com
  perigos, rota BAIXA longa e segura — e volta a juntar-se. Ambas as
  pontas alcançam o reencontro (de cima desce-se, de baixo ≤ 1 salto).
- [x] **Estrutura em 3 actos** (arco de bioma tipo Dead Cells): `prog`
  (0→1 pela jornada) + `intens` — intro suave (`prog<0.28`, ×0.35→1) →
  meio a apertar (`0.28–0.82`, ×1→1.28) → alívio antes da rampa do chefe
  (`prog>0.82`, ×0.5, quase só `descanso`). `intens` escala perigos,
  inimigos e plataformas móveis.
- [x] **Assinatura de região** (`ASSINATURA`): no acto do meio, ~30% de a
  câmara ser a "cara" do bioma (Floresta=trampolim, Prisão=guilhotinas,
  Torres=vento, Catacumbas=gruta, Cidade=impulso, Castelo=fogo), se a
  dificuldade já a libertou.
- [x] **`_f_arena`** — chão largo sobre o líquido + 3-6 inimigos de
  comportamentos variados + checkpoint. "Limpa a sala." (~13%, actos 1-2)
- [x] **`_f_corredor`** — tecto baixo + serras em calha no ritmo; passa-se
  a correr/rolar, não a saltar. (~12%, acto 2, dif > 0.28)
- [x] **`_f_cripta`** — sala com parede interior baixa (saltar por cima ou
  rota alta) + pedras que caem + checkpoint. (~8%, 16% na região Catacumbas)
- [x] **`_f_crossfire`** — lanço recto com torretas montadas nos dois lados
  a cuspir fogo horizontal a alturas alternadas; leitura de padrão, não
  salto difícil. Pool das regiões Prisão/Cidade/Castelo, `TIER` 0.4.
- [x] **`_f_ferry`** — fosso largo (620-880 px) sobre o líquido atravessado
  por uma plataforma-balsa (`TumuloElevador` horizontal, `auto`); passa-se
  em pé a desviar de 2 lâminas penduladas. Pool das regiões Torres/
  Catacumbas/Castelo, `TIER` 0.3. O beat "a viagem".
- [x] **`_f_pedras`** — beiral sem tecto sob uma saraivada de `PedraQueda`
  (1/3 em ciclo, resto por proximidade). Estava listada na pool das
  Catacumbas mas sem handler → gerava um vão morto; agora é câmara a
  sério. `TIER` 0.0 (só região 3).
- [x] **`_f_espinhos`** — forquilha: calha baixa = tapete de `Espinhos`
  ("pogavel", atravessa-se aos ressaltos com o pogo da Fase 1); calha alta
  = plataformas limpas (caminho justo). Pool Prisão/Catacumbas, `TIER`
  0.36. Mostra a mecânica de pogo.
- [x] guard em `_flavour()`: tipo sem `_f_` → `push_warning` + `_f_descanso`
  (era um `Vector2(x+180,y)` silencioso).
- [ ] mais "tons" de peça: alcove-segredo / atalho (precisa do sistema de
  recompensa — ver Fase 5; deixado para o Paulo decidir o "sink")
- [ ] atalhos: 1-2 `Portal` "de retorno" por jornada (teletransporte)
- [ ] (talvez) mover as peças mais estáveis para `scenes/rooms/*.tscn`

## Fase 2b — Inimigos com ameaça própria (combate Dead Cells)

- [x] `DemonioBase.comportamento` (`@export_enum`): **saltador** (salta em
  arco na direção da Koliani quando perto) e **carga** (telegrafa — pára e
  estremece — e arranca a 3.4× a velocidade, sem virar; recupera na
  parede). O gerador atribui-os a partir de `_dif > 0.15` (não nos
  voadores). Método `_dir_koliani_perto(alcance)` (o nome `_dir_para_koliani`
  já existe no `ChefeBase`). **Falta playtest** dos números.
- [x] **voador** (aplicado aos "olho" pelo gerador): sem gravidade, paira à
  volta da origem e MERGULHA na Koliani (direção fixada no arranque,
  recupera na parede/chão).
- [x] **escudeiro** (dif > 0.35): golpe de FRENTE bate no escudo (só
  "clinc"); pisão e golpes pelas costas passam. Anda mais devagar.
- [x] **trepador** (dif > 0.3): agarrado ao tecto (sprite invertido);
  solta-se e cai quando a Koliani passa por baixo, depois anda como
  patrulha. O gerador põe-no ~120-170 px acima da plataforma.
- [x] **cuspidor** (dif > 0.22): patrulha e, à distância (≤ 440 px, dy <
  170), planta-se, telegrafa (wind-up 0.5 s) e cospe uma `BolaFogo` na
  direção da Koliani com a mira achatada no y; recarga 1.8-2.8 s.
  Pressão à distância que obriga a fechar distância ou a desviar.
- [x] **telegrafos legíveis** (`_telegrafo`): antes de qualquer investida o
  inimigo pisca forte (branco-quente) + estremece. `carga` já tinha
  wind-up; `saltador` (agacha 0.26 s) e `voador` (trava no ar 0.3 s) ganham
  wind-up + som de aviso. `_saltando`/`_mergulho` protegem o arco/picada
  de a patrulha os pisar.

## Fase 3 — Arte de ambiente por região

Fontes já em `assets/sprites/incoming/` (nada para descarregar):
Ansimuz **Gothicvania** (church/swamp/town) + parallax **Cold Corridors /
Caverns / Rocky Pass / Mountain Dusk**, **Magic Cliffs** gamekit,
**LuizMelo** inimigos. Copiar o usado para `assets/sprites/pixel/` e
creditar em `CREDITS.md`.

- [x] I Floresta → Gothicvania **Swamp** (`pantano`) na Floresta Putrefacta
  e no Ninho (o pôr-do-sol laranja do parallax_forest não lê como floresta
  podre); `floresta` fica na Árvore que Chora e no Coração.
- [x] II Prisão → Cold Corridors (`prisao`) + **church** (`igreja`) na
  Fornalha e na Ala dos Mortos.
- [x] III Torres → Mountain Dusk (`montanhas`) + Rocky Pass (`rochoso`) no
  Pico Esquecido.
- [x] IV Catacumbas → Caverns + **church**: `caverna` ganhou a camada
  `tumulos.png` (túmulo com gárgula + pilar de crânios) em primeiro plano;
  a Cripta das Mil Velas passa a `igreja` inteira.
- [x] V Cidade → **Gothicvania town** (`cidade`: céu de nuvens + silhueta da
  vila com janelas acesas). Era `rochoso` -- serra rochosa numa cidade. A
  Catedral da Corrupção usa `igreja`.
- [x] VI Castelo → `corredores` (Portões, Torre do Coração) + `igreja`
  (Salão dos Espelhos, Banquete, **Trono**) com tinta magenta.
- [x] recolor por bioma: `tinta_fundo` + `neblina_fundo` (profundidade
  atmosférica) + `dessaturar_fundo` em `atmosfera.gd`
  (`assets/shaders/fundo_bioma.gdshader`). Desatura o pack ANTES de o
  pintar -- é o que tira o azul-néon ao Cold Corridors e o vermelho às
  falésias do Mountain Dusk. Passe de paleta (`cor_ambiente`/`cor_fundo`/
  `cor_luz`/`cor_poeira`) nos 30 níveis: luar frio + magenta do key_art, e
  os ambientes que estavam escuros de mais (O Abismo a 0.14) levantados.
- [x] líquido mortal (`agua_venenosa.gd`): superfície escura com a linha de
  água acesa em vez de um bloco chapado de cor -- ocupa um terço do ecrã na
  jornada.
- [ ] **falta playtestar**: as tintas/desaturações são todas "a olho" em
  screenshots headless (`tools/shot_dev_nivel.gd`).

## Fase 4 — Rig da Koliani  ✅ (1 set 2026, v0.9.1)

O Paulo trouxe o pack **"Knight_player 1.4"** (@Jump_Button) — cavaleira de
faixa na testa, armadura, espada e escudo. Ficou esse em vez do Magic
Cliffs. **Licença NÃO é CC0** (ver `CREDITS.md`): crédito obrigatório no uso
comercial e o autor proíbe treino de IA/NFT.

- [x] adotar o sheet (tiras de 100x64, 15 estados)
- [x] recolorir para a Koliani (vermelhos → magenta, metal → violeta frio),
  em `tools/importar_rig_cavaleiro.gd`
- [x] ligar a `koliani.gd` (`RIG = "cavaleiro"`, `_KOLI_ANIMS_CAVALEIRO`) e
  **acrescentar os estados que faltavam**: roll, dash, hurt, defesa, borda,
  aterrar, morte
- [x] afinar pés/escala (0.8 + offset -2 sobre a colisão de 20x44)
- [ ] **falta playtest**: escala, alinhamento nos declives, se a leitura da
  silhueta aguenta a 1.4 de zoom

## Fase 5 — Economia / loadout (leve, não roguelite)

- [ ] as gemas viram "essência" com contador visível
- [ ] 2 slots de skill trocáveis num banco entre níveis (já há
  `EstadoJogo` habilidades) — sem perder o esquema de progressão fixa

---

Progresso detalhado em `docs/progresso_agente.md`.
