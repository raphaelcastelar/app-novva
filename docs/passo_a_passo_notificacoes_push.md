# Passo a passo de implementação das notificações push — Novva

**Status:** pronto para execução  
**Última atualização:** 16 de outubro de 2026  
**Aplicativo:** Flutter (iOS e Android)  
**Backend:** NestJS + Prisma + PostgreSQL  
**Entrega de push:** Firebase Cloud Messaging (FCM) + Apple Push Notification service (APNs)  
**API de produção:** `https://api-novva.inovarcontabilidadex.com.br/api/v1/`

## 1. Objetivo

Implementar notificações push no Novva sem substituir a caixa de entrada do aplicativo. O banco de dados e a API continuam sendo a fonte oficial da informação; o push apenas avisa o usuário e o direciona para a tela correta.

O primeiro fluxo deve funcionar assim:

1. a equipe publica um comunicado ou o sistema cria um evento;
2. o backend salva a notificação no PostgreSQL;
3. o backend encontra os dispositivos ativos do destinatário;
4. o backend envia uma mensagem ao Firebase Cloud Messaging;
5. no iPhone, o Firebase encaminha a mensagem ao APNs;
6. o sistema operacional exibe a notificação;
7. ao tocar, o app abre, autentica o usuário e consulta os dados atuais na API;
8. a leitura é registrada no backend.

## 2. Situação atual do projeto

### Já disponível

- Bundle ID iOS definitivo: `br.com.novva.app`;
- Team ID Apple: `4UQ4KUM5R5`;
- aplicativo Novva criado no App Store Connect;
- primeira build enviada ao TestFlight como `0.1.0 (1)`;
- backend NestJS publicado na DigitalOcean;
- banco PostgreSQL e migrations pelo Prisma;
- modelos existentes `Notice`, `NoticeRecipient` e `Notification`;
- endpoints para listar comunicados, marcar como lido e baixar anexos;
- endpoints de notificações persistidas em `resources/notifications`;
- tela de notificações criada, ainda com conteúdo estático;
- Application ID Android atual: `br.com.novva.novva_app`.

### Ainda falta

- criar e configurar o projeto Firebase;
- ativar Push Notifications no App ID da Apple;
- criar a chave de autenticação APNs;
- recriar o provisioning profile de distribuição;
- adicionar Firebase ao iOS e Android;
- integrar os pacotes Firebase ao Flutter;
- solicitar permissão do usuário;
- registrar tokens dos aparelhos no backend;
- enviar pushes pelo backend;
- conectar a tela de notificações à API;
- tratar o toque e a navegação;
- testar em aparelhos físicos;
- enviar a build `0.1.0 (2)` ao TestFlight.

## 3. Arquitetura escolhida

```text
Painel administrativo / evento automático
                    |
                    v
              API NestJS Novva
               /           \
              v             v
       PostgreSQL       Firebase Admin
    (fonte oficial)          |
                             v
                            FCM
                         /       \
                        v         v
                 APNs / iOS    Android
                        \         /
                         v       v
                       App Flutter
                            |
                            v
                   consulta a API Novva
```

Decisões importantes:

- o app nunca enviará push diretamente;
- as credenciais administrativas ficarão somente no backend;
- o push não conterá dados fiscais, médicos ou financeiros sensíveis;
- o payload conterá apenas título genérico, tipo e identificador interno;
- se o push falhar, a notificação continuará disponível na caixa de entrada;
- o app aceitará somente tipos de navegação previamente definidos.

## 4. Contas, arquivos e informações necessárias

Antes de alterar o código, separar:

- [ ] acesso de Account Holder ou Admin à conta Apple Developer;
- [ ] acesso ao Firebase/Google Cloud que será usado pela Novva;
- [ ] acesso às variáveis de ambiente do backend na DigitalOcean;
- [ ] um iPhone físico para homologação;
- [ ] um Android físico para homologação;
- [ ] arquivo da chave APNs `.p8`;
- [ ] Key ID da chave APNs;
- [x] Team ID Apple: `4UQ4KUM5R5`;
- [x] Bundle ID iOS: `br.com.novva.app`;
- [x] Application ID Android: `br.com.novva.novva_app`;
- [ ] `GoogleService-Info.plist` do app iOS;
- [ ] `google-services.json` do app Android;
- [ ] credencial de serviço do Firebase usada pelo backend.

O arquivo `.p8` só pode ser baixado uma vez. Ele e as credenciais do Firebase não devem ser enviados por e-mail comum, colocados no Git ou incluídos em imagens Docker.

## 5. Configuração da Apple Developer

### 5.1 Ativar Push Notifications no App ID

1. Acessar [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/identifiers/list).
2. Abrir **Identifiers**.
3. Selecionar o identificador `br.com.novva.app`.
4. Na lista de capabilities, habilitar **Push Notifications**.
5. Clicar em **Save** e confirmar a alteração.

Essa alteração invalida os provisioning profiles anteriores associados ao App ID. O perfil manual atual precisa ser recriado antes do próximo archive.

### 5.2 Criar a chave APNs

Preferir uma chave de autenticação APNs em vez de certificado TLS, porque ela não expira automaticamente e pode atender desenvolvimento e produção.

1. Em **Certificates, Identifiers & Profiles**, abrir **Keys**.
2. Clicar no botão **+**.
3. Nome sugerido: `Novva Firebase APNs`.
4. Habilitar **Apple Push Notification service (APNs)**.
5. Quando solicitado, configurar a chave para os ambientes necessários e para o app Novva.
6. Confirmar a criação.
7. Anotar o **Key ID**.
8. Baixar o arquivo `.p8`.
9. Guardar o arquivo em um gerenciador de segredos ou cofre seguro.

Dados resultantes:

```text
APNS_KEY_ID=<Key ID mostrado pela Apple>
APPLE_TEAM_ID=4UQ4KUM5R5
APNS_KEY_FILE=AuthKey_<Key ID>.p8
```

O `.p8` será enviado ao Firebase Console, não ao aplicativo nem ao backend Novva, porque o backend usará o Firebase Admin para entregar as mensagens.

### 5.3 Recriar o provisioning profile de distribuição

1. Abrir **Profiles** no portal Apple Developer.
2. Clicar no botão **+**.
3. Escolher perfil para **App Store Connect**.
4. Selecionar o App ID `br.com.novva.app`.
5. Selecionar o certificado Apple Distribution já criado.
6. Nome sugerido: `Novva App Store Push`.
7. Gerar e baixar o perfil.
8. Abrir o arquivo `.mobileprovision` para instalá-lo no Xcode.
9. No target Runner, trocar o perfil manual antigo pelo novo.

O novo perfil deve conter o entitlement `aps-environment` para distribuição.

### 5.4 Adicionar capabilities no Xcode

1. Abrir `ios/Runner.xcworkspace` no Xcode.
2. Selecionar o projeto **Runner** e depois o target **Runner**.
3. Abrir **Signing & Capabilities**.
4. Confirmar o Team `Matheus Augusto Moura Eler`.
5. Manter o Bundle Identifier `br.com.novva.app`.
6. Clicar em **+ Capability** e adicionar **Push Notifications**.
7. Adicionar **Background Modes**.
8. Dentro de Background Modes, marcar **Remote notifications**.
9. Confirmar que Release usa o novo perfil `Novva App Store Push`.

Resultado esperado no projeto:

- arquivo de entitlements do Runner;
- `aps-environment` resolvido pela assinatura;
- background mode `remote-notification`;
- build assinada pelo Team ID correto.

## 6. Configuração do Firebase

### 6.1 Criar o projeto

1. Acessar [Firebase Console](https://console.firebase.google.com/).
2. Criar o projeto `Novva Produção`.
3. Vincular a uma organização Google corporativa, se disponível.
4. Conceder acesso administrativo a pelo menos duas pessoas responsáveis.
5. O Google Analytics é opcional para a primeira versão de push.

Recomendação futura: criar `Novva Homologação` separado para impedir que testes atinjam usuários reais.

### 6.2 Cadastrar o aplicativo iOS

1. Dentro do projeto, clicar em **Adicionar app** e escolher iOS.
2. Informar exatamente `br.com.novva.app`.
3. Apelido sugerido: `Novva iOS`.
4. O App Store ID pode ser informado se o console solicitar; ele não é necessário para o push funcionar.
5. Baixar `GoogleService-Info.plist`.
6. No Xcode, arrastar o arquivo para `Runner/`.
7. Marcar **Copy items if needed**.
8. Confirmar que o target **Runner** está selecionado.

O arquivo deve estar incluído no bundle do app. Ele pode ficar versionado no projeto por não ser uma chave administrativa, mas ambientes diferentes devem usar arquivos diferentes.

### 6.3 Conectar APNs ao Firebase

1. No Firebase Console, abrir **Configurações do projeto**.
2. Abrir a aba **Cloud Messaging**.
3. Localizar a configuração do aplicativo iOS.
4. Em **APNs Authentication Key**, clicar em **Upload**.
5. Selecionar o arquivo `.p8`.
6. Informar o Key ID anotado na Apple.
7. Informar o Team ID `4UQ4KUM5R5`.
8. Salvar.

### 6.4 Cadastrar o aplicativo Android

1. No mesmo projeto Firebase, adicionar um app Android.
2. Informar exatamente `br.com.novva.novva_app`.
3. Apelido sugerido: `Novva Android`.
4. Baixar `google-services.json`.
5. Colocar o arquivo em `android/app/google-services.json`.
6. Aplicar o plugin Google Services na configuração Gradle conforme as instruções atuais do Firebase.

Antes de publicar o Android, também será necessário substituir a assinatura de debug atual por uma assinatura release própria. Isso não impede a implementação e os testes iniciais do push.

### 6.5 Preparar a credencial do backend

1. No Firebase/Google Cloud, abrir as configurações de contas de serviço.
2. Criar ou selecionar uma conta usada exclusivamente pelo backend Novva.
3. Conceder somente as permissões necessárias para enviar mensagens FCM.
4. Gerar a credencial seguindo o mecanismo adotado na DigitalOcean.
5. Salvar seus valores como secrets, nunca em arquivos versionados.

Variáveis sugeridas:

```text
FIREBASE_PROJECT_ID=
FIREBASE_CLIENT_EMAIL=
FIREBASE_PRIVATE_KEY=
PUSH_NOTIFICATIONS_ENABLED=false
```

Ao cadastrar `FIREBASE_PRIVATE_KEY`, preservar as quebras de linha ou convertê-las corretamente na inicialização do SDK.

## 7. Implementação no Flutter

### 7.1 Dependências

Adicionar versões compatíveis com o Flutter utilizado no projeto:

```yaml
dependencies:
  firebase_core: <versão compatível>
  firebase_messaging: <versão compatível>
  flutter_local_notifications: <versão compatível>
  package_info_plus: <versão compatível>
```

Usar a FlutterFire CLI para gerar a configuração dos aplicativos:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Selecionar o projeto Firebase correto e os targets Android e iOS. Revisar o arquivo gerado `lib/firebase_options.dart` antes de versioná-lo.

### 7.2 Estrutura sugerida

```text
lib/core/notifications/
  notification_service.dart
  notification_permission_service.dart
  notification_navigation_service.dart
  notification_payload.dart

lib/features/notifications/
  data/
    notifications_remote_datasource.dart
    notifications_repository_impl.dart
  domain/
    entities/notification_item.dart
    repositories/notifications_repository.dart
  presentation/
    pages/notifications_page.dart
    providers/notifications_providers.dart
```

### 7.3 Inicialização

No início do aplicativo:

1. chamar `WidgetsFlutterBinding.ensureInitialized()`;
2. inicializar `Firebase.initializeApp` com as opções geradas;
3. registrar um handler de background como função de nível superior;
4. inicializar o serviço de notificações locais;
5. criar o canal Android;
6. configurar a apresentação em primeiro plano no iOS;
7. executar `runApp` mesmo que a inicialização do push falhe.

Push é complementar e uma indisponibilidade do Firebase não pode impedir login, documentos ou obrigações.

### 7.4 Solicitação de permissão

Não solicitar permissão assim que o app abrir pela primeira vez. Fluxo recomendado:

1. usuário realiza login;
2. o app explica que enviará avisos sobre documentos, obrigações e comunicados;
3. o usuário toca em **Ativar notificações**;
4. o app abre o diálogo nativo;
5. se autorizado, sincroniza o token;
6. se negado, mantém a caixa de entrada funcionando e oferece atalho futuro para Ajustes.

Solicitar `alert`, `badge` e `sound`. Não solicitar permissões provisórias ou críticas no MVP.

### 7.5 Token FCM

Depois da autenticação:

1. confirmar a permissão;
2. no iOS, aguardar o token APNs ficar disponível;
3. obter o token FCM;
4. enviar o token ao backend;
5. observar `onTokenRefresh` e reenviar quando mudar;
6. repetir a sincronização no login e na inicialização autenticada;
7. no logout, solicitar a desativação daquele token no backend;
8. permitir logout mesmo se estiver offline.

### 7.6 Recebimento e toque

Tratar quatro cenários:

| Cenário | Comportamento esperado |
|---|---|
| App aberto | Atualizar providers e exibir notificação local/banner |
| App em segundo plano | Sistema exibe; o app trata o toque em `onMessageOpenedApp` |
| App encerrado | Ler `getInitialMessage` após inicialização |
| Usuário deslogado | Guardar destino, abrir login e navegar somente após autenticação |

### 7.7 Navegação permitida

Usar uma lista fechada, por exemplo:

```text
notice                 -> /notifications
document_available     -> /documents/details?id=<entityId>
document_rejected      -> /documents/details?id=<entityId>
obligation_available   -> /obligations/details?id=<entityId>
obligation_due         -> /obligations/details?id=<entityId>
support_reply          -> /chat
general                -> /notifications
```

Nunca abrir uma URL ou rota arbitrária enviada no push. Ao abrir o destino, a API deve verificar se a entidade pertence ao usuário autenticado.

### 7.8 Tornar a tela de notificações real

1. registrar `RouteNames.notifications` no `GoRouter`;
2. substituir os itens fixos de `NotificationsPage` pelos endpoints existentes;
3. implementar carregamento, vazio, erro e atualização por gesto;
4. diferenciar itens lidos e não lidos;
5. marcar como lido ao abrir;
6. implementar **Marcar todas como lidas**;
7. atualizar o contador no ícone de sino;
8. manter comunicados com anexos usando o fluxo autenticado existente.

## 8. Implementação no backend

### 8.1 Instalar e inicializar Firebase Admin

1. adicionar `firebase-admin` ao backend;
2. criar um módulo/serviço `PushNotificationsService`;
3. inicializar uma única instância do Firebase Admin;
4. validar secrets no boot quando `PUSH_NOTIFICATIONS_ENABLED=true`;
5. usar uma implementação falsa nos testes automatizados;
6. não registrar credenciais nem tokens completos em logs.

### 8.2 Migration de dispositivos

Adicionar ao Prisma:

```prisma
enum PushPlatform {
  IOS
  ANDROID
}

enum PushEnvironment {
  DEVELOPMENT
  PRODUCTION
}

model PushDevice {
  id          String          @id @default(uuid()) @db.Uuid
  userId      String          @map("user_id") @db.Uuid
  token       String          @unique
  platform    PushPlatform
  environment PushEnvironment
  appVersion  String?         @map("app_version") @db.VarChar(30)
  deviceId    String?         @map("device_id") @db.VarChar(100)
  enabled     Boolean         @default(true)
  lastSeenAt  DateTime        @default(now()) @map("last_seen_at")
  createdAt   DateTime        @default(now()) @map("created_at")
  updatedAt   DateTime        @updatedAt @map("updated_at")
  user        User            @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@index([userId, enabled])
  @@index([environment, enabled])
  @@map("push_devices")
}
```

Adicionar também `pushDevices PushDevice[]` ao modelo `User` e criar uma migration versionada.

### 8.3 Endpoints de dispositivo

Criar endpoints autenticados:

```http
PUT /devices/current
Authorization: Bearer <JWT>
Content-Type: application/json

{
  "token": "token-fcm",
  "platform": "ios",
  "environment": "production",
  "appVersion": "0.1.0+2",
  "deviceId": "uuid-local-do-app"
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

Regras obrigatórias:

- `PUT` idempotente;
- um usuário pode ter vários aparelhos;
- token globalmente único;
- reassociar com segurança um token renovado;
- usuário só pode desativar seus próprios dispositivos;
- nunca armazenar IMEI ou Advertising ID;
- desabilitar tokens inválidos informados pelo FCM;
- atualizar `lastSeenAt` a cada sincronização.

### 8.4 Contrato do payload

Exemplo:

```json
{
  "notification": {
    "title": "Novo documento disponível",
    "body": "Há uma atualização disponível no aplicativo Novva."
  },
  "data": {
    "type": "document_available",
    "entityId": "uuid",
    "notificationId": "uuid"
  }
}
```

Todo valor em `data` deve ser string, conforme o contrato do FCM.

Não incluir:

- CPF ou CNPJ;
- valores ou códigos de pagamento;
- conteúdo médico;
- documentos;
- credenciais ou tokens de sessão;
- descrição fiscal detalhada.

O conteúdo pode aparecer na tela bloqueada do telefone.

### 8.5 Serviço de envio

O serviço deve:

1. receber IDs de usuários, conteúdo e ação permitida;
2. localizar tokens ativos do ambiente correto;
3. dividir lotes conforme o limite atual do SDK;
4. enviar pelo Firebase Admin;
5. registrar apenas contagens e códigos de erro seguros;
6. desabilitar tokens inválidos;
7. não desfazer a notificação persistida quando o push falhar;
8. evitar duplicidade por chave de idempotência.

### 8.6 Integração com os eventos existentes

Primeira entrega:

- comunicado administrativo publicado;
- documento disponibilizado;
- documento rejeitado;
- obrigação próxima do vencimento;
- obrigação/guia disponibilizada;
- resposta de suporte.

Ao criar um `Notice`, salvar o comunicado e os destinatários primeiro. Só depois solicitar o envio. Editar um comunicado não deve reenviar automaticamente; criar uma ação explícita de reenvio.

Para maior confiabilidade, usar uma tabela outbox ou fila:

1. notificação e tarefa de envio são criadas na mesma transação;
2. worker busca tarefas pendentes;
3. erro temporário recebe retry com backoff;
4. erro permanente desabilita o token;
5. uma chave única impede envio duplicado.

O MVP pode começar sem worker, desde que a falha do FCM nunca reverta o dado salvo. A outbox deve entrar antes de automações de grande volume.

## 9. Segurança e LGPD

- [ ] guardar chaves somente em secrets;
- [ ] impedir que `.p8` e JSON administrativo entrem no Git;
- [ ] proteger endpoints de dispositivos com JWT;
- [ ] limitar tamanho e formato dos tokens recebidos;
- [ ] usar lista fechada de plataformas, ambientes e ações;
- [ ] verificar propriedade da entidade ao navegar;
- [ ] não exibir informações sensíveis na tela bloqueada;
- [ ] permitir desativação de categorias não essenciais em evolução futura;
- [ ] documentar o uso de tokens de dispositivo na Política de Privacidade;
- [ ] definir retenção e limpeza de aparelhos inativos;
- [ ] revisar acessos à Apple, Firebase e DigitalOcean periodicamente;
- [ ] nunca usar tópico público para mensagens individualizadas.

## 10. Testes obrigatórios

### 10.1 Backend automatizado

- [ ] cadastro idempotente do mesmo token;
- [ ] renovação/substituição do token;
- [ ] separação entre desenvolvimento e produção;
- [ ] usuário não remove aparelho de outro usuário;
- [ ] falha do Firebase não apaga a notificação persistida;
- [ ] token inválido é desabilitado;
- [ ] retry não duplica envio;
- [ ] payload não contém campos sensíveis;
- [ ] envio respeita exatamente os destinatários;
- [ ] tokens e credenciais não aparecem nos logs.

### 10.2 Flutter automatizado

- [ ] parsing de payload válido e inválido;
- [ ] mapeamento de cada tipo para a rota permitida;
- [ ] payload desconhecido abre a caixa de entrada;
- [ ] sincronização de token ocorre apenas autenticada;
- [ ] falha na sincronização não bloqueia o app;
- [ ] tela lista estados carregando, vazio, erro e sucesso;
- [ ] leitura atualiza item e contador.

### 10.3 Testes manuais em aparelho físico

Executar no iPhone e no Android:

- [ ] permissão ainda não decidida;
- [ ] permissão aceita;
- [ ] permissão negada;
- [ ] app aberto;
- [ ] app em segundo plano;
- [ ] app encerrado;
- [ ] toque com usuário autenticado;
- [ ] toque com usuário deslogado;
- [ ] troca de usuário no mesmo aparelho;
- [ ] logout sem internet;
- [ ] renovação de token;
- [ ] reinstalação do aplicativo;
- [ ] comunicado com e sem anexo;
- [ ] build debug;
- [ ] build de distribuição via TestFlight.

## 11. Deploy em ordem segura

### 11.1 Backend

1. criar a migration `push_devices`;
2. rodar testes e build local;
3. cadastrar os secrets do Firebase na DigitalOcean;
4. manter `PUSH_NOTIFICATIONS_ENABLED=false`;
5. fazer deploy do backend;
6. aplicar a migration com `prisma migrate deploy`;
7. conferir health check e logs;
8. testar os endpoints de registro de dispositivo.

### 11.2 Aplicativo

1. integrar Firebase e permissões;
2. aumentar `pubspec.yaml` de `0.1.0+1` para `0.1.0+2`;
3. executar `flutter analyze`;
4. executar `flutter test`;
5. executar build Android de validação;
6. abrir o workspace iOS e conferir capabilities/assinatura;
7. gerar archive Release;
8. validar que o archive contém `aps-environment`;
9. enviar a build ao App Store Connect;
10. adicionar `0.1.0 (2)` ao grupo interno do TestFlight.

### 11.3 Ativação gradual

1. instalar a build via TestFlight nos aparelhos internos;
2. confirmar que tokens aparecem no banco;
3. enviar um teste pelo Firebase Console;
4. ativar `PUSH_NOTIFICATIONS_ENABLED=true` no backend;
5. enviar apenas para usuários internos;
6. conferir entrega, navegação e leitura;
7. expandir gradualmente para os demais usuários.

## 12. Rollback

Se houver erro no envio:

1. definir `PUSH_NOTIFICATIONS_ENABLED=false` na DigitalOcean;
2. manter a API, caixa de entrada e cadastro de dispositivos ativos;
3. não apagar tokens durante o incidente;
4. corrigir e testar com usuários internos;
5. revisar tarefas pendentes antes de reenviar;
6. reativar gradualmente.

Se o erro estiver no aplicativo, retirar a build do grupo interno e publicar uma nova build com número superior. Uma build já enviada ao App Store Connect não pode ser substituída mantendo o mesmo número.

## 13. Monitoramento

Monitorar sem expor conteúdo ou tokens:

- quantidade de dispositivos ativos por plataforma e ambiente;
- envios solicitados, concluídos e com erro;
- tokens inválidos desabilitados;
- taxa de erro do FCM;
- atraso entre criação e envio;
- abertura por tipo de notificação;
- crescimento anormal de envios;
- falhas de cadastro/renovação de token no app.

## 14. Critério de conclusão

A implementação estará pronta quando:

1. o usuário autorizar notificações;
2. o app registrar o token na API;
3. o backend persistir uma notificação para o usuário;
4. o backend enviar o push pelo FCM;
5. iPhone e Android receberem com o app aberto, em segundo plano e encerrado;
6. o toque abrir a tela correta após autenticação;
7. a leitura atualizar a API e o contador;
8. falhas do Firebase não eliminarem a caixa de entrada;
9. nenhum segredo ou token completo aparecer no Git ou nos logs;
10. a build `0.1.0 (2)` estiver funcionando no TestFlight interno.

## 15. Checklist resumido de execução

### Responsável pela Apple/Firebase

- [ ] ativar Push Notifications no App ID;
- [ ] criar e guardar chave `.p8`;
- [ ] recriar provisioning profile;
- [ ] criar projeto Firebase;
- [ ] cadastrar iOS e Android;
- [ ] enviar chave APNs ao Firebase;
- [ ] disponibilizar arquivos de configuração;
- [ ] disponibilizar credencial segura para o backend.

### Desenvolvimento

- [ ] configurar capabilities iOS e Gradle Android;
- [ ] integrar FlutterFire;
- [ ] implementar permissão, token, handlers e navegação;
- [ ] implementar migration e endpoints;
- [ ] integrar Firebase Admin;
- [ ] conectar caixa de entrada à API;
- [ ] criar testes automatizados;
- [ ] atualizar Política de Privacidade.

### Publicação

- [ ] configurar secrets na DigitalOcean;
- [ ] aplicar migration;
- [ ] publicar backend com envio desativado;
- [ ] gerar build `0.1.0 (2)`;
- [ ] distribuir no TestFlight interno;
- [ ] homologar em aparelhos físicos;
- [ ] ativar envios para internos;
- [ ] liberar gradualmente.

## 16. Referências oficiais

- [Apple — habilitar capabilities no App ID](https://developer.apple.com/help/account/identifiers/enable-app-capabilities/)
- [Apple — criar chave privada para serviços](https://developer.apple.com/help/account/keys/create-a-private-key/)
- [Apple — registrar o app no APNs](https://developer.apple.com/documentation/usernotifications/registering-your-app-with-apns)
- [Firebase — configurar Cloud Messaging em apps Apple](https://firebase.google.com/docs/cloud-messaging/ios/get-started)
- [Firebase — configurar Cloud Messaging no Flutter](https://firebase.google.com/docs/cloud-messaging/flutter/get-started)
- [Firebase — receber mensagens no Flutter](https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages)
- [Firebase — ambiente de servidor](https://firebase.google.com/docs/cloud-messaging/server-environment)
- [Firebase — enviar mensagens com Admin SDK](https://firebase.google.com/docs/cloud-messaging/send/admin-sdk)
- [Firebase — preços](https://firebase.google.com/pricing)

