# Retomar aqui — 3 de setembro de 2026 (fim da sessão longa)

> **LEIA PRIMEIRO.** O Paulo deu uma lista nova a meio da sessão e ela tem
> prioridade sobre tudo o resto. Está por fazer quase toda.

## ⚠ A LISTA DO PAULO (3 set, prioridade máxima)

Por ordem. Só o ponto 2 está feito.

### 1. Substituir a KOLIANI pelo modelo pixel-art novo — BLOQUEADO
O Paulo anexou no chat uma folha de referência da Koliani nova e pediu:
*"substitua a Koliani por este modelo pixel art que tenho em anexo (procure
assets o mais próximos disto se não conseguir replicar a 100%, e adapte
para ficar o mais parecido possível e com esses movimentos)"*.

**A imagem NÃO ficou em disco** — só existia na conversa, e com o `/clear`
perde-se. **Pedir ao Paulo para a gravar** em
`assets/branding/koliani_ref_nova.png` (ou no Desktop) antes de começar.

O que a folha mostra, para se saber o que procurar:
- **Personagem**: cabelo roxo-escuro em rabo-de-cavalo, cachecol/capa
  vermelho-escuro esvoaçante, roupa preta/cinza-escura com cintos e
  braçadeiras, botas escuras, **espada recta a brilhar magenta**.
- **Paleta** (a folha traz a barra): roxos escuros, vermelhos-tijolo,
  castanhos, cinzas, e dois magentas vivos para o brilho da lâmina.
- **Animações da folha**: `idle` 4 frames · `run` 5 · `jump` 7 ·
  `attack` 5 (com arco magenta e um golpe de estocada com rasto) ·
  `crouch` 3 · `wall slide` 3 · `double jump` 5 (com um rebentamento
  magenta por baixo).

Estado actual: `koliani.gd` tem `RIG = "nova"` (arte do Paulo em
`C:/Users/paulo/Desktop/newkoliani/`, só `idle` 10 e `walk` 24 desenhados;
os outros 16 estados são derivados). O rig novo entra por
`tools/importar_rig_koliani_nova.py`.

### 2. Ressalto do pisão a metade — FEITO
`STOMP_RESSALTO` de 1.4x para 0.7x o salto normal (commit `6abcee0`).

### 3. Sons mais realistas — POR FAZER
*"Mude todos os sons de mobs, animações (saltos, hits espada, tiros,
bosses) para algo mais realista, está tudo muito modo arcade ainda."*
Hoje **todos** os sons são sintetizados por `tools/gerar_audio.py` (sem
dependências, sem licenças) — é por isso que soam a arcade. A resposta é
trocar por samples reais CC0. Ver a nota das fontes mais abaixo.

### 4. 20 músicas de nível, em ciclo — POR FAZER
*"Só existe uma música de fundo nos níveis, coloque 20 músicas épicas de
jogos e vá metendo 1 em cada nível; ao chegar ao nível 21 a lista
reinicia."* Ou seja `faixa = indice_nivel % 20`.

### 5. 20 músicas de chefe, em ciclo — POR FAZER
O mesmo para `Musica.boss()`.

### 6. Só depois disto, voltar aos CHEFES (ver secção mais abaixo).

---

## Notas de investigação já feita (para não se repetir)

**Música e sons — de onde os tirar.** O Paulo autorizou descarregar sem
perguntar de cada vez (só o que é *pago* é que se pergunta).

- **Pixabay está BLOQUEADO ao `curl`** (devolve uma página de desafio de
  5 kB). Foi de lá que vieram as três faixas actuais, mas manualmente.
- **OpenGameArt FUNCIONA** e tem exactamente o que falta. Colheita de
  candidatos (deu 170 na sessão passada):

  ```
  https://opengameart.org/art-search-advanced?keys=<termo>&field_art_type_tid[]=12&sort_by=count&sort_order=DESC
  ```
  e na página do item, `<a href="/content/<slug>">Título</a>`.
  Termos que deram bom resultado: `epic orchestral`, `boss battle`,
  `epic battle`, `dark fantasy`, `orchestral loop`, `cinematic`,
  `dungeon`, `gothic`, `medieval battle`, `adventure theme`.
  Para sons: mesmo sítio com `field_art_type_tid[]=13` (Sound Effects).
- Numa página de item o que interessa sai assim:
  - ficheiros: `https://opengameart.org/sites/default/files/<nome>.(ogg|mp3|wav)`
  - licença: um `<div class='license-name'>CC-BY 3.0</div>`
  - título: o `<title>` da página.
  **Preferir `.ogg` > `.mp3` e fugir do `.wav`** (enormes).

**⚠ Peso no repositório.** `assets/audio` tem 20 MB e o `.git` já vai em
103 MB. Quarenta faixas a ~4 MB seriam +160 MB. **Não há `ffmpeg` nesta
máquina**, portanto não dá para reencodar — a escolha tem de ser por
faixas já pequenas (loops curtos em `.ogg`). Se não der para manter o
total abaixo de ~50 MB, falar com o Paulo antes de commitar.

**Licenças.** OpenGameArt mistura CC0, CC-BY, CC-BY-SA e GPL. Registar
cada uma em `assets/audio/CREDITS.md` — as CC-BY exigem atribuição.

**itch.io dá para automatizar** (foi preciso para os packs de chefe):
```bash
TOK=$(curl -sL -c jar.txt "<url do pack>" | grep -oE 'name="csrf_token" value="[^"]*"' | head -1 | sed 's/.*value="//;s/"//')
curl -s -b jar.txt -X POST "<url do pack>/download_url"   -H "Content-Type: application/json" -H "Referer: <url do pack>"   --data "{\"csrf_token\":\"$TOK\"}"
```
Devolve `{"url": "..."}` com o link directo.

---

## Onde ficaram os CHEFES (retomar aqui depois da lista acima)

Feito e no `master`: os chefes passaram a ANIMAR (`ChefeBase.rig` +
`tools/importar_chefes_animados.py`, 5 rigs de packs gratuitos que já
estavam no repo); 5 chefes de 1-30 já os usam; e entraram os GUARDIÕES
(nem todo o nível tem chefe — um chefe por região, guardião nos outros
quatro).

**Estava a meio de descarregar dois packs de chefe do itch.io** quando a
lista nova chegou — nenhum ficheiro foi escrito, portanto não há lixo:
- [Boss: Undead Executioner](https://darkpixel-kronovi.itch.io/undead-executioner) — 57 kB, 6 animações
- [Boss: Mecha-Stone Golem](https://darkpixel-kronovi.itch.io/mecha-golem-free) — 103 kB, 8 animações

Ambos comerciais OK, sem redistribuir. O comando do `download_url` está
na secção acima. Faltam rigs para os outros 24 chefes de 1-30.

---

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

### A. Níveis 31–100 — ARRANCOU (v0.10.0)

A **Região VII (31–35, Terras Queimadas) está feita e a jogar**, de ponta a
ponta. Foi de propósito uma fatia vertical: uma região inteira a funcionar
prova a tubagem toda, e as 13 restantes são a mesma coisa repetida.

O que ficou construído e serve para as outras 13:

| Peça | O quê |
| --- | --- |
| `scripts/chefe_generico.gd` | uma máquina de estados, 5 arquétipos (INVESTIDA / ATIRADOR / SALTADOR / INVOCADOR / FEIXE). Um chefe novo = uma cena + `@export`s |
| `tools/testar_chefe_generico.gd` | bancada dos arquétipos — como os 70 partilham o script, um arquétipo partido parte-os a todos |
| `tools/gerar_niveis_31_100.py` | as cenas saem de uma tabela: 1 linha por nível |
| `_dificuldade()` / `_comprimento()` | o **2.º acto** — a região nova recomeça mais abaixo e volta a subir (a curva antiga era para 30 níveis e punha o nível 31 no máximo dos dois) |

**Para acrescentar a Região VIII (36–40) — a receita:**

1. `tools/gerar_niveis_31_100.py`: 5 linhas em `NIVEIS` (ficheiro, índice,
   bioma emprestado, arquétipo, vida, cor, sprite de chefe emprestado).
2. `scripts/gerador_corredor.gd`: `LIQUIDO[7]`, `POOL_REGIAO[7]`,
   `ASSINATURA[7]`, `ESP_REGIAO[7]`, +5 em `ESP_ASSINATURA`, +5 em `PERFIL`.
3. `scripts/estado_jogo.gd`: +5 em `NIVEIS`, +1 em `REGIOES`.
4. `scripts/catalogo_campanha.gd`: +5 em `CHEFE_KEY`.
5. `assets/i18n/*.json`: +10 chaves nos **seis** ficheiros.
6. `tools/afinar_atmosfera.py`: +5 linhas, e correr o tool.
7. `godot --headless --import`, a suite, `verifica_jornada`, folha de contacto.

**Estrutura decidida (3 set, a mando do Paulo):** *"não precisa ter um
boss todos os níveis"*. Da Região VII em diante cada região de 5 tem **um
chefe — o último** — e **guardiões** nos outros quatro: um elite que sela a
porta até cair (`nivel_com_chefe.gd` liga-se ao `tree_exited` do nó
`Guardiao`). Dá clímax ao nível sem gastar um chefe, e são 14 chefes novos
em vez de 70 — cada um pode ser trabalhado a sério. Os níveis 1–30 ficam
como estão (têm chefe todos, e estão playtestados). No carrossel, um nível
de guardião diz "Guardião: X" (`sel.guard`) em vez de "Chefe: X"; a chave
i18n é `guard.*` em vez de `boss.*`, e o `CatalogoCampanha.tem_chefe()`
distingue-os.

**Chefes animados (3 set):** até aqui NENHUM chefe animava — a folha do
`extrair_chefes_packs.gd` são quatro POSES. Agora há
`tools/importar_chefes_animados.py` e cinco rigs (idle/walk/attack/hurt/
death) de packs gratuitos que já estavam no repo. Cinco chefes de 1–30 já
os usam. **Faltam rigs para os outros 24** — ver a lista de packs abaixo.

**Decisões que ficam por tomar (precisam do Paulo):**

- **Os dois pontos de partida do 2.º acto** — 0.72 de dificuldade e
  14000 px de jornada para o primeiro nível da região nova. São palpite
  fundamentado (a dureza do nível ~21, o comprimento do ~10). Só a jogar
  se sabe.
- **Arte.** Os 70 chefes usam sprites emprestados dos 29 de 1–30, e os
  fundos são reaproveitados: a regra "um pack nunca em duas regiões" vale
  para as seis primeiras, que consomem os doze packs que existem. Da VII em
  diante a identidade vem toda da tinta. 14 regiões × ~2 packs é o trabalho
  de arte que falta, e é o que separa isto de parecer conteúdo a sério.
- **A nota de design do próprio Paulo** no plano: *"eu evitaria que todos
  fossem obrigatoriamente nível → boss"*. A tabela do plano dá um chefe a
  cada nível de 31 a 95, e foi essa que se seguiu. Se a ideia dos
  70–75 normais + 15 especiais + 10 chefes principais é para valer, é
  decidir antes de construir as 13 regiões que faltam.
- **O último nível da lista nunca tem jornada** (`indice < NIVEIS.size()-1`
  no `nivel_com_chefe.gd`). Hoje isso é o nível 35, que por isso é só a
  arena do chefe. Resolve-se sozinho quando a Região VIII entrar.

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
