# Combat Lab v1.1 -- correcoes (anti-spam do goblin, clamp de avanco, contrato do Perfect Dodge, isencoes do N6)

Estado (26 set 2026, sem push): **isolado**; nada de combate integrado em producao (inimigos normais, bosses, N1-N6, Energia global, tiro, arte e controlos moveis intactos). Base: `docs/combat_lab_v1.md`.

## 1. Goblin -- anti-spam (regra final)
Regra (`scripts/lab/lab_inimigo.gd`): so' contam golpes LEVES terrestres (`normal`, `dash`, `pogo`); janela de 0,8 s entre golpes para serem a mesma sequencia.
- Golpes 1-3: hitstun normal (0,22/0,26/0,34 s).
- **4.o golpe leve seguido: hitstun x0,25**, **super-armadura de 0,9 s** (golpes leves so' tiram vida), o goblin **recua** (0,32 s, ate' 340 px/s a decair) e **retoma a iniciativa** com um contra-bote telegrafado mais curto (0,30 s, vermelho). A sequencia reinicia.
- Launcher / Cleave / Counter e golpes NO AR nao contam e a armadura nao os trava (intencao continua a funcionar). Nao ha' poise permanente, nem HP extra (500).

### Medido (mesmos bots; `teste_combat_lab_antispam`)
| Cenario | v1 (BEFORE) | v1.1 (AFTER) |
|---|---|---|
| spam com deslocacao, vida 500: TTK / botes completos / acertos no bot | 2,55 s / 1 / 0 | 2,85 s / 1 / 1 |
| spam PARADO, vida 500: TTK | 2,40 s | 2,40 s |
| 12 s de spam, vida infinita: botes completos / acertos / % preso | 5 / 5 / 17 % | 5 / 5 / 26 % |
| 12 s de spam PARADO, vida infinita: botes / acertos / % preso | 5 / 5 / 22 % | 5 / 5 / 40 % |
| escapes disparados em 12 s | 0 | 5-6 |
| N-N-N + Launcher (TTK, lancamentos) | 4,17 s, 1 | 4,17 s, 1 |
| Launcher -> salto -> Air x2 (TTK, golpes no ar) | 7,08 s, 3 | 7,08 s, 3 |
**Conclusao honesta (medida, contraria ao que o v1 sugeria):** o spam NUNCA prendeu o goblin ate' morrer -- nem na v1 (em 12 s de vida infinita ele completava 5 botes e acertava 5 vezes; so' fica ~20 % do tempo em hitstun porque o recuo do combo o afasta). O que faz o spam "dominar" e' a **taxa de dano**: o combo de producao de 4 golpes da' ~250 por 1,2 s; 500 de vida caem em ~2,4-2,9 s. A v1.1 cumpre a regra pedida (o 4.o golpe ja' nao prende, o goblin recua e contra-ataca) mas o resultado por bot e' praticamente o da v1. Combo intencional continua a funcionar (Launcher e Air combo intactos). **BASIC ATTACK SPAM DOMINANT: YES** (por dps, nao por prisao). Opcoes para o GM (nao aplicadas): mais dano nos golpes especiais (launcher/air/cleave) em vez de mais vida; ou o recuo/escape disparar ao 3.o golpe (o remate ficaria em vazio); ou um "imposto de martelar parado" (nao recomendado).

## 2. Clamp do avanco (Koliani ja' nao atravessa o alvo)
`CombateLab.limitar_x` (gancho em `koliani.gd`, so' com o lab e so' durante um golpe): a velocidade horizontal e' limitada para nao passar do **centro** do inimigo a` frente (mesma faixa vertical, +-30 px). Distancia minima ao centro = meia largura do alvo + meia largura dela (10) - **tolerancia 10 px** => goblin 20 px, golem 30 px. So' trava (nunca empurra para tras nem puxa; sem magnetismo nem auto-target); quem ja' esta' depois do centro nao e' tocado; o dash em si continua a atravessar (i-frames): o Dash Attack corta o dash no instante do input e o resto do avanco e' limitado.
Teste `teste_combat_lab_clamp` (Launcher, Cleave, Dash Attack, N3 do combo x goblin, golem x alvo a 50 e 90 px = 16 casos): **sem clamp 6/16 atravessavam; com clamp 0/16; acertos 16/16 nos dois** (o clamp nao faz perder acertos).

## 3. Perfect Dodge -- contrato de dano
`Koliani.receber_dano(quantidade, dir_empurrao := 0.0, origem := "")`. Origem:
| origem | significado | Perfect Dodge |
|---|---|---|
| `""` (omissao) | contacto corporal / desconhecido -- **todos os chamadores de producao de hoje** | **nunca** |
| `"ataque"` | golpe/projectil de um inimigo com telegrafo claro | sim (se o roll estiver na janela de 0,22 s) |
| `"hazard_ataque"` | armadilha que ataca (serra a descer, jato) com ciclo claro | sim |
Regra: o PD so' e' avaliado quando a Koliani esta' invulneravel a meio de um roll; sem origem valida fica registado (`pd_ignorado`) e segue as regras normais. **Contrato para a integracao futura:** cada inimigo/hazard de producao que deva permitir PD passa `"ataque"`/`"hazard_ataque"` no seu golpe telegrafado (Slam/Sweep/Bote ja' o fazem no lab); contacto e dano periodico ficam sem origem. Nada de producao foi migrado (o default `""` mantem tudo como estava).
Lab: `LabInimigo.lab_contato_dano` liga dano de contacto (para teste). `teste_combat_lab_pd_contrato`: contacto (directo e pelo goblin) na janela -> 0 PD; `"ataque"` -> PD; `"hazard_ataque"` -> PD. Bote/Slam/Sweep marcados como ataque (`teste_combat_lab_pd_real` continua a passar). **CONTACT DAMAGE CAN TRIGGER PERFECT_DODGE: NO.**

## 4. N6 -- isencoes de vento
Removidas as duas que mascaravam checkpoints. Correcao minima (so' as duas zonas de ensino, nada mais): `VentoAprende1` 340-700 (era 300-700; ja' nao cobre o `CheckInicio` a 300 nem o spawn) e `VentoAprende2` 700-920 (era 700-1000; ja' nao cobre o `CheckAntesPonte` a 960). Layout, checkpoints, vento das pontes/rota alta, vida do Golem: intactos.
Fica UMA isencao, deliberada: `VentoArena` (mecanica authored, contrato verificado em `teste_n6_autoral`: guia visivel, pulsado, fraco (1500/140), comeca 250+ px antes do Golem e 100+ px depois do `CheckFinal`, nao cobre checkpoint/spawn, fase inicial visivel).

## 5. Testes novos/actualizados
`teste_combat_lab_pd_contrato`, `teste_combat_lab_clamp`, `teste_combat_lab_antispam` (BEFORE/AFTER), `teste_combat_lab` (PD com origem, stun-lock com escape), `teste_n6_autoral` (zonas de ensino fora dos checkpoints, contrato do VentoArena), `test_region02_wind_levels` (so' a isencao da arena).
