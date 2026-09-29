# Combat Lab v1 -- nova direcao de combate da Koliani (PROTOTIPO ISOLADO)

Estado (26 set 2026, sem push): **PRONTO PARA PLAYTEST DO GM DE COMBATE.** Nao integrado em nenhum nivel; N1-N6 e bosses intactos.
Correr: `Godot --path . res://scenes/lab/CombatLab.tscn` (teclas: `1` goblin, `2` golem, `3` ambos, `R` reset, `P` resumo no terminal, `H` ajuda; `--lab-log` imprime cada evento).

## 1. Arquitectura
| Peca | Ficheiro | Papel |
|---|---|---|
| Arena | `scenes/lab/CombatLab.tscn` + `scripts/lab/combat_lab_cena.gd` | chao 2600 px, paredes, Koliani com o lab ligado, kit do lab (`dash, pogo, salto_duplo, especial, projetil`; so' em memoria, restaura ao sair), sem morte (cura abaixo de 40 de vida) |
| Componente | `scripts/lab/combate_lab.gd` (`CombateLab`) | Launcher, cadeia aerea, Cleave, Dash Attack, Perfect Dodge, Counter. E' FILHO da Koliani, criado por `Koliani.ativar_combat_lab()`; sem ele `_lab == null` |
| Alvos | `scripts/lab/lab_inimigo.gd` (`LabInimigo extends DemonioBase`) + `LabGoblin.tscn` / `LabGolem.tscn` | IA e reaccao proprias; **variantes so' do lab** (as cenas/numeros de producao nao mudam) |
| Metricas / HUD | `lab_metricas.gd`, `lab_hud.gd` | registo de eventos (golpes, hits, energia, PD, mortes) e overlay |
Ganchos em `scripts/koliani.gd` (todos gated por `_lab != null`): `tick`/`tratar_input` antes do input de ataque, `ar_pode_encadear`/`ar_passo_seguinte` na cadeia aerea, `ao_acertar_normal` na hitbox normal, `tentativa_de_dano` em `receber_dano` (invulneravel), `lab_golpe_custom` (desliga a hitbox normal durante golpes do lab). Nenhuma fisica F1 mexida; o Pogo e' o de producao.

## 2. Inputs finais
ATAQUE x3 = combo base | **CIMA+ATAQUE (chao) = Launcher** | ATAQUE no ar = cadeia de ate' 2 | BAIXO+ATAQUE no ar = Pogo (inalterado) | **SEGURAR ATAQUE >= 0,50 s e largar = Shadow Cleave** | **ATAQUE durante/logo apos DASH = Dash Attack** | ROLL a tempo = **Perfect Dodge** | ATAQUE ate' 0,60 s depois = **Shadow Counter** (so' com input). Sem botoes novos.

## 3. Frame data (60 Hz; 1 frame = 0,0167 s)
| Golpe | Startup | Activo | Recuperacao | Total | Avanco |
|---|---|---|---|---|---|
| Combo N1-N4 (producao) | ~4-8 f | ~0,10-0,15 s | (ver `DUR_COMBO` 0,18/0,20/0,30/0,26) | -- | 330-470 px/s |
| Launcher | 0,10 s (6 f) | 0,10 s (6 f) | 0,24 s (14 f) | 0,44 s | 0 |
| Air 1 / Air 2 (golpes de producao 1/2 no ar) | -- | -- | -- | 0,18 / 0,20 s | x0,5 |
| Dash Attack | 0,04 s (2 f) | 0,10 s (6 f) | 0,22 s (13 f) | 0,36 s | 300 px/s x 0,14 s (<= 42 px; corta o dash restante) |
| Shadow Cleave | carga 0,50 s + 0,14 s (8 f) | 0,12 s (7 f) | 0,40 s (24 f) | 0,66 s | 160 px/s x 0,12 s |
| Shadow Counter | 0,06 s (4 f) | 0,12 s (7 f) | 0,16 s (10 f) | 0,34 s | 520 px/s x 0,14 s |
Cancelamentos: golpe normal que ACERTOU -> Launcher; Launcher que acertou + salto -> golpe aereo; Dash Attack/Counter/Cleave que acertaram + CIMA -> Launcher; qualquer ATAQUE durante um golpe do lab fica em buffer e sai no fim da recuperacao (o compromisso mantem-se).

## 4. Dano / stagger / knockback (dano base da espada = 50)
| Golpe | Dano | Goblin | Golem |
|---|---|---|---|
| N1/N2/N3/N4 | x0,85 / 1,0 / 1,25 / 1,9 | hitstun 0,22/0,26/0,34/0,40 s, recuo 90-210 | guardado (20 %), -5 guarda |
| Launcher | x0,9 (45) | **lancado** (vy -560, ~0,8 s no ar); 1,2 s imune a novo launcher depois de cair | guardado, -8 guarda, **nao lancado** |
| Air 1 / Air 2 | 42 / 50 | no ar: elevacao -170 (juggle, max 3; depois cai a 1,6 g) | -- |
| Dash Attack | x1,15 (57) | hitstun 0,30, recuo 200 | guardado, -8 guarda |
| Shadow Cleave | x2,0 (100) | hitstun 0,80, recuo 300 (ignora o encolher) | **quebra a guarda**: 1,6 s exposto (x1,4), 3 s imune a nova quebra |
| Shadow Counter | x2,4 (120) | hitstun 1,00, recuo 520 | idem Cleave |
| Pogo (producao) | x1,0 (50) | como golpe no ar | guardado, -10 guarda |
| Critico (pos-roll) | x1,7 | | |

## 5. Goblin (leve) -- `LabInimigo` `goblin`
Vida 500 (~10 golpes; vida de producao a escala do nivel nao se usa). Aproxima-se a 80 px/s; a <= 80 px: **telegrafo 0,50 s** (vermelho), bote 0,14 s a 320 px/s (14 de dano), recuperacao 0,70 s, cd 0,8 s. Lancavel, juggle max 3, cai 0,5 s. **Anti stun-lock**: cada hitstun em 2 s encolhe 25 %; ao 4.o ganha 1,0 s de super-armadura; cleave/counter ignoram o encolher. Contacto nao fere: so' o bote.

## 6. Golem (pesado) -- `LabInimigo` `golem` (escala 1,5)
Vida 2000, **guarda 100**. Nao e' lancado nem interrompido por golpes normais. Guarda levantada em IDLE/aproximar: golpe de FRENTE conta 20 % e gasta guarda (5 normal, 8 launcher/dash, 10 pogo); guarda a 0 tambem quebra. Pelas costas / a atacar: dano inteiro sem interromper. Quebrada: 1,6 s exposto (x1,4), depois guarda cheia e 3 s imune a nova quebra. Ataques telegrafados: **SLAM** (0,85 s de aviso, 0,16 s activo, alcance 110, 28 de dano, recup 0,90 s) e **SWEEP** (0,60 s, 0,20 s, alcance 150, baixo -- salta-se, 22 de dano, recup 0,70 s), sorteio 50/50 com semente.

## 7. Perfect Dodge
Roll existente. **Janela: o golpe inimigo tem de cair nos primeiros 0,22 s dos 0,30 s do roll** (as i-frames sao as de producao; os ultimos 0,08 s protegem mas nao contam). Cooldown 0,90 s (sem farmar). So' o Roll conta (o Dash nao). Efeito: hit-stop 0,06 s, flash branco + aura + tremor, texto `PERFECT DODGE`, som (`acerto_critico` + `bloqueio` agudo), **+25 Energia**.
Medido contra o golem real (`teste_combat_lab_pd_real`): roll a 0,09 s do golpe -> PD, 0 de dano; roll a 0,62 s -> nao conta (a distancia salva-a, sem PD).

## 8. Counter
Janela **0,60 s** depois do PD. NAO e' automatico (medido: 30 frames sem input -> sem counter). Corta o resto do roll, avanca 520 px/s x 0,14 s, x2,4, quebra guarda, **+10 Energia** (alem dos +25 do PD). Fora da janela nao existe.

## 9. Energia por accao (0-99; Especial custa 33; regen 12/s inalterada)
Golpe normal que acerta +5 (producao) | Launcher +5 | Dash Attack +5 | Cleave +8 | Counter +10 | **Perfect Dodge +25** | Pogo +8 (producao). PD + Counter = +35 numa troca (1/3 da barra = um Especial). Nao se mexeu na regeneracao global do N4.

## 10. Combos encontrados (todos testados por script)
1 N-N-N (passos 0,1,2) OK | 2 Launcher -> salto -> Ar -> Ar (3.o ar recusado) OK | 3 Launcher -> Air combo -> Pogo OK | 4 Dash -> Attack (nao alarga o dash) OK | 5 Cleave -> golpe normal (buffer) OK | 6 PD -> Counter OK | 7 Dash Attack -> Launcher -> Air combo OK | 8 Air combo -> Pogo (repoe a cadeia aerea) -> novo golpe aereo OK. Uteis de facto (medidos): Launcher, Air x2, Dash Attack, Cleave (so' contra o golem), Counter, Pogo.

## 11. Problemas / exploits / observacoes
1. **Spam ainda e' forte contra o goblin**: um bot que toca ATAQUE a cada 0,3 s mata-o em ~2,95 s deixando-o acertar 1 vez (o encolher/armadura so' entra ao 4.o hitstun seguido, quando ja' esta' quase morto). Decisao do GM: hitstun mais curto no N1-N2 do combo ou goblin com poise.
2. **Stun-lock/juggle infinito: NAO encontrado.** 30 golpes leves em 6 s -> super-armadura liga e < 85 % do tempo em hitstun; juggle capado a 3 elevacoes; launcher com 1,2 s de imunidade. O loop Air x2 -> Pogo -> Air x2 esta' limitado por vida e pelo juggle (a cadeia repoe-se com o pogo por desenho: e' o "reposicionamento").
3. A Koliani **nao colide com inimigos**: o avanco dos golpes pode leva-la ATRAVES do alvo e o Cleave/Launcher falha (rect comeca a -10 px). Nao e' exploit, mas pede um `alcance` mais tolerante ou ancoragem ao alvo.
4. **Perfect Dodge em producao**: hoje `tentativa_de_dano` conta qualquer dano bloqueado por i-frames durante o roll (incl. contacto). No lab so' os ataques telegrafados ferem. Antes de integrar: marcar a fonte como "ataque".
5. O Cleave exige SEGURAR: o toque de inicio dispara um golpe normal (custo aceite por ser o tap normal; a carga so' conta com a Koliani no chao, sem roll nem dano).
6. O golpe aereo unico de producao ganhou cadeia de 2: `_combo_pedido` aereo e `_combo_passo` aereo passam pelo lab (so' com o lab).
7. TTK **por bots simples** (nao dao TTK humano): goblin 3,75 s total (2,95 s desde o 1.o golpe; 8 acertos), golem 13,28 s total (11,1 s; 23 acertos; bot cleave+combo, sem esquivar, levou 3 golpes).

## 12. Assets / animacoes em falta (tudo placeholder)
Poses/animacoes proprias de Launcher (usa `attack3`), Dash Attack, Cleave (pose de carga e de corte), Counter; VFX de carga/corte/quebra de guarda e de Perfect Dodge (so' flash + texto); som proprio de guard break e de PD (reusa `acerto_critico`/`bloqueio`); animacoes de telegrafo do goblin/golem (so' tom vermelho); reaccoes de lancado/exposto; icones/UI tactil (**controlos de telemovel NAO adaptados**: CIMA+ATAQUE e segurar ATAQUE pedem mapeamento no joystick/botao).

## 13. Testes (`tests/run_tests.gd`)
`teste_combat_lab` (isolamento; launcher lanca goblin e nao o golem; air combo = 2; cleave quebra guarda, toque curto nao; dash attack nao alarga; PD janela/cooldown/energia; counter nao automatico e so' na janela; anti stun-lock e juggle; TTK), `teste_combat_lab_combos` (combos 1,3,5,7,8), `teste_combat_lab_pd_real` (golem real).
