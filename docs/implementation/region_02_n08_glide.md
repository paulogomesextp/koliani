# Região II — N08 Ilhas Suspensas + planar (glide)

## Estado

**PARTIAL — HUMAN PLAYTEST REQUIRED** (17 set 2026, Process 11).

Integração técnica concluída e verificada no motor: cena carrega, suite
completa, harness de glide A–O, WindZone A–L, Movement+Camera 4A, verificações
do CI e rota automática do spawn à arena com a Koliani real, sem modo Dev.
Falta o percurso humano (sensação, legibilidade, justiça dos vãos e luta com o
chefe), por isso não há PASS final. Browser/telemóvel: **DEVICE VALIDATION
REQUIRED**.

Branch `claude/region02-n08-glide`, base `c41c19ed` (`origin/codex/region02-wind-system`).

## Decisão: planar LOCAL/CONTEXTUAL, não habilidade permanente

O jogo já tem a habilidade permanente `"planar"`
(`EstadoJogo.HABILIDADES_TODAS`), ensinada e desbloqueada no **N63** (Asas,
`gerador_corredor.gd`, texto `mec.asas`). A auditoria regional já avisava que
antecipá-la no N08 era uma decisão de progressão. Dar a habilidade no N08
mudaria a campanha (N09–N62 passariam a ter planar em todo o lado, incluindo a
Região V, que é a de mobilidade aérea) e o significado do N63.

Por isso o planar do N08 é **contextual**: uma `ZonaPlanar` concede-o
enquanto a Koliani está dentro dela. Nada é gravado, desbloqueado ou
anunciado na HUD como habilidade. A habilidade permanente continua intacta e
as duas fontes partilham exatamente a mesma física.

## Contrato do planar

| Tema | Regra |
|---|---|
| Tipo | Local/contextual (`ZonaPlanar`); a permanente `"planar"` (N63) continua a valer onde existir. |
| Input | Segurar **saltar** (o mesmo botão do N63; nenhum botão novo no telemóvel). |
| Ativação | No ar, a descer, com saltar seguro e contexto ativo (ou habilidade). Sem atraso: prende a queda no próprio frame. |
| Desativação | Largar saltar, aterrar, sair da zona, zona desligada/libertada, atordoamento de dano, dash/rolamento/escudo/gancho/parede (estados exclusivos não planam). |
| Queda | Presa a `Movimento.VEL_PLANAR` = 190 px/s (queda normal até 1100). |
| Subida | Nunca: só atua quando `vy > 190` a descer; a subida de um salto é igual com e sem planar. |
| Controlo horizontal | O controlo aéreo normal (corrida 240, `ACEL_AR` 1350, viragem 1800). Não há aceleração nem velocidade extra. |
| Vento | `WindZone` soma a força **depois** do tecto do planar (ordem já existente em `koliani.gd`). Rajadas mudam `vx`; o tecto vertical mantém-se. |
| Corrente ascendente | Levanta quem plana só se for mais forte do que a queda (> 1708 px/s²) e sempre limitada por `velocidade_max`; fora da coluna volta a descer a 190. |
| Dash | O dash manda (vy = 0, 620 px/s); o planar retoma sozinho no fim, se saltar continuar seguro. |
| Dano / knockback | A Koliani não recebe empurrão físico ao levar dano (contrato existente). Durante `_hurt_t` (0,24 s) o planar fica suspenso — o golpe lê-se como queda — e retoma depois. Impulsos externos (`aplicar_impulso`) não são afetados. |
| Aterragem | No chão não há planar; saltos e coyote repõem-se como sempre. Nenhum estado sobrevive ao frame (`_planando` volta a falso em cada physics frame). |
| Morte | Morrer recarrega a cena: Koliani e zonas nascem de novo, sem contexto. |
| Respawn | `recuperar_no_checkpoint` limpa contexto, `_planando`, ventos e velocidade; a `ZonaPlanar` que cobre a fogueira volta a conceder no frame seguinte. |
| Mudança de cena | `ZonaPlanar._exit_tree` retira o contexto no mesmo frame; TTL de 0,12 s como rede (teleporte, sinal perdido, zona libertada). |
| Suspensão | `habilidades_suspensas` com `"planar"` (`ZonaSemPoder`) desliga também o contexto. |
| Modo Dev | Continua a dar tudo, incluindo a habilidade permanente; os testes e o bot do N08 correm **sem** modo Dev. |

## Arquitetura

- `scripts/zona_planar.gd` + `scenes/actors/ZonaPlanar.tscn` (`class_name ZonaPlanar`): `Area2D` na máscara da Koliani (layer 2), grupo `zonas_planar`, `tamanho` e `ativa` exportados. Renova `atualizar_planar_contextual(self)` por physics frame para cada corpo dentro, remove na saída e no `_exit_tree`. Duplica a forma antes de a redimensionar.
- `scripts/koliani.gd`: registo por origem (`_planar_contextos`, chave `instance_id`, `WeakRef`, TTL `PLANAR_CONTEXTO_TTL`), API `atualizar_planar_contextual`, `remover_planar_contextual`, `limpar_planar_contextual`, `quantidade_planar_contextual`, `pode_planar`, `esta_a_planar`. O pedido de planar passa a `pode_planar() and _hurt_t <= 0`. Nenhuma constante global de gravidade/velocidade foi mudada; `movimento.gd` não foi tocado.
- `scripts/nivel_com_chefe.gd`: `@export var mecanica_anunciada` — permite a uma sala à mão ensinar outra mecânica que não a estreia da jornada. O N08 usa `"asas"` (texto existente nas 6 línguas: "Hold jump while falling to glide…"). Não há strings novas nem mudança de UI.
- Sem `level == 8` em lado nenhum: o N08 é só uma cena com uma `ZonaPlanar`.

## N08 — o que mudou

Cena: `res://scenes/levels/Corredor_das_Execucoes.tscn` (nome e UID
mantidos: `EstadoJogo.NIVEIS`, manifesto, saves e seletor apontam para ela).

| Elemento antigo | Decisão | Nota |
|---|---|---|
| Spawn `(150,600)`, 3 fogueiras, porta, chefe | KEEP | Três fogueiras nos mesmos papéis (início, meio, pré-arena). |
| `ColProjetil` (habilidade `projetil`) | KEEP | Progressão; passou para a ilha da fogueira do meio, no caminho crítico. |
| Chefe Dama da Guilhotina + chão da arena (560 px) | KEEP | Cena/script intactos; arena mudou só de x/y. O ataque de guilhotinas usa o grupo `guilhotinas_arena`, que já estava vazio antes. |
| Elite chort de carga | KEEP | Numa ilha própria antes da fogueira do meio; `alcance_patrulha` 110 → 90 para caber na ilha. |
| Jornada procedural (`corredor = true`) | REMOVE | Gerava câmaras de guilhotinas (estreia do N08 na tabela do gerador) e dominava o nível. Agora `corredor = false`. |
| `alongar_plataformas` | REMOVE | Desligado: o esticão automático mudaria os vãos medidos. |
| Guilhotinas ×5, serra, plataforma quebrável, ácido | REMOVE | Identidade prisional; a queda no abismo (`Y_MORTE`) é o perigo. |
| `CascaMasmorra` | REMOVE | Teto e volumes de alvenaria fechavam o céu e cortavam a subida; paredes-limite simples no início e no fim substituem as laterais. |
| Corredor horizontal + mini-bifurcação | REPLACE | Sequência de ilhas suspensas. |
| `Atmosfera` | ADAPT | Só `largura_nivel` 3400 → 5800. Paleta/pack prisionais ficam para o art pass. |
| `ZonaPlanar`, 3 `WindZone` | ADD | Ver abaixo. |

### Sequência (x cresce para a direita; y para baixo; topo das plataformas)

1. **Partida** — `ChaoInicio` 0–460 @650, fogueira 1.
2. **Ensaio** — vão 280 px a descer 100 até `Ilha1` (740–1000 @750). Quem falha cai na `RedeEnsaio` (470–700 @860) e volta a subir (110 px). Placa do planar à entrada.
3. **Cadeia** — `Pedra1` estreita (80 px @820), depois vão de 380 px a descer 80 até `Ilha2` (1640–1900 @900).
4. **Corrente** — coluna `CorrenteSubida` (x 1950–2150, y 500–1100, 2600 px/s², teto 340, contínua) leva a `Ilha3` (2170–2440 @560), encostada à coluna. Quem sai por baixo/pela direita apanha o `RepousoCorrente` (2170–2290 @800) e volta a entrar.
5. **Meio** — `IlhaElite` (2560–2880 @600) com o chort; `IlhaMeio` (2960–3240 @600) com a fogueira 2 e o projetil.
6. **A favor** — `RajadaFavor` contínua (x 3260–3880, y 380–720, 2000 px/s², teto 420) sobre um vão de 640 px a descer 80 até `IlhaVento` (3880–4160 @680). É o vão-assinatura: só se faz a planar.
7. **Contra** — `RajadaContra` pulsada (x 4160–4400, y 480–760, 1600 px/s², teto 150, 0,9 s ligada / 1,6 s pausa) sobre 240 px até `IlhaContra` (4400–4640 @700). Com as setas acesas, a segurar em frente o planar encalha (vx ≈ 0); atravessar cabe na pausa.
8. **Arena** — vão de 360 px a descer 60 até `ChaoChefe` (5000–5560 @760); fogueira 3 a 220 px do chefe; porta em 5530; parede-limite `MuroFim`.

`ZonaPlanar` única: centro (2780, 325), 5680 × 1850 — cobre spawn, fogueiras,
todas as ilhas e a porta. Nenhuma `WindZone` cobre fogueiras, spawn ou chefe.

### Defeito encontrado no `WindZone` (anterior, não corrigido)

`WindZone.tscn` tem um único `RectangleShape2D` e `wind_zone.gd::_configurar_forma`
redimensiona esse recurso **partilhado**. Numa cena com várias zonas, todas
colidem com o `tamanho` da última configurada; o guia de setas desenha o
tamanho exportado, por isso não se nota a olho. Medido no motor:

| Cena | Zona | `tamanho` | colisão real |
|---|---|---|---|
| N06 | VentoEntrada | 760×250 | 820×300 |
| N07 | UpdraftMeio | 210×320 | 190×300 |
| N09 | VentoVariavelEntrada | 680×240 | **300×220** |
| N09 | VentoVariavelCombate | 650×270 | **300×220** |

No N08 cada `WindZone` tem forma própria na cena (sub-recurso local), e o
teste estrutural exige-o. `wind_zone.gd` e N06/N07/N09 **não** foram mexidos
(fora do scope; mudar as áreas efetivas altera níveis já aceites em playtest).
Correção recomendada num lote próprio: duplicar a forma em
`_configurar_forma` (como a `ZonaPlanar` faz) e repetir o playtest de
N06/N07/N09.

## Ferramentas de verificação

- `tools/verifica_alcance.gd` (CI, via `verifica_alcance_todos.gd`) passa a ler `ZonaPlanar` e `WindZone` **contínuas**: vão de planar `300 + descida` (teto 700), bónus de rajada a favor, subida por corrente mais forte do que a queda. Sem essas zonas o crivo é idêntico ao anterior; pulsos não contam. Medido: 100 níveis, 0 portas inalcançáveis; N08 `porta_alcancavel=true` (órfãs só as duas paredes-limite, de propósito).
- `tools/verifica_rota_n08.gd` (novo, manual): joga o N08 com a Koliani real e o kit de chegada (`dash`, `salto_duplo`, `dash_aereo`, `escalar_paredes`), sem modo Dev e sem imunidade, com teclas simuladas.
  - `rota`: spawn → chão da arena, vão a vão, com morte provocada depois da fogueira do meio.
  - `sem_planar` / `sem_planar_dash [vão]`: contrafactual com a `ZonaPlanar` desligada, vão a vão.
- `tools/verifica_casca.gd` e `tools/verifica_interiores_masmorras.gd`: o N08 saiu da lista de masmorras (já não tem Casca).

## Testes

- `tests/test_glide_region02.gd` (na suite): matemática pura — A salto normal, B ativar em queda, C sem subida, D gravidade ativa, E largar restaura, F aterragem repõe saltos, H vento lateral e rajada contra, I corrente com teto e regresso ao tecto, N 20 ativações.
- `tests/run_glide_region02.tscn` (harness no motor): contexto dentro/fora, B–E, G dash, J dano, H a favor/sair/contra, I corrente e zona libertada, N botão, M zona fora da árvore, F aterragem, L respawn, K instância nova, O nada gravado + suspensão.
- `tests/test_region02_n08_level.gd` (na suite): contrato estrutural (sem jornada, sem esticão, placa `asas`, spawn/porta/chefe/projetil/3 fogueiras, nenhum `habilidade_id = "planar"`, nenhum perigo prisional, `ZonaPlanar` a cobrir spawn/fogueiras/porta/plataformas, corrente contínua > queda, a favor contínua, contra pulsada com pausa maior, forma própria por zona, zonas fora de fogueiras/spawn/chefe, última fogueira ≤ 260 px do chefe).
- Mutações provaram que as asserções mordem: tirar a suspensão por dano → J falha; tirar a limpeza no respawn → L falha; não remover no `_exit_tree` → M falha; tirar a forma própria das rajadas e afastar a última fogueira → estrutural falha; partir o tecto do planar → A–N falham.

### Resultados (17 set 2026, Godot 4.7.2, APPDATA isolado)

| Prova | Baseline `c41c19ed` | Final |
|---|---|---|
| Suite completa (`tools/correr_testes.ps1`) | OK, EXIT 0 | OK, EXIT 0, save real intacto |
| WindZone A–L | OK | OK |
| Movement + Camera 4A | OK | OK |
| Glide A–O (harness) | — | OK |
| Smoke N08 | EXIT 0 | EXIT 0 (240 e 600 frames) |
| Alcance N08 | porta alcançável (sala antiga) | porta alcançável |
| Alcance 100 níveis (CI) | — | 0 portas inalcançáveis |
| CI: jornada, mecânicas, baú, regras de bicho, actores novos, câmaras novas, Aerion, spawn livre | — | todos EXIT 0 / TUDO OK; N08 lido como "sala à mão, sem jornada" |
| Rota N08 (`rota`) | — | chegou à arena; 1 morte provocada; respawn na fogueira do meio com ventos=0, contexto=1, a_planar=false |

Contrafactual sem planar (mesmas teclas, cada vão isolado):

| Vão | Só salto duplo | Duplo + dash aéreo |
|---|---|---|
| ensaio | passa | passa |
| pedra | passa | (bot passa do alvo) |
| cadeia | **não** | passa |
| corrente | passa (é o vento que sobe) | (bot passa do alvo) |
| elite / meio | passa | — |
| a favor (640 px) | **não** | **não** |
| contra | passa | passa |
| arena (360 px) | **não** | passa |

Leitura: o planar é o caminho pensado, e o vão com vento a favor só se faz a
planar. Quem domina o dash aéreo encurta dois vãos sem planar — é o dash
existente, que não foi mexido. O bot tem timing perfeito: a margem humana tem
de ser medida no playtest.

## Limitações

- Sem feedback visual próprio do planar (nem pose nem partículas): lê-se pela queda lenta. É gameplay e estrutura; a arte e o SFX da Região II são processos posteriores.
- Fundo, paleta e props continuam prisionais (`Atmosfera` "prisao"); os props automáticos das plataformas (caixas, candeeiros) ainda aparecem.
- O bot não luta com o chefe nem com o elite; a luta é a mesma de antes, com arena reposicionada.
- Valores de vento, vãos e a largura da pausa contra foram afinados por medição, não por sensação.
- A placa `asas` fica marcada como explicada na sessão: se se jogar o N63 na mesma sessão, a placa não se repete.

## Checklist de playtest humano (progressão normal, sem Dev)

Save normal com N01–N07 concluídos (`dash`, `salto_duplo`, `dash_aereo`,
`escalar_paredes`), ou `--nivel=8` sobre esse save sem modo Dev.

1. A placa "Glide" aparece à entrada e o ensaio ensina a segurar saltar; falhar cai na rede e dá para voltar.
2. Cadeia e pedra estreita: aterrar sem frustração a planar.
3. Corrente: entrar a planar, subir a segurar saltar e passar para a `Ilha3`; sair por baixo e usar o repouso.
4. Elite e fogueira do meio; apanhar o projetil.
5. Vão a favor (640 px): leitura das setas, sensação de ser levada, aterragem.
6. Vão contra: perceber a pausa pelas setas; a travessia cabe na pausa.
7. Arena: vão final, fogueira pré-arena, chefe, baú e porta.
8. Morrer nas três secções: reaparece na fogueira certa, sem vento/planar residual.
9. Nada de planar fora do N08 (ex.: N09) e nenhuma habilidade nova na HUD.
