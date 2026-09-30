# Featured — carrossel de skins (1 outubro 2026)

O Hero do Featured alterna a cada cinco segundos entre Shadowblade, Abadia Afogada, Celestial, Anjo e Demónio. Desvanece arte/texto durante 0,3 s, muda o conteúdo e reaparece durante 0,3 s. Nome, descrição, raridade, estado e botão Ver referem-se à skin anunciada. Não muda automaticamente o item selecionado no painel de compra.

Escolher um cartão cancela a transição, apresenta esse item e reinicia os cinco segundos. Ver seleciona a skin anunciada e foca o detalhe correspondente. Sair do Featured pára o carrossel; fechar a loja liberta Timer/Tween. O temporizador é filho da loja, segue o seu modo de pausa e não atua em menus fechados. Futuras skins épicas/lendárias entram pelo catálogo quando tiverem destaque e campo splash válido; placeholders sem arte e raridades inferiores ficam fora.

Quatro splashes novos, 1536×1024, criados com imagegen integrada a partir dos sprites existentes e guardados como fontes primárias em:

- `assets/sprites/koliani_skins/abadia_afogada/apresentacao/splash_premium.png`
- `assets/sprites/koliani_skins/celestial/apresentacao/splash_premium.png`
- `assets/sprites/koliani_skins/anjo/apresentacao/splash_premium.png`
- `assets/sprites/koliani_skins/demonio/apresentacao/splash_premium.png`

Prompt exato e crédito de cada arte em `docs/featured_splashes_prompts.md`; Shadowblade reutiliza o splash da passagem anterior. Nenhum sprite do corpo, preço, raridade, regra de compra, save ou gameplay foi alterado nesta passagem.

QA real: `tools/qa_carrossel_loja.gd` provou os cinco segundos, alpha intermediário do fade, ciclo de cinco artes, coerência do Hero, seleção de compra preservada, Ver, seleção manual durante fade, tabs e fecho durante fade. `tests/qa_shop_layout.tscn` passou sem falhas. Ambos têm 110 ObjectDB ao encerrar, sem ERROR nos logs finais. Três saves reais intactos. Capturas em `work/shadowblade_fidelity/carrossel_*.png`.

Auditoria: 7.927 hashes, 34 alterações visuais autorizadas, zero inesperadas. O validador permite somente os métodos de apresentação/carrossel da loja; funções de comprar, equipar, economia e catálogo fora dos cinco campos splash continuam idênticas à base. Fidelidade estrutural dos 84 frames da Shadowblade passou.

Windows e Web locais são preparados da mesma árvore de fontes a3b059dc com o diff de candidato, versão 0.18.20. O executável principal recebe a cópia após export/smoke, com backup em `C:\Projetos\koliani-master\build\windows\backups\carrossel_antes_20261001`. O manifesto/logs ficam em `work/shadowblade_fidelity/`. Fontes do checkout principal antigo permanecem preservadas; a fonte deste candidato é o worktree `shadowblade-fidelity`.

**HUMAN PLAYTEST REQUIRED** para ritmo do fade, estética e fidelidade percebida das ilustrações. **DEVICE VALIDATION REQUIRED** para mobile/Web e pausa da loja em hardware real. Sem commit/push/publicação PWA online; não se declara entrega publicada. Próximo: avaliação humana do carrossel, validação no dispositivo e fecho do lote local.
