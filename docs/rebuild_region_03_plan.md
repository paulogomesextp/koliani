# Plano de rebuild — Região III, Torre dos Ecos (N11–N15) — 25 set 2026

**Estado: PLANO. Nada foi implementado.** Foco: N12, N13, N14. N11 e N15 ficam intactos (sem violação concreta).
Autoridade: decisões do GM → `REGION03_VISUAL_GAMEPLAY_CONTRACT.md` + 7 pranchas LOCKED
(`level_mechanics.png`, `layout_usage.png`, …) → assets aprovados → implementação (só baseline técnica).

## 1. Método e medição de base

Contagem em runtime (níveis carregados no Godot, `tools`-style bench em scratchpad, nada gravado no repo) das instâncias
por tipo em `idx 10..14`. A jornada é determinística por nível, por isso os números são reproduzíveis.

| Ator | N11 | N12 | N13 | N14 | N15 |
|---|---:|---:|---:|---:|---:|
| `SinoTorre` | 3 | **0** | 1 | **0** | 1 |
| `TumuloElevador` (arte de túmulo) | 3 | 3 | 3 | 3 | 0 |
| `PlataformaRoda` | 0 | 2 | 2 | 2 | 0 |
| `PlataformaEspectral` | 0 | 0 | 5 | 0 | 20 |
| `PlataformaFlutuante` (oscilante) | 3 | 3 | 4 | 4 | 5 |
| `PlataformaQuebra` | 0 | 0 | 0 | 1 | 0 |
| `CorrenteAr` (vento) | 0 | 2 | 0 | 1 | 0 |
| `PenduloLamina` | 2 | 0 | 5 | 0 | 10 |
| `Serra` | 10 | 3 | 0 | 15 | 17 |
| `Fogo` | 5 | 12 | 10 | 10 | 9 |
| `Alavanca` / `PortaTrancada` | 0 | 1 / 1 | 0 | 0 | 0 |
| `Vitral` | 0 | 0 | 0 | 0 | 0 |
| **`RaioTempestade` / `ParaRaios`** | 0 | 0 | **17 / 2** | 0 | 0 |
| **`ZonaGravidade`** | 0 | 0 | 0 | **1** | 0 |
| Guardião | Sino Vivo | Aerion | Voltaris | Sacerdotisa Lunar | Vyrak |

## 2. Distribuição APROVADA das mecânicas (extraída do contrato/pranchas)

| Nível | Mecânicas principais | Únicos | Hazards |
|---|---|---|---|
| **N11 TEACH** | sinos básicos (ativar) · plataformas oscilantes · correntes móveis · ecos visuais (baixa intensidade) | sino de entrada · plataformas em vaivém · passarelas externas | espinhos simples · queda vertical · lâminas de sino rotativas **lentas** |
| **N12 TEST** | plataformas verticais (elevadores) · escadas quebradas · sinos de sincronização · **ecos que revelam plataformas** | elevador de coluna (com corrente) · plataformas que desaparecem · vitrais interativos (projetam eco) | queda em poços · plataformas falsas · lâminas verticais **rápidas**; fluxo C = secção de vento e **queda controlada** |
| **N13 COMBINE** | rodas de engrenagem · sinos com padrão · alavancas múltiplas · plataformas rotativas · pontes reconfiguráveis | mecanismo central (3 sinos) · pontes móveis · engrenagens giratórias · contrapesos | engrenagens mortais · piso que colapsa · correntes com peso · lâminas em pêndulo |
| **N14 CHALLENGE** | sinos em sequência · plataformas grandes (oscilação) · correntes controláveis · **vento vertical (updraft)** · plataformas temporizadas | sinos gigantes (em movimento) · plataformas circulares em rotação · correntes que mudam direção · secções ao ar livre com vento | sinos em queda · vento que empurra · lâminas em cruz |
| **N15 BOSS** | combinação de sinos · plataformas dinâmicas · **ecos de memória (plataformas ilusórias)** · vento intenso · elementos destrutíveis | plataforma final (fases) · sinos celestiais · fragmentos de eco · estruturas em colapso | feixes de luz · plataformas instáveis · queda com vento · destroços |

**Do briefing sem suporte nas pranchas da R3 (NÃO se acrescenta):** *paredes móveis* (só existem "pontes móveis/reconfiguráveis" no N13; o
ator `ParedeMovel` é da R4 legada) e *queda controlada* como mecânica autónoma (é só o fluxo C do N12: vento + queda).

## 3. Decisão pendente antes do N13 (1 palavra do GM)

`ASSIN_NIVEL[12] = "raio"` e o comentário no gerador dizem que o raio "FICA por decisão do briefing" (20 set). As pranchas do N13 **não têm
raios**. Pela regra de hoje (boards LOCKED prevalecem sobre decisão anterior), o plano **remove** os raios; se o GM reafirmar a decisão antiga, o
passo "remover raios" sai do N13 e nada mais muda (é um passo isolado).

## 4. N11 — Entrada dos Ecos (TEACH) — **INTACTO**

- **Manter:** 3 `SinoTorre`, 3 oscilantes, espinhos, checkpoints, `PedraQueda`/pêndulos/serras (todos no vocabulário §5), Sino Vivo, Acólito do Eco.
- **Remover / Adicionar:** nada obrigatório. Opcional P3 (só se barato): forçar 1 câmara `correntes` (correntes móveis, listada e ausente).
- **Verificar (sem alterar):** `Fogo` ×5 — se for chama laranja contradiz a paleta LOCKED ("chamas azuis"); `TumuloElevador` ×3 com arte de túmulo (ver §8).
- **Risco:** LOW · **PASS:** baseline de geometria N11 idêntica; suite verde.

## 5. N12 — Galerias Verticais (TEST) — MEDIUM

- **Manter:** 3 elevadores, 2 `CorrenteAr` (secção de vento), 3 oscilantes, `AguaVenenosa` como poço, Aerion, Gárgula Vitral, `Alavanca`+`PortaTrancada` (inofensivos).
- **Remover:** `Fogo` ×12 (hazard fora do contrato N12).
- **Adicionar (tudo com sistemas existentes, salvo a câmara nova):**
  1. **Sinos de sincronização** — ≥2 `SinoTorre` no mesmo grupo `sino_alterna` (badalada alterna plataformas); hoje 0.
  2. **Ecos que revelam plataformas / vitrais interativos** — câmara `vitral` (já na pool) forçada: `Vitral` parte → plataformas `vitral_luz` ficam sólidas; hoje 0.
  3. **Plataformas que desaparecem / falsas** — câmara `quebra` (`PlataformaQuebra`) forçada; hoje 0.
  4. **Escadas quebradas** — câmara NOVA `_f_escadas` (só `_plat` em degraus com lacunas; sem ator novo).
  5. **Lâminas verticais rápidas** — `Guilhotina` (existe) em cadência alta.
- **Layout:** fluxo do contrato A base · B ascensão por plataformas · C vento + queda controlada · D chegada; N12 é `v:+1`, banda `a:1.22` (já certo).
- **Assets:** props/arquitetura R3 já extraídos (32 props); vitrais existentes; `Vitral.tscn`, `SinoTorre.tscn`, `PlataformaQuebra.tscn`, `Guilhotina.tscn`.
- **Sistemas:** existe tudo exceto `_f_escadas` e a lógica "forçar câmaras por nível" (ver §7).
- **Risco:** MEDIUM · **PASS:** ≥2 sinos, ≥1 vitral+plataformas reveladas, ≥1 câmara de quebra, ≥1 escadaria, 0 `Fogo`, 2 `CorrenteAr` mantidas, alcance dos 100 níveis OK, geometria dos outros 99 níveis idêntica, bot sem softlock.

## 6. N13 — Mecanismos Antigos (COMBINE) — MEDIUM

- **Manter:** 2 `PlataformaRoda` (engrenagens), `PenduloLamina` ×5, `SinoTorre` ×1, Voltaris (não se mexe no boss), pontes por `sino_alterna`.
- **Remover:** `RaioTempestade` ×17 e `ParaRaios` ×2 (também as instâncias autoradas em `Torre_da_Tempestade.tscn`), `ASSIN_NIVEL[12]`; `Fogo` ×10 (fora do contrato) — **sujeito a §3**.
- **Adicionar:**
  1. **Mecanismo central de 3 sinos** (elemento chave): controlador NOVO `mecanismo_sinos.gd` que espera 3 `SinoTorre` na ordem/padrão certo e abre a progressão; hoje há só 1 sino.
  2. **Sinos com padrão** (mesmo controlador, padrão fixo e telegrafado).
  3. **Alavancas múltiplas** ≥2 (`Alavanca` existe; falta ligá-las a pontes: adaptação pequena para além de `PortaTrancada`).
  4. **Pontes móveis/reconfiguráveis** — grupos `sino_alterna` + alavanca.
  5. **Engrenagens giratórias / plataformas rotativas** ≥4 (`_f_engrenagens` já existe; subir a quantidade) + **engrenagens mortais** (`Serra`), **piso que colapsa** (`PlataformaQuebra`), **correntes com peso** (`PlataformaCorrente` modo pêndulo).
  6. **Contrapesos** — decoração (extração do atlas).
- **Sistemas:** existem `PlataformaRoda`, `PenduloLamina`, `PlataformaQuebra`, `PlataformaCorrente`, `SinoTorre`, `Alavanca`; **novo:** `mecanismo_sinos.gd`, ligação alavanca→ponte.
- **Risco:** MEDIUM (controlador novo + anti-softlock nas pontes) · **PASS:** 0 raios; ≥4 rodas; ≥3 sinos ligados ao mecanismo e a porta/elemento chave só abre com o padrão; ≥2 alavancas com efeito; pêndulos e quebra presentes; alcance OK; sem softlock (bot).

## 7. N14 — Campanário (CHALLENGE) — MEDIUM

- **Manter:** `CorrenteAr` ×1 (updraft), 2 `PlataformaRoda` (circulares), oscilantes ×4, `PlataformaQuebra` (temporizadas), `Serra` (candidata a "lâminas em cruz", ver abaixo), Monge das Correntes.
- **Remover (LEGACY / CONTRADICTS):** `ZonaGravidade` em `Observatorio_Lunar.tscn`; qualquer resíduo `gravidade` (a pool R3 já não a tem); `Fogo` ×10.
- **Adicionar:**
  1. **Sinos em sequência** — reutiliza `mecanismo_sinos.gd` (do N13) com ≥3 sinos.
  2. **Sinos gigantes (em movimento)** — sino grande em vaivém/pêndulo (composição de `PlataformaCorrente` pêndulo + arte de sino grande do atlas); é o "elemento chave".
  3. **Correntes controláveis / que mudam direção** — `PlataformaCorrente` modo horizontal com inversão por alavanca (adaptação pequena).
  4. **Secções ao ar livre com vento intenso** — mais `CorrenteAr` (updraft + empurrão), ≥2 secções.
  5. **Sinos em queda** — variante de `PedraQueda` com arte de sino; **lâminas em cruz** — `Serra`/`PlataformaRoda` com 4 braços (avaliar antes de criar ator).
- **Risco:** MEDIUM–HIGH (vários sistemas; depende do N13) · **PASS:** 0 gravidade; ≥3 sinos em sequência funcionais; ≥1 sino gigante móvel; ≥2 secções de vento; ≥1 plataforma circular; hazards do contrato presentes; alcance OK; sem softlock.

## 8. N15 — O Topo dos Ecos (BOSS) — **INTACTO**

Manter: 20 `PlataformaEspectral` (ecos de memória), pêndulos, Vyrak (2 fases, A Voz dos Ecos), sinos. Sem violação concreta. Só **validar**:
sinos celestiais, fragmentos de eco, estruturas em colapso (sem alterar); `Fogo` ×9 sujeito à mesma verificação de cor.

## 9. Assets a reutilizar
Props/arquitetura R3 (32 props + arcos/vitrais/colunas/sinos grandes) · bestiário R3 completo (`assets/sprites/pixel/enemies/*`) · rig de Vyrak ·
`fundo_pack torre_ecos` · atlas LOCKED `asset_atlas.png` (fonte para contrapesos, sino gigante, elevador de coluna) — **extração do atlas, nunca desenho por código**.
Lacuna de arte: `TumuloElevador` tem arte de túmulo (Catacumbas) em 4 níveis; o contrato pede "elevador de coluna (com corrente)". Extrair do atlas; se a peça não estiver no atlas → marcar `APPROVED ART ASSET MISSING`.

## 10. Ficheiros que seriam alterados
- `scripts/gerador_corredor.gd` — `MECANICA_DO_NIVEL` (N12–N14), pool/pesos da R3, câmaras forçadas por nível, `_f_escadas`, `ASSIN_NIVEL` (remover `12`), `DESBLOQUEIO_REGIAO`, tabelas `ESP_*` se a distribuição de inimigos não bater com o LOCKED, remoção de `Fogo` na R3.
- `scenes/levels/Torre_dos_Ventos.tscn`, `Torre_da_Tempestade.tscn`, `Observatorio_Lunar.tscn` — retirar `Fogo`/`RaioTempestade`/`ParaRaios`/`ZonaGravidade` autorados.
- **novos:** `scripts/mecanismo_sinos.gd` (+ `.uid`), extensão pequena de `scripts/alavanca.gd` (ponte/direção) e `scripts/plataforma_corrente.gd` (inversão), variante de `scripts/pedra_queda.gd` (sino em queda).
- `tests/` — novo `test_region03_mecanicas.gd` + registo em `tests/run_tests.gd`.
- `tools/extrair_props_regiao03.py` (ou equivalente) + PNGs em `assets/sprites/pixel/deco/torres/` e `.../arquitetura/` — só extração do atlas aprovado.
- `docs/retomar_aqui.md`, `docs/plano_atual.md`, este plano (estado).
**N11 e N15: nenhum ficheiro.** Nenhum boss, i18n nem save.

## 11. Ordem de implementação
**N12 → N13 → N14.** Dependência objetiva: o N13 cria `mecanismo_sinos.gd` e a ligação alavanca→ponte, que o N14 reutiliza (sinos em sequência, correntes controláveis). O N12 só usa sistemas existentes (+ `_f_escadas`), por isso vai primeiro e dá a base de "forçar câmaras por nível". Após cada nível: baseline de geometria dos 100 níveis (só os da R3 podem mudar), `verifica_alcance_todos`, bot `tools/correr_bot_r3.sh`, suite e capturas em janela real.

## 12. Riscos
1. **Decisão do raio (§3)** — conflito entre briefing antigo e as pranchas.
2. **Bosses/guardiões legados** N12 Aerion, N13 Voltaris, N14 Sacerdotisa Lunar: vêm do "Torre dos Ventos/Tempestade/Observatório"; o contrato §8.2 já os reclassificou guardiões, mas as identidades não batem com os nomes canónicos. **Não tocados** (fora de âmbito).
3. **RNG do gerador:** câmaras forçadas/`_f_escadas` gastam `_rng`; têm de ficar atrás de `_regiao == 2` para não deslocar a geometria dos outros 95 níveis (precedente da R3).
4. **Softlocks** nas pontes por sino/alavanca e no mecanismo de 3 sinos (regra global LOCKED: softlocks = 0).
5. **Distribuição de inimigos** não verificada: cada cena autora 1 espécie; a mistura em runtime vem de `ESP_ASSINATURA/ESP_REGIAO` — comparar com a tabela LOCKED (N12: Gárgula Vitral/Autómato/Monge; N13: Autómato/Construto Vitral/Espírito; N14: Monge/Sino Flutuante/Corvo).
6. **`Fogo`/`Serra` em volume** nos cinco níveis (5–17 por nível) contra hazards do contrato; cor da chama por confirmar.
7. **Escala:** as jornadas têm 16–20 mil px, acima da escala "1–3 min" que o contrato §7.1 fixa como decisão conservadora — não é âmbito, mas afeta o ritmo.
8. Ausência de `paredes móveis` nas pranchas (ver §2).
