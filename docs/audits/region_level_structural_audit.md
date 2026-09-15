# Auditoria estrutural dos níveis 1–100

Data: 2026-09-15  
Base auditada: `67b68b249513ee2801846f77b9ef5ed73309dff9` (`codex/region-canon-integration`)

## Escopo e método

Esta auditoria compara a estrutura técnica atual da campanha com o cânone em
`docs/art_direction/`. Foram lidos o manifesto, as listas de campanha, o
seletor, as cenas textuais, os scripts partilhados, o catálogo de encontros e
os caminhos de recursos. Não houve execução do jogo, screenshots, inspeção
artística, alteração de cenas nem validação de percurso.

As classificações são estruturais:

- **PRESENT**: cena authored com estrutura concreta e dependências existentes.
- **PARTIAL**: estrutura concreta, mas incompleta de forma explícita.
- **PLACEHOLDER**: cena genérica/procedural que existe e é endereçável, mas não
  constitui implementação regional específica.
- **MISSING**: sem implementação identificável.
- **UNKNOWN**: evidência estática insuficiente.

`PRESENT` não certifica jogabilidade, alcance, diversão ou ausência de erros.
Esses pontos exigem execução e, quando aplicável, `HUMAN PLAYTEST REQUIRED`.

## 1. Arquitetura atual dos níveis

- `data/level_manifest.json` declara 20 regiões e 100 níveis, liga cada
  `level_XXX` a uma cena runtime e regista origem, ownership, boss e gerador.
- `scripts/estado_jogo.gd` mantém `NIVEIS`, uma lista fixa de 100 cenas. A lista
  coincide integralmente e na mesma ordem com o manifesto: 100 caminhos
  únicos, zero omissões, extras ou duplicados.
- `scripts/ids_progressao.gd` consome o manifesto para IDs persistentes;
  `scripts/level_session.gd` gere sessão/checkpoints; `scripts/main.gd` carrega
  `EstadoJogo.caminho_nivel_atual()`.
- `scripts/nivel_com_chefe.gd` é o controlador comum: porta, boss/guardião,
  checkpoints, iluminação, recompensa e gerador de jornada.
- Níveis 1–30: `origin=authored`, `ownership=authored`, cenas com 27–61 nós e
  dependências específicas. Níveis 1–4 terminam em guardião e o 5 em boss;
  6–30 ainda contêm um boss específico em cada cena.
- Níveis 31–100: `origin=generated`, `ownership=unknown`,
  `auto_regenerate=false`; cenas mínimas de 9–11 nós apoiadas em
  `scripts/gerador_corredor.gd`, atmosfera partilhada e
  `scenes/actors/ChefeGenerico.tscn`. O próprio gerador descreve estas cenas
  como jornadas procedurais temáticas, não salas desenhadas à mão.
- Todas as 100 cenas e todas as cenas de boss referidas no manifesto existem.

## 2. Inventário 1–100

| Level | Região | Cena/path | Estado |
|---:|---:|---|---|
| 001 | I | `res://scenes/levels/Floresta_Putrefata.tscn` | PRESENT |
| 002 | I | `res://scenes/levels/Pantano_dos_Sussurros.tscn` | PRESENT |
| 003 | I | `res://scenes/levels/Ninho_da_Viuva_Negra.tscn` | PRESENT |
| 004 | I | `res://scenes/levels/A_Arvore_que_Chora.tscn` | PRESENT |
| 005 | I | `res://scenes/levels/Coracao_da_Floresta.tscn` | PRESENT |
| 006 | II | `res://scenes/levels/Prisao_dos_Condenados.tscn` | PRESENT |
| 007 | II | `res://scenes/levels/Fornalha_dos_Pecadores.tscn` | PRESENT |
| 008 | II | `res://scenes/levels/Corredor_das_Execucoes.tscn` | PRESENT |
| 009 | II | `res://scenes/levels/Ala_dos_Mortos.tscn` | PRESENT |
| 010 | II | `res://scenes/levels/A_Cela_Zero.tscn` | PRESENT |
| 011 | III | `res://scenes/levels/Torre_dos_Sinos.tscn` | PRESENT |
| 012 | III | `res://scenes/levels/Torre_dos_Ventos.tscn` | PRESENT |
| 013 | III | `res://scenes/levels/Torre_da_Tempestade.tscn` | PRESENT |
| 014 | III | `res://scenes/levels/Observatorio_Lunar.tscn` | PRESENT |
| 015 | III | `res://scenes/levels/O_Pico_Esquecido.tscn` | PRESENT |
| 016 | IV | `res://scenes/levels/Cemiterio_dos_Reis.tscn` | PRESENT |
| 017 | IV | `res://scenes/levels/Galeria_dos_Ossos.tscn` | PRESENT |
| 018 | IV | `res://scenes/levels/Cripta_das_Mil_Velas.tscn` | PRESENT |
| 019 | IV | `res://scenes/levels/Templo_da_Serpente.tscn` | PRESENT |
| 020 | IV | `res://scenes/levels/O_Abismo.tscn` | PRESENT |
| 021 | V | `res://scenes/levels/Vila_dos_Sem_Rosto.tscn` | PRESENT |
| 022 | V | `res://scenes/levels/Mercado_da_Carne.tscn` | PRESENT |
| 023 | V | `res://scenes/levels/Trem_dos_Mortos.tscn` | PRESENT |
| 024 | V | `res://scenes/levels/Catedral_da_Corrupcao.tscn` | PRESENT |
| 025 | V | `res://scenes/levels/Praca_do_Eclipse.tscn` | PRESENT |
| 026 | VI | `res://scenes/levels/Portoes_de_Zeriko.tscn` | PRESENT |
| 027 | VI | `res://scenes/levels/Salao_dos_Espelhos.tscn` | PRESENT |
| 028 | VI | `res://scenes/levels/Banquete_dos_Imortais.tscn` | PRESENT |
| 029 | VI | `res://scenes/levels/Torre_do_Coracao_Negro.tscn` | PRESENT |
| 030 | VI | `res://scenes/levels/O_Trono_de_Zeriko.tscn` | PRESENT |
| 031 | VII | `res://scenes/levels/Estrada_das_Cinzas.tscn` | PLACEHOLDER |
| 032 | VII | `res://scenes/levels/Rio_de_Magma.tscn` | PLACEHOLDER |
| 033 | VII | `res://scenes/levels/A_Forja_dos_Demonios.tscn` | PLACEHOLDER |
| 034 | VII | `res://scenes/levels/Vulcao_do_Rei_Morto.tscn` | PLACEHOLDER |
| 035 | VII | `res://scenes/levels/O_Ceu_em_Chamas.tscn` | PLACEHOLDER |
| 036 | VIII | `res://scenes/levels/Porto_dos_Afogados.tscn` | PLACEHOLDER |
| 037 | VIII | `res://scenes/levels/Cidade_Submersa.tscn` | PLACEHOLDER |
| 038 | VIII | `res://scenes/levels/Palacio_das_Sereias_Mortas.tscn` | PLACEHOLDER |
| 039 | VIII | `res://scenes/levels/Ossario_das_Baleias.tscn` | PLACEHOLDER |
| 040 | VIII | `res://scenes/levels/Abismo_Oceanico.tscn` | PLACEHOLDER |
| 041 | IX | `res://scenes/levels/Floresta_Congelada.tscn` | PLACEHOLDER |
| 042 | IX | `res://scenes/levels/Montanha_dos_Ventos.tscn` | PLACEHOLDER |
| 043 | IX | `res://scenes/levels/Cavernas_Cristalinas.tscn` | PLACEHOLDER |
| 044 | IX | `res://scenes/levels/Castelo_Congelado.tscn` | PLACEHOLDER |
| 045 | IX | `res://scenes/levels/Coracao_do_Inverno.tscn` | PLACEHOLDER |
| 046 | X | `res://scenes/levels/Mar_de_Areia.tscn` | PLACEHOLDER |
| 047 | X | `res://scenes/levels/Templo_Sem_Nome.tscn` | PLACEHOLDER |
| 048 | X | `res://scenes/levels/Vale_dos_Escorpioes.tscn` | PLACEHOLDER |
| 049 | X | `res://scenes/levels/Cidade_Enterrada.tscn` | PLACEHOLDER |
| 050 | X | `res://scenes/levels/Piramide_Negra.tscn` | PLACEHOLDER |
| 051 | XI | `res://scenes/levels/Jardim_das_Rosas_Negras.tscn` | PLACEHOLDER |
| 052 | XI | `res://scenes/levels/Labirinto_Verde.tscn` | PLACEHOLDER |
| 053 | XI | `res://scenes/levels/Jardim_das_Almas.tscn` | PLACEHOLDER |
| 054 | XI | `res://scenes/levels/Estufa_Maldita.tscn` | PLACEHOLDER |
| 055 | XI | `res://scenes/levels/Arvore_do_Rei.tscn` | PLACEHOLDER |
| 056 | XII | `res://scenes/levels/Distrito_das_Engrenagens.tscn` | PLACEHOLDER |
| 057 | XII | `res://scenes/levels/Linha_13.tscn` | PLACEHOLDER |
| 058 | XII | `res://scenes/levels/Fabrica_dos_Homunculos.tscn` | PLACEHOLDER |
| 059 | XII | `res://scenes/levels/Torre_Electrica.tscn` | PLACEHOLDER |
| 060 | XII | `res://scenes/levels/Coracao_da_Maquina.tscn` | PLACEHOLDER |
| 061 | XIII | `res://scenes/levels/Ilhas_Flutuantes.tscn` | PLACEHOLDER |
| 062 | XIII | `res://scenes/levels/Templo_do_Trovao.tscn` | PLACEHOLDER |
| 063 | XIII | `res://scenes/levels/Cidade_dos_Anjos_Mortos.tscn` | PLACEHOLDER |
| 064 | XIII | `res://scenes/levels/Lua_Quebrada.tscn` | PLACEHOLDER |
| 065 | XIII | `res://scenes/levels/O_Fim_do_Ceu.tscn` | PLACEHOLDER |
| 066 | XIV | `res://scenes/levels/Vila_dos_Sonhos.tscn` | PLACEHOLDER |
| 067 | XIV | `res://scenes/levels/Mundo_Invertido.tscn` | PLACEHOLDER |
| 068 | XIV | `res://scenes/levels/Quarto_das_Criancas_Mortas.tscn` | PLACEHOLDER |
| 069 | XIV | `res://scenes/levels/Pesadelo.tscn` | PLACEHOLDER |
| 070 | XIV | `res://scenes/levels/A_Mente.tscn` | PLACEHOLDER |
| 071 | XV | `res://scenes/levels/Avenida_dos_Mortos.tscn` | PLACEHOLDER |
| 072 | XV | `res://scenes/levels/Cemiterio_Infinito.tscn` | PLACEHOLDER |
| 073 | XV | `res://scenes/levels/Catedral_Fantasma.tscn` | PLACEHOLDER |
| 074 | XV | `res://scenes/levels/Palacio_dos_Reis_Mortos.tscn` | PLACEHOLDER |
| 075 | XV | `res://scenes/levels/Trono_da_Morte.tscn` | PLACEHOLDER |
| 076 | XVI | `res://scenes/levels/Margem_do_Sangue.tscn` | PLACEHOLDER |
| 077 | XVI | `res://scenes/levels/Serpentes_do_Mar.tscn` | PLACEHOLDER |
| 078 | XVI | `res://scenes/levels/Navio_da_Condenacao.tscn` | PLACEHOLDER |
| 079 | XVI | `res://scenes/levels/Fortaleza_Kraken.tscn` | PLACEHOLDER |
| 080 | XVI | `res://scenes/levels/Coracao_Vermelho.tscn` | PLACEHOLDER |
| 081 | XVII | `res://scenes/levels/Portao_Infernal.tscn` | PLACEHOLDER |
| 082 | XVII | `res://scenes/levels/Cidade_dos_Demonios.tscn` | PLACEHOLDER |
| 083 | XVII | `res://scenes/levels/Rio_das_Almas.tscn` | PLACEHOLDER |
| 084 | XVII | `res://scenes/levels/Palacio_de_Sangue.tscn` | PLACEHOLDER |
| 085 | XVII | `res://scenes/levels/Trono_Infernal.tscn` | PLACEHOLDER |
| 086 | XVIII | `res://scenes/levels/Primeiro_Vazio.tscn` | PLACEHOLDER |
| 087 | XVIII | `res://scenes/levels/Segundo_Vazio.tscn` | PLACEHOLDER |
| 088 | XVIII | `res://scenes/levels/Labirinto_Impossivel.tscn` | PLACEHOLDER |
| 089 | XVIII | `res://scenes/levels/A_Coisa_Atras_do_Mundo.tscn` | PLACEHOLDER |
| 090 | XVIII | `res://scenes/levels/Centro_do_Vazio.tscn` | PLACEHOLDER |
| 091 | XIX | `res://scenes/levels/Campo_de_Batalha.tscn` | PLACEHOLDER |
| 092 | XIX | `res://scenes/levels/Ceu_em_Guerra.tscn` | PLACEHOLDER |
| 093 | XIX | `res://scenes/levels/Cerco_ao_Castelo.tscn` | PLACEHOLDER |
| 094 | XIX | `res://scenes/levels/Torre_da_Corrupcao.tscn` | PLACEHOLDER |
| 095 | XIX | `res://scenes/levels/Os_Cem_Guerreiros.tscn` | PLACEHOLDER |
| 096 | XX | `res://scenes/levels/O_Reino_Antes_da_Corrupcao.tscn` | PLACEHOLDER |
| 097 | XX | `res://scenes/levels/O_Primeiro_Castelo.tscn` | PLACEHOLDER |
| 098 | XX | `res://scenes/levels/O_Coracao_de_Zeriko.tscn` | PLACEHOLDER |
| 099 | XX | `res://scenes/levels/O_Fim_de_Tudo.tscn` | PLACEHOLDER |
| 100 | XX | `res://scenes/levels/O_Ultimo_Salto.tscn` | PLACEHOLDER |

Contagem: **PRESENT 30; PARTIAL 0; PLACEHOLDER 70; MISSING 0; UNKNOWN 0**.

## 3. Resumo por região

| Região | Níveis | Completude estrutural | Estrutura, assets e mecânicas atuais |
|---|---:|---|---|
| I — Floresta Sagrada | 1–5 | 5 PRESENT | Cenas authored; kit `region_01_forest`, floresta/pântano, raízes, teias, gravidade, plataformas e guardiões; boss final atual Coração Putrefacto. |
| II — Desfiladeiro dos Ventos | 6–10 | 5 PRESENT | Estrutura antiga de prisão/fornalha; casca de masmorra, fogo, guilhotina, serras, correntes e plataformas frágeis/espectrais. Não implementa a identidade canónica do desfiladeiro. |
| III — Torre dos Ecos | 11–15 | 5 PRESENT | Torres authored; correntes de ar, sinos, raios, para-raios, gravidade; Vyrak no nível 15. |
| IV — Fornalha | 16–20 | 5 PRESENT | Estrutura antiga de catacumbas/abismo; velas, túmulos, paredes móveis/frágeis e plataformas de luz. Não corresponde integralmente à Fornalha canónica. |
| V — Cidades Flutuantes | 21–25 | 5 PRESENT | Estrutura antiga de vila/cidade; correntes, plataformas ritmadas, elevadores e vitrais. Identidade canónica aérea não está estabelecida. |
| VI — Deserto das Ilusões | 26–30 | 5 PRESENT | Estrutura antiga de castelo de Zeriko; espelhos, fogo e plataformas especiais. Não corresponde ao deserto canónico. |
| VII — Jardins Envenenados | 31–35 | 5 PLACEHOLDER | Jornada procedural com temas emprestados de floresta/catacumbas/castelo e boss genérico; scripts especiais Vulkar/elemental/oceânico. Tema atual é “Terras Queimadas”, divergente do cânone. |
| VIII — Catacumbas da Fome | 36–40 | 5 PLACEHOLDER | Jornada procedural, assets base e boss genérico/oceânico; tema atual é “Mar dos Mortos”. |
| IX — Abadia Afogada | 41–45 | 5 PLACEHOLDER | Jornada procedural, boss genérico/glacial; tema atual é gelo, divergente da abadia afogada. |
| X — Biblioteca Proibida | 46–50 | 5 PLACEHOLDER | Jornada procedural, boss genérico/deserto; não há estrutura específica de biblioteca, runas ou Arconte. |
| XI — Costa Afundada | 51–55 | 5 PLACEHOLDER | Jornada procedural e boss genérico com `chefe_lore.gd`; tema atual é jardins. |
| XII — Terras Envenenadas | 56–60 | 5 PLACEHOLDER | Jornada procedural e boss genérico/lore; tema atual é máquinas. |
| XIII — Torre Invertida | 61–65 | 5 PLACEHOLDER | Jornada procedural e boss genérico/lore; tema atual é Céu Partido. |
| XIV — Planícies Celestiais | 66–70 | 5 PLACEHOLDER | Jornada procedural e boss genérico/lore; tema atual é Reino dos Sonhos. |
| XV — Laboratório Sombrio | 71–75 | 5 PLACEHOLDER | Jornada procedural e boss genérico/lore; tema atual é Cidade dos Mortos. |
| XVI — Cânion Sangrento | 76–80 | 5 PLACEHOLDER | Jornada procedural e boss genérico/lore; tema atual é Mar Vermelho. |
| XVII — Jardim Onírico | 81–85 | 5 PLACEHOLDER | Jornada procedural e boss genérico/lore; tema atual é Inferno. |
| XVIII — Cidade Caída | 86–90 | 5 PLACEHOLDER | Jornada procedural e boss genérico/lore; tema atual é Vazio. |
| XIX — Portal Dimensional | 91–95 | 5 PLACEHOLDER | Jornada procedural e boss genérico/lore; tema atual é Guerra. |
| XX — Trono de Zeriko | 96–100 | 5 PLACEHOLDER | Jornada procedural final e boss genérico/lore; catálogo termina em “Zeriko, Apenas um Homem”, mas não existe cena de boss especializada. |

Dependências partilhadas dominantes: `Koliani.tscn`, `Plataforma.tscn`,
`Porta.tscn`, `AguaVenenosa.tscn`, `Atmosfera.tscn`, `checkpoint.gd`,
`nivel_com_chefe.gd`; nos níveis 31–100 juntam-se
`gerador_corredor.gd`, `ChefeGenerico.tscn` e, por região, scripts de boss
elemental/oceânico/glacial/deserto/lore.

## 4. Boss mapping

O quadro usa o encontro do quinto nível de cada região. “PRESENT” significa
que a identidade canónica está reconhecível no catálogo/implementação;
“DIFFERENT” significa que existe encontro, mas com outra identidade.

| Região | Boss canónico | Implementação atual | Estado |
|---|---|---|---|
| I | Guardião Verde | `ChefeCoracaoPutrefacto.tscn` | DIFFERENT |
| II | Guardião dos Céus | `ChefePrimeiroPrisioneiro.tscn` | DIFFERENT |
| III | Vyrak | `ChefeVyrak.tscn` | PRESENT |
| IV | Guardião da Fornalha | `ChefeOlhoDoAbismo.tscn` | DIFFERENT |
| V | Oráculo do Vento | `ChefeNoivaDoEclipse.tscn` | DIFFERENT |
| VI | Mirage Eterna | `ChefeZerikoFinal.tscn` | DIFFERENT |
| VII | Rainha Espinhosa | Chefe genérico “Estrela Caída” | DIFFERENT |
| VIII | Devorador da Cripta | Chefe genérico “Mãe do Abismo” | DIFFERENT |
| IX | Abade Naufragado | Chefe genérico “Ymiria” | DIFFERENT |
| X | Arconte do Conhecimento | Chefe genérico “Deus Esquecido” | DIFFERENT |
| XI | Senhor das Marés | Chefe genérico “Rei Botânico” | DIFFERENT |
| XII | Arauto da Pestilência | Chefe genérico “Máquina-Rei” | DIFFERENT |
| XIII | Soberano Invertido | Chefe genérico “Astrónomo” | DIFFERENT |
| XIV | Oráculo Estelar | Chefe genérico “Outra Koliani” | DIFFERENT |
| XV | Arquialquimista Morvak | Chefe genérico “A Própria Morte” | DIFFERENT |
| XVI | Malgor, o Carniceiro da Ravina | Chefe genérico “O Mar” | DIFFERENT |
| XVII | Rainha do Sonho | Chefe genérico “Rei dos Demónios” | DIFFERENT |
| XVIII | Colosso da Ruína | Chefe genérico “A Entidade” | DIFFERENT |
| XIX | Arquiteto do Limiar | Chefe genérico “O Campeão” | DIFFERENT |
| XX | Zeriko | Chefe genérico catalogado como “Zeriko, Apenas um Homem” | PRESENT (genérico) |

Resumo: **2 identidades canónicas presentes, 18 diferentes, 0 missing,
0 unknown**. A Sentinela do Vazio não foi identificada como implementação
regional da Região X; o boss atual do nível 50 também não é o Arconte.

## 5. Level selector e loading

- O fluxo começa em `Intro.tscn`, passa pelas UIs e usa
  `scripts/seletor_niveis.gd`/`SeletorNiveis.tscn`.
- `EstadoJogo.NIVEIS` define os 100 caminhos; `caminho_nivel_atual()` limita o
  índice ao intervalo e `main.gd` muda para essa cena.
- O seletor apresenta 20 regiões × 5 níveis. Em modo normal, o nível 1 está
  aberto e os restantes seguem `nivel_desbloqueado()`/conclusão anterior. Em
  modo dev, `configurar(indice, false)` permite selecionar qualquer nível.
- Todos os 100 níveis são endereçáveis. Não foram encontrados caminhos
  omitidos, duplicados ou extras entre manifesto e `NIVEIS`.
- Há hardcodes paralelos de 100 posições em `EstadoJogo.NIVEIS`,
  `CatalogoCampanha` e retratos do seletor, além do manifesto. Isto cria risco
  de drift quando nomes, bosses ou ordem mudam.

## 6. Missing, partial e placeholder

- **MISSING:** nenhum ficheiro de cena ou boss referenciado está ausente.
- **PARTIAL:** nenhum nível foi classificado assim; a evidência separa cenas
  authored das cenas genéricas.
- **PLACEHOLDER:** níveis 31–100. Existem e têm caminho runtime, mas partilham
  esqueleto mínimo, jornada procedural, assets temáticos emprestados,
  ownership desconhecido e boss genérico. Isto satisfaz literalmente o
  critério “estrutura genérica”.
- **Divergência canónica:** as regiões II e IV–VI são authored mas conservam
  temas/bosses anteriores; VII–XIX usam a campanha gerada antiga. Estado
  estrutural PRESENT não significa alinhamento com o cânone atual.

## 7. Riscos técnicos

1. Três fontes paralelas de mapeamento (manifesto, `NIVEIS`, catálogo/UI)
   podem divergir silenciosamente.
2. Os 70 níveis gerados estão marcados `ownership=unknown` e
   `auto_regenerate=false`; o risco de sobrescrita/autoridade de fonte deve ser
   resolvido antes de qualquer regeneração.
3. As cenas runtime 31–100 ainda contêm `ChefeGenerico` em todos os níveis,
   enquanto scripts/comentários recentes descrevem quatro guardiões e um boss
   regional. O runtime e o contrato narrativo não estão alinhados.
4. O cânone regional novo diverge do catálogo antigo em 18 bosses e de vários
   temas de região; uma migração oportunista quebraria nomes, saves, UI e
   progressão.
5. A existência estática das cenas não prova importação limpa, percurso,
   checkpoints, boss completion nem acessibilidade móvel. Uma futura validação
   deve usar as provas da skill de níveis e marcar playtest/dispositivo quando
   aplicável.

## 8. Ordem recomendada de futura implementação

1. **Região I (níveis 1–5):** manter como baseline da Vertical Slice e validar
   apenas regressões; já é authored e gameplay-approved no cânone.
2. **Região II (níveis 6–10):** primeira implementação recomendada. É a região
   seguinte na campanha, já possui cinco cenas authored, mas tema, mecânicas e
   boss divergem do cânone; oferece uma migração limitada antes do bloco
   procedural.
3. **Regiões III–VI:** reconciliar sequencialmente as cenas authored com o
   cânone, preservando Vyrak na III.
4. **Regiões VII–XX:** substituir placeholders região a região, começando por
   contratos de source/ownership e pelo boss canónico do quinto nível. Não
   regenerar em massa antes de resolver a autoridade dos níveis 31–100.

Recomendação imediata: **Região II — Desfiladeiro dos Ventos**, porque é a
primeira lacuna canónica após a Vertical Slice e já tem cinco estruturas
authored que permitem uma migração controlada.
