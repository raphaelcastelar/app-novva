# Novva API

API REST do aplicativo Novva, construída com NestJS, TypeScript, Prisma e PostgreSQL.

## Desenvolvimento local

Requisitos: Node.js 22+, npm e PostgreSQL 17 (ou Docker Desktop).

```bash
cp .env.example .env
docker compose up -d postgres
npm install
npx prisma generate
npm run migrate:deploy
npm run seed
npm run dev
```

A API estará em `http://localhost:8080/api/v1` e o Swagger em `http://localhost:8080/docs`.

Usuário criado pelo seed: CPF `12831146747`, senha `Novva@1234`. O seed é bloqueado em produção, salvo quando `ALLOW_PRODUCTION_SEED=true` for definido conscientemente.

## Módulos e endpoints

- Autenticação: verificação de CPF, login, criação/redefinição/troca de senha, refresh e logout.
- Usuário: dados básicos, perfil médico e exclusão completa da conta.
- CNPJs: listagem, cadastro, edição, ativação e exclusão.
- Dashboard: resumo consolidado do usuário.
- Documentos: listagem, detalhe e solicitação.
- Obrigações: listagem, detalhe e confirmação de pagamento.
- NFS-e: listagem, detalhe e solicitação de emissão.
- Pagamentos e relatórios: consultas consolidadas.
- Chat: histórico e envio de mensagens.
- Notificações: listagem, leitura individual e leitura em lote.

Todas as rotas privadas usam `Authorization: Bearer <accessToken>` e filtram os dados pelo usuário do token. Valores monetários são devolvidos como números na API.

## Produção

- Use um `JWT_SECRET` aleatório com no mínimo 32 caracteres.
- Restrinja `APP_ORIGIN`; não use `*` em produção.
- Execute `npm run migrate:deploy` antes de iniciar a nova versão.
- Use PostgreSQL gerenciado com backup e restauração testados.
- Configure TLS no proxy/load balancer e nunca exponha o banco publicamente.
- Não execute o seed de demonstração.
- O fluxo `forgot-password` cria o token com validade curta. A entrega por e-mail deve ser ligada ao provedor transacional escolhido antes do lançamento público.
- Arquivos/PDFs são representados por chaves privadas no banco. Upload e URLs temporárias devem ser ligados ao bucket S3 escolhido antes do lançamento público.

## Qualidade

```bash
npm run build
npm test
```
