# SFX Overhaul — auditoria e correções críticas

Data: 20 setembro 2026. Base: `origin/master` em `72ea2477`.

## Resultado executivo

O catálogo central `Som` tem 79 chaves e todos os 79 streams carregam. Os SFX
não estão duplicados em nós de cena: gameplay usa um autoload com pool de oito
`AudioStreamPlayer` no bus `SFX`. A dispersão está nas chamadas: há dezenas de
`Som.toca()` com volume e pitch definidos localmente em scripts de player,
inimigos, bosses, mundo e UI.

Foram corrigidos quatro defeitos objetivos: o portal tocava um ataque de boss;
mortes fatais da Koliani e de inimigos empilhavam hurt+death no mesmo frame; e
a queda/recompensa de boss arrancavam juntas. Música regional não foi alterada.

Legenda de estado: `KEEP`, `REPLACE`, `MISSING`, `VOLUME FIX`, `TIMING FIX` e
`DUPLICATION FIX`.

## FIXED NOW

| EVENT | CURRENT SFX | STATUS | PROBLEM | ACTION | RESULT |
| --- | --- | --- | --- | --- | --- |
| Portal de teleporte | antes `onda` −12 dB/pitch 1,6; agora `transicao` −10 dB/pitch 1,08 | REPLACE | `onda` é ataque de boss e dava identidade errada ao teleporte | encaminhar para o whoosh de portal já existente | uma voz `transicao.wav` por travessia |
| Player death | antes `dano` −7 dB + `morte_koliani` −6 dB no mesmo frame | DUPLICATION FIX | hurt mascarava a morte e ocupava duas vozes | tocar `dano` apenas em golpe não fatal | uma voz `morte_koliani.wav` no golpe fatal |
| Enemy death | antes `mob_*_dano` + `mob_*_morte` no mesmo frame | DUPLICATION FIX | hit e death sobrepostos em todas as famílias | voz de dano apenas quando o inimigo sobrevive | uma voz `mob_*_morte.ogg` no golpe fatal |
| Boss kill sem diálogo | antes `chefe_cai` −6 dB + `conquista` −4 dB simultâneos | TIMING FIX | dois eventos fortes começavam juntos e mascaravam a leitura queda→recompensa | `conquista` após 450 ms e a −6 dB | exatamente duas vozes, ordenadas e sem onset simultâneo |

## NEXT PASS

### Player e combate

| EVENT | CURRENT SFX | STATUS | PROBLEM | ACTION | RESULT |
| --- | --- | --- | --- | --- | --- |
| Jump / double jump | `salto`, `salto_duplo`, −9 a −11 dB | KEEP | streams curtos, onset 0–1 ms; wall-jump reutiliza `salto` | ouvir em jogo e manter salvo rejeição humana | tecnicamente ligado |
| Land | `aterrar`, tiers de volume por impacto | KEEP | routing e timing corretos; um único sample para três intensidades | avaliar variantes no passe de player | tecnicamente ligado |
| Dash / roll | `dash` −11 dB; `rolamento` −13 dB | KEEP | sem duplicação observada | ouvir contra passos e combate | tecnicamente ligado |
| Sword swing / combo | `ataque`, `ataque2`, `ataque3`, `ataque_forte` | KEEP | quatro samples distintos; cada golpe disparou uma vez | passe auditivo e alinhamento fino ao frame de impacto | combo 1→4 validado |
| Player hit on target | `acerto` com 3 variantes, −10 a −5 dB | VOLUME FIX | amplitude muda 5 dB entre normal/crítico e recebe randomização de pitch no callsite e no autoload | consolidar ganho/pitch e testar com Shadowblade | pendente |
| Player hurt | `dano` −7 dB | KEEP | agora separado da morte; cauda de 296 ms | confirmar inteligibilidade sob ataques de boss | tecnicamente ligado |
| Shield | `bloqueio`, −15 dB no player | VOLUME FIX | o mesmo stream vai de −18 a −6 dB noutros contextos | separar escudo do player de bloqueios inimigos/boss | pendente |
| Ranged / special | `lancar`, `projetil`, `gelo`, `agarrar`, `parede` | REPLACE | algumas habilidades partilham sons de mundo/boss; não há identidade completa por poder | inventário por habilidade no Prompt 2 | pendente |

### Enemies e bosses

| EVENT | CURRENT SFX | STATUS | PROBLEM | ACTION | RESULT |
| --- | --- | --- | --- | --- | --- |
| Enemy attack/hit/death | 7 famílias × `ataque`, `dano`, `morte` | DUPLICATION FIX | 19+ espécies comprimidas em sete famílias; repetição por espécie continua audível | variantes por família e cooldown onde houver cadência alta | morte fatal corrigida; restante pendente |
| Enemy projectile | `projetil` em inimigos e bosses | REPLACE | um sample cobre muitos projéteis sem material/energia próprios | separar magia, flecha/metal e energia | pendente |
| Boss common attacks | banco partilhado (`investida`, `projetil`, `invocar`, `golpe_pesado`, `esmagar`, `grito`, `onda`...) | DUPLICATION FIX | 20 bosses reutilizam poucos sons; `chefe_cai` aparece em 33 callsites explícitos, incluindo transições | auditar boss a boss e reservar cada chave ao seu significado | pendente |
| Boss phase transition | sobretudo `mudar_forma`; alguns scripts usam `chefe_cai` junto | REPLACE | queda de boss usada como quebra de fase em vários bosses | criar/atribuir transições por material e evitar falso kill | pendente |
| Boss hurt | nenhum SFX próprio no `ChefeBase`; ouve-se apenas `acerto` do player | MISSING | bosses não respondem sonoramente ao dano normal | adicionar hurt leve com cooldown, distinto do final hit | pendente |
| Boss death / final hit | `chefe_cai` seguido de `conquista` | TIMING FIX | sequência base corrigida; scripts especializados ainda têm volumes/pitches próprios | normalizar subclasses e validar os 20 bosses | base corrigida; cobertura global pendente |

### World e progressão

| EVENT | CURRENT SFX | STATUS | PROBLEM | ACTION | RESULT |
| --- | --- | --- | --- | --- | --- |
| Hazards Região I | `raiz_aviso`, `raiz_irrompe`, `plataforma_surge` | KEEP | eventos carregam e disparam; `raiz_aviso` tem pico baixo (−15,4 dBFS no ficheiro) | ouvir contra música/combate | tecnicamente ligado |
| Checkpoint | `selo` −12 dB | KEEP | uma voz por primeira ativação | manter | validado no Godot real |
| Bells | `sino_ataque` apenas no boss Sino Vivo | MISSING | sinos ambientais/mecânicos não têm camada própria | mapear câmaras `sinos` e Vyrak no passe de mundo | pendente |
| Doors / level complete | `porta` para fechadura; `transicao` −3 dB na saída | VOLUME FIX | saída está 7 dB acima do portal e `transicao` dura 1,05 s | uniformizar ganho por contexto após escuta | conclusão L1→L2 funcional |
| Mechanisms | `plataforma_surge`, `engrenagem`; restantes mecanismos variam ou estão mudos | MISSING | sem contrato sonoro por tipo | inventariar alavanca, prensa, elevador, plataforma e lâmina | pendente |
| Wind / environmental feedback | sem SFX dedicado no sistema de vento | MISSING | força importante não tem feedback sonoro contínuo | desenhar loop leve com entrada/saída e limite de vozes | pendente |
| Boss kill | sequência `chefe_cai` → `conquista` | TIMING FIX | onset simultâneo corrigido | validar subclasses | base validada |
| Chest | `apanhar` −6 dB | REPLACE | baú usa o pickup genérico | criar abertura + recompensa curta | pendente |
| Portal | `transicao` −10 dB | REPLACE | corrigido de `onda` | manter e ouvir em percurso | routing validado |
| Unlock | pickups/santuário reutilizam `apanhar`/`conquista` conforme o fluxo | MISSING | não há assinatura consistente de desbloqueio | definir evento único e curto | pendente |

### UI

| EVENT | CURRENT SFX | STATUS | PROBLEM | ACTION | RESULT |
| --- | --- | --- | --- | --- | --- |
| Select / menu movement | `ui_mover` + v2/v3, −13/−12/−9 dB conforme ecrã | VOLUME FIX | variantes evitam repetição imediata, mas ganho varia 4 dB entre menus | centralizar ganho por evento | um disparo validado |
| Confirm | `ui_confirmar`, −8 a −5 dB | VOLUME FIX | inconsistência entre menu e seletor | escolher ganho único após escuta | um disparo validado |
| Back | `ui_voltar` −8 dB | KEEP | mapping consistente | manter | stream carregado |
| Error / denied | `ui_negado` −8 dB | KEEP | mapping consistente | manter | stream carregado |
| Carousel | `carrossel` −12 dB | KEEP | sample curto, pico imediato | manter e comparar com `ui_mover` | tecnicamente ligado |

## OPTIONAL

| EVENT | CURRENT SFX | STATUS | PROBLEM | ACTION | RESULT |
| --- | --- | --- | --- | --- | --- |
| Footsteps by surface | três passos genéricos | REPLACE | madeira/grão iguais em todos os pisos | materiais por superfície depois do passe de combate | não iniciado |
| Spatial audio | todos os SFX no pool global não posicional | REPLACE | mundo e bosses não têm atenuação/posição | avaliar `AudioStreamPlayer2D` apenas para mundo | decisão futura |
| Long-event voice policy | pool round-robin de 8 vozes | DUPLICATION FIX | uma rajada pode substituir um SFX longo; não há prioridade/cooldown central | política leve por categoria, sem redesign total | decisão futura |

## Medições e arquitetura

- WAVs medidos pela ferramenta existente: zero amostras em clipping no conjunto
  auditado. OGGs não foram decodificados por essa ferramenta, portanto não há
  declaração global de clipping zero.
- Durações relevantes: `ui_mover` 55 ms, ataques 150–400 ms,
  `morte_koliani` 1,10 s, `transicao` 1,05 s, `conquista` 6,125 s.
- Em jogo real, o pico observado no bus SFX durante movimento/combo foi
  −3,9 dB, sem resource path ausente. Isto é margem técnica, não aprovação
  subjetiva do mix.
- `Som.toca()` aplica sempre pitch aleatório ±5%; vários callsites também
  randomizam pitch. Essa dupla variação deve ser consolidada no próximo passe.
- Não existe cooldown central por evento. Hazards, boss attacks e UI dependem
  exclusivamente do debounce do respetivo script.
- O pool é central e evita `AudioStreamPlayer` espalhados; a política de
  volume/timing continua espalhada. Não foi feita refatoração total neste lote.

## Validação

- Godot 4.7.2 import/editor: sem erro de script ou resource.
- Renderer real OpenGL, RTX 5070, `verificar_sfx_criticos.gd`: 79/79 streams;
  portal, checkpoint, UI, enemy death, boss sequence e player death passaram
  com as contagens acima; zero falhas.
- Renderer real OpenGL, QA jogado na Floresta Putrefacta: 23/23 streams do
  conjunto player/UI/progressão carregados; combo `ataque`→`ataque_forte`
  disparou uma vez por passo; sem pedidos sem stream; pico SFX −3,9 dB.
- Renderer real OpenGL, percurso L1→L2: golpe fatal real matou Ghorak uma vez,
  7 motes/70 essência, porta abriu, uma entrada, L2 carregou e a recompensa
  de vida não duplicou.
- Suíte geral: chegou a `OK -- todos os testes passaram`, mas o runner de
  `master` destrói a SceneTree em `run_tests.gd:3940–3983`, repete a suíte e
  emite erros. Foi interrompido após três repetições; não conta como PASS limpo.
- Avisos/leaks já presentes nos harnesses: Camera2D em physics interpolation e
  ObjectDB retido ao sair. Nenhum foi escondido ou corrigido fora do âmbito.

`HUMAN LISTEN REQUIRED` e `HUMAN PLAYTEST REQUIRED` para timbre, conforto,
leitura no caos e volume “razoável”. `DEVICE VALIDATION REQUIRED` para mobile
e Web reais. A validação técnica prova routing, contagem, carregamento e margem;
não substitui audição humana.

## Próxima ação

**SFX PROMPT 2 — COMBAT + PLAYER + ENEMY SOUND PASS.** Prioridade: consolidar
ganhos/pitch de ataque-hit-hurt-shield, variantes das famílias inimigas,
projectiles por material e boss hurt com cooldown. Depois: boss-by-boss e mundo.
