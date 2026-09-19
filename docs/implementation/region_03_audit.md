# REGIÃO III — AUDITORIA REAL N11–N15

**Base:** `origin/master` @ `17b90e28` · **Branch:** `claude/region03-completion-pass`
**Contrato:** [`REGION03_VISUAL_GAMEPLAY_CONTRACT.md`](../art_direction/regions/region_03/REGION03_VISUAL_GAMEPLAY_CONTRACT.md)
**Suite no arranque:** PASS (baseline, antes de qualquer alteração).

---

## 0. COMO O NÍVEL É FEITO (isto muda a auditoria toda)

Os cinco níveis usam `nivel_com_chefe.gd`, que **prepende uma JORNADA
procedural** (`gerador_corredor.gd`, 5129 linhas) à sala feita à mão. O que
está no `.tscn` é só **a sala final do chefe**; o grosso do nível — câmaras,
inimigos, hazards, luzes, checkpoints — é gerado em runtime a partir de
tabelas indexadas pela **região** (índice 2 = Região III).

**Consequência:** tornar a Região III canónica **não é** sobretudo editar os
cinco `.tscn`. É sobretudo mexer nas tabelas do gerador para a região 2.
Medir só o `.tscn` dá uma imagem falsa do nível.

---

## 1. BASELINE MEDIDA — as salas feitas à mão

| | N11 | N12 | N13 | N14 | N15 |
|---|---|---|---|---|---|
| Cena | `Torre_dos_Sinos` | `Torre_dos_Ventos` | `Torre_da_Tempestade` | `Observatorio_Lunar` | `O_Pico_Esquecido` |
| Índice | 10 | 11 | 12 | 13 | 14 |
| `largura_nivel` | 2600 | 2600 | 2600 | 2600 | 2600 |
| Extensão x | 200–1065 | 200–1065 | 200–1065 | 200–1065 | 160–1135 |
| Extensão y (altura) | 184–1120 (936) | 194–1120 (926) | 194–1120 (926) | 184–1120 (936) | 268–1120 (852) |
| Plataformas | 16 | 16 | 16 | 16 | 13 |
| Inimigos (à mão) | 1 | 1 | 1 | 1 | 1 |
| Coletáveis | 1 | 1 | 0 | 1 | 1 |
| Ator regional | `SinoTorre` ×2 | `CorrenteAr` ×2 | `RaioTempestade` ×3 + `ParaRaios` ×2 | `ZonaGravidade` ×1 | **nenhum** |
| Chefe | `ChefeSinoVivo` | `ChefeAerion` | `ChefeVoltaris` | `ChefeSacerdotisaLunar` | `ChefeVyrak` |
| `bioma` | `torres` | `torres` | `torres` | `torres` | `torres` |
| `fundo_pack` | `montanhas` | `montanhas` | `montanhas` | `montanhas` | `montanhas` |

### O que estes números provam

1. **As cinco salas são quase clones.** Quatro têm exatamente a mesma
   extensão x (200–1065), a mesma `largura_nivel` (2600) e o mesmo número de
   plataformas (16). O briefing receava "níveis que parecem cópias uns dos
   outros" — na sala feita à mão, **são**.
2. **N15 é a mais pobre**, não a mais rica: 13 plataformas, sem ator
   regional nenhum. É o exame final da região e é a sala com menos conteúdo.
3. **O `fundo_pack` é `montanhas` nos cinco.** O cânone pede cinco camadas
   próprias (silhueta próxima / torres distantes / catedral da cidade /
   montanhas e nuvens / lua e céu). `montanhas` cobre só a camada 4.
4. **`bioma = "torres"` já está certo** nos cinco — a base existe.

---

## 2. O GERADOR NA REGIÃO 2 — onde está a identidade real

| Tabela | Valor hoje | Cânone | Veredicto |
|---|---|---|---|
| `ASSINATURA[2]` | **`"vento"`** | sinos e ecos são "o elemento central" | **ERRADO.** O vento é a assinatura da Região **II** (Desfiladeiro dos Ventos) e, no cânone da III, aparece só como *secção* do N14. |
| `POOL_REGIAO[2]` | `vento, saltos, gravidade, pendulos, trampolim, ritmo, portal, ferry, sinos, alavanca, segredo` | sinos, plataformas rítmicas, elevadores, engrenagens, alavancas | `sinos` **já está na pool** — só não é a assinatura. Falta `elevador` e `quebra` (plataformas que desaparecem / piso que colapsa). |
| `ESPECIES[2]` | `xamane, wogol, olho, abutre, imp` | 10 arquétipos de torre | **Nenhum canónico.** São demónios genéricos herdados. |
| `LIQUIDO[2]` | trevas/vazio | queda vertical | **Certo.** |
| `ASSIN_NIVEL[12]` | `"raio"` (n13 Torre da Tempestade) | N13 = Mecanismos Antigos (engrenagens) | Tema errado para o nível canónico. |

**A alteração de maior retorno por linha mexida da região inteira:**
`ASSINATURA[2]: "vento" → "sinos"`. Faz a câmara de assinatura dos cinco
níveis passar a ser de sinos, que é literalmente o que o cânone diz ser o
elemento central.

---

## 3. CLASSIFICAÇÃO KEEP / ADAPT / REPLACE

| Eixo | N11 | N12 | N13 | N14 | N15 |
|---|---|---|---|---|---|
| **Layout** | KEEP | KEEP | KEEP | KEEP | **ADAPT** (pobre para um exame final) |
| **Gameplay** | KEEP (sinos já cá) | ADAPT | ADAPT | ADAPT | ADAPT |
| **Inimigos** | REPLACE | REPLACE | REPLACE | REPLACE | REPLACE |
| **Arte** | ADAPT | ADAPT | ADAPT | ADAPT | ADAPT |
| **Encontro** | KEEP (guardião) | ADAPT | ADAPT | ADAPT | **REPLACE** |
| **Chefe** | KEEP→guardião | KEEP→guardião | KEEP→guardião | KEEP→guardião | **REPLACE** |
| **Nome** | REPLACE | REPLACE | REPLACE | REPLACE | REPLACE |

Nada é REPLACE no layout: a verticalidade real (≈930 px de subida, poço de
trevas em baixo, bifurcação oeste/este no N11) **está conforme o cânone** e é
o que há de melhor na região. Preserva-se.

---

## 4. N11 — O SINO VIVO (atenção especial pedida)

**Conclusão: PRESERVAR.**

O "Sino Vivo" do briefing **não é uma mecânica** — é o chefe do N11
(`ChefeSinoVivo.tscn`, chave `boss.sino_vivo`, "The Living Bell"). A
confusão vinha de o N11 ter também `SinoTorre.tscn` ×2, que é a mecânica de
tocar sinos para **congelar inimigos** e ganhar a subida.

Ambos são **coerentes com o cânone**:

- um chefe-sino no topo de uma torre de sinos é exatamente a "Torre dos Ecos";
- `SinoTorre` é o "sino ativável"/"mecanismo de sino" das pranchas, e o N11
  canónico pede precisamente "sinos básicos (ativar)" e "sino de entrada
  (ativação inicial)".

**Única alteração necessária:** reclassificar de `boss.sino_vivo` para
`guard.sino_vivo`, porque o cânone só admite **um** confronto na região
(Vyrak). É o mesmo precedente já aplicado na Região II. Gameplay intacto.

---

## 5. N12 — ECRÃ PRETO (atenção especial pedida)

**Estado real: NÃO REPRODUZ. Não mexer.**

Verificado de duas formas, não por memória:

1. **Carregamento headless** de `Torre_dos_Ventos.tscn` (180 frames,
   Godot 4.7.2): `exit = 0`, sem *script errors*, sem *null instance*. Os
   cinco níveis comportam-se igual. (O aviso `1 resources still in use at
   exit` aparece nos cinco e é ruído de encerramento, não falha.)
2. **Frame real renderizado** — headless não desenha nada, por isso não
   podia provar "não é ecrã preto". Capturou-se um PNG verdadeiro com
   `tools/shot_plataforma.gd` sobre **Xvfb** (`tools/capturar_regiao3.sh`).
   A imagem tem terreno, parallax, luz de candeeiro e a Koliani. **Não é
   preto.**

O histórico de ecrã preto é anterior e está resolvido. **Não se cria uma
regressão para um bug que não existe** — um teste "anti-ecrã-preto" sem bug
para apanhar não prova nada. O que se acrescenta (Fase 11) é o teste de
*carregamento* dos cinco níveis, que apanharia a falha de arranque real.

---

## 5b. PROVA VISUAL DA BASELINE — o achado mais grave

Os cinco PNGs reais (`tools/capturar_regiao3.sh`) mostram o que a leitura do
`.tscn` não mostrava:

| Observado no frame | Cânone | Veredicto |
|---|---|---|
| **Pinheiros verdes** no parallax (N11, N13, N15) | torre gótica, silhuetas de torres, catedral | **FAILED** |
| Céu **castanho-avermelhado / magenta** | azul noite + luz de lua | **FAILED** |
| **Cruzes de madeira** (campas) como props | estátuas angélicas, sinos, arcos, vitrais | **FAILED** |
| Corredor de tijolo liso, horizontal | arquitetura vertical e interligada | **LOW** |
| Zero sinos visíveis | "sinos e ecos como elemento central" | **FAILED** |
| Sem lua, sem vitrais, sem arcos | camadas 1–5 do parallax nomeadas | **FAILED** |
| Os cinco frames quase indistinguíveis | 5 facetas distintas da mesma torre | **LOW** |

A causa está identificada e é de uma linha por nível: `fundo_pack =
"montanhas"` puxa arte de floresta/montanha, e a `ASSINATURA[2] = "vento"`
não põe sinos em lado nenhum. **A Região III, hoje, não se lê como uma torre
de sinos — lê-se como floresta ao entardecer.**

Baseline guardada em `docs/playtests/region_03_visual_evidence/antes/`.

---

## 6. N15 — VYRAK (atenção especial pedida)

**Conclusão: REPLACE de identidade, KEEP de arquitetura de código.**

| Eixo | Implementação atual | Cânone aprovado | Fidelidade |
|---|---|---|---|
| Identidade | "Vyrak, **o Dragão das Sombras**" | "Vyrak, **A Voz dos Ecos**" | **FAILED** |
| Silhueta | besta alada, rig `bosses_anim/alado`, 4 frames | guardião humanoide encapuzado, coroa anelar, sino ao peito, asas de eco | **FAILED** |
| Escala | `escala_visual = 1.35` | ≈ **4× Koliani** | **FAILED** |
| Paleta | roxo-sombra (`0.75,0.45,1`), núcleo em brasa | ouro antigo + azul noite + energia de eco + vitral | **LOW** |
| Fases | **3** (pico → voa → em cima dele) | **2** (100–50 %, ritual, 50–0 %) | **FAILED** |
| Ataques | garra, sopro de sombra, cauda, bolas de sombra, nova | 9 nomeados: golpe de sino, onda de eco, sino em queda, lanças de luz, investida aérea, chuva de sinos, espiral de ecos, parede de eco, julgamento final | **FAILED** |
| Arena | "plataformas_pico" caem na F2 | plataforma contínua → expande com sinos e plataformas novas | **LOW** |
| Recompensa | genérica | Memória de Vyrak · Cristal de Eco · Insígnia da Torre | ausente |

**O que se preserva:** a *arquitetura* de `chefe_vyrak.gd` é boa e não se
deita fora — máquina de estados `TELEGRAFO → ATAQUE → EXPOSTO`, herança de
`ChefeBase`, gestão de fases por percentagem de vida, núcleo exposto com dano
a dobrar. Isso mapeia diretamente nos princípios canónicos ("boss sempre
atingível", "telegraphing claro", "janelas de reação justas").

**O que muda:** identidade, sprite, escala, paleta, o conjunto de ataques e a
contagem de fases (3 → 2). Não é polimento — a prancha e o jogo descrevem
duas criaturas diferentes.

> Registo: o texto antigo do projeto (`docs/niveis.md`, `docs/progresso_agente.md`)
> chama-lhe dragão. As pranchas APPROVED são a fonte de verdade e o
> `README.md` da região di-lo explicitamente ("Não inferir cânone a partir de
> texto errado dentro dos PNGs" — e, por maioria de razão, de texto antigo
> fora deles). Os docs de texto é que estão desatualizados.

---

## 7. INVENTÁRIO DE INIMIGOS

| Inimigo canónico | Implementação hoje | Comportamento `DemonioBase` que serve |
|---|---|---|
| Sentinela da Torre | **nenhuma** | `escudeiro` (bloqueia) |
| Acólito do Eco | **nenhuma** | `cuspidor` |
| Autómato do Sino | **nenhuma** | `carga` lento/resistente |
| Gárgula Vitral | **nenhuma** | `voador` |
| Sino Flutuante | **nenhuma** | `voador` (rota fixa) |
| Arqueiro das Sombras | **nenhuma** | `cuspidor` (posição elevada) |
| Monge das Correntes | **nenhuma** | `patrulha` + puxão (**falta**) |
| Espírito do Eco | **nenhuma** | `carga` que explode |
| Construto Vitral | **nenhuma** | `carga` pesado |
| Corvo do Sino | **nenhuma** | `voador` rápido |

`DemonioBase` tem 7 comportamentos (`patrulha`, `saltador`, `carga`,
`voador`, `escudeiro`, `trepador`, `cuspidor`) e species ligadas a folhas de
pixel-art. **9 dos 10 arquétipos mapeiam em comportamento já existente** — o
custo real é **arte** (10 folhas novas), não IA.

O que a região usa hoje são `xamane`, `wogol`, `olho`, `abutre`, `imp`:
demónios genéricos, os mesmos das regiões anteriores. É exatamente o que o
briefing proíbe ("inimigos herdados de biomas anteriores sem razão").

---

## 8. PROGRESSÃO DE DIFICULDADE — baseline

Não há *spikes* medidos na sala feita à mão porque **não há praticamente
combate lá**: 1 inimigo por nível nos cinco. A dificuldade real vem do
gerador, que escala por `_regiao` e `intens`.

O cânone pede combate a subir 30 % → 60 % ao longo de N11→N15. Hoje a sala
feita à mão é ~0 % de combate nos cinco e o gerador não distingue os níveis
entre si dentro da região a não ser pelo `PERFIL` de forma.

**Baseline para comparar depois da implementação:** inimigos à mão 1/1/1/1/1;
plataformas 16/16/16/16/13; altura 936/926/926/936/852.

---

## 9. ORDEM DE TRABALHO (por retorno canónico)

1. **Nomes canónicos** — i18n nas 6 línguas, `boss.*` → `guard.*` em N11–N14.
   Barato, exato, e é o que o jogador lê.
2. **`ASSINATURA[2]` `vento` → `sinos`** — uma linha, muda a identidade do
   procedural nos cinco níveis.
3. **Vyrak** — o único FAILED. Sprite, escala, paleta, 2 fases, ataques do cânone.
4. **Parallax `torre_ecos`** — as 5 camadas nomeadas, em vez de `montanhas`.
5. **Inimigos** — arquétipos da torre no lugar dos demónios genéricos.
6. **Mecânicas por nível** — sinos nos cinco; engrenagens no N13; updraft no N14.
7. Testes, bot, evidência visual, build.
