# Novva App Flutter

Aplicativo Flutter mobile-first para gestão contábil de médicos, baseado no app React Native/Expo em `reference-react`.

## Análise do repositório React

O repositório base é um app Expo/React Native. As telas encontradas foram:

- `CpfScreen`, `PassScreen`, `CreatePassScreen`, `ResetPasswordScreen`: autenticação por CPF e senha.
- `HomepageScreen`: home com atalhos para NFs-e, Simples Nacional e documentos constitutivos.
- `NfsScreen` e `DescriptionScreen`: solicitação de emissão de NFs-e com município, CNPJ, valor, data, código `04.01.01 Medicina` e descrição do serviço.
- `DasScreen`: listagem anual/mensal de DAS, download por link do Google Drive e solicitação de recálculo.
- `DocumentScreen`: solicitação de documentos constitutivos.
- `ManageCNPJsScreen`: CRUD básico de tomadores/CNPJs por CPF.
- `SettingsScreen`, `UserSettingsScreen`, `MenuModal`: configurações, perfil simples e logout.

Contratos Firestore observados:

- `pre_cadastro`: `cpf`, `nome`, `email`, `senha`.
- `tomador/{cpf}/CNPJ`: `cnpj`, `apelido`, `createdAt`.
- `servicos/{cpf}/notas`: `municipio`, `cnpj`, `data`, `valor`, `codigo_tributacao`, `descricao_servico`, `horario_emissao`.
- `servicos/{cpf}/documentos`: `nome_documento`, `data`.
- `das/{cpf}/links/{ano-mes}`: `mes`, `ano`, `linkdas`.
- `das/{cpf}/Recalculo`: `cpf`, `mes`, `ano`, `data_hora`.

Riscos encontrados na referência: senha em texto puro, SendGrid API key hardcoded, Firebase config no cliente, logs com dados sensíveis e sessão em AsyncStorage. A versão Flutter isola esses pontos atrás de repositórios e usa `flutter_secure_storage`.

## Funcionalidades migradas e ampliadas

- Autenticação por CPF/senha, criação e recuperação de senha.
- Dashboard médico com situação contábil, pendências, guias, documentos, relatórios e mensagens.
- Documentos com filtros, status, detalhe, upload, rejeição e motivo.
- Obrigações/guias com vencimento, valor, status, código de pagamento e PDF.
- Financeiro com mensalidade, impostos, boletos/PIX e histórico.
- Relatórios com métricas e gráfico.
- Perfil médico/empresa.
- Mensagens/chamados.
- Notificações internas e estrutura para push/local notifications.
- Gestão de CNPJs.
- Área administrativa inicial para clientes médicos.
- Fluxo de NFs-e baseado em `NfsScreen` e `DescriptionScreen`.

## Arquitetura

Estrutura Clean Architecture + Feature First:

```txt
lib/
  app/          rotas, tema e configuração
  core/         rede, segurança, erros, utils e widgets compartilhados
  features/     auth, dashboard, documents, obligations, payments, reports...
```

Cada feature crítica possui `data`, `domain` e `presentation`. Os dados estão mockados em providers/datasources e podem ser trocados por API/Firebase sem alterar widgets.

## Como instalar

Instale o Flutter estável mais recente e depois rode:

```bash
flutter pub get
flutter run -d "iPhone 15"
```

Este ambiente não tinha `flutter`/`dart` no PATH, então os arquivos nativos completos devem ser materializados com:

```bash
flutter create --platforms=ios,android .
flutter pub get
```

Depois preserve/mescle o `ios/Runner/Info.plist` deste repositório.

## Ambiente

Configure a API real por `--dart-define`:

```bash
flutter run \
  --dart-define=NOVVA_API_BASE_URL=https://sua-api.example.com \
  --dart-define=NOVVA_USE_MOCK_API=false
```

Não coloque secrets, tokens, SendGrid keys ou chaves privadas no app cliente.

## iOS

Bundle identifier sugerido: `br.com.novva.app`.

Permissões preparadas no `ios/Runner/Info.plist`:

- Câmera.
- Fotos.
- Face ID.
- Notificações.

Build release:

```bash
flutter build ios --release \
  --dart-define=NOVVA_API_BASE_URL=https://sua-api.example.com \
  --dart-define=NOVVA_USE_MOCK_API=false
```

## Testes

```bash
flutter test
```

Há testes iniciais para validators e usecase de login. Próximos testes recomendados: repositories com `mocktail`, navegação autenticada, widget tests das telas principais e logout.

## Próximos passos

- Implementar `AuthRemoteDataSource` real com API segura ou Firebase Admin mediado por backend.
- Remover qualquer senha em texto puro do backend atual e migrar para hash/Identity Provider.
- Conectar documentos e uploads a storage seguro com validação de MIME/tamanho.
- Implementar refresh token real, push notifications e cache Hive por feature.
- Gerar ícones finais com `flutter_launcher_icons` e splash nativa com `flutter_native_splash`.
