# Handoff completo — Android e publicação do Novva na Google Play

> Documento preparado em 10 de novembro de 2026 para continuar o trabalho em um computador Windows.
>
> Este documento descreve o estado real do repositório neste momento. Não trate a pasta `android/` atual como pronta para produção.

## 0. Status da implementação (atualizado em 10/11/2026)

Os bloqueadores de código da seção 3 foram resolvidos no repositório:

| Item | Status |
| --- | --- |
| 3.1 Package `br.com.novva.app`, `MainActivity` movida | Feito |
| 3.2 `INTERNET` no manifest principal | Feito |
| 3.3 Assinatura release via `android/key.properties` | Feito — o build release **falha** se o arquivo não existir (nunca usa a chave debug) |
| 3.4 Plugin Google Services 4.5.0 | Feito — aplicado automaticamente quando `android/app/google-services.json` existir; release falha sem ele |
| 3.5 Push no Android | Feito — token FCM sem APNs, plataforma `ANDROID`, canal `novva_documents` criado na `MainActivity`, ícone/cor padrão no manifest, aviso interno (SnackBar com "Ver") em primeiro plano, backend envia `android.priority=high` + `channelId` |
| 3.6 Biometria | Feito — `FlutterFragmentActivity`, `USE_BIOMETRIC`, tema AppCompat, aceita qualquer biometria no Android, textos "biometria" no Android e "Face ID" no iOS |
| 3.7 Ícone e splash | Feito — gerados por `python scripts/generate_android_assets.py` (ícone adaptativo + monochrome, ícone de notificação, splash Android < 12 e 12+, ícone 512 e feature graphic em `app_store/google_play/`) |
| 3.8 Label `Novva` | Feito |
| 3.9 Gradle Wrapper versionado | Feito — `gradlew`, `gradlew.bat` e `gradle-wrapper.jar` (9.1.0, SHA-256 conferido) |
| Permissões de mídia do `open_filex` | Removidas (`READ_MEDIA_*` e `READ_EXTERNAL_STORAGE`); PDFs ficam no cache do app, então não há declaração de fotos/vídeos na Play |
| 13 Página web de exclusão | Feito — `docs/delete-account/index.html`, linkada no suporte e na privacidade |
| 14 Política de privacidade | Atualizada (Android/Google Play, FCM, biometria local, SERPRO, exclusão web) |

Continuam manuais (dependem de consoles/segredos):

1. Registrar o app Android `br.com.novva.app` no Firebase e salvar `android/app/google-services.json` (etapa 4).
2. Gerar a upload key e criar `android/key.properties` (etapa 8).
3. Publicar as páginas (`git push` para o GitHub Pages) e conferir `https://raphaelcastelar.github.io/app-novva/delete-account/`.
4. Testes em aparelhos (seção 8), Play Console (seções 9 a 17).

## 1. Objetivo

Entregar a versão Android do Novva com as mesmas funções da versão iOS publicada, testar em aparelhos Android reais, distribuir primeiro em uma faixa de testes da Google Play e depois publicar para usuários no Brasil.

O aplicativo é um portal de atendimento contábil para médicos. Ele permite:

- autenticação por CPF e senha;
- login posterior com biometria;
- consulta e download de documentos;
- recebimento de notificações de documentos concluídos;
- acesso a obrigações e guias DAS;
- geração e recálculo de DAS pela integração SERPRO no backend;
- solicitação de emissão de nota fiscal;
- rascunhos, favoritos e sugestões de descrição de nota;
- cadastro e seleção de tomadores;
- gestão de CNPJs;
- suporte via WhatsApp;
- exclusão da conta pelo próprio aplicativo;
- temas claro e escuro conforme o sistema.

## 2. Contexto do produto e da infraestrutura

### Identidade

- Nome da marca: `Novva`
- Nome recomendado na Google Play: `Novva: Contabilidade Médica`
- Empresa responsável: `Novva Assessoria Médica Ltda.`
- CNPJ: `69.356.635/0001-22`
- Idioma: Português do Brasil
- Mercado inicial: Brasil
- Modelo: aplicativo gratuito, sem anúncios, sem compras no app e sem assinatura digital vendida no app
- Público: médicos e empresas médicas clientes da Novva; não é destinado a crianças

### Contatos públicos

- E-mail: `novvacontabilidade@gmail.com`
- WhatsApp: `+55 22 99882-5251`
- Suporte: `https://raphaelcastelar.github.io/app-novva/`
- Privacidade: `https://raphaelcastelar.github.io/app-novva/privacy/`

### Repositório

- GitHub: `https://github.com/raphaelcastelar/app-novva.git`
- Branch de trabalho: `main`
- Commit de referência na criação deste documento: `319eb31`
- Stack: Flutter/Dart, Riverpod, GoRouter, Dio, Firebase Messaging e `local_auth`
- Versão atual no `pubspec.yaml`: `1.0.0+18`
- A versão iOS 1.0, build 18, já foi aprovada e publicada na App Store.

### Backend de produção

- API pública: `https://api-novva.134-209-223-54.sslip.io/api/v1/`
- Health check: `https://api-novva.134-209-223-54.sslip.io/api/v1/health`
- Infraestrutura: droplet DigitalOcean `app-novva`
- Acesso administrativo conhecido no ambiente original: `ssh root@172.28.173.171`
- O IP acima é privado e depende da rede privada/ZeroTier configurada.
- O backend já utiliza Firebase Admin e o banco já aceita plataformas `IOS` e `ANDROID` para dispositivos push.
- A API, banco, certificados SERPRO, credenciais SERPRO e chave de serviço Firebase ficam no servidor. **Nunca copiar esses segredos para o aplicativo Android.**

### Conta de demonstração

Existe uma conta de demonstração com documentos, obrigação e solicitação de nota para revisores das lojas.

- O CPF e a senha devem ser entregues ao responsável pelo Windows por um canal seguro.
- A credencial atual pode ser conferida em **App Store Connect → App Review Information**.
- Não registrar a senha neste repositório, em commits, prints ou tickets públicos.
- Na Google Play, cadastrar a mesma conta em **Policy and programs → App content → App access**.
- Informar ao revisor que o usuário é um CPF de 11 dígitos, não um e-mail, que não há OTP e que a biometria pode ser ignorada.

## 3. Estado atual do Android — bloqueadores conhecidos

Não enviar o bundle atual para a Google Play antes de corrigir todos os itens abaixo.

### 3.1 Identificador provisório

O Android atual usa:

```text
namespace     = br.com.novva.novva_app
applicationId = br.com.novva.novva_app
```

O identificador de produção recomendado é:

```text
br.com.novva.app
```

Ele é igual ao Bundle ID do iOS e deve ser definido **antes** de registrar o app Android no Firebase e antes do primeiro upload na Google Play. O `applicationId` da Google Play não pode ser trocado depois que o primeiro bundle for publicado.

Arquivos a alterar:

- `android/app/build.gradle.kts`
- pacote e caminho de `MainActivity.kt`
- registro do aplicativo Android no Firebase
- qualquer automação que referencie o package antigo

O destino correto da Activity deve ser:

```text
android/app/src/main/kotlin/br/com/novva/app/MainActivity.kt
```

E a primeira linha:

```kotlin
package br.com.novva.app
```

### 3.2 Release sem acesso à internet

O `android/app/src/main/AndroidManifest.xml` não declara `INTERNET`. A permissão existe apenas nos manifests de debug/profile, portanto uma release pode abrir sem conseguir acessar a API.

Adicionar acima de `<application>`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

### 3.3 Assinatura de debug

O build `release` está configurado para usar a chave de debug:

```kotlin
signingConfig = signingConfigs.getByName("debug")
```

É obrigatório criar uma upload key de produção, configurar `key.properties` e ativar Play App Signing. Nunca publicar uma release assinada com chave de debug.

### 3.4 Firebase Android inexistente

Existe somente:

```text
ios/Runner/GoogleService-Info.plist
```

Ainda não existe:

```text
android/app/google-services.json
```

É necessário adicionar o app Android ao **mesmo projeto Firebase usado no iOS**, usando exatamente `br.com.novva.app`.

### 3.5 Notificações limitadas ao iOS

O código atual não habilita FCM no Android:

- `PushNotificationService.isSupported` retorna verdadeiro apenas no iOS;
- o registro sempre envia `platform: 'IOS'` para a API;
- a obtenção do token sempre espera um token APNs, que só existe em aparelhos Apple;
- ainda não existe canal Android de notificações;
- mensagens em primeiro plano não geram uma notificação visual automaticamente.

Arquivos principais:

- `lib/core/notifications/push_notification_service.dart`
- `lib/core/notifications/push_device_remote_data_source.dart`
- `lib/core/notifications/notification_navigation_service.dart`
- `backend/src/modules/push-devices/push-notifications.service.ts`

### 3.6 Biometria limitada ao Face ID

`BiometricAuthService` considera apenas `BiometricType.face`. Em muitos Androids a biometria aparecerá como `fingerprint`, `strong` ou `weak`.

Também é necessário:

- trocar `FlutterActivity` por `FlutterFragmentActivity`;
- declarar `android.permission.USE_BIOMETRIC`;
- usar um tema AppCompat compatível com o diálogo biométrico;
- trocar textos “Face ID” por “Biometria” no Android;
- aceitar qualquer biometria cadastrada adequada, sem depender somente de `BiometricType.face`.

### 3.7 Ícone e splash provisórios

- O launcher Android ainda mostra o ícone azul padrão do Flutter.
- O splash nativo Android ainda é somente branco/tema padrão.
- Reutilizar `assets/images/logo_mark_transparent.png` como fonte da marca.
- Criar ícone adaptativo Android, com foreground e background próprios.
- Manter a transição visual coerente com a splash Flutter que exibe a logo Novva.

### 3.8 Nome provisório

No manifest consta:

```xml
android:label="novva_app"
```

Trocar para:

```xml
android:label="Novva"
```

### 3.9 Wrapper Gradle não versionado

O `.gitignore` atual ignora `gradlew`, `gradlew.bat` e `gradle-wrapper.jar`. Um clone limpo no Windows pode não conseguir compilar.

Opções:

1. Preferível: restaurar e versionar o Gradle Wrapper antes de transferir o projeto.
2. Alternativa no Windows: executar `flutter create --platforms=android .` antes de fazer as customizações e revisar cuidadosamente o diff para não sobrescrever configurações.

Não executar `flutter create` depois das customizações sem revisar o diff.

## 4. Acessos e materiais necessários no Windows

Providenciar antes de começar:

- conta GitHub com acesso ao repositório;
- conta Google com acesso ao projeto Firebase de produção;
- conta Google com acesso ao Play Console;
- conta Play Console verificada;
- se a conta for de organização: número D-U-N-S e dados jurídicos consistentes com a Novva;
- CPF e senha da conta de demonstração, entregues fora do Git;
- logo transparente em `assets/images/logo_mark_transparent.png`;
- acesso ao link público de suporte/privacidade;
- 12 contas Google de testadores, caso se aplique a exigência de teste fechado;
- local seguro para backup do upload keystore e respectivas senhas.

Não são necessários no Windows:

- certificado Apple `.p8`;
- certificado de distribuição iOS;
- credenciais privadas do SERPRO;
- certificado SERPRO;
- senha do banco;
- conta de serviço Firebase Admin do backend;
- segredo JWT da API.

## 5. Preparação do Windows

### 5.1 Instalar ferramentas

Instalar:

1. Git for Windows.
2. Flutter Stable. O ambiente de origem usa Flutter 3.44.0 e Dart 3.12.0; usar essa versão ou uma versão estável posterior compatível.
3. Android Studio estável.
4. Android SDK Platform 36 e Build Tools atuais.
5. JDK 17.
6. Google Chrome, para os consoles Firebase e Play.
7. Opcional: Firebase CLI e FlutterFire CLI.

No Android Studio SDK Manager, instalar:

- Android SDK Platform 36;
- Android SDK Build-Tools;
- Android SDK Command-line Tools;
- Android Emulator;
- Platform Tools;
- uma imagem de emulador com **Google Play**, não apenas AOSP.

Validar no PowerShell:

```powershell
git --version
flutter --version
dart --version
java -version
flutter doctor -v
flutter doctor --android-licenses
```

Todas as pendências relevantes do `flutter doctor` devem ser resolvidas.

### 5.2 Clonar

```powershell
git clone https://github.com/raphaelcastelar/app-novva.git
cd app-novva
git checkout main
git pull origin main
flutter pub get
```

Confirmar que o commit `319eb31` ou um commit posterior está presente:

```powershell
git log -5 --oneline
git status
```

## 6. Ordem recomendada de implementação

Executar nesta ordem para não registrar identificadores incorretos nos consoles.

### Etapa 1 — Materializar e validar o projeto Android

1. Garantir que `gradlew.bat` e o wrapper existem.
2. Abrir a raiz do projeto no VS Code e a pasta `android/` no Android Studio quando precisar editar Gradle.
3. Rodar um build debug antes das alterações para identificar problemas básicos.
4. Não criar ainda o app na Play Console nem no Firebase Android.

### Etapa 2 — Fixar a identidade Android

Em `android/app/build.gradle.kts`:

```kotlin
android {
    namespace = "br.com.novva.app"
    compileSdk = 36

    defaultConfig {
        applicationId = "br.com.novva.app"
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
}
```

Em novembro de 2026, novos apps e atualizações precisam mirar Android 16/API 36 ou superior. Confirmar novamente a exigência no momento do envio: <https://support.google.com/googleplay/android-developer/answer/11926878>.

Mover e atualizar `MainActivity.kt`:

```kotlin
package br.com.novva.app

import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity()
```

### Etapa 3 — Manifest e tema

O manifest de produção deve conter, no mínimo:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.USE_BIOMETRIC" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

    <application
        android:label="Novva"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        ...
    </application>
</manifest>
```

O FCM atual já inclui `POST_NOTIFICATIONS` por merge de manifest, mas deixá-la explícita facilita a auditoria. Android 13+ também exige solicitação em tempo de execução.

Atualizar `styles.xml` para um tema AppCompat compatível com `local_auth`. Referência: <https://pub.dev/packages/local_auth_android>.

### Etapa 4 — Firebase Android

Usar o mesmo projeto Firebase do iOS:

1. Abrir Firebase Console.
2. Project settings → General → Add app → Android.
3. Package: `br.com.novva.app`.
4. Apelido sugerido: `Novva Android`.
5. Baixar `google-services.json`.
6. Salvar exatamente em `android/app/google-services.json`.
7. Nunca usar um JSON cujo package seja diferente.

Configuração manual oficial atual:

Em `android/settings.gradle.kts`:

```kotlin
plugins {
    // plugins existentes
    id("com.google.gms.google-services") version "4.5.0" apply false
}
```

Em `android/app/build.gradle.kts`:

```kotlin
plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}
```

Como alternativa preferencial, usar a CLI oficial:

```powershell
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
flutterfire configure
```

Selecionar o projeto Firebase existente e apenas Android/iOS que realmente devem permanecer configurados. Revisar o diff gerado. A documentação oficial recomenda FlutterFire CLI: <https://firebase.google.com/docs/flutter/setup>.

Se a CLI gerar `lib/firebase_options.dart`, inicializar com `DefaultFirebaseOptions.currentPlatform` e confirmar que o iOS continua funcionando.

### Etapa 5 — Tornar notificações multiplataforma

Alterações mínimas esperadas:

1. `isSupported` deve aceitar iOS e Android.
2. No iOS, continuar esperando APNs antes de chamar `getToken()`.
3. No Android, não consultar APNs; chamar `FirebaseMessaging.instance.getToken()` após a permissão.
4. `PushDeviceRemoteDataSource.register` deve enviar `ANDROID` quando estiver no Android e `IOS` quando estiver no iOS.
5. Criar canal Android de alta prioridade, por exemplo:

```text
ID: novva_documents
Nome: Documentos
Importância: alta
Som: padrão
```

6. Configurar o canal padrão no manifest.
7. Exibir notificação local quando a mensagem chegar com o aplicativo em primeiro plano, ou apresentar um banner interno claramente testado. O FCM não mostra banner automaticamente em primeiro plano.
8. Manter o clique na notificação direcionando para Documentos e expandindo o documento correto.
9. Validar background, app encerrado e primeiro lançamento por notificação.

O backend envia um payload genérico FCM e já pode entregar para Android. É recomendável acrescentar configuração Android explícita com prioridade alta e `channelId`, mas isso não substitui a configuração do cliente.

Referências:

- <https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages>
- <https://firebase.google.com/docs/cloud-messaging/android/get-started>

### Etapa 6 — Biometria Android

Em `BiometricAuthService`:

- não exigir somente `BiometricType.face`;
- considerar a lista não vazia ou os tipos `fingerprint`, `strong`, `weak` e `face`;
- usar `isDeviceSupported()` quando apropriado;
- manter `biometricOnly: true` se o produto continuar exigindo biometria real;
- usar texto “Use a biometria para acessar sua conta Novva” no Android;
- manter “Face ID” somente no iOS.

Fluxo esperado, igual ao iOS:

1. Primeiro login com CPF e senha.
2. Oferta opcional para ativar biometria depois do login.
3. Próxima abertura mostra a conta salva.
4. Usuário toca em Continuar.
5. Só então o sistema solicita biometria.
6. Se falhar ou cancelar, abrir a tela de senha.

### Etapa 7 — Identidade visual

Substituir o ícone padrão do Flutter usando a marca transparente.

Recomendação:

- usar `flutter_launcher_icons` para gerar mipmaps;
- criar foreground adaptativo sem fundo branco embutido;
- usar uma cor de fundo coerente com a paleta Novva;
- conferir o safe zone em ícones redondos, quadrados e “squircle”;
- criar splash Android 12+ e fallback de versões anteriores;
- testar tema claro e escuro.

Não reutilizar cegamente o PNG final da App Store como adaptive foreground; preservar margem para o recorte Android.

### Etapa 8 — Assinatura

No PowerShell, gerar a upload key uma única vez:

```powershell
keytool -genkeypair -v `
  -keystore "$env:USERPROFILE\novva-upload-keystore.jks" `
  -storetype JKS `
  -keyalg RSA `
  -keysize 2048 `
  -validity 10000 `
  -alias upload
```

Criar `android/key.properties`:

```properties
storePassword=SUBSTITUIR
keyPassword=SUBSTITUIR
keyAlias=upload
storeFile=C:/Users/USUARIO/novva-upload-keystore.jks
```

O arquivo `key.properties`, a keystore e as senhas não podem entrar no Git.

Configurar `signingConfigs.release` em `android/app/build.gradle.kts` seguindo a documentação Flutter: <https://docs.flutter.dev/deployment/android>.

Na Play Console, manter **Play App Signing** ativado e permitir que o Google gere/proteja a app signing key. A chave local será apenas a upload key. Fazer backup da keystore e senhas em pelo menos dois locais seguros. Referência: <https://support.google.com/googleplay/android-developer/answer/9842756>.

Exportar o certificado público da upload key:

```powershell
keytool -export -rfc `
  -keystore "$env:USERPROFILE\novva-upload-keystore.jks" `
  -alias upload `
  -file "$env:USERPROFILE\novva-upload-certificate.pem"
```

Após o primeiro upload, copiar também os SHA-1/SHA-256 da app signing key fornecidos pela Google Play para o Firebase, se algum serviço futuro depender desses fingerprints.

## 7. Execução e build no Windows

### Debug conectado à produção

```powershell
$ApiUrl = "https://api-novva.134-209-223-54.sslip.io/api/v1/"

flutter run `
  --dart-define="NOVVA_API_BASE_URL=$ApiUrl" `
  --dart-define=NOVVA_USE_MOCK_API=false
```

### Qualidade antes da release

```powershell
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test test
```

### App Bundle de produção

```powershell
$ApiUrl = "https://api-novva.134-209-223-54.sslip.io/api/v1/"

flutter clean
flutter pub get
flutter build appbundle --release `
  --dart-define="NOVVA_API_BASE_URL=$ApiUrl" `
  --dart-define=NOVVA_USE_MOCK_API=false
```

Saída esperada:

```text
build/app/outputs/bundle/release/app-release.aab
```

Validar no bundle:

- package `br.com.novva.app`;
- `targetSdkVersion` 36 ou superior;
- `versionName` e `versionCode` corretos;
- assinatura release, não debug;
- permissão de internet;
- permissões de biometria e notificações;
- nenhuma credencial privada embutida.

Para a primeira versão Android, `1.0.0+18` é tecnicamente válido. Para manter uma sequência nova e clara, também é aceitável preparar `1.0.1+19`. Depois do primeiro upload, o `versionCode` sempre precisa aumentar.

## 8. Matriz obrigatória de testes

Testar preferencialmente o AAB entregue por uma faixa interna da Play Store, não apenas `flutter run`.

### Dispositivos

- Android 7/API 24, limite mínimo;
- Android 13/API 33, permissão de notificações;
- Android 16/API 36, target atual;
- pelo menos um aparelho físico Samsung;
- pelo menos um aparelho físico Google/Pixel ou Motorola;
- emulador de telefone com Google Play;
- emulador/tablet Android em retrato e paisagem.

### Fluxos

- instalação limpa;
- CPF inexistente e CPF inválido;
- login da conta demo;
- teclado visível sem sobrepor botões;
- logout e login novamente;
- conta salva sem preencher o CPF no input;
- biometria oferecida depois do login, nunca ao abrir automaticamente;
- biometria cancelada/falha encaminhando para senha;
- tema claro e escuro;
- permissão de notificações aceita e negada;
- recebimento em primeiro plano, segundo plano e app encerrado;
- clique no push abrindo o documento correto;
- download e abertura de PDF;
- solicitação de documento;
- solicitação de nota;
- validação de CNPJ;
- cadastro, edição, exclusão e seleção de tomador;
- rascunho, favorito e sugestão de nota;
- guias DAS, geração, download e recálculo;
- WhatsApp externo;
- recuperação de senha;
- exclusão de conta usando uma conta descartável, nunca a conta do revisor;
- conexão lenta, offline, timeout e retorno da conexão;
- rotação de tela e fontes maiores;
- reinício do aparelho e atualização sobre uma versão anterior.

## 9. Conta Google Play e criação do app

### Tipo de conta

Como o aplicativo representa uma empresa e oferece um serviço profissional/comercial, a recomendação é uma conta Google Play do tipo **Organization**, em nome da Novva, com dados jurídicos corretos. A organização exige D-U-N-S. Referência: <https://support.google.com/googleplay/android-developer/answer/13634885>.

Antes de criar:

- conferir razão social, endereço, telefone e domínio;
- verificar se a empresa já possui D-U-N-S;
- usar e-mail corporativo/controlado pela empresa;
- ativar autenticação em duas etapas;
- adicionar pelo menos um segundo administrador confiável.

### Cadastro do aplicativo

No Play Console:

1. Create app.
2. Nome: `Novva: Contabilidade Médica`.
3. Idioma padrão: Português (Brasil).
4. App ou game: App.
5. Gratuito ou pago: Gratuito.
6. Aceitar declarações aplicáveis.
7. Disponibilidade inicial: Brasil.
8. Não habilitar Wear OS, TV, Automotive ou XR.

O package real será definido pelo primeiro AAB. Confirmar `br.com.novva.app` antes desse upload.

## 10. Testes exigidos pela Google Play

Começar por **Internal testing** para QA rápido.

Se a conta for pessoal e tiver sido criada depois de 13 de novembro de 2023, a Google exige atualmente:

- closed test;
- pelo menos 12 testadores inscritos;
- participação contínua por 14 dias;
- depois, solicitação de acesso à produção.

Se alguém sair e voltar, a contagem contínua desse testador reinicia. Confirmar a regra atual aqui: <https://support.google.com/googleplay/android-developer/answer/14151465>.

Mesmo em conta de organização, usar:

1. Internal testing.
2. Closed testing com usuários reais da equipe/clientes autorizados.
3. Produção com managed publishing ativado, para controlar o momento do lançamento.

## 11. Ficha da loja

### Textos sugeridos

**Nome — máximo de 30 caracteres**

```text
Novva: Contabilidade Médica
```

**Descrição curta — máximo de 80 caracteres**

```text
Contabilidade médica, documentos, notas fiscais e guias em um só lugar.
```

**Descrição completa sugerida**

```text
O Novva é o portal de atendimento contábil criado para médicos e empresas médicas clientes da Novva.

Tenha documentos, obrigações fiscais, guias e solicitações organizados em um único aplicativo, com acesso seguro por CPF e senha.

Com o Novva você pode:

• consultar e baixar documentos disponibilizados pela equipe;
• receber avisos quando um documento estiver concluído;
• acompanhar obrigações e guias DAS;
• gerar, baixar e solicitar o recálculo de guias disponíveis;
• solicitar a emissão de notas fiscais;
• salvar rascunhos e descrições favoritas;
• cadastrar e selecionar tomadores;
• gerenciar os CNPJs vinculados à sua conta;
• falar com a equipe Novva pelo WhatsApp;
• proteger o acesso com biometria compatível com o aparelho.

O acesso é destinado a clientes previamente cadastrados pela Novva. O aplicativo não oferece serviços médicos, diagnóstico, tratamento, banco, empréstimos, investimentos ou processamento de pagamentos.

Precisa de ajuda? Entre em contato com a equipe Novva pelos canais informados nesta página.
```

### Categoria

- Categoria principal recomendada: `Finance`
- Alternativa: `Business`
- Não classificar como Medical/Health, porque o aplicativo não presta atendimento de saúde nem trata prontuários de pacientes.

### Recursos gráficos

- Ícone Play Store: PNG 32-bit com alpha, `512 × 512`, até 1 MB.
- Feature graphic: JPG ou PNG 24-bit sem alpha, `1024 × 500`.
- Pelo menos 2 screenshots são obrigatórios.
- Recomendado: 4 a 8 screenshots de telefone em `1080 × 1920` ou outra proporção 9:16 válida.
- Para tablets, recomendado adicionar pelo menos 4 screenshots reais em 9:16 ou 16:9, entre 1080 e 7680 px.
- Capturar a interface Android real. Não reutilizar prints com barra de status/iPhone.
- Não exibir CPF, CNPJ real, e-mail, token, nomes de clientes ou documentos sensíveis.

Sequência sugerida:

1. Painel inicial.
2. Documentos.
3. Documento concluído e download.
4. Guias DAS.
5. Solicitação de nota.
6. Tomadores.
7. Notificações.
8. Mais/configurações.

Regras atuais de assets: <https://support.google.com/googleplay/android-developer/answer/9866151>.

## 12. App content e políticas — respostas planejadas

Revisar novamente as respostas com base no AAB final; não copiar mecanicamente se o código mudar.

### Ads

- O app contém anúncios? **Não**.

### App access

- O app exige login? **Sim**.
- Fornecer CPF e senha da conta demo.
- Informar passos:
  1. digitar o CPF somente com números;
  2. tocar em Continuar;
  3. digitar a senha;
  4. tocar em Entrar;
  5. biometria e notificações são opcionais.
- Garantir que a conta permaneça ativa durante toda a análise.

### Público-alvo

- Selecionar somente adultos, preferencialmente `18 and over`.
- O app não é dirigido a crianças.

### Content rating

- Preencher o questionário honestamente.
- O produto não contém violência, sexo, drogas, apostas ou conteúdo gerado publicamente por usuários.
- Solicitações e documentos privados não constituem uma rede social pública.

### News app

- Não é aplicativo de notícias.

### Government app

- Não é aplicativo oficial do governo.
- Ele utiliza uma integração contratada com o SERPRO no backend, mas não deve sugerir afiliação ou endosso governamental.

### Health apps

- Não é health app.
- O público ser médico não transforma o produto em aplicativo médico.
- O app não fornece diagnóstico, tratamento, aconselhamento médico nem prontuário de pacientes.

### Financial features declaration

Todos os apps precisam preencher essa declaração. O Novva não oferece banco, empréstimo, carteira, transferência, investimento, seguro ou criptomoeda.

Como ele lida com contabilidade, notas e impostos, revisar as opções apresentadas no formulário. Se houver opção adequada de serviço contábil/fiscal ou `Other`, declará-la e explicar que se trata de suporte contábil e geração de documentos fiscais para clientes. Não marcar produtos financeiros que não existem. Referência: <https://support.google.com/googleplay/android-developer/answer/13849271>.

### Data safety — inventário inicial

Dados tratados para funcionalidade da conta:

- nome;
- CPF como identificador da conta;
- e-mail;
- telefone opcional;
- CNPJ e dados empresariais;
- informações profissionais;
- informações fiscais, contábeis e financeiras necessárias ao serviço;
- solicitações, observações e arquivos/documentos;
- token técnico FCM do dispositivo;
- registros de segurança e auditoria.

Finalidades principais:

- app functionality;
- account management;
- security/fraud prevention;
- developer communications/notificações de serviço;
- compliance/legal obligations quando aplicável.

Declarações esperadas:

- dados criptografados em trânsito: **Sim**, API HTTPS;
- usuário pode solicitar exclusão: **Sim**;
- dados vendidos: **Não**;
- anúncios/personalização publicitária: **Não**;
- Firebase Analytics: atualmente não instalado;
- Crashlytics: atualmente não instalado;
- rastreamento entre apps: não realizado.

Antes de responder “shared”, ler a definição da Google para operadores/service providers. O app transmite dados somente aos fornecedores necessários ao serviço, como infraestrutura, Firebase/FCM e SERPRO. A declaração deve corresponder ao comportamento final e à política de privacidade.

Referência geral: <https://support.google.com/googleplay/android-developer/answer/9859455>.

## 13. Exclusão da conta — bloqueador de política

O aplicativo já possui exclusão interna em:

```text
Mais → Privacidade e conta → Excluir minha conta
```

Entretanto, a Google exige também uma página web pública onde o usuário consiga solicitar exclusão sem reinstalar o app.

Criar antes de produção:

```text
https://raphaelcastelar.github.io/app-novva/delete-account/
```

A página deve:

- mencionar Novva e Novva Assessoria Médica Ltda.;
- explicar como solicitar exclusão;
- oferecer formulário funcional ou e-mail clicável com assunto predefinido;
- informar como a identidade será confirmada;
- explicar quais dados serão apagados;
- explicar eventuais dados mantidos por obrigação legal e o prazo;
- fornecer prazo de atendimento;
- estar acessível sem login e sem geobloqueio;
- estar destacada na política de privacidade e no suporte.

Depois, informar essa URL no campo de account deletion da Data safety. A página atual de privacidade, sozinha, apenas aponta para a exclusão dentro do app e não é suficiente como fluxo web destacado. Referência oficial: <https://support.google.com/googleplay/android-developer/answer/13327111>.

## 14. Política de privacidade

Usar:

```text
https://raphaelcastelar.github.io/app-novva/privacy/
```

Antes do envio Android, atualizar a política para citar explicitamente:

- Android e Google Play;
- Firebase Cloud Messaging no Android;
- identificador/token de dispositivo;
- biometria processada localmente pelo sistema;
- SERPRO para funcionalidades fiscais;
- exclusão web e retenção legal;
- data real da última atualização.

A política deve continuar acessível sem login, por HTTPS e dentro do app.

## 15. Criar a primeira release na Play Console

### Internal testing

1. Test and release → Testing → Internal testing.
2. Criar release.
3. Ativar Play App Signing.
4. Enviar `app-release.aab`.
5. Adicionar release notes.
6. Adicionar testadores.
7. Publicar a faixa interna.
8. Instalar usando o link da Play Store em aparelho físico.

Release notes sugeridas:

```text
Primeira versão Android do Novva, com acesso a documentos, notificações, guias, solicitações de notas, tomadores e suporte contábil.
```

### Closed testing

1. Corrigir tudo encontrado no teste interno.
2. Criar a faixa fechada.
3. Manter testadores inscritos e ativos.
4. Coletar feedback real.
5. Não trocar o package nem perder a upload key.

### Produção

Antes de enviar:

- Store listing completa;
- App content sem pendências;
- Data safety concluída;
- URL de exclusão ativa;
- conta demo funcionando;
- target API aceito;
- AAB assinado;
- conteúdo e screenshots correspondem ao app;
- países corretos;
- managed publishing configurado;
- backend e Firebase em produção.

## 16. Checklist final técnico

- [ ] Package final é `br.com.novva.app`.
- [ ] Namespace final é `br.com.novva.app`.
- [ ] MainActivity está no pacote correto.
- [ ] MainActivity usa `FlutterFragmentActivity`.
- [ ] `minSdk` é pelo menos 24.
- [ ] `targetSdk` é pelo menos 36.
- [ ] Manifest release contém `INTERNET`.
- [ ] Manifest contém `USE_BIOMETRIC`.
- [ ] Permissão de notificações funciona em Android 13+.
- [ ] `google-services.json` corresponde ao package final.
- [ ] FCM gera token Android.
- [ ] API recebe plataforma `ANDROID`.
- [ ] Push chega e abre o documento correto.
- [ ] Foreground notification tem comportamento definido.
- [ ] Biometria aceita fingerprint/face/strong/weak adequadamente.
- [ ] Cancelar biometria leva à senha.
- [ ] Ícone Novva substituiu o ícone Flutter.
- [ ] Splash Novva substituiu o splash branco padrão.
- [ ] Label instalado é `Novva`.
- [ ] Release usa upload keystore, nunca debug key.
- [ ] Upload keystore possui backup seguro.
- [ ] AAB não contém segredos.
- [ ] `flutter analyze` passa.
- [ ] Testes unitários passam.
- [ ] Testes físicos passam.
- [ ] Teste via Play Internal passa.

## 17. Checklist final da Google Play

- [ ] Conta Play Console verificada.
- [ ] Conta de organização e D-U-N-S avaliados.
- [ ] App gratuito e Brasil configurados.
- [ ] Ficha em Português do Brasil.
- [ ] Ícone 512 × 512.
- [ ] Feature graphic 1024 × 500.
- [ ] Pelo menos quatro screenshots Android de telefone recomendadas.
- [ ] Screenshots de tablet se o app permanecer disponível em tablets.
- [ ] Política de privacidade ativa.
- [ ] Página web de exclusão ativa.
- [ ] Ads declarado como Não.
- [ ] App access com conta demo.
- [ ] Público-alvo adulto.
- [ ] Content rating concluído.
- [ ] Data safety revisada conforme o AAB final.
- [ ] Financial features declaration concluída.
- [ ] Health declaration como não aplicável.
- [ ] Government app como não.
- [ ] News app como não.
- [ ] Teste fechado obrigatório concluído, se aplicável.
- [ ] Produção enviada com managed publishing.

## 18. Erros que não devem ser cometidos

- Não registrar `br.com.novva.novva_app` na Play Store por engano.
- Não gerar vários keystores e perder a chave usada no primeiro upload.
- Não commitar `key.properties`, `.jks`, senhas ou chaves privadas.
- Não colocar credenciais SERPRO ou Firebase Admin no app.
- Não testar apenas debug; release tem diferenças de manifest e assinatura.
- Não declarar “não coletamos dados” na Data safety.
- Não usar screenshots de iPhone na ficha Android.
- Não marcar o app como infantil ou médico.
- Não publicar sem página web de exclusão.
- Não deixar a conta demo expirar durante a análise.
- Não usar o ícone padrão Flutter.
- Não afirmar vínculo oficial com SERPRO ou governo.
- Não executar geração/recálculo de DAS repetidamente em produção durante QA sem saber o impacto.

## 19. Fontes oficiais consultadas

- Target API: <https://support.google.com/googleplay/android-developer/answer/11926878>
- Teste obrigatório para novas contas pessoais: <https://support.google.com/googleplay/android-developer/answer/14151465>
- Configuração inicial do app: <https://support.google.com/googleplay/android-developer/answer/9859152>
- Play App Signing: <https://support.google.com/googleplay/android-developer/answer/9842756>
- App content/revisão: <https://support.google.com/googleplay/android-developer/answer/9859455>
- Exclusão de conta: <https://support.google.com/googleplay/android-developer/answer/13327111>
- Assets da loja: <https://support.google.com/googleplay/android-developer/answer/9866151>
- Declaração financeira: <https://support.google.com/googleplay/android-developer/answer/13849271>
- Firebase Flutter: <https://firebase.google.com/docs/flutter/setup>
- FCM Android: <https://firebase.google.com/docs/cloud-messaging/android/get-started>
- FCM Flutter: <https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages>
- Biometria Flutter/Android: <https://pub.dev/packages/local_auth_android>
- Build e assinatura Flutter Android: <https://docs.flutter.dev/deployment/android>

## 20. Critério de conclusão

O trabalho só está concluído quando:

1. o AAB release assinado é instalado por uma faixa da Google Play;
2. login, biometria, documentos, notas, guias e downloads funcionam em aparelho físico;
3. uma notificação enviada pelo backend chega ao Android e abre o documento correto;
4. todas as declarações da Play Console correspondem ao comportamento real;
5. a página de exclusão funciona fora do app;
6. a conta demo funciona para o revisor;
7. não há pendências no dashboard da Play Console;
8. o release de produção foi aprovado e publicado no Brasil.
