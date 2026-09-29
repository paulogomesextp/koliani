# Combat Lab v1.2 -- hierarquia de dano (BASIC SPAM < COMBO INTENCIONAL)

Estado (26 set 2026, sem push): **isolado no Combat Lab**; nenhum nivel, boss, inimigo de producao, tiro, Energia global ou controlo movel foi tocado. Base: `combat_lab_v1.md` + `combat_lab_v1_1.md`. Mantido EXACTAMENTE da v1.1: anti-stunlock/escape do goblin, Goblin = 500 HP, clamp de 10 px (0 atravessamentos), PD so' com `ataque`/`hazard_ataque`, correccao dos checkpoints do N6 (N6 nao foi tocado).

## O que mudou (so' lab; valores afinaveis em `combate_lab.gd`)
Multiplicadores do dano base da espada (50):
| Golpe | BEFORE (producao / v1.1) | AFTER (v1.2) | dano @50 |
|---|---|---|---|
| N1 | 0,85 | **0,30** | 42 -> 15 |
| N2 | 1,00 | **0,35** | 50 -> 17 |
| N3 (atordoa) | 1,25 | **0,43** | 62 -> 21 |
| N4 (remate; e' critico apos o atordoamento do N3, x1,7) | 1,90 | **0,60** | 95 (161 crit) -> 30 (51 crit) |
| Air 1 / Air 2 | 0,85 / 1,00 (golpe aereo unico) | **1,40 / 1,60** | 42 / 50 -> 70 / 80 |
| Launcher | 0,90 | **1,30** | 45 -> 65 |
| Dash Attack | 1,15 | **1,30** | 57 -> 65 |
| Shadow Cleave | 2,00 | **2,30** (+ quebra guarda) | 100 -> 115 |
| Shadow Counter | 2,40 | **2,70** (+ quebra guarda) | 120 -> 135 |
Combo basico -- recuperacao: **N4 0,26 s -> 0,38 s** (+0,12 s; a janela activa nao muda, so' a recuperacao); N1-N3 inalterados (0,18/0,20/0,30 s). O remate **nao cancela gratis** para o Launcher (antes cancelava depois de acertar); o recuo do goblin nos golpes do combo passou de 90/130/170/210 para **70/80/90/100 px/s** (o 4.o golpe ja' nao o atira para fora do golpe seguinte). Imunidade do goblin a novo launcher depois de cair: 1,2 s -> **0,8 s** (para o loop Dash Attack -> Launcher -> Air nao ficar refem de uma pausa longa; continua a haver imunidade anti-loop).
O combo de 4 golpes continua completo (N1-N2-N3-N4, o N3 ainda atordoa e o N4 ainda acerta).

## TTK no mesmo goblin de 500 HP (do 1.o golpe recebido ate' morrer; `teste_combat_lab_balanco`)
| Cenario | v1.1 (BEFORE) | v1.2 (AFTER) | alvo |
|---|---|---|---|
| Spam PARADO (toca ATAQUE a cada 0,3 s sem andar) | 2,40 s * | **4,48 s** | 4,5-6 s |
| Spam com deslocacao (persegue o goblin) | 2,85 s * | **4,92 s** | 4-6 s |
| Combo intencional bem executado (Dash Attack -> Launcher -> Air x2, N-N-N enquanto o goblin esta' imune a launcher) | n/m (bot ideal criado na v1.2) | **3,60 s** | 3-4,5 s |
(* medidos na v1.1 com a cauda do bot incluida, por isso o valor real e' um pouco menor; a v1.2 mede do 1.o golpe ao ultimo, pelo proprio alvo.) O combo ideal fica ~20-27 % mais rapido que o spam, sem ser mais rapido do que o spam antigo (2,4 s): diferenca perceptivel, nao gigantesca. **Nota de feel:** os golpes basicos individuais passam a fazer 15-30 (~24 acertos so' com N1-N4 sem critico); se soar a "cocegas" no playtest, o ajuste preferivel e' subir N1-N3 um pouco e baixar o critico do N4 (nao mexer no goblin).

## Ataques do goblin durante o spam
Spam com deslocacao: 2 botes completos / 2 acertos na Koliani em 4,9 s; spam parado: 2/2 em 4,5 s; combo ideal: 0/0 (esta' sempre em hitstun/no ar/caido). Em 12 s de spam com vida infinita (v1.1, mesma regra de escape): 5 botes/5 acertos e o escape dispara 5-6 vezes: o spam ja' nao mata sem custo.

## Algum combo domina em excesso? / power creep
- **Nao:** o melhor combo medido (o bot ideal) mede 3,60 s -- mais lento que o spam da v1.1 (2,4 s) e a ~0,75x do spam novo; Cleave/Counter nao foram medidos em TTK (dependem de guarda/PD); nenhum caminho baixa de 3 s (o teste falha abaixo de 2,5 s como sinal de power creep).
- Cleave (115 + quebra de guarda) e Counter (135 + quebra) so' subiram +15 % / +12,5 %; o Counter exige um Perfect Dodge (o roll certo contra um ataque telegrafado) e o Cleave 0,5 s de carga: o custo e' o de compromisso, nao o do dano.
- Dash Attack e Launcher ficaram a x1,3 (eram 1,15 / 0,9): +13 % e +44 %, moderado. O que ficou mais alto que a producao e' o golpe AEREO (70/80 vs 42/50): e' a recompensa de fazer Launcher -> salto -> Air, e continua limitada a 2 golpes por salto e a 3 elevacoes por juggle.

## Testes
`teste_combat_lab_balanco` (TTK e hierarquia; falha se o combo ideal for mais lento que o spam ou < 2,5 s), mais toda a bateria v1/v1.1 (clamp 0/16, PD por origem, anti-spam, combos 1-8). Suite completa: ver commit.
