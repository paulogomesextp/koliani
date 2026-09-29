# Auditoria de reestruturação — níveis 1–20 (25 set 2026)

Só leitura: nenhuma cena, script ou asset foi alterado nem commitado.

**Método e limites.** Inspeção ESTÁTICA das 20 cenas de `data/level_manifest.json`
(instâncias por tipo, `bioma`, `fundo_pack`, `perfil_altitude`, `corredor`), do gerador
(`gerador_corredor.gd`: `MECANICA_DO_NIVEL`, `ASSIN_NIVEL`, `PERFIL`), dos nomes i18n e da
documentação. **Nada foi jogado** — "layout", "duração" e "ritmo" são inferidos. Como
`corredor = true` é o defeito, N1–N7, N9 e N11–N20 têm uma **jornada procedural** prependida
em runtime que não está nas cenas; o que ela faz vem do gerador, não de contagem de nós.

**Autoridade usada** (por ordem): pranchas APPROVED/LOCKED de `docs/art_direction/regions/`
(`level_mechanics*.png`, `layout_usage.png`, `concept_environment*.png`) →
`KOLIANI_REGION_CANON.md` + `REGION03_VISUAL_GAMEPLAY_CONTRACT.md` → assets finais →
implementação. Legenda: MATCH / PARTIAL / MISSING / LEGACY / CONTRADICTS.

## Decisões do Game Master (25 set 2026) — conflitos FECHADOS

1. **Região I — boss canónico = CORAÇÃO PUTREFACTO.** O "Guardião Verde" deixa de ser autoridade para o boss da R1.
2. **Região I — N1–N4 NÃO são boss levels** (N1 introdução · N2 desenvolvimento/test · N3 combinação · N4 desafio · N5 exame/boss).
   Os guardiões atuais (Ghorak, Morvanna, Rainha Aracnídea, Entrevane) só podem ficar como inimigos/elites normais, nunca como
   boss obrigatório nem a substituir a função pedagógica do nível. Hoje o manifesto marca-os `guardian` → **CONTRADICTS a decisão**.
3. **Regiões III e IV — prevalecem pranchas/boards APPROVED e packs/contratos LOCKED** sobre texto antigo, salvo decisão explícita posterior.
   R3 e R4 seguem as pranchas.

Efeito nas classificações da R1: N5 sobe a **LOW** (boss agora correto); N1–N4 mantêm-se em LOW/MEDIUM/MEDIUM/MEDIUM mas
passam a ter como desvio adicional "guardião obrigatório no fim do nível". A R1 continua **PARTIAL LEVEL REBUILD**; nada
foi alterado no gameplay da R1 nem da R4 nesta execução.

**Ponto em aberto (menor):** "paredes móveis" e "queda controlada" (lista do briefing) não têm atribuição nas pranchas da R3
(ver `docs/rebuild_region_03_plan.md` §2).

---

# REGIÃO I — Floresta (N1–N5)

Sem prancha de gameplay nesta cópia. Canon = texto: travessia gradual, plataformas naturais,
perigos ambientais, combate base. Referência interna: `docs/mecanicas_por_nivel.md` (não é canon aprovado).

| Nível | Função | Hoje (estático) | Mecânicas × canon | Desvio |
|---|---|---|---|---|
| **1** Corrupted Forest | TEACH | 17 plataformas, 5 raízes que irrompem, 3 plataformas rítmicas, 2 inimigos, água venenosa, guardião Ghorak; `Region1HybridVisualTarget`; largura 3800 | raízes telegrafadas MATCH; plataformas móveis PARTIAL (só rítmicas); picos MISSING (raízes fazem de perigo); frágeis MISSING | LOW |
| **2** Swamp of Whispers | TEST | 17 plat., 2 flutuantes, 2 raízes, água mortal + ilhas; Morvanna | plataformas móveis MATCH; frágeis MISSING | LOW |
| **3** Black Widow's Nest | COMBINE | 26 plat., 7 teias, 1 rítmica, 4 inimigos; Rainha Aracnídea | teia (movimento retirado) sem equivalente no canon PARTIAL; frágeis MISSING | MEDIUM |
| **4** The Weeping Tree | CHALLENGE | 27 plat., gotas de ácido, alavanca + 2 portas trancadas, 3 inimigos; Entrevane; sem móveis | plataformas móveis MISSING; ácido/alavanca = mecânicas do catálogo interno, não do canon | MEDIUM |
| **5** Heart of the Forest | BOSS | 16 plat., 5 rítmicas, zona de gravidade, boss Coração Putrefacto | boss MATCH (decisão GM); combinação das mecânicas PARTIAL | LOW |

Arte: `bioma floresta`, packs de fundo `luar/pantano/floresta`, golden set opt-in em L1–L5 — **PARTIAL**
(sem prancha para medir; a arte regional foi aprovada por outro canal, não verificável aqui).
Progressão Teach→Boss: função existe mas 4 guardiões antes do "boss" quebra o modelo de 5 degraus.

**REGIÃO I — ESTADO:** arte correta 5/5 (não verificável) · mecânicas corretas 2/5 · progressão correta 3/5 ·
legacy: mecânicas do catálogo interno (teia, ácido, alavanca), nomes de nível antigos · ausentes: elementos
frágeis, picos · assets não usados: n/d (sem pranchas) · **REBUILD: PARTIAL LEVEL REBUILD** (conflitos resolvidos; falta frágeis/picos e tirar o carácter de boss aos guardiões N1–N4).

---

# REGIÃO II — Desfiladeiro dos Ventos (N6–N10)

Prancha `level_mechanics_and_layout.png`: N6 rajadas horizontais + plataformas móveis · N7 correntes
ascendentes · N8 ilhas suspensas, plataformas que aparecem/desaparecem, planar · N9 vento variável +
móveis + inimigos, caminhos com vento inverso · N10 Torre dos Céus, todas as mecânicas.

| Nível | Função | Hoje | Mecânicas | Arte | Desvio |
|---|---|---|---|---|---|
| **6** Open Cliffs | TEACH | 15 plat., 3 correntes, 2 `WindZone`, 2 fogos, 2 inimigos, guardião Carcereiro; jornada com assinatura legada `alavanca` | vento MATCH (2 zonas); móveis PARTIAL (3 de corrente); fogo/alavanca **LEGACY** (Prisão) | fundo/arquitetura remodelados (ponte); vinhas/gelo no terreno MISSING | MEDIUM |
| **7** Rising Gorge | TEST | 15 plat., 3 `WindZone`, 3 fogos, serra, 1 corrente; assinatura legada `fogo` | correntes ascendentes PARTIAL; **serra e fogo LEGACY** | torre partida, silhueta própria | MEDIUM |
| **8** Suspended Ruins | COMBINE | `corredor=false`, largura 5800, 14 plat., 3 `WindZone`, 1 `ZonaPlanar`; **GAMEPLAY LOCKED** | planar MATCH; **plataformas que aparecem/desaparecem MISSING**; assinatura legada `guilhotinas` | ilhas + queda de água | HIGH |
| **9** Turning Gale | COMBINE | 10 plat. + 6 espectrais, 3 `WindZone`, 2 inimigos; assinatura `arena` | vento variável PARTIAL; **plataformas espectrais LEGACY** (Ala dos Mortos); móveis+vento MISSING | altar em ruínas, ruínas atmosféricas | MEDIUM |
| **10** Eternal Winds | BOSS | `corredor=false`, 2400, 17 plat., 4 `WindZone`, Guardião dos Céus (contrato visual cumprido); `prensa` | "todas as mecânicas anteriores" PARTIAL; sequência final até à arena OK | Torre dos Céus + lua | MEDIUM |

Ausentes da prancha (nenhuma cena os usa): interruptores de pressão/distância, sino ativável, elevador de
correntes, pêndulo retrátil, plataforma elevatória, tornados, laser de cristais, queda de pedras, lâminas giratórias,
plataformas que aparecem/desaparecem/oscilantes; terreno com vinhas/gelo/cristais.

**REGIÃO II — ESTADO:** arte correta 4/5 (N8 medido o melhor; N6/N7/N9/N10 ainda sem terreno de vinhas) ·
mecânicas corretas 2/5 (N8 planar, N10) · progressão Teach→Boss 3/5 · legacy: assinaturas `alavanca/fogo/guilhotinas/arena/prensa`
no gerador, fogos/serra, plataformas espectrais · **REBUILD: PARTIAL LEVEL REBUILD** (mecânicas; a arte já está a meio caminho).

---

# REGIÃO III — Torre dos Ecos (N11–N15)

Contrato LOCKED em `REGION03_VISUAL_GAMEPLAY_CONTRACT.md` + 7 pranchas. Os nomes do jogo (i18n) já são os canónicos.
`MECANICA_DO_NIVEL` já dá a cada nível a mecânica do contrato (sinos, elevador, engrenagens, vento, espectral).

| Nível | Função | Hoje | Mecânicas × contrato | Desvio |
|---|---|---|---|---|
| **11** Entrance of Echoes | TEACH | 16 plat., 2 `SinoTorre`, 1 inimigo (Acólito do Eco), boss Sino Vivo | sinos MATCH; oscilantes/correntes/ecos visuais PARTIAL | LOW |
| **12** Vertical Galleries | TEST | 16 plat., 2 `CorrenteAr`; estreia `elevador` | elevador MATCH; escadas quebradas, plataformas que desaparecem, vitrais que projetam eco MISSING | MEDIUM |
| **13** Ancient Mechanisms | COMBINE | 16 plat., 3 `RaioTempestade` + 2 `ParaRaios` (legado "Torre da Tempestade"); estreia `engrenagens`, assinatura `raio` | engrenagens MATCH; **raios = LEGACY mantido por decisão**; mecanismo central de 3 sinos, alavancas múltiplas MISSING | MEDIUM |
| **14** The Belfry | CHALLENGE | 16 plat., **`ZonaGravidade` (legado Observatório)**; estreia `vento` | **gravidade CONTRADICTS** (Campanário = sinos em movimento, plataformas circulares, updraft); sinos gigantes MISSING | MEDIUM |
| **15** Summit of Echoes | BOSS | 13 plat., zero atores mecânicos na cena (depende da jornada); Vyrak canónico | ecos de memória/plataformas ilusórias via `espectral` PARTIAL | LOW |

Arte: `bioma torres`, `fundo_pack torre_ecos`, bestiário canónico presente em `assets/sprites/pixel/enemies`
(acólito, sino flutuante, gárgula vitral, autómato, monge, arqueiro…) — **MATCH**. Ficheiros das cenas mantêm nomes antigos
(`Torre_dos_Ventos`, `Observatorio_Lunar`…) — cosmético.

**REGIÃO III — ESTADO:** arte correta 5/5 · mecânicas corretas 2/5 · progressão 4/5 · legacy: raios N13, gravidade N14,
nomes de ficheiro · ausentes: sinos em movimento/gigantes, plataformas circulares, vitrais interativos, mecanismo de 3 sinos,
pontes reconfiguráveis · **REBUILD: PARTIAL LEVEL REBUILD** (N12–N14; N11 e N15 são retoques).

---

# REGIÃO IV — Fornalha (N16–N20)

Pranchas LOCKED: N16 Entrada da Fornalha (pisos aquecidos telegrafados) · N17 Fundição (ameaças verticais de lava,
elevadores de corrente, plataformas instáveis) · N18 Câmara da Lava (lava que sobe, plataformas em ascensão) ·
N19 Sala das Pressões (jatos de fogo, pistões, válvulas, plataformas sincronizadas) · N20 Núcleo da Fornalha (combinação
+ Guardião da Fornalha).

**O que existe não é a Fornalha.** É a Região IV *legada* — Catacumbas do Abismo:

| Nível | Hoje | vs canon | Desvio |
|---|---|---|---|
| **16** Graveyard of Kings | `bioma catacumbas`, fundo `caverna`, 12 plat., 2 `TumuloElevador`, necromante/esqueleto, boss Rei Ossário | CONTRADICTS (tema, arte, inimigos, boss); elevador funciona como ideia | CRITICAL |
| **17** Gallery of Bones | catacumbas/`gruta`, 14 plat., 1 `ParedeFragil`, Colosso Ósseo | CONTRADICTS; chão que desaba ≈ "plataformas instáveis" só como analogia | CRITICAL |
| **18** Crypt of a Thousand Candles | catacumbas, 7 plat. + 6 `PlataformaLuz`, 6 velas, Freira Negra | CONTRADICTS (velas/escuridão ≠ calor/lava) | CRITICAL |
| **19** Temple of the Serpent | catacumbas, 13 plat., 2 `ParedeMovel`, Naga Zeraph | CONTRADICTS; sem jatos/pistões/válvulas | CRITICAL |
| **20** The Abyss | catacumbas, 11 plat., `LuzSeguidora`, boss Olho do Abismo | CONTRADICTS; **sem Guardião da Fornalha** | CRITICAL |

Mecânicas da prancha inexistentes: pisos que aquecem, lava rasa/crescente, jatos de fogo telegrafados, pistões,
válvulas de pressão, plataformas sincronizadas/instáveis por calor, gotas de magma. Também **não existem**: tileset/deco/fundo
de fornalha (`assets/sprites/pixel/terreno|deco` só têm floresta, prisao, torres, catacumbas, cidade, castelo, desfiladeiro),
inimigos da prancha (Trabalhador Corrompido, Gosma de Lava, Arqueiro da Fornalha, Torreta de Fogo, Válvula Viva…) e
`ChefeGuardiaoDaFornalha`. Nota: `Fornalha_dos_Pecadores.tscn` é o **N7 da Região II** (legado), não a Região IV.

**REGIÃO IV — ESTADO:** arte correta 0/5 · mecânicas corretas 0/5 (túmulo-elevador aproxima N17) · progressão 0/5 · legacy 5/5 ·
ausentes: todas as de calor/lava/pressão · assets aprovados não usados: as 7 pranchas de `region_04/` inteiras ·
**REBUILD: FULL LEVEL REBUILD.**

---

## Cinco maiores desvios
1. **R4 inteira é Catacumbas legada**, sem uma única peça de Fornalha (tema, arte, inimigos, mecânicas, boss).
2. **Falta o Guardião da Fornalha** — nenhuma cena de boss, nenhuma arte animada.
3. **R2 N8 sem plataformas que aparecem/desaparecem** (foco da prancha) e N6–N10 arrastam assinaturas legadas da Prisão (alavanca, fogo, serra, guilhotinas, prensa, espectrais).
4. **R3 N14 usa gravidade** (Observatório legado) em vez de sinos gigantes/plataformas circulares; N12/N13 sem escadas quebradas, mecanismo de 3 sinos nem pontes reconfiguráveis.
5. **R1 sem frágeis/picos e com guardiões-boss obrigatórios em N1–N4** (o boss do N5 ficou decidido: Coração Putrefacto).

## Ordem de reconstrução recomendada (sem implementar)
0. Decisões do Game Master: fechadas (ver topo).
1. **R3** (menor esforço, contrato LOCKED, arte já MATCH): trocar N14 e completar N12/N13.
2. **R2**: plataformas que aparecem/desaparecem (N8 é LOCKED — só acrescentar fora do caminho), retirar assinaturas legadas do gerador, terreno com vinhas.
3. **R4** por ordem N16→N20: primeiro o kit (tileset, deco, fundo, extração de inimigos das pranchas), depois as mecânicas de calor/lava/pressão como camadas novas, boss no fim.
4. **R1**: acrescentar frágeis/picos e desclassificar os guardiões N1–N4 como bosses obrigatórios.

CANON FOUND: YES · APPROVED ART FOUND: YES (R2–R4; R1 não) · APPROVED MECHANICS FOUND: YES (R2–R4 em pranchas; R1 só texto)
CURRENT GAMEPLAY MATCHES APPROVED DESIGN: PARTIAL · IMPLEMENTATION CHANGES MADE: NO
