# Visão canónica — Koliani 1.0

## Identidade

Koliani é um platformer de campanha por níveis, com história e progresso
guardado. Não é roguelite. O alvo é mobile-first em landscape, mantendo Web,
com leitura clara em ecrã pequeno e objetivo de 60 fps.

## Cânone

- A campanha tem **100 níveis**.
- A estrutura tem **20 regiões × 5 níveis**.
- **Koliani tem 16 anos**.
- **Elara** é o nome canónico da mãe de Koliani.
- **Shadowblade** é a arma principal.
- **Hardcore está fora do scope 1.0**.
- A **Região I (níveis 1–5)** é a primeira Vertical Slice.

Referências antigas a Aurora ou à inclusão de Hardcore descrevem estado legado
e não alteram estas decisões. A correção futura dessas divergências deve ser
planeada e migrada; não é trabalho implícito desta documentação.

## Estratégia 1.0

A Região I deve provar o padrão completo antes de este ser multiplicado pela
campanha: apresentação, percurso, combate, chefe, interface, áudio, progressão,
save e comportamento nas plataformas alvo. “Vertical Slice” não significa que
os restantes 95 níveis estejam concluídos ou validados.

Qualquer expansão deve preservar IDs e saves, proteger conteúdo autoral contra
geradores destrutivos e separar validação automática de playtest humano e de
validação em dispositivo real.

## Baseline confirmado

Após as Executions 1A, 1A.1 e 1B: 44 testes, zero falhas, localização PASS,
nível 5 PASS, nível 12 desktop/OpenGL PASS e `SalaLabirinto` determinística
PASS. O nível 12 em Safari/PWA num iPhone permanece
**DEVICE VALIDATION REQUIRED**.

Ver estado operacional em [execution_dashboard.md](execution_dashboard.md) e
decisões formais em [decisoes.md](decisoes.md).
