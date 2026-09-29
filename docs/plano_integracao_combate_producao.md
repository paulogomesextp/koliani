# Plano de integração do Combat Lab v1.2 em produção

Documento de planeamento. **Nada aqui foi integrado.** Baseline: Combat Lab
v1.2 (`24f5f26d`) + correção "usa a Koliani de produção" (`30975ccd`). Física
F1 e N1–N6 atuais intactos — não tocados nesta execução.

## 1. Auditoria da Koliani de produção

Onde vive hoje cada sistema, em [`scripts/koliani.gd`](../scripts/koliani.gd)
salvo indicação contrária:

| Sistema | Onde vive hoje | Classificação |
|---|---|---|
| Combo básico (golpe→golpe) | `_iniciar_ataque` / `_marcar_combo` / `_atualizar_janela_ataque` (l.2331–2436); dano em `_dano_golpe` (l.29) | REUSE |
| Hitbox de ataque | nó `HitboxAtaque` (Area2D) na cena `Koliani.tscn`, ligado/desligado em `_iniciar_ataque`/`_desativar_hitbox_ataque` | REUSE |
| Frame data (startup/ativo/recovery) | **não existe como dado** — é timing solto dentro de `_iniciar_ataque`/`_atualizar_janela_ataque`, sem tabela | EXTEND |
| Avanço dos golpes | não existe (a Koliani não avança ao bater) | LAB ONLY (`combate_lab.gd` MOVES[].avanco) |
| Dash | `Input.is_action_just_pressed("dash")`, `_dash_restante`, `_rasto_dash`, `_sfx_dash`, `_vfx9g_dash` (várias linhas 1148–1660) | REUSE |
| Roll | `Input.is_action_just_pressed("rolar")`, `Movimento.pode_rolar`, `_rolar_restante` | REUSE (mas sem janela de Perfect Dodge associada — ver §3) |
| Pogo | `_pogo_pode_iniciar`/`_iniciar_pogo`/`_tratar_pogo`/`_pogo_acertar` (l.2201–2322); já usa BAIXO+ATAQUE no ar | REUSE |
| Energia | `energia_actual`/`ganhar_energia`/`usar_especial` (l.2506–2551); hoje só alimentada por tiro/especial, não por golpes "bons" | EXTEND |
| Especial | `usar_especial`, `_lancar_projetil`, tecla `especial` | REUSE (não mexer) |
| `receber_dano` (a Koliani leva dano) | l.2971, **já tem parâmetro `origem`** desde o Combat Lab v1.1 (comentário l.2968), mas todo chamador de produção omite-o | EXTEND |
| Animações de combate | `_montar_golden_set`/`_montar_frames`/`_atualizar_anim` (l.797–2075); só tem `attack`/`lancar`/`dash`, sem Launcher/Cleave/Counter | EXTEND (dados) / **falta arte** (§6) |
| Input mobile/teclado/comando | `Input.is_action_*` no `koliani.gd` (mapa de acções do Godot); botões em [`scripts/controlos_tacteis.gd`](../scripts/controlos_tacteis.gd) e [`scripts/controlos_toque.gd`](../scripts/controlos_toque.gd) | EXTEND (ver §7) |
| Combo/Launcher/Air Combo/Cleave/Dash Attack/Perfect Dodge/Counter/clamp/anti-spam | [`scripts/lab/combate_lab.gd`](../scripts/lab/combate_lab.gd), componente `CombateLab` só criado por `ativar_combat_lab()` (l.2322); nenhum nível de produção o cria | LAB ONLY |

**Nota**: `chefe_base.gd` e `demonio_base.gd` têm o seu **próprio**
`receber_dano` — mas esse é o inimigo a levar dano da Koliani, sistema
diferente do de a Koliani levar dano deles.

## 2. Core Combat vs Balance

Proposta de duas camadas, sem sobre-engenharia (a estrutura já existe quase
toda no `combate_lab.gd`; é só separar dados de lógica):

```
scripts/combate/
  core_combat.gd      # class_name CoreCombate, extends Node
                       # a MESMA logica do CombateLab de hoje: estados de
                       # combo, Launcher, Air Combo, Cleave, Dash Attack,
                       # Perfect Dodge, Counter, clamp de avanco, guard break.
                       # Não tem números embutidos — lê-os de `BalanceCombate`.
  balance_combate.gd   # class_name BalanceCombate, extends Resource
                       # o dicionario MOVES + mult_golpe + ENERGIA_* +
                       # janelas de PD/Counter + CARGA_T + PD_JANELA, hoje
                       # espalhados como consts/vars no combate_lab.gd.
                       # Um .tres por perfil de dificuldade se algum dia
                       # precisar (hoje só um: `balance_combate_v1.tres`).
```

`CoreCombate` substitui `CombateLab` (mesma API pública:
`iniciar(koliani)`, `tentativa_de_dano(quantidade, origem)`); o
`combate_lab.gd` atual fica congelado como está — ninguém o apaga nesta
fase, só deixa de crescer. Isto evita espalhar constantes por
`koliani.gd`: o `koliani.gd` continua a expor só os "ganchos" que já tem
hoje (`_ao_acertar_corpo`, `receber_dano`, `ganhar_energia`,
`_hitstop`, `_flash_branco`, `_abanar`) e o `CoreCombate` chama-os de fora,
exactamente como o Lab já faz.

## 3. Contrato de dano — Perfect Dodge

O comentário em `koliani.gd:2968` já define o contrato: `origem` tem de ser
`"ataque"` ou `"hazard_ataque"` para poder disparar Perfect Dodge; tudo o
resto (`""`, contacto) não conta.

**Achado crítico**: fiz `grep` a todos os 22 chamadores de produção de
`corpo.receber_dano(...)` / `c.receber_dano(...)` fora do Lab — **nenhum
passa um 3.º argumento**. Ou seja, hoje **zero** ataques de produção
classificam a sua origem; todos caem no default `""` (contacto/desconhecido).
Perfect Dodge não pode disparar contra nada em produção, mesmo já ligado.

Classificação de todos os chamadores encontrados:

| Ficheiro | Chamada | Classificação hoje | Devia ser |
|---|---|---|---|
| `demonio_base.gd:1045` (`_ao_tocar`) | `corpo.receber_dano(dano_contacto, ...)` | contato | `contato` (correto — é toque de corpo, não golpe) |
| `chefe_base.gd:663` | `corpo.receber_dano(dano, ...)` | contato | `contato` (chefes-base só têm dano de corpo; não têm hitbox de ataque telegrafada) |
| `projetil_koliani.gd` | (dano em inimigos, não na Koliani) | n/a | n/a |
| `projetil_zeriko.gd:52` | `corpo.receber_dano(dano, ...)` | contato | `ataque` (é um projétil disparado por um chefe — devia contar) |
| `armadilha.gd:42` | `corpo.receber_dano(dano, dir)` | contato | `hazard_ataque` |
| `chao_quente.gd:94` | `c.receber_dano(dano, 0.0)` | contato | `hazard_ataque` |
| `gota_acida.gd:126,171,177` | `corpo/c.receber_dano(...)` | contato | `hazard_ataque` |
| `guilhotina.gd:91` | `corpo.receber_dano(...)` | contato | `hazard_ataque` |
| `pedra_queda.gd:155` | `corpo.receber_dano(...)` | contato | `hazard_ataque` |
| `pendulo_lamina.gd:165` | `corpo.receber_dano(...)` | contato | `hazard_ataque` |
| `raiz_perigo.gd:176,194` | `corpo.receber_dano(...)` | contato | `hazard_ataque` |
| `raio_tempestade.gd:96` | `c.receber_dano(...)` | contato | `hazard_ataque` |
| `serpente.gd:107` | `c.receber_dano(...)` | contato | `ataque` (é um inimigo a atacar, não um hazard fixo) |
| `sombra_atrasada.gd:127` | `c.receber_dano(...)` | contato | `ataque` |
| `teia_prende.gd:85` | `corpo.receber_dano(dano)` | contato | `hazard_ataque` |
| `zona_sem_ar.gd:121` | `_alvo.receber_dano(dano, 0.0)` | contato | `ambiente` (DoT, não deveria dar PD) |
| `ameaca_que_avanca.gd:97` | `c.receber_dano(...)` | contato | `ataque` |
| `bola_fogo.gd:80` | `corpo.receber_dano(...)` | contato | `ataque` |
| `ceifa.gd:93` | `c.receber_dano(...)` | contato | `hazard_ataque` |
| `main.gd:408,440` | `e.receber_dano(1, 1.0)` | n/a (é a Koliani a bater no inimigo `e`, não o inverso) | n/a |
| `para_raios.gd:65` | `chefe.receber_dano(...)` | n/a (dano no chefe) | n/a |

**Contagem**: **13 sistemas** de produção têm de ser tocados para o
contrato ficar honesto (adicionar o 3.º argumento na chamada): 8
armadilhas/hazards → `"hazard_ataque"`, 4 inimigos/projéteis com ataque real
→ `"ataque"`, 1 DoT ambiental → `"ambiente"` (novo valor, hoje não
distinguido do resto). Nenhuma migração feita nesta execução.

## 4. Enemy Combat Contract v1 (só para inimigos novos/reconstruídos)

Não se aplica a nenhum inimigo legacy em massa. Proposta de contrato — um
conjunto de `@export` + métodos que um inimigo de combate **novo** declara
(via uma nova classe base opcional, ex. `InimigoDeCombate extends
DemonioBase`, sem alterar `DemonioBase` em si):

```gdscript
@export_enum("leve", "medio", "pesado") var peso := "leve"
@export var pode_ser_lancado := true       # false para pesados (ex.: Golem)
@export var resistencia_stagger := 1.0     # multiplicador de hitstun recebido
@export var tem_guarda := false            # bloqueia golpes normais; Cleave quebra
func telegraph_ataque() -> void: pass      # aviso visual antes do hit
func ativar_hitbox_ataque() -> void: pass  # liga a hitbox real (frames ativos)
func desativar_hitbox_ataque() -> void: pass
func ao_levar_launcher() -> void: pass     # leve: vai pelos ares; pesado: nao aplicavel
func ao_levar_cleave() -> void: pass       # quebra guarda se tem_guarda
func ao_levar_counter() -> void: pass      # sempre critico
func comportamento_aereo(_dt: float) -> void: pass  # só relevante se pode_ser_lancado
```

Hoje **nada disto existe** no lado inimigo: `DemonioBase`/`chefe_base.gd`
não têm peso, guarda, nem hitbox de ataque telegrafada — só `_ao_tocar`
(dano de contacto) e um `receber_dano` próprio para quando SÃO atingidos.
É tudo por construir; classificação: LAB ONLY / a criar.

## 5. Migração-piloto (só planeamento, não tocar)

- **Goblin da Região I**: hoje é uma instância de `DemonioBase` com
  `rig`/espécie configurados na cena do nível (não há `scripts/goblin.gd`
  dedicado). Alvo: `peso = "leve"`, `pode_ser_lancado = true`. Testa combo,
  Launcher, Air Combo, anti-spam — o Lab já tem `LabGoblin.tscn` +
  `lab_inimigo.gd` como referência de comportamento a copiar (não herdar
  directamente; o piloto de produção deve ser uma classe própria que
  implementa o Enemy Combat Contract v1, não uma cena do Lab reaproveitada
  às cegas).
- **Golem do N6**: igualmente uma instância de `DemonioBase` (voador/pesado
  configurado no nível). Alvo: `peso = "pesado"`, `pode_ser_lancado = false`,
  `tem_guarda = true`. Testa Cleave (quebra de guarda), Perfect Dodge,
  Counter.

Nenhum dos dois é alterado nesta execução.

## 6. Animações em falta

Com base no que `_montar_golden_set`/`_montar_frames` já montam
(`idle`, `run_final`, `jump`, `fall`, `dash`, `attack`, `lancar`) e no que
o Combat Lab pede:

| Animação | Estado hoje | Notas |
|---|---|---|
| Launcher | **falta** | pode reusar pose de `attack` com hitbox redimensionada — GAMEPLAY READY / ART DEBT |
| Air Attack 1/2 | **falta** dedicada (hoje reusa `attack`/`lancar` no ar) | GAMEPLAY READY / ART DEBT |
| Dash Attack | **falta** | pode reusar `dash` + flash de golpe (`_flash_golpe`) — GAMEPLAY READY / ART DEBT |
| Cleave charge (segurar) | **falta** | precisa de um estado visível de "carregar" para o jogador sentir o input a segurar — sem isto o Cleave é confuso; **não** é ART DEBT seguro, recomendo arte mínima antes de expor ao jogador |
| Cleave hit | **falta** | idem |
| Counter | **falta** | pode reusar `attack` forte + VFX de golpe existente — GAMEPLAY READY / ART DEBT |
| Perfect Dodge feedback | **falta** (o Lab já tem `_pd_flash: Label` como placeholder de debug, não é arte final) | precisa de um flash/partícula mínima, reusa `_abanar`/`_flash_branco` como base |
| Guard break (inimigo) | **falta** (não existe guarda em inimigo nenhum ainda) | depende do Enemy Combat Contract (§4), que ainda não existe |

Sem gerar nem copiar arte nesta execução, como pedido.

## 7. Mobile — inputs e riscos

| Mecânica nova | Input previsto | Conflito? |
|---|---|---|
| Launcher | CIMA + ATAQUE | **RISCO**: `mirar_cima`/`mirar_baixo` no toque vêm do eixo Y do joystick esquerdo, e hoje servem para **mirar o tiro** (`controlos_tacteis.gd:367`, comentário explícito "a mira lê o mirar_cima/mirar_baixo"). Empurrar o joystick para cima enquanto se carrega no botão ATACAR já é um gesto existente (mirar tiro para cima); reutilizá-lo para Launcher pode disparar Launcher quando o jogador só queria mirar um tiro para cima, ou vice-versa. Precisa de decisão de UX — ver §10. |
| Air Attack | ATAQUE no ar | Sem conflito — já é o botão único de ataque, sem direcção extra |
| Pogo | BAIXO + ATAQUE (ar) | **Já é produção** (`_pogo_pode_iniciar`, l.2202, usa `mirar_baixo` + `atacar`). Mesmo risco de mira-vs-ação que o Launcher, mas já convive em produção há tempo — não é risco novo |
| Cleave | segurar ATAQUE | Sem conflito directo, mas o botão `atacar` do toque não distingue hoje "prima" de "segura" com feedback visual (ver §6, Cleave charge) — sem esse feedback, segurar por engano é fácil no toque |
| Dash Attack | DASH + ATAQUE | Sem conflito de mapeamento (botões distintos, `hud.controls.dash` + `hud.controls.attack`); risco é só de timing/janela, não de input |
| Counter | ATAQUE após Perfect Dodge | Sem conflito — é o mesmo botão de sempre, dentro de uma janela temporal |

**Resumo do risco real**: só o eixo cima/baixo do joystick (Launcher e,
em menor grau, o Pogo já existente) está sobreposto com a mira de tiro.
Isto é uma decisão de design, não um bug — decidir em §10.

## 8. Ordem de integração proposta (commits pequenos e reversíveis)

1. `CoreCombate`/`BalanceCombate` como infra-estrutura, **sem activar**
   (cópia 1:1 da lógica do `combate_lab.gd` de hoje, só separando dados de
   lógica — nenhum nível ganha o componente ainda).
2. Launcher + Air Combo (dados + lógica, ainda só testável via Combat Lab).
3. Cleave.
4. Dash Attack.
5. Perfect Dodge + Counter.
6. Contrato de dano: adicionar `origem` aos 13 chamadores do §3, um grupo
   de cada vez (hazards primeiro, depois inimigos/projécteis) — reversível
   por ficheiro, sem tocar em `koliani.gd`.
7. Goblin piloto (Enemy Combat Contract v1 aplicado só a ele).
8. Golem piloto (peso pesado + guarda).
9. Playtest humano (Paulo/GM) antes de qualquer propagação.
10. Só depois, propagação gradual a outros inimigos/níveis — região a
    região, nunca em massa.

Cada passo dos 1–8 é um commit isolado e reversível com `git revert`, sem
dependências cruzadas de gameplay activado (o Lab continua a ser o único
sítio onde o jogador sente as mecânicas até ao passo 9).

## 9. Riscos de regressão

- **Perfect Dodge silencioso**: se o contrato de dano (§3, passo 6) for
  aplicado parcialmente (ex.: só hazards, não inimigos), o jogador pode
  achar que "o Perfect Dodge não funciona contra bichos" — pior do que não
  o ter, porque parece bug.
- **Ambiguidade de mira vs. Launcher/Pogo no toque** (§7): pode fazer
  jogadores de telemóvel disparar Launcher sem querer ao tentar mirar um
  tiro para cima. Já existe hoje com o Pogo e ninguém reportou — mas o
  Launcher é mais "caro" (lança o inimigo, pode tirá-lo de uma arena
  apertada) do que mirar um tiro, por isso o custo de um falso positivo é
  maior.
- **Cleave sem feedback de carga** (§6): sem animação de "a carregar",
  segurar por engano em combate apertado é frustração pura, não é skill
  issue do jogador.
- **Enemy Combat Contract tocando em `DemonioBase`**: mesmo com uma classe
  derivada nova, qualquer alteração ao `_ao_tocar`/`receber_dano` da base
  arrisca todos os ~30 níveis com demónios comuns. O piloto deve herdar,
  nunca modificar o pai.
- **Energia dupla-fonte**: hoje a Energia só vem de tiro/especial
  (`ganhar_energia` chamado de poucos sítios). Ligar Perfect
  Dodge/Cleave/Counter/Launcher/Dash Attack a `ganhar_energia` muda a
  economia de Energia em produção (afecta quando o jogador pode pagar o
  Especial) — isto precisa de ser medido, não assumido neutro.

## 10. Pontos que exigem decisão do Game Master

1. **Launcher no toque**: manter CIMA+ATAQUE mesmo sobrepondo com a mira de
   tiro, ou dar-lhe um gesto próprio (ex.: duplo-toque no botão de ataque,
   ou um botão dedicado como os de dash/especial)?
2. **Cleave — arte antes ou depois da lógica?**: o documento recomenda
   **arte mínima antes** de expor ao jogador (§6), ao contrário do resto
   ("GAMEPLAY READY / ART DEBT" é aceitável). Confirmar se este é o único
   caso a bloquear por arte.
3. **Ordem dos pilotos**: Goblin (Região I) antes do Golem (N6) como
   proposto, ou o Golem primeiro por ser mais isolado (só aparece no N6)?
4. **`origem = "ambiente"`** (novo valor para DoTs como `zona_sem_ar.gd`):
   confirmar que isto não deve nunca dar Perfect Dodge, mesmo que uma
   variante futura de DoT seja "esquivável".
5. **Economia de Energia**: aceitar que ligar as mecânicas novas a
   `ganhar_energia` muda quando o jogador pode pagar o Especial em
   produção, e que isso só se mede depois do piloto (passo 9)?

---

`PRODUCTION COMBAT MODIFIED: NO`
`INTEGRATION PLAN READY: YES`
`DAMAGE CONTRACT MAPPED: YES`
`ENEMY CONTRACT READY: YES`
`MOBILE INPUT RISKS FOUND: YES`
`READY FOR CONTROLLED INTEGRATION: YES`
