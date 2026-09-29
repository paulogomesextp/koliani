# Regiao I (Floresta Corrompida) -- VERTICAL SLICE / QUALITY BAR

Estado (26 set 2026, sem push): **aprovada pelo GM como vertical slice.** N1, Ghorak, N2, N3 (baseline com Pogo intencional),
N4, N5 e o Coracao Putrefacto aprovados "por agora". Passa a ser a barra de qualidade para todas as regioes seguintes.

## Decisoes fechadas
- **Salto duplo = recompensa do Coracao Putrefacto.** NAO e' necessario para concluir a Regiao I; abre so' depois da vitoria
  (`HABILIDADE_DO_CHEFE[4]` em `scripts/nivel_com_chefe.gd`, contrato 9H.17 C) e faz parte do kit a partir da Regiao II.
- **Encerramento da Regiao I** (novo): `BOSS DERROTADO` -> bau -> `SALTO DUPLO DESBLOQUEADO` -> cartao
  `FLORESTA CORROMPIDA CONCLUIDA` -> Continuar -> porta abre. `scripts/cartao_regiao.gd` (UI ja' existente: painel + botao, chaves
  `region.*` nos 6 i18n), ligado por `REGIAO_CONCLUIDA` em `nivel_com_chefe.gd` (`_ao_bau_recolhido`). Sem cinematica nem arte nova.
  Para outra regiao: acrescentar `{indice_do_exame: "region.N.complete"}` + a chave nos 6 JSON.

## Regras/padroes que funcionaram (aplicar a todas as regioes)
1. **Nivel authored**: `corredor = false`, zero jornada procedural como percurso principal. Cena gerada uma vez por script e depois editada.
2. **Progressao por nivel**: Teach -> Develop -> Combine -> Challenge -> Boss. Cada nivel ensina UMA coisa, combina-a com o que ja' se sabe
   e so' entao aperta. O N5 e' exame: combina tudo o que a regiao ensinou, sem skill nova a exigir.
3. **Checkpoints intencionais** (`checkpoints_autorais`, `estreia_x_autoral`): antes de cada prova, um perto da arena do boss
   (morrer no boss nao repete o exame).
4. **Poucos inimigos, cada um com funcao** (ex.: N5 tem 4). Elites existem para forcar uma resposta (reposicionar, gerir Energia).
5. **Hazards regionais** que telegrafam (raizes, espinhos, agua) e se combinam com a mecanica ensinada.
6. **Bosses com vulnerability loop**: PROTEGIDO (casca ~5 %) -> MECANICA telegrafada -> EXPOSTO (punish) -> RECOVER; fase 2 encadeia o
   mesmo vocabulario (nao infla numeros). TTK do bot perfeito 30-40 s, humano 45-75 s.
7. **Testes por nivel** (`teste_nN_autoral`) com bots/pilotos medem alcance, TTK e "so' bater na casca nao ganha".
8. Docs por nivel: `docs/nivel_autoral_n1..n5.md`.

## Divida visual registada (nao resolver agora)
Inimigos legacy; raizes/props procedurais; animacao de mantle; animacao/VFX proprios do Pogo; arte definitiva do Especial;
placeholders do boss N5 (broto, onda, tira de aviso); polish audiovisual; arte do cartao de fim de regiao.

## Balanceamento -- SPECIAL BOSS DPS -- REVIEW DURING GLOBAL COMBAT BALANCE
O bot com Especial vence o Coracao em ~19,7 s contra ~35,5 s do bot perfeito so' com ataques normais nas janelas.
**Registado, NAO alterado** (dano/custo/absorcao ficam como estao ate' ao balanceamento global de combate).
