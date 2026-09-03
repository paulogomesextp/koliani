# Retomar aqui — 3 de setembro de 2026

Ponto de situação no fim da sessão de arte. Tudo o que está descrito como
FEITO está commitado e no `origin/master` (até `15061cb`).

## FEITO nesta sessão

### 1. Arte dos mapas ("parece tudo muito igual")
O diagnóstico e as quatro ferramentas novas estão em
[`../CLAUDE.md`](../CLAUDE.md) e no cabeçalho de cada tool:

| Ferramenta | O que faz |
| --- | --- |
| `tools/gerar_terreno.py` | capa/corpo/franja/lado por região — **um pack CC0 diferente por região** |
| `tools/gerar_deco.py` | 65 props por região (chão + parede) |
| `tools/gerar_fundos.py` | prepara os 4 fundos parallax novos |
| `tools/afinar_atmosfera.py` | **uma linha por nível**: céu, luz-chave, neblina, pó |

- `plataforma.gd` monta o terreno em camadas e põe os props de chão.
- `atmosfera.gd` põe os props de parede em **camada de parallax própria**
  (na "Perto" herdavam o `motion_mirroring` e repetiam numa grelha) e as
  camadas de fundo deixaram de repetir na vertical.
- `agua_venenosa.gd`: linha de água ondulada com espuma; o halo por baixo
  encolheu de 300 px/alfa 0.85 para ~80 px/alfa 0.22 (era a "barra chapada"
  que tomava um terço do ecrã em todos os níveis). A lava também.

**Para ver se um passe melhorou:** `tools/folha_de_contacto.gd` dá os 30
níveis numa grelha. Precisa de janela — `--screen 1`, não corre em
`--headless`.

### 2. Koliani nova
- Arte original do Paulo em `C:/Users/paulo/Desktop/newkoliani/`
  (`idle` 10 frames, `walk` 24). `tools/importar_rig_koliani_nova.py`
  monta os 18 estados; `koliani.gd` tem `RIG = "nova"`.
- **Só o `idle` e o `run` são frames desenhados.** Os outros 16 são
  derivados por transformação (inclinar/achatar/rodar/rasto) mais um arco
  de espada azul desenhado por código nos 4 golpes do combo. Assim que
  houver `attack`/`jump`/`roll` do mesmo artista, é largar na pasta de
  origem e ligar no tool.
- Projécteis passaram de roxo a **azul** (`fx/bala_azul.png`,
  `fx/impacto_azul.png`, folha "Water" do bdragon1727), para casarem com o
  manto. O roxo ficou para o Zeriko.

### 3. Plano dos níveis 31–100
[`plano_niveis_31_100.md`](plano_niveis_31_100.md) — guia do Paulo, 14
regiões novas. É a fonte de verdade acima do nível 30.

## A FAZER — por onde continuar

### A. Níveis 31–100 (a seguir)
Ordem proposta, cada passo é commitável por si:

1. **Arte das 14 regiões novas.** Já há packs para regrar: o sistema de
   graduação (`tinta`/`dessat`/`escuro`/`rim` em `gerar_terreno.py` e
   `gerar_deco.py`) foi feito precisamente para o mesmo material ler
   diferente. Falta escolher células/paletas por região. Packs novos já
   descarregados em `assets/sprites/incoming/_dl/` (todos CC0, licenças em
   `incoming/LICENSES.md`): cemetery, patreon collection (old dark castle,
   gothic horror, night town), opp3 cave, bridge expansion, glax.
   Em falta mesmo: gelo, deserto, steampunk, submarino.
2. **Camada de dados**: `EstadoJogo.NIVEIS` 30 → 100, `EstadoJogo.REGIOES`
   6 → 20, `CatalogoCampanha.CHEFE_KEY` → 100.
3. **Chefe genérico**: hoje cada chefe tem script próprio (29 deles).
   Para 70 é preciso um `chefe_generico.gd` com arquétipos (investida /
   atirador / saltador / invocador / feixe) + fases, configurado por cena.
4. **Gerador de níveis**: as cenas 31-100 podem sair de uma tabela — com
   `corredor = true` o `gerador_corredor.gd` constrói a jornada toda e a
   cena só precisa da arena do chefe, porta, spawn e atmosfera.
5. **i18n**: `level.n30`..`level.n99` + 70 chaves `boss.*` nos **seis**
   `assets/i18n/*.json` (o `en.json` é a fonte de verdade e os testes
   exigem as mesmas chaves em todos).

> Aviso honesto para dar ao Paulo: 70 níveis por esta via ficam **jornadas
> procedurais temáticas com chefe**, não 70 salas desenhadas à mão como as
> 29 actuais. Desenhar à mão é trabalho de várias sessões por região.

### B. Arte — FEITA a 3 set (v0.9.44)
Os três pontos que estavam aqui ficaram fechados:

- **Props pendurados** — `gerar_deco.py` ganhou a categoria `pendurado`,
  fontes empilháveis (`("^", fonte, n)`: o elo de corrente 8×8 do Pixel
  Adventure dá correntes de qualquer comprimento) e a bandeira `vflip`
  (cristal do chão virado = estalactite; árvore morta virada = raiz).
  29 props, 4 a 8 por região. O `plataforma.gd` monta-os com
  `z_index = -2` para o ponto de agarre ficar escondido atrás da franja.
  A espinha da jornada é toda de degraus de 18 px — e é de lá que se vê o
  fundo — por isso os degraus finos levam **um só** prop, curto (≤120 px)
  e estreito (≤45% do degrau).
- **`PASSO_DECO`** de 270/5 para 190/9.
- **Parede de "fim do mundo"** — quatro lascas escalonadas em ALTURA e não
  só em profundidade (uma lasca atrás de outra mais alta não se vê de
  todo). O "pé" mantém a pegada da antiga, portanto continua a barrar a
  saída pela esquerda; `verifica_jornada` passa nos 30 níveis.

Pelo caminho: o `shot_plataforma.gd` aceitava só X ≥ 0 e descartava em
silêncio qualquer pedido para ir à jornada, que vive toda em X negativo.

**Nada disto foi jogado** — foi verificado por screenshot (`--window
--screen 1`, os `--headless` não gravam nesta máquina) e pelos
verificadores. Falta o teu olho: em particular se a densidade de props
não ficou uma montra, e se as estalactites das catacumbas não lêem como
pano pendurado.

### B2. Arte — o que continua por fazer
- Ruído conhecido, **anterior a esta sessão**: cada nível carregado cospe
  `There is no animation with name 'idle'`. É a cena da Koliani a pôr
  `animation = "idle"` antes de o `_montar_frames` atribuir os
  `sprite_frames` — inofensivo, mas suja o output dos tools.
- Faltam ainda os 16 estados derivados da Koliani nova (só `idle` e `run`
  são frames desenhados) — ver secção 2 acima.
