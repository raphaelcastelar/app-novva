# Plano de evolução Novva

## Direção de produto

Novva deve parecer um banco digital da contabilidade médica: seguro, claro, resolutivo e consultivo. A experiência deve reduzir jargões, antecipar pendências e transformar obrigações fiscais em tarefas simples.

## Arquitetura visual

- Manter Flutter, Riverpod, GoRouter, `MaterialApp.router` e estrutura por features.
- Centralizar identidade em `app/theme` e componentes reutilizáveis em `core/widgets`.
- Usar dados mockados por providers enquanto a integração real não estiver pronta.
- Priorizar cards premium, status visuais, ações explícitas e microcopy em pt-BR.

## Design system

- Cores base preservadas: `#145C73`, `#0C3744`, `#2F9E8F`, `#F6F8FA`, `#FFFFFF`.
- Cards com raio 22, borda `#E3E9ED` e sombra sutil.
- Headers com gradiente `#0C3744 -> #145C73 -> #2F9E8F`.
- Badges semânticos para regular, pendente, em análise, pago, vencido, disponível e atenção.
- Componentes principais: `PremiumHeader`, `MetricCard`, `ActionTile`, `InsightCard`, `TimelineStatus`, `MiniBarChart`, `AppCard`, `StatusBadge`, `EmptyState`.

## Navegação

Bottom navigation principal:

1. Início
2. Documentos
3. Guias
4. Notas
5. Mais

Em “Mais”: relatórios, chat, perfil médico, CNPJs, configurações, notificações, ajuda e segurança.

## Prioridades de tela

1. Dashboard premium com saúde contábil, faturamento, DAS atual, pendências, atalhos e educação.
2. Documentos com abas, solicitações, histórico, filtros e timeline.
3. Guias/DAS com abas por status, card do DAS atual e ações de pagamento.
4. NFS-e em etapas: dados, descrição, revisão e status.
5. Relatórios com métricas, gráficos e insights preventivos.
6. Chat com contador e ações contextuais a partir de guias, documentos e notas.
7. Perfil, CNPJs, notificações, segurança, tema e estados offline/loading/erro/vazio.

## Próximos passos técnicos

- Ligar os cards a modelos de domínio reais por feature.
- Criar providers específicos para pendências, DAS, notas fiscais e relatórios.
- Implementar preview/download/compartilhamento de PDF.
- Adicionar upload com câmera, galeria e arquivo em `document_upload`.
- Evoluir detalhes de guia com PDF embutido, linha digitável e histórico.
- Persistir CNPJ ativo e preferências do usuário.
- Adicionar testes de widget para dashboard, documentos, guias e NFS-e.
