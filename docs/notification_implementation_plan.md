# Planejamento de notificações — Novva App

**Status:** planejamento  
**Última revisão:** 12 de outubro de 2026  
**Aplicativos:** Flutter para Android e iOS  
**Backend:** NestJS + Prisma/PostgreSQL  
**Canal de push recomendado:** Firebase Cloud Messaging (FCM)

## 1. Objetivo

Implementar notificações confiáveis para os usuários da Novva, combinando:

- **caixa de entrada no aplicativo**, persistida no banco de dados;
- **notificação push**, usada para avisar o usuário mesmo quando o app está fechado;
- **navegação contextual**, levando o usuário ao comunicado, documento, obrigação ou solicitação relacionado;
- **painel administrativo e eventos automáticos**, capazes de gerar comunicados para usuários específicos.

O push será apenas o canal de entrega. O conteúdo persistido na API será a fonte oficial, permitindo que o usuário encontre o aviso mesmo se o push atrasar, for bloqueado pelo sistema operacional ou não for entregue.

## 2. Diagnóstico do projeto atual

O projeto já possui uma base relevante:

- API de produção configurada em `https://api-novva.inovarcontabilidadex.com.br/api/v1/`;
- backend NestJS no diretório `backend/`;
- banco PostgreSQL acessado por Prisma;
- modelos `Notice`, `NoticeRecipient` e `Notification`;
- endpoints autenticados para listar comunicados, marcar como lido e baixar anexos;
- criação e edição de comunicados pela área administrativa;
- listagem de comunicados no dashboard Flutter;
- identificador Android atual: `br.com.novva.novva_app`;
- Bundle ID iOS documentado: `br.com.novva.app`.

Pendências encontradas:

- Firebase ainda não está configurado no Flutter;
- não existe armazenamento de tokens de dispositivos no backend;
- o backend ainda não envia mensagens ao FCM;
- o app não solicita permissão de notificação;
- mensagens em primeiro plano, segundo plano e app encerrado ainda não são tratadas;
- a tela `NotificationsPage` contém dados estáticos;
- existe a constante `/notifications`, mas essa rota não está registrada no `GoRouter`;
- o build Android release ainda usa assinatura de debug e precisa ser preparado para publicação.

Antes de cadastrar os apps no Firebase, os identificadores definitivos de Android e iOS devem ser confirmados. Alterá-los posteriormente gera novos cadastros de aplicativo e arquivos de configuração.

## 3. Arquitetura proposta

```text
Painel administrativo ou evento do sistema
                  |
                  v
       API Novva no domínio HTTPS
        |                    |
        | grava              | envia
        v                    v
PostgreSQL (fonte oficial)  Firebase Cloud Messaging
        |                    |
        +----------+---------+
                   v
           App Android/iOS
                   |
                   v
     Tela relacionada + status de leitura
```

Fluxo de um comunicado manual:

1. a equipe cria o comunicado no painel;
2. o backend grava `Notice` e `NoticeRecipient`;
3. depois da gravação bem-sucedida, o backend localiza os dispositivos ativos dos destinatários;
4. o backend solicita o envio ao FCM;
5. o app exibe o push e, ao toque, abre o comunicado;
6. o app busca os dados atuais na API e marca o comunicado como lido.

Fluxo de uma notificação automática:

1. um evento ocorre, como documento rejeitado ou obrigação próxima do vencimento;
2. o backend cria uma notificação persistente e associa o tipo e a entidade relacionada;
3. o mesmo serviço dispara o push;
4. ao tocar, o usuário é direcionado à tela da entidade.

## 4. Responsabilidade do domínio

O domínio existente será utilizado para:

- expor os endpoints autenticados de cadastro de dispositivos;
- receber as ações administrativas;
- armazenar as notificações no banco;
- acionar o FCM a partir de um ambiente confiável;
- servir os dados atualizados quando o app for aberto.

Não é necessário criar um domínio exclusivo para notificações nem fazer uma configuração especial de DNS para o FCM mobile. O requisito principal é manter a API disponível por HTTPS.

Links universais usando o domínio podem ser adicionados no futuro. Nesse caso, serão necessários `apple-app-site-association` no iOS e `assetlinks.json` no Android. Para a primeira versão, a navegação pode usar dados internos do push e o roteador do app.

## 5. Pré-requisitos e acessos

Providenciar antes da implementação:

- [ ] conta Google que será proprietária do projeto Firebase;
- [ ] acesso à conta Apple Developer da Novva;
- [ ] permissão para criar chave APNs na Apple;
- [ ] acesso ao projeto iOS no Xcode e aos certificados de distribuição;
- [ ] acesso ao ambiente de produção do backend/DigitalOcean;
- [ ] acesso às variáveis secretas do ambiente de produção;
- [ ] Android Application ID e iOS Bundle ID definitivos;
- [ ] pelo menos um iPhone físico e um Android para homologação;
- [ ] definição dos primeiros eventos que poderão enviar push.

Usar contas corporativas e manter pelo menos dois administradores nos projetos Apple, Google e infraestrutura para evitar dependência de uma única pessoa.

## 6. Etapa 1 — Configurar Firebase, Android e Apple

### 6.1 Firebase

- [ ] criar um projeto Firebase de produção da Novva;
- [ ] definir proprietários e administradores;
- [ ] habilitar o Firebase Cloud Messaging API HTTP v1;
- [ ] cadastrar o aplicativo Android com o Application ID definitivo;
- [ ] cadastrar o aplicativo iOS com o Bundle ID definitivo;
- [ ] gerar os arquivos de configuração de cada plataforma;
- [ ] separar projetos Firebase de produção e homologação, se ambos enviarem push para usuários reais;
- [ ] executar um envio manual pelo console para validar a configuração inicial.

O FCM é disponibilizado sem custo. Outros serviços opcionais do Firebase ou Google Cloud podem ter cobrança própria.

### 6.2 Android

- [ ] adicionar o arquivo `google-services.json` ao target Android correto;
- [ ] aplicar o plugin Google Services na configuração Gradle;
- [ ] confirmar compatibilidade do `minSdk` com as versões atuais dos pacotes;
- [ ] declarar a permissão de notificações exigida no Android 13 ou superior;
- [ ] criar um canal de alta importância para avisos relevantes;
- [ ] definir ícone monocromático e cor padrão da notificação;
- [ ] configurar assinatura release real antes da publicação;
- [ ] validar recebimento em Android com o app aberto, em segundo plano e encerrado.

### 6.3 iOS

- [ ] habilitar Push Notifications no App ID da Apple;
- [ ] criar uma chave de autenticação APNs e guardar o arquivo `.p8` com segurança;
- [ ] enviar a chave APNs, Key ID e Team ID ao projeto Firebase;
- [ ] adicionar a capability **Push Notifications** ao target Runner;
- [ ] habilitar **Background Modes > Remote notifications**;
- [ ] adicionar `GoogleService-Info.plist` ao target correto;
- [ ] confirmar que o entitlement `aps-environment` corresponde ao tipo de build;
- [ ] testar em iPhone físico com build assinado.

A chave APNs e as credenciais administrativas do Firebase não devem ser incluídas no Git.

## 7. Etapa 2 — Alterações no backend

### 7.1 Dependência e inicialização

- [ ] adicionar o Firebase Admin SDK ao backend NestJS;
- [ ] criar um `PushNotificationModule` com serviço próprio;
- [ ] inicializar uma única instância do SDK durante o ciclo de vida da aplicação;
- [ ] desabilitar envio real em testes automatizados;
- [ ] falhar de forma clara no boot de produção quando uma configuração obrigatória estiver ausente.

Variáveis sugeridas:

```text
FIREBASE_PROJECT_ID=
FIREBASE_CLIENT_EMAIL=
FIREBASE_PRIVATE_KEY=
PUSH_NOTIFICATIONS_ENABLED=true
```

Na DigitalOcean, essas variáveis devem ser cadastradas como secrets. Outra opção é fornecer uma credencial pelo mecanismo de Application Default Credentials. A chave privada nunca deve aparecer em código, imagem Docker, log ou resposta HTTP.

### 7.2 Cadastro de dispositivos

Criar uma tabela Prisma semelhante a:

```text
PushDevice
- id: UUID
- userId: UUID
- token: texto único
- platform: ios | android
- environment: production | development
- appVersion: texto opcional
- deviceId: identificador local opcional, não publicitário
- enabled: boolean
- lastSeenAt: data/hora
- createdAt: data/hora
- updatedAt: data/hora
```

Regras:

- um usuário pode ter vários dispositivos;
- o token deve ser único globalmente;
- se o mesmo token aparecer em outra sessão, sua associação deve ser atualizada com segurança;
- não armazenar IMEI, Advertising ID ou outro identificador invasivo;
- remover ou desabilitar tokens que o FCM informar como inválidos;
- registrar `lastSeenAt` para permitir limpeza periódica;
- separar tokens de homologação e produção para impedir envios cruzados.

Endpoints autenticados propostos:

```http
PUT /devices/current
Authorization: Bearer <JWT>
Content-Type: application/json

{
  "token": "token-fcm",
  "platform": "ios",
  "appVersion": "0.1.0"
}
```

```http
DELETE /devices/current
Authorization: Bearer <JWT>
Content-Type: application/json

{
  "token": "token-fcm"
}
```

O `PUT` deve ser idempotente. O app pode chamá-lo no login, ao iniciar uma sessão autenticada e sempre que o FCM renovar o token.

### 7.3 Serviço de envio

Criar uma interface interna que receba:

- destinatários;
- título e resumo;
- tipo da notificação;
- identificador da entidade;
- ação de navegação permitida;
- opções de prioridade e expiração.

Exemplo de payload conceitual:

```json
{
  "notification": {
    "title": "Novo documento disponível",
    "body": "Seu DAS de outubro já pode ser consultado."
  },
  "data": {
    "type": "obligation_available",
    "entityId": "uuid-da-obrigacao",
    "notificationId": "uuid-da-notificacao"
  }
}
```

Não enviar CPF, CNPJ, diagnóstico, informação médica, valor financeiro detalhado, documento ou token de autenticação no push. O texto pode aparecer na tela bloqueada. O app deve receber apenas identificadores e consultar dados protegidos na API após autenticação.

O campo `type` deve usar uma lista fechada de ações. O app não deve aceitar uma URL ou rota arbitrária enviada pelo servidor.

### 7.4 Integração com as estruturas atuais

Manter inicialmente os papéis atuais:

- `Notice` + `NoticeRecipient`: comunicados criados pela equipe, com possível anexo;
- `Notification`: eventos transacionais gerados pelo sistema.

O serviço de push pode atender as duas estruturas, mas ambas devem compartilhar:

- convenção de tipos;
- política de conteúdo sensível;
- serviço de entrega;
- métricas e tratamento de token inválido;
- navegação validada no aplicativo.

No método administrativo `createNotice`, o push deve ser enfileirado somente depois que o comunicado e seus destinatários forem persistidos. A edição de um comunicado não deve reenviar automaticamente para todos; disponibilizar uma ação explícita de reenvio evita duplicidade acidental.

### 7.5 Confiabilidade

Para o MVP, o envio pode ser executado após a transação do banco, desde que uma falha no FCM não desfaça o comunicado salvo.

Para produção robusta, adotar um **outbox** ou fila:

1. gravar o comunicado e uma tarefa de envio na mesma transação;
2. um worker processa a tarefa;
3. falhas transitórias recebem novas tentativas com backoff;
4. falhas permanentes desabilitam o token;
5. cada tarefa usa chave de idempotência para impedir envio duplicado.

Não registrar o token completo do dispositivo em logs. Quando necessário para diagnóstico, registrar apenas um hash ou os últimos caracteres.

## 8. Etapa 3 — Alterações no Flutter

### 8.1 Dependências

Adicionar e manter nas versões compatíveis com o Flutter do projeto:

- `firebase_core`;
- `firebase_messaging`;
- `flutter_local_notifications`.

Usar FlutterFire CLI para gerar a configuração, evitando copiar opções manualmente entre ambientes.

### 8.2 Inicialização

- [ ] inicializar Firebase antes de `runApp`;
- [ ] registrar o handler de mensagens em segundo plano como função de nível superior;
- [ ] criar um serviço de notificações isolado da interface;
- [ ] criar o canal Android durante a inicialização;
- [ ] definir apresentação em primeiro plano no iOS;
- [ ] garantir que falhas de push não impeçam a abertura do aplicativo.

### 8.3 Permissão

Não pedir permissão imediatamente na primeira tela. Apresentar antes uma explicação curta do benefício, preferencialmente após login ou quando o usuário acessar a área de notificações.

Fluxo:

1. explicar quais avisos serão enviados;
2. pedir a permissão nativa;
3. registrar o resultado localmente;
4. se negada, manter a caixa de entrada funcionando;
5. oferecer um atalho para as configurações do sistema, sem insistência excessiva.

### 8.4 Registro e renovação do token

- [ ] obter o token FCM somente depois da inicialização válida;
- [ ] no iOS, aguardar a disponibilidade do token APNs antes de operações dependentes do FCM;
- [ ] enviar o token à API quando houver usuário autenticado;
- [ ] ouvir a renovação do token e atualizar a API;
- [ ] tentar novamente após falhas temporárias de rede;
- [ ] desassociar o token no logout quando possível;
- [ ] não bloquear o logout caso o aparelho esteja offline.

Como proteção adicional para logout offline, o backend deve validar a sessão do usuário e permitir expiração/limpeza de dispositivos inativos. O conteúdo do push continuará sem dados sensíveis.

### 8.5 Recebimento e navegação

Tratar os estados:

- **app aberto:** receber pelo listener e exibir notificação local ou atualizar a interface;
- **segundo plano:** o sistema exibe o push; o app trata o toque;
- **app encerrado:** ler a mensagem inicial e navegar depois que autenticação e roteador estiverem prontos.

Criar um tradutor centralizado de ações, por exemplo:

```text
notice                    -> /notifications (ou detalhe do comunicado)
document_available        -> /documents/details?id=...
document_rejected         -> /documents/details?id=...
obligation_due            -> /obligations/details?id=...
request_status            -> tela da solicitação correspondente
support_reply             -> conversa/chamado correspondente
```

Se o usuário estiver deslogado, guardar temporariamente a intenção de navegação, abrir o login e executar a navegação somente após autenticação. Se a entidade não existir mais ou não pertencer ao usuário, mostrar mensagem neutra e abrir a caixa de entrada.

### 8.6 Interface

- [ ] substituir os itens estáticos de `NotificationsPage` por dados da API;
- [ ] registrar `/notifications` no `GoRouter`;
- [ ] exibir estado carregando, vazio e erro;
- [ ] diferenciar visualmente itens lidos e não lidos;
- [ ] marcar como lido ao abrir;
- [ ] atualizar o contador do sino após leitura;
- [ ] incluir atualização por gesto de puxar;
- [ ] manter download autenticado dos anexos;
- [ ] considerar a ação “marcar todas como lidas” em uma segunda etapa.

## 9. Etapa 4 — Eventos iniciais

Implementar primeiro eventos de alto valor e baixa ambiguidade:

| Evento | Destinatário | Navegação | Prioridade sugerida |
|---|---|---|---|
| Comunicado administrativo publicado | Usuários selecionados | Comunicado | Normal |
| Documento disponibilizado | Dono do documento | Detalhe do documento | Normal |
| Documento rejeitado | Dono do documento | Detalhe do documento | Alta |
| Obrigação próxima do vencimento | Responsável | Detalhe da obrigação | Alta |
| Solicitação atualizada | Solicitante | Solicitação | Normal |
| Resposta de suporte | Participante | Conversa/chamado | Normal |

Regras de produto a definir para cada evento:

- quem recebe;
- quando recebe;
- se pode repetir;
- horário permitido;
- título e resumo;
- validade do push;
- tela de destino;
- ação quando a entidade já foi resolvida.

Evitar excesso de notificações. Eventos repetitivos devem ser agrupados ou possuir janela mínima entre envios.

## 10. Segurança, privacidade e LGPD

- tratar tokens FCM como identificadores protegidos;
- armazenar credenciais administrativas somente em secrets do servidor;
- nunca enviar push diretamente a partir do app cliente;
- validar a propriedade da entidade ao abrir qualquer destino;
- limitar o texto visível na tela bloqueada;
- documentar notificações e tokens de dispositivo na política de privacidade;
- permitir que o usuário desative categorias não essenciais quando essa funcionalidade for criada;
- manter trilha de auditoria de comunicados administrativos;
- definir retenção e limpeza de tokens inativos;
- revisar acesso dos administradores ao Firebase periodicamente;
- não usar tópicos públicos para mensagens individualizadas ou confidenciais.

## 11. Estratégia de ambientes

Recomendação:

| Item | Homologação | Produção |
|---|---|---|
| Projeto Firebase | Novva Homolog | Novva Produção |
| API | ambiente de homologação | domínio de produção |
| Aplicativo | ID/sufixo próprio, se viável | IDs oficiais |
| APNs | build de desenvolvimento/TestFlight | distribuição/App Store |
| Credenciais backend | secrets de homologação | secrets de produção |

Se for mantido apenas um projeto Firebase, o backend deverá obrigatoriamente separar `environment` nos dispositivos e nos envios.

## 12. Testes e critérios de aceite

### 12.1 Backend

- [ ] cadastro idempotente de dispositivo;
- [ ] usuário não pode remover dispositivo de outro usuário;
- [ ] renovação substitui corretamente o token anterior;
- [ ] criação de comunicado permanece bem-sucedida se o FCM estiver indisponível;
- [ ] retry não gera duplicidade;
- [ ] token inválido é desabilitado;
- [ ] payload nunca contém dados sensíveis;
- [ ] envio respeita destinatários e ambiente;
- [ ] credenciais e tokens não aparecem nos logs.

### 12.2 Flutter

- [ ] permissão aceita, negada e ainda não decidida;
- [ ] recebimento em primeiro plano;
- [ ] recebimento em segundo plano;
- [ ] recebimento com app encerrado;
- [ ] toque abre o destino correto;
- [ ] toque com usuário deslogado passa pelo login;
- [ ] token é enviado após login e renovação;
- [ ] logout funciona mesmo sem internet;
- [ ] lista e contador são atualizados;
- [ ] anexo continua protegido pela autenticação;
- [ ] app continua utilizável quando Firebase ou API estão indisponíveis.

### 12.3 Dispositivos mínimos

- um Android 13 ou superior;
- um Android anterior ao 13, se estiver dentro do suporte do app;
- um iPhone físico com uma versão atual do iOS;
- build debug para desenvolvimento;
- build release/TestFlight para validar APNs de distribuição.

### 12.4 Critério de conclusão do MVP

O MVP estará concluído quando:

1. um usuário autenticado registrar o dispositivo na API;
2. a equipe criar um comunicado para esse usuário;
3. o comunicado ficar disponível na caixa de entrada;
4. o aparelho receber o push nos três estados do app;
5. o toque abrir o destino correto;
6. a leitura atualizar o backend e o contador;
7. falhas de entrega não eliminarem o comunicado persistido;
8. testes automatizados e manuais essenciais estiverem aprovados.

## 13. Ordem recomendada de implementação

### Fase A — Fundação

- confirmar IDs definitivos dos aplicativos;
- criar projetos Firebase;
- configurar Android, Apple e APNs;
- instalar dependências Flutter;
- validar um push manual em aparelhos de teste.

### Fase B — Backend

- criar migration de `PushDevice`;
- implementar endpoints de cadastro e remoção;
- integrar Firebase Admin SDK;
- implementar envio e limpeza de tokens inválidos;
- adicionar testes.

### Fase C — Aplicativo

- inicializar Firebase;
- implementar permissão e sincronização de token;
- tratar foreground, background, encerrado e toque;
- registrar rota e tornar a tela de notificações dinâmica;
- adicionar testes unitários e de widget.

### Fase D — Integração

- disparar push ao criar comunicado administrativo;
- implementar um evento automático piloto;
- homologar Android e iOS;
- revisar texto da política de privacidade.

### Fase E — Produção e evolução

- liberar gradualmente;
- monitorar erros e tokens inválidos;
- adicionar outbox/fila, caso não tenha entrado no MVP;
- incluir preferências por categoria;
- adicionar métricas de abertura sem registrar conteúdo sensível.

## 14. Implantação e rollback

Ordem segura de deploy:

1. aplicar migration de dispositivos;
2. publicar backend com envio desativado por `PUSH_NOTIFICATIONS_ENABLED=false`;
3. publicar o app com registro de token e caixa de entrada;
4. validar a população de dispositivos em homologação/produção;
5. ativar envio apenas para usuários internos;
6. validar métricas e logs;
7. ampliar gradualmente para os demais usuários.

Rollback:

- desativar imediatamente `PUSH_NOTIFICATIONS_ENABLED`;
- manter caixa de entrada e endpoints funcionando;
- não apagar tokens durante um incidente;
- corrigir o serviço e reativar gradualmente;
- não reenviar automaticamente tarefas antigas sem revisar risco de duplicidade.

## 15. Monitoramento operacional

Criar métricas e alertas para:

- quantidade de dispositivos ativos por plataforma;
- solicitações de envio criadas, concluídas e com erro;
- tokens inválidos removidos/desabilitados;
- taxa de erro do FCM;
- atraso entre criação e processamento;
- aberturas por tipo, sem armazenar conteúdo sensível;
- crescimento anormal de envios, que pode indicar loop ou abuso.

O painel operacional deve mostrar identificadores internos e contagens, evitando expor tokens completos.

## 16. Decisões pendentes

- [ ] confirmar o Application ID Android definitivo;
- [ ] confirmar o Bundle ID iOS definitivo;
- [ ] definir se haverá Firebase separado para homologação;
- [ ] escolher os eventos incluídos no MVP;
- [ ] definir horário silencioso e preferências do usuário;
- [ ] decidir se o MVP já utilizará outbox/fila;
- [ ] definir período de retenção dos tokens inativos;
- [ ] definir quem será responsável por Apple, Firebase e infraestrutura;
- [ ] revisar a política de privacidade antes da publicação.

## 17. Referências oficiais

- [Firebase Cloud Messaging para Flutter](https://firebase.google.com/docs/cloud-messaging/flutter/get-started)
- [Recebimento de mensagens em Flutter](https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages)
- [Ambiente de servidor do FCM](https://firebase.google.com/docs/cloud-messaging/server-environment)
- [Envio pela API HTTP v1](https://firebase.google.com/docs/cloud-messaging/send/v1-api)
- [Preços do Firebase](https://firebase.google.com/pricing)
- [Registro do aplicativo no APNs](https://developer.apple.com/documentation/usernotifications/registering-your-app-with-apns)

