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
- Obrigações: listagem, geração e recálculo de DAS pelo Integra Contador, download e confirmação de pagamento.
- NFS-e: listagem, detalhe e solicitação de emissão.
- Pagamentos e relatórios: consultas consolidadas.
- Chat: histórico e envio de mensagens.
- Notificações: listagem, leitura individual e leitura em lote.
- Dispositivos push: registro e remoção do token FCM do aparelho autenticado.

Todas as rotas privadas usam `Authorization: Bearer <accessToken>` e filtram os dados pelo usuário do token. Valores monetários são devolvidos como números na API.

## Notificações push

Ao anexar um arquivo a um documento pela área administrativa, a API registra a
notificação e envia um push aos aparelhos vinculados ao usuário. Gere uma conta
de serviço em Firebase Console > Configurações do projeto > Contas de serviço e
configure o ambiente do backend:

```text
PUSH_NOTIFICATIONS_ENABLED=true
FIREBASE_SERVICE_ACCOUNT_BASE64=<JSON da conta de serviço codificado em base64>
```

Como alternativa, configure `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL` e
`FIREBASE_PRIVATE_KEY`. O JSON e a chave privada são segredos do servidor e não
devem ser incluídos no app, no Git ou em imagens Docker.

Rotas autenticadas do aparelho:

- `PUT /api/v1/devices/current` para registrar ou renovar o token FCM;
- `DELETE /api/v1/devices/current` para desativar o token no logout.

## Produção

- Use um `JWT_SECRET` aleatório com no mínimo 32 caracteres.
- Restrinja `APP_ORIGIN`; não use `*` em produção.
- Execute `npm run migrate:deploy` antes de iniciar a nova versão.
- Use PostgreSQL gerenciado com backup e restauração testados.
- Configure TLS no proxy/load balancer e nunca exponha o banco publicamente.
- Não execute o seed de demonstração.
- O fluxo `forgot-password` cria o token com validade curta. A entrega por e-mail deve ser ligada ao provedor transacional escolhido antes do lançamento público.
- Arquivos/PDFs são representados por chaves privadas no banco. Upload e URLs temporárias devem ser ligados ao bucket S3 escolhido antes do lançamento público.

## Integra Contador / DAS

A geração usa o serviço `PGDASD/GERARDAS12` do Integra Contador. Configure no
ambiente do backend:

```text
SERPRO_ENABLED=true
SERPRO_CONSUMER_KEY=
SERPRO_CONSUMER_SECRET=
SERPRO_CONTRACTOR_CNPJ=00000000000000
SERPRO_CERT_PEM=
SERPRO_PRIVATE_KEY_PEM=
SERPRO_CERT_PASSWORD=
```

Os valores PEM podem ser fornecidos como secrets com quebras de linha reais ou
com `\n`. Como alternativa, use `SERPRO_CERT_PATH` e
`SERPRO_PRIVATE_KEY_PATH`. Credenciais e certificados nunca devem ser enviados
ao app Flutter ou incluídos no repositório.

Rotas autenticadas:

- `POST /api/v1/obligations/generate` com `{ "month": 10, "year": 2026 }`;
- `POST /api/v1/obligations/:id/recalculate` para emitir novamente uma guia existente;
- `GET /api/v1/obligations/:id/file` para baixar o PDF armazenado.

## Qualidade

```bash
npm run build
npm test
```
